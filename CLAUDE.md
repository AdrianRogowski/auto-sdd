# Spec-Driven Development (SDD)

This project uses a spec-driven development workflow. Follow these rules in all interactions.

## Core Principle

**Spec before code.** Define behavior before implementing it.

```
Project setup (once):
  /vision → /personas → /design-tokens

Per feature (Red-Green-Refactor TDD):
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │    SPEC      │ ──▶ │  RED (test)  │ ──▶ │ GREEN (impl) │ ──▶ │  REFACTOR    │
  │ (Gherkin +   │     │  (failing)   │     │ (until tests │     │ (clean up,   │
  │  mockup +    │     │              │     │  pass)       │     │  tests must  │
  │  persona     │     │              │     │              │     │  still pass) │
  │  revision)   │     │              │     │              │     │              │
  └──────┬───────┘     └──────────────┘     └──────┬───────┘     └──────┬───────┘
         │                                         │                     │
      [PAUSE]                                      ▼                     ▼
    user approves                           ┌──────────────┐     ┌──────────────┐
    then /tdd                               │ DRIFT CHECK  │     │ DRIFT CHECK  │
                                            │ (layer 1)    │     │ (layer 1b)   │
                                            └──────────────┘     └──────┬───────┘
                                                                        │
                                                                        ▼
                                                                 ┌──────────────┐
                                                                 │  COMPOUND    │
                                                                 │ (learnings)  │
                                                                 └──────────────┘
```

---

## Command Triggers

When the user says any of these phrases, **automatically invoke `/spec-first`**:

| User says | Action |
|-----------|--------|
| "spec first" | Run `/spec-first {feature}` |
| "spec-first" | Run `/spec-first {feature}` |
| "write a spec for" | Run `/spec-first {feature}` |
| "create a spec" | Run `/spec-first {feature}` |
| "spec this out" | Run `/spec-first {feature}` |
| "spec out" | Run `/spec-first {feature}` |
| "plan this feature" | Run `/spec-first {feature}` |
| "write the spec" | Run `/spec-first {feature}` |
| "create spec" | Run `/spec-first {feature}` |
| "update the spec for" | Run `/spec-first {feature}` (update mode) |
| "update spec" | Run `/spec-first {feature}` (update mode) |

When the user says any of these after a spec is shown, **invoke `/tdd`**:

| User says | Action |
|-----------|--------|
| "tdd" | Run `/tdd {feature}` |
| "go ahead" | Run `/tdd` with current spec |
| "build it" | Run `/tdd` with current spec |
| "implement it" | Run `/tdd` with current spec |
| "ship it" | Run `/tdd` with current spec |

Extract the feature description from the rest of their message.

When the user says any of these, **invoke the corresponding ralph/utility command**:

| User says | Action |
|-----------|--------|
| "ralph setup", "set up ralph", "configure ralph" | Run `/ralph-setup` |
| "ralph run", "run ralph", "start the loop", "run the loop" | Run `/ralph-run` |
| "clean slate", "kill everything", "restart everything", "nuke localhost" | Run `/clean-slate` |
| "generate guide", "update guide", "how to use guide" | Run `/guide` |

### Full Mode Triggers

If user includes "full", "auto", "no stops", or "don't pause":
- Add `--full` flag to the command
- Example: "spec first user auth, full mode" → `/spec-first user auth --full`

---

## Directory Structure

```
.specs/
├── vision.md              # App vision (created by /vision or /clone-app)
├── roadmap.md             # Feature roadmap (single source of truth)
├── personas/              # User personas (inform every spec)
│   ├── primary.md         # Main user persona
│   ├── secondary.md       # Second user type (if needed)
│   ├── anti-persona.md    # Who you're NOT building for
│   └── _template.md       # Template for new personas
├── features/              # Gherkin specs with ASCII mockups
│   └── {domain}/
│       └── {feature}.feature.md
├── test-suites/           # Test documentation
│   └── {mirrors test dir structure}
├── design-system/         # Design tokens and patterns
│   ├── tokens.md          # Colors, spacing, typography (personality-driven)
│   └── components/        # Component pattern docs
│       └── {component}.md
├── learnings/             # Cross-cutting patterns by category
│   ├── index.md           # Summary
│   ├── testing.md
│   ├── performance.md
│   ├── security.md
│   ├── api.md
│   ├── design.md
│   └── general.md
├── mapping.md             # AUTO-GENERATED from spec frontmatter
├── codebase-summary.md    # Generated by /spec-init
└── needs-review.md        # Files that need manual attention
```

