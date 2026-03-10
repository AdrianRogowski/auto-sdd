#!/bin/bash
# strip-specs.sh
# Strip implementation details from feature specs to create behavioral seeds.
# Copies specs from a source project to a target project, keeping Gherkin scenarios,
# mockups, and user journeys while removing file paths, test refs, and architecture notes.
#
# Usage:
#   ./scripts/strip-specs.sh --source /path/to/old-project --target /path/to/new-project
#   ./scripts/strip-specs.sh --source /old --target /new --features "dashboard-shell,ai-agent"
#   ./scripts/strip-specs.sh --source /old --target /new --include-context
#   ./scripts/strip-specs.sh --source /old --target /new --dry-run
#
# Options:
#   --source PATH       Source project root (required)
#   --target PATH       Target project root (required)
#   --features LIST     Comma-separated feature slugs to include (default: all)
#   --exclude LIST      Comma-separated feature slugs to exclude
#   --include-context   Also copy personas, design tokens, vision, learnings
#   --dry-run           Preview what would be copied/stripped without writing
#   --verbose           Show detailed processing info
#   --help              Show this help message

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SOURCE_DIR=""
TARGET_DIR=""
FEATURES_FILTER=""
EXCLUDE_FILTER=""
INCLUDE_CONTEXT=false
DRY_RUN=false
VERBOSE=false

usage() {
    head -20 "$0" | grep "^#" | sed 's/^# \?//'
    exit 0
}

log()     { echo -e "${GREEN}[strip]${NC} $*"; }
warn()    { echo -e "${YELLOW}[strip]${NC} $*"; }
err()     { echo -e "${RED}[strip]${NC} $*" >&2; }
verbose() { [ "$VERBOSE" = true ] && echo -e "${CYAN}[strip]${NC} $*" || true; }
dry()     { [ "$DRY_RUN" = true ] && echo -e "${BLUE}[dry-run]${NC} $*" || true; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --source)    SOURCE_DIR="$2"; shift 2 ;;
        --target)    TARGET_DIR="$2"; shift 2 ;;
        --features)  FEATURES_FILTER="$2"; shift 2 ;;
        --exclude)   EXCLUDE_FILTER="$2"; shift 2 ;;
        --include-context) INCLUDE_CONTEXT=true; shift ;;
        --dry-run)   DRY_RUN=true; shift ;;
        --verbose)   VERBOSE=true; shift ;;
        --help|-h)   usage ;;
        *) err "Unknown option: $1"; usage ;;
    esac
done

if [ -z "$SOURCE_DIR" ] || [ -z "$TARGET_DIR" ]; then
    err "Both --source and --target are required."
    echo ""
    usage
fi

if [ ! -d "$SOURCE_DIR/.specs" ]; then
    err "Source directory has no .specs/ folder: $SOURCE_DIR"
    exit 1
fi

SOURCE_FEATURES="$SOURCE_DIR/.specs/features"
TARGET_FEATURES="$TARGET_DIR/.specs/features"

if [ ! -d "$SOURCE_FEATURES" ]; then
    err "Source has no feature specs: $SOURCE_FEATURES"
    exit 1
fi

# Convert comma-separated lists to arrays for matching
IFS=',' read -ra INCLUDE_LIST <<< "${FEATURES_FILTER:-}"
IFS=',' read -ra EXCLUDE_LIST <<< "${EXCLUDE_FILTER:-}"

# Trim whitespace from filter entries
for i in "${!INCLUDE_LIST[@]}"; do
    INCLUDE_LIST[$i]=$(echo "${INCLUDE_LIST[$i]}" | xargs)
done
for i in "${!EXCLUDE_LIST[@]}"; do
    EXCLUDE_LIST[$i]=$(echo "${EXCLUDE_LIST[$i]}" | xargs)
done

