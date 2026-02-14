#!/bin/bash
# build-loop-local.sh
# Run /build-next in a loop locally. No git remote, no push, no PRs.
# Use when you want to build roadmap features without connecting to a remote.
#
# Usage:
#   ./scripts/build-loop-local.sh
#   MAX_FEATURES=5 ./scripts/build-loop-local.sh
#   BRANCH_STRATEGY=both ./scripts/build-loop-local.sh
#
# CONFIG: set MAX_FEATURES, MAX_RETRIES, BUILD_CHECK_CMD, BRANCH_STRATEGY in .env.local
# or pass in env.
#
# BRANCH_STRATEGY: How to handle branches (default: chained)
#   - chained: Each feature branches from the previous feature's branch
#              (Feature #2 has Feature #1's code even if not merged)
#   - independent: Each feature builds in a separate git worktree from main
#                  (Features are isolated, no shared code until merged)
#   - both: Run chained first (full build), then rebuild each feature
#           independently from main (sequential, not parallel)
#   - sequential: All features on one branch (original behavior)
#
# BUILD_CHECK_CMD: command to verify the build after each feature.
#   Defaults to auto-detection (TypeScript → tsc, Python → pytest, etc.)
#   Set to "skip" to disable build checking.
#   Examples:
#     BUILD_CHECK_CMD="npx tsc --noEmit"
#     BUILD_CHECK_CMD="npm run build"
#     BUILD_CHECK_CMD="python -m py_compile main.py"
#     BUILD_CHECK_CMD="cargo check"
#     BUILD_CHECK_CMD="skip"
#
# DRIFT_CHECK: whether to run spec↔code drift detection after each feature.
#   Defaults to "true". Set to "false" to disable.
#   When enabled, a SEPARATE agent invocation reads the spec and source files
#   after the build agent commits, comparing them with fresh context.
#   This catches mismatches the build agent missed (fox-guarding-henhouse problem).
#
# MAX_DRIFT_RETRIES: how many times to retry fixing drift (default: 1).
#   If drift is found, the drift agent auto-fixes by updating specs.
#   If the fix breaks the build, it retries up to this many times.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -f "$PROJECT_DIR/.env.local" ]; then
    source "$PROJECT_DIR/.env.local"
fi

MAX_FEATURES="${MAX_FEATURES:-25}"
MAX_RETRIES="${MAX_RETRIES:-1}"
BRANCH_STRATEGY="${BRANCH_STRATEGY:-chained}"
DRIFT_CHECK="${DRIFT_CHECK:-true}"
MAX_DRIFT_RETRIES="${MAX_DRIFT_RETRIES:-1}"

log() { echo "[$(date '+%H:%M:%S')] $1"; }
success() { echo "[$(date '+%H:%M:%S')] ✓ $1"; }
warn() { echo "[$(date '+%H:%M:%S')] ⚠ $1"; }
fail() { echo "[$(date '+%H:%M:%S')] ✗ $1"; }

format_duration() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    local seconds=$((total_seconds % 60))
    if [ "$hours" -gt 0 ]; then
        printf "%dh %dm %ds" "$hours" "$minutes" "$seconds"
    elif [ "$minutes" -gt 0 ]; then
        printf "%dm %ds" "$minutes" "$seconds"
    else
        printf "%ds" "$seconds"
    fi
}

SCRIPT_START=$(date +%s)

cd "$PROJECT_DIR"

# Validate BRANCH_STRATEGY
if [[ ! "$BRANCH_STRATEGY" =~ ^(chained|independent|both|sequential)$ ]]; then
    fail "Invalid BRANCH_STRATEGY: $BRANCH_STRATEGY (must be: chained, independent, both, or sequential)"
    exit 1
fi

# Get main branch name
MAIN_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
if git rev-parse --verify main >/dev/null 2>&1; then
    MAIN_BRANCH="main"
elif git rev-parse --verify master >/dev/null 2>&1; then
    MAIN_BRANCH="master"
fi

if ! command -v agent &> /dev/null; then
    echo "Cursor CLI (agent) not found. Install from: https://cursor.com/cli"
    exit 1
