#!/bin/bash
# nightly-review.sh
# Nightly review that extracts learnings from the day's work
# Run BEFORE overnight-autonomous.sh so learnings are available for implementation
#
# CONFIGURATION (set in .env.local):
#   PROJECT_DIR  - Project directory (default: current directory)
#   HOURS_BACK   - How many hours of commits to review (default: 24)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ✗${NC} $1"; }

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -f "$PROJECT_DIR/.env.local" ]; then
    source "$PROJECT_DIR/.env.local"
fi

HOURS_BACK="${HOURS_BACK:-24}"

log "Starting nightly review"
log "Project: $PROJECT_DIR"
log "Reviewing commits from last $HOURS_BACK hours"

cd "$PROJECT_DIR"

# ─────────────────────────────────────────────
# STEP 1: Ensure we're on main and up to date
# ─────────────────────────────────────────────

log "Syncing with main branch..."
git checkout main 2>/dev/null || git checkout master 2>/dev/null
git pull origin "$(git branch --show-current)"
success "Synced with remote"

# ─────────────────────────────────────────────
# STEP 2: Gather context from recent work
# ─────────────────────────────────────────────

log "Gathering recent commits..."

# Get recent commits
RECENT_COMMITS=$(git log --since="${HOURS_BACK} hours ago" --pretty=format:"%h %s" --no-merges 2>/dev/null | head -50)
COMMIT_COUNT=$(echo "$RECENT_COMMITS" | grep -c "." || echo "0")

if [ "$COMMIT_COUNT" -eq 0 ] || [ -z "$RECENT_COMMITS" ]; then
    log "No commits in the last $HOURS_BACK hours. Nothing to review."
    exit 0
fi

log "Found $COMMIT_COUNT commits to review"

# Get changed files
CHANGED_FILES=$(git log --since="${HOURS_BACK} hours ago" --name-only --pretty=format:"" --no-merges 2>/dev/null | sort -u | grep -v "^$" | head -100)

# Get recent PRs (if gh available)
RECENT_PRS=""
if command -v gh &> /dev/null; then
    RECENT_PRS=$(gh pr list --state merged --search "merged:>=$(date -v-${HOURS_BACK}H '+%Y-%m-%d')" --json title,body --jq '.[].title' 2>/dev/null | head -10)
fi

# Check if Cursor CLI is available
if ! command -v agent &> /dev/null; then
    error "Cursor CLI (agent) not found. Install from: https://cursor.com/cli"
    exit 1
fi

# ─────────────────────────────────────────────
# STEP 3: Run learning extraction
# ─────────────────────────────────────────────

log "Extracting learnings from recent work..."

agent -p --force --output-format text "
NIGHTLY REVIEW: Extract learnings from today's work.

## Recent Commits (last $HOURS_BACK hours)

$RECENT_COMMITS

## Changed Files

$CHANGED_FILES

## Recent Merged PRs

$RECENT_PRS

---

INSTRUCTIONS:

1. ANALYZE the commits and changes to understand what was worked on today.

2. For each significant piece of work, identify:
   - **Patterns**: What approaches worked well?
   - **Gotchas**: What edge cases or pitfalls were discovered?
   - **Decisions**: What architectural or design choices were made?
   - **Bug Fixes**: What bugs were fixed and why did they occur?

3. CATEGORIZE each learning:

   a) **Feature-specific learnings**:
      - Find the relevant spec in .specs/features/
      - Add to that spec's '## Learnings' section
      - Format: '### $(date '+%Y-%m-%d')' followed by bullet points
   
   b) **Cross-cutting learnings**:
      - Add to .specs/learnings/{category}.md based on type:
        - testing.md: Mocking, assertions, test patterns
        - performance.md: Optimization, lazy loading, caching
        - security.md: Auth, cookies, validation
        - api.md: Endpoints, data handling, errors
        - design.md: Tokens, components, accessibility
        - general.md: Other patterns
      - Also add brief entry to .specs/learnings/index.md under "Recent Learnings"

4. UPDATE frontmatter:
   - Set 'updated: $(date '+%Y-%m-%d')' in any modified specs

5. RUN drift detection:
   - Check if any specs don't match their implementations
   - Note any drift found in the commit message

6. COMMIT all changes:
   git add .specs/ CLAUDE.md
   git commit -m 'compound: nightly review $(date '+%Y-%m-%d')'
   git push origin main

7. REPORT what was captured:
   - Number of learnings extracted
   - Which files were updated
   - Any drift detected
   - Any learnings promoted to CLAUDE.md

If no significant learnings are found, that's okay - just report 'No new learnings identified.'
"

# ─────────────────────────────────────────────
# STEP 4: Verify and report
# ─────────────────────────────────────────────

# Check if anything was committed
LAST_COMMIT=$(git log -1 --pretty=format:"%s" 2>/dev/null)

if [[ "$LAST_COMMIT" == *"compound: nightly review"* ]]; then
    success "Nightly review complete - learnings committed"
else
    log "Nightly review complete - no new learnings to commit"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
success "Nightly review finished!"
echo "  Commits reviewed: $COMMIT_COUNT"
echo "  Files changed: $(echo "$CHANGED_FILES" | wc -l | tr -d ' ')"
echo "═══════════════════════════════════════════════════════════"
