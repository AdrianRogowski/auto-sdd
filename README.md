# SDD 2.0: Spec-Driven Development + Compound Learning

A framework for AI-assisted development that combines:
- **Spec-Driven Development (SDD)** - Define behavior before implementing
- **Compound Learning** - Agent gets smarter from every session
- **Overnight Automation** - Wake up to draft PRs from Slack/Jira items

## Quick Start

```bash
# Install Cursor CLI (required for automation)
curl https://cursor.com/install -fsS | bash

# Install yq for YAML parsing
brew install yq

# Configure overnight automation
cp .env.local.example .env.local
nano .env.local  # Set your Slack channel and Jira project

# Set up scheduled jobs (optional)
./scripts/setup-overnight.sh
```

## The Workflow

### Daytime: Manual SDD

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

1. **`/spec-first {feature}`** - Creates spec with Gherkin scenarios + ASCII mockups
2. **Review & approve** - Human checkpoint before implementation
3. **Write tests** - Failing tests from scenarios
4. **Implement** - Code until tests pass
5. **`/compound`** - Extract learnings (optional, end of session)

### Overnight: Autonomous Implementation

```
10:00 PM  Mac stays awake (caffeinate)
10:30 PM  Extract learnings from today's commits
11:00 PM  Scan Slack/Jira → Create specs → Implement → Open draft PRs
 7:00 AM  You review 3-4 draft PRs
```

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/spec-first` | Create feature spec with Gherkin + ASCII mockup |
| `/compound` | Extract learnings from current session |
| `/spec-init` | Bootstrap SDD on existing codebase |
| `/catch-drift` | Detect spec ↔ code misalignment |
| `/check-coverage` | Find gaps in spec/test coverage |
| `/fix-bug` | Create regression test for bug |
| `/code-review` | Review against engineering standards |

## Directory Structure

```
.
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
│   ├── features/           # Feature specs (Gherkin + ASCII mockups)
│   │   └── {domain}/
│   │       └── {feature}.feature.md
│   ├── test-suites/        # Test documentation
│   ├── design-system/      # Design tokens + component docs
│   ├── mapping.md          # AUTO-GENERATED routing table
│   └── learnings.md        # Cross-cutting patterns
│
├── scripts/
│   ├── generate-mapping.sh        # Regenerate mapping.md
│   ├── nightly-review.sh          # Extract learnings (10:30 PM)
│   ├── overnight-autonomous.sh    # Auto-implement features (11:00 PM)
│   ├── setup-overnight.sh         # Install launchd jobs
│   └── launchd/                   # macOS scheduling plists
│
├── logs/                   # Overnight automation logs
├── CLAUDE.md               # Agent instructions + learned patterns
└── .env.local              # Configuration (Slack, Jira, etc.)
```

## Feature Spec Format

Every feature spec has YAML frontmatter that powers the auto-generated mapping:

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

## Configuration

Copy `.env.local.example` to `.env.local` and configure:

```bash
# Slack channel to scan for feature requests
SLACK_CHANNEL=feature-requests

# Jira project and label for auto-ok items
JIRA_PROJECT=PROJ
JIRA_AUTO_LABEL=auto-ok

# Max features per night
MAX_FEATURES=4
```

## How It Works

### Auto-Generated Mapping

The `.specs/mapping.md` file is generated from spec frontmatter:

1. You update a spec's YAML frontmatter
2. Cursor hook runs `generate-mapping.sh`
3. `mapping.md` is regenerated
4. No merge conflicts (each PR only touches its own spec)

### Compound Learning

Learnings are extracted and persisted at three levels:

| Level | Location | Example |
|-------|----------|---------|
| Feature-specific | Spec's `## Learnings` | "Login: Safari needs onBlur" |
| Cross-cutting | `.specs/learnings/{category}.md` | "All forms need loading states" |

Categories: `testing.md`, `performance.md`, `security.md`, `api.md`, `design.md`, `general.md`

### Overnight Automation

1. **Scan**: Agent searches Slack/Jira for feature requests
2. **Filter**: Only items in configured channel/with configured label
3. **Spec**: Creates full spec with Gherkin + mockup
4. **Implement**: Writes tests, implements, runs tests
5. **PR**: Creates draft PR with spec embedded
6. **Mark**: Adds ✅ to Slack or transitions Jira issue

## Scripts

| Script | Purpose |
|--------|---------|
| `./scripts/generate-mapping.sh` | Regenerate mapping.md from specs |
| `./scripts/nightly-review.sh` | Extract learnings from today's commits |
| `./scripts/overnight-autonomous.sh` | Full overnight automation |
| `./scripts/setup-overnight.sh` | Install launchd scheduled jobs |
| `./scripts/uninstall-overnight.sh` | Remove launchd jobs |

## Requirements

- **Cursor** with CLI (`agent` command)
- **GitHub CLI** (`gh`) for PR creation
- **yq** for YAML parsing (`brew install yq`)
- **jq** for JSON parsing (usually pre-installed)

## Credits

Inspired by [Ryan Carson's Compound Engineering](https://x.com/ryancarson/status/2016520542723924279) approach, adapted for Cursor and the SDD workflow.
