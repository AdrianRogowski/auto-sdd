# /ralph-setup — Interactive Environment Setup Wizard

Set up `.env.local` for the SDD build loop with interactive prompts and auto-detection.

## What This Command Does

1. **Detect project** — framework, test runner, build tool, package manager
2. **Ask key questions** — CLI provider, branch strategy, integrations, parallelism
3. **Generate `.env.local`** — sensible defaults with auto-detected commands pre-populated
4. **Validate tooling** — check that `agent` or `claude` CLI exists, `gh` installed if PRs enabled
5. **Print summary** — "you're ready" with the exact command to run next

---

## Instructions

### Step 1: Check for Existing Config

Read `.env.local` if it exists. If it does:
- Tell the user what's currently configured
- Ask if they want to reconfigure or just update specific sections
- Preserve any values they don't want to change

If `.env.local` doesn't exist, copy from `.env.local.example` as a starting point.

### Step 2: Detect Project Type

Scan the project directory to determine:

```
- Framework: Check for package.json (Next.js, Vite, etc.), Cargo.toml, go.mod, pyproject.toml, etc.
- Package manager: pnpm-lock.yaml, yarn.lock, bun.lockb, package-lock.json
- Test runner: vitest, jest, pytest, cargo test, go test
- Build tool: tsc, vite build, cargo build, go build
- Lint tool: eslint, biome, ruff, clippy
- ORM/DB: drizzle, prisma, alembic, diesel
- E2E: playwright, cypress
```

Report what was detected.

### Step 3: Ask Configuration Questions

Use the AskQuestion tool for each section. Group related questions together:

**Core Settings:**
1. CLI provider: Cursor (`agent`) or Claude Code (`claude`)?
2. Branch strategy: chained (default), independent, sequential, parallel, or both?
3. If parallel: how many concurrent features? (default: 3)
4. Max features per run? (default: 50 for local, 4 for overnight)

**Integrations (optional):**
1. Do you use Slack for feature requests? → configure SLACK_* vars
2. Do you use Jira for tracking? → configure JIRA_* vars
3. Want draft PRs on completion? → requires `gh` CLI

**Build Validation:**
Show auto-detected commands and ask if they look right:
- Build: `{detected}` — correct? Override?
- Test: `{detected}` — correct? Override?
- Lint: `{detected}` — correct? Override?
- Migration: `{detected}` — correct? Override?
- E2E: `{detected}` — correct? Override?

**Model Selection (optional):**
1. Default model for all steps? (recommend `composer-1.5` for Cursor)
2. Want different models per phase? (show the phase list: spec, build, refactor, drift, compound, review)

**Overnight Automation (optional):**
1. Want to set up overnight scheduled runs? → guide through `setup-overnight.sh`

### Step 4: Generate .env.local

Write the `.env.local` file with:
- All configured values
- Comments explaining each section
- Auto-detected commands filled in (not empty strings)
- Unconfigured optional sections commented out

### Step 5: Validate

Run these checks:
1. CLI exists: `which agent` or `which claude` (depending on provider)
2. If PRs enabled: `which gh`
3. If mapping generation needed: `which yq` (optional, has fallback)
4. Build command works: quick dry-run of BUILD_CHECK_CMD
5. Test command works: quick dry-run of TEST_CHECK_CMD

Report any issues with fix instructions.

### Step 6: Dev Ports Config

Ask about dev server ports:
- What ports does your dev server use? (auto-detect from package.json scripts, vite config, etc.)
- Set `DEV_PORTS` and `DEV_CMD` in `.env.local` for `/clean-slate`

### Step 7: Summary

Print a clear summary:

```
✓ ralph-setup complete!

  CLI: cursor (agent)
  Strategy: chained
  Build: npx tsc --noEmit
  Test: pnpm test
  Lint: pnpm lint
  Models: composer-1.5 (all phases)
  Dev ports: 3000,5173
  Dev cmd: pnpm dev

  Next steps:
    /ralph-run          — launch the build loop
    /clean-slate        — kill dev servers and restart
    /spec-first {feat}  — build a single feature
```

---

## If Things Go Wrong

If auto-detection fails for any command, set it to empty (`""`) and tell the user:
- The build loop will try to auto-detect after the first feature creates project infrastructure
- They can always run `/ralph-setup` again to reconfigure
