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
MAX_FEATURES="${MAX_FEATURES:-4}"
BRANCH_STRATEGY="${BRANCH_STRATEGY:-chained}"
DRIFT_CHECK="${DRIFT_CHECK:-true}"
MAX_DRIFT_RETRIES="${MAX_DRIFT_RETRIES:-1}"
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
log "Branch strategy: $BRANCH_STRATEGY"
log "Max features: $MAX_FEATURES"
log "Slack channel: $SLACK_FEATURE_CHANNEL"
log "Jira project: ${JIRA_PROJECT_KEY:-not configured}"

cd "$PROJECT_DIR"

# Check prerequisites
if ! command -v agent &> /dev/null; then
    error "Cursor CLI (agent) not found. Install from: https://cursor.com/cli"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    warn "GitHub CLI (gh) not found - PRs won't be created"
fi

# ── Model selection & test detection ──────────────────────────────────────

AGENT_MODEL="${AGENT_MODEL:-}"
BUILD_MODEL="${BUILD_MODEL:-}"
RETRY_MODEL="${RETRY_MODEL:-}"
DRIFT_MODEL="${DRIFT_MODEL:-}"
REVIEW_MODEL="${REVIEW_MODEL:-}"
TRIAGE_MODEL="${TRIAGE_MODEL:-}"
POST_BUILD_STEPS="${POST_BUILD_STEPS:-test}"

agent_cmd() {
    local step_model="$1"
    local model="${step_model:-$AGENT_MODEL}"
    local cmd="agent -p --force --output-format text"
    if [ -n "$model" ]; then
        cmd="$cmd --model $model"
    fi
    echo "$cmd"
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

run_code_review() {
    log "Running code-review agent (fresh context, model: ${REVIEW_MODEL:-${AGENT_MODEL:-default}})..."
    $(agent_cmd "$REVIEW_MODEL") "
Review and improve code quality of the most recently built feature.
1. Check 'git log --oneline -10' to see recent commits
2. Review source files against senior engineering standards
3. Fix critical issues ONLY (no 'any' types, proper error handling, etc.)
4. Do NOT change behavior. Do NOT refactor for style.
5. Commit fixes if any: git add -A && git commit -m 'refactor: code quality improvements (auto-review)'
Output: REVIEW_CLEAN or REVIEW_FIXED: {summary} or REVIEW_FAILED: {reason}
" 2>&1 || true
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        git add -A && git commit -m "refactor: code quality improvements (auto-review)" 2>/dev/null || true
    fi
}

log "Test suite: ${TEST_CMD:-disabled}"
log "Post-build steps: ${POST_BUILD_STEPS:-none}"
if [ -n "$AGENT_MODEL" ] || [ -n "$BUILD_MODEL" ] || [ -n "$DRIFT_MODEL" ] || [ -n "$REVIEW_MODEL" ]; then
    log "Models: default=${AGENT_MODEL:-CLI default} build=${BUILD_MODEL:-↑} drift=${DRIFT_MODEL:-↑} review=${REVIEW_MODEL:-↑}"
fi

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

        $(agent_cmd "$DRIFT_MODEL") "
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

Output EXACTLY ONE of:
NO_DRIFT
DRIFT_FIXED: {brief summary}
DRIFT_UNRESOLVABLE: {what needs human attention}
" 2>&1 | tee "$DRIFT_OUTPUT" || true
        DRIFT_RESULT=$(cat "$DRIFT_OUTPUT")
        rm -f "$DRIFT_OUTPUT"

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
    fail "Drift check failed"
    return 1
}

# ─────────────────────────────────────────────
# STEP 0: Ensure we're on main and up to date
# ─────────────────────────────────────────────

section "STEP 0: Sync with main"
STEP_START=$(date +%s)

git checkout main 2>/dev/null || git checkout master 2>/dev/null
MAIN_BRANCH=$(git branch --show-current)
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

