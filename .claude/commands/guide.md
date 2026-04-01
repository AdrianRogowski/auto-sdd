# /guide — Generate Living "How to Use" Guide

Generate or update a `GUIDE.md` that explains how to use the built application — not the SDD framework, but the actual app that was built with it.

## What This Command Does

1. **Read all feature specs** — stitch together the user flows, screens, and capabilities
2. **Read codebase** — detect tech stack, entry points, environment requirements
3. **Generate GUIDE.md** — a friendly, practical guide for developers and users
4. **Optionally update README.md** — merge guide content into the project README

---

## Instructions

### Step 1: Gather Context

Read these files in parallel:

```
.specs/vision.md              — app purpose, tech stack
.specs/roadmap.md             — feature list and status
.specs/personas/*.md          — who uses this app
.specs/features/**/*.feature.md — all feature specs (scenarios + user journeys)
.specs/design-system/tokens.md  — design personality
.specs/codebase-summary.md    — architecture overview (if exists)
.specs/learnings/index.md     — key patterns and gotchas
```

Also scan the codebase:
- `package.json` / `pyproject.toml` / `Cargo.toml` — dependencies and scripts
- `.env.local.example` or `.env.example` — required environment variables
- `docker-compose.yml` — infrastructure services
- Entry point files (e.g., `src/app/layout.tsx`, `main.py`, `main.go`)

### Step 2: Generate Sections

Write `GUIDE.md` at the project root with these sections:

#### Quick Start
- Prerequisites (Node version, Python version, etc.)
- Install dependencies
- Set up environment variables (list required ones, explain each)
- Start the development server
- Open in browser

#### What This App Does
- One paragraph from vision.md
- Target user (from primary persona, in plain language)
- Key capabilities (derived from completed features in roadmap)

#### User Flows
For each completed feature (✅ in roadmap), extract the User Journey section from its spec and stitch them together into end-to-end flows:

```markdown
### Getting Started
1. **Sign Up** — Create an account with email and password
2. **Onboarding** — Set your preferences and profile
3. **Dashboard** — See your overview and recent activity

### Managing [Domain]
1. **List View** — Browse and filter items
2. **Create** — Add new items with the form
3. **Detail** — View and edit individual items
```

#### Screen Inventory
List all screens/pages with a one-line description, pulled from feature specs:

```markdown
| Screen | Route | Description |
|--------|-------|-------------|
| Dashboard | `/dashboard` | Overview with stats and recent activity |
| Settings | `/settings` | User preferences and account management |
```

#### API Reference (if applicable)
If the app has API routes, list them:

```markdown
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/items` | List all items |
| POST | `/api/items` | Create new item |
```

#### Environment Variables
Parse from `.env.example` or `.env.local.example`:

```markdown
| Variable | Required | Description |
|----------|----------|-------------|
| DATABASE_URL | Yes | PostgreSQL connection string |
| NEXTAUTH_SECRET | Yes | Session encryption key |
```

#### Architecture
High-level "how it's wired":
- Tech stack summary
- Key directories and what they contain
- Database schema overview (if ORM config exists)
- External services/integrations

#### Key Patterns & Gotchas
Pull from `.specs/learnings/index.md` — the most important cross-cutting patterns for anyone working on this codebase.

#### Development Commands
```markdown
| Command | Purpose |
|---------|---------|
| `npm run dev` | Start dev server |
| `npm test` | Run test suite |
| `npm run build` | Production build |
```

### Step 3: Handle Missing Information

If sections can't be filled because specs don't exist yet:
- Mark them as `<!-- TODO: Add after implementing {feature} -->`
- List what's missing at the bottom

### Step 4: Commit

```
git add GUIDE.md
git commit -m "docs: generate/update application guide"
```

### Step 5: Report

```
✓ GUIDE.md generated/updated

  Sections:
    ✅ Quick Start (complete)
    ✅ What This App Does (from vision.md)
    ✅ User Flows (8 features documented)
    ✅ Screen Inventory (12 screens)
    ⚠️ API Reference (3 endpoints found, may be incomplete)
    ✅ Environment Variables (7 vars documented)
    ✅ Architecture (from codebase scan)
    ✅ Key Patterns (from learnings)

  Open GUIDE.md to review.
```

---

## When to Run

- After `/compound` — to capture newly built features
- After `/build-next` completes — to add the new feature to the guide
- Periodically — to sync the guide with the current state of the app
- Before onboarding a new developer — to give them a "start here" doc

## Update Mode

If `GUIDE.md` already exists, update it rather than overwriting:
- Add new features to user flows and screen inventory
- Update architecture if new patterns emerged
- Preserve any manual edits (look for `<!-- manual -->` markers)
