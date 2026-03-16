#!/bin/bash
# overnight-autonomous.sh
# Autonomous overnight feature implementation using roadmap
#
# Flow:
#   1. Sync with main branch
#   2. Rebase existing auto PRs
#   3. Triage Slack/Jira → add to roadmap
#   4. Build features from roadmap (up to MAX_FEATURES)
#   5. Report summary
#
# CONFIGURATION (set in .env.local):
#   BASE_BRANCH            - Branch to sync and branch from (default: main)
#                           Use develop, main, or current branch
#   SLACK_FEATURE_CHANNEL  - Slack channel to scan
#   JIRA_PROJECT_KEY       - Jira project key
#   JIRA_AUTO_LABEL        - Label marking auto-ok items
#   MAX_FEATURES           - Max features per night (default: 4)
#   PROJECT_DIR            - Project directory

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ✗${NC} $1"; }
section() { echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"; }

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

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -f "$PROJECT_DIR/.env.local" ]; then
    source "$PROJECT_DIR/.env.local"
fi

# Defaults
CLI_PROVIDER="${CLI_PROVIDER:-cursor}"
MAX_FEATURES="${MAX_FEATURES:-4}"
BRANCH_STRATEGY="${BRANCH_STRATEGY:-chained}"
# BASE_BRANCH: develop, main, or "current" (use git branch --show-current)
BASE_BRANCH="${BASE_BRANCH:-main}"
DRIFT_CHECK="${DRIFT_CHECK:-true}"
MAX_DRIFT_RETRIES="${MAX_DRIFT_RETRIES:-2}"
SLACK_FEATURE_CHANNEL="${SLACK_FEATURE_CHANNEL:-#feature-requests}"
SLACK_REPORT_CHANNEL="${SLACK_REPORT_CHANNEL:-}"
JIRA_PROJECT_KEY="${JIRA_PROJECT_KEY:-}"

# Validate BRANCH_STRATEGY
if [[ ! "$BRANCH_STRATEGY" =~ ^(chained|independent)$ ]]; then
    warn "Invalid BRANCH_STRATEGY: $BRANCH_STRATEGY (must be: chained or independent)"
    warn "Using default: chained"
    BRANCH_STRATEGY="chained"
fi

section "OVERNIGHT AUTONOMOUS RUN"
log "Project: $PROJECT_DIR"
log "CLI provider: $CLI_PROVIDER"
log "Base branch: $BASE_BRANCH"
log "Branch strategy: $BRANCH_STRATEGY"
log "Max features: $MAX_FEATURES"
log "Slack channel: $SLACK_FEATURE_CHANNEL"
log "Jira project: ${JIRA_PROJECT_KEY:-not configured}"

cd "$PROJECT_DIR"

# Check prerequisites
if [ "$CLI_PROVIDER" = "claude" ]; then
    command -v claude &>/dev/null || { error "Claude Code CLI not found. Install from: https://code.claude.com"; exit 1; }
else
    command -v agent &>/dev/null || { error "Cursor CLI (agent) not found. Install from: https://cursor.com/cli"; exit 1; }
fi

if ! command -v gh &> /dev/null; then
    warn "GitHub CLI (gh) not found - PRs won't be created"
fi

# ── Model selection & test detection ──────────────────────────────────────

# Cursor CLI default; run `agent --list-models` to see available models
AGENT_MODEL="${AGENT_MODEL:-composer-1.5}"
SPEC_MODEL="${SPEC_MODEL:-}"
BUILD_MODEL="${BUILD_MODEL:-}"
REFACTOR_MODEL="${REFACTOR_MODEL:-}"
RETRY_MODEL="${RETRY_MODEL:-}"
DRIFT_MODEL="${DRIFT_MODEL:-}"
COMPOUND_MODEL="${COMPOUND_MODEL:-}"
REVIEW_MODEL="${REVIEW_MODEL:-}"
TRIAGE_MODEL="${TRIAGE_MODEL:-}"
POST_BUILD_STEPS="${POST_BUILD_STEPS:-test}"
REFACTOR="${REFACTOR:-true}"
COMPOUND="${COMPOUND:-true}"
RATE_LIMIT_BACKOFF="${RATE_LIMIT_BACKOFF:-60}"
RATE_LIMIT_MAX_WAIT="${RATE_LIMIT_MAX_WAIT:-18000}"

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