fi

# ── Auto-detect build check command ──────────────────────────────────────

detect_build_check() {
    if [ -n "$BUILD_CHECK_CMD" ]; then
        if [ "$BUILD_CHECK_CMD" = "skip" ]; then
            echo ""
        else
            echo "$BUILD_CHECK_CMD"
        fi
        return
    fi

    # TypeScript (check for tsconfig.build.json first, then tsconfig.json)
    if [ -f "tsconfig.build.json" ]; then
        echo "npx tsc --noEmit --project tsconfig.build.json"
    elif [ -f "tsconfig.json" ]; then
        echo "npx tsc --noEmit"
    # Python
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "python -m py_compile $(find . -name '*.py' -not -path '*/venv/*' -not -path '*/.venv/*' | head -1 2>/dev/null || echo 'main.py')"
    # Rust
    elif [ -f "Cargo.toml" ]; then
        echo "cargo check"
    # Go
    elif [ -f "go.mod" ]; then
        echo "go build ./..."
    # Node.js with build script
    elif [ -f "package.json" ] && grep -q '"build"' package.json 2>/dev/null; then
        echo "npm run build"
    else
        echo ""
    fi
}

BUILD_CMD=$(detect_build_check)

# ── Helpers ──────────────────────────────────────────────────────────────

check_working_tree_clean() {
    local dirty
    dirty=$(git status --porcelain 2>/dev/null | grep -v '^\?\?' | head -1)
    [ -z "$dirty" ]
}

clean_working_tree() {
    if ! check_working_tree_clean; then
        warn "Cleaning dirty working tree before next feature..."
        git stash push -m "build-loop: stashing failed feature attempt $(date '+%Y%m%d-%H%M%S')" 2>/dev/null || true
        success "Stashed uncommitted changes"
    fi
}

check_build() {
    if [ -z "$BUILD_CMD" ]; then
        log "No build check configured (set BUILD_CHECK_CMD to enable)"
        return 0
    fi
    log "Running build check: $BUILD_CMD"
    if eval "$BUILD_CMD" 2>&1; then
        success "Build check passed"
        return 0
    else
        fail "Build check failed"
        return 1
    fi
}

# ── Drift check helpers ──────────────────────────────────────────────────

# Extract spec file and source files from build output or git diff.
# Sets: DRIFT_SPEC_FILE, DRIFT_SOURCE_FILES
extract_drift_targets() {
    local build_result="$1"

    # Try to extract from agent's structured output first
    DRIFT_SPEC_FILE=$(echo "$build_result" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | xargs 2>/dev/null || echo "")
    DRIFT_SOURCE_FILES=$(echo "$build_result" | grep "^SOURCE_FILES:" | tail -1 | cut -d: -f2- | xargs 2>/dev/null || echo "")

    # Fallback: derive from git diff if agent didn't provide them
    if [ -z "$DRIFT_SPEC_FILE" ]; then
        DRIFT_SPEC_FILE=$(git diff HEAD~1 --name-only 2>/dev/null | grep '\.specs/features/.*\.feature\.md$' | head -1 || echo "")
    fi
    if [ -z "$DRIFT_SOURCE_FILES" ]; then
        DRIFT_SOURCE_FILES=$(git diff HEAD~1 --name-only 2>/dev/null | grep -E '\.(tsx?|jsx?|py|rs|go)$' | grep -v '\.test\.' | grep -v '\.spec\.' | tr '\n' ', ' | sed 's/,$//' || echo "")
    fi
}

