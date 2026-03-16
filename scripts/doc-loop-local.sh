#!/bin/bash
# doc-loop-local.sh
# Document an existing codebase by discovering files, grouping by domain,
# and running /document-code on each group in a fresh agent context.
#
# Philosophy: "Document, don't fix."
# Tests are written to match current behavior. If they fail, log the finding
# and move on — don't try to fix code during documentation.
#
# Usage:
#   ./scripts/doc-loop-local.sh                  # Full run (discovery + doc loop)
#   ./scripts/doc-loop-local.sh --continue       # Resume from existing doc-queue.md
#   ./scripts/doc-loop-local.sh --discovery-only # Just create the queue, don't process
#   ./scripts/doc-loop-local.sh --verify-only    # Just run final verification
#   ./scripts/doc-loop-local.sh --scope src/auth # Only discover/document this directory
#
# CONFIG: set in .env.local or pass as env vars (env vars override .env.local)
#
# CLI_PROVIDER: cursor (default) or claude
#
# AGENT_MODEL: Default model for all agents (empty = CLI default)
# DISCOVERY_MODEL: Model for discovery phase (overrides AGENT_MODEL)
# DOC_MODEL: Model for per-item documentation (overrides AGENT_MODEL)
#
# MAX_ITEMS: Max queue items to process (default: 200)
# COMMIT_EVERY: Commit progress every N items (default: 5)
# DOC_WRITE_TESTS: Write tests for documented code (default: true)
# TEST_CHECK_CMD: Test runner (auto-detected). Set "skip" to disable.
#
# RATE_LIMIT_BACKOFF: Initial wait on rate limit (default: 60)
# RATE_LIMIT_MAX_WAIT: Max wait before giving up (default: 18000 = 5h)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

# ── Load .env.local (command-line env wins over file) ────────────────────

if [ -f "$PROJECT_DIR/.env.local" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            [[ -n "${!key+x}" ]] && continue
            value="${BASH_REMATCH[2]}"
            if [[ "$value" =~ ^\"([^\"]*)\" ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ "$value" =~ ^\'([^\']*)\' ]]; then
                value="${BASH_REMATCH[1]}"
            else
                value="${value%%#*}"
                value="${value%"${value##*[![:space:]]}"}"
            fi
            export "$key=$value"
        fi
    done < "$PROJECT_DIR/.env.local"
fi

# ── Config ───────────────────────────────────────────────────────────────

CLI_PROVIDER="${CLI_PROVIDER:-cursor}"
MAX_ITEMS="${MAX_ITEMS:-200}"
COMMIT_EVERY="${COMMIT_EVERY:-5}"
DOC_WRITE_TESTS="${DOC_WRITE_TESTS:-true}"

AGENT_MODEL="${AGENT_MODEL:-}"
DISCOVERY_MODEL="${DISCOVERY_MODEL:-}"
DOC_MODEL="${DOC_MODEL:-}"

RATE_LIMIT_BACKOFF="${RATE_LIMIT_BACKOFF:-60}"
RATE_LIMIT_MAX_WAIT="${RATE_LIMIT_MAX_WAIT:-18000}"

DOC_QUEUE="$PROJECT_DIR/.specs/doc-queue.md"
NEEDS_REVIEW="$PROJECT_DIR/.specs/needs-review.md"
CODEBASE_SUMMARY="$PROJECT_DIR/.specs/codebase-summary.md"

# ── CLI args ─────────────────────────────────────────────────────────────

MODE="full"
SCOPE=""
for arg in "$@"; do
    case "$arg" in
        --continue)       MODE="continue" ;;
        --discovery-only) MODE="discovery" ;;
        --verify-only)    MODE="verify" ;;
        --scope)          : ;;  # next arg is scope
        *)
            if [ "$prev_arg" = "--scope" ]; then
                SCOPE="$arg"
            fi
            ;;
    esac
    prev_arg="$arg"
done
# Handle --scope=path format
for arg in "$@"; do
    if [[ "$arg" == --scope=* ]]; then
        SCOPE="${arg#--scope=}"
    fi