# ── Refactor, Compound, and Roadmap helpers ──────────────────────────────

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
2. Identify refactoring opportunities: long functions, duplication, poor names, complex conditionals, missing types, dead code
3. Apply refactoring incrementally
4. Run tests after each change — they MUST still pass
5. If tests fail after a change, REVERT that change and move on
6. Do NOT change test assertions
7. Do NOT update the roadmap or feature spec
8. Commit: refactor: clean up $feature_name

Before outputting your final signal, write a session summary between these exact markers:
SESSION_SUMMARY_START
- Refactored: [what was changed and why]
- Skipped: [what looked refactorable but was left alone, and why]
- Patterns: [refactoring patterns applied]
SESSION_SUMMARY_END

Output: REFACTOR_COMPLETE: {summary} or REFACTOR_SKIPPED: code already clean
"
}

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
Extract learnings from this implementation.

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
   - Feature-specific patterns → add to spec's ## Learnings section
   - Cross-cutting patterns → add to .specs/learnings/{category}.md
   - Add brief entry to .specs/learnings/index.md
7. Prioritize: errors hit > gotchas > decisions > patterns (hard-won knowledge is most valuable)
8. Update spec frontmatter: updated: $(date '+%Y-%m-%d')
9. Commit: compound: learnings from $feature_name

Output: COMPOUND_COMPLETE: {summary}
"
}

