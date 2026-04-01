# SDD: Spec-Driven Development + Compound Learning

A framework for AI-assisted development that combines:
- **Spec-Driven Development (SDD)** - Define behavior before implementing
- **Red-Green-Refactor TDD** - Failing tests → implement → clean up (via `/tdd` command)
- **User Personas** - Specs are written in users' language, scoped to their patience
- **Personality-Driven Design** - Design system derived from vision, not generic templates
- **Compound Learning** - Agent gets smarter from every session
- **Roadmap-Driven Automation** - Build entire apps feature-by-feature
- **Overnight Automation** - Wake up to draft PRs

Works with both **Cursor** and **Claude Code**. Build scripts (`build-loop-local.sh`, `overnight-autonomous.sh`) support either CLI — set `CLI_PROVIDER=cursor` or `CLI_PROVIDER=claude` in `.env.local`.

## Installation

### Option 1: Git Alias (Recommended)

Add to your `~/.gitconfig`:

```ini
[alias]
    auto = "!f() { git clone --depth 1 https://github.com/AdrianRogowski/auto-sdd.git .sdd-temp && rm -rf .sdd-temp/.git && cp -r .sdd-temp/. . && rm -rf .sdd-temp && echo \"SDD $(cat VERSION 2>/dev/null || echo latest) installed! Run /spec-first to create your first feature spec.\"; }; f"
```

Then in any project:

```bash
git auto
```

This copies all SDD files into your current project:
- `VERSION` - Framework version (semver)
- `.cursor/` - Cursor rules, commands, hooks
- `.claude/` - Claude Code commands
- `.specs/` - Feature specs, learnings, design system, personas, roadmap
- `scripts/` - Automation scripts
- `CLAUDE.md` - Agent instructions

### Option 2: Manual Clone

```bash
git clone https://github.com/AdrianRogowski/auto-sdd.git
cp -r auto-sdd/.cursor auto-sdd/.claude auto-sdd/.specs auto-sdd/scripts auto-sdd/CLAUDE.md .
rm -rf auto-sdd
```

### Upgrading an Existing SDD Project

If you have an existing SDD project (any version), **do NOT run `git auto`** — it would overwrite your files.

Instead, use the two-step upgrade process:

```bash
# Step 1: Stage the latest files (creates .sdd-upgrade/ directory)
git auto-upgrade

# Step 2: Run the upgrade (in Cursor or Claude Code)
/sdd-migrate
```

This works for any version → latest (1.0→2.1, 2.0→2.1, etc.). Custom commands and rules are preserved; only stock SDD files are updated. See `CHANGELOG.md` for what's new in each version.

**Git alias for `auto-upgrade`** (add to `~/.gitconfig`):

```ini
[alias]
    auto-upgrade = "!f() { git clone --depth 1 https://github.com/AdrianRogowski/auto-sdd.git .sdd-temp && rm -rf .sdd-temp/.git && mkdir -p .sdd-upgrade && cp -r .sdd-temp/. .sdd-upgrade/ && rm -rf .sdd-temp && echo \"SDD $(cat .sdd-upgrade/VERSION 2>/dev/null || echo latest) files staged in .sdd-upgrade/\" && echo 'Now run /sdd-migrate to upgrade'; }; f"
```

### Post-Install (Optional: Overnight Automation)

```bash
# Install dependencies
brew install yq gh

# Configure Slack/Jira integration
cp .env.local.example .env.local
nano .env.local

# Set up scheduled jobs
./scripts/setup-overnight.sh
```

## Quick Start

After installing, use the slash commands:

```
/vision "CRM for real estate"      # Define what you're building
/personas                          # Create user personas (vocabulary, patience, frustrations)
/design-tokens                     # Create personality-driven design system
/spec-first user authentication    # Create a feature spec (informed by personas + tokens)
/tdd                               # Build it: RED → GREEN → REFACTOR → COMPOUND
/roadmap create                    # Create a roadmap from the vision
/build-next                        # Build next feature from roadmap
```

## The Workflows

### Project Setup (Once)

Before building features, set up the project-level infrastructure. Each step reads the output of the previous:

```
/vision "description"  →  /personas  →  /design-tokens
     │                        │               │
     ▼                        ▼               ▼
 vision.md              personas/         tokens.md
 (app purpose,          (vocabulary,      (personality-driven
  users, tech)           patience,         colors, spacing,
                         frustrations)     typography)
```

All three are optional but improve every spec. `/spec-first` will note what's missing.

