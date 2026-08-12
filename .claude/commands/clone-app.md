# Clone App

Analyze an existing web application and create a build plan (vision + roadmap).

## Usage

```
/clone-app <url>
/clone-app https://example.com
/clone-app "TodoMVC app"
```

## What This Command Does

1. **Discover** - Navigate the target app and document what it does
2. **Decompose** - Break it into demoable vertical features (prefer L; avoid layer rows)
3. **Sequence** - Order by time-to-aha, then dependencies (core loop before auth)
4. **Document** - Create vision.md and populate roadmap.md

---

## Step 1: Discovery

Use the browser MCP to explore the app:

```
1. Navigate to the URL
2. Take screenshot of main screens
3. Document:
   - What the app does (purpose)
   - Who it's for (target users)
   - The core loop / aha moment (what makes someone say "this is useful")
   - Main screens/areas
   - Key interactions
   - Auth flow (if any) — note it, but do not assume it comes first in the roadmap
   - Data displayed
```

### Discovery Checklist

- [ ] Landing/home page
- [ ] Core loop (the primary create → view / act flow) — find this before deep-diving auth
- [ ] Sign up / login flow (document; usually defer in roadmap)
- [ ] Main dashboard or list view
- [ ] Detail views
- [ ] Create/edit forms
- [ ] Settings/profile
- [ ] Any unique features

### Browser Navigation Pattern

```
CallMcpTool("cursor-browser-extension", "browser_navigate", {
  url: "<target-url>"
})

CallMcpTool("cursor-browser-extension", "browser_snapshot", {})

// Navigate to different areas
CallMcpTool("cursor-browser-extension", "browser_click", {
  selector: "<button or link>"
})
```

---

## Step 2: Create Vision

Update `.specs/vision.md` with discovered information:

```markdown
# App Vision

> [One line description]

## Overview

[What the app does and why]

**Target users**: [Who uses it]
**Core value proposition**: [Problem it solves]
**Core loop / aha**: [The smallest path to "this is useful"]

## Key Screens / Areas

| Screen | Purpose | Priority |
|--------|---------|----------|
| Landing | Marketing, signup CTA | Secondary (unless landing IS the product) |
| [Core loop screen] | Primary user value | Core |
| Settings | User preferences | Secondary |

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | [Detected or planned] |
| ... | ... |

## Design Principles

1. [Key principle 1]
2. [Key principle 2]

## Reference

**Source app**: [URL]
**Analysis date**: [Today's date]
```

---

## Step 3: Decompose into Features

Break the app into roadmap rows that are **prefix-demoable**: after any completed row, someone can stop and use a coherent product (incomplete is fine; broken or "schema only" is not).

### Sizing (Critical!)

Prefer **Large (L) verticals** as the default roadmap row. Ralph pays a fixed tax per row (spec, worktree, verify, drift, compound) — atomizing greenfield into tiny rows makes that tax dominate.

| Size | When to use | Rough scope |
|------|-------------|-------------|
| **L** (default) | A full user-demoable vertical | Often ~7–15 files; fuse scaffold + store + first CRUD when it's the first row |
| **M** | A clear vertical that doesn't need to be huge | ~3–7 files |
| **S** | Polish, bugs, small additive UX — **not** bootstrap | ~1–3 files |

**Hard rules:**

1. **Vertical, not horizontal.** Every row must be independently demoable — a screen, flow, or endpoint someone can click or curl. Never create layer rows like "Project setup", "Database models", "design tokens", "service layer", or "API endpoints". Fold layers into the user-facing feature they serve. Sub-steps belong in the feature spec's `### Implementation Slices`, not on the roadmap.
2. **One row = one aha (or one coherent capability).** Prefer "App spine + store + log/list items" over separate setup / store / one-tool rows. Prefer "MCP logging surface" over one row per tool.
3. **Target ~10–15 features** for a typical cloned app (not 25–40). If you have more, merge rows that aren't separately demoable.
4. **Split only when** a row would exceed one agent context *and* the pieces are each demoable alone. File count is a soft ceiling, not an automatic splitter. "Scary" is not a reason to atomize.
5. **Phases are chapter titles, not execution units.** Ralph builds rows. A phase may contain several `--full` units — each must be its own roadmap row.

### Feature Decomposition Pattern

```
❌ Too atomized / layer-shaped:
  - Project setup
  - SQLite store
  - Auth: Signup
  - Auth: Login
  - Auth: Session
  - MCP: log_diaper
  - MCP: list_diapers

✅ Demoable verticals (greenfield / clone):
  - App spine + local store + log/list diapers (L)  ← first demo; includes ownership stub
  - MCP logging surface (L)
  - Voice parse + confirm (L)
  - Companion timeline (L)
  - Auth: signup + login + session (M)             ← after core loop proves value
```

### Ownership without early Auth

Defer **auth product** (signup/login screens, OAuth, invites) until after the core loop is demoable — unless auth *is* the product (SSO/permissions/multi-tenant are the aha) or strategy demands enterprise onboarding first.

