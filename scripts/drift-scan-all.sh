#!/bin/bash
# drift-scan-all.sh
# Run /catch-drift against every spec in .specs/features/ (or a filtered subset).
# Each spec gets its own fresh agent invocation. Reports a summary at the end.
#
# Usage:
#   ./scripts/drift-scan-all.sh                         # All specs
#   ./scripts/drift-scan-all.sh --domain chatbot        # Only chatbot domain
#   ./scripts/drift-scan-all.sh --status implemented    # Only implemented specs
#   ./scripts/drift-scan-all.sh --fix                   # Auto-fix drift (default: report only)
#   ./scripts/drift-scan-all.sh --domain intake --fix   # Combine filters
#
# CONFIG (set in .env.local or env):
#   CLI_PROVIDER        - cursor (default) or claude
#   AGENT_MODEL         - Default model for all steps (fallback)
#   DRIFT_MODEL         - Model for drift-check agents (overrides AGENT_MODEL)
#   MAX_DRIFT_RETRIES   - Retries per spec if fix breaks build/tests (default: 1)
#   COOLDOWN_SECONDS    - Pause between specs for memory reclaim (default: 15)
#   MAX_HOURS           - Hard time limit (default: 4)
#   MEMORY_PRESSURE_THRESHOLD - "warn" (default) or "critical"
#   TEST_CHECK_CMD      - Test command (auto-detected if not set, "skip" to disable)
#   BUILD_CHECK_CMD     - Build command (auto-detected if not set, "skip" to disable)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

# ── Parse CLI args ────────────────────────────────────────────────────────

FILTER_DOMAIN=""
FILTER_STATUS=""
FIX_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)   FILTER_DOMAIN="$2"; shift 2 ;;
        --status)   FILTER_STATUS="$2"; shift 2 ;;
        --fix)      FIX_MODE=true; shift ;;
        --help|-h)
            echo "Usage: $0 [--domain <domain>] [--status <status>] [--fix]"
            echo ""
            echo "Options:"
            echo "  --domain <domain>   Only check specs in this domain (e.g. chatbot, intake)"
            echo "  --status <status>   Only check specs with this status (e.g. implemented, tested)"
            echo "  --fix               Auto-fix drift (default: report only)"
            echo ""
            echo "Config (env or .env.local):"
            echo "  CLI_PROVIDER, DRIFT_MODEL, COOLDOWN_SECONDS, MAX_HOURS, etc."
            exit 0
            ;;
        *)
            echo "Unknown argument: $1 (use --help for usage)"
            exit 1
            ;;
    esac
done

# ── Load .env.local (command-line env wins) ───────────────────────────────

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

# ── Defaults ──────────────────────────────────────────────────────────────

CLI_PROVIDER="${CLI_PROVIDER:-cursor}"
AGENT_MODEL="${AGENT_MODEL:-composer-1.5}"
DRIFT_MODEL="${DRIFT_MODEL:-}"
MAX_DRIFT_RETRIES="${MAX_DRIFT_RETRIES:-1}"
COOLDOWN_SECONDS="${COOLDOWN_SECONDS:-15}"
MAX_HOURS="${MAX_HOURS:-4}"
MEMORY_PRESSURE_THRESHOLD="${MEMORY_PRESSURE_THRESHOLD:-warn}"

# ── Logging ───────────────────────────────────────────────────────────────

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

# ── CLI check ─────────────────────────────────────────────────────────────

if [ "$CLI_PROVIDER" = "claude" ]; then
    command -v claude &>/dev/null || { fail "Claude Code CLI not found"; exit 1; }
else
    command -v agent &>/dev/null || { fail "Cursor CLI (agent) not found"; exit 1; }
fi

# ── Agent runner ──────────────────────────────────────────────────────────

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

# ── Auto-detect build/test commands ───────────────────────────────────────

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

BUILD_CMD=$(detect_build_check)
TEST_CMD=$(detect_test_check)

# ── Resource guards ───────────────────────────────────────────────────────

MAX_SECONDS=$((MAX_HOURS * 3600))

check_time_limit() {
    local elapsed=$(( $(date +%s) - SCRIPT_START ))
    if [ "$elapsed" -ge "$MAX_SECONDS" ]; then
        warn "Time limit reached (${MAX_HOURS}h). Stopping."
        return 1
    fi
    return 0
}

get_memory_pressure() {
    if command -v sysctl &>/dev/null; then
        local level
        level=$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null || echo "0")
        case "$level" in
            1) echo "normal" ;; 2) echo "warn" ;; 4) echo "critical" ;; *) echo "normal" ;;
        esac
    else
        echo "normal"
    fi
}

check_memory_pressure() {
    local pressure
    pressure=$(get_memory_pressure)
    case "$pressure" in
        critical) fail "Memory pressure is CRITICAL. Stopping."; return 1 ;;
        warn)
            if [ "$MEMORY_PRESSURE_THRESHOLD" = "warn" ]; then
                fail "Memory pressure is elevated. Stopping."; return 1
            else
                warn "Memory pressure elevated but continuing (threshold=$MEMORY_PRESSURE_THRESHOLD)"
            fi
            ;;
    esac
    return 0
}