# Run catch-drift via a fresh agent invocation.
# Args: $1 = spec file path, $2 = comma-separated source files
# Returns 0 if no drift (or drift was fixed), 1 if unresolvable drift.
check_drift() {
    if [ "$DRIFT_CHECK" != "true" ]; then
        log "Drift check disabled (set DRIFT_CHECK=true to enable)"
        return 0
    fi

    local spec_file="$1"
    local source_files="$2"

    if [ -z "$spec_file" ]; then
        warn "No spec file found — skipping drift check"
        return 0
    fi

    log "Running drift check (fresh agent)..."
    log "  Spec: $spec_file"
    log "  Source: ${source_files:-<detected from spec>}"

    local drift_attempt=0
    while [ "$drift_attempt" -le "$MAX_DRIFT_RETRIES" ]; do
        if [ "$drift_attempt" -gt 0 ]; then
            warn "Drift fix retry $drift_attempt/$MAX_DRIFT_RETRIES"
        fi

        DRIFT_OUTPUT=$(mktemp)

        local drift_prompt="
Run /catch-drift for this specific feature. This is an automated check — do NOT ask for user input. Auto-fix all drift by updating specs to match code (prefer documenting reality over reverting code).

Spec file: $spec_file
Source files: $source_files

Instructions:
1. Read the spec file and all its Gherkin scenarios
2. Read each source file listed above
3. Compare: does the code implement what the spec describes?
4. Check: are there behaviors in code not covered by the spec?
5. Check: are there scenarios in the spec not implemented in code?
6. If drift found: update the spec to match the code (document reality)
7. If tests need updating, update them too
8. Commit any fixes with message: 'fix: reconcile spec drift for {feature}'

IMPORTANT: Output EXACTLY ONE of these signals at the end:
NO_DRIFT
DRIFT_FIXED: {brief summary of what was reconciled}
DRIFT_UNRESOLVABLE: {what needs human attention and why}
"
        agent -p --force --output-format text "$drift_prompt" 2>&1 | tee "$DRIFT_OUTPUT" || true
        DRIFT_RESULT=$(cat "$DRIFT_OUTPUT")
        rm -f "$DRIFT_OUTPUT"

        if echo "$DRIFT_RESULT" | grep -q "NO_DRIFT"; then
            success "Drift check passed — spec and code are aligned"
            return 0
        fi

        if echo "$DRIFT_RESULT" | grep -q "DRIFT_FIXED"; then
            local fix_summary
            fix_summary=$(echo "$DRIFT_RESULT" | grep "DRIFT_FIXED" | tail -1 | cut -d: -f2- | xargs)
            success "Drift detected and auto-fixed: $fix_summary"
            # Verify the fix didn't break the build
            if check_build; then
                return 0
            else
                warn "Drift fix broke the build — retrying"
            fi
        fi

        if echo "$DRIFT_RESULT" | grep -q "DRIFT_UNRESOLVABLE"; then
            local unresolvable_reason
            unresolvable_reason=$(echo "$DRIFT_RESULT" | grep "DRIFT_UNRESOLVABLE" | tail -1 | cut -d: -f2- | xargs)
            warn "Unresolvable drift: $unresolvable_reason"
            return 1
        fi

        # No clear signal — treat as drift found but not fixed
        warn "Drift check did not produce a clear signal"
        drift_attempt=$((drift_attempt + 1))
    done

    fail "Drift check failed after $((MAX_DRIFT_RETRIES + 1)) attempt(s)"
    return 1
}

# ── Branch strategy helpers ────────────────────────────────────────────────

setup_branch_chained() {
    local base_branch="${LAST_FEATURE_BRANCH:-$MAIN_BRANCH}"

    if [ "$base_branch" != "$MAIN_BRANCH" ]; then
        log "Branching from previous feature: $base_branch"
        git checkout "$base_branch" 2>/dev/null || {
            warn "Previous branch $base_branch not found, using $MAIN_BRANCH"
            base_branch="$MAIN_BRANCH"
            git checkout "$base_branch"
        }
    else
        log "Branching from $MAIN_BRANCH (first feature)"
        git checkout "$MAIN_BRANCH"
    fi

    CURRENT_FEATURE_BRANCH="auto/chained-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$CURRENT_FEATURE_BRANCH" 2>/dev/null || {
        fail "Failed to create branch $CURRENT_FEATURE_BRANCH"
        return 1
    }
    success "Created branch: $CURRENT_FEATURE_BRANCH (from $base_branch)"
}