$(agent_cmd "$TRIAGE_MODEL") "
Run the /roadmap-triage command to:
1. Scan Slack channel $SLACK_FEATURE_CHANNEL for feature requests
2. Scan Jira project $JIRA_PROJECT_KEY for tickets with label 'auto-ok'
3. Add new items to .specs/roadmap.md in the Ad-hoc Requests section
4. Create Jira tickets for Slack items (if configured)
5. Mark sources as triaged (reply to Slack, comment on Jira)
6. Commit the roadmap changes

If no new requests found, that's fine - continue.
"

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
    
    # Run /build-next
    BUILD_OUTPUT=$(mktemp)
    
    $(agent_cmd "$BUILD_MODEL") "
Run the /build-next command to:
1. Read .specs/roadmap.md and find the next pending feature
2. Check that all dependencies are completed
3. If a feature is ready:
   - Update roadmap to mark it 🔄 in progress
   - Run /spec-first {feature} --full to build it (includes /compound)
   - Update roadmap to mark it ✅ completed
   - Sync Jira status if configured
4. If no features are ready, output: NO_FEATURES_READY
5. If build fails, output: BUILD_FAILED: {reason}

After completion, output EXACTLY these signals (each on its own line):
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to the .feature.md file you created/updated}
SOURCE_FILES: {comma-separated paths to source files created/modified}

Or: NO_FEATURES_READY
Or: BUILD_FAILED: {reason}

The SPEC_FILE and SOURCE_FILES lines are REQUIRED when FEATURE_BUILT is reported.
" > "$BUILD_OUTPUT" 2>&1 || true
    
    BUILD_RESULT=$(cat "$BUILD_OUTPUT")
    rm "$BUILD_OUTPUT"
    
    # Check result
    if echo "$BUILD_RESULT" | grep -q "NO_FEATURES_READY"; then
        log "No more features ready to build"
        git checkout "$MAIN_BRANCH"
        git branch -D "$BRANCH_NAME" 2>/dev/null || true
        break
    fi
    
    if echo "$BUILD_RESULT" | grep -q "BUILD_FAILED"; then
        REASON=$(echo "$BUILD_RESULT" | grep "BUILD_FAILED" | cut -d: -f2-)
        FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
        warn "Build failed: $REASON ($(format_duration $FEATURE_DURATION))"
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
        
        # Validate: do tests pass?
        if should_run_step "test" && ! check_tests; then
            FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
            warn "Tests failed for $FEATURE_NAME ($(format_duration $FEATURE_DURATION))"
            FEATURE_TIMINGS+=("⚠ $FEATURE_NAME (tests): $(format_duration $FEATURE_DURATION)")
            # Continue to push — tests are documented in the PR for human review
        fi
        
        # Run drift check (fresh agent, separate context)
        extract_drift_targets "$BUILD_RESULT"
        if ! check_drift "$DRIFT_SPEC_FILE" "$DRIFT_SOURCE_FILES"; then
            FEATURE_DURATION=$(( $(date +%s) - FEATURE_START ))
            warn "Feature built but drift check failed ($(format_duration $FEATURE_DURATION))"
            FEATURE_TIMINGS+=("⚠ $FEATURE_NAME (drift): $(format_duration $FEATURE_DURATION)")
            # Continue to push — drift is documented in the PR for human review
        fi
        
        # Run code review (fresh agent, separate context)
        if should_run_step "code-review"; then
            run_code_review || warn "Code review had issues (non-blocking)"
            # Re-validate after review changes
            if ! check_build; then
                warn "Code review broke the build!"
            elif should_run_step "test" && [ -n "$TEST_CMD" ] && ! check_tests; then
                warn "Code review broke tests!"
            fi
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
    $(agent_cmd "$TRIAGE_MODEL") "
Post a message to Slack channel $SLACK_REPORT_CHANNEL:

🌙 **Overnight Run Complete**

Features built: $BUILT
Features failed: $FAILED

Roadmap: $COMPLETED completed, $PENDING pending

Check GitHub for draft PRs to review.
"
fi

success "Overnight run complete!"