### Per Feature: Spec → Red-Green-Refactor TDD

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    SPEC      │ ──▶ │  RED (test)  │ ──▶ │ GREEN (impl) │ ──▶ │  REFACTOR    │
│              │     │  (failing)   │     │ (until tests │     │ (clean up,   │
│ Reads:       │     │              │     │  pass)       │     │  tests must  │
│ - personas   │     │              │     │              │     │  still pass) │
│ - tokens     │     │              │     │              │     │              │
│              │     │              │     │              │     │              │
│ Writes:      │     │              │     │              │     │              │
│ - Gherkin    │     │              │     │              │     │              │
│ - mockup     │     │              │     │              │     │              │
│ - journey    │     │              │     │              │     │              │
│              │     │              │     │              │     │              │
│ Then:        │     └──────────────┘     └──────┬───────┘     └──────┬───────┘
│ - persona    │                                 │                     │
│   revision   │                                 ▼                     ▼
└──────┬───────┘                          ┌──────────────┐     ┌──────────────┐
       │                                  │ DRIFT CHECK  │     │ DRIFT CHECK  │
    [PAUSE]                               │ (layer 1)    │     │ (layer 1b)   │
  user approves                           └──────────────┘     └──────┬───────┘
  then /tdd                                                          │
                                                                     ▼
                                                              ┌──────────────┐
                                                              │  /compound   │
                                                              │ (learnings)  │
                                                              └──────────────┘
```

The **SPEC** step loads personas and design tokens, writes Gherkin scenarios using the user's vocabulary, creates ASCII mockups referencing design tokens, then re-reads the draft through the persona's eyes and revises. The revision notes appear at the pause point so you see what changed and why.

The **TDD** step (`/tdd` command) runs the full Red-Green-Refactor cycle: write failing tests (RED), implement until they pass (GREEN), self-check drift, refactor the code (tests must still pass), re-check drift, then extract learnings.

### Roadmap: Full App Build

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  /vision    │ ──▶ │  /personas  │ ──▶ │  /roadmap   │ ──▶ │ /build-next │
│ (describe)  │     │ + /tokens   │     │  (plan)     │     │  (repeat)   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘

Or from an existing app:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  /clone-app │ ──▶ │ vision.md + │ ──▶ │ /build-next │ ──repeat──▶ App Built!
│  (analyze)  │     │ roadmap.md  │     │  (loop)     │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Overnight: Autonomous

```
11:00 PM  /roadmap-triage (scan Slack/Jira → add to roadmap)
          /build-next × MAX_FEATURES (build from roadmap)
            └─ Each feature: spec → RED → GREEN → refactor → drift check → compound → [code review] → commit
          Create draft PRs
 7:00 AM  You review 3-4 draft PRs (specs verified against code)
```

### Document Existing Codebase

For codebases built without specs, use the doc-loop to systematically document everything:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /spec-init     │ ──▶ │ doc-loop-local  │ ──▶ │  Verification   │
│ (discovery)     │     │ (fresh agent    │     │ (coverage       │
│                 │     │  per domain)    │     │  report)        │
│ Creates:        │     │                 │     │                 │
│ - doc-queue.md  │     │ Processes:      │     │ Reports:        │
│ - codebase-     │     │ - specs         │     │ - % documented  │
│   summary.md    │     │ - tests         │     │ - gaps          │
│                 │     │ - test docs     │     │ - issues found  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
     (in IDE)              (in terminal)           (in terminal)
```

**Philosophy: Document, don't fix.** Tests are written to pass against current code. Pre-existing failures are recorded as baseline, not fixed. Source code is never modified.

```bash
# Interactive: review queue before processing
/spec-init                                # Creates doc-queue.md (in Cursor/Claude)
# ... review .specs/doc-queue.md ...
./scripts/doc-loop-local.sh --continue    # Process the queue

# Headless: discovery + process in one go
./scripts/doc-loop-local.sh

# Scoped: only document one directory
./scripts/doc-loop-local.sh --scope src/auth

# Discovery only: just create the queue
./scripts/doc-loop-local.sh --discovery-only

# Resume after interruption
./scripts/doc-loop-local.sh --continue
```

Each queue item gets a **fresh agent context**, so documentation quality stays consistent even for large codebases (unlike running everything in one agent session).

### Rebuild: Seeded from Previous Project

When you've iterated on a project and know what works, strip the behavioral specs and rebuild fresh with a better model or cleaner architecture:

```
Old Project                         New Project
┌─────────────────────┐             ┌─────────────────────┐
│ .specs/features/    │  strip-     │ .specs/features/    │
│   158 specs with    │──specs.sh──▶│   34 stripped specs  │
│   implementation    │             │   (behavior only)   │
│   details           │             │                     │
│ .specs/personas/    │────copy────▶│ .specs/personas/    │
│ .specs/design-sys/  │────copy────▶│ .specs/design-sys/  │
│ .specs/vision.md    │──copy+flag─▶│ .specs/vision.md    │
└─────────────────────┘             └─────────────────────┘
                                            │
                                    edit vision + roadmap
                                            │
                                            ▼
                                    ./scripts/build-loop-local.sh
                                    (agent reads seeded specs in
                                     update mode, makes own
                                     architecture decisions)
```

```bash
# 1. Strip specs from old project (exclude features you don't want)
./scripts/strip-specs.sh \
  --source ~/projects/old-app \
  --target ~/projects/new-app \
  --exclude "deal-pipeline,contact-manager,email-integration" \
  --include-context

# 2. Edit vision and roadmap for new scope
cd ~/projects/new-app
# (update .specs/vision.md, create .specs/roadmap.md)

# 3. Build from seeded specs
./scripts/build-loop-local.sh
```

Stripped specs keep Gherkin scenarios, ASCII mockups, and user journeys. File paths, test refs, component lists, architecture notes, and learnings are removed. The build agent reads the behavioral seed via `/spec-first` update mode and makes fresh architecture decisions.

### Build Validation Pipeline

Every feature build goes through a multi-stage pipeline. Each agent-based step runs in a **fresh context window** — you can assign different AI models to each step.

**Manual** (`/build-next` in Cursor/Claude): Uses `/spec-first --full` — spec, RED, GREEN, refactor, drift check, compound, commit.

**Automated** (scripts): Uses a **5-phase** flow — each phase gets a fresh context window and can use a different model.

```
┌─────────┐  ┌─────────┐  ┌────────┐  ┌─────────┐  ┌────────┐  ┌──────┐  ┌──────────┐  ┌────────┐  ┌─────────┐  ┌──────┐  ┌──────────┐  ┌─────────┐
│ Phase 1 │─▶│ Phase 2 │─▶│ build  │─▶│ migrate │─▶│  test  │─▶│ lint │─▶│ Phase 3  │─▶│ build  │─▶│ Phase 4 │─▶│ e2e  │─▶│ Phase 5  │─▶│ roadmap │
│ SPEC    │  │ BUILD   │  │ check  │  │ (if     │  │ suite  │  │      │  │ REFACTOR │  │+test   │  │ DRIFT   │  │      │  │ COMPOUND │  │   ✅    │
│ (agent) │  │ (agent) │  │(shell) │  │ schema) │  │(shell) │  │      │  │ (agent)  │  │(shell) │  │ (agent) │  │      │  │ (agent)  │  │(script) │
└─────────┘  └─────────┘  └────────┘  └─────────┘  └────────┘  └──────┘  └──────────┘  └────────┘  └─────────┘  └──────┘  └──────────┘  └─────────┘
     │             │            │                        │                      │              │           │                     │
     └── retry ◄───┴── retry ◄──┴──────── retry ◄───────┘                reverts if broken ◄──┘           │                     │
                                                                                                          ▼                     ▼
                                                                                                     build+tests           non-fatal
                                                                                                     re-run
```

| Phase | Type | Model | Controls | Blocking? | Safety net |
|-------|------|-------|----------|-----------|------------|
| 1. Spec | Agent | `SPEC_MODEL` | — | Yes (retry) | — |
| 2. Build (RED→GREEN) | Agent | `BUILD_MODEL` | — | Yes (retry) | — |
| Build check | Shell | — | `BUILD_CHECK_CMD` | Yes (retry) | — |
| Migration | Shell | — | `MIGRATION_CMD` | No (warn) | Only runs when schema files change |
| Test check | Shell | — | `TEST_CHECK_CMD` | Yes (retry) | — |
| Lint check | Shell | — | `LINT_CHECK_CMD` | No (warn) | — |
| 3. Refactor | Agent | `REFACTOR_MODEL` | `REFACTOR=true` | No (auto-reverts) | Reverts to pre-refactor if build/tests break |
| Post-refactor check | Shell | — | `BUILD_CHECK_CMD`, `TEST_CHECK_CMD` | — | Triggers revert |
| 4. Drift check | Agent | `DRIFT_MODEL` | `DRIFT_CHECK=true` | Yes (retry) | build + tests after fix |
| E2E check | Shell | — | `E2E_CHECK_CMD` | No (warn) | Runs after drift (final code) |
| 5. Compound | Agent | `COMPOUND_MODEL` | `COMPOUND=true` | No (non-fatal) | — |
| Code review | Agent | `REVIEW_MODEL` | `POST_BUILD_STEPS` | No (warn only) | build + tests after fix |
| Roadmap ✅ | Script | — | — | — | Only marks complete after ALL phases pass |