should_include() {
    local file="$1"
    local slug
    slug=$(basename "$file" .feature.md)
    local domain
    domain=$(basename "$(dirname "$file")")

    # Check exclude list first
    if [ -n "$EXCLUDE_FILTER" ]; then
        for ex in "${EXCLUDE_LIST[@]}"; do
            [ -z "$ex" ] && continue
            if [[ "$slug" == *"$ex"* ]] || [[ "$domain" == *"$ex"* ]]; then
                verbose "Excluded: $domain/$slug (matched '$ex')"
                return 1
            fi
        done
    fi

    # If no include filter, include everything not excluded
    if [ -z "$FEATURES_FILTER" ]; then
        return 0
    fi

    # Check include list
    for inc in "${INCLUDE_LIST[@]}"; do
        [ -z "$inc" ] && continue
        if [[ "$slug" == *"$inc"* ]] || [[ "$domain" == *"$inc"* ]]; then
            return 0
        fi
    done

    verbose "Skipped: $domain/$slug (not in include list)"
    return 1
}

# Strip a single spec file: reset frontmatter, remove implementation sections, clean inline paths
strip_spec() {
    local input="$1"
    local output="$2"
    local today
    today=$(date +%Y-%m-%d)

    awk -v today="$today" '
    BEGIN {
        in_frontmatter = 0
        frontmatter_done = 0
        dash_count = 0
        skip_section = 0
        skip_depth = 0
        in_learnings = 0
        printed_learnings_header = 0
    }

    # Track frontmatter boundaries
    /^---$/ && frontmatter_done == 0 {
        dash_count++
        if (dash_count == 1) {
            in_frontmatter = 1
            print "---"
            next
        }
        if (dash_count == 2) {
            in_frontmatter = 0
            frontmatter_done = 1
            print "---"
            next
        }
    }

    # Inside frontmatter: strip/reset fields
    in_frontmatter == 1 {
        # Skip indented array items that follow a reset array field
        if ($0 ~ /^  - / && skip_array_items) {
            next
        }
        # Any non-indented line ends array item skipping
        if ($0 !~ /^  -/) {
            skip_array_items = 0
        }

        # Reset source to empty
        if ($0 ~ /^source:/) {
            print "source:"
            next
        }
        # Reset tests to empty array (and skip following indented items)
        if ($0 ~ /^tests:/) {
            print "tests: []"
            skip_array_items = 1
            next
        }
        # Reset components to empty array
        if ($0 ~ /^components:/) {
            print "components: []"
            skip_array_items = 1
            next
        }
        # Reset design_refs to empty array
        if ($0 ~ /^design_refs:/) {
            print "design_refs: []"
            skip_array_items = 1
            next
        }
        # Reset status to specced
        if ($0 ~ /^status:/) {
            print "status: specced"
            next
        }
        # Update the updated date
        if ($0 ~ /^updated:/) {
            print "updated: " today
            next
        }

        print
        next
    }

    # Outside frontmatter: handle section removal
    frontmatter_done == 1 {

        # Detect section headers to remove entirely
        if ($0 ~ /^## Architecture Notes/ ||
            $0 ~ /^## Architecture$/ ||
            $0 ~ /^## Implementation Notes/ ||
            $0 ~ /^## Implementation$/ ||
            $0 ~ /^## Data Flow/ ||
            $0 ~ /^## Integration with/ ||
            $0 ~ /^## Technical Details/ ||
            $0 ~ /^## File Structure/) {
            skip_section = 1
            skip_depth = 2
            next
        }

        # Detect H3 subsections to remove
        if ($0 ~ /^### Architecture/ ||
            $0 ~ /^### Implementation/ ||
            $0 ~ /^### Data Flow/) {
            skip_section = 1
            skip_depth = 3
            next
        }

        # If skipping a section, stop at next section of same or higher level
        if (skip_section == 1) {
            if (skip_depth == 2 && $0 ~ /^## /) {
                skip_section = 0
            } else if (skip_depth == 3 && $0 ~ /^###? /) {
                skip_section = 0
            } else {
                next
            }
        }

        # Special handling for Learnings: keep header, clear content
        if ($0 ~ /^## Learnings/) {
            in_learnings = 1
            printed_learnings_header = 1
            print $0
            print ""
            print "<!-- Cleared during strip. Will be re-populated via /compound -->"
            next
        }
        if (in_learnings == 1) {
            if ($0 ~ /^## / && $0 !~ /^## Learnings/) {
                in_learnings = 0
            } else {
                next
            }
        }

        # Clear the **Source File**: line path
        if ($0 ~ /^\*\*Source File\*\*:/) {
            print "**Source File**: _(to be determined)_"
            next
        }

        # Strip Component References table rows that have file paths
        # Keep the section header but clean paths from rows
        if ($0 ~ /^\| .+ \| .+ \| `(src\/|app\/|components\/|lib\/|server\/)/) {
            # Replace specific file paths with placeholder
            gsub(/`(src|app|components|lib|server)[^`]*`/, "_(TBD)_")
        }

        # Strip inline file paths from Gherkin and body text
        # Matches: src/..., app/..., components/..., ./src/..., etc.
        gsub(/`?\.\/(src|app|components|lib|server|tests?|__tests__)[^`[:space:]]*`?/, "")
        gsub(/`?(src|app|components|lib|server|tests?|__tests__)\/[a-zA-Z0-9_.\/\-]+`?/, "")

        # Strip store/hook implementation references from body text (not from Gherkin Given/When/Then)
        if ($0 !~ /^(Given|When|Then|And|But) /) {
            gsub(/`use[A-Z][a-zA-Z]*Store`/, "")
            gsub(/`use[A-Z][a-zA-Z]*Hook`/, "")
        }

        # Clean up double spaces left by stripping (but not in code fences/indented lines)
        if ($0 !~ /^```/ && $0 !~ /^[│┌└├┼]/) {
            gsub(/  +/, " ")
        }

        print
    }
    ' "$input" > "$output"
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

