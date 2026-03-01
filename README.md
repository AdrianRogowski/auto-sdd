# SDD 2.0.0: Spec-Driven Development + Compound Learning

A framework for AI-assisted development that combines:
- **Spec-Driven Development (SDD)** - Define behavior before implementing
- **Compound Learning** - Agent gets smarter from every session
- **Roadmap-Driven Automation** - Build entire apps feature-by-feature
- **Overnight Automation** - Wake up to draft PRs

Works with both **Cursor** and **Claude Code**. Build scripts (`build-loop-local.sh`, `overnight-autonomous.sh`) support either CLI — set `CLI_PROVIDER=cursor` or `CLI_PROVIDER=claude` in `.env.local`.

## Installation

### Option 1: Git Alias (Recommended)

Add to your `~/.gitconfig`:

```ini
[alias]
    auto = "!f() { git clone --depth 1 https://github.com/AdrianRogowski/auto-sdd.git .sdd-temp && rm -rf .sdd-temp/.git && cp -r .sdd-temp/. . && rm -rf .sdd-temp && echo 'SDD 2.0.0 installed! Run /spec-first to create your first feature spec.'; }; f"
```

Then in any project:

```bash
git auto
```

This copies all SDD files into your current project:
- `VERSION` - Framework version (semver, e.g. 2.0.0)
- `.cursor/` - Cursor rules, commands, hooks
- `.claude/` - Claude Code commands
- `.specs/` - Feature specs, learnings, design system, roadmap
- `scripts/` - Automation scripts
- `CLAUDE.md` - Agent instructions

### Option 2: Manual Clone

```bash
git clone https://github.com/AdrianRogowski/auto-sdd.git
cp -r auto-sdd/.cursor auto-sdd/.claude auto-sdd/.specs auto-sdd/scripts auto-sdd/CLAUDE.md .
rm -rf auto-sdd
```

### Migrating from SDD 1.0

If you have an existing project using SDD 1.0 (`git sdd`), **do NOT run `git auto`** - it would overwrite your files.

Instead, use the two-step migration process:

```bash
# Step 1: Stage the 2.0 files (creates .sdd-upgrade/ directory)
git auto-upgrade

# Step 2: Run the migration (in Cursor or Claude Code)
/sdd-migrate
```

**Git alias for `auto-upgrade`** (add to `~/.gitconfig`):

```ini
[alias]
    auto-upgrade = "!f() { git clone --depth 1 https://github.com/AdrianRogowski/auto-sdd.git .sdd-temp && rm -rf .sdd-temp/.git && mkdir -p .sdd-upgrade && cp -r .sdd-temp/. .sdd-upgrade/ && rm -rf .sdd-temp && echo 'SDD 2.0.0 files staged in .sdd-upgrade/' && echo 'Now run /sdd-migrate to upgrade'; }; f"
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
/spec-first user authentication    # Create a feature spec
/compound                          # Extract learnings after implementing
/vision "CRM for real estate"      # Create a vision doc from description
/roadmap create                    # Create a roadmap from the vision
/clone-app https://example.com     # Clone an app into vision + roadmap
/build-next                        # Build next feature from roadmap
```

## The Workflows

### Manual: Single Feature

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   DESIGN    │ ──▶ │    SPEC     │ ──▶ │    TEST     │ ──▶ │ IMPLEMENT   │
│ (tokens)    │     │ (Gherkin)   │     │  (failing)  │     │   (code)    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                                                                   ▼
                                                            ┌─────────────┐
                                                            │  /compound  │
                                                            │ (learnings) │
                                                            └─────────────┘
```

### Roadmap: Full App Build

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  /vision    │ ──▶ │  /roadmap   │ ──▶ │ /build-next │ ──▶ │   repeat    │
│ (describe)  │     │  (plan)     │     │  (build)    │     │  until done │
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
            └─ Each feature: build → tests → drift check → [code review] → commit
          Create draft PRs
 7:00 AM  You review 3-4 draft PRs (specs verified against code)
```

### Build Validation Pipeline

Every feature build goes through a multi-stage pipeline. Each agent-based step runs in a **fresh context window** — you can assign different AI models to each step.

```
┌─────────────┐  ┌───────────┐  ┌───────────┐  ┌─────────────┐  ┌─────────────┐  ┌──────────┐
│   BUILD     │─▶│  BUILD    │─▶│   TEST    │─▶│ DRIFT CHECK │─▶│CODE REVIEW  │─▶│  COMMIT  │
│ (spec-first │  │  CHECK    │  │  SUITE    │  │ (fresh agent│  │(fresh agent,│  │          │
│  --full)    │  │ (compile) │  │ (npm test)│  │  Layer 2)   │  │ optional)   │  │          │
└─────────────┘  └───────────┘  └───────────┘  └─────────────┘  └─────────────┘  └──────────┘
      │               │               │               │                │
      └── retry ◄─────┴── retry ◄─────┘               │                │
                                                       ▼                ▼
                                              build+tests re-run  build+tests re-run
                                              (agents modify code)  (agents modify code)
```

| Stage | Type | Controls | Blocking? | Re-validates? |
|-------|------|----------|-----------|---------------|
| Build check | Shell (compile/type check) | `BUILD_CHECK_CMD` | Yes (retry) | — |
| Test suite | Shell (test runner) | `TEST_CHECK_CMD` | Yes (retry) | — |
| Drift check | Agent (fresh context) | `DRIFT_CHECK=true` | Yes (retry) | build + tests after fix |
| Code review | Agent (fresh context) | `POST_BUILD_STEPS` | No (warn only) | build + tests after fix |