run_cooldown() {
    if [ "$COOLDOWN_SECONDS" -gt 0 ]; then
        log "Cooldown: ${COOLDOWN_SECONDS}s..."
        sleep "$COOLDOWN_SECONDS"
    fi
}

check_resource_guards() {
    check_time_limit || return 1
    check_memory_pressure || return 1
    return 0
}

# ── Extract source files from spec frontmatter ────────────────────────────

extract_source_from_spec() {
    local spec_file="$1"
    local source=""

    # Extract source: field from YAML frontmatter
    source=$(awk '/^---$/{n++; next} n==1 && /^source:/{print $2; exit}' "$spec_file" 2>/dev/null || echo "")

    # If source file doesn't exist, try to find related files from the spec content
    if [ -n "$source" ] && [ -f "$source" ]; then
        echo "$source"
        return
    fi

    # Fallback: look for Source File reference in body
    local body_source
    body_source=$(grep -m1 '^\*\*Source File\*\*:' "$spec_file" 2>/dev/null | sed 's/.*: *//' | xargs 2>/dev/null || echo "")
    if [ -n "$body_source" ] && [ -f "$body_source" ]; then
        echo "$body_source"
        return
    fi

    # Return whatever we found even if file doesn't exist (agent will figure it out)
    echo "${source:-$body_source}"
}

# ── Discover specs ────────────────────────────────────────────────────────

discover_specs() {
    local specs_dir=".specs/features"
    if [ ! -d "$specs_dir" ]; then
        fail "No specs directory found at $specs_dir"
        exit 1
    fi

    local all_specs
    all_specs=$(find "$specs_dir" -name "*.feature.md" -type f | sort)

    for spec in $all_specs; do
        # Filter by domain
        if [ -n "$FILTER_DOMAIN" ]; then
            local domain
            domain=$(echo "$spec" | sed "s|$specs_dir/||" | cut -d/ -f1)
            if [ "$domain" != "$FILTER_DOMAIN" ]; then
                continue
            fi
        fi

        # Filter by status
        if [ -n "$FILTER_STATUS" ]; then
            local status
            status=$(awk '/^---$/{n++; next} n==1 && /^status:/{print $2; exit}' "$spec" 2>/dev/null || echo "")
            if [ "$status" != "$FILTER_STATUS" ]; then
                continue
            fi
        fi

        echo "$spec"
    done
}

# ── Main loop ─────────────────────────────────────────────────────────────

SPECS=$(discover_specs)
TOTAL=$(echo "$SPECS" | grep -c . || echo "0")

if [ "$TOTAL" -eq 0 ]; then
    fail "No specs found matching filters (domain=${FILTER_DOMAIN:-any}, status=${FILTER_STATUS:-any})"
    exit 1
fi

MODE_LABEL="report-only"
if [ "$FIX_MODE" = true ]; then
    MODE_LABEL="auto-fix"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  DRIFT SCAN ALL SPECS"
echo "═══════════════════════════════════════════════════════════"
echo ""
log "Specs to scan: $TOTAL"
log "Mode: $MODE_LABEL"
log "CLI provider: $CLI_PROVIDER"
log "Model: ${DRIFT_MODEL:-${AGENT_MODEL:-default}}"
log "Domain filter: ${FILTER_DOMAIN:-none}"
log "Status filter: ${FILTER_STATUS:-none}"
log "Build check: ${BUILD_CMD:-disabled}"
log "Test suite: ${TEST_CMD:-disabled}"
log "Max hours: $MAX_HOURS"
log "Cooldown: ${COOLDOWN_SECONDS}s"
echo ""

# Result tracking
CLEAN=0
FIXED=0
DRIFTED=0
SKIPPED=0
ERRORS=0
RESULTS=()

CURRENT=0
for spec_file in $SPECS; do
    CURRENT=$((CURRENT + 1))

    # Resource guards
    if ! check_resource_guards; then
        SKIPPED=$((TOTAL - CURRENT + 1))
        warn "Skipping remaining $SKIPPED specs due to resource limits"
        break
    fi

    # Extract info
    local_source=$(extract_source_from_spec "$spec_file")
    feature_name=$(awk '/^---$/{n++; next} n==1 && /^feature:/{$1=""; print; exit}' "$spec_file" 2>/dev/null | xargs || echo "")
    domain=$(echo "$spec_file" | sed 's|.specs/features/||' | cut -d/ -f1)
    short_name="${feature_name:-$(basename "$spec_file" .feature.md)}"

    echo ""
    log "[$CURRENT/$TOTAL] $short_name ($domain)"
    log "  Spec: $spec_file"
    log "  Source: ${local_source:-<not specified>}"

    SPEC_START=$(date +%s)

    # Build the prompt
    test_context=""
    if [ -n "$TEST_CMD" ]; then
        test_context="
Test command: $TEST_CMD"
    fi

    if [ "$FIX_MODE" = true ]; then
        drift_prompt="
Run /catch-drift for this specific feature. This is an automated scan — do NOT ask for user input.

Spec file: $spec_file
Source files: $local_source$test_context

