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

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -f "$PROJECT_DIR/.env.local" ]; then
    source "$PROJECT_DIR/.env.local"
fi

# Defaults
MAX_FEATURES="${MAX_FEATURES:-4}"
BRANCH_STRATEGY="${BRANCH_STRATEGY:-chained}"
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

# ─────────────────────────────────────────────
# STEP 0: Ensure we're on main and up to date
# ─────────────────────────────────────────────

section "STEP 0: Sync with main"

git checkout main 2>/dev/null || git checkout master 2>/dev/null
MAIN_BRANCH=$(git branch --show-current)
git pull origin "$MAIN_BRANCH"
success "Synced with $MAIN_BRANCH"

# ─────────────────────────────────────────────
# STEP 1: Rebase any existing auto PRs
# ─────────────────────────────────────────────

section "STEP 1: Rebase existing auto PRs"

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

# ─────────────────────────────────────────────
# STEP 2: Triage Slack/Jira → Roadmap
# ─────────────────────────────────────────────

section "STEP 2: Triage new requests"

log "Running /roadmap-triage to scan Slack/Jira..."

agent -p --force --output-format text "
Run the /roadmap-triage command to:
1. Scan Slack channel $SLACK_FEATURE_CHANNEL for feature requests
2. Scan Jira project $JIRA_PROJECT_KEY for tickets with label 'auto-ok'
3. Add new items to .specs/roadmap.md in the Ad-hoc Requests section
4. Create Jira tickets for Slack items (if configured)
5. Mark sources as triaged (reply to Slack, comment on Jira)
6. Commit the roadmap changes

If no new requests found, that's fine - continue.
"

success "Triage complete"

# ─────────────────────────────────────────────
# STEP 3: Build features from roadmap
# ─────────────────────────────────────────────

section "STEP 3: Build features from roadmap"

BUILT=0
FAILED=0
LAST_FEATURE_BRANCH=""

for i in $(seq 1 "$MAX_FEATURES"); do
    log "Build iteration $i/$MAX_FEATURES..."
    
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
    
    agent -p --force --output-format text "
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

After completion, output:
FEATURE_BUILT: {feature name}
or
NO_FEATURES_READY
or
BUILD_FAILED: {reason}
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
        warn "Build failed: $REASON"
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
                    success "Created PR: $PR_URL"
                    BUILT=$((BUILT + 1))
                    # Track branch for chained mode
                    if [ "$BRANCH_STRATEGY" = "chained" ]; then
                        LAST_FEATURE_BRANCH="$BRANCH_NAME"
                    fi
                fi
            else
                success "Branch pushed (PR not created - gh CLI unavailable)"
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

section "SUMMARY"

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

# Notify via Slack if configured
if [ "$BUILT" -gt 0 ] && [ -n "$SLACK_REPORT_CHANNEL" ]; then
    agent -p --force --output-format text "
Post a message to Slack channel $SLACK_REPORT_CHANNEL:

🌙 **Overnight Run Complete**

Features built: $BUILT
Features failed: $FAILED

Roadmap: $COMPLETED completed, $PENDING pending

Check GitHub for draft PRs to review.
"
fi

success "Overnight run complete!"