done

# ── Helpers ──────────────────────────────────────────────────────────────

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

# ── Validate CLI provider ────────────────────────────────────────────────

if [ "$CLI_PROVIDER" = "claude" ]; then
    command -v claude &>/dev/null || { fail "Claude Code CLI not found. Install from: https://code.claude.com"; exit 1; }
else
    command -v agent &>/dev/null || { fail "Cursor CLI (agent) not found. Install from: https://cursor.com/cli"; exit 1; }
fi

# ── Auto-detect test command ─────────────────────────────────────────────

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

# ── Agent runner (supports Cursor CLI and Claude Code) ───────────────────

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

# ── Queue helpers ────────────────────────────────────────────────────────

count_pending() {
    if [ ! -f "$DOC_QUEUE" ]; then echo "0"; return; fi
    grep -c '⬜' "$DOC_QUEUE" 2>/dev/null || echo "0"
}

count_total() {
    if [ ! -f "$DOC_QUEUE" ]; then echo "0"; return; fi
    grep -cE '^\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|' "$DOC_QUEUE" 2>/dev/null | tail -1 || echo "0"
}

# Returns: num|domain|files|type
get_next_pending() {
    if [ ! -f "$DOC_QUEUE" ]; then return 1; fi
    local line
    line=$(grep '⬜' "$DOC_QUEUE" | head -1)
    if [ -z "$line" ]; then return 1; fi
    echo "$line" | awk -F'|' '{
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        gsub(/^[ \t]+|[ \t]+$/, "", $3);
        gsub(/^[ \t]+|[ \t]+$/, "", $4);
        gsub(/^[ \t]+|[ \t]+$/, "", $5);
        print $2 "|" $3 "|" $4 "|" $5
    }'
}

mark_queue_status() {
    local item_num="$1"
    local status_emoji="$2"
    if [ ! -f "$DOC_QUEUE" ]; then return; fi
    sed -i.bak -E "/\| *${item_num} *\|/s/⬜|🔄|✅|🟡|❌/${status_emoji}/g" "$DOC_QUEUE"
    rm -f "${DOC_QUEUE}.bak"
}

# ── Prompts ──────────────────────────────────────────────────────────────