echo ""
echo -e "${BOLD}SDD Strip Specs${NC}"
echo -e "Source: ${CYAN}$SOURCE_DIR${NC}"
echo -e "Target: ${CYAN}$TARGET_DIR${NC}"
[ -n "$FEATURES_FILTER" ] && echo -e "Include: ${CYAN}$FEATURES_FILTER${NC}"
[ -n "$EXCLUDE_FILTER" ] && echo -e "Exclude: ${CYAN}$EXCLUDE_FILTER${NC}"
[ "$INCLUDE_CONTEXT" = true ] && echo -e "Context: ${GREEN}yes${NC} (personas, tokens, vision, learnings)"
[ "$DRY_RUN" = true ] && echo -e "Mode: ${BLUE}dry-run${NC}"
echo ""

# Ensure target .specs structure exists
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$TARGET_DIR/.specs/features"
    mkdir -p "$TARGET_DIR/.specs/design-system/components"
    mkdir -p "$TARGET_DIR/.specs/personas"
    mkdir -p "$TARGET_DIR/.specs/learnings"
    mkdir -p "$TARGET_DIR/.specs/test-suites"
fi

# ------------------------------------------------------------------
# 1. Strip and copy feature specs
# ------------------------------------------------------------------

copied=0
skipped=0
total_source=0

while IFS= read -r -d '' spec; do
    total_source=$((total_source + 1))

    if ! should_include "$spec"; then
        skipped=$((skipped + 1))
        continue
    fi

    # Preserve domain/feature directory structure
    rel_path="${spec#"$SOURCE_FEATURES/"}"
    target_file="$TARGET_FEATURES/$rel_path"
    target_subdir=$(dirname "$target_file")

    if [ "$DRY_RUN" = true ]; then
        dry "Would strip and copy: $rel_path"
        copied=$((copied + 1))
        continue
    fi

    mkdir -p "$target_subdir"
    strip_spec "$spec" "$target_file"
    verbose "Stripped: $rel_path"
    copied=$((copied + 1))

done < <(find "$SOURCE_FEATURES" -name "*.feature.md" -print0 2>/dev/null | sort -z)

log "Feature specs: ${GREEN}$copied${NC} copied, ${YELLOW}$skipped${NC} skipped (of $total_source total)"

# ------------------------------------------------------------------
# 2. Copy context files (optional)
# ------------------------------------------------------------------

