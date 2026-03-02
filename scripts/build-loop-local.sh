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
# CONFIG: set CLI_PROVIDER, MAX_FEATURES, MAX_RETRIES, BUILD_CHECK_CMD, BRANCH_STRATEGY in .env.local
# or pass in env. Command-line env vars override .env.local (e.g. MAX_FEATURES=3 ./script).
#
# BASE_BRANCH: Branch to create feature branches from (default: current)
#   - Unset or empty: Use current branch — checkout your branch, run script, done.
#   - develop, main: Use that branch instead.
#   Workflow: git checkout my-branch && ./scripts/build-loop-local.sh
#   Examples: BASE_BRANCH=develop  BASE_BRANCH=main
#
# BRANCH_STRATEGY: How to handle branches (default: chained)
#   - chained: Each feature branches from the previous feature's branch
#              (Feature #2 has Feature #1's code even if not merged)
#   - independent: Each feature builds in a separate git worktree from BASE_BRANCH
#                  (Features are isolated, no shared code until merged)
#   - both: Run chained first (full build), then rebuild each feature
#           independently from BASE_BRANCH (sequential, not parallel)
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
# MAX_DRIFT_RETRIES: how many times to retry fixing drift (default: 2).
#   If drift is found, the drift agent auto-fixes by updating specs.
#   If the fix breaks the build, it retries up to this many times.
#
# TEST_CHECK_CMD: command to run the test suite after each feature.
#   Defaults to auto-detection (npm test, pytest, cargo test, go test, etc.)
#   Set to "skip" to disable test checking.
#   Examples:
#     TEST_CHECK_CMD="npm test"
#     TEST_CHECK_CMD="npx vitest run"
#     TEST_CHECK_CMD="pytest"
#     TEST_CHECK_CMD="cargo test"
#     TEST_CHECK_CMD="skip"
#
# POST_BUILD_STEPS: comma-separated list of extra steps after build+drift.
#   Each agent-based step runs in a FRESH context window.
#   Available steps:
#     test          - Run test suite (shell cmd, uses TEST_CHECK_CMD)
#     code-review   - Agent reviews code quality (fresh context)
#   Note: drift check is controlled separately via DRIFT_CHECK.
#   Default: "test"
#   Examples:
#     POST_BUILD_STEPS="test"                  # Just tests (default)
#     POST_BUILD_STEPS="test,code-review"      # Tests + quality review
#     POST_BUILD_STEPS=""                       # Skip all post-build steps
#
# CLI_PROVIDER: cursor (default) or claude. Use cursor for Cursor CLI (agent),
#   claude for Claude Code CLI. Model names differ per provider.
#
# MODEL SELECTION: which AI model to use for each agent invocation.
#   Each step gets its own fresh context window — choose the model per step.
#   Leave empty to use the CLI default. Run `agent --list-models` or check
#   Claude docs for model names.
#
#   AGENT_MODEL       - Default model for ALL agent steps (fallback)
#   SPEC_MODEL        - Model for spec phase (/spec-first without --full)
#   BUILD_MODEL       - Model for implement phase (tests, implement, compound, commit)
#   RETRY_MODEL       - Model for retry attempts (fixing build/test failures)
#   DRIFT_MODEL       - Model for catch-drift agent
#   REVIEW_MODEL      - Model for code-review agent
#
#   Examples:
#     SPEC_MODEL="opus-4.6-thinking"              # Opus for spec (strong at planning)
#     BUILD_MODEL="composer-1.5"                  # Cheaper model for implementation
#     DRIFT_MODEL="gemini-3-flash"                # Cheap model for drift checks
#     REVIEW_MODEL="sonnet-4.5-thinking"          # Thinking model for reviews

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