**Data flow**: Spec phase outputs `FEATURE_SPEC_READY` + `SPEC_FILE` → build phase. Build phase outputs `FEATURE_BUILT` + `SOURCE_FILES` → refactor, drift, and compound phases. Build/test failures feed `LAST_BUILD_OUTPUT` and `LAST_TEST_OUTPUT` into the retry agent.

**Lazy re-detection**: All check commands (`BUILD_CHECK_CMD`, `TEST_CHECK_CMD`, `LINT_CHECK_CMD`, `MIGRATION_CMD`, `E2E_CHECK_CMD`) are auto-detected from project files. If empty at startup (e.g., greenfield project where Feature 1 creates the infrastructure), they are **re-detected after each feature** and persisted back to `.env.local`. This means Feature 1 can create `package.json`, `tsconfig.json`, and `drizzle.config.ts`, and the script will automatically pick up `npx tsc --noEmit`, `npm test`, `npm run lint`, and `npm run db:push` for Features 2+.

**Infrastructure hint**: For early features (first 2), the build prompt includes a reminder to update `.env.local` with correct verification commands if the feature creates project infrastructure.

**Roadmap status**: The spec agent marks the feature 🔄 (in progress). The **script** (not any agent) marks it ✅ only after all phases pass. This prevents features being marked complete when post-build verification fails. If the loop is interrupted and restarted, it will **resume any 🔄 in-progress feature** before picking up the next ⬜ pending one.

**Transient error handling**: The scripts detect rate limit errors (429, overloaded) AND transient network errors (connection reset, ECONNRESET, ETIMEDOUT, socket hang up, etc.) and retry with exponential backoff (configurable via `RATE_LIMIT_BACKOFF` and `RATE_LIMIT_MAX_WAIT`).

**Model selection**: Each phase can use a different model: `SPEC_MODEL`, `BUILD_MODEL`, `REFACTOR_MODEL`, `DRIFT_MODEL`, `COMPOUND_MODEL`, `REVIEW_MODEL`.

## Slash Commands

### Setup

| Command | Purpose |
|---------|---------|
| `/vision` | Create or update vision.md from description, Jira, or Confluence |
| `/personas` | Create user personas (vocabulary, patience, frustrations, anti-persona) |
| `/design-tokens` | Create personality-driven design tokens (reads vision + personas) |
| `/spec-init` | Discover codebase structure, create doc-queue.md (discovery only) |

### Core Workflow

| Command | Purpose |
|---------|---------|
| `/spec-first` | Create or update feature spec with Gherkin + ASCII mockup (persona-informed) |
| `/spec-first --full` | Create/update spec AND build without pauses (full Red-Green-Refactor cycle) |
| `/tdd` | Run Red-Green-Refactor cycle from an approved spec |
| `/compound` | Extract learnings from current session |

### Roadmap Commands

| Command | Purpose |
|---------|---------|
| `/roadmap` | Create, add features, reprioritize, or check status |
| `/clone-app <url>` | Analyze app → create vision.md + roadmap.md |
| `/build-next` | Build next pending feature from roadmap |
| `/roadmap-triage` | Scan Slack/Jira → add to roadmap |

### Rebuild & Seed

| Command | Purpose |
|---------|---------|
| `/strip-specs` | Strip implementation details from specs for rebuilding in a new project |

### Ralph Commands (Build Loop Management)

| Command | Purpose |
|---------|---------|
| `/ralph-setup` | Interactive wizard: configure .env.local with auto-detection |
| `/ralph-run` | Show roadmap status, kill dev servers, launch build loop |
| `/clean-slate` | Kill all processes on dev ports, optionally restart dev server |
| `/guide` | Generate/update GUIDE.md — living "how to use" guide for the built app |

### Maintenance

| Command | Purpose |
|---------|---------|
| `/sdd-migrate` | Upgrade SDD to latest version |
| `/refactor` | Refactor code while keeping tests green |
| `/catch-drift` | Detect spec ↔ code misalignment |
| `/check-coverage` | Find gaps in spec/test coverage |
| `/fix-bug` | Create regression test for bug |
| `/code-review` | Review against engineering standards |

