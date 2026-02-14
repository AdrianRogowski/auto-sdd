---
description: Create, update, or restructure the project's build roadmap (.specs/roadmap.md)
---

Manage the roadmap for: $ARGUMENTS

## Mode Detection

| Condition | Mode |
|-----------|------|
| No roadmap.md or only template | **Create** — build from vision + user input |
| `create` subcommand | **Create** — force fresh roadmap |
| `add "feature"` subcommand | **Add** — add features to existing roadmap |
| `reprioritize` subcommand | **Reprioritize** — restructure existing roadmap |
| `status` subcommand | **Status** — report progress only (read-only) |
| `--from-jira PROJECT_KEY` | **Import** — seed from Jira epics/stories |
| `--from-confluence PAGE_ID` | **Import** — seed from Confluence page |
| No subcommand, roadmap exists | **Interactive** — ask what user wants to do |

## Instructions

### Create Mode

1. Read `.specs/vision.md` for app overview, screens, tech stack, principles
2. Scan codebase for existing features (routes, API, schema, components) — mark as ✅
3. Decompose into right-sized features:
   - **S**: 1-3 files, single component
   - **M**: 3-7 files, multiple components
   - **L**: 7-15 files, full feature
   - If bigger than L, break down further
4. Identify dependencies between features
5. Group into phases (4-8 features each, descriptive names, clear goals)
6. Write roadmap.md with Implementation Rules, Progress, Phases, Status/Complexity Legends, Notes
7. Show draft, wait for approval

### Add Mode

1. Read existing roadmap to understand phases, numbering, dependencies
2. Classify new feature(s): complexity, dependencies, placement (existing phase / new phase / ad-hoc)
3. Break down large features into multiple items
4. Show diff and confirm before applying

### Reprioritize Mode

1. Read roadmap, vision, learnings, mapping
2. Present analysis: what's done, what's next, observations (parallelizable phases, dependency bottlenecks, complexity concerns)
3. Ask about priority changes, new features, cancellations, reordering
4. Restructure based on feedback
5. Show diff and confirm

### Status Mode (read-only)

Show progress table by phase, overall percentage, next feature, blocked items, and time estimate. No file changes.

### Import Mode (Jira)

1. Fetch epics → map to Phases
2. Fetch stories under each epic → map to Features
3. Story points/priority → Complexity estimates
4. Jira keys → Source column
5. Show draft, wait for approval

### Import Mode (Confluence)

1. Fetch page and child pages
2. Parse for feature lists, tables, headings
3. Transform into roadmap format
4. Show draft, wait for approval

## Roadmap Structure

Always include:
- Implementation Rules section (no mock data, real APIs, real error handling)
- Progress summary table
- Phases with feature tables (# | Feature | Source | Complexity | Deps | Status)
- Status Legend and Complexity Legend
- Notes section with implementation insights

Feature numbering: Phase 1 = #1-9, Phase 2 = #10-19, etc. Ad-hoc = #100+.

## After Saving

Report feature counts by phase and suggest next steps (`/build-next`, `/roadmap add`, `/roadmap-triage`).
