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
# LINT_CHECK_CMD: command to run lint checks after each feature.
#   Defaults to auto-detection (npm run lint, ruff check, cargo clippy, etc.)
#   Lint failures are non-blocking (warns but doesn't retry).
#   Set to "skip" to disable lint checking.
#   Examples:
#     LINT_CHECK_CMD="npm run lint"
#     LINT_CHECK_CMD="pnpm lint"
#     LINT_CHECK_CMD="ruff check ."
#     LINT_CHECK_CMD="skip"
#
# MIGRATION_CMD: command to apply database migrations after schema changes.
#   Defaults to auto-detection (drizzle-kit push, prisma db push, alembic upgrade, etc.)
#   Only runs when schema files change (detected via git diff).
#   Migration failures are non-blocking (warns — database may not be available).
#   Set to "skip" to disable migration.
#   Examples:
#     MIGRATION_CMD="npm run db:push"
#     MIGRATION_CMD="npx drizzle-kit push"
#     MIGRATION_CMD="npx prisma db push"
#     MIGRATION_CMD="alembic upgrade head"
#     MIGRATION_CMD="skip"
#
# E2E_CHECK_CMD: command to run end-to-end tests after each feature.
#   Defaults to auto-detection (playwright, cypress).
#   Runs after drift check (most expensive, needs final code).
#   E2E failures are non-blocking (warns but doesn't retry).
#   Set to "skip" to disable e2e testing.
#   Examples:
#     E2E_CHECK_CMD="npx playwright test"
#     E2E_CHECK_CMD="npx cypress run"
#     E2E_CHECK_CMD="skip"
#
# LAZY RE-DETECTION: All check commands are re-detected after each feature
#   if they are empty. This handles greenfield projects where Feature 1 creates
#   the project infrastructure (package.json, tsconfig, etc.) that didn't exist
#   at script startup. Newly detected commands are persisted back to .env.local.
#
# POST_BUILD_STEPS: comma-separated list of extra steps after build+drift.
#   Each agent-based step runs in a FRESH context window.
#   Available steps:
#     test          - Run test suite (shell cmd, uses TEST_CHECK_CMD)
#     code-review   - Agent reviews code quality (fresh context)
#   Note: drift check is controlled separately via DRIFT_CHECK.
#   Note: refactor and compound are always-on phases (not optional steps).
#   Default: "test"
#   Examples:
#     POST_BUILD_STEPS="test"                  # Just tests (default)
#     POST_BUILD_STEPS="test,code-review"      # Tests + quality review
#     POST_BUILD_STEPS=""                       # Skip all post-build steps
#
# REFACTOR: whether to run the refactor phase after build+test.
#   Defaults to "true". Set to "false" to skip.
#
# COMPOUND: whether to run the compound (learnings) phase after drift check.
#   Defaults to "true". Set to "false" to skip.
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
#   BUILD_MODEL       - Model for implement phase (tests, implement, commit)
#   REFACTOR_MODEL    - Model for refactor phase (clean up code, tests must pass)
#   RETRY_MODEL       - Model for retry attempts (fixing build/test failures)
#   DRIFT_MODEL       - Model for catch-drift agent
#   COMPOUND_MODEL    - Model for compound/learnings agent
#   REVIEW_MODEL      - Model for code-review agent
#
#   Examples:
#     SPEC_MODEL="opus-4.6-thinking"              # Opus for spec (strong at planning)
#     BUILD_MODEL="composer-1.5"                  # Cheaper model for implementation
#     REFACTOR_MODEL="opus-4.6-thinking"          # Strong model for refactoring
#     DRIFT_MODEL="gemini-3-flash"                # Cheap model for drift checks
#     COMPOUND_MODEL="gemini-3-flash"             # Cheap model for learnings
#     REVIEW_MODEL="sonnet-4.5-thinking"          # Thinking model for reviews
#
# TRANSIENT ERROR HANDLING (rate limits + network errors):
#   RATE_LIMIT_BACKOFF    - Initial wait in seconds when error detected (default: 60)
#   RATE_LIMIT_MAX_WAIT   - Max wait in seconds before giving up (default: 18000 = 5h)
#   Retries on: rate limits (429, overloaded, capacity), network errors
#   (connection reset, ECONNRESET, ETIMEDOUT, socket hang up, fetch failed, etc.)
#
# IN-PROGRESS RESUME:
#   If a feature is marked 🔄 in the roadmap (from a previous interrupted run),
#   the loop will resume that feature before picking up the next ⬜ pending one.

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
            # Handle quoted values (strip quotes, ignore anything after closing quote)
            if [[ "$value" =~ ^\"([^\"]*)\" ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ "$value" =~ ^\'([^\']*)\' ]]; then
                value="${BASH_REMATCH[1]}"
            else
                # Unquoted: strip inline comments and trailing whitespace
                value="${value%%#*}"
                value="${value%"${value##*[![:space:]]}"}"
            fi
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
REFACTOR="${REFACTOR:-true}"
COMPOUND="${COMPOUND:-true}"

# Model selection (per-step overrides with AGENT_MODEL fallback)
# Cursor CLI default; run `agent --list-models` to see available models
AGENT_MODEL="${AGENT_MODEL:-composer-1.5}"
SPEC_MODEL="${SPEC_MODEL:-}"
BUILD_MODEL="${BUILD_MODEL:-}"
REFACTOR_MODEL="${REFACTOR_MODEL:-}"
RETRY_MODEL="${RETRY_MODEL:-}"
DRIFT_MODEL="${DRIFT_MODEL:-}"
COMPOUND_MODEL="${COMPOUND_MODEL:-}"
REVIEW_MODEL="${REVIEW_MODEL:-}"

# Rate limit handling
RATE_LIMIT_BACKOFF="${RATE_LIMIT_BACKOFF:-60}"
RATE_LIMIT_MAX_WAIT="${RATE_LIMIT_MAX_WAIT:-18000}"

log() { echo "[$(date '+%H:%M:%S')] $1"; }
success() { echo "[$(date '+%H:%M:%S')] ✓ $1"; }
warn() { echo "[$(date '+%H:%M:%S')] ⚠ $1"; }
fail() { echo "[$(date '+%H:%M:%S')] ✗ $1"; }
trim() { sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

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

# ── Auto-detect lint check command ──────────────────────────────────────────

detect_lint_check() {
    if [ -n "$LINT_CHECK_CMD" ]; then
        if [ "$LINT_CHECK_CMD" = "skip" ]; then echo ""; else echo "$LINT_CHECK_CMD"; fi
        return
    fi
    if [ -f "package.json" ] && grep -q '"lint"' package.json 2>/dev/null; then
        echo "npm run lint"; return
    fi
    if command -v ruff &>/dev/null && { [ -f "pyproject.toml" ] || [ -f "ruff.toml" ]; }; then
        echo "ruff check ."; return
    fi
    if [ -f "Cargo.toml" ]; then echo "cargo clippy -- -D warnings 2>/dev/null || true"; return; fi
    echo ""
}

LINT_CMD=$(detect_lint_check)

# ── Auto-detect migration command ───────────────────────────────────────────

detect_migration_cmd() {
    if [ -n "$MIGRATION_CMD" ]; then
        if [ "$MIGRATION_CMD" = "skip" ]; then echo ""; else echo "$MIGRATION_CMD"; fi
        return
    fi
    # Drizzle
    if [ -f "drizzle.config.ts" ] || [ -f "drizzle.config.js" ]; then
        if [ -f "package.json" ] && grep -q '"db:push"' package.json 2>/dev/null; then
            echo "npm run db:push"; return
        fi
        echo "npx drizzle-kit push"; return
    fi
    # Prisma
    if [ -f "prisma/schema.prisma" ]; then echo "npx prisma db push"; return; fi
    # Alembic (Python)
    if [ -f "alembic.ini" ] || [ -d "alembic" ]; then echo "alembic upgrade head"; return; fi
    # Django
    if [ -f "manage.py" ] && grep -q "django" "requirements.txt" 2>/dev/null; then echo "python manage.py migrate"; return; fi
    echo ""
}

DB_MIGRATION_CMD=$(detect_migration_cmd)

# ── Auto-detect e2e check command ───────────────────────────────────────────

detect_e2e_check() {
    if [ -n "$E2E_CHECK_CMD" ]; then
        if [ "$E2E_CHECK_CMD" = "skip" ]; then echo ""; else echo "$E2E_CHECK_CMD"; fi
        return
    fi
    if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
        echo "npx playwright test"; return
    fi
    if [ -f "cypress.config.ts" ] || [ -f "cypress.config.js" ]; then
        echo "npx cypress run"; return
    fi
    echo ""
}

E2E_CMD=$(detect_e2e_check)

# ── Agent runner (supports Cursor CLI and Claude Code) ─────────────────────

run_agent() {
    local step_model="$1"
    local prompt="$2"
    local model="${step_model:-$AGENT_MODEL}"
    local backoff="$RATE_LIMIT_BACKOFF"
    local total_waited=0

    while true; do
        local agent_output
        agent_output=$(mktemp)
        local exit_code=0

        if [ "$CLI_PROVIDER" = "claude" ]; then
            if [ -n "$model" ]; then
                claude -p "$prompt" --output-format text --dangerously-skip-permissions --model "$model" 2>&1 | tee "$agent_output" || exit_code=$?
            else
                claude -p "$prompt" --output-format text --dangerously-skip-permissions 2>&1 | tee "$agent_output" || exit_code=$?
            fi
        else
            if [ -n "$model" ]; then
                agent -p --force --output-format text --model "$model" "$prompt" 2>&1 | tee "$agent_output" || exit_code=$?
            else
                agent -p --force --output-format text "$prompt" 2>&1 | tee "$agent_output" || exit_code=$?
            fi
        fi

        local output_text
        output_text=$(cat "$agent_output")
        rm -f "$agent_output"

        # Only check for transient errors when the CLI exited with an error.
        # Grepping the full output caused false positives when the agent wrote
        # code mentioning "429", "capacity", etc. Now we check exit code first,
        # then only inspect the last 5 lines (where CLI error messages appear).
        if [ "$exit_code" -ne 0 ]; then
            local tail_output
            tail_output=$(echo "$output_text" | tail -5)
            if echo "$tail_output" | grep -qi "rate.limit\|overloaded\|429\|too many requests\|capacity\|connection.reset\|ECONNRESET\|network.error\|socket.hang.up\|ETIMEDOUT\|ECONNREFUSED\|EAI_AGAIN\|EPIPE\|fetch.failed"; then
                if [ "$total_waited" -ge "$RATE_LIMIT_MAX_WAIT" ]; then
                    warn "Transient error and max wait ($RATE_LIMIT_MAX_WAIT s) exceeded. Giving up."
                    echo "$output_text"
                    return 1
                fi
                warn "Transient error detected. Waiting ${backoff}s before retry... (total waited: ${total_waited}s)"
                sleep "$backoff"
                total_waited=$((total_waited + backoff))
                backoff=$((backoff * 2))
                [ "$backoff" -gt "$RATE_LIMIT_MAX_WAIT" ] && backoff=$RATE_LIMIT_MAX_WAIT
                continue
            fi
        fi

        return $exit_code
    done
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
LAST_LINT_OUTPUT=""
LAST_MIGRATION_OUTPUT=""
LAST_E2E_OUTPUT=""
FEATURE_SESSION_NOTES=""
LAST_DRIFT_SUMMARY=""

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

check_lint() {
    if [ -z "$LINT_CMD" ]; then
        return 0
    fi
    log "Running lint check: $LINT_CMD"
    local tmpfile
    tmpfile=$(mktemp)
    eval "$LINT_CMD" 2>&1 | tee "$tmpfile"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        success "Lint check passed"
        LAST_LINT_OUTPUT=""
    else
        LAST_LINT_OUTPUT=$(tail -50 "$tmpfile")
        warn "Lint check failed (non-blocking)"
    fi
    rm -f "$tmpfile"
    return $exit_code
}

check_migration() {
    if [ -z "$DB_MIGRATION_CMD" ]; then
        return 0
    fi

    # Only run if schema files changed in recent commits
    local schema_changed
    schema_changed=$(git diff HEAD~1 --name-only 2>/dev/null | grep -E 'schema/|migrations?/|prisma/|alembic/' | head -1 || echo "")
    if [ -z "$schema_changed" ]; then
        log "No schema changes — skipping migration"
        return 0
    fi

    log "Schema files changed — running migration: $DB_MIGRATION_CMD"
    local tmpfile
    tmpfile=$(mktemp)
    eval "$DB_MIGRATION_CMD" 2>&1 | tee "$tmpfile"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        success "Migration applied"
        LAST_MIGRATION_OUTPUT=""
    else
        LAST_MIGRATION_OUTPUT=$(tail -50 "$tmpfile")
        warn "Migration failed (non-blocking — database may not be available)"
    fi
    rm -f "$tmpfile"
    return $exit_code
}

check_e2e() {
    if [ -z "$E2E_CMD" ]; then
        return 0
    fi
    log "Running e2e tests: $E2E_CMD"
    local tmpfile
    tmpfile=$(mktemp)
    eval "$E2E_CMD" 2>&1 | tee "$tmpfile"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        success "E2E tests passed"
        LAST_E2E_OUTPUT=""
    else
        LAST_E2E_OUTPUT=$(tail -80 "$tmpfile")
        warn "E2E tests failed (non-blocking)"
    fi
    rm -f "$tmpfile"
    return $exit_code
}

# ── Lazy re-detection (handles greenfield bootstrap) ────────────────────────
# After each feature, re-detect any empty commands from actual project files.
# Persists discoveries to .env.local so the next run doesn't need to re-detect.

update_env_local() {
    local key="$1"
    local value="$2"
    local env_file="$PROJECT_DIR/.env.local"
    [ ! -f "$env_file" ] && return

    if grep -q "^${key}=" "$env_file" 2>/dev/null; then
        sed -i.bak "s|^${key}=.*|${key}=\"${value}\"|" "$env_file"
        rm -f "$env_file.bak"
    else
        printf '\n%s="%s"\n' "$key" "$value" >> "$env_file"
    fi
}

redetect_if_empty() {
    local persisted=false

    if [ -z "$BUILD_CMD" ]; then
        BUILD_CMD=$(detect_build_check)
        if [ -n "$BUILD_CMD" ]; then
            success "Auto-detected build check: $BUILD_CMD"
            update_env_local "BUILD_CHECK_CMD" "$BUILD_CMD"
            persisted=true
        fi
    fi
    if [ -z "$TEST_CMD" ]; then
        TEST_CMD=$(detect_test_check)
        if [ -n "$TEST_CMD" ]; then
            success "Auto-detected test suite: $TEST_CMD"
            update_env_local "TEST_CHECK_CMD" "$TEST_CMD"
            persisted=true
        fi
    fi
    if [ -z "$LINT_CMD" ]; then
        LINT_CMD=$(detect_lint_check)
        if [ -n "$LINT_CMD" ]; then
            success "Auto-detected lint check: $LINT_CMD"
            update_env_local "LINT_CHECK_CMD" "$LINT_CMD"
            persisted=true
        fi
    fi
    if [ -z "$DB_MIGRATION_CMD" ]; then
        DB_MIGRATION_CMD=$(detect_migration_cmd)
        if [ -n "$DB_MIGRATION_CMD" ]; then
            success "Auto-detected migration: $DB_MIGRATION_CMD"
            update_env_local "MIGRATION_CMD" "$DB_MIGRATION_CMD"
            persisted=true
        fi
    fi
    if [ -z "$E2E_CMD" ]; then
        E2E_CMD=$(detect_e2e_check)
        if [ -n "$E2E_CMD" ]; then
            success "Auto-detected e2e tests: $E2E_CMD"
            update_env_local "E2E_CHECK_CMD" "$E2E_CMD"
            persisted=true
        fi
    fi

    if [ "$persisted" = true ]; then
        log "Persisted newly detected commands to .env.local"
    fi
}

should_run_step() {
    echo ",$POST_BUILD_STEPS," | grep -q ",$1,"
}

# Extract session summary from agent output (between SESSION_SUMMARY_START/END markers)
extract_session_summary() {
    local output="$1"
    local phase="$2"
    local summary
    summary=$(echo "$output" | sed -n '/SESSION_SUMMARY_START/,/SESSION_SUMMARY_END/p' | sed '1d;$d')
    if [ -n "$summary" ]; then
        printf "\n### %s\n%s\n" "$phase" "$summary"
    fi
}

# ── Drift check helpers ──────────────────────────────────────────────────

# Extract spec file and source files from build output or git diff.
# Sets: DRIFT_SPEC_FILE, DRIFT_SOURCE_FILES
extract_drift_targets() {
    local build_result="$1"

    # Try to extract from agent's structured output first
    DRIFT_SPEC_FILE=$(echo "$build_result" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | trim)
    DRIFT_SOURCE_FILES=$(echo "$build_result" | grep "^SOURCE_FILES:" | tail -1 | cut -d: -f2- | trim)

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

Before outputting your final signal, write a session summary between these exact markers:
SESSION_SUMMARY_START
- Drift found: [what mismatches were detected between spec and code]
- Fixed: [how mismatches were reconciled]
- Root cause: [why the drift likely occurred]
SESSION_SUMMARY_END

Output EXACTLY ONE of these signals at the end:
NO_DRIFT
DRIFT_FIXED: {brief summary of what was reconciled}
DRIFT_UNRESOLVABLE: {what needs human attention and why}
"
        run_agent "$DRIFT_MODEL" "$drift_prompt" 2>&1 | tee "$DRIFT_OUTPUT" || true
        DRIFT_RESULT=$(cat "$DRIFT_OUTPUT")
        rm -f "$DRIFT_OUTPUT"

        # Capture session summary for compound phase (global variable)
        LAST_DRIFT_SUMMARY=$(extract_session_summary "$DRIFT_RESULT" "Drift Check Phase")

        if echo "$DRIFT_RESULT" | grep -q "NO_DRIFT"; then
            success "Drift check passed — spec and code are aligned"
            return 0
        fi

        if echo "$DRIFT_RESULT" | grep -q "DRIFT_FIXED"; then
            local fix_summary
            fix_summary=$(echo "$DRIFT_RESULT" | grep "DRIFT_FIXED" | tail -1 | cut -d: -f2- | trim)
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
            unresolvable_reason=$(echo "$DRIFT_RESULT" | grep "DRIFT_UNRESOLVABLE" | tail -1 | cut -d: -f2- | trim)
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
Find the next feature from the roadmap and create the spec ONLY (do NOT run /build-next or /spec-first --full):

1. Read .specs/roadmap.md
2. First, check for any feature marked 🔄 (in progress) — if found, resume that feature (it was started but not finished in a previous run)
3. If no in-progress feature, find the next ⬜ (pending) feature whose dependencies are all ✅ (completed)
4. If a feature is ready:
   - If it was ⬜ pending, update roadmap to mark it 🔄 in progress
   - Load context: read .specs/personas/*.md (user vocabulary, patience level), .specs/design-system/tokens.md (personality, token names), .specs/vision.md
   - Check if a spec already exists for this feature in .specs/features/ — if so, run /spec-first in update mode
   - Run /spec-first {feature} (WITHOUT --full) — create or update the spec only, do NOT implement
   - Use persona vocabulary in all Gherkin scenarios and mockup labels
   - Do NOT write tests, do NOT implement, do NOT commit yet
   - Regenerate mapping: run ./scripts/generate-mapping.sh
5. If no features are ready, output: NO_FEATURES_READY
6. If spec fails, output: SPEC_FAILED: {reason}

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

    # For early features (infrastructure), remind the agent to configure build tooling
    local infra_hint=""
    if [ "${LOOP_BUILT:-0}" -lt 2 ]; then
        infra_hint="
INFRASTRUCTURE NOTE: This is an early feature in the build. If this feature creates or modifies
project infrastructure (package.json scripts, tsconfig, test framework config, ORM/migration config,
linter config), also update .env.local with the correct verification commands:
  BUILD_CHECK_CMD — e.g. \"npx tsc --noEmit\" or \"cargo check\"
  TEST_CHECK_CMD  — e.g. \"pnpm test\" or \"pytest\"
  LINT_CHECK_CMD  — e.g. \"pnpm lint\" or \"ruff check .\"
  MIGRATION_CMD   — e.g. \"pnpm db:push\" or \"npx prisma db push\"
These are used by the build loop for deterministic verification after each feature.
Only set commands for tools that this feature actually configures (leave others empty).
"
    fi

    echo "
The spec for \"$feature_name\" exists at $spec_file. Implement it through RED → GREEN:

1. Read the spec file and all its Gherkin scenarios
2. Write failing tests covering ALL scenarios (RED)
3. Implement until all tests pass (GREEN)
4. Self-check drift: re-read spec, compare to code, fix obvious mismatches (Layer 1)
5. Regenerate mapping: run ./scripts/generate-mapping.sh
6. Commit all changes with message: feat: $feature_name

IMPORTANT: Do NOT update the roadmap status. Do NOT run /compound. Those happen in later phases after verification.

CRITICAL IMPLEMENTATION RULES (from roadmap):
- NO mock data, fake JSON, or placeholder content. All features use real DB queries and real API calls.
- NO fake API endpoints that return static JSON. Every route must do real work.
- NO placeholder UI. Components must be wired to real data sources.
- Features must work end-to-end with real user data or they are not done.
- Real validation, real error handling, real flows.
$infra_hint
Before outputting your final signals, write a session summary between these exact markers:
SESSION_SUMMARY_START
- Decisions: [key architectural or design decisions you made and why]
- Errors hit: [build/type/test errors encountered and how you resolved them]
- Patterns: [notable code patterns used or discovered]
- Gotchas: [unexpected issues, edge cases, or workarounds needed]
- Testing: [testing approach, what was tricky to test, mock strategies used]
SESSION_SUMMARY_END

After completion, output EXACTLY these signals (each on its own line):
FEATURE_BUILT: $feature_name
SPEC_FILE: $spec_file
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or if build fails:
BUILD_FAILED: {reason}

The SPEC_FILE and SOURCE_FILES lines are REQUIRED when FEATURE_BUILT is reported.
They are used by the automated refactor, drift-check, and compound phases that run after your build.
"
}

build_retry_prompt() {
    local prompt='The previous attempt FAILED (spec phase or implement phase). There are uncommitted changes or errors.

Your job:
1. Run "git status" to understand the current state
2. Look at .specs/roadmap.md to find the feature marked 🔄 in progress
3. If the spec is missing or incomplete: run /spec-first {feature} (without --full) to create/update it
4. If the spec exists: fix the implementation — type errors, missing imports, incomplete code, failing tests
5. Complete RED → GREEN: tests, implement until pass, commit
6. Make sure the feature works end-to-end with REAL data (no mocks, no fake endpoints)
7. Run the test suite to verify everything passes: '"$TEST_CMD"'

IMPORTANT: Do NOT update the roadmap status. Do NOT run /compound. Those happen in later phases after verification.

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

    if [ -n "$LAST_LINT_OUTPUT" ]; then
        prompt="$prompt
LINT CHECK FAILURE OUTPUT (last 50 lines):
$LAST_LINT_OUTPUT
"
    fi

    prompt="$prompt
Before outputting your final signals, write a session summary between these exact markers:
SESSION_SUMMARY_START
- Decisions: [key architectural or design decisions you made and why]
- Errors hit: [build/type/test errors encountered and how you resolved them]
- Patterns: [notable code patterns used or discovered]
- Gotchas: [unexpected issues, edge cases, or workarounds needed]
- Testing: [testing approach, what was tricky to test, mock strategies used]
SESSION_SUMMARY_END

After completion, output EXACTLY these signals (each on its own line):
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to the .feature.md file}
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or if build fails:
BUILD_FAILED: {reason}
"
    echo "$prompt"
}

# Phase 3: Refactor (REFACTOR_MODEL). Called after build+test pass.
refactor_prompt() {
    local feature_name="$1"
    local spec_file="$2"
    local source_files="$3"
    local test_cmd_hint=""
    if [ -n "$TEST_CMD" ]; then
        test_cmd_hint="
Run the test suite after each change to verify: $TEST_CMD"
    fi
    echo "
You are the REFACTOR agent. The feature \"$feature_name\" has been implemented and all tests pass.
Your job: clean up the code WITHOUT changing behavior. Tests must still pass after every change.

Spec file: $spec_file
Source files: $source_files$test_cmd_hint

Instructions:
1. Read the source files listed above
2. Identify refactoring opportunities:
   - Functions longer than ~30 lines → extract
   - Duplicated code blocks → consolidate
   - Poor variable/function names → rename
   - Overly complex conditionals → simplify
   - Missing type annotations → add
   - Dead code or unused imports → remove
   - Magic numbers/strings → extract to constants
3. Apply refactoring incrementally
4. Run tests after each change — they MUST still pass
5. If tests fail after a change, REVERT that change and move on
6. Do NOT change test assertions (if you need to, it's a behavior change)
7. Do NOT update the roadmap or feature spec (behavior didn't change)
8. Commit: refactor: clean up $feature_name

Before outputting your final signal, write a session summary between these exact markers:
SESSION_SUMMARY_START
- Refactored: [what was changed and why]
- Skipped: [what looked refactorable but was left alone, and why]
- Patterns: [refactoring patterns applied]
SESSION_SUMMARY_END

After completion, output EXACTLY ONE of:
REFACTOR_COMPLETE: {brief summary of changes made}
REFACTOR_SKIPPED: code already clean
"
}

# Phase 5: Compound (COMPOUND_MODEL). Called after drift check.
# Args: $1=feature_name, $2=spec_file, $3=source_files, $4=session_notes (optional)
compound_prompt() {
    local feature_name="$1"
    local spec_file="$2"
    local source_files="$3"
    local session_notes="$4"

    local notes_section=""
    if [ -n "$session_notes" ]; then
        notes_section="
## Session Notes (from prior build phases)

These notes were captured from the build, refactor, and drift-check agents that ran before you.
They describe the journey — errors hit, decisions made, patterns discovered:
$session_notes
---"
    fi

    echo "
You are the COMPOUND agent. The feature \"$feature_name\" has been built, refactored, and drift-checked.
Your job: extract learnings from this implementation session.

Spec file: $spec_file
Source files: $source_files
$notes_section

Instructions:
1. Read the spec file and source files listed above
2. Run \`git log --oneline -15\` to see the commit history for this feature
3. Run \`git diff HEAD~5 --stat\` to see all files changed (including test files)
4. Read the session notes above — errors and gotchas are the most valuable learnings
5. Read existing .specs/learnings/index.md to avoid duplicating known patterns
6. Identify learnings:
   - Feature-specific patterns → add to the spec file's ## Learnings section
   - Cross-cutting patterns → add to .specs/learnings/{category}.md (testing, performance, security, api, design, general)
   - Add a brief entry to .specs/learnings/index.md
7. Prioritize: errors hit > gotchas > decisions > patterns (hard-won knowledge is most valuable)
8. Update the spec's frontmatter: set updated: $(date '+%Y-%m-%d')
9. Update .specs/roadmap.md:
   a. Find the row for this feature and change its status emoji from 🔄 to ✅
   b. Recalculate the Progress summary table at the top of the file by counting the actual status emojis (✅, 🔄, ⬜, ⏸️, ❌) across ALL feature rows in the roadmap. Update the counts to match reality.
   c. Update the 'Last updated' date
10. Commit all changes (learnings + roadmap update): compound: learnings from $feature_name

After completion, output:
COMPOUND_COMPLETE: {brief summary of learnings captured}
"
}

# ── Roadmap status helper ────────────────────────────────────────────────
# Updates the roadmap status for a feature at the SCRIPT level (not agent).
# This ensures roadmap is only marked ✅ after ALL verification passes.
mark_roadmap_status() {
    local feature_name="$1"
    local status_emoji="$2"
    local roadmap_file="$PROJECT_DIR/.specs/roadmap.md"

    if [ ! -f "$roadmap_file" ]; then
        warn "No roadmap.md found — skipping status update"
        return 0
    fi

    local escaped_name
    escaped_name=$(echo "$feature_name" | sed 's/[.[\*^$()+?{|\\]/\\&/g')

    if grep -q "$escaped_name" "$roadmap_file" 2>/dev/null; then
        # Replace status emoji on the line containing this feature name
        # Handles: ⬜ 🔄 ✅ ⏸️ ❌
        sed -i.bak -E "/$escaped_name/s/⬜|🔄|✅|⏸️|❌/$status_emoji/g" "$roadmap_file"
        rm -f "$roadmap_file.bak"
        log "Roadmap: $feature_name → $status_emoji"
    else
        warn "Feature '$feature_name' not found in roadmap — skipping status update"
    fi
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

        # ── Pre-flight: reset session notes and ensure working tree is clean ──
        FEATURE_SESSION_NOTES=""
        LAST_DRIFT_SUMMARY=""
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
                    FEATURE_FOR_IMPL=$(echo "$SPEC_RESULT" | grep "FEATURE_SPEC_READY" | tail -1 | cut -d: -f2- | trim)
                    SPEC_FILE_FOR_IMPL=$(echo "$SPEC_RESULT" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | trim)
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
                feature_name=$(echo "$BUILD_RESULT" | grep "FEATURE_BUILT" | tail -1 | cut -d: -f2- | trim)

                # Re-detect commands if any are empty (handles greenfield bootstrap)
                redetect_if_empty

                local phase_ok=true

                # ── Post-build verification: build → migration → test (blocking) ──
                if ! check_working_tree_clean; then
                    warn "Agent said FEATURE_BUILT but left uncommitted changes"
                    phase_ok=false
                elif ! check_build; then
                    warn "Agent said FEATURE_BUILT but build check failed"
                    phase_ok=false
                fi

                if [ "$phase_ok" = true ]; then
                    check_migration || warn "Migration failed (continuing — database may not be available)"
                fi

                if [ "$phase_ok" = true ] && should_run_step "test" && ! check_tests; then
                    warn "Agent said FEATURE_BUILT but tests failed"
                    phase_ok=false
                fi

                # Lint is non-blocking — warn but don't retry
                if [ "$phase_ok" = true ]; then
                    check_lint || true
                fi

                if [ "$phase_ok" = true ]; then
                    extract_drift_targets "$BUILD_RESULT"

                    # Capture build phase session summary
                    local build_summary
                    build_summary=$(extract_session_summary "$BUILD_RESULT" "Build Phase")
                    if [ -n "$build_summary" ]; then
                        FEATURE_SESSION_NOTES="${FEATURE_SESSION_NOTES}${build_summary}"
                    fi

                    # ── Phase 3: Refactor (REFACTOR_MODEL) ──
                    if [ "$REFACTOR" = "true" ]; then
                        log "Phase 3: Refactor (model: ${REFACTOR_MODEL:-${AGENT_MODEL:-default}}) — $feature_name"
                        local pre_refactor_commit
                        pre_refactor_commit=$(git rev-parse HEAD)

                        REFACTOR_OUTPUT=$(mktemp)
                        run_agent "$REFACTOR_MODEL" "$(refactor_prompt "$feature_name" "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES")" 2>&1 | tee "$REFACTOR_OUTPUT" || true
                        local REFACTOR_RESULT
                        REFACTOR_RESULT=$(cat "$REFACTOR_OUTPUT")
                        rm -f "$REFACTOR_OUTPUT"

                        # Verify refactor didn't break anything
                        if ! check_build || (should_run_step "test" && [ -n "$TEST_CMD" ] && ! check_tests); then
                            warn "Refactor broke build/tests — reverting to pre-refactor state"
                            git reset --hard "$pre_refactor_commit"
                            success "Reverted to pre-refactor commit"
                        else
                            success "Refactor complete — build and tests still pass"
                            local refactor_summary
                            refactor_summary=$(extract_session_summary "$REFACTOR_RESULT" "Refactor Phase")
                            if [ -n "$refactor_summary" ]; then
                                FEATURE_SESSION_NOTES="${FEATURE_SESSION_NOTES}${refactor_summary}"
                            fi
                        fi
                    else
                        log "Refactor disabled (set REFACTOR=true to enable)"
                    fi

                    # ── Phase 4: Drift check (DRIFT_MODEL — fresh agent) ──
                    if check_drift "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES"; then

                        # Capture drift session summary (set by check_drift via global)
                        if [ -n "$LAST_DRIFT_SUMMARY" ]; then
                            FEATURE_SESSION_NOTES="${FEATURE_SESSION_NOTES}${LAST_DRIFT_SUMMARY}"
                        fi

                        # ── E2E tests (non-blocking, after drift when code is final) ──
                        check_e2e || true

                        # ── Phase 5: Compound (COMPOUND_MODEL) ──
                        if [ "$COMPOUND" = "true" ]; then
                            log "Phase 5: Compound (model: ${COMPOUND_MODEL:-${AGENT_MODEL:-default}}) — $feature_name"
                            COMPOUND_OUTPUT=$(mktemp)
                            run_agent "$COMPOUND_MODEL" "$(compound_prompt "$feature_name" "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES" "$FEATURE_SESSION_NOTES")" 2>&1 | tee "$COMPOUND_OUTPUT" || true
                            rm -f "$COMPOUND_OUTPUT"
                            success "Compound (learnings) complete"
                        else
                            log "Compound disabled (set COMPOUND=true to enable)"
                        fi

                        # ── Optional: code review (fresh agent) ──
                        if should_run_step "code-review"; then
                            run_code_review || warn "Code review had issues (non-blocking)"
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

                        BUILT_FEATURE_NAMES+=("$feature_name")

                        break
                    else
                        warn "Agent said FEATURE_BUILT but drift check failed"
                    fi
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

show_cmd_status() {
    local label="$1" cmd="$2" env_var="$3"
    if [ -n "$cmd" ]; then
        echo "  $label: $cmd"
    else
        echo "  $label: auto-detect (will re-detect after each feature, or set $env_var)"
    fi
}

echo ""
echo "Build loop (local only, no remote/push/PR)"
echo "CLI provider: $CLI_PROVIDER"
echo "Base branch: $MAIN_BRANCH"
echo "Branch strategy: $BRANCH_STRATEGY"
echo "Max features: $MAX_FEATURES | Max retries per feature: $MAX_RETRIES"
echo ""
echo "Verification commands:"
show_cmd_status "Build" "$BUILD_CMD" "BUILD_CHECK_CMD"
show_cmd_status "Test" "$TEST_CMD" "TEST_CHECK_CMD"
show_cmd_status "Lint" "$LINT_CMD" "LINT_CHECK_CMD"
show_cmd_status "Migration" "$DB_MIGRATION_CMD" "MIGRATION_CMD"
show_cmd_status "E2E" "$E2E_CMD" "E2E_CHECK_CMD"
echo ""
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
                INDEP_SPEC_FILE=$(echo "$INDEP_SPEC_RESULT" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | trim)
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