# Load .env.local but don't overwrite vars already set (command-line wins over .env.local)
if [ -f "$PROJECT_DIR/.env.local" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            [[ -n "${!key+x}" ]] && continue
            value="${BASH_REMATCH[2]}"
            value="${value%\"}"; value="${value#\"}"
            value="${value%\'}"; value="${value#\'}"
            export "$key=$value"
        fi
    done < "$PROJECT_DIR/.env.local"
fi

CLI_PROVIDER="${CLI_PROVIDER:-cursor}"
MAX_FEATURES="${MAX_FEATURES:-50}"
MAX_RETRIES="${MAX_RETRIES:-3}"
BRANCH_STRATEGY="${BRANCH_STRATEGY:-chained}"
DRIFT_CHECK="${DRIFT_CHECK:-true}"
MAX_DRIFT_RETRIES="${MAX_DRIFT_RETRIES:-2}"
POST_BUILD_STEPS="${POST_BUILD_STEPS:-test}"

# Model selection (per-step overrides with AGENT_MODEL fallback)
# Cursor CLI default; run `agent --list-models` to see available models
AGENT_MODEL="${AGENT_MODEL:-composer-1.5}"
SPEC_MODEL="${SPEC_MODEL:-}"
BUILD_MODEL="${BUILD_MODEL:-}"
RETRY_MODEL="${RETRY_MODEL:-}"
DRIFT_MODEL="${DRIFT_MODEL:-}"
REVIEW_MODEL="${REVIEW_MODEL:-}"

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

# Get base branch (sync target and branch-from target)
# BASE_BRANCH: explicit (e.g. develop, main); unset = current branch
if [ -n "$BASE_BRANCH" ]; then
    if git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
        MAIN_BRANCH="$BASE_BRANCH"
    else
        echo "Error: BASE_BRANCH=$BASE_BRANCH does not exist"
        exit 1
    fi
else
    MAIN_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    if [ -z "$MAIN_BRANCH" ]; then
        MAIN_BRANCH="main"
    fi
fi

if [ "$CLI_PROVIDER" = "claude" ]; then
    command -v claude &>/dev/null || { fail "Claude Code CLI not found. Install from: https://code.claude.com"; exit 1; }
else
    command -v agent &>/dev/null || { fail "Cursor CLI (agent) not found. Install from: https://cursor.com/cli"; exit 1; }
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

# ── Auto-detect test check command ────────────────────────────────────────

detect_test_check() {
    if [ -n "$TEST_CHECK_CMD" ]; then
        if [ "$TEST_CHECK_CMD" = "skip" ]; then echo ""; else echo "$TEST_CHECK_CMD"; fi
        return
    fi
    if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
        if ! grep -q "no test specified" package.json 2>/dev/null; then echo "npm test"; return; fi
    fi
    if [ -f "pytest.ini" ] || [ -f "conftest.py" ]; then echo "pytest"; return; fi
    if [ -f "pyproject.toml" ] && grep -q "pytest" "pyproject.toml" 2>/dev/null; then echo "pytest"; return; fi
    if [ -f "Cargo.toml" ]; then echo "cargo test"; return; fi
    if [ -f "go.mod" ]; then echo "go test ./..."; return; fi
    echo ""
}

TEST_CMD=$(detect_test_check)

# ── Agent runner (supports Cursor CLI and Claude Code) ─────────────────────

run_agent() {
    local step_model="$1"
    local prompt="$2"
    local model="${step_model:-$AGENT_MODEL}"

    if [ "$CLI_PROVIDER" = "claude" ]; then
        if [ -n "$model" ]; then
            claude -p "$prompt" --output-format text --allowedTools Read,Edit,Bash,Grep,Glob --model "$model"
        else
            claude -p "$prompt" --output-format text --allowedTools Read,Edit,Bash,Grep,Glob
        fi
    else
        if [ -n "$model" ]; then
            agent -p --force --output-format text --model "$model" "$prompt"
        else
            agent -p --force --output-format text "$prompt"
        fi
    fi
}

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

LAST_BUILD_OUTPUT=""
LAST_TEST_OUTPUT=""

check_build() {
    if [ -z "$BUILD_CMD" ]; then
        log "No build check configured (set BUILD_CHECK_CMD to enable)"
        return 0
    fi
    log "Running build check: $BUILD_CMD"
    local tmpfile
    tmpfile=$(mktemp)
    eval "$BUILD_CMD" 2>&1 | tee "$tmpfile"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        success "Build check passed"
        LAST_BUILD_OUTPUT=""
    else
        LAST_BUILD_OUTPUT=$(tail -50 "$tmpfile")
        fail "Build check failed"
    fi
    rm -f "$tmpfile"
    return $exit_code
}

check_tests() {
    if [ -z "$TEST_CMD" ]; then
        log "No test suite configured (set TEST_CHECK_CMD to enable)"
        return 0
    fi
    log "Running test suite: $TEST_CMD"
    local tmpfile
    tmpfile=$(mktemp)
    eval "$TEST_CMD" 2>&1 | tee "$tmpfile"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        success "Tests passed"
        LAST_TEST_OUTPUT=""
    else
        LAST_TEST_OUTPUT=$(tail -80 "$tmpfile")
        fail "Tests failed"
    fi
    rm -f "$tmpfile"
    return $exit_code
}

should_run_step() {
    echo ",$POST_BUILD_STEPS," | grep -q ",$1,"
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

        local test_context=""
        if [ -n "$TEST_CMD" ]; then
            test_context="
Test command: $TEST_CMD"
        fi
        if [ -n "$LAST_TEST_OUTPUT" ]; then
            test_context="$test_context

PREVIOUS TEST FAILURE OUTPUT (last 80 lines):
$LAST_TEST_OUTPUT"
        fi

        local drift_prompt="
Run /catch-drift for this specific feature. This is an automated check — do NOT ask for user input. Auto-fix all drift by updating specs to match code (prefer documenting reality over reverting code).

Spec file: $spec_file
Source files: $source_files$test_context

Instructions:
1. Read the spec file and all its Gherkin scenarios
2. Read each source file listed above
3. Compare: does the code implement what the spec describes?
4. Check: are there behaviors in code not covered by the spec?
5. Check: are there scenarios in the spec not implemented in code?
6. If drift found: update specs, code, or tests as needed (prefer updating specs to match code)
7. Run the test suite (\`$TEST_CMD\`) and fix any failures — iterate until tests pass
8. Commit all fixes with message: 'fix: reconcile spec drift for {feature}'

IMPORTANT: Your goal is spec+code alignment AND a passing test suite. Keep iterating until both are achieved.

Output EXACTLY ONE of these signals at the end:
NO_DRIFT
DRIFT_FIXED: {brief summary of what was reconciled}
DRIFT_UNRESOLVABLE: {what needs human attention and why}
"
        run_agent "$DRIFT_MODEL" "$drift_prompt" 2>&1 | tee "$DRIFT_OUTPUT" || true
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
            # Verify the fix didn't break build or tests
            if ! check_build; then
                warn "Drift fix broke the build — retrying"
            elif should_run_step "test" && [ -n "$TEST_CMD" ] && ! check_tests; then
                warn "Drift fix broke tests — retrying"
            else
                return 0
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

# ── Code review (fresh agent) ────────────────────────────────────────────

run_code_review() {
    log "Running code-review agent (fresh context, model: ${REVIEW_MODEL:-${AGENT_MODEL:-default}})..."
    local REVIEW_OUTPUT
    REVIEW_OUTPUT=$(mktemp)

    local test_context=""
    if [ -n "$TEST_CMD" ]; then
        test_context="
Test command: $TEST_CMD"
    fi

    local review_prompt="
Review and improve the code quality of the most recently built feature.
$test_context

Steps:
1. Check 'git log --oneline -10' to see recent commits
2. Identify source files for the most recent feature (look at git diff of recent commits)
3. Review against senior engineering standards:
   - TypeScript: No 'any' types, proper utility types, explicit return types
   - Async: Proper error handling, no await-in-forEach, correct Promise patterns
   - React: Complete useEffect deps, proper cleanup, no state mutation
   - Architecture: Proper abstraction, no library leaking, DRY
   - Security: Input validation, XSS prevention
4. Fix critical and high-severity issues ONLY
5. Do NOT change feature behavior
6. Do NOT refactor working code for style preferences
7. Run the test suite (\`$TEST_CMD\`) after your changes — iterate until tests pass
8. Commit fixes if any: git add -A && git commit -m 'refactor: code quality improvements (auto-review)'

IMPORTANT: Do not introduce test regressions. Run tests after every change and fix anything you break.

After completion, output exactly one of:
REVIEW_CLEAN
REVIEW_FIXED: {summary}
REVIEW_FAILED: {reason}
"
    run_agent "$REVIEW_MODEL" "$review_prompt" 2>&1 | tee "$REVIEW_OUTPUT" || true

    local REVIEW_RESULT
    REVIEW_RESULT=$(cat "$REVIEW_OUTPUT")
    rm -f "$REVIEW_OUTPUT"

    if echo "$REVIEW_RESULT" | grep -q "REVIEW_CLEAN\|REVIEW_FIXED"; then
        success "Code review complete"
        if ! check_working_tree_clean; then
            git add -A && git commit -m "refactor: code quality improvements (auto-review)" 2>/dev/null || true
        fi
        return 0
    else
        warn "Code review reported issues it couldn't fix"
        if ! check_working_tree_clean; then
            git add -A && git commit -m "refactor: partial code quality fixes (auto-review)" 2>/dev/null || true
        fi
        return 1
    fi
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

# Phase 1: Spec only (no --full). Uses SPEC_MODEL.
SPEC_PROMPT='
Run the /build-next command to find the next feature, then create the spec ONLY:

1. Read .specs/roadmap.md and find the next pending feature
2. Check that all dependencies are completed
3. If a feature is ready:
   - Update roadmap to mark it 🔄 in progress
   - Run /spec-first {feature} (WITHOUT --full) — create or update the spec only, do NOT implement
   - Do NOT write tests, do NOT implement, do NOT commit yet
   - Regenerate mapping: run ./scripts/generate-mapping.sh
4. If no features are ready, output: NO_FEATURES_READY
5. If spec fails, output: SPEC_FAILED: {reason}

After completion, output EXACTLY these signals (each on its own line):
FEATURE_SPEC_READY: {feature name}
SPEC_FILE: {path to the .feature.md file you created/updated}

Or if no features are ready:
NO_FEATURES_READY

Or if spec fails:
SPEC_FAILED: {reason}

The SPEC_FILE line is REQUIRED when FEATURE_SPEC_READY is reported.
'

# Phase 2: Implement from spec. Uses BUILD_MODEL.
# Called with: implement_prompt "$feature_name" "$spec_file"
implement_prompt() {
    local feature_name="$1"
    local spec_file="$2"
    echo "
The spec for \"$feature_name\" exists at $spec_file. Implement it through the full TDD cycle:

1. Read the spec file and all its Gherkin scenarios
2. Write failing tests covering ALL scenarios
3. Implement until all tests pass
4. Run /compound to extract learnings
5. Regenerate mapping: run ./scripts/generate-mapping.sh
6. Update roadmap to mark the feature ✅ completed
7. Commit all changes with a descriptive message

CRITICAL IMPLEMENTATION RULES (from roadmap):
- NO mock data, fake JSON, or placeholder content. All features use real DB queries and real API calls.
- NO fake API endpoints that return static JSON. Every route must do real work.
- NO placeholder UI. Components must be wired to real data sources.
- Features must work end-to-end with real user data or they are not done.
- Real validation, real error handling, real flows.

After completion, output EXACTLY these signals (each on its own line):
FEATURE_BUILT: $feature_name
SPEC_FILE: $spec_file
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or if build fails:
BUILD_FAILED: {reason}

The SPEC_FILE and SOURCE_FILES lines are REQUIRED when FEATURE_BUILT is reported.
They are used by the automated drift-check that runs after your build.
"
}

build_retry_prompt() {
    local prompt='The previous attempt FAILED (spec phase or implement phase). There are uncommitted changes or errors.

Your job:
1. Run "git status" to understand the current state
2. Look at .specs/roadmap.md to find the feature marked 🔄 in progress
3. If the spec is missing or incomplete: run /spec-first {feature} (without --full) to create/update it
4. If the spec exists: fix the implementation — type errors, missing imports, incomplete code, failing tests
5. Complete the full TDD cycle: tests, implement until pass, /compound, commit
6. Make sure the feature works end-to-end with REAL data (no mocks, no fake endpoints)
7. Run the test suite to verify everything passes: '"$TEST_CMD"'
8. Update roadmap to mark the feature ✅ completed

CRITICAL: Do NOT use mock data, fake JSON, or placeholder content. All features must use real DB queries and real API calls.
'

    # Append failure context if available
    if [ -n "$LAST_BUILD_OUTPUT" ]; then
        prompt="$prompt
BUILD CHECK FAILURE OUTPUT (last 50 lines):
$LAST_BUILD_OUTPUT
"
    fi

    if [ -n "$LAST_TEST_OUTPUT" ]; then
        prompt="$prompt
TEST SUITE FAILURE OUTPUT (last 80 lines):
$LAST_TEST_OUTPUT
"
    fi

    prompt="$prompt
After completion, output EXACTLY these signals (each on its own line):
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to the .feature.md file}
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or if build fails:
BUILD_FAILED: {reason}
"
    echo "$prompt"
}

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
                # ── Phase 1: Spec only (SPEC_MODEL) ──
                log "Phase 1: Spec (model: ${SPEC_MODEL:-${AGENT_MODEL:-default}})"
                run_agent "$SPEC_MODEL" "$SPEC_PROMPT" 2>&1 | tee "$BUILD_OUTPUT" || true
                SPEC_RESULT=$(cat "$BUILD_OUTPUT")

                # Check for no features ready (exit loop)
                if echo "$SPEC_RESULT" | grep -q "NO_FEATURES_READY"; then
                    BUILD_RESULT="$SPEC_RESULT"
                    rm -f "$BUILD_OUTPUT"
                    # Fall through to NO_FEATURES_READY handling below
                elif echo "$SPEC_RESULT" | grep -q "FEATURE_SPEC_READY"; then
                    # ── Phase 2: Implement (BUILD_MODEL) ──
                    FEATURE_FOR_IMPL=$(echo "$SPEC_RESULT" | grep "FEATURE_SPEC_READY" | tail -1 | cut -d: -f2- | xargs)
                    SPEC_FILE_FOR_IMPL=$(echo "$SPEC_RESULT" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | xargs)
                    log "Phase 2: Implement (model: ${BUILD_MODEL:-${AGENT_MODEL:-default}}) — $FEATURE_FOR_IMPL"
                    run_agent "$BUILD_MODEL" "$(implement_prompt "$FEATURE_FOR_IMPL" "$SPEC_FILE_FOR_IMPL")" 2>&1 | tee "$BUILD_OUTPUT" || true
                    BUILD_RESULT=$(cat "$BUILD_OUTPUT")
                    rm -f "$BUILD_OUTPUT"
                else
                    # SPEC_FAILED or unclear — use as BUILD_RESULT for retry logic
                    BUILD_RESULT="$SPEC_RESULT"
                    rm -f "$BUILD_OUTPUT"
                fi
            else
                run_agent "$RETRY_MODEL" "$(build_retry_prompt)" 2>&1 | tee "$BUILD_OUTPUT" || true
                BUILD_RESULT=$(cat "$BUILD_OUTPUT")
                rm -f "$BUILD_OUTPUT"
            fi

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
                        # Verify: do tests pass?
                        if ! should_run_step "test" || check_tests; then
                            # Verify: spec and code are aligned (fresh agent)
                            extract_drift_targets "$BUILD_RESULT"
                            if check_drift "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES"; then
                                # Optional: code review (fresh agent)
                                if should_run_step "code-review"; then
                                    run_code_review || warn "Code review had issues (non-blocking)"
                                    # Re-validate after review changes
                                    if ! check_build; then
                                        warn "Code review broke the build!"
                                    elif should_run_step "test" && [ -n "$TEST_CMD" ] && ! check_tests; then
                                        warn "Code review broke tests!"
                                    fi
                                fi

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
                            warn "Agent said FEATURE_BUILT but tests failed"
                        fi
                    else
                        warn "Agent said FEATURE_BUILT but build check failed"
                    fi
                else
                    warn "Agent said FEATURE_BUILT but left uncommitted changes"
                fi
            fi

            # ── If we get here, the attempt failed ──
            if echo "$BUILD_RESULT" | grep -q "SPEC_FAILED"; then
                local reason
                reason=$(echo "$BUILD_RESULT" | grep "SPEC_FAILED" | tail -1 | cut -d: -f2-)
                warn "Spec phase failed:$reason"
            elif echo "$BUILD_RESULT" | grep -q "BUILD_FAILED"; then
                local reason
                reason=$(echo "$BUILD_RESULT" | grep "BUILD_FAILED" | tail -1 | cut -d: -f2-)
                warn "Implement phase failed:$reason"
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
                    # Keep LAST_FEATURE_BRANCH so next feature branches from last successful, not base
                    warn "Feature failed, next feature will branch from last successful: ${LAST_FEATURE_BRANCH:-$MAIN_BRANCH}"
                    git checkout "${LAST_FEATURE_BRANCH:-$MAIN_BRANCH}" 2>/dev/null || git checkout "$MAIN_BRANCH" 2>/dev/null || true
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
echo "CLI provider: $CLI_PROVIDER"
echo "Base branch: $MAIN_BRANCH"
echo "Branch strategy: $BRANCH_STRATEGY"
echo "Max features: $MAX_FEATURES | Max retries per feature: $MAX_RETRIES"
if [ -n "$BUILD_CMD" ]; then
    echo "Build check: $BUILD_CMD"
else
    echo "Build check: disabled (set BUILD_CHECK_CMD to enable)"
fi
if [ -n "$TEST_CMD" ]; then
    echo "Test suite: $TEST_CMD"
else
    echo "Test suite: disabled (set TEST_CHECK_CMD to enable)"
fi
if [ "$DRIFT_CHECK" = "true" ]; then
    echo "Drift check: enabled (max retries: $MAX_DRIFT_RETRIES)"
else
    echo "Drift check: disabled (set DRIFT_CHECK=true to enable)"
fi
echo "Post-build steps: ${POST_BUILD_STEPS:-none}"
if [ -n "$AGENT_MODEL" ] || [ -n "$SPEC_MODEL" ] || [ -n "$BUILD_MODEL" ] || [ -n "$DRIFT_MODEL" ] || [ -n "$REVIEW_MODEL" ]; then
    echo "Models: default=${AGENT_MODEL:-CLI default} spec=${SPEC_MODEL:-↑} build=${BUILD_MODEL:-↑} drift=${DRIFT_MODEL:-↑} review=${REVIEW_MODEL:-↑}"
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

            # Independent pass: spec phase then implement phase
            INDEP_SPEC_PROMPT="
Build the spec only for feature: $fn

This is an independent build from $MAIN_BRANCH — do not assume other features exist.

1. Run /spec-first $fn (WITHOUT --full) — create or update the spec only
2. Do NOT implement yet. Regenerate mapping: run ./scripts/generate-mapping.sh

Output exactly one of:
FEATURE_SPEC_READY: $fn
SPEC_FILE: {path to .feature.md}
SPEC_FAILED: {reason}
"

            BUILD_OUTPUT=$(mktemp)
            log "[independent] Phase 1: Spec for $fn"
            run_agent "$SPEC_MODEL" "$INDEP_SPEC_PROMPT" 2>&1 | tee "$BUILD_OUTPUT" || true
            INDEP_SPEC_RESULT=$(cat "$BUILD_OUTPUT")

            if echo "$INDEP_SPEC_RESULT" | grep -q "FEATURE_SPEC_READY"; then
                INDEP_SPEC_FILE=$(echo "$INDEP_SPEC_RESULT" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | xargs)
                log "[independent] Phase 2: Implement $fn"
                run_agent "$BUILD_MODEL" "$(implement_prompt "$fn" "${INDEP_SPEC_FILE:-.specs/features/unknown.feature.md}")" 2>&1 | tee "$BUILD_OUTPUT" || true
            else
                echo "$INDEP_SPEC_RESULT" > "$BUILD_OUTPUT"
            fi
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