Do **not** defer **ownership in the data model**. The first domain feature should include a thin identity stub:

- A `user_id` / `owner_id` (or equivalent) on domain records from day one
- Queries scoped by that id
- A hardcoded/local current user is fine until real auth lands

Then "add auth later" is mostly session + guards, not a rewrite.

### Identify Dependencies

Features should list what must be built first. Prefer a shallow chain: core loop unlocks most later rows; avoid serializing everything behind auth.

```
Feature: Companion timeline
Deps: 1  (requires the first log/list vertical — NOT auth)
```

---

## Step 4: Sequence into Phases

Sequence by **time-to-aha**, then dependencies — not by "what a mature SaaS has in its nav."

### Phase 1: Core loop / time-to-aha
- First row = scaffold fused into the first demoable vertical (not a separate setup row)
- Primary create → view / act path
- No auth unless auth is the aha

### Phase 2: Expand the loop
- Adjacent capabilities that deepen the same value
- Secondary screens that still demo alone

### Phase 3: Accounts, polish, scale
- Auth / sync / multi-user (when needed)
- Nice-to-haves, performance, keyboard shortcuts

If `.specs/strategy.md` exists, phase names and order should follow buying motion (PLG → time-to-aha first; enterprise → onboarding/auth may come earlier).

---

## Step 5: Populate Roadmap

Update `.specs/roadmap.md` with the feature list. Reuse the same structure and Implementation Rules as `/roadmap`. Example:

```markdown
## Phase 1: Core loop

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 1 | App spine + store + task inbox (create/complete) | clone-app | - | L | - | ⬜ |
| 2 | Projects + filters on the inbox | clone-app | - | L | 1 | ⬜ |

## Phase 2: Expand

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 10 | Due dates + priorities | clone-app | - | M | 1 | ⬜ |
| 11 | Search | clone-app | - | M | 1 | ⬜ |

## Phase 3: Accounts & polish

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 20 | Auth: signup + login + session | clone-app | - | M | 1 | ⬜ |
```

### Jira Integration (Optional)

If `CREATE_JIRA_FOR_ROADMAP=true` in `.env.local`:

For each feature, create a Jira ticket:

```
CallMcpTool("user-atlassian", "createJiraIssue", {
  cloudId: "[from .env.local or getAccessibleAtlassianResources]",
  projectKey: "[JIRA_PROJECT_KEY from .env.local]",
  issueTypeName: "Story",
  summary: "[Feature name]",
  description: "Source: /clone-app\nPhase: [phase]\nDependencies: [deps]"
})
```

Update roadmap with Jira ticket key.

---

## Step 6: Update Progress Summary

Update the Progress section in roadmap.md:

```markdown
## Progress

| Status | Count |
|--------|-------|
| ✅ Completed | 0 |
| 🔄 In Progress | 0 |
| ⬜ Pending | [total count] |
| ⏸️ Blocked | 0 |

**Last updated**: [current date/time]
```

---

## Output

After running `/clone-app`:

1. `.specs/vision.md` - Filled with app description
2. `.specs/roadmap.md` - Populated with sequenced features
3. (Optional) Jira tickets created for each feature

Before finishing, self-check the roadmap:

- [ ] No layer rows (setup / schema / tokens / "API for X")
- [ ] ~10–15 features for a typical app (merge if bloated)
- [ ] Row #1 is demoable without auth (unless auth is the product)
- [ ] Auth is not Phase 1 unless strategy/aha requires it
- [ ] First domain feature mentions ownership stub (`user_id` / scoped queries)
- [ ] Every row is something you could stop on and show someone

---

## Next Steps

After `/clone-app` completes, tell the user:

```
✅ Clone complete!

Created:
- .specs/vision.md (app vision)
- .specs/roadmap.md ([N] features across [M] phases)

Next steps:
1. Review vision.md - does it capture the app correctly?
2. Review roadmap.md - is each row demoable? Is auth deferred past the core loop?
3. Run /build-next to start building!

Or run overnight-autonomous.sh to build features while you sleep.
```

---

## Example Session

```
User: /clone-app https://todoist.com

Agent:
1. Navigates to todoist.com
2. Finds core loop: add task → see it in inbox → complete it (aha before accounts)
3. Documents findings in vision.md (including core loop)
4. Decomposes into ~12 L/M verticals (not 25 atomized rows)
5. Sequences: inbox loop → projects/filters → dates/priorities → auth → polish
6. Populates roadmap.md

Output:
✅ Clone complete!

Created:
- .specs/vision.md (Todoist - task management app)
- .specs/roadmap.md (12 features across 3 phases)

Phase 1: Core loop (3 features)
  - App spine + store + task inbox, Projects + list switcher, Quick add + complete

Phase 2: Expand (5 features)
  - Due dates, Priorities, Labels, Filters, Search

Phase 3: Accounts & polish (4 features)
  - Auth: signup + login + session, Keyboard shortcuts, Drag-drop reorder, Mobile polish

Ready to build? Run /build-next to start with feature #1.
```
