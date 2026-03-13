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
2. **Spec** - Create or update feature spec
3. **Build** - Implement through TDD cycle (includes self-check drift)
4. **Update** - Mark roadmap as complete, sync Jira
5. **Build Check** - Shell verifies compilation (auto-detected or `BUILD_CHECK_CMD`)
6. **Test Suite** - Shell runs tests (auto-detected or `TEST_CHECK_CMD`) — failures retry the build
7. **Drift Check** - Fresh agent verifies spec↔code alignment, runs tests, iterates until passing
8. **Code Review** - Fresh agent reviews quality, runs tests, iterates until passing (optional)
9. **PR** - Create PR (if in overnight mode)

All agents receive the test command and are told to iterate until tests pass. The retry agent also receives the actual build/test failure output so it knows exactly what to fix.

### Manual vs Automated Flow

- **Manual** (interactive): You run `/spec-first {feature} --full` in one call — spec, tests, implement, compound, commit. Steps 5–8 are run by the build loop scripts when you use them.
- **Automated** (scripts): `build-loop-local.sh` and `overnight-autonomous.sh` use a **two-phase** flow — they do not invoke this command. Phase 1: spec-only (no `--full`). Phase 2: implement from spec. Each phase gets a fresh context window. Why two-phase: spec can be reviewed before implementation; implement phase can retry independently.

---

## Step 1: Read the Roadmap

Read `.specs/roadmap.md` and `.specs/vision.md` to understand:
- What's been built (✅)
- What's in progress (🔄) - should only be one
- What's pending (⬜)
- What's blocked (⏸️)

---

## Step 2: Select Next Feature

**Priority 1**: Resume any feature marked 🔄 (in progress). It was started in a previous run but not finished — pick it up and complete it.

**Priority 2**: If no in-progress feature, find the first feature where:
1. Status is ⬜ (pending)
2. All dependencies are ✅ (completed)

### Selection Logic

```
// Priority 1: Resume in-progress work
for each phase in order:
  for each feature in phase:
    if feature.status == 🔄:
      return feature  // Resume unfinished work

// Priority 2: Start next pending feature
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

### Read Personas
```
Read .specs/personas/*.md for:
- Primary persona: vocabulary, patience level, frustrations, success metric
- Anti-persona: what NOT to build (prevents scope creep)
These drive Gherkin language, flow complexity, and UI labels.
```

### Read Vision
```
Read .specs/vision.md for:
- App purpose
- Tech stack
- Design principles
```

### Read Design System
```
Read .specs/design-system/tokens.md for:
- Personality (Professional/Friendly/Minimal/Bold/Technical)
- Token names and values
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

If the feature has a Jira ticket and `SYNC_JIRA_STATUS=true`:

```
CallMcpTool("user-atlassian", "transitionJiraIssue", {
  cloudId: "[from config]",
  issueIdOrKey: "PROJ-105",
  transition: { id: "[In Progress transition ID]" }
})
```

To find transition IDs:
```
CallMcpTool("user-atlassian", "getTransitionsForJiraIssue", {
  cloudId: "[from config]",
  issueIdOrKey: "PROJ-105"
})
```

---

## Step 6: Run /spec-first --full

Execute the full TDD cycle for this feature:

```
/spec-first {feature name} --full
```

The `--full` flag means:
- Create or update spec (no pause)
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

```
// Transition to Done (or your "Ready for Review" status)
CallMcpTool("user-atlassian", "transitionJiraIssue", {
  cloudId: "[from config]",
  issueIdOrKey: "PROJ-105",
  transition: { id: "[Done transition ID]" }
})

// Add comment with PR link (if PR created)
CallMcpTool("user-atlassian", "addCommentToJiraIssue", {
  cloudId: "[from config]",
  issueIdOrKey: "PROJ-105",
  commentBody: "✅ Implementation complete!\n\nPR: [PR_URL]\nSpec: .specs/features/dashboard/dashboard.feature.md"
})
```

---

## Step 9: Mark Source Complete (Slack)

If feature source is Slack (`slack:CHANNEL/TIMESTAMP`):

```
CallMcpTool("user-slack", "conversations_add_message", {
  channel_id: "[CHANNEL]",
  thread_ts: "[TIMESTAMP]",
  payload: "✅ Done! This feature has been implemented.\n\nPR: [PR_URL]"
})
```

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

When run from the build loop, you MUST output these signals at the end (each on its own line):

```
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to the .feature.md file you created/updated}
SOURCE_FILES: {comma-separated paths to source files created/modified}
```

These are parsed by `build-loop-local.sh` and `overnight-autonomous.sh` to:
1. Know which feature was built
2. Pass exact file paths to the automated drift-check agent

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
SOURCE_FILES: app/(protected)/dashboard/page.tsx, components/dashboard-stats.tsx, hooks/useDashboardData.ts

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

The overnight script (`overnight-autonomous.sh`) follows the same workflow as /build-next: it selects the next feature, creates the spec, implements it, and runs post-build validation (build check, tests, drift check). It does **not** invoke the /build-next command directly — it runs its own spec + implement prompts. When running overnight:
- Non-interactive mode
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

# Post-build validation (used by build-loop-local.sh and overnight-autonomous.sh)
BUILD_CHECK_CMD=""                               # Auto-detected if empty
TEST_CHECK_CMD=""                                # Auto-detected if empty
POST_BUILD_STEPS="test"                          # Default: just tests
# POST_BUILD_STEPS="test,code-review"            # Tests + quality review

# Model selection (per-step, each gets a fresh context window)
# Run `agent --list-models` to see available models
AGENT_MODEL=""                                   # Default for all steps (empty = CLI default)
SPEC_MODEL=""                                    # Spec phase (build-loop, overnight)
BUILD_MODEL=""                                   # Main build agent (/build-next → /spec-first)
RETRY_MODEL=""                                   # Retry agent (fixing failures)
DRIFT_MODEL=""                                   # Catch-drift agent
REVIEW_MODEL=""                                  # Code-review agent
# Example: Opus for building, cheaper model for validation
# BUILD_MODEL="opus-4.6-thinking"
# DRIFT_MODEL="gemini-3-flash"
# REVIEW_MODEL="sonnet-4.5"
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

FEATURE_BUILT: Dashboard
SPEC_FILE: .specs/features/dashboard/dashboard.feature.md
SOURCE_FILES: app/(protected)/dashboard/page.tsx, components/dashboard-stats.tsx

--- Build loop takes over (shell + fresh agents) ---

11. Build check: `npx tsc --noEmit` → ✅
12. Test suite: `npm test` → ✅
13. Drift check (fresh agent):
    - Receives spec file + source files + test command
    - Compares spec vs code, runs tests, iterates until aligned + passing
    - → NO_DRIFT ✅
14. Code review (fresh agent, if POST_BUILD_STEPS includes "code-review"):
    - Reviews code quality, runs tests after fixes
    - → REVIEW_CLEAN ✅
15. Shell re-runs build + tests after agent steps (zero-token safety net)
16. ✅ Feature #5 complete

--- If step 12 had failed ---

12. Test suite: `npm test` → ❌ (3 tests failing)
    Shell captures last 80 lines of test output
    → Retry agent launched with failure output in prompt
    → Agent reads errors, fixes code, reruns tests
    → Loop back to step 11
```
