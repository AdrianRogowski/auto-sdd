---
description: Create or update the project's vision document (.specs/vision.md)
---

Create or update the vision for: $ARGUMENTS

## Mode Detection

| Condition | Mode |
|-----------|------|
| No vision.md or only template scaffolding | **Create** — build from scratch |
| Vision.md has real content | **Update** — revise existing |
| `--from-jira PROJECT_KEY` flag | **Import** — seed from Jira project |
| `--from-confluence PAGE_ID` flag | **Import** — seed from Confluence page |
| `--update` flag | **Update** — force update mode |

## Instructions

### Create Mode

1. **Gather information** from the user's description (`$ARGUMENTS`), or ask:
   - What does the app do? Who is it for? What problem does it solve?
   - Main screens/areas? Tech stack? Design principles?
2. **Scan the codebase** (if existing project) to detect tech stack, routes, schema, components
3. **Draft vision.md** following the standard structure:
   - Overview, target users, value proposition
   - Key Screens table (Screen, Purpose, Priority)
   - Tech Stack table
   - Design Principles (numbered list)
   - Out of Scope section
4. **Show draft** and wait for approval before saving

### Import Mode (Jira)

1. Fetch project info and epics from Jira
2. Map epics to Key Screens / Areas
3. Map project description to Overview
4. Draft vision.md and show for approval

### Import Mode (Confluence)

1. Fetch page content in markdown
2. Extract product description, user personas, feature lists, technical requirements
3. Transform into vision.md structure
4. Show draft and wait for approval

### Update Mode

1. Read current `.specs/vision.md`
2. Read `.specs/roadmap.md`, `.specs/learnings/index.md`, `.specs/mapping.md`
3. Identify drift: new screens not in vision, tech stack changes, evolved principles, scope changes
4. Present findings: what's accurate, what needs updating, suggested additions
5. Ask which updates to apply
6. Update vision.md preserving accurate existing prose

## After Saving

Report:
```
✅ Vision saved to .specs/vision.md

Next steps:
- Run /roadmap to create a build plan from this vision
- Run /spec-first to start building a specific feature
```