## Personas

User personas live in `.specs/personas/` and inform every feature spec. They're created once by `/personas` (or auto-suggested on first `/spec-first`) and referenced before every spec is written.

**What they contain:**
- **Context** — how the user spends their day, devices, technical level
- **Vocabulary** — their words vs developer words → drives all UI labels
- **Patience level** — Very Low / Low / Medium / High → drives flow length
- **Frustrations** — interaction patterns to avoid
- **Success metric** — how they measure if the app works

**How `/spec-first` uses them:**
1. Reads personas before writing Gherkin and mockups
2. Uses persona vocabulary in all labels and copy
3. Matches flow length to patience level
4. After drafting, re-reads through persona's eyes and revises
5. Shows revision notes at the pause point ("renamed X → Y because broker vocabulary")

**Anti-persona** — describes who you're NOT building for. Prevents scope creep. If a scenario is really for the anti-persona, it gets cut or deferred.

## Design System

The design system lives in `.specs/design-system/tokens.md` and is created by `/design-tokens`.

Unlike generic design token templates, `/design-tokens` derives a **tailored** system:

1. **Reads context** — vision.md (app purpose, design principles), personas (patience, technical level)
2. **Determines personality** — Professional, Friendly, Minimal, Bold, or Technical
3. **Derives palette** — starts from one primary color, derives neutrals (tinted, not pure gray), semantic colors matched to palette energy
4. **Constrains to v1** — fewer tokens used consistently beats many tokens used randomly
5. **Documents rationale** — explains *why* these choices, not just what they are

| Personality | Radii | Spacing | Example Apps |
|-------------|-------|---------|-------------|
| Professional | 2-6px | Tight (4px base) | Linear, Jira |
| Friendly | 8-12px | Comfortable (8px base) | Notion, Slack |
| Minimal | 4-8px | Generous whitespace | iA Writer, Apple |
| Bold | 12-16px+ | Generous | Stripe, Vercel |
| Technical | 0-4px | Tight-compact | GitHub, Grafana |

## Directory Structure

```
.
├── VERSION                 # Framework version (semver)
├── CHANGELOG.md            # Release history
├── .cursor/
│   ├── commands/           # Slash command definitions
│   ├── rules/              # Cursor rules (SDD workflow, design tokens)
│   ├── hooks.json          # Cursor hooks configuration
│   └── hooks/              # Hook scripts
│
├── .claude/
│   └── commands/           # Claude Code command definitions
│
├── .specs/
│   ├── vision.md           # App vision (created by /vision or /clone-app)
│   ├── roadmap.md          # Feature roadmap (single source of truth)
│   ├── personas/           # User personas (inform every spec)
│   │   ├── primary.md      # Main user persona
│   │   ├── anti-persona.md # Who you're NOT building for
│   │   └── _template.md    # Template for new personas
│   ├── features/           # Feature specs (Gherkin + ASCII mockups)
│   │   └── {domain}/
│   │       └── {feature}.feature.md
│   ├── test-suites/        # Test documentation
│   ├── design-system/      # Personality-driven tokens + component docs
│   │   ├── tokens.md       # Colors, spacing, typography (with rationale)
│   │   └── components/     # Component pattern docs
│   ├── learnings/          # Cross-cutting patterns by category
│   │   ├── index.md        # Summary + recent learnings
│   │   ├── testing.md
│   │   ├── performance.md
│   │   ├── security.md
│   │   ├── api.md
│   │   ├── design.md
│   │   └── general.md
│   ├── mapping.md          # AUTO-GENERATED routing table
│   └── doc-queue.md        # Documentation queue (created by /spec-init or doc-loop)
│
├── scripts/
│   ├── build-loop-local.sh        # Run /build-next in a loop (no remote)
│   ├── generate-mapping.sh        # Regenerate mapping.md
│   ├── nightly-review.sh          # Extract learnings (10:30 PM)
│   ├── overnight-autonomous.sh    # Auto-implement features (11:00 PM)
│   ├── setup-overnight.sh         # Install launchd jobs
│   ├── uninstall-overnight.sh     # Remove launchd jobs
│   └── launchd/                   # macOS scheduling plists
│
├── logs/                   # Overnight automation logs
├── CLAUDE.md               # Agent instructions (universal)
└── .env.local              # Configuration (Slack, Jira, etc.)
```

### Versioning