---

## Project Setup (Once)

These are created once and inform every feature:

| Command | Creates | Purpose |
|---------|---------|---------|
| `/vision` | `.specs/vision.md` | App purpose, users, tech stack, design principles |
| `/personas` | `.specs/personas/*.md` | Who uses this (vocabulary, patience, frustrations) |
| `/design-tokens` | `.specs/design-system/tokens.md` | Personality-driven tokens derived from vision + personas |

All three are optional but improve every spec. `/spec-first` will note what's missing.

---

## Personas

User personas live in `.specs/personas/` and are loaded before every spec.

**What they contain:**
- **Context** — how the user spends their day, devices, technical level
- **Vocabulary** — their words vs developer words → drives all UI labels
- **Patience level** — Very Low / Low / Medium / High → drives flow length
- **Frustrations** — patterns to avoid
- **Success metric** — how they measure if the app works

**How they're used:**

**Before writing**: Loads persona vocabulary, patience level, and frustrations. This shapes the Gherkin scenarios, mockup labels, and flow complexity from the start.

**After writing**: Re-reads the spec through each persona's eyes. Revises vocabulary, simplifies flows, cuts anti-persona features. Reports what changed at the pause point.

### Creating Personas

Run `/personas` or they're auto-suggested on first `/spec-first` run. Most projects need 2:
- **Primary**: The main user. Every feature must work for them.
- **Anti-persona**: Who you're NOT building for. Prevents scope creep.

---

## Design System

Design tokens are in `.specs/design-system/tokens.md`, created by `/design-tokens`.

### How It Works

`/design-tokens` doesn't stamp a generic template. It:
1. Reads vision + personas for context
2. Determines a **personality** (Professional / Friendly / Minimal / Bold / Technical)
3. Derives a tailored palette from personality + brand color
4. Constrains to v1 minimums (fewer tokens = more consistency)
5. Writes rationale explaining the choices

### Token Reference

When implementing UI, use token names from `tokens.md` (not hardcoded values). The specific tokens depend on the project — read `tokens.md` for the actual names and values.

**Common categories:** Colors (primary, neutrals, semantic), Typography (1 font family, 4-5 sizes, 3 weights), Spacing (6 values), Radii (3 + full), Shadows (2).

### When `/spec-first` Runs on Greenfield

If no design system exists:
1. Auto-create via `/design-tokens` flow (reads whatever context exists)
2. Create `.cursor/rules/design-tokens.mdc` cursor rule
3. Proceed with feature spec

### When a Spec References New Components

If ASCII mockup references a component that doesn't exist in `.specs/design-system/components/`:
1. Auto-create a **stub** file: `.specs/design-system/components/{component}.md`
2. Stub includes: name, purpose, "pending implementation" status
3. After implementation, stub gets filled in (manually or via `/document-component`)

### Design System Maintenance

`.specs/design-system/tokens.md` is the source of truth. When tokens change:
1. Update `tokens.md`
2. Update `.cursor/rules/design-tokens.mdc` if token names changed
3. Update affected component documentation

---

## When Implementing Features

### /spec-first: Create vs Update

`/spec-first` automatically detects whether to create or update:

1. **Resolve spec**: Search `.specs/features/**/*.feature.md` for a spec matching the feature name (by path or frontmatter `feature:`)
2. **If match found** → UPDATE mode: revise scenarios and mockup, preserve status/tests/components. With `--full`, continues through tests → implement → compound → commit
3. **If no match** → CREATE mode: load personas + tokens, create new spec with Gherkin + ASCII mockup + user journey, revise through persona lens

### What happens in the SPEC step:

1. **Load context** — Read personas and design tokens
2. **Write Gherkin** — Scenarios using persona vocabulary, matching patience level
3. **Write mockup** — ASCII art referencing design tokens
4. **Add user journey** — Where this feature fits in the user's flow
5. **Persona revision** — Re-read through persona's eyes, revise, note changes
6. **Create component stubs** — For any new UI components
7. **Pause** — Show spec + revision notes, ask "Run `/tdd` when ready"

### What happens in the /tdd step (Red-Green-Refactor):

1. **RED** — Write failing tests from Gherkin scenarios
2. **GREEN** — Implement until all tests pass
3. **Drift Check L1** — Self-check spec vs code alignment
4. **REFACTOR** — Clean up code, tests must still pass
5. **Drift Check L1b** — Re-verify after refactoring
6. **COMPOUND** — Extract learnings

### For New Features
1. Run `/spec-first {feature}` — it will CREATE a spec if none exists
2. Loads personas and design tokens before writing
3. Writes Gherkin using persona vocabulary
4. Creates ASCII mockup referencing design tokens
5. Adds user journey (where this feature fits in the flow)
6. Runs persona revision pass, notes changes
7. **STOP for approval** — "Run `/tdd` when ready" (unless `--full`)
8. Run `/tdd` — full Red-Green-Refactor cycle:
   - RED: Write failing tests
   - GREEN: Implement until tests pass
   - Drift check (Layer 1)
   - REFACTOR: Clean up code, tests must still pass
   - Drift check (Layer 1b)
   - Compound: Extract learnings
9. Fill in component documentation

### For Existing Features
1. Run `/spec-first {feature}` — it will UPDATE the spec if one exists
2. Or read the spec first and update manually if behavior changes
3. Update tests to match
4. Update `.specs/mapping.md` (or run `./scripts/generate-mapping.sh`)

### For Bug Fixes
1. Check if spec defines expected behavior
2. If gap found, add scenario to spec
3. Write failing test that reproduces bug
4. Fix the bug
5. Document the new test

### Documenting an Existing Codebase

For documenting a codebase that was built without specs, use the doc-loop workflow:

```
/spec-init                              # Discovery only: creates doc-queue.md
  ↓ (review the queue)
./scripts/doc-loop-local.sh --continue  # Processes queue with fresh agent per item
```

Or headless (discovery + processing in one go):
```
./scripts/doc-loop-local.sh             # Does its own discovery, then loops
```

**Philosophy: Document, don't fix.**
- Tests are written to pass against current code (documenting reality)
- If tests fail after one retry, log the finding and move on
- Pre-existing test failures are recorded as baseline, not fixed
- Source code is never modified during documentation

**How it works:**
1. **Discovery**: Scans codebase, groups files by domain, creates `.specs/doc-queue.md`
2. **Doc loop**: For each queue item, spawns a fresh agent that runs `/document-code` in batch mode
3. **Verification**: Runs test suite, reports final coverage

Each queue item gets a fresh agent context, so quality stays consistent even for large codebases. Progress is committed periodically and the queue tracks status, so you can resume with `--continue` if interrupted.

**Key files:**
- `.specs/doc-queue.md` — Ordered list of items to document (automation parses this)
- `.specs/codebase-summary.md` — Project overview + baseline status
- `.specs/needs-review.md` — Items that couldn't be fully documented

---

## Pause Triggers

If the user says any of these (or similar), create the spec and **STOP** - wait for approval:
- "let me review first"
- "write the spec first"
- "show me the Gherkin"
- "spec this out"
- "don't implement yet"
- "plan this first"
- "what would this look like?"
- "before you implement..."
- "hold on"
- "wait"
- "let me see"

After showing spec: "Does this look right? Run `/tdd` when ready, or say 'go ahead' to start the Red-Green-Refactor cycle."

---

## Feature Spec Format

Every feature spec should include:

```markdown
---
feature: Feature Name
domain: domain-name
source: path/to/source.tsx
tests: []
components: []
design_refs: []
personas: [primary, anti-persona]
status: stub    # stub → specced → tested → implemented
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Feature Name

**Source File**: `path/to/file.tsx`
**Design System**: `.specs/design-system/tokens.md`
**Personas**: `.specs/personas/primary.md`

## Feature: [Name]

[Brief description — who it's for and what problem it solves]

### Scenario: [Happy path]
Given [precondition]
When [action]
Then [expected result]

### Scenario: [Edge case]
Given [precondition]
When [action]
Then [expected result]

## User Journey

1. [Where user comes from]
2. **[This feature]**
3. [Where user goes next]

## UI Mockup

(ASCII art referencing design tokens, using persona vocabulary)

## Component References

- Button: `.specs/design-system/components/button.md`
- Card: `.specs/design-system/components/card.md` (stub)

## Learnings

<!-- Updated via /compound -->
```

### Frontmatter Fields

| Field | Description | When to Update |
|-------|-------------|----------------|
| `status` | stub → specced → tested → implemented | Each workflow stage |
| `tests` | Array of test file paths | After writing tests |
| `components` | Array of component names | After implementation |
| `design_refs` | Array of design system references | Spec creation |
| `personas` | Array of persona names referenced | Spec creation |
| `updated` | Last modified date | Any change |

---

## Component Stub Lifecycle

```
1. /spec-first "user profile"
   └─▶ Mockup references "Card" component
   └─▶ Card doesn't exist → CREATE STUB

2. Stub created: .specs/design-system/components/card.md
   Status: 📝 Stub (pending implementation)

3. Implementation happens...

4. /design-component card
   └─▶ Reads actual component code
   └─▶ Fills in props, variants, usage examples
   └─▶ Status: ✅ Documented
```

---

## Available Commands

### Setup
| Command | Purpose |
|---------|---------|
| `/spec-init` | Discover codebase structure, create doc-queue.md (discovery only) |
| `/vision` | Create or update vision.md |
| `/personas` | Create or update user personas |
| `/design-tokens` | Create or update design tokens (personality-driven) |
| `/spec-first` | Create or update spec + mockup (auto-detects create vs update) |
| `/spec-first --full` | Create/update spec AND build without pauses (full Red-Green-Refactor cycle) |
| `/tdd` | Run the Red-Green-Refactor cycle from an approved spec |

### Core Workflow
| Command | Purpose |
|---------|---------|
| `/document-code` | Generate specs from existing code (single or batch mode) |
| `/prototype` | Rapid prototyping without specs |
| `/formalize` | Convert prototype to production with specs |
| `/compound` | Extract and persist learnings from session |
| `/strip-specs` | Strip implementation details from specs for rebuilding in a new project |

### Roadmap Commands
| Command | Purpose |
|---------|---------|
| `/roadmap` | Create, update, or restructure roadmap.md |
| `/clone-app <url>` | Analyze app → create vision.md + roadmap.md |
| `/build-next` | Build next pending feature from roadmap |
| `/roadmap-triage` | Scan Slack/Jira → add to roadmap |

### Design System
| Command | Purpose |
|---------|---------|
| `/design-tokens` | Create or update design tokens (personality-driven) |
| `/design-component` | Document a component pattern |

### Bug Fixing and Refactoring
| Command | Purpose |
|---------|---------|
| `/fix-bug` | Fix bugs with regression tests |
| `/refactor` | Refactor while keeping tests green |

### Documentation and Maintenance
| Command | Purpose |
|---------|---------|
| `/check-coverage` | Find gaps in spec/test coverage |
| `/update-test-docs` | Sync test docs with actual tests |
| `/catch-drift` | Detect spec ↔ code drift |
| `/verify-test-counts` | Reconcile test counts |

### Ralph Commands (Build Loop Management)
| Command | Purpose |
|---------|---------|
| `/ralph-setup` | Interactive wizard: configure .env.local with auto-detection |
| `/ralph-run` | Show roadmap status, kill dev servers, launch build loop |
| `/clean-slate` | Kill all processes on dev ports, optionally restart |
| `/guide` | Generate/update GUIDE.md — living "how to use" guide for the built app |

### Git Workflow
| Command | Purpose |
|---------|---------|
| `/start-feature` | Create new feature branch |
| `/code-review` | Review against engineering standards |

---

## Parallel Builds

`BRANCH_STRATEGY=parallel` enables concurrent feature builds in separate git worktrees:

```
main ────────────────────────────────────────────────
  │           │           │
  ├── wt-a/  ├── wt-b/  ├── wt-c/     ← worktrees
  │   build  │   build  │   build      ← concurrent agents
  │   done✓  │   done✓  │   fail✗
  └───────────┴───────────┘
              │
        merge + test (sequential)
              │
        integration branch
```

Configuration in `.env.local`:
```bash
BRANCH_STRATEGY=parallel
PARALLEL_FEATURES=3          # max concurrent agents
MERGE_STRATEGY=dependency    # merge in dependency order (or: fifo)
```

Merge conflict resolution:
- Feature-specific files (specs, new source): merge cleanly
- Shared append-only files (learnings, roadmap): auto-resolved
- Auto-generated files (mapping.md): regenerated after merge
- Source code conflicts: branch preserved, feature marked blocked

---

## Subagent Patterns

When executing SDD commands, use subagents to parallelize independent work.

### When to Fan Out

| Command | What to parallelize |
|---------|-------------------|
| `/spec-first` | Load personas, design tokens, and search for existing spec simultaneously |
| `/tdd` | Post-GREEN: run build check, lint check, and test check simultaneously |
| `/build-next` | Context loading: read vision, personas, tokens, related specs, learnings in parallel |
| `/check-coverage` | Check spec coverage, test coverage, and mapping consistency independently |
| `/catch-drift` | Batch 3-5 specs per subagent instead of one at a time |
| `/guide` | Read all feature specs, codebase files, and learnings in parallel batches |
| `/ralph-run` | Pre-flight: validate CLI, check ports, read roadmap simultaneously |

### When NOT to Fan Out

- **Sequential dependencies**: Spec must complete before tests, tests before implementation
- **Git operations**: Only one agent should touch git at a time
- **Roadmap updates**: Single writer to avoid race conditions on roadmap.md
- **Small tasks**: If total work is < 10 seconds, the overhead isn't worth it

### Patterns

**Parallel Reads Then Sequential Write:**
1. Fan out: read personas, tokens, existing specs simultaneously
2. Collect results
3. Sequential: write the spec using all gathered context

**Parallel Validation:**
1. Agent completes implementation
2. Fan out: run tests, build, lint simultaneously
3. If all pass → continue. If any fail → fix sequentially (failures may be related)

**Batch Processing** (drift-scan, doc-loop, check-coverage):
1. Gather list of items
2. Chunk into batches of PARALLEL_FEATURES (default: 3)
3. Fan out: one subagent per chunk
4. Collect and merge results

`BRANCH_STRATEGY=parallel` handles script-level parallelism (multiple agent processes in worktrees). Within each agent process, use the patterns above for command-level parallelism.

---

## Test ID Conventions

| Prefix | Component/Module |
|--------|------------------|
| UT | utils |
| API | api handlers |
| SVC | services |
| CMP | components |
| PG | pages |
| HK | hooks |

---

## Always Mention

When working with specs, always tell the user:
- Which spec files you're reading/creating/updating
- Which persona files you're reading
- Which design system files you're referencing
- Any gaps between specs and tests
- Component stubs that need documentation

---

## File Locations

| Type | Location |
|------|----------|
| App vision | `.specs/vision.md` |
| Build roadmap | `.specs/roadmap.md` |
| User personas | `.specs/personas/*.md` |
| Feature specs | `.specs/features/{domain}/{feature}.feature.md` |
| Test suite docs | `.specs/test-suites/{mirrors test dir}` |
| Design tokens | `.specs/design-system/tokens.md` |
| Component docs | `.specs/design-system/components/{name}.md` |
| Mapping | `.specs/mapping.md` (auto-generated) |
| Documentation queue | `.specs/doc-queue.md` (created by `/spec-init` or `doc-loop-local.sh`) |
| Cross-cutting learnings | `.specs/learnings/` (by category) |

---

## Mapping File

The `.specs/mapping.md` file is **auto-generated** from feature spec YAML frontmatter.

**Do not edit mapping.md directly.** Instead:
1. Update the feature spec's YAML frontmatter
2. The Cursor hook will regenerate mapping.md automatically
3. Or run `./scripts/generate-mapping.sh` manually