setup_branch_independent() {
    local worktree_name="auto-independent-$(date +%Y%m%d-%H%M%S)"
    local worktree_path="$PROJECT_DIR/.build-worktrees/$worktree_name"

    mkdir -p "$(dirname "$worktree_path")"

    log "Creating worktree: $worktree_name (from $MAIN_BRANCH)"
    git worktree add -b "auto/$worktree_name" "$worktree_path" "$MAIN_BRANCH" 2>/dev/null || {
        fail "Failed to create worktree $worktree_name"
        return 1
    }

    CURRENT_FEATURE_BRANCH="auto/$worktree_name"
    CURRENT_WORKTREE_PATH="$worktree_path"
    cd "$worktree_path"
    success "Created worktree: $worktree_name at $worktree_path"
}

setup_branch_sequential() {
    CURRENT_FEATURE_BRANCH=$(git branch --show-current)
    log "Building on current branch: $CURRENT_FEATURE_BRANCH"
}

cleanup_branch_chained() {
    LAST_FEATURE_BRANCH="$CURRENT_FEATURE_BRANCH"
    log "Next feature will branch from: $LAST_FEATURE_BRANCH"
}

cleanup_branch_independent() {
    if [ -n "$CURRENT_WORKTREE_PATH" ] && [ -d "$CURRENT_WORKTREE_PATH" ]; then
        log "Removing worktree: $CURRENT_WORKTREE_PATH"
        cd "$PROJECT_DIR"
        git worktree remove "$CURRENT_WORKTREE_PATH" 2>/dev/null || {
            warn "Failed to remove worktree, may need manual cleanup"
        }
        success "Cleaned up worktree (kept branch: $CURRENT_FEATURE_BRANCH)"
    fi
    cd "$PROJECT_DIR"
}

cleanup_branch_sequential() {
    :
}

# ── Prompts ──────────────────────────────────────────────────────────────

BUILD_PROMPT='
Run the /build-next command to:
1. Read .specs/roadmap.md and find the next pending feature
2. Check that all dependencies are completed
3. If a feature is ready:
   - Update roadmap to mark it 🔄 in progress
   - Run /spec-first {feature} --full to build it (includes /compound)
   - Update roadmap to mark it ✅ completed
   - Regenerate mapping: run ./scripts/generate-mapping.sh
   - Commit all changes with a descriptive message
4. If no features are ready, output: NO_FEATURES_READY
5. If build fails, output: BUILD_FAILED: {reason}

CRITICAL IMPLEMENTATION RULES (from roadmap):
- NO mock data, fake JSON, or placeholder content. All features use real DB queries and real API calls.
- NO fake API endpoints that return static JSON. Every route must do real work.
- NO placeholder UI. Components must be wired to real data sources.
- Features must work end-to-end with real user data or they are not done.
- Real validation, real error handling, real flows.

After completion, output EXACTLY these signals (each on its own line):
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to the .feature.md file you created/updated}
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or if no features are ready:
NO_FEATURES_READY

Or if build fails:
BUILD_FAILED: {reason}

The SPEC_FILE and SOURCE_FILES lines are REQUIRED when FEATURE_BUILT is reported.
They are used by the automated drift-check that runs after your build.
'

RETRY_PROMPT_TEMPLATE='
The previous build attempt FAILED. There are uncommitted changes or build errors from the last attempt.

Your job:
1. Run "git status" to understand the current state
2. Look at .specs/roadmap.md to find the feature marked 🔄 in progress
3. Fix whatever is broken — type errors, missing imports, incomplete implementation
4. Make sure the feature works end-to-end with REAL data (no mocks, no fake endpoints)
5. Commit all changes with a descriptive message
6. Update roadmap to mark the feature ✅ completed

CRITICAL: Do NOT use mock data, fake JSON, or placeholder content. All features must use real DB queries and real API calls.

After completion, output EXACTLY these signals (each on its own line):
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to the .feature.md file}
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or if build fails:
BUILD_FAILED: {reason}
'