SDD uses semantic versioning (MAJOR.MINOR.PATCH). The `VERSION` file holds the framework version. `.specs/.sdd-version` mirrors it for upgrade detection. To check: `cat VERSION`. See `CHANGELOG.md` for release history.

## Roadmap System

The roadmap is the **single source of truth** for what to build.

### vision.md

High-level app description. Created by:
- `/vision "description"` — from a text description
- `/vision --from-jira PROJECT_KEY` — seeded from Jira epics
- `/vision --from-confluence PAGE_ID` — seeded from a Confluence page
- `/clone-app <url>` — from analyzing a live app
- `/vision --update` — refresh based on what's been built and learned

Contents: app overview, target users, key screens, tech stack, design principles.

### roadmap.md

Ordered list of features with dependencies. Managed by:
- `/roadmap create` — build from vision.md
- `/roadmap add "feature"` — add features to existing roadmap
- `/roadmap reprioritize` — restructure phases and reorder
- `/roadmap status` — read-only progress report
- `/clone-app <url>` — auto-generated from app analysis
- `/roadmap-triage` — add items from Slack/Jira

```markdown
## Phase 1: Foundation

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 1 | Project setup | clone-app | PROJ-101 | S | - | ✅ |
| 2 | Auth: Signup | clone-app | PROJ-102 | M | 1 | 🔄 |
| 3 | Auth: Login | clone-app | PROJ-103 | M | 1 | ⬜ |

## Ad-hoc Requests

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 100 | Dark mode | slack:C123/ts | PROJ-200 | M | - | ⬜ |
```

### How Features Flow In

```
┌─────────────────────────────────────────────────────────────────┐
│                     ROADMAP (Single Source)                     │
├─────────────────────────────────────────────────────────────────┤
│                              ▲                                  │
│          ┌───────────────────┼───────────────────┐              │
│          │                   │                   │              │
│    ┌─────┴─────┐  ┌────┴────┐  ┌────┴────┐  ┌─────┴─────┐       │
│    │  /vision   │  │/roadmap │  │  Slack  │  │   Jira    │       │
│    │ /clone-app │  │  add    │  │(triage) │  │ (triage)  │       │
│    └───────────┘  └────────┘  └────────┘  └───────────┘       │
│                                                                 │
│                              │                                  │
│                              ▼                                  │
│                       ┌─────────────┐                           │
│                       │ /build-next │ ──▶ Resumes 🔄 or picks   │
│                       └─────────────┘     next ⬜, builds it    │
└─────────────────────────────────────────────────────────────────┘
```

## Jira/Slack Integration

The system integrates with Jira and Slack via MCPs:

| Action | Jira | Slack |
|--------|------|-------|
| **Triage** | Search by label | Search channel |
| **Track** | Create tickets for features | Reply with Jira link |
| **Start** | Transition to "In Progress" | - |
| **Complete** | Transition to "Done" + PR link | Reply with ✅ |

Configure in `.env.local`:

```bash
# CLI provider for build scripts (cursor | claude)
# - cursor: Cursor CLI (agent) — default
# - claude: Claude Code CLI (model names differ per provider)
CLI_PROVIDER=cursor

# Slack
SLACK_FEATURE_CHANNEL="#feature-requests"
SLACK_REPORT_CHANNEL="#dev-updates"

# Jira
JIRA_CLOUD_ID="yoursite.atlassian.net"
JIRA_PROJECT_KEY="PROJ"
JIRA_AUTO_LABEL="auto-ok"

# Base branch (branch to sync from and create feature branches from)
BASE_BRANCH=                  # Unset: build-loop uses current branch; overnight uses main
# BASE_BRANCH=develop         # Use develop instead of main
# BASE_BRANCH=current         # Overnight: use whatever branch you're on

# Options
CREATE_JIRA_FOR_SLACK=true    # Create Jira tickets for Slack requests
SYNC_JIRA_STATUS=true         # Keep Jira status in sync
MAX_FEATURES=4                # Features per overnight run

# Build validation (all auto-detected if empty, re-detected after each feature)
BUILD_CHECK_CMD=""            # Auto-detected (tsc, cargo check, go build, etc.)
TEST_CHECK_CMD=""             # Auto-detected (npm test, pytest, cargo test, etc.)
LINT_CHECK_CMD=""             # Auto-detected (npm run lint, ruff check, etc.) — non-blocking
MIGRATION_CMD=""              # Auto-detected (drizzle-kit push, prisma db push, etc.) — non-blocking
E2E_CHECK_CMD=""              # Auto-detected (playwright, cypress) — non-blocking
POST_BUILD_STEPS="test"       # Comma-separated: test, code-review
DRIFT_CHECK=true              # Spec↔code drift detection (Phase 4)
REFACTOR=true                 # Refactor phase after tests pass (Phase 3)
COMPOUND=true                 # Compound/learnings phase (Phase 5)

# Model selection (per-phase, each gets a fresh context window)
# Cursor: composer-1.5, sonnet-4.5; Claude: claude-sonnet-4-5, etc.
AGENT_MODEL="composer-1.5"    # Default for all phases (empty = CLI default)
SPEC_MODEL=""                 # Phase 1: Spec (find feature, create spec only)
BUILD_MODEL=""                # Phase 2: Build (RED → GREEN, tests + implement)
REFACTOR_MODEL=""             # Phase 3: Refactor (clean up, tests must pass)
DRIFT_MODEL=""                # Phase 4: Catch-drift agent
COMPOUND_MODEL=""             # Phase 5: Compound/learnings agent
RETRY_MODEL=""                # Retry agent (fixing build/test failures)
REVIEW_MODEL=""               # Code-review agent (optional)

# Transient error handling (rate limits + network errors like connection reset)
RATE_LIMIT_BACKOFF=60         # Initial wait in seconds
RATE_LIMIT_MAX_WAIT=18000     # Max wait (~5 hours)
```

