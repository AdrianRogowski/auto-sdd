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

## Roadmap row contract (all modes)

Every roadmap row is a Ralph/`build-next` unit. It must satisfy:

1. **Prefix-demoable** — after the row is ✅, someone can stop and use a coherent product. Incomplete is fine; "schema only" / "service layer" / setup-only is not.
2. **Vertical, not horizontal** — a screen, flow, or endpoint someone can click or curl. Never add layer rows ("set up database schema", "build service layer", "API endpoints", "project setup", "design tokens"). Fold layers into the user-facing feature they serve. Sub-steps live in the feature spec's `### Implementation Slices`.
3. **Prefer L verticals** — default to Large (~7–15 files, full vertical). Use M when the vertical is naturally smaller. Reserve S for polish/bugs, not bootstrap. File count is a soft ceiling; do not split just because a row feels "big" unless each piece is demoable alone.
4. **Greenfield density** — aim for ~10–15 features for a typical app. Fuse scaffold + store into the first demoable feature. Prefer one "MCP surface" row over one row per tool.
5. **Core loop before auth** — sequence by time-to-aha. Defer signup/login/OAuth until after the core loop is demoable, unless auth *is* the product or strategy demands enterprise onboarding first. Still include an **ownership stub** (`user_id` / scoped queries, hardcoded local user is fine) in the first domain feature so auth can land later without a rewrite.
6. **Phases are chapter titles** — Ralph executes rows, not phases. A phase may group several `--full` units; each unit is its own row.

## Instructions

### Create Mode

1. Read `.specs/strategy.md` for business strategy — target customer, buying motion, success metrics, anti-goals. **Strategy drives prioritization**: features that support the buying motion and move success metrics come first. Anti-goals prevent scope creep into features the strategy says to defer. PLG / exploration → time-to-aha before auth. Enterprise top-down → onboarding/auth may come earlier.
2. Read `.specs/vision.md` for app overview, screens, tech stack, principles. Identify the **core loop / aha** explicitly.
3. Scan codebase for existing features (routes, API, schema, components) — mark as ✅
4. Decompose into right-sized features using the **Roadmap row contract** above:
   - **L** (default): full user-demoable vertical
   - **M**: smaller but still demoable vertical
   - **S**: polish / small additive only
   - If a candidate is a layer, merge it into the user-facing feature it serves
   - Target ~10–15 rows for a greenfield / clone-sized app
5. Identify dependencies — prefer shallow graphs; do not put auth on the critical path of the core loop
6. Group into phases (3–6 features each when using fatter L rows; descriptive names, clear goals). Phase 1 should be "Core loop / time-to-aha" (or strategy-equivalent), not "Foundation: setup + auth"
7. Write roadmap.md with Implementation Rules, Progress, Phases, Status/Complexity Legends, Notes
8. Self-check: no layer rows; row #1 demoable without auth (unless exception); ownership stub called out for first domain feature; density ~10–15 unless the product is genuinely larger
9. Show draft, wait for approval

### Add Mode

1. Read existing roadmap to understand phases, numbering, dependencies
2. Classify new feature(s): complexity, dependencies, placement (existing phase / new phase / ad-hoc)
3. Break down large features into multiple items — each item must stay vertical (user-demoable), never a layer
4. If the requested feature is layer-shaped ("add the API for X"), fold it into the user-facing feature it serves instead of adding a row
5. If the request is auth and the core loop is not yet ✅, warn and default to placing auth *after* the core loop (unless user overrides or strategy exception applies)
6. Show diff and confirm before applying

### Reprioritize Mode

1. Read roadmap, strategy, vision, learnings, mapping. If strategy exists, check alignment: "Are the top features actually the ones that move the strategy's success metrics?"
2. Present analysis: what's done, what's next, observations (parallelizable phases, dependency bottlenecks, complexity concerns, auth-too-early, atomized rows that should merge)
3. Ask about priority changes, new features, cancellations, reordering, merging tiny rows into L verticals
4. Restructure based on feedback — keep the row contract
5. Show diff and confirm

### Status Mode (read-only)

Show progress table by phase, overall percentage, next feature, blocked items, and time estimate. No file changes.

### Import Mode (Jira)

1. Fetch epics → map to Phases
2. Fetch stories under each epic → map to Features. Jira stories are often layer-shaped ("build the API", "create the schema") — merge those into the user-facing feature they serve so every roadmap row stays vertical
3. Auth/onboarding stories: place after core-loop features unless strategy says enterprise-first
4. Story points/priority → Complexity estimates (bias toward L when merging atomized tickets)
5. Jira keys → Source column
6. Show draft, wait for approval

### Import Mode (Confluence)

1. Fetch page and child pages
2. Parse for feature lists, tables, headings
3. Transform into roadmap format (apply row contract: merge layers, defer auth, prefer L)
4. Show draft, wait for approval

## Roadmap Structure

Always include:
- Implementation Rules section (no mock data, real APIs, real error handling)
- Progress summary table
- Phases with feature tables (# | Feature | Source | Complexity | Deps | Status)
- Status Legend and Complexity Legend
- Notes section with implementation insights (call out ownership stub + auth deferral when relevant)

Feature numbering: Phase 1 = #1-9, Phase 2 = #10-19, etc. Ad-hoc = #100+.

## After Saving

Report feature counts by phase and suggest next steps (`/build-next`, `/roadmap add`, `/roadmap-triage`).
Remind the user: each ✅ should be a place you could stop and still demo something real.