# ── Build loop function ──────────────────────────────────────────────────
#
# run_build_loop <strategy>
#
# Runs the build loop with the given strategy. Sets these globals:
#   LOOP_BUILT, LOOP_FAILED, LOOP_SKIPPED, BUILT_FEATURE_NAMES[]
#
run_build_loop() {
    local strategy="$1"
    LOOP_BUILT=0
    LOOP_FAILED=0
    LOOP_SKIPPED=""
    LOOP_TIMINGS=()
    LAST_FEATURE_BRANCH=""
    CURRENT_FEATURE_BRANCH=""
    CURRENT_WORKTREE_PATH=""

    for i in $(seq 1 "$MAX_FEATURES"); do
        FEATURE_START=$(date +%s)
        local elapsed_so_far=$(( FEATURE_START - SCRIPT_START ))

        echo ""
        echo "═══════════════════════════════════════════════════════════"
        log "[$strategy] Build $i/$MAX_FEATURES (built: $LOOP_BUILT, failed: $LOOP_FAILED) | elapsed: $(format_duration $elapsed_so_far)"
        echo "═══════════════════════════════════════════════════════════"
        echo ""

        # ── Setup branch based on strategy ──
        case "$strategy" in
            chained)
                setup_branch_chained || { fail "Failed to setup chained branch"; continue; }
                ;;
            independent)
                setup_branch_independent || { fail "Failed to setup independent worktree"; continue; }
                ;;
            sequential)
                setup_branch_sequential
                ;;
        esac

        # ── Pre-flight: ensure working tree is clean ──
        clean_working_tree

        # ── Build attempt ──
        local attempt=0
        local feature_done=false

        while [ "$attempt" -le "$MAX_RETRIES" ]; do
            if [ "$attempt" -gt 0 ]; then
                echo ""
                warn "Retry $attempt/$MAX_RETRIES"
                echo ""
            fi

            BUILD_OUTPUT=$(mktemp)

            if [ "$attempt" -eq 0 ]; then
                agent -p --force --output-format text "$BUILD_PROMPT" 2>&1 | tee "$BUILD_OUTPUT" || true
            else
                agent -p --force --output-format text "$RETRY_PROMPT_TEMPLATE" 2>&1 | tee "$BUILD_OUTPUT" || true
            fi

            BUILD_RESULT=$(cat "$BUILD_OUTPUT")
            rm -f "$BUILD_OUTPUT"

            # ── Check for "no features ready" ──
            if echo "$BUILD_RESULT" | grep -q "NO_FEATURES_READY"; then
                log "No more features ready to build"
                feature_done=true

                # Clean up the branch/worktree we just created (nothing to build)
                case "$strategy" in
                    chained)
                        git checkout "${LAST_FEATURE_BRANCH:-$MAIN_BRANCH}" 2>/dev/null || git checkout "$MAIN_BRANCH" 2>/dev/null || true
                        git branch -D "$CURRENT_FEATURE_BRANCH" 2>/dev/null || true
                        ;;
                    independent)
                        cleanup_branch_independent
                        ;;
                esac

                return 0  # Exit the function (all done)
            fi

            # ── Check if the agent reported success ──
            if echo "$BUILD_RESULT" | grep -q "FEATURE_BUILT"; then
                local feature_name
                feature_name=$(echo "$BUILD_RESULT" | grep "FEATURE_BUILT" | tail -1 | cut -d: -f2- | xargs)

                # Verify: did it actually commit?
                if check_working_tree_clean; then
                    # Verify: does it actually build?
                    if check_build; then
                        # Verify: spec and code are aligned (fresh agent)
                        extract_drift_targets "$BUILD_RESULT"
                        if check_drift "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES"; then
                            LOOP_BUILT=$((LOOP_BUILT + 1))
                            local feature_end=$(date +%s)
                            local feature_duration=$((feature_end - FEATURE_START))
                            success "Feature $LOOP_BUILT built: $feature_name ($(format_duration $feature_duration))"
                            LOOP_TIMINGS+=("✓ $feature_name: $(format_duration $feature_duration)")
                            feature_done=true

                            # Track feature name for 'both' mode
                            BUILT_FEATURE_NAMES+=("$feature_name")

                            break
                        else
                            warn "Agent said FEATURE_BUILT but drift check failed"
                        fi
                    else
                        warn "Agent said FEATURE_BUILT but build check failed"
                    fi
                else
                    warn "Agent said FEATURE_BUILT but left uncommitted changes"
                fi
            fi

            # ── If we get here, the attempt failed ──
            if echo "$BUILD_RESULT" | grep -q "BUILD_FAILED"; then
                local reason
                reason=$(echo "$BUILD_RESULT" | grep "BUILD_FAILED" | tail -1 | cut -d: -f2-)
                warn "Build failed:$reason"
            else
                warn "Build did not produce a clear success signal"
            fi

            attempt=$((attempt + 1))
        done

        # ── Post-build: cleanup branch ──
        if [ "$feature_done" = true ]; then
            case "$strategy" in
                chained)    cleanup_branch_chained ;;
                independent) cleanup_branch_independent ;;
                sequential)  cleanup_branch_sequential ;;
            esac
        else
            # Feature failed
            LOOP_FAILED=$((LOOP_FAILED + 1))
            local feature_end=$(date +%s)
            local feature_duration=$((feature_end - FEATURE_START))
            LOOP_SKIPPED="${LOOP_SKIPPED}\n  - feature $i ($(format_duration $feature_duration))"
            LOOP_TIMINGS+=("✗ feature $i: $(format_duration $feature_duration)")
            fail "Feature failed after $((MAX_RETRIES + 1)) attempt(s). Skipping. ($(format_duration $feature_duration))"
            clean_working_tree

            case "$strategy" in
                chained)
                    warn "Feature failed, next feature will branch from $MAIN_BRANCH"
                    LAST_FEATURE_BRANCH=""
                    git checkout "$MAIN_BRANCH" 2>/dev/null || true
                    git branch -D "$CURRENT_FEATURE_BRANCH" 2>/dev/null || true
                    ;;
                independent)
                    cleanup_branch_independent
                    ;;
                sequential)
                    cleanup_branch_sequential
                    ;;
            esac
        fi
    done
}

