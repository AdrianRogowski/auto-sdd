# Roadmap

Create, update, or restructure the project's build roadmap (`.specs/roadmap.md`).

## Usage

```
/roadmap                               # Interactive — detect mode
/roadmap create                        # Create roadmap from vision.md
/roadmap add "email integration"       # Add a feature or phase
/roadmap reprioritize                  # Restructure based on current state
/roadmap status                        # Show progress summary
/roadmap --from-jira PROJ             # Seed from Jira project
/roadmap --from-confluence PAGE_ID    # Seed from Confluence page
```

---

## What This Command Does

1. **Detect** - Check if roadmap.md exists and what mode to use
2. **Gather** - Collect features from vision, user input, Jira, or Confluence
3. **Organize** - Sequence into phases with dependencies and complexity estimates
4. **Write** - Create or update `.specs/roadmap.md`
5. **Review** - Present for user approval

---

## Mode Detection

| Condition | Mode | Behavior |
|-----------|------|----------|
| No roadmap.md or only template | **Create** | Build from vision + user input |
| `create` subcommand | **Create** | Force fresh roadmap |
| `add` subcommand | **Add** | Add features to existing roadmap |
| `reprioritize` subcommand | **Reprioritize** | Restructure existing roadmap |
| `status` subcommand | **Status** | Report progress only |
| `--from-jira` flag | **Import** | Seed from Jira project |
| `--from-confluence` flag | **Import** | Seed from Confluence page |
| No subcommand, roadmap exists | **Interactive** | Ask what user wants to do |

---

## Create Mode

### Step 1: Read the Vision

Read `.specs/vision.md` for:
- App overview and purpose
- Key screens / areas
- Tech stack
- Design principles

If no vision.md exists:
```
No vision.md found. Run /vision first to define what you're building,
or describe the features you want and I'll create the roadmap directly.
```

If the user provides features inline, proceed without vision.md.

### Step 2: Scan the Codebase (if existing project)

Check what already exists:
- Route files → existing screens
- API routes → existing endpoints
- Schema → existing data models
- Components → existing UI
- Test files → existing test coverage

Mark discovered features as ✅ (already implemented).

### Step 3: Decompose into Features

Break the app into right-sized features. Each feature must be completable in ONE agent context window:

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| **S** (Small) | 1-3 | Single component, few files | "Add empty state to contacts table" |
| **M** (Medium) | 3-7 | Multiple components, moderate logic | "Auth: Login form with validation" |
| **L** (Large) | 7-15 | Full feature, many files, complex logic | "Email sync with OAuth + threading" |

**If a feature feels bigger than L, break it down further.**

### Step 4: Identify Dependencies

For each feature, note what must be built first:
- Auth features before anything requiring login
- Data models before UI that displays that data
- Core layout before page-specific features
- API endpoints before client-side consumers

### Step 5: Sequence into Phases

Group features into logical phases:

```markdown
## Phase 1: Foundation
> Infrastructure, auth, core layout. Must be built first.

## Phase 2: Core Features  
> Primary user-facing functionality.

## Phase 3: [Domain-specific name]
> [Description of what this phase achieves]

## Phase N: Enhancement
> Polish, performance, secondary features.
```

**Phase naming guidelines:**
- Use descriptive names, not just "Phase N"
- Each phase should have a clear goal (stated in the `>` description)
- Phases should be roughly 4-8 features each
- Features within a phase should be related

### Step 6: Write the Roadmap

Generate `.specs/roadmap.md` following the standard format:

```markdown
# Build Roadmap

> Ordered list of features to implement. Each feature should be completable within a single agent context window.
> Updated by `/clone-app`, `/vision`, `/roadmap`, `/roadmap-triage`, and `/build-next`.

## Implementation Rules

**Every feature in this roadmap must be implemented with real data, real API calls, and real database operations.** No exceptions.

- **No mock data** — never use hardcoded arrays, fake JSON, or placeholder content to simulate functionality.
- **No fake API endpoints** — every endpoint must do real work. No routes that return static JSON.
- **No placeholder UI** — components must be wired to real data sources. Show proper empty states, not fake data.
- **No "demo mode"** — features either work end-to-end or they aren't done.
- **Real validation** — forms validate against real constraints.
- **Real error handling** — API failures, empty results, rate limits, and edge cases must be handled.
- **Test against real flows** — when verifying a feature, use the app as a user would.

---

## Progress

| Status | Count |
|--------|-------|
| ✅ Completed | 0 |
| 🔄 In Progress | 0 |
| ⬜ Pending | [count] |
| ⏸️ Blocked | 0 |

**Last updated**: [today's date]

---

## Phase 1: [Name]

> [Phase goal]

| # | Feature | Source | Complexity | Deps | Status |
|---|---------|--------|------------|------|--------|
| 1 | [Feature name] | [source] | [S/M/L] | - | ⬜ |
```