### Feature Spec Frontmatter

Every feature spec should have YAML frontmatter:

```yaml
---
feature: Feature Name
domain: domain-name
source: path/to/source.tsx
tests:
  - path/to/test.ts
components:
  - ComponentName
design_refs:
  - tokens.md
personas:
  - primary
  - anti-persona
status: stub | specced | tested | implemented
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

---

## Learnings

Cross-cutting learnings are stored in `.specs/learnings/` by category:

| Category | File |
|----------|------|
| Testing | `.specs/learnings/testing.md` |
| Performance | `.specs/learnings/performance.md` |
| Security | `.specs/learnings/security.md` |
| API & Data | `.specs/learnings/api.md` |
| Design System | `.specs/learnings/design.md` |
| General | `.specs/learnings/general.md` |

Read `.specs/learnings/index.md` for a summary and recent learnings.

Feature-specific learnings are in each spec's `## Learnings` section.

Run `/compound` at the end of implementation sessions to extract and persist learnings.

---

## Roadmap System

For building entire apps, use the roadmap system:

### vision.md

High-level app description:
- What the app does
- Target users
- Key screens
- Tech stack

Created by `/vision` (from description, Jira, or Confluence) or `/clone-app <url>` (from a live app).

### roadmap.md

Ordered list of features with dependencies and status:

```markdown
| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 1 | Auth: Signup | clone-app | PROJ-101 | M | - | ✅ |
| 2 | Dashboard | clone-app | PROJ-102 | L | 1 | ⬜ |
```

Status symbols:
- ⬜ Pending
- 🔄 In Progress
- ✅ Completed
- ⏸️ Blocked
- ❌ Cancelled

### Building from Roadmap

1. `/vision` or `/clone-app` creates vision.md
2. `/personas` creates persona files (from vision's target users)
3. `/design-tokens` creates personality-driven tokens (from vision + personas)
4. `/roadmap` or `/clone-app` creates roadmap.md
5. `/build-next` picks next pending feature (deps met)
6. Build loop runs per feature:
   - Phase 1: Spec agent (creates spec)
   - Phase 2: Build agent (RED → GREEN + self-check drift)
   - Post-build: build + test verification
   - Phase 3: Refactor agent (clean up code, tests must pass)
   - Phase 4: Drift check agent (Layer 2, fresh context)
   - Phase 5: Compound agent (extract learnings)
   - Script marks roadmap ✅ (only after ALL phases pass)
7. Repeat until done

---

## Drift Enforcement

Spec↔code drift is enforced at two layers:

### Layer 1: Self-Check (same agent, lightweight)

Built into the build agent (Phase 2) after GREEN:
- The build agent re-reads its own Gherkin scenarios
- Compares against what it actually implemented
- Fixes obvious mismatches before committing

This is cheap (same context) but has the "fox guarding henhouse" limitation.

### Layer 1b: Post-Refactor Self-Check

Built into `/tdd` and `/spec-first --full` after the refactor step:
- Re-verify spec↔code alignment after refactoring
- Catch any subtle behavior changes from refactoring

### Layer 2: Fresh-Agent Cross-Check (separate agent, thorough)

Built into `build-loop-local.sh` and `overnight-autonomous.sh` (Phase 4):
- After refactor, a **separate agent** is spawned with fresh context
- Reads the spec file and source files without prior build context
- Reports `NO_DRIFT`, `DRIFT_FIXED`, or `DRIFT_UNRESOLVABLE`
- Feature is only marked complete if drift is clean

### Signal Protocol

The build agent MUST output these signals for drift checking:

```
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to .feature.md file}
SOURCE_FILES: {comma-separated source file paths}
```

The drift-check agent MUST output one of:

```
NO_DRIFT
DRIFT_FIXED: {summary of what was reconciled}
DRIFT_UNRESOLVABLE: {what needs human attention}
```

### Configuration

In `.env.local`:

```bash
DRIFT_CHECK=true          # Enable/disable drift checking (default: true)
MAX_DRIFT_RETRIES=1       # Retry attempts for fixing drift (default: 1)
```
