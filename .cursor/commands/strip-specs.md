# Strip Specs

Strip implementation details from feature specs to create behavioral seeds for rebuilding a project.

## Usage

```
/strip-specs --source /path/to/old-project --target /path/to/new-project
/strip-specs --source /old --target /new --features "dashboard-shell,ai-agent,widget-framework"
/strip-specs --source /old --target /new --include-context --dry-run
```

## What This Command Does

Takes feature specs from a completed/existing project and strips implementation details while preserving behavioral definitions. The output is a set of "seed" specs that `/spec-first` can pick up in **update mode** — the agent reads the existing Gherkin, improves it, then writes tests and implements with a fresh architecture.

```
Source Project                    Target Project
.specs/features/                  .specs/features/
├── auth/login.feature.md    →   ├── auth/login.feature.md (stripped)
├── dashboard/shell.feature.md → ├── dashboard/shell.feature.md (stripped)
└── ai/agent.feature.md      →   └── ai/agent.feature.md (stripped)

Kept: Gherkin scenarios, ASCII mockups, user journeys, persona refs
Stripped: file paths, test refs, component lists, architecture notes, learnings
```

---

## Options

| Flag | Purpose | Default |
|------|---------|---------|
| `--source PATH` | Source project root (required) | — |
| `--target PATH` | Target project root (required) | — |
| `--features LIST` | Comma-separated feature slugs to include | All |
| `--exclude LIST` | Comma-separated feature slugs to exclude | None |
| `--include-context` | Also copy personas, design tokens, vision, learnings | Off |
| `--dry-run` | Preview without writing files | Off |
| `--verbose` | Show detailed processing info | Off |

---

## Behavior

### Step 1: Validate Inputs

1. Check `--source` has a `.specs/features/` directory
2. Check `--target` exists (or create `.specs/` structure)
3. If `--features` provided, validate at least one spec matches

### Step 2: Run the Strip Script

Execute `./scripts/strip-specs.sh` with the provided arguments:

```bash
./scripts/strip-specs.sh \
  --source "$SOURCE" \
  --target "$TARGET" \
  [--features "$FEATURES"] \
  [--exclude "$EXCLUDE"] \
  [--include-context] \
  [--dry-run] \
  [--verbose]
```

### Step 3: Report Results

After the script runs, report:

```
✅ Strip complete!

Specs stripped: 34 (of 158 total)
Specs skipped: 124

Context files:
  - Personas: 4 files copied
  - Design tokens: copied
  - Vision: copied (flagged for review)
  - Learnings: 7 files copied

Target: /path/to/new-project/.specs/features/

Next steps:
1. Review/update .specs/vision.md for the new project scope
2. Create or update .specs/roadmap.md with features you want to build
3. Run /build-next or ./scripts/build-loop-local.sh to start building
```

---

## What Gets Stripped Per Spec

### Frontmatter

| Field | Before | After |
|-------|--------|-------|
| `source:` | `src/components/Sidebar.tsx` | _(cleared)_ |
| `tests:` | `[src/__tests__/sidebar.test.tsx]` | `[]` |
| `components:` | `[Sidebar, NavItem]` | `[]` |
| `design_refs:` | `[tokens.md, sidebar.md]` | `[]` |
| `status:` | `implemented` | `specced` |
| `updated:` | `2026-01-15` | _(today)_ |

### Sections

| Section | Action | Reason |
|---------|--------|--------|
| `## Feature:` + Gherkin | **Keep** | Core behavioral value |
| `## UI Mockup` | **Keep** | Design intent |
| `## User Journey` | **Keep** | Flow context |
| `## Design Tokens Used` | **Keep** | Implementation-independent |
| `## Open Questions` | **Keep** | Still relevant |
| `## Architecture Notes` | **Remove** | Old project structure |
| `## Architecture` | **Remove** | Old project structure |
| `## Implementation Notes` | **Remove** | Old project details |
| `## Data Flow` | **Remove** | Old integration details |
| `## Integration with...` | **Remove** | Old coupling |
| `## Technical Details` | **Remove** | Old decisions |
| `## File Structure` | **Remove** | Old layout |
| `## Component References` | **Strip paths** | Keep names, clear file refs |
| `## Learnings` | **Clear content** | Keep header, will be re-populated |
| `**Source File**:` | **Clear path** | No file exists yet |

### Inline

- File paths (`src/...`, `app/...`, `components/...`) removed from body text
- Store/hook references (`useXxxStore`) removed from non-Gherkin text
- Gherkin Given/When/Then lines are preserved (behavioral language stays)

---

## Context Files (--include-context)

When `--include-context` is passed, also copies:

| File | Action |
|------|--------|
| `.specs/personas/*.md` | Copy unchanged (no code references) |
| `.specs/design-system/tokens.md` | Copy unchanged (implementation-independent) |
| `.specs/vision.md` | Copy with review flag (may need scope editing) |
| `.specs/learnings/*.md` | Copy as-is (pattern-level learnings) |

---

## Integration with /spec-first

Stripped specs have `status: specced` and empty `source:`. When `/spec-first` runs for a feature that matches a stripped spec:

1. **Update mode activates** — agent sees existing Gherkin scenarios
2. Agent reads the behavioral seed (scenarios, mockups, journeys)
3. Agent potentially improves/updates the scenarios
4. Agent makes its own architecture decisions (new `source:` path)
5. Agent writes tests and implements from the behavioral definition

This is much faster than creating specs from scratch because the agent doesn't have to figure out edge cases, error states, and user flows from a 1-sentence roadmap entry.

---

## Integration with build-loop-local.sh

You can seed a new project before starting the build loop:

```bash
# 1. Seed the new project with stripped specs
./scripts/strip-specs.sh \
  --source /path/to/old-project \
  --target /path/to/new-project \
  --features "dashboard-shell,widget-framework,ai-agent" \
  --include-context

# 2. Edit vision and roadmap for new scope
cd /path/to/new-project
# (edit .specs/vision.md and .specs/roadmap.md)

# 3. Build from the seeded specs
./scripts/build-loop-local.sh
```

---

## Example: Rebuilding Without CRM Features

```bash
# Strip everything except deal management specs
./scripts/strip-specs.sh \
  --source ~/projects/old-app \
  --target ~/projects/new-app \
  --exclude "deal-pipeline,deal-intelligence,news-alerts,template-outreach,league-tables,broker-rankings,contact-manager,email-integration" \
  --include-context \
  --dry-run

# Review the dry run output, then run for real
./scripts/strip-specs.sh \
  --source ~/projects/old-app \
  --target ~/projects/new-app \
  --exclude "deal-pipeline,deal-intelligence,news-alerts,template-outreach,league-tables,broker-rankings,contact-manager,email-integration" \
  --include-context
```

---

## Prioritizing Which Specs to Copy

Not all specs are equally valuable. Prioritize by how hard they are to re-derive:

**Must copy (hard to re-derive):**
- Foundation specs (project setup, shell, framework)
- Complex query/filter specs (temporal joins, cross-dataset, filter chains)
- AI agent specs (tool layer, safety validation)
- Deep UX specs (deck system, widget linking, map interactions)

**Can regenerate from roadmap (simpler, follow patterns):**
- Individual data display widgets
- Map layers that follow a template
- Simple CRUD features
- Export/sharing features

Use `--features` to copy only the high-value specs:

```bash
./scripts/strip-specs.sh \
  --source ~/old \
  --target ~/new \
  --features "project-setup,dashboard-shell,widget-framework,deck,filter,ai-agent,cross-query,sidebar,map-interactions"
```
