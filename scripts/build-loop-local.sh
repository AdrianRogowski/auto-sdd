#!/bin/bash
# build-loop-local.sh
# Run /build-next in a loop locally. No git remote, no push, no PRs.
# Use when you want to build roadmap features without connecting to a remote.
#
# Usage:
#   ./scripts/build-loop-local.sh
#   MAX_FEATURES=5 ./scripts/build-loop-local.sh
#
# CONFIG: set MAX_FEATURES, MAX_RETRIES, BUILD_CHECK_CMD in .env.local
# or pass in env.
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

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -f "$PROJECT_DIR/.env.local" ]; then
    source "$PROJECT_DIR/.env.local"
fi

MAX_FEATURES="${MAX_FEATURES:-25}"
MAX_RETRIES="${MAX_RETRIES:-1}"

log() { echo "[$(date '+%H:%M:%S')] $1"; }
success() { echo "[$(date '+%H:%M:%S')] ✓ $1"; }
warn() { echo "[$(date '+%H:%M:%S')] ⚠ $1"; }
fail() { echo "[$(date '+%H:%M:%S')] ✗ $1"; }

cd "$PROJECT_DIR"

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

# ── Main prompt (shared by build and retry) ──────────────────────────────

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

After completion, output exactly one of:
FEATURE_BUILT: {feature name}
NO_FEATURES_READY
BUILD_FAILED: {reason}
'

# ── Loop ─────────────────────────────────────────────────────────────────

echo ""
echo "Build loop (local only, no remote/push/PR)"
echo "Max features: $MAX_FEATURES | Max retries per feature: $MAX_RETRIES"
if [ -n "$BUILD_CMD" ]; then
    echo "Build check: $BUILD_CMD"
else
    echo "Build check: disabled (set BUILD_CHECK_CMD to enable)"
fi
echo ""

BUILT=0
FAILED=0
SKIPPED_FEATURES=""

for i in $(seq 1 "$MAX_FEATURES"); do
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    log "Build $i/$MAX_FEATURES (built: $BUILT, failed: $FAILED)"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # ── Pre-flight: ensure working tree is clean ──
    clean_working_tree

    # ── Build attempt ──
    ATTEMPT=0
    FEATURE_DONE=false

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        if [ "$ATTEMPT" -gt 0 ]; then
            echo ""
            warn "Retry $ATTEMPT/$MAX_RETRIES for feature $i"
            echo ""
        fi

        BUILD_OUTPUT=$(mktemp)

        if [ "$ATTEMPT" -eq 0 ]; then
            # First attempt: normal build
            agent -p --force --output-format text "$BUILD_PROMPT" 2>&1 | tee "$BUILD_OUTPUT" || true
        else
            # Retry: give the agent context about the failure
            RETRY_PROMPT="
The previous build attempt FAILED. There are uncommitted changes or build errors from the last attempt.

Your job:
1. Run 'git status' to understand the current state
2. Look at .specs/roadmap.md to find the feature marked 🔄 in progress
3. Fix whatever is broken — type errors, missing imports, incomplete implementation
4. Make sure the feature works end-to-end with REAL data (no mocks, no fake endpoints)
5. Commit all changes with a descriptive message
6. Update roadmap to mark the feature ✅ completed

CRITICAL: Do NOT use mock data, fake JSON, or placeholder content. All features must use real DB queries and real API calls.

After completion, output exactly one of:
FEATURE_BUILT: {feature name}
BUILD_FAILED: {reason}
"
            agent -p --force --output-format text "$RETRY_PROMPT" 2>&1 | tee "$BUILD_OUTPUT" || true
        fi

        BUILD_RESULT=$(cat "$BUILD_OUTPUT")
        rm -f "$BUILD_OUTPUT"

        # ── Check for "no features ready" ──
        if echo "$BUILD_RESULT" | grep -q "NO_FEATURES_READY"; then
            log "No more features ready to build"
            FEATURE_DONE=true
            break 2  # break out of both loops
        fi

        # ── Check if the agent reported success ──
        if echo "$BUILD_RESULT" | grep -q "FEATURE_BUILT"; then
            FEATURE_NAME=$(echo "$BUILD_RESULT" | grep "FEATURE_BUILT" | tail -1 | cut -d: -f2-)

            # Verify: did it actually commit?
            if check_working_tree_clean; then
                # Verify: does it actually build?
                if check_build; then
                    BUILT=$((BUILT + 1))
                    success "Feature $BUILT built:$FEATURE_NAME"
                    FEATURE_DONE=true
                    break
                else
                    warn "Agent said FEATURE_BUILT but build check failed"
                fi
            else
                warn "Agent said FEATURE_BUILT but left uncommitted changes"
            fi
        fi

        # ── If we get here, the attempt failed ──
        if echo "$BUILD_RESULT" | grep -q "BUILD_FAILED"; then
            REASON=$(echo "$BUILD_RESULT" | grep "BUILD_FAILED" | tail -1 | cut -d: -f2-)
            warn "Build failed:$REASON"
        else
            warn "Build did not produce a clear success signal"
        fi

        ATTEMPT=$((ATTEMPT + 1))
    done

    # ── If all retries exhausted, log failure and continue ──
    if [ "$FEATURE_DONE" = false ]; then
        FAILED=$((FAILED + 1))
        FEATURE_TAG="feature $i"
        SKIPPED_FEATURES="${SKIPPED_FEATURES}\n  - ${FEATURE_TAG}"
        fail "Feature failed after $((MAX_RETRIES + 1)) attempt(s). Skipping to next feature."
        # Clean up so next feature starts fresh
        clean_working_tree
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════"
success "Done. Built: $BUILT, Failed: $FAILED"
if [ -n "$SKIPPED_FEATURES" ]; then
    echo ""
    warn "Skipped features (check git stash list for their partial work):"
    echo -e "$SKIPPED_FEATURES"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