Instructions:
1. Read the spec file and all its Gherkin scenarios
2. Read each source file listed above (if source is missing, check the spec's Source File reference and frontmatter)
3. Compare: does the code implement what the spec describes?
4. Check: are there behaviors in code not covered by the spec?
5. Check: are there scenarios in the spec not implemented in code?
6. Structural check: if the spec has a '### Program Design' section, compare its file list, key signatures, and call stack against the actual code — update the section to describe reality if it diverged
7. If drift found: update specs, code, or tests as needed (prefer updating specs to match code)
8. If a test command is available, run it and fix any failures — iterate until tests pass
9. Commit all fixes with message: 'fix: reconcile spec drift for $short_name'

IMPORTANT: Your goal is spec+code alignment AND a passing test suite. Keep iterating until both are achieved.

Output EXACTLY ONE of these signals at the end:
NO_DRIFT
DRIFT_FIXED: {brief summary of what was reconciled}
DRIFT_UNRESOLVABLE: {what needs human attention and why}
"
    else
        drift_prompt="
Check for spec-code drift for this feature. This is a READ-ONLY audit — do NOT modify any files. Do NOT ask for user input.

Spec file: $spec_file
Source files: $local_source

Instructions:
1. Read the spec file and all its Gherkin scenarios
2. Read each source file listed above (if source is missing, check the spec's Source File reference and frontmatter)
3. Compare: does the code implement what the spec describes?
4. List any mismatches:
   - Scenarios in spec not implemented in code
   - Behaviors in code not covered by spec
   - API/prop/type differences between spec and code
   - '### Program Design' (files, signatures, call stack) not matching the actual code layout
5. Do NOT modify any files

Output EXACTLY ONE of these signals at the end:
NO_DRIFT
DRIFT_FOUND: {brief summary of mismatches}
"
    fi

    DRIFT_OUTPUT=$(mktemp)
    run_agent "$DRIFT_MODEL" "$drift_prompt" 2>&1 | tee "$DRIFT_OUTPUT" || true
    DRIFT_RESULT=$(cat "$DRIFT_OUTPUT")
    rm -f "$DRIFT_OUTPUT"

    SPEC_DURATION=$(( $(date +%s) - SPEC_START ))
    duration_str=$(format_duration $SPEC_DURATION)

    if echo "$DRIFT_RESULT" | grep -q "NO_DRIFT"; then
        success "$short_name — clean ($duration_str)"
        CLEAN=$((CLEAN + 1))
        RESULTS+=("✓ $short_name — clean ($duration_str)")
    elif echo "$DRIFT_RESULT" | grep -q "DRIFT_FIXED"; then
        fix_summary=$(echo "$DRIFT_RESULT" | grep "DRIFT_FIXED" | tail -1 | cut -d: -f2- | xargs)
        success "$short_name — fixed: $fix_summary ($duration_str)"
        FIXED=$((FIXED + 1))
        RESULTS+=("⚡ $short_name — fixed: $fix_summary ($duration_str)")
    elif echo "$DRIFT_RESULT" | grep -q "DRIFT_FOUND"; then
        drift_summary=$(echo "$DRIFT_RESULT" | grep "DRIFT_FOUND" | tail -1 | cut -d: -f2- | xargs)
        warn "$short_name — drift: $drift_summary ($duration_str)"
        DRIFTED=$((DRIFTED + 1))
        RESULTS+=("⚠ $short_name — drift: $drift_summary ($duration_str)")
    elif echo "$DRIFT_RESULT" | grep -q "DRIFT_UNRESOLVABLE"; then
        unresolvable=$(echo "$DRIFT_RESULT" | grep "DRIFT_UNRESOLVABLE" | tail -1 | cut -d: -f2- | xargs)
        fail "$short_name — unresolvable: $unresolvable ($duration_str)"
        DRIFTED=$((DRIFTED + 1))
        RESULTS+=("✗ $short_name — unresolvable: $unresolvable ($duration_str)")
    else
        warn "$short_name — no clear signal from agent ($duration_str)"
        ERRORS=$((ERRORS + 1))
        RESULTS+=("? $short_name — unclear result ($duration_str)")
    fi

    # Cooldown between specs
    if [ "$CURRENT" -lt "$TOTAL" ]; then
        run_cooldown
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────

TOTAL_ELAPSED=$(( $(date +%s) - SCRIPT_START ))

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  DRIFT SCAN SUMMARY ($(format_duration $TOTAL_ELAPSED))"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Clean (no drift):  $CLEAN"
if [ "$FIX_MODE" = true ]; then
    echo "  Fixed (auto):      $FIXED"
fi
echo "  Drifted:           $DRIFTED"
echo "  Skipped:           $SKIPPED"
echo "  Errors:            $ERRORS"
echo "  Total scanned:     $((CLEAN + FIXED + DRIFTED + ERRORS))"
echo ""

if [ ${#RESULTS[@]} -gt 0 ]; then
    echo "Per-spec results:"
    for r in "${RESULTS[@]}"; do
        echo "  $r"
    done
    echo ""
fi

# Exit code: non-zero if any drift found
if [ "$DRIFTED" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0
