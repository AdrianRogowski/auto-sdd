# Start New Feature

Prepare your git workspace for a new feature: sync with remote, switch to main branch, and create a feature branch.

```
feature-branch ──► (merge) ──► develop
       │                          │
       │    /start-feature        │
       │          │               │
       └──────────┼───────────────┘
                  ▼
            new-feature-branch
```

## When to Use

- After merging a PR and wanting to start something new
- When switching context to a different feature
- Starting work for the day
- Any time you need a fresh feature branch from latest code

## Behavior

### 1. Check Current State
- What branch am I on?
- Are there uncommitted changes?
- Is there a PR merged that I was working on?

### 2. Handle Uncommitted Changes
If there are changes:
- Ask: "You have uncommitted changes. Stash them, commit them, or abort?"
- Options: `stash` / `commit` / `abort`

### 3. Sync with Remote
```bash
git fetch origin
git checkout {main_branch}  # develop, main, or master
git pull origin {main_branch}
```

### 4. Create Feature Branch
- Ask for feature description if not provided
- Generate branch name from description
- Create and checkout the branch

### 5. Ready for Work
- Confirm branch created
- Remind about `/spec-first` workflow
- Optionally create initial spec file

## Configuration

The command respects your project's branching strategy:

| Setting | Default | Description |
|---------|---------|-------------|
| Main branch | `develop` | Branch to sync from (`main`, `master`, `develop`) |
| Branch prefix | `feature/` | Prefix for new branches |
| Branch style | `kebab-case` | How to format branch names |

Configure in `.cursor/rules/specs-workflow.mdc`:
```markdown
## Git Configuration
- Main branch: develop
- Feature prefix: feature/
- Bugfix prefix: fix/
```

## Output Format

```markdown
## Starting New Feature 🚀

### Git Status
- Previous branch: `feature/bulk-export`
- Uncommitted changes: None

### Syncing
```
✓ Fetched from origin
✓ Switched to develop
✓ Pulled latest (3 new commits)
```

### New Branch Created
- Branch: `feature/user-notifications`
- Based on: `develop` (up to date)

### Ready to Go!

**Next steps:**
1. Describe the feature for `/spec-first user notifications`
2. Or start exploring with `/prototype notifications system`

---

**You're on `feature/user-notifications` and ready to code!**
```

## Example Usage

### With Feature Description
```
/start-feature user notification preferences
```
I will:
1. Stash/handle any uncommitted changes
2. Sync develop branch
3. Create `feature/user-notification-preferences`
4. Ask if you want to start with `/spec-first`

### Without Description
```
/start-feature
```
I will:
1. Handle git housekeeping
2. Ask: "What feature are you starting?"
3. Create branch based on your answer

### After Merging PR
```
/start-feature next: implement email templates
```
I will:
1. Note you're on the old feature branch
2. Sync and switch to develop
3. Create `feature/implement-email-templates`

### Bug Fix Variant
```
/start-feature fix: date picker timezone bug
```
I will:
1. Use `fix/` prefix instead of `feature/`
2. Create `fix/date-picker-timezone-bug`

## Branch Naming

The command converts your description to a branch name:

| Input | Branch Name |
|-------|-------------|
| "user notification preferences" | `feature/user-notification-preferences` |
| "Add CSV export" | `feature/add-csv-export` |
| "fix: login timeout" | `fix/login-timeout` |
| "JIRA-1234 user settings" | `feature/JIRA-1234-user-settings` |

## Error Handling

### Uncommitted Changes
```
⚠️ You have uncommitted changes:
- M components/DealCard.tsx
- A components/NewFile.tsx

Options:
1. `stash` - Stash changes and continue
2. `commit` - Commit with message and continue  
3. `abort` - Cancel and stay on current branch

What would you like to do?
```

### Merge Conflicts on Pull
```
⚠️ Merge conflicts when pulling develop:
- components/DealCard.tsx

Options:
1. Resolve conflicts now
2. Abort and stay on current branch

Would you like help resolving conflicts?
```

### Branch Already Exists
```
⚠️ Branch `feature/user-notifications` already exists.

Options:
1. Switch to existing branch
2. Create with suffix: `feature/user-notifications-2`
3. Choose different name

What would you like to do?
```

## Tips

1. **Commit or stash first** - Always handle changes before switching
2. **Descriptive names** - Good branch names help with PR titles
3. **Include ticket numbers** - If using Jira/Linear, include the ID
4. **Short but meaningful** - `feature/csv-export` > `feature/add-ability-to-export-data-to-csv-format`