## Feature Spec Format

Every feature spec has YAML frontmatter and references personas:

```markdown
---
feature: User Login
domain: auth
source: src/auth/LoginForm.tsx
tests:
  - tests/auth/login.test.ts
components:
  - LoginForm
personas:
  - primary
  - anti-persona
status: implemented
created: 2026-01-31
updated: 2026-01-31
---

# User Login

**Personas**: .specs/personas/primary.md

## Scenarios

### Scenario: Successful login
Given user is on the login page
When user enters their email and password
Then user sees their dashboard

## User Journey

1. User lands on marketing page (existing)
2. **Clicks "Log in" → sees this login form**
3. Submits → redirected to Dashboard (feature #5)

## UI Mockup

┌─────────────────────────────────────┐
│           Welcome Back              │
├─────────────────────────────────────┤
│  Email: [________________]          │
│  Password: [________________]       │
│  [        Log in        ]           │
└─────────────────────────────────────┘

## Learnings

### 2026-01-31
- **Gotcha**: Safari autofill needs onBlur handler
```

## Compound Learning

Learnings are persisted at two levels:

| Level | Location | Example |
|-------|----------|---------|
| Feature-specific | Spec's `## Learnings` section | "Login: Safari needs onBlur" |
| Cross-cutting | `.specs/learnings/{category}.md` | "All forms need loading states" |

Categories: `testing.md`, `performance.md`, `security.md`, `api.md`, `design.md`, `general.md`

## Scripts

| Script | Purpose |
|--------|---------|
| `./scripts/build-loop-local.sh` | Run /build-next in a loop locally (no remote/push/PR). Config: CLI_PROVIDER, BASE_BRANCH, BRANCH_STRATEGY, MAX_FEATURES |
| `./scripts/doc-loop-local.sh` | Document existing codebase (discovery + fresh agent per domain). Config: CLI_PROVIDER, DOC_MODEL, DISCOVERY_MODEL |
| `./scripts/strip-specs.sh` | Strip implementation details from specs for seeding a rebuild |
| `./scripts/generate-mapping.sh` | Regenerate mapping.md from specs |
| `./scripts/nightly-review.sh` | Extract learnings from today's commits |
| `./scripts/overnight-autonomous.sh` | Full overnight automation (sync, triage, build, PRs) |
| `./scripts/setup-overnight.sh` | Install launchd scheduled jobs |
| `./scripts/uninstall-overnight.sh` | Remove launchd jobs |
| `./scripts/clean-slate.sh` | Kill all processes on dev ports, optionally restart dev server |

### Build Loop Examples