mark_roadmap_status() {
    local feature_name="$1"
    local status_emoji="$2"
    local roadmap_file="$PROJECT_DIR/.specs/roadmap.md"
    if [ ! -f "$roadmap_file" ]; then return 0; fi
    local escaped_name
    escaped_name=$(echo "$feature_name" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
    if grep -q "$escaped_name" "$roadmap_file" 2>/dev/null; then
        sed -i.bak -E "/$escaped_name/s/⬜|🔄|✅|⏸️|❌/$status_emoji/g" "$roadmap_file"
        rm -f "$roadmap_file.bak"
        log "Roadmap: $feature_name → $status_emoji"
    fi
}

detect_build_check() {
    if [ -n "$BUILD_CHECK_CMD" ]; then
        if [ "$BUILD_CHECK_CMD" = "skip" ]; then echo ""; else echo "$BUILD_CHECK_CMD"; fi
        return
    fi
    if [ -f "tsconfig.build.json" ]; then echo "npx tsc --noEmit --project tsconfig.build.json"
    elif [ -f "tsconfig.json" ]; then echo "npx tsc --noEmit"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then echo "python -m py_compile $(find . -name '*.py' -not -path '*/venv/*' -not -path '*/.venv/*' | head -1 2>/dev/null || echo 'main.py')"
    elif [ -f "Cargo.toml" ]; then echo "cargo check"
    elif [ -f "go.mod" ]; then echo "go build ./..."
    elif [ -f "package.json" ] && grep -q '"build"' package.json 2>/dev/null; then echo "npm run build"
    else echo ""; fi
}

BUILD_CMD=$(detect_build_check)

check_build() {
    if [ -z "$BUILD_CMD" ]; then return 0; fi
    log "Running build check: $BUILD_CMD"
    local tmpfile; tmpfile=$(mktemp)
    eval "$BUILD_CMD" 2>&1 | tee "$tmpfile"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then success "Build check passed"; LAST_BUILD_OUTPUT=""
    else LAST_BUILD_OUTPUT=$(tail -50 "$tmpfile"); error "Build check failed"; fi
    rm -f "$tmpfile"; return $exit_code
}

LAST_BUILD_OUTPUT=""
LAST_TEST_OUTPUT=""

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

check_tests() {
    if [ -z "$TEST_CMD" ]; then return 0; fi
    log "Running test suite: $TEST_CMD"
    local tmpfile; tmpfile=$(mktemp)
    eval "$TEST_CMD" 2>&1 | tee "$tmpfile"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then success "Tests passed"; LAST_TEST_OUTPUT=""
    else LAST_TEST_OUTPUT=$(tail -80 "$tmpfile"); error "Tests failed"; fi
    rm -f "$tmpfile"; return $exit_code
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

FEATURE_SESSION_NOTES=""
LAST_DRIFT_SUMMARY=""

run_code_review() {
    log "Running code-review agent (fresh context, model: ${REVIEW_MODEL:-${AGENT_MODEL:-default}})..."
    local test_context=""
    if [ -n "$TEST_CMD" ]; then
        test_context="
Test command: $TEST_CMD"
    fi

    local review_prompt="
Review and improve code quality of the most recently built feature.
$test_context

Steps:
1. Check 'git log --oneline -10' to see recent commits
2. Review source files against senior engineering standards
3. Fix critical issues ONLY (no 'any' types, proper error handling, etc.)
4. Do NOT change behavior. Do NOT refactor for style.
5. Run the test suite (\`$TEST_CMD\`) after your changes — iterate until tests pass
6. Commit fixes if any: git add -A && git commit -m 'refactor: code quality improvements (auto-review)'

IMPORTANT: Do not introduce test regressions. Run tests after every change and fix anything you break.

Output: REVIEW_CLEAN or REVIEW_FIXED: {summary} or REVIEW_FAILED: {reason}
"
    run_agent "$REVIEW_MODEL" "$review_prompt" 2>&1 || true
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        git add -A && git commit -m "refactor: code quality improvements (auto-review)" 2>/dev/null || true
    fi
}

log "Test suite: ${TEST_CMD:-disabled}"
log "Post-build steps: ${POST_BUILD_STEPS:-none}"
if [ -n "$AGENT_MODEL" ] || [ -n "$SPEC_MODEL" ] || [ -n "$BUILD_MODEL" ] || [ -n "$DRIFT_MODEL" ] || [ -n "$REVIEW_MODEL" ]; then
    log "Models: default=${AGENT_MODEL:-CLI default} spec=${SPEC_MODEL:-↑} build=${BUILD_MODEL:-↑} refactor=${REFACTOR_MODEL:-↑} drift=${DRIFT_MODEL:-↑} compound=${COMPOUND_MODEL:-↑} review=${REVIEW_MODEL:-↑}"
fi
log "Refactor: $REFACTOR | Compound: $COMPOUND"

# ── Drift check helpers ──────────────────────────────────────────────────

extract_drift_targets() {
    local build_result="$1"
    DRIFT_SPEC_FILE=$(echo "$build_result" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | xargs 2>/dev/null || echo "")
    DRIFT_SOURCE_FILES=$(echo "$build_result" | grep "^SOURCE_FILES:" | tail -1 | cut -d: -f2- | xargs 2>/dev/null || echo "")
    if [ -z "$DRIFT_SPEC_FILE" ]; then
        DRIFT_SPEC_FILE=$(git diff HEAD~1 --name-only 2>/dev/null | grep '\.specs/features/.*\.feature\.md$' | head -1 || echo "")
    fi
    if [ -z "$DRIFT_SOURCE_FILES" ]; then
        DRIFT_SOURCE_FILES=$(git diff HEAD~1 --name-only 2>/dev/null | grep -E '\.(tsx?|jsx?|py|rs|go)$' | grep -v '\.test\.' | grep -v '\.spec\.' | tr '\n' ', ' | sed 's/,$//' || echo "")
    fi
}

check_drift() {
    if [ "$DRIFT_CHECK" != "true" ]; then
        log "Drift check disabled"
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
Run /catch-drift for this specific feature. Auto-fix all drift by updating specs to match code.

Spec file: $spec_file
Source files: $source_files$test_context

Instructions:
1. Read the spec file and all its Gherkin scenarios
2. Read each source file
3. Compare: does the code implement what the spec describes?
4. If drift found: update specs, code, or tests as needed (prefer updating specs to match code)
5. Run the test suite (\`$TEST_CMD\`) and fix any failures — iterate until tests pass
6. Commit all fixes with message: 'fix: reconcile spec drift for {feature}'

IMPORTANT: Your goal is spec+code alignment AND a passing test suite. Keep iterating until both are achieved.

Before outputting your final signal, write a session summary between these exact markers:
SESSION_SUMMARY_START
- Drift found: [what mismatches were detected between spec and code]
- Fixed: [how mismatches were reconciled]
- Root cause: [why the drift likely occurred]
SESSION_SUMMARY_END

Output EXACTLY ONE of:
NO_DRIFT
DRIFT_FIXED: {brief summary}
DRIFT_UNRESOLVABLE: {what needs human attention}
"
        run_agent "$DRIFT_MODEL" "$drift_prompt" 2>&1 | tee "$DRIFT_OUTPUT" || true
        DRIFT_RESULT=$(cat "$DRIFT_OUTPUT")
        rm -f "$DRIFT_OUTPUT"

        # Capture session summary for compound phase (global variable)
        LAST_DRIFT_SUMMARY=$(extract_session_summary "$DRIFT_RESULT" "Drift Check Phase")

        if echo "$DRIFT_RESULT" | grep -q "NO_DRIFT"; then
            success "Drift check passed"
            return 0
        fi
        if echo "$DRIFT_RESULT" | grep -q "DRIFT_FIXED"; then
            local fix_summary
            fix_summary=$(echo "$DRIFT_RESULT" | grep "DRIFT_FIXED" | tail -1 | cut -d: -f2- | xargs)
            success "Drift auto-fixed: $fix_summary"
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
            warn "Unresolvable drift: $(echo "$DRIFT_RESULT" | grep "DRIFT_UNRESOLVABLE" | tail -1 | cut -d: -f2- | xargs)"
            return 1
        fi
        drift_attempt=$((drift_attempt + 1))
    done
    error "Drift check failed"
    return 1
}

# ─────────────────────────────────────────────
# STEP 0: Ensure we're on BASE_BRANCH and up to date
# ─────────────────────────────────────────────

# Resolve BASE_BRANCH: "current" = use current branch
SYNC_BRANCH="$BASE_BRANCH"
if [ "$BASE_BRANCH" = "current" ]; then
    SYNC_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
fi

section "STEP 0: Sync with $SYNC_BRANCH"
STEP_START=$(date +%s)

if ! git rev-parse --verify "$SYNC_BRANCH" >/dev/null 2>&1; then
    error "BASE_BRANCH=$BASE_BRANCH (resolved: $SYNC_BRANCH) does not exist"
    exit 1
fi
git checkout "$SYNC_BRANCH"
MAIN_BRANCH="$SYNC_BRANCH"
git pull origin "$MAIN_BRANCH"

STEP_DURATION=$(( $(date +%s) - STEP_START ))
success "Synced with $MAIN_BRANCH ($(format_duration $STEP_DURATION))"
STEP_TIMINGS=("Step 0 - Sync: $(format_duration $STEP_DURATION)")

# ─────────────────────────────────────────────
# STEP 1: Rebase any existing auto PRs
# ─────────────────────────────────────────────

section "STEP 1: Rebase existing auto PRs"
STEP_START=$(date +%s)

if command -v gh &> /dev/null; then
    REBASED=0
    for pr_branch in $(gh pr list --search "head:auto/" --json headRefName --jq '.[].headRefName' 2>/dev/null || echo ""); do
        if [ -n "$pr_branch" ]; then
            log "Rebasing $pr_branch..."
            git fetch origin "$pr_branch" 2>/dev/null || continue
            git checkout "$pr_branch" 2>/dev/null || continue
            
            if git rebase "origin/$MAIN_BRANCH" 2>/dev/null; then
                git push --force-with-lease origin "$pr_branch" 2>/dev/null && {
                    success "Rebased $pr_branch"
                    REBASED=$((REBASED + 1))
                }
            else
                git rebase --abort 2>/dev/null
                warn "Could not rebase $pr_branch - may need manual intervention"
            fi
        fi
    done
    
    git checkout "$MAIN_BRANCH" 2>/dev/null
    
    if [ "$REBASED" -gt 0 ]; then
        success "Rebased $REBASED existing PRs"
    else
        log "No existing auto PRs to rebase"
    fi
else
    log "Skipping rebase (gh CLI not available)"
fi

STEP_DURATION=$(( $(date +%s) - STEP_START ))
STEP_TIMINGS+=("Step 1 - Rebase PRs: $(format_duration $STEP_DURATION)")

# ─────────────────────────────────────────────
# STEP 2: Triage Slack/Jira → Roadmap
# ─────────────────────────────────────────────

section "STEP 2: Triage new requests"
STEP_START=$(date +%s)

log "Running /roadmap-triage to scan Slack/Jira..."

triage_prompt="
Run the /roadmap-triage command to:
1. Scan Slack channel $SLACK_FEATURE_CHANNEL for feature requests
2. Scan Jira project $JIRA_PROJECT_KEY for tickets with label 'auto-ok'
3. Add new items to .specs/roadmap.md in the Ad-hoc Requests section
4. Create Jira tickets for Slack items (if configured)
5. Mark sources as triaged (reply to Slack, comment on Jira)
6. Commit the roadmap changes

If no new requests found, that's fine - continue.
"
run_agent "$TRIAGE_MODEL" "$triage_prompt"

STEP_DURATION=$(( $(date +%s) - STEP_START ))
success "Triage complete ($(format_duration $STEP_DURATION))"
STEP_TIMINGS+=("Step 2 - Triage: $(format_duration $STEP_DURATION)")

# ─────────────────────────────────────────────
# STEP 3: Build features from roadmap
# ─────────────────────────────────────────────

section "STEP 3: Build features from roadmap"
STEP_START=$(date +%s)

BUILT=0
FAILED=0
LAST_FEATURE_BRANCH=""
FEATURE_TIMINGS=()

for i in $(seq 1 "$MAX_FEATURES"); do
    FEATURE_START=$(date +%s)
    FEATURE_SESSION_NOTES=""
    LAST_DRIFT_SUMMARY=""
    elapsed_so_far=$(( FEATURE_START - SCRIPT_START ))
    log "Build iteration $i/$MAX_FEATURES... (elapsed: $(format_duration $elapsed_so_far))"
    
    # Create a new branch for this feature based on strategy
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BRANCH_NAME="auto/feature-$TIMESTAMP"
    
    if [ "$BRANCH_STRATEGY" = "chained" ]; then
        # Chained: Branch from previous feature's branch (or main if first)
        base_branch="${LAST_FEATURE_BRANCH:-$MAIN_BRANCH}"
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
    else
        # Independent: Always branch from main
        git checkout "$MAIN_BRANCH"
    fi
    
    git checkout -b "$BRANCH_NAME"
    
    # Spec phase then implement phase (two-phase, does NOT invoke /build-next)
    BUILD_OUTPUT=$(mktemp)

    spec_prompt="
Find the next feature from the roadmap and create the spec ONLY (do NOT run /build-next or /spec-first --full):
1. Read .specs/roadmap.md
2. First, check for any feature marked 🔄 (in progress) — if found, resume that feature (it was started but not finished in a previous run)
3. If no in-progress feature, find the next ⬜ (pending) feature whose dependencies are all ✅ (completed)
4. If a feature is ready:
   - If it was ⬜ pending, update roadmap to mark it 🔄 in progress
   - Check if a spec already exists for this feature in .specs/features/ — if so, run /spec-first in update mode
   - Run /spec-first {feature} (WITHOUT --full) — create or update the spec only, do NOT implement
   - Do NOT write tests, do NOT implement, do NOT commit yet
   - Regenerate mapping: run ./scripts/generate-mapping.sh
5. If no features are ready, output: NO_FEATURES_READY
6. If spec fails, output: SPEC_FAILED: {reason}

Output EXACTLY:
FEATURE_SPEC_READY: {feature name}
SPEC_FILE: {path to .feature.md}

Or: NO_FEATURES_READY
Or: SPEC_FAILED: {reason}
"
    log "Phase 1: Spec"
    run_agent "$SPEC_MODEL" "$spec_prompt" > "$BUILD_OUTPUT" 2>&1 || true
    SPEC_RESULT=$(cat "$BUILD_OUTPUT")

    if echo "$SPEC_RESULT" | grep -q "FEATURE_SPEC_READY"; then
        FEATURE_FOR_IMPL=$(echo "$SPEC_RESULT" | grep "FEATURE_SPEC_READY" | cut -d: -f2- | xargs)
        SPEC_FILE_FOR_IMPL=$(echo "$SPEC_RESULT" | grep "^SPEC_FILE:" | tail -1 | cut -d: -f2- | xargs)
        implement_prompt="
The spec for \"$FEATURE_FOR_IMPL\" exists at $SPEC_FILE_FOR_IMPL. Implement it through RED → GREEN:

1. Read the spec file and all its Gherkin scenarios
2. Write failing tests covering ALL scenarios (RED)
3. Implement until all tests pass (GREEN)
4. Self-check drift: re-read spec, compare to code, fix obvious mismatches (Layer 1)
5. Regenerate mapping: run ./scripts/generate-mapping.sh
6. Commit all changes with message: feat: $FEATURE_FOR_IMPL

IMPORTANT: Do NOT update the roadmap status. Do NOT run /compound. Those happen in later phases after verification.

CRITICAL IMPLEMENTATION RULES (from roadmap):
- NO mock data, fake JSON, or placeholder content. All features use real DB queries and real API calls.
- NO fake API endpoints that return static JSON. Every route must do real work.
- NO placeholder UI. Components must be wired to real data sources.
- Features must work end-to-end with real user data or they are not done.
- Real validation, real error handling, real flows.

Before outputting your final signals, write a session summary between these exact markers:
SESSION_SUMMARY_START
- Decisions: [key architectural or design decisions you made and why]
- Errors hit: [build/type/test errors encountered and how you resolved them]
- Patterns: [notable code patterns used or discovered]
- Gotchas: [unexpected issues, edge cases, or workarounds needed]
- Testing: [testing approach, what was tricky to test, mock strategies used]
SESSION_SUMMARY_END

Output EXACTLY these signals (each on its own line):
FEATURE_BUILT: $FEATURE_FOR_IMPL
SPEC_FILE: $SPEC_FILE_FOR_IMPL
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or if build fails:
BUILD_FAILED: {reason}
"
        log "Phase 2: Implement"
        run_agent "$BUILD_MODEL" "$implement_prompt" > "$BUILD_OUTPUT" 2>&1 || true
    else
        echo "$SPEC_RESULT" > "$BUILD_OUTPUT"
    fi

    BUILD_RESULT=$(cat "$BUILD_OUTPUT")
    rm -f "$BUILD_OUTPUT"
    
    # Check result
    if echo "$BUILD_RESULT" | grep -q "NO_FEATURES_READY"; then
        log "No more features ready to build"
        git checkout "$MAIN_BRANCH"
        git branch -D "$BRANCH_NAME" 2>/dev/null || true
        break
    fi
    
    if echo "$BUILD_RESULT" | grep -q "SPEC_FAILED"; then
        REASON=$(echo "$BUILD_RESULT" | grep "SPEC_FAILED" | cut -d: -f2-)
        FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
        warn "Spec phase failed: $REASON ($(format_duration $FEATURE_DURATION))"
        FEATURE_TIMINGS+=("✗ feature $i: $(format_duration $FEATURE_DURATION)")
        FAILED=$((FAILED + 1))
        git checkout "$MAIN_BRANCH"
        git branch -D "$BRANCH_NAME" 2>/dev/null || true
        continue
    fi

    if echo "$BUILD_RESULT" | grep -q "BUILD_FAILED"; then
        REASON=$(echo "$BUILD_RESULT" | grep "BUILD_FAILED" | cut -d: -f2-)
        FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
        warn "Implement phase failed: $REASON ($(format_duration $FEATURE_DURATION))"
        FEATURE_TIMINGS+=("✗ feature $i: $(format_duration $FEATURE_DURATION)")
        FAILED=$((FAILED + 1))
        git checkout "$MAIN_BRANCH"
        git branch -D "$BRANCH_NAME" 2>/dev/null || true
        continue
    fi
    
    # Feature built - check for changes
    if [ -n "$(git status --porcelain)" ]; then
        git add -A
        
        # Extract feature name from output
        FEATURE_NAME=$(echo "$BUILD_RESULT" | grep "FEATURE_BUILT" | cut -d: -f2- | xargs || echo "feature")
        FEATURE_NAME="${FEATURE_NAME:-feature}"
        
        git commit -m "feat(auto): $FEATURE_NAME" 2>/dev/null || true
        
        # Post-build verification
        local post_build_ok=true
        if ! check_build; then
            FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
            warn "Build check failed for $FEATURE_NAME ($(format_duration $FEATURE_DURATION))"
            FEATURE_TIMINGS+=("⚠ $FEATURE_NAME (build): $(format_duration $FEATURE_DURATION)")
            post_build_ok=false
        fi
        
        if [ "$post_build_ok" = true ] && should_run_step "test" && ! check_tests; then
            FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
            warn "Tests failed for $FEATURE_NAME ($(format_duration $FEATURE_DURATION))"
            FEATURE_TIMINGS+=("⚠ $FEATURE_NAME (tests): $(format_duration $FEATURE_DURATION)")
            post_build_ok=false
        fi

        extract_drift_targets "$BUILD_RESULT"

        # Capture build phase session summary
        local build_summary
        build_summary=$(extract_session_summary "$BUILD_RESULT" "Build Phase")
        if [ -n "$build_summary" ]; then
            FEATURE_SESSION_NOTES="${FEATURE_SESSION_NOTES}${build_summary}"
        fi

        # Phase 3: Refactor (fresh agent)
        if [ "$post_build_ok" = true ] && [ "$REFACTOR" = "true" ]; then
            log "Phase 3: Refactor — $FEATURE_NAME"
            local pre_refactor_commit
            pre_refactor_commit=$(git rev-parse HEAD)
            
            REFACTOR_OUTPUT=$(mktemp)
            run_agent "$REFACTOR_MODEL" "$(refactor_prompt "$FEATURE_NAME" "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES")" > "$REFACTOR_OUTPUT" 2>&1 || true
            local REFACTOR_RESULT
            REFACTOR_RESULT=$(cat "$REFACTOR_OUTPUT")
            rm -f "$REFACTOR_OUTPUT"
            
            if ! check_build || (should_run_step "test" && [ -n "$TEST_CMD" ] && ! check_tests); then
                warn "Refactor broke build/tests — reverting"
                git reset --hard "$pre_refactor_commit"
            else
                success "Refactor complete"
                # Capture refactor session summary (only if not reverted)
                local refactor_summary
                refactor_summary=$(extract_session_summary "$REFACTOR_RESULT" "Refactor Phase")
                if [ -n "$refactor_summary" ]; then
                    FEATURE_SESSION_NOTES="${FEATURE_SESSION_NOTES}${refactor_summary}"
                fi
            fi
        fi
        
        # Phase 4: Drift check (fresh agent, separate context)
        if [ "$post_build_ok" = true ] && ! check_drift "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES"; then
            FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
            warn "Feature built but drift check failed ($(format_duration $FEATURE_DURATION))"
            FEATURE_TIMINGS+=("⚠ $FEATURE_NAME (drift): $(format_duration $FEATURE_DURATION)")
        fi

        # Capture drift session summary (set by check_drift via global)
        if [ -n "$LAST_DRIFT_SUMMARY" ]; then
            FEATURE_SESSION_NOTES="${FEATURE_SESSION_NOTES}${LAST_DRIFT_SUMMARY}"
        fi

        # Phase 5: Compound (fresh agent)
        if [ "$post_build_ok" = true ] && [ "$COMPOUND" = "true" ]; then
            log "Phase 5: Compound — $FEATURE_NAME"
            COMPOUND_OUTPUT=$(mktemp)
            run_agent "$COMPOUND_MODEL" "$(compound_prompt "$FEATURE_NAME" "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES" "$FEATURE_SESSION_NOTES")" > "$COMPOUND_OUTPUT" 2>&1 || true
            rm -f "$COMPOUND_OUTPUT"
            success "Compound (learnings) complete"
        fi
        
        # Run code review (fresh agent, separate context)
        if should_run_step "code-review"; then
            run_code_review || warn "Code review had issues (non-blocking)"
            if ! check_build; then
                warn "Code review broke the build!"
            elif should_run_step "test" && [ -n "$TEST_CMD" ] && ! check_tests; then
                warn "Code review broke tests!"
            fi
        fi

        # Mark roadmap ✅ at script level (after ALL verification)
        if [ "$post_build_ok" = true ]; then
            mark_roadmap_status "$FEATURE_NAME" "✅"
            git add -A && git commit -m "chore: mark $FEATURE_NAME complete in roadmap" --allow-empty 2>/dev/null || true
        fi
        
        # Push and create PR
        if git push -u origin "$BRANCH_NAME" 2>/dev/null; then
            success "Pushed branch $BRANCH_NAME"
            
            if command -v gh &> /dev/null; then
                # Get spec content if available
                SPEC_FILE=$(find .specs/features -name "*.feature.md" -newer .git/HEAD 2>/dev/null | head -1)
                SPEC_CONTENT=""
                if [ -f "$SPEC_FILE" ]; then
                    SPEC_CONTENT=$(cat "$SPEC_FILE")
                fi
                
                PR_URL=$(gh pr create --draft \
                    --title "Auto: $FEATURE_NAME" \
                    --body "$(cat <<EOF
## Feature

$FEATURE_NAME

## Generated Spec

<details>
<summary>Click to expand</summary>

\`\`\`markdown
$SPEC_CONTENT
\`\`\`

</details>

## Review Checklist

- [ ] Spec makes sense
- [ ] Implementation matches spec
- [ ] Tests are adequate
- [ ] No security issues
- [ ] Code follows project patterns

---

_Generated by overnight-autonomous.sh_
EOF
)" 2>/dev/null || echo "")
                
                if [ -n "$PR_URL" ]; then
                    FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
                    success "Created PR: $PR_URL ($(format_duration $FEATURE_DURATION))"
                    FEATURE_TIMINGS+=("✓ $FEATURE_NAME: $(format_duration $FEATURE_DURATION)")
                    BUILT=$((BUILT + 1))
                    # Track branch for chained mode
                    if [ "$BRANCH_STRATEGY" = "chained" ]; then
                        LAST_FEATURE_BRANCH="$BRANCH_NAME"
                    fi
                fi
            else
                FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
                success "Branch pushed (PR not created - gh CLI unavailable) ($(format_duration $FEATURE_DURATION))"
                FEATURE_TIMINGS+=("✓ $FEATURE_NAME: $(format_duration $FEATURE_DURATION)")
                BUILT=$((BUILT + 1))
                # Track branch for chained mode
                if [ "$BRANCH_STRATEGY" = "chained" ]; then
                    LAST_FEATURE_BRANCH="$BRANCH_NAME"
                fi
            fi
        else
            error "Failed to push branch $BRANCH_NAME"
        fi
    else
        log "No changes to commit"
        git checkout "$MAIN_BRANCH"
        git branch -D "$BRANCH_NAME" 2>/dev/null || true
    fi
    
    # Return to main for next iteration (unless chained mode)
    if [ "$BRANCH_STRATEGY" != "chained" ]; then
        git checkout "$MAIN_BRANCH" 2>/dev/null
    fi
done

# ─────────────────────────────────────────────
# STEP 4: Summary
# ─────────────────────────────────────────────

STEP_DURATION=$(( $(date +%s) - STEP_START ))
STEP_TIMINGS+=("Step 3 - Build features: $(format_duration $STEP_DURATION)")

TOTAL_ELAPSED=$(( $(date +%s) - SCRIPT_START ))

section "SUMMARY (total: $(format_duration $TOTAL_ELAPSED))"

echo "Features built: $BUILT"
echo "Features failed: $FAILED"

# Get roadmap status
if [ -f ".specs/roadmap.md" ]; then
    COMPLETED=$(grep -c "| ✅ |" .specs/roadmap.md 2>/dev/null || echo "0")
    PENDING=$(grep -c "| ⬜ |" .specs/roadmap.md 2>/dev/null || echo "0")
    IN_PROGRESS=$(grep -c "| 🔄 |" .specs/roadmap.md 2>/dev/null || echo "0")
    
    echo ""
    echo "Roadmap status:"
    echo "  ✅ Completed: $COMPLETED"
    echo "  🔄 In Progress: $IN_PROGRESS"
    echo "  ⬜ Pending: $PENDING"
fi

echo ""
echo "Step timings:"
for t in "${STEP_TIMINGS[@]}"; do
    echo "  $t"
done

if [ ${#FEATURE_TIMINGS[@]} -gt 0 ]; then
    echo ""
    echo "Per-feature timings:"
    for t in "${FEATURE_TIMINGS[@]}"; do
        echo "  $t"
    done
fi

echo ""
echo "Total time: $(format_duration $TOTAL_ELAPSED)"

# Notify via Slack if configured
if [ "$BUILT" -gt 0 ] && [ -n "$SLACK_REPORT_CHANNEL" ]; then
    slack_prompt="
Post a message to Slack channel $SLACK_REPORT_CHANNEL:

🌙 **Overnight Run Complete**

Features built: $BUILT
Features failed: $FAILED

Roadmap: $COMPLETED completed, $PENDING pending

Check GitHub for draft PRs to review.
"
    run_agent "$TRIAGE_MODEL" "$slack_prompt"
fi

success "Overnight run complete!"
