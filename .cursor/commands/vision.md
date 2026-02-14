# Vision

Create or update the project's vision document (`.specs/vision.md`).

## Usage

```
/vision                              # Interactive — detect mode, ask questions
/vision "CRM for real estate brokers" # Create from description
/vision --update                     # Update existing vision with current state
/vision --from-jira PROJ             # Seed from Jira project epics
/vision --from-confluence PAGE_ID    # Seed from Confluence page
```

---

## What This Command Does

1. **Detect** - Check if `.specs/vision.md` already exists and has content
2. **Gather** - Collect information from user description, codebase, Jira, Confluence, or conversation
3. **Draft** - Write or update `.specs/vision.md`
4. **Review** - Present the vision for user approval before committing

---

## Mode Detection

| Condition | Mode |
|-----------|------|
| No vision.md or only template scaffolding | **Create** - build from scratch |
| Vision.md has real content | **Update** - revise existing |
| `--from-jira` flag | **Import** - seed from Jira project |
| `--from-confluence` flag | **Import** - seed from Confluence page |

---

## Create Mode

### If user provided a description

Use the description directly. Example:
```
/vision "A deal management platform for commercial real estate brokers. 
Tracks leads, prospects, contacts, and deals. Integrates with CompStak 
for market data and provides AI-powered deal intelligence."
```

### If no description provided

Ask the user these questions (all at once, not one by one):

```
To create your vision doc, I need to understand:

1. **What does this app do?** (one paragraph)
2. **Who is it for?** (target users)
3. **What problem does it solve?** (core value proposition)
4. **What are the main screens/areas?** (e.g., Dashboard, Settings, List view)
5. **What tech stack?** (or should I detect from the codebase?)
6. **Any design principles?** (e.g., mobile-first, accessible, fast)
```

### If there's an existing codebase

Scan the project to detect:
- **Tech stack**: Check `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, etc.
- **Screens/routes**: Check route files, page directories (`app/`, `pages/`, `src/routes/`)
- **Data models**: Check schema files (`prisma/schema.prisma`, `models/`, etc.)
- **Existing features**: Check component directories, API routes

Combine detected info with user description.

---

## Import Mode: Jira

If `--from-jira PROJECT_KEY` is provided:

### Step 1: Get project info
```
CallMcpTool("user-atlassian", "getVisibleJiraProjects", {
  cloudId: "[from config]",
  searchString: "[PROJECT_KEY]"
})
```

### Step 2: Get epics
```
CallMcpTool("user-atlassian", "searchJiraIssuesUsingJql", {
  cloudId: "[from config]",
  jql: "project = [PROJECT_KEY] AND issuetype = Epic ORDER BY rank ASC",
  fields: ["summary", "description", "status", "priority"]
})
```

### Step 3: Map to vision
- Project description → Overview
- Epics → Key Screens / Areas
- Epic priorities → Screen priorities

---

## Import Mode: Confluence

If `--from-confluence PAGE_ID` is provided:

### Step 1: Fetch page
```
CallMcpTool("user-atlassian", "getConfluencePage", {
  cloudId: "[from config]",
  pageId: "[PAGE_ID]",
  contentFormat: "markdown"
})
```

### Step 2: Extract structure
Parse the page content for:
- Product description / overview sections
- User persona / target audience sections
- Feature lists or requirements
- Technical requirements
- Design guidelines

### Step 3: Map to vision format
Transform extracted content into the vision.md structure.

---

## Update Mode

When vision.md already exists and has content:

### Step 1: Read current state

Read these files to understand what's changed:
- `.specs/vision.md` (current vision)
- `.specs/roadmap.md` (what's been built, what's planned)
- `.specs/learnings/index.md` (recent learnings)
- `.specs/mapping.md` (feature inventory)

### Step 2: Identify drift

Compare vision against reality:
- **Screens that exist but aren't in vision** — add them
- **Screens in vision that were never built** — flag for removal or keep as aspirational
- **Tech stack changes** — update if new tools were adopted
- **Design principles that evolved** — update based on learnings
- **New problems discovered** — add to a "Current Problems" section if relevant
- **Scope changes** — update "Out of Scope" section

### Step 3: Ask user what to update

```
Here's what I found:

**Already accurate:**
- Overview, target users, core value prop ✅
- Tech stack ✅

**Needs updating:**
- Key Screens: 3 new screens built that aren't documented
- Design Principles: learnings suggest adding "sharp corners, no rounded UI"
- Out of Scope: mobile app is no longer out of scope (Phase 6 plans it)

**Suggested additions:**
- "Current Problems" section based on roadmap notes
- "Future Direction" section based on later phases

Should I apply all updates, or do you want to pick which ones?
```

### Step 4: Apply updates

Update vision.md with approved changes. Preserve user's existing prose — don't rewrite sections that are still accurate.

---

## Vision Document Structure

The output follows this format:

```markdown
# App Vision

> [One-line description of what the app does]

---

## Overview

[One paragraph describing the app's purpose, what makes it unique, 
and the core workflow.]

**Target users**: [Who uses this]

**Core value proposition**: [The key problem it solves]

---

## Key Screens / Areas

| Screen | Purpose | Priority |
|--------|---------|----------|
| Dashboard | Command center — stats, news, activity | Core |
| Leads | Browse and prospect deal intelligence leads | Core |
| Contacts | Manage CRM contacts and relationships | Core |
| Settings | User preferences and integrations | Secondary |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Next.js 14 (App Router) |
| Styling | Tailwind CSS + shadcn/ui |
| Backend | Next.js API routes |
| Database | PostgreSQL via Prisma |
| Auth | NextAuth.js |
| Hosting | Vercel |

---

## Design Principles

1. Professional and clean — match the add-contact dialog aesthetic
2. Data-dense but not cluttered — brokers need information at a glance
3. Real data only — no mock data, no placeholder content
4. Mobile-responsive — works on phone and tablet

---

## Out of Scope (for now)

- Native mobile apps
- Multi-tenant / team features
- Public-facing pages

---

## Reference

**Created**: [date]
**Last updated**: [date]
**Source**: [user description / clone-app / jira / confluence]
```

---

## Pause and Review

After drafting, **always** show the vision to the user:

```
Here's the draft vision:

[show full vision.md content]

---

Does this capture it correctly? I can:
- Add/remove screens
- Adjust the tech stack
- Refine the design principles
- Add a "Current Problems" or "Future Direction" section

Once approved, I'll save to .specs/vision.md.
```

Wait for approval before writing the file.

---

## After Saving

```
✅ Vision saved to .specs/vision.md

Next steps:
- Run /roadmap to create a build plan from this vision
- Run /spec-first to start building a specific feature
- Run /clone-app <url> if you want to also reference an existing app
```

---

## Example Sessions

### From scratch
```
User: /vision "A task management app for small teams"

Agent:
1. Asks clarifying questions about screens, tech stack, principles
2. Scans codebase for existing tech (finds Next.js, Prisma)
3. Drafts vision.md
4. Shows draft for approval
5. Saves on approval
```

### From Jira
```
User: /vision --from-jira DEAL

Agent:
1. Fetches DEAL project from Jira
2. Reads all epics and their descriptions
3. Maps epics to screens/areas
4. Drafts vision.md
5. Shows draft for approval
6. Saves on approval
```

### Update existing
```
User: /vision --update

Agent:
1. Reads current vision.md
2. Reads roadmap (sees 24 features completed)
3. Reads learnings (finds design pattern changes)
4. Shows what's accurate and what needs updating
5. Asks which updates to apply
6. Updates vision.md with approved changes
```