if [ "$INCLUDE_CONTEXT" = true ]; then
    echo ""
    log "Copying context files..."

    # Personas (copy unchanged)
    if [ -d "$SOURCE_DIR/.specs/personas" ]; then
        persona_count=0
        for f in "$SOURCE_DIR/.specs/personas"/*.md; do
            [ -f "$f" ] || continue
            fname=$(basename "$f")
            if [ "$DRY_RUN" = true ]; then
                dry "Would copy persona: $fname"
            else
                cp "$f" "$TARGET_DIR/.specs/personas/$fname"
                verbose "Copied persona: $fname"
            fi
            persona_count=$((persona_count + 1))
        done
        log "Personas: ${GREEN}$persona_count${NC} files"
    else
        warn "No personas found in source"
    fi

    # Design tokens (copy unchanged)
    if [ -f "$SOURCE_DIR/.specs/design-system/tokens.md" ]; then
        if [ "$DRY_RUN" = true ]; then
            dry "Would copy design tokens"
        else
            cp "$SOURCE_DIR/.specs/design-system/tokens.md" "$TARGET_DIR/.specs/design-system/tokens.md"
        fi
        log "Design tokens: ${GREEN}copied${NC}"
    else
        warn "No design tokens found in source"
    fi

    # Vision (copy but flag for editing)
    if [ -f "$SOURCE_DIR/.specs/vision.md" ]; then
        if [ "$DRY_RUN" = true ]; then
            dry "Would copy vision.md (flagged for review)"
        else
            {
                echo "<!-- REVIEW: This vision was copied from a previous project. -->"
                echo "<!-- Update to reflect the new project scope before building. -->"
                echo ""
                cat "$SOURCE_DIR/.specs/vision.md"
            } > "$TARGET_DIR/.specs/vision.md"
        fi
        log "Vision: ${GREEN}copied${NC} ${YELLOW}(flagged for review)${NC}"
    else
        warn "No vision.md found in source"
    fi

    # Learnings - copy pattern-level files, clear implementation-specific entries
    if [ -d "$SOURCE_DIR/.specs/learnings" ]; then
        learnings_count=0
        for f in "$SOURCE_DIR/.specs/learnings"/*.md; do
            [ -f "$f" ] || continue
            fname=$(basename "$f")
            if [ "$DRY_RUN" = true ]; then
                dry "Would copy learning: $fname"
            else
                cp "$f" "$TARGET_DIR/.specs/learnings/$fname"
            fi
            learnings_count=$((learnings_count + 1))
        done
        log "Learnings: ${GREEN}$learnings_count${NC} files"
    fi
fi

# ------------------------------------------------------------------
# 3. Regenerate mapping in target (if not dry-run)
# ------------------------------------------------------------------

if [ "$DRY_RUN" = false ] && [ -f "$TARGET_DIR/scripts/generate-mapping.sh" ]; then
    log "Regenerating mapping.md in target..."
    (cd "$TARGET_DIR" && bash ./scripts/generate-mapping.sh)
elif [ "$DRY_RUN" = false ]; then
    verbose "No generate-mapping.sh in target, skipping mapping regeneration"
fi

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------

echo ""
echo -e "${BOLD}Summary${NC}"
echo "─────────────────────────────────"
echo -e "  Specs copied:    ${GREEN}$copied${NC}"
echo -e "  Specs skipped:   ${YELLOW}$skipped${NC}"
echo -e "  Total in source: $total_source"
if [ "$INCLUDE_CONTEXT" = true ]; then
    echo -e "  Context files:   ${GREEN}copied${NC}"
fi
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}Dry run complete. No files were written.${NC}"
    echo "Run without --dry-run to execute."
else
    echo -e "${GREEN}Done!${NC} Stripped specs are in: $TARGET_DIR/.specs/features/"
    echo ""
    echo "Next steps:"
    echo "  1. Review/update vision.md for the new project scope"
    echo "  2. Create or update roadmap.md with the features you want to build"
    echo "  3. Run /build-next or ./scripts/build-loop-local.sh to start building"
fi
echo ""
