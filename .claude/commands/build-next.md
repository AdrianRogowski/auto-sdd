# Build Next

Pick the next pending feature from the roadmap and build it through the full TDD cycle.

## Usage

```
/build-next
/build-next --skip-jira
```

---

## What This Command Does

1. **Select** - Find the next buildable feature (pending, dependencies met)
2. **Spec** - Create feature spec with `/spec-first --full`
3. **Build** - Implement through TDD cycle (includes self-check drift)
4. **Update** - Mark roadmap as complete, sync Jira
5. **Drift Check** - Build loop runs a fresh agent to verify spec↔code alignment
6. **PR** - Create PR (if in overnight mode)

---

## Step 1: Read the Roadmap

Read `.specs/roadmap.md` and `.specs/vision.md` to understand:
- What's been built (✅)
- What's in progress (🔄) - should only be one
- What's pending (⬜)
- What's blocked (⏸️)

---

## Step 2: Select Next Feature

Find the first feature where:
1. Status is ⬜ (pending)
2. All dependencies are ✅ (completed)

### Selection Logic

```
for each phase in order:
  for each feature in phase:
    if feature.status == ⬜:
      if all(dep.status == ✅ for dep in feature.deps):
        return feature
        
return null  // Nothing ready to build
```

### If Nothing is Ready

If no features are ready:
- Check if there are ⏸️ blocked items and report why
- Check if all features are ✅ complete
- Report status to user

---

## Step 3: Load Context

Before building, load relevant context:

### Read Vision
```
Read .specs/vision.md for:
- App purpose
- Tech stack
- Design principles
```

### Read Related Specs
```
For each completed dependency:
  Read .specs/features/{domain}/{feature}.feature.md
  Note: patterns used, components created, API shape
```

### Read Learnings
```
Read .specs/learnings/index.md for relevant cross-cutting patterns
```

---

## Step 4: Update Roadmap Status

Mark the feature as in-progress:

```markdown
| 5 | Dashboard | clone-app | PROJ-105 | L | 1,2 | 🔄 |
```

Commit: `chore: start feature #5 - Dashboard`

---

## Step 5: Sync Jira (if configured)

If the feature has a Jira ticket and Jira integration is enabled:
- Transition issue to "In Progress"
- Use available Jira MCP tools

---

## Step 6: Run /spec-first --full

Execute the full TDD cycle for this feature:

```
/spec-first {feature name} --full
```

The `--full` flag means:
- Create spec (no pause)
- Write tests (no pause)
- Implement until tests pass
- Commit changes

### Spec Location

Place spec at: `.specs/features/{domain}/{feature-slug}.feature.md`

Where:
- `domain` = derived from feature name (e.g., "Auth: Signup" → "auth")
- `feature-slug` = kebab-case (e.g., "auth-signup")

---

## Step 7: Update Roadmap and Mapping on Completion

After `/spec-first --full` completes:

```markdown
| 5 | Dashboard | clone-app | PROJ-105 | L | 1,2 | ✅ |
```

Update the Progress section:
```markdown
## Progress

| Status | Count |
|--------|-------|
| ✅ Completed | [+1] |
| 🔄 In Progress | 0 |
| ⬜ Pending | [-1] |
| ⏸️ Blocked | 0 |

**Last updated**: [current timestamp]
```

Regenerate the mapping file:
```bash
./scripts/generate-mapping.sh
```

Commit: `chore: complete feature #5 - Dashboard`

---

## Step 8: Sync Jira on Completion

If feature has Jira ticket:
- Transition to Done (or "Ready for Review")
- Add comment with PR link

---

## Step 9: Mark Source Complete (Slack)

If feature source is Slack (`slack:CHANNEL/TIMESTAMP`):
- Reply to thread confirming completion
- Include PR link

---

## Step 10: Create PR (Overnight Mode)

If running in overnight/automated mode, create a draft PR:

```bash
git checkout -b feature/{feature-slug}
git push -u origin HEAD
gh pr create --draft --title "feat: {feature name}" --body "..."
```

---

## Step 11: Learnings (handled by /spec-first --full)

Note: `/spec-first --full` already runs `/compound` at the end of implementation.
No additional action needed here - learnings are already extracted.

---

## Step 12: Report Status

### Required Output Signals

You MUST output these signals at the end (each on its own line):

```
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to .feature.md file}
SOURCE_FILES: {comma-separated source file paths}
```

These are parsed by the build loop to run automated drift-checking.

### If Feature Built Successfully

```
✅ Feature #5 built: Dashboard

Spec: .specs/features/dashboard/dashboard.feature.md
Tests: [list of test files]
Components: [list of components]
Jira: PROJ-105 → Done

Roadmap progress: 5/18 features (28%)

FEATURE_BUILT: Dashboard
SPEC_FILE: .specs/features/dashboard/dashboard.feature.md
SOURCE_FILES: app/(protected)/dashboard/page.tsx, components/dashboard-stats.tsx

Run /build-next again to continue, or wait for overnight automation.
```

### If Build Failed

```
⚠️ Feature #5 partially built: Dashboard

Status: Tests failing / Implementation incomplete
Reason: [describe issue]

Roadmap: Feature marked as 🔄 (in progress)
Jira: PROJ-105 → still In Progress

Manual intervention needed. Run /build-next after fixing.
```

### If No Features Ready

```
📋 Roadmap Status

✅ Completed: 18/18 features (100%)

All features have been built! 🎉

Or:

⏸️ Blocked: 3 features waiting on:
- #7 requires #6 (in progress)
- #8 requires #7
- #9 requires external API decision

Run /build-next after #6 completes.
```

---

## Overnight Automation

When called from `overnight-autonomous.sh`, `/build-next`:
- Runs in non-interactive mode
- Creates draft PRs automatically
- Continues to next feature up to MAX_FEATURES
- Reports summary at end

---

## Configuration

In `.env.local`:

```bash
# Jira sync
SYNC_JIRA_STATUS=true
JIRA_CLOUD_ID="yoursite.atlassian.net"
JIRA_PROJECT_KEY="PROJ"

# Slack notifications
SLACK_NOTIFY_COMPLETE=true

# PR creation (for automated runs)
CREATE_PR_ON_COMPLETE=true
```

---

## Example Session

```
User: /build-next

Agent:
1. Reads roadmap.md - finds feature #5 "Dashboard" is next
2. Checks deps: #1 Auth ✅, #2 Login ✅ - ready to build
3. Reads vision.md for context
4. Reads completed specs for auth patterns
5. Updates roadmap: #5 → 🔄
6. Syncs Jira: PROJ-105 → In Progress
7. Runs /spec-first Dashboard --full
   - Creates spec
   - Writes tests
   - Implements
   - Self-checks drift (Layer 1)
   - Tests pass
   - Extracts learnings (/compound)
8. Updates roadmap: #5 → ✅
9. Syncs Jira: PROJ-105 → Done + comment
10. Reports success with signals
11. Build loop runs fresh-agent drift check (Layer 2)

✅ Feature #5 built: Dashboard
Roadmap progress: 5/18 (28%)

FEATURE_BUILT: Dashboard
SPEC_FILE: .specs/features/dashboard/dashboard.feature.md
SOURCE_FILES: app/(protected)/dashboard/page.tsx, components/dashboard-stats.tsx
```
