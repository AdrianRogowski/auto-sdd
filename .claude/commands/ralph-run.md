# /ralph-run — Build Loop Launcher

Check current state and launch the appropriate SDD build automation.

## What This Command Does

1. **Validate config** — ensure `.env.local` exists and is configured
2. **Show current state** — roadmap progress, features pending, deps status
3. **Ask what to run** — single feature, build loop, doc loop, or overnight
4. **Launch it** — run the script, report the log file to watch

---

## Instructions

### Step 1: Validate Configuration

Check that `.env.local` exists and has required values:
- `CLI_PROVIDER` is set
- The CLI binary exists (`which agent` or `which claude`)
- At least one of BUILD_CHECK_CMD or TEST_CHECK_CMD is set (or will be auto-detected)

If `.env.local` is missing or incomplete:
```
⚠️ Configuration not found. Run /ralph-setup first to configure your environment.
```

### Step 2: Show Current State

Read `.specs/roadmap.md` and report:

```
📋 Roadmap Status
  ✅ Completed: 5/18 features (28%)
  🔄 In Progress: 1 (Auth: Password Reset)
  ⬜ Ready to build: 3 (deps met)
  ⏸️ Blocked: 2
  ⬜ Pending (deps not met): 7

  Branch: main
  Strategy: chained
  CLI: cursor (composer-1.5)
```

If no roadmap exists, say so and suggest `/roadmap` or `/vision` first.

### Step 3: Kill Existing Dev Servers

Before launching any build automation, check if anything is running on dev ports:

```bash
./scripts/clean-slate.sh
```

This prevents port conflicts during build/test phases. Tell the user what was killed.

### Step 4: Ask What to Run

Use AskQuestion:

**Options:**
1. **Build next feature** — runs `/build-next` (single feature, interactive)
2. **Build loop** — runs `./scripts/build-loop-local.sh` (multiple features, automated)
3. **Parallel build** — runs `BRANCH_STRATEGY=parallel ./scripts/build-loop-local.sh`
4. **Doc loop** — runs `./scripts/doc-loop-local.sh` (document existing code)
5. **Overnight mode** — runs `./scripts/overnight-autonomous.sh`
6. **Just show me the command** — print the command without running it

If they pick build loop or parallel, also ask:
- How many features? (default from .env.local)
- Use current branch or specific base branch?

### Step 5: Launch

For script-based options (build loop, doc loop, overnight):

1. Run the script in background using Shell with `block_until_ms: 0`
2. Tell the user the log file to watch
3. Show first few lines of output to confirm it started

For single feature (/build-next):
- Just run `/build-next` directly in the current context

For "just show me":
- Print the exact command with all env overrides

### Step 6: Monitor (if backgrounded)

After launching a script:
- Read the terminal output periodically
- Report progress: "Feature 1/5 complete", "Currently on: Dashboard"
- Alert on failures: "Feature 3 failed, retrying..."

---

## Example Session

```
User: /ralph-run

Agent:
📋 Roadmap Status
  ✅ Completed: 5/18 features (28%)
  ⬜ Ready to build: 3 (deps met)

  [Killed 2 processes on ports 3000, 5173]

  What would you like to run?
  > Build loop (3 features ready)

  Launching: ./scripts/build-loop-local.sh
  Strategy: chained | Max: 3 | Model: composer-1.5

  [Monitoring...]
  ✓ Feature 6/18: Dashboard (4m 23s)
  ✓ Feature 7/18: Settings Page (3m 11s)
  ✗ Feature 8/18: User Profile (failed, retrying...)
```

---

## Quick Shortcuts

If the user says `/ralph-run build` or `/ralph-run loop`, skip the question and go straight to that mode. Supported shortcuts:

| Shortcut | Action |
|----------|--------|
| `/ralph-run build` | Launch build loop |
| `/ralph-run parallel` | Launch parallel build |
| `/ralph-run next` | Run /build-next (single feature) |
| `/ralph-run doc` | Launch doc loop |
| `/ralph-run overnight` | Launch overnight mode |
| `/ralph-run status` | Just show roadmap status |