```bash
# Default: Cursor CLI, chained branches, build with test suite enforcement
./scripts/build-loop-local.sh

# Use Claude Code CLI instead
CLI_PROVIDER=claude ./scripts/build-loop-local.sh

# Full validation: tests + code review
POST_BUILD_STEPS="test,code-review" ./scripts/build-loop-local.sh

# Use Opus for spec (strong at planning), cheaper for implementation
SPEC_MODEL="opus-4.6-thinking" BUILD_MODEL="composer-1.5" ./scripts/build-loop-local.sh

# Branch strategies (set in .env.local or pass inline)
BRANCH_STRATEGY=independent ./scripts/build-loop-local.sh   # Each feature isolated (worktrees)
BRANCH_STRATEGY=both ./scripts/build-loop-local.sh         # Chained + independent rebuild
BRANCH_STRATEGY=sequential ./scripts/build-loop-local.sh   # All features on current branch
BRANCH_STRATEGY=parallel ./scripts/build-loop-local.sh    # Concurrent builds + merge (NEW)
BRANCH_STRATEGY=parallel PARALLEL_FEATURES=5 ./scripts/build-loop-local.sh  # 5 concurrent agents

# Base branch (default: current branch for build-loop, main for overnight)
BASE_BRANCH=develop ./scripts/build-loop-local.sh

# Skip refactor phase (faster builds)
REFACTOR=false ./scripts/build-loop-local.sh

# Skip compound/learnings phase
COMPOUND=false ./scripts/build-loop-local.sh

# Claude Code with rate-limit handling (longer backoff for Opus)
CLI_PROVIDER=claude RATE_LIMIT_BACKOFF=120 RATE_LIMIT_MAX_WAIT=18000 ./scripts/build-loop-local.sh
```

### Doc Loop Examples

```bash
# Default: Cursor CLI, document entire codebase
./scripts/doc-loop-local.sh

# Use Claude Code CLI
CLI_PROVIDER=claude ./scripts/doc-loop-local.sh

# Discovery only (review queue before processing)
./scripts/doc-loop-local.sh --discovery-only

# Resume from existing queue
./scripts/doc-loop-local.sh --continue

# Scope to one directory
./scripts/doc-loop-local.sh --scope src/components

# Use different models for discovery vs documentation
DISCOVERY_MODEL="opus-4.6-thinking" DOC_MODEL="composer-1.5" ./scripts/doc-loop-local.sh

# Skip test writing (specs only)
DOC_WRITE_TESTS=false ./scripts/doc-loop-local.sh

# Commit more frequently (every 3 items instead of 5)
COMMIT_EVERY=3 ./scripts/doc-loop-local.sh

# Just run verification on already-processed queue
./scripts/doc-loop-local.sh --verify-only
```

## Requirements

- **Cursor** or **Claude Code** (for slash commands)
- **GitHub CLI** (`gh`) for PR creation
- **yq** for YAML parsing (`brew install yq`)

For build scripts (`build-loop-local.sh`, `overnight-autonomous.sh`):
- **Cursor CLI** (`agent`) or **Claude Code CLI** (`claude`) — set `CLI_PROVIDER=cursor` or `CLI_PROVIDER=claude` in `.env.local`
- macOS (for launchd scheduling of overnight runs)

## Example: Building a Full App

### From a description

```bash
# 1. Initialize project
mkdir my-app && cd my-app
git init
git auto

# 2. Define what you're building
/vision "A task management app for small teams with projects, labels, and due dates"

# 3. Create personas and design system
/personas                    # Creates primary persona + anti-persona
/design-tokens               # Derives personality-driven tokens from vision + personas

# 4. Create the build plan
/roadmap create

# 5. Build feature by feature
/build-next    # Builds feature #1 (spec uses persona vocabulary + design tokens)
/build-next    # Builds feature #2
# ...or let overnight automation handle it

# 6. Check progress
/roadmap status
```

### From an existing app

```bash
# 1. Initialize project
mkdir my-app && cd my-app
git init
git auto

# 2. Clone an existing app into roadmap
/clone-app https://todoist.com

# Creates:
# - .specs/vision.md (app description)
# - .specs/roadmap.md (20 features across 3 phases)

# 3. Create personas and design system
/personas                    # From vision's target users
/design-tokens               # From vision + personas

# 4. Build feature by feature
/build-next    # Builds feature #1
/build-next    # Builds feature #2
```

### Adding features later

```bash
# Add a new feature or phase
/roadmap add "email notifications and digest system"

# Pull in requests from Slack/Jira
/roadmap-triage

# Restructure after priorities change
/roadmap reprioritize

# Update vision after building 20 features
/vision --update
```

## Credits

Inspired by [Ryan Carson's Compound Engineering](https://x.com/ryancarson) approach, adapted for Cursor/Claude Code and the SDD workflow.

## License

Copyright (c) 2026 Adrian Rogowski. All rights reserved.

This software is proprietary. No part of it may be copied, modified, distributed, or used without the prior written permission of the copyright holder. See [LICENSE](LICENSE) for details.