# ── Clean up worktrees helper ────────────────────────────────────────────

cleanup_all_worktrees() {
    if [ -d "$PROJECT_DIR/.build-worktrees" ]; then
        log "Cleaning up remaining worktrees..."
        for wt in "$PROJECT_DIR/.build-worktrees"/*; do
            if [ -d "$wt" ]; then
                git worktree remove "$wt" 2>/dev/null || true
            fi
        done
        rmdir "$PROJECT_DIR/.build-worktrees" 2>/dev/null || true
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────

echo ""
echo "Build loop (local only, no remote/push/PR)"
echo "Branch strategy: $BRANCH_STRATEGY"
echo "Max features: $MAX_FEATURES | Max retries per feature: $MAX_RETRIES"
if [ -n "$BUILD_CMD" ]; then
    echo "Build check: $BUILD_CMD"
else
    echo "Build check: disabled (set BUILD_CHECK_CMD to enable)"
fi
if [ "$DRIFT_CHECK" = "true" ]; then
    echo "Drift check: enabled (max retries: $MAX_DRIFT_RETRIES)"
else
    echo "Drift check: disabled (set DRIFT_CHECK=true to enable)"
fi
echo ""

# Track feature names across passes (used by 'both' mode)
BUILT_FEATURE_NAMES=()

if [ "$BRANCH_STRATEGY" = "both" ]; then
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # BOTH MODE: Run chained first, then independent
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  PASS 1 of 2: CHAINED                                   ║"
    echo "║  Building all features sequentially (each has deps)      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    run_build_loop "chained"
    CHAINED_BUILT=$LOOP_BUILT
    CHAINED_FAILED=$LOOP_FAILED
    CHAINED_SKIPPED="$LOOP_SKIPPED"
    CHAINED_TIMINGS=("${LOOP_TIMINGS[@]}")
    CHAINED_LAST_BRANCH="$LAST_FEATURE_BRANCH"
    CHAINED_FEATURE_NAMES=("${BUILT_FEATURE_NAMES[@]}")

    success "Chained pass complete: $CHAINED_BUILT built, $CHAINED_FAILED failed"

    if [ "$CHAINED_BUILT" -eq 0 ]; then
        warn "No features were built in chained pass. Skipping independent pass."
    else
        # Go back to main for independent pass
        cd "$PROJECT_DIR"
        git checkout "$MAIN_BRANCH" 2>/dev/null || true

        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║  PASS 2 of 2: INDEPENDENT                               ║"
        echo "║  Rebuilding each feature from $MAIN_BRANCH (isolated)    ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        echo ""
        log "Features to rebuild independently: ${#CHAINED_FEATURE_NAMES[@]}"
        for fn in "${CHAINED_FEATURE_NAMES[@]}"; do
            log "  - $fn"
        done
        echo ""

        INDEPENDENT_BUILT=0
        INDEPENDENT_FAILED=0

        INDEPENDENT_TIMINGS=()

        for fn in "${CHAINED_FEATURE_NAMES[@]}"; do
            INDEP_FEATURE_START=$(date +%s)
            local elapsed_so_far=$(( INDEP_FEATURE_START - SCRIPT_START ))

            echo ""
            echo "═══════════════════════════════════════════════════════════"
            log "[independent] Building: $fn | elapsed: $(format_duration $elapsed_so_far)"
            echo "═══════════════════════════════════════════════════════════"
            echo ""

            # Create a worktree from main for this feature
            worktree_name="independent-$(echo "$fn" | tr ' :/' '-' | tr '[:upper:]' '[:lower:]')-$(date +%H%M%S)"
            worktree_path="$PROJECT_DIR/.build-worktrees/$worktree_name"
            branch_name="auto/independent-$(echo "$fn" | tr ' :/' '-' | tr '[:upper:]' '[:lower:]')"

            mkdir -p "$(dirname "$worktree_path")"

            # Remove branch if it already exists (from a previous run)
            git branch -D "$branch_name" 2>/dev/null || true

            git worktree add -b "$branch_name" "$worktree_path" "$MAIN_BRANCH" 2>/dev/null || {
                fail "Failed to create worktree for: $fn"
                INDEPENDENT_FAILED=$((INDEPENDENT_FAILED + 1))
                continue
            }

            success "Created worktree: $worktree_path (branch: $branch_name)"

            cd "$worktree_path"

            INDEP_PROMPT="
Build the feature: $fn

Instructions:
1. Run /spec-first $fn --full to build this feature from scratch
2. This is an independent build from $MAIN_BRANCH — do not assume other features exist
3. Create the spec, write tests, implement, and commit
4. Regenerate mapping: run ./scripts/generate-mapping.sh
5. Commit all changes with a descriptive message

CRITICAL IMPLEMENTATION RULES:
- NO mock data, fake JSON, or placeholder content. All features use real DB queries and real API calls.
- NO fake API endpoints that return static JSON. Every route must do real work.
- NO placeholder UI. Components must be wired to real data sources.
- Features must work end-to-end with real user data or they are not done.
- Real validation, real error handling, real flows.

After completion, output exactly one of:
FEATURE_BUILT: $fn
BUILD_FAILED: {reason}
"

            BUILD_OUTPUT=$(mktemp)
            agent -p --force --output-format text "$INDEP_PROMPT" 2>&1 | tee "$BUILD_OUTPUT" || true
            BUILD_RESULT=$(cat "$BUILD_OUTPUT")
            rm -f "$BUILD_OUTPUT"

            local indep_feature_end=$(date +%s)
            local indep_feature_duration=$((indep_feature_end - INDEP_FEATURE_START))

            if echo "$BUILD_RESULT" | grep -q "FEATURE_BUILT"; then
                if check_working_tree_clean; then
                    INDEPENDENT_BUILT=$((INDEPENDENT_BUILT + 1))
                    success "Independently built: $fn (branch: $branch_name) ($(format_duration $indep_feature_duration))"
                    INDEPENDENT_TIMINGS+=("✓ $fn: $(format_duration $indep_feature_duration)")
                else
                    warn "Agent said FEATURE_BUILT but left uncommitted changes ($(format_duration $indep_feature_duration))"
                    INDEPENDENT_FAILED=$((INDEPENDENT_FAILED + 1))
                    INDEPENDENT_TIMINGS+=("✗ $fn: $(format_duration $indep_feature_duration)")
                fi
            else
                warn "Independent build failed for: $fn ($(format_duration $indep_feature_duration))"
                INDEPENDENT_FAILED=$((INDEPENDENT_FAILED + 1))
                INDEPENDENT_TIMINGS+=("✗ $fn: $(format_duration $indep_feature_duration)")
            fi

            # Clean up worktree but keep the branch
            cd "$PROJECT_DIR"
            git worktree remove "$worktree_path" 2>/dev/null || {
                warn "Failed to remove worktree: $worktree_path"
            }
        done

        cleanup_all_worktrees
    fi

    # ── Final summary for both mode ──
    cd "$PROJECT_DIR"
    git checkout "$MAIN_BRANCH" 2>/dev/null || true

    local total_elapsed=$(( $(date +%s) - SCRIPT_START ))

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    success "BOTH PASSES COMPLETE (total: $(format_duration $total_elapsed))"
    echo ""
    echo "  Chained pass:      $CHAINED_BUILT built, $CHAINED_FAILED failed"
    echo "  Independent pass:  ${INDEPENDENT_BUILT:-0} built, ${INDEPENDENT_FAILED:-0} failed"
    echo ""
    if [ ${#CHAINED_TIMINGS[@]} -gt 0 ]; then
        echo "  Chained timings:"
        for t in "${CHAINED_TIMINGS[@]}"; do
            echo "    $t"
        done
        echo ""
    fi
    if [ ${#INDEPENDENT_TIMINGS[@]} -gt 0 ]; then
        echo "  Independent timings:"
        for t in "${INDEPENDENT_TIMINGS[@]}"; do
            echo "    $t"
        done
        echo ""
    fi
    if [ -n "$CHAINED_LAST_BRANCH" ]; then
        echo "  Chained branches (full app with deps):"
        echo "    Last branch: $CHAINED_LAST_BRANCH"
    fi
    if [ "${INDEPENDENT_BUILT:-0}" -gt 0 ] 2>/dev/null; then
        echo ""
        echo "  Independent branches (isolated per feature):"
        for fn in "${CHAINED_FEATURE_NAMES[@]}"; do
            branch_name="auto/independent-$(echo "$fn" | tr ' :/' '-' | tr '[:upper:]' '[:lower:]')"
            if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
                echo "    $branch_name"
            fi
        done
    fi
    if [ -n "$CHAINED_SKIPPED" ]; then
        echo ""
        warn "Skipped in chained pass:"
        echo -e "$CHAINED_SKIPPED"
    fi
    echo ""
    echo "  Total time: $(format_duration $total_elapsed)"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""

else
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # SINGLE MODE: chained, independent, or sequential
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    run_build_loop "$BRANCH_STRATEGY"

    # ── Final cleanup ──
    cd "$PROJECT_DIR"

    if [ "$BRANCH_STRATEGY" = "independent" ]; then
        cleanup_all_worktrees
    fi

    local total_elapsed=$(( $(date +%s) - SCRIPT_START ))

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    success "Done. Built: $LOOP_BUILT, Failed: $LOOP_FAILED (total: $(format_duration $total_elapsed))"
    echo ""
    if [ ${#LOOP_TIMINGS[@]} -gt 0 ]; then
        echo "  Per-feature timings:"
        for t in "${LOOP_TIMINGS[@]}"; do
            echo "    $t"
        done
        echo ""
    fi
    if [ -n "$LOOP_SKIPPED" ]; then
        warn "Skipped features (check git stash list for their partial work):"
        echo -e "$LOOP_SKIPPED"
        echo ""
    fi
    if [ "$BRANCH_STRATEGY" = "chained" ] && [ -n "$LAST_FEATURE_BRANCH" ]; then
        log "Last feature branch: $LAST_FEATURE_BRANCH"
        log "You can review/merge branches or reset to $MAIN_BRANCH"
        echo ""
    fi
    echo "  Total time: $(format_duration $total_elapsed)"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
fi