discovery_prompt() {
    local scope_hint=""
    if [ -n "$SCOPE" ]; then
        scope_hint="
SCOPE: Only scan files under '$SCOPE'. Ignore files outside this directory."
    fi

    local test_hint=""
    if [ -n "$TEST_CMD" ]; then
        test_hint="
Test command detected: $TEST_CMD"
    fi

    echo "
You are the DISCOVERY agent for documenting an existing codebase.
Your job: scan the codebase, understand its structure, and create a documentation queue.

DO NOT write any specs, tests, or documentation. Only analyze and create the queue.
$scope_hint$test_hint

## Steps

1. **Detect environment**: Language, framework, test runner, source directories
2. **Scan all source files** in scope (skip: node_modules, dist, .git, generated files, config files, type definitions, entry-point re-exports)
3. **Check existing coverage**: For each file, check if a feature spec already exists in .specs/features/
4. **Group by domain**: Related files that should be documented together (e.g., a component + its hook, an API route + its service). Use directory structure as the primary grouping signal. Each group = 1 queue item.
5. **Classify each group**: component, service, api, hook, util, model, page, config
6. **Run the existing test suite** (if detected) and record baseline results — DO NOT try to fix any failures
7. **Create .specs/codebase-summary.md** with:
   - Project overview (language, framework, structure)
   - Baseline test results (X passing, Y failing, Z skipped — pre-existing)
   - Directory purposes
   - Total files in scope vs already documented
8. **Create .specs/doc-queue.md** with the format below

## doc-queue.md Format

IMPORTANT: Use this EXACT format. The automation script parses this table.

\`\`\`markdown
# Documentation Queue

Generated: $(date '+%Y-%m-%d')
Environment: {language} + {framework}, {test runner}
Scope: ${SCOPE:-full codebase}
Total files: {X}
Already documented: {Y}
Items to document: {Z}

## Baseline

Test suite: {X passing, Y failing} (pre-existing, not our problem)
Build status: {clean | N errors} (pre-existing)

## Queue

| # | Domain | Files | Type | Status |
|---|--------|-------|------|--------|
| 1 | {domain} | {comma-separated file paths} | {type} | ⬜ |
| 2 | {domain} | {file paths} | {type} | ⬜ |
\`\`\`

## Grouping Rules

- Group files that share a domain/feature (auth, deals, users, etc.)
- Max 5 files per group (if more, split into sub-groups)
- Files already fully documented (spec + test + test-doc) → skip entirely
- Files partially documented → include, note what's missing
- Order: infrastructure/utils first, then features, then pages/views last

## Output Signals

After completion, output EXACTLY ONE of:
DISCOVERY_COMPLETE: {number of items in queue}
DISCOVERY_FAILED: {reason}
"
}

doc_prompt() {
    local item_num="$1"
    local domain="$2"
    local files="$3"
    local file_type="$4"

    local test_hint=""
    if [ "$DOC_WRITE_TESTS" = "true" ] && [ -n "$TEST_CMD" ]; then
        test_hint="
5. **Write passing tests**: Write tests that PASS against the current implementation. These document reality, not aspirations.
6. **Run your new tests**: Execute them with \`$TEST_CMD\` (or the appropriate subset command).
   - If tests PASS: great, continue
   - If tests FAIL after one fix attempt: log the failing tests in the spec's Learnings section as 'Discovered behavior gap' and continue. Do NOT keep retrying.
7. **Create test documentation**: Create .specs/test-suites/ doc for the test file"
    else
        test_hint="
5. **Skip tests**: Test writing is disabled for this run (DOC_WRITE_TESTS=false)"
    fi

    echo "
You are the DOCUMENTATION agent. Your job: read existing code and generate specs + tests that document its ACTUAL behavior.

PHILOSOPHY: Document, don't fix. You are capturing reality, not defining desired behavior.

## Your Assignment

Item #$item_num | Domain: $domain | Type: $file_type
Files to document: $files

## Steps

1. **Read all source files** listed above. Understand exports, behaviors, edge cases handled, error states.
2. **Check for existing specs**: Look in .specs/features/$domain/ for existing specs covering these files. If found, update rather than recreate.
3. **Generate feature spec(s)**: Create .specs/features/$domain/{name}.feature.md with:
   - YAML frontmatter (feature, domain, source, status: documented, created, updated)
   - Gherkin scenarios describing ACTUAL current behavior
   - ASCII mockup if UI component
   - Note any behaviors that seem unintentional under '## Potential Issues'
$test_hint
8. **Update mapping**: Run ./scripts/generate-mapping.sh if it exists
9. **Create component stubs**: If UI components, create stubs in .specs/design-system/components/

## Rules

- **Be honest**: Document what the code does, even if it seems wrong
- **Flag issues**: Note potential bugs as 'Potential Issues', don't fix them
- **No code changes**: Do NOT modify any source files. Only create .specs/ and test files.
- **Passing tests**: Tests must pass against CURRENT code. If they don't, you misread the code.
- **One retry**: If tests fail, re-read the code and fix the TEST (not the source). If still failing, log as discovered issue and move on.

## Output Signals

After completion, output EXACTLY ONE of:
DOC_COMPLETE: $item_num
DOC_PARTIAL: $item_num — {what couldn't be fully documented and why}
DOC_FAILED: $item_num — {reason}

Also output (when DOC_COMPLETE or DOC_PARTIAL):
SPEC_FILES: {comma-separated paths to spec files created/updated}
TEST_FILES: {comma-separated paths to test files created, or 'none'}
"
}

verification_prompt() {
    echo "
You are the VERIFICATION agent. The documentation loop has finished.
Your job: verify coverage and produce a final report.

## Steps

1. **Read .specs/doc-queue.md** to understand what was processed
2. **Count coverage**:
   - How many items were fully documented (✅)?
   - How many were partial (🟡)?
   - How many failed (❌)?
   - How many are still pending (⬜)?
3. **Verify specs exist**: For each ✅ item, confirm the spec file actually exists
4. **Run test suite** (if available: $TEST_CMD) — record results but do NOT fix anything
5. **Check .specs/needs-review.md** for items needing attention
6. **Update .specs/codebase-summary.md** with final numbers
7. **Regenerate mapping**: Run ./scripts/generate-mapping.sh if it exists

## Output

Print a clear summary:

\`\`\`
═══════════════════════════════════════════════════════════════════
                    DOCUMENTATION COVERAGE: XX%
═══════════════════════════════════════════════════════════════════

Queue items:          N
Fully documented:     X  (✅)
Partially documented: Y  (🟡) — see needs-review.md
Failed:               Z  (❌) — see needs-review.md
Still pending:        W  (⬜)

Feature specs:       A created
Test files:          B created
Test documentation:  C created

Baseline test suite: {X passing, Y failing}
Post-doc test suite: {X passing, Y failing}

Files needing review: .specs/needs-review.md
═══════════════════════════════════════════════════════════════════
\`\`\`

Output signal:
VERIFICATION_COMPLETE: {coverage percentage}
"
}

# ── Needs-review logger ──────────────────────────────────────────────────

log_needs_review() {
    local item_num="$1"
    local domain="$2"
    local files="$3"
    local reason="$4"

    mkdir -p "$(dirname "$NEEDS_REVIEW")"

    if [ ! -f "$NEEDS_REVIEW" ]; then
        cat > "$NEEDS_REVIEW" << 'HEADER'
# Files Needing Review

Items that couldn't be fully documented during the automated doc-loop.
Review these manually or re-run with `/document-code {feature}`.

---

HEADER
    fi

    cat >> "$NEEDS_REVIEW" << EOF

## Item #$item_num: $domain ($(date '+%Y-%m-%d %H:%M'))

**Files**: $files
**Reason**: $reason

---
EOF
}

# ── Main ─────────────────────────────────────────────────────────────────

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  doc-loop-local.sh — Document an existing codebase       ║"
echo "║  Philosophy: document, don't fix                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "CLI provider:    $CLI_PROVIDER"
echo "Mode:            $MODE"
[ -n "$SCOPE" ] && echo "Scope:           $SCOPE"
echo "Max items:       $MAX_ITEMS"
echo "Commit every:    $COMMIT_EVERY items"
echo "Write tests:     $DOC_WRITE_TESTS"
[ -n "$TEST_CMD" ] && echo "Test command:    $TEST_CMD"
echo "Models:          default=${AGENT_MODEL:-CLI default} discovery=${DISCOVERY_MODEL:-↑} doc=${DOC_MODEL:-↑}"
echo ""

# ── Phase 1: Discovery ──────────────────────────────────────────────────

if [ "$MODE" = "verify" ]; then
    log "Skipping to verification..."
elif [ "$MODE" = "continue" ]; then
    if [ ! -f "$DOC_QUEUE" ]; then
        fail "No doc-queue.md found. Run without --continue first."
        exit 1
    fi
    pending=$(count_pending)
    log "Resuming from existing doc-queue.md ($pending items pending)"
else
    echo "═══════════════════════════════════════════════════════════"
    log "PHASE 1: DISCOVERY"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    mkdir -p "$PROJECT_DIR/.specs"

    DISCOVERY_OUTPUT=$(mktemp)
    run_agent "$DISCOVERY_MODEL" "$(discovery_prompt)" 2>&1 | tee "$DISCOVERY_OUTPUT" || true
    DISCOVERY_RESULT=$(cat "$DISCOVERY_OUTPUT")
    rm -f "$DISCOVERY_OUTPUT"

    if echo "$DISCOVERY_RESULT" | grep -q "DISCOVERY_COMPLETE"; then
        queue_count=$(echo "$DISCOVERY_RESULT" | grep "DISCOVERY_COMPLETE" | tail -1 | cut -d: -f2- | xargs)
        success "Discovery complete: $queue_count items in queue"

        if [ ! -f "$DOC_QUEUE" ]; then
            fail "Discovery agent did not create doc-queue.md"
            exit 1
        fi

        git add .specs/doc-queue.md .specs/codebase-summary.md 2>/dev/null || true
        git commit -m "chore: doc-loop discovery — $queue_count items queued" --allow-empty 2>/dev/null || true
    elif echo "$DISCOVERY_RESULT" | grep -q "DISCOVERY_FAILED"; then
        reason=$(echo "$DISCOVERY_RESULT" | grep "DISCOVERY_FAILED" | tail -1 | cut -d: -f2-)
        fail "Discovery failed:$reason"
        exit 1
    else
        fail "Discovery did not produce a clear signal"
        exit 1
    fi

    if [ "$MODE" = "discovery" ]; then
        echo ""
        success "Discovery-only mode. Queue created at .specs/doc-queue.md"
        log "Review the queue, then run: ./scripts/doc-loop-local.sh --continue"
        echo ""
        exit 0
    fi
fi

# ── Phase 2: Documentation Loop ─────────────────────────────────────────

if [ "$MODE" != "verify" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    log "PHASE 2: DOCUMENTATION LOOP"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    ITEMS_PROCESSED=0
    ITEMS_COMPLETE=0
    ITEMS_PARTIAL=0
    ITEMS_FAILED=0
    ITEMS_SINCE_COMMIT=0
    LOOP_TIMINGS=()

    while true; do
        if [ "$ITEMS_PROCESSED" -ge "$MAX_ITEMS" ]; then
            log "Reached MAX_ITEMS ($MAX_ITEMS). Stopping."
            break
        fi

        next_item=$(get_next_pending)
        if [ -z "$next_item" ]; then
            log "No more pending items in queue."
            break
        fi

        ITEM_START=$(date +%s)
        ITEMS_PROCESSED=$((ITEMS_PROCESSED + 1))

        item_num=$(echo "$next_item" | cut -d'|' -f1)
        domain=$(echo "$next_item" | cut -d'|' -f2)
        files=$(echo "$next_item" | cut -d'|' -f3)
        file_type=$(echo "$next_item" | cut -d'|' -f4)

        pending=$(count_pending)
        elapsed_so_far=$(( ITEM_START - SCRIPT_START ))

        echo ""
        echo "───────────────────────────────────────────────────────────"
        log "Item #$item_num: $domain ($file_type) | pending: $pending | elapsed: $(format_duration $elapsed_so_far)"
        log "  Files: $files"
        echo "───────────────────────────────────────────────────────────"

        mark_queue_status "$item_num" "🔄"

        DOC_OUTPUT=$(mktemp)
        run_agent "$DOC_MODEL" "$(doc_prompt "$item_num" "$domain" "$files" "$file_type")" 2>&1 | tee "$DOC_OUTPUT" || true
        DOC_RESULT=$(cat "$DOC_OUTPUT")
        rm -f "$DOC_OUTPUT"

        item_end=$(date +%s)
        item_duration=$((item_end - ITEM_START))

        if echo "$DOC_RESULT" | grep -q "DOC_COMPLETE: *$item_num"; then
            mark_queue_status "$item_num" "✅"
            ITEMS_COMPLETE=$((ITEMS_COMPLETE + 1))
            success "Item #$item_num documented: $domain ($(format_duration $item_duration))"
            LOOP_TIMINGS+=("✓ #$item_num $domain: $(format_duration $item_duration)")

        elif echo "$DOC_RESULT" | grep -q "DOC_PARTIAL: *$item_num"; then
            partial_reason=$(echo "$DOC_RESULT" | grep "DOC_PARTIAL" | tail -1 | sed "s/.*DOC_PARTIAL: *$item_num *— *//" | xargs)
            mark_queue_status "$item_num" "🟡"
            ITEMS_PARTIAL=$((ITEMS_PARTIAL + 1))
            warn "Item #$item_num partial: $partial_reason ($(format_duration $item_duration))"
            log_needs_review "$item_num" "$domain" "$files" "$partial_reason"
            LOOP_TIMINGS+=("🟡 #$item_num $domain: $(format_duration $item_duration)")

        else
            fail_reason="No clear signal from documentation agent"
            if echo "$DOC_RESULT" | grep -q "DOC_FAILED: *$item_num"; then
                fail_reason=$(echo "$DOC_RESULT" | grep "DOC_FAILED" | tail -1 | sed "s/.*DOC_FAILED: *$item_num *— *//" | xargs)
            fi
            mark_queue_status "$item_num" "❌"
            ITEMS_FAILED=$((ITEMS_FAILED + 1))
            fail "Item #$item_num failed: $fail_reason ($(format_duration $item_duration))"
            log_needs_review "$item_num" "$domain" "$files" "$fail_reason"
            LOOP_TIMINGS+=("✗ #$item_num $domain: $(format_duration $item_duration)")
        fi

        # Periodic commits
        ITEMS_SINCE_COMMIT=$((ITEMS_SINCE_COMMIT + 1))
        if [ "$ITEMS_SINCE_COMMIT" -ge "$COMMIT_EVERY" ]; then
            log "Committing progress ($ITEMS_SINCE_COMMIT items since last commit)..."
            git add -A 2>/dev/null || true
            git commit -m "chore: doc-loop progress — $ITEMS_COMPLETE documented, $ITEMS_PARTIAL partial, $ITEMS_FAILED failed" --allow-empty 2>/dev/null || true
            ITEMS_SINCE_COMMIT=0
            success "Progress committed"
        fi
    done

    # Final commit for any remaining work
    if [ "$ITEMS_SINCE_COMMIT" -gt 0 ]; then
        git add -A 2>/dev/null || true
        git commit -m "chore: doc-loop complete — $ITEMS_COMPLETE documented, $ITEMS_PARTIAL partial, $ITEMS_FAILED failed" --allow-empty 2>/dev/null || true
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    success "Documentation loop finished"
    echo "  Complete: $ITEMS_COMPLETE"
    echo "  Partial:  $ITEMS_PARTIAL"
    echo "  Failed:   $ITEMS_FAILED"
    echo ""
fi

# ── Phase 3: Verification ───────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════"
log "PHASE 3: VERIFICATION"
echo "═══════════════════════════════════════════════════════════"
echo ""

VERIFY_OUTPUT=$(mktemp)
run_agent "$DISCOVERY_MODEL" "$(verification_prompt)" 2>&1 | tee "$VERIFY_OUTPUT" || true
VERIFY_RESULT=$(cat "$VERIFY_OUTPUT")
rm -f "$VERIFY_OUTPUT"

if echo "$VERIFY_RESULT" | grep -q "VERIFICATION_COMPLETE"; then
    coverage=$(echo "$VERIFY_RESULT" | grep "VERIFICATION_COMPLETE" | tail -1 | cut -d: -f2- | xargs)
    success "Verification complete: $coverage coverage"
fi

git add -A 2>/dev/null || true
git commit -m "chore: doc-loop verification complete" --allow-empty 2>/dev/null || true

# ── Final Summary ────────────────────────────────────────────────────────

total_elapsed=$(( $(date +%s) - SCRIPT_START ))

echo ""
echo "═══════════════════════════════════════════════════════════"
success "DOCUMENTATION COMPLETE (total: $(format_duration $total_elapsed))"
echo ""
if [ "$MODE" != "verify" ] && [ ${#LOOP_TIMINGS[@]} -gt 0 ]; then
    echo "  Per-item timings:"
    for t in "${LOOP_TIMINGS[@]}"; do
        echo "    $t"
    done
    echo ""
fi
echo "  Queue:         $DOC_QUEUE"
echo "  Summary:       $CODEBASE_SUMMARY"
[ -f "$NEEDS_REVIEW" ] && echo "  Needs review:  $NEEDS_REVIEW"
echo ""
echo "  Total time: $(format_duration $total_elapsed)"
echo "═══════════════════════════════════════════════════════════"
echo ""
