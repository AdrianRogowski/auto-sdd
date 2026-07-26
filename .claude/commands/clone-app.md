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
2. **Decompose** - Break it into right-sized features (each fits in one agent context)
3. **Sequence** - Order features respecting dependencies
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
   - Main screens/areas
   - Key interactions
   - Auth flow (if any)
   - Data displayed
```

### Discovery Checklist

- [ ] Landing/home page
- [ ] Sign up / login flow
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

## Key Screens / Areas

| Screen | Purpose | Priority |
|--------|---------|----------|
| Landing | Marketing, signup CTA | Core |
| Dashboard | Main user view | Core |
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

Break the app into features that are:

### Right-Sized (Critical!)

Each feature must be completable in ONE agent context window:
- **Small (S)**: 1-3 files, single component
- **Medium (M)**: 3-7 files, multiple components
- **Large (L)**: 7-15 files, full feature with tests

If a feature seems larger than L, break it down further!

### Feature Decomposition Pattern

```
Auth System (too big!)
  ↓ Break down into:
  - Auth: Signup form (M)
  - Auth: Login form (M)
  - Auth: Session management (M)
  - Auth: Password reset (M)
  - Auth: Protected routes (S)
```

### Identify Dependencies

Features should list what must be built first:

```
Feature: Dashboard
Deps: 1, 2  (requires Auth: Signup and Auth: Login)
```

---

## Step 4: Sequence into Phases

Organize features into logical phases:

### Phase 1: Foundation
- Project setup
- Core layout/navigation
- Auth (if needed)
- Database models

### Phase 2: Core Features
- Primary user functionality
- Main screens

### Phase 3: Enhancement
- Secondary features
- Polish
- Performance

---

## Step 5: Populate Roadmap

Update `.specs/roadmap.md` with the feature list:

```markdown
## Phase 1: Foundation

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| 1 | Project setup | clone-app | - | S | - | ⬜ |
| 2 | Auth: Signup | clone-app | - | M | 1 | ⬜ |
| 3 | Auth: Login | clone-app | - | M | 1 | ⬜ |
| 4 | Auth: Session | clone-app | - | M | 2,3 | ⬜ |
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
2. Review roadmap.md - is the sequence logical?
3. Run /build-next to start building!

Or run overnight-autonomous.sh to build features while you sleep.
```

---

## Example Session

```
User: /clone-app https://todoist.com

Agent:
1. Navigates to todoist.com
2. Explores: landing, signup, login, task list, task detail, projects, labels, filters
3. Documents findings in vision.md
4. Decomposes into ~15-20 features
5. Sequences by dependency
6. Populates roadmap.md

Output:
✅ Clone complete!

Created:
- .specs/vision.md (Todoist - task management app)
- .specs/roadmap.md (18 features across 3 phases)

Phase 1: Foundation (5 features)
  - Project setup, Auth, Core layout, Task model, List component

Phase 2: Core (8 features)  
  - Task CRUD, Projects, Labels, Filters, Due dates, Priorities, Search

Phase 3: Enhancement (5 features)
  - Keyboard shortcuts, Drag-drop, Dark mode, Mobile responsive, Performance

Ready to build? Run /build-next to start with feature #1.
```