**Agents are test-aware**: Every agent receives the test command and is told to run tests and iterate until they pass. The retry agent also receives the actual failure output (last 50/80 lines of build/test errors) so it knows exactly what to fix. After each agent step, the shell re-runs build + tests as a safety net — **zero additional AI tokens** for that verification.

**Model selection**: Each agent step can use a different model via `BUILD_MODEL`, `DRIFT_MODEL`, `REVIEW_MODEL`, etc.

## Slash Commands

### Core Workflow

| Command | Purpose |
|---------|---------|
| `/spec-first` | Create feature spec with Gherkin + ASCII mockup |
| `/spec-first --full` | Create spec AND build without pauses |
| `/compound` | Extract learnings from current session |
| `/spec-init` | Bootstrap SDD on existing codebase |

### Roadmap Commands

| Command | Purpose |
|---------|---------|
| `/vision` | Create or update vision.md from description, Jira, or Confluence |
| `/roadmap` | Create, add features, reprioritize, or check status |
| `/clone-app <url>` | Analyze app → create vision.md + roadmap.md |
| `/build-next` | Build next pending feature from roadmap |
| `/roadmap-triage` | Scan Slack/Jira → add to roadmap |

### Maintenance

| Command | Purpose |
|---------|---------|
| `/sdd-migrate` | Migrate from SDD 1.0 to 2.0 |
| `/catch-drift` | Detect spec ↔ code misalignment |
| `/check-coverage` | Find gaps in spec/test coverage |
| `/fix-bug` | Create regression test for bug |
| `/code-review` | Review against engineering standards |

## Directory Structure

```
.
├── VERSION                 # Framework version (semver, e.g. 2.0.0)
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
│   ├── features/           # Feature specs (Gherkin + ASCII mockups)
│   │   └── {domain}/
│   │       └── {feature}.feature.md
│   ├── test-suites/        # Test documentation
│   ├── design-system/      # Design tokens + component docs
│   ├── learnings/          # Cross-cutting patterns by category
│   │   ├── index.md        # Summary + recent learnings
│   │   ├── testing.md
│   │   ├── performance.md
│   │   ├── security.md
│   │   ├── api.md
│   │   ├── design.md
│   │   └── general.md
│   └── mapping.md          # AUTO-GENERATED routing table
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

SDD uses semantic versioning. The `VERSION` file at the project root holds the framework version (e.g. `2.0.0`). `.specs/.sdd-version` mirrors it for migration detection. To check your version: `cat VERSION`.

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
│                       │ /build-next │ ──▶ Picks next pending    │
│                       └─────────────┘     feature, builds it    │
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

# Build validation
BUILD_CHECK_CMD=""            # Auto-detected (tsc, cargo check, etc.)
TEST_CHECK_CMD=""             # Auto-detected (npm test, pytest, etc.)
POST_BUILD_STEPS="test"       # Comma-separated: test, code-review
DRIFT_CHECK=true              # Spec↔code drift detection

# Model selection (per-step, each gets a fresh context window)
# Cursor: use composer-1.5, sonnet-4.5; Claude: use claude-sonnet-4-5, etc.
AGENT_MODEL="composer-1.5"    # Default for all steps (empty = CLI default)
BUILD_MODEL=""                # Main build agent
DRIFT_MODEL=""                # Catch-drift agent
REVIEW_MODEL=""               # Code-review agent
```

## Feature Spec Format

Every feature spec has YAML frontmatter:

```markdown
---
feature: User Login
domain: auth
source: src/auth/LoginForm.tsx
tests:
  - tests/auth/login.test.ts
components:
  - LoginForm
status: implemented
created: 2026-01-31
updated: 2026-01-31
---

# User Login

## Scenarios

### Scenario: Successful login
Given user is on login page
When user enters valid credentials
Then user is redirected to dashboard

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
| `./scripts/generate-mapping.sh` | Regenerate mapping.md from specs |
| `./scripts/nightly-review.sh` | Extract learnings from today's commits |
| `./scripts/overnight-autonomous.sh` | Full overnight automation (sync, triage, build, PRs) |
| `./scripts/setup-overnight.sh` | Install launchd scheduled jobs |
| `./scripts/uninstall-overnight.sh` | Remove launchd jobs |

### Build Loop Examples

```bash
# Default: Cursor CLI, chained branches, build with test suite enforcement
./scripts/build-loop-local.sh

# Use Claude Code CLI instead
CLI_PROVIDER=claude ./scripts/build-loop-local.sh

# Full validation: tests + code review
POST_BUILD_STEPS="test,code-review" ./scripts/build-loop-local.sh

# Use Opus for building, cheap model for validation
BUILD_MODEL="opus-4.6-thinking" DRIFT_MODEL="gemini-3-flash" ./scripts/build-loop-local.sh

# Branch strategies (set in .env.local or pass inline)
BRANCH_STRATEGY=independent ./scripts/build-loop-local.sh   # Each feature isolated (worktrees)
BRANCH_STRATEGY=both ./scripts/build-loop-local.sh         # Chained + independent rebuild
BRANCH_STRATEGY=sequential ./scripts/build-loop-local.sh   # All features on current branch

# Base branch (default: current branch for build-loop, main for overnight)
BASE_BRANCH=develop ./scripts/build-loop-local.sh
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

# 3. Create the build plan
/roadmap create

# 4. Build feature by feature
/build-next    # Builds feature #1
/build-next    # Builds feature #2
# ...or let overnight automation handle it

# 5. Check progress
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

# 3. Build feature by feature
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

MIT