### Feature numbering:
- Phase 1: #1-9
- Phase 2: #10-19
- Phase 3: #20-29
- Phase N: #(N*10) - #(N*10+9)
- Ad-hoc: #100+

---

## Add Mode

When user runs `/roadmap add "feature description"`:

### Step 1: Read existing roadmap

Read `.specs/roadmap.md` to understand:
- Current phases and their themes
- Existing feature numbers (to avoid collisions)
- Dependencies graph
- Which features are completed

### Step 2: Classify the new feature(s)

For each feature the user describes:

1. **Estimate complexity** (S/M/L)
2. **Identify dependencies** on existing features
3. **Determine placement**:
   - Fits an existing phase? → Add there
   - New domain? → Create a new phase
   - One-off request? → Add to Ad-hoc Requests
4. **Assign feature number** based on phase

### Step 3: If it's a large feature, break it down

```
"Email integration" is too big for a single feature. Breaking down:

| # | Feature | Complexity | Deps |
|---|---------|------------|------|
| 30 | Gmail/Outlook OAuth connection | L | - |
| 31 | Email sync and contact matching | L | 30 |
| 32 | Email on contact records | M | 31 |
| 33 | Email in activity feed | M | 31 |

Add these as a new Phase 4: Email Integration?
```

### Step 4: Show diff and confirm

```
I'll add to roadmap.md:

## Phase 4: Email Integration (NEW)

| # | Feature | Source | Complexity | Deps | Status |
|---|---------|--------|------------|------|--------|
| 30 | Gmail/Outlook OAuth | user | L | - | ⬜ |
| 31 | Email sync | user | L | 30 | ⬜ |
| 32 | Email on contacts | user | M | 31 | ⬜ |
| 33 | Email in activity feed | user | M | 31 | ⬜ |

Progress updated: ⬜ Pending 12 → 16

Apply?
```

---

## Reprioritize Mode

When user runs `/roadmap reprioritize`:

### Step 1: Assess current state

Read:
- `.specs/roadmap.md` — what's done, what's planned
- `.specs/vision.md` — original goals
- `.specs/learnings/index.md` — what we've learned
- `.specs/mapping.md` — feature completion inventory

### Step 2: Analyze

Present findings:

```
## Current Roadmap Analysis

### What's done
- Phase 1 (Foundation): 6/6 ✅
- Phase 2 (UI Overhaul): 6/6 ✅
- Phase 3 (News): 4/4 ✅
Total: 16/28 features (57%)

### What's next in current order
- Phase 4 features 30-33 (Email Integration)

### Observations
- Phase 6 (Mobile) and Phase 7 (Dashboard) have no cross-deps — could run in parallel
- Feature #50 (Deep linking) is a dependency for 3 features in later phases — consider pulling it earlier
- Phase 9 (Email Cadences) depends heavily on Phase 4 — can't be parallelized
- Based on learnings, the skills refactor (#70) is more complex than estimated

### Questions
1. Has the priority of any phase changed?
2. Are there new features to add?
3. Should any features be cancelled or descoped?
4. Should any phases be reordered?
```

### Step 3: Restructure based on feedback

Apply user's decisions:
- Reorder phases
- Move features between phases
- Cancel features (mark ❌)
- Add new features
- Adjust dependencies
- Re-estimate complexity

### Step 4: Show diff and confirm

Show the before/after of the roadmap structure. Highlight:
- Moved features
- New features
- Cancelled features
- Reordered phases

---

## Status Mode

When user runs `/roadmap status`:

```
## Roadmap Progress

| Phase | Name | Done | Total | Status |
|-------|------|------|-------|--------|
| 1 | Foundation | 6 | 6 | ✅ Complete |
| 2 | UI Overhaul | 6 | 6 | ✅ Complete |
| 3 | News & Alerts | 4 | 4 | ✅ Complete |
| 4 | Email Integration | 2 | 4 | 🔄 In Progress |
| 5 | AI Platform | 0 | 4 | ⬜ Pending |
| 6 | Mobile & Deep Linking | 0 | 5 | ⬜ Pending |

**Overall**: 18/29 features (62%)

**Next up**: Feature #32 "Email on contact records" (M, deps: #31 ✅)

**Blocked**: None

**Time estimate**: ~11 features remaining
- 3 Small, 5 Medium, 3 Large
- Estimated: 2-3 /build-next sessions per phase

Run /build-next to continue building.
```

No file changes in status mode — read-only report.

---

## Import Mode: Jira

If `--from-jira PROJECT_KEY` is provided:

### Step 1: Get epics and stories
```
Search for epics in the project, then get stories under each epic.
Map:
- Epics → Phases
- Stories → Features
- Story points / priority → Complexity estimates
- Epic links → Dependencies
```

### Step 2: Generate roadmap

Transform Jira structure into roadmap format:
- Epic name → Phase name
- Epic description → Phase description
- Story summary → Feature name
- Story priority → helps determine order within phase
- Jira key → Source column (`jira:PROJ-123`)

### Step 3: Review and adjust

Present the generated roadmap. Ask:
- Are the phases in the right order?
- Any features missing that aren't in Jira?
- Any Jira tickets that shouldn't be in the roadmap?

---

## Import Mode: Confluence

If `--from-confluence PAGE_ID` is provided:

### Step 1: Fetch page content

Read the Confluence page and any child pages.

### Step 2: Extract features

Parse for:
- Numbered lists of features/requirements
- Tables with feature descriptions
- Headings that map to phases
- Priority indicators

### Step 3: Generate roadmap

Transform into roadmap format and present for review.

---

## Pause and Review

**Always** show the roadmap to the user before writing:

```
Here's the roadmap:

[show roadmap content]

---

Does this look right? I can:
- Reorder phases
- Add/remove features
- Adjust complexity estimates
- Change dependencies
- Create new phases

Once approved, I'll save to .specs/roadmap.md.
```

Wait for approval before writing the file.

---

## After Saving

```
✅ Roadmap saved to .specs/roadmap.md

[N] features across [M] phases:
- Phase 1: [name] ([count] features)
- Phase 2: [name] ([count] features)
...

Next steps:
- Run /build-next to start building feature #1
- Run /roadmap add to add more features later
- Run /roadmap-triage to pull in Slack/Jira requests
```

---

## Notes Section

When creating a roadmap, include a Notes section at the bottom with implementation insights:

```markdown
## Notes

### Phase-specific notes
- **Phase 1** should establish patterns that all later phases follow
- **Phase N and Phase M** can run in parallel if no cross-deps exist

### General observations
- [Any important context about dependencies, complexity, or sequencing]
```

This section is critical for `/build-next` — it reads Notes to understand context that isn't captured in the feature table.

---

## Example Sessions

### Create from vision
```
User: /roadmap create

Agent:
1. Reads vision.md
2. Scans codebase for existing features
3. Decomposes into 20 features across 4 phases
4. Shows draft for approval
5. Saves on approval
```

### Add features
```
User: /roadmap add "dark mode and theme customization"

Agent:
1. Reads existing roadmap
2. Breaks into: theme tokens (S), dark mode toggle (M), theme persistence (S)
3. Proposes adding to existing Enhancement phase
4. Shows diff, waits for approval
5. Updates roadmap.md
```

### Reprioritize
```
User: /roadmap reprioritize

Agent:
1. Reads roadmap, vision, learnings
2. Presents analysis: what's done, what's next, observations
3. Asks about priorities
4. Restructures based on feedback
5. Shows diff, waits for approval
6. Updates roadmap.md
```

### Import from Jira
```
User: /roadmap --from-jira DEAL

Agent:
1. Fetches DEAL project epics and stories
2. Maps to phases and features
3. Estimates complexity from story points
4. Shows draft for approval
5. Saves on approval
```
