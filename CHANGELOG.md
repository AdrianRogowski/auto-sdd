# Changelog

Versioning: MAJOR.MINOR.PATCH — MAJOR = breaking changes (renamed commands, changed directory structure, removed config), MINOR = new features (new commands, new phases, new config), PATCH = bug fixes only.

## 2.3.0 — Ralph Commands, Parallel Builds, Clean Slate

### New
- **`/ralph-setup`** — Interactive wizard that auto-detects project framework, test runner, build tool, and package manager, then generates a fully configured `.env.local` through guided prompts. Available in both Cursor and Claude Code.
- **`/ralph-run`** — Build loop launcher that shows roadmap status, kills dev servers, and lets you pick what to run (single feature, build loop, parallel build, doc loop, overnight). Supports shortcuts like `/ralph-run parallel`.
- **`/guide`** — Generates a living `GUIDE.md` for the built application (not SDD itself). Stitches user flows from feature specs, lists screens, API endpoints, env vars, architecture, and key gotchas from learnings.
- **`/clean-slate`** — Kills all processes on dev ports and optionally restarts the dev server. Also available as `scripts/clean-slate.sh` for zero-overhead usage.
- **`BRANCH_STRATEGY=parallel`** — Concurrent feature builds in separate git worktrees. Fans out up to `PARALLEL_FEATURES` (default: 3) background agent processes, then merges results onto an integration branch with auto-conflict resolution and build/test verification per merge.
- **`PARALLEL_FEATURES`** env var — Max concurrent agent processes for parallel builds (default: 3).
- **`MERGE_STRATEGY`** env var — How to order merges after parallel builds: `dependency` (respects roadmap deps, default) or `fifo` (first done, first merged).
- **`DEV_PORTS`** / **`DEV_CMD`** env vars — Configure which ports `/clean-slate` kills and what command restarts the dev server.
- **Subagent patterns rule** (`.cursor/rules/subagent-patterns.mdc`) — Teaches the agent when and how to use the Task tool for parallel work within SDD commands (parallel reads, parallel validation, batch processing).
- **Natural language triggers** for new commands: "ralph setup", "ralph run", "clean slate", "nuke localhost", "generate guide", etc.

### Changed
- **`CLAUDE.md`** — Full subagent patterns reference inlined (Claude Code can't read `.cursor/rules/`), parallel builds section, new command tables and triggers.
- **`specs-workflow.mdc`** — Ralph command triggers and command table added.
- **`README.md`** — Ralph commands section, parallel build examples, clean-slate script documented.

## 2.2.4 — Sync CLAUDE.md with Cursor Rules

### Fixed
- **CLAUDE.md missing command triggers** — Added the full natural language trigger mapping (e.g., "spec first", "go ahead", "build it", "ship it") and full mode triggers ("full", "auto", "no stops", "don't pause") that were only in `.cursor/rules/specs-workflow.mdc`.
- **CLAUDE.md missing SPEC/TDD step breakdowns** — Added the explicit 7-step SPEC process and 6-step /tdd process that Cursor had.
- **CLAUDE.md missing greenfield behavior** — Added "When `/spec-first` Runs on Greenfield" (auto-create design tokens) and "When a Spec References New Components" (auto-create stubs) sections.
- **CLAUDE.md missing `design_refs` frontmatter field** — Added to both feature spec template and mapping frontmatter example.
- **CLAUDE.md missing frontmatter fields table** — Added table documenting when to update each field.
- **CLAUDE.md missing persona "Context" field** — Added "how the user spends their day, devices, technical level" and expanded persona usage to match Cursor's before/after writing detail.
- **CLAUDE.md missing pause triggers** — Added "show me the Gherkin", "what would this look like?", "before you implement...", "let me see".

## 2.2.3 — Fix False-Positive Transient Error Detection

### Fixed
- **Transient error false positives** — `run_agent()` in all three scripts (`build-loop-local.sh`, `overnight-autonomous.sh`, `doc-loop-local.sh`) grepped the entire agent output for keywords like `429`, `capacity`, `fetch.failed`. If the agent wrote code handling HTTP 429 or mentioned "capacity" in a comment, the script incorrectly triggered exponential backoff (up to 5 hours). Now: only checks when the CLI exits with a non-zero code, and only inspects the last 5 lines of output where CLI error messages actually appear.

## 2.2.2 — Fix Ambiguous /build-next Reference in Script Prompts

### Fixed
- **Spec-phase prompt ambiguity** — `build-loop-local.sh` and `overnight-autonomous.sh` spec prompts said "Run the /build-next command" then contradicted it with "spec ONLY, do NOT implement." Since `/build-next` always runs `/spec-first --full`, agents could follow the command spec instead of the inline instructions, causing the full TDD cycle to run in the spec phase. Replaced with "Find the next feature from the roadmap" and an explicit "do NOT run /build-next or /spec-first --full" guard.

## 2.2.1 — Re-sync on Same Version

### Fixed
- **`/sdd-migrate` same-version skip** — When TARGET = CURRENT version, the command now performs a full re-sync instead of skipping. This ensures files added to the template without a version bump (or missed during a partial migration) are still picked up. The summary labels the operation as "RE-SYNC" to distinguish from a version upgrade.

## 2.2.0 — Extended Build Validation Pipeline

### New
- **Lint check** (`LINT_CHECK_CMD`) — Auto-detected from `package.json` lint script, ruff, cargo clippy. Non-blocking (warns, doesn't retry). Runs after tests pass.
- **Migration check** (`MIGRATION_CMD`) — Auto-detected from drizzle, prisma, alembic, django. Only runs when schema files change (detected via `git diff`). Non-blocking (database may not be available).
- **E2E check** (`E2E_CHECK_CMD`) — Auto-detected from playwright or cypress config. Non-blocking. Runs after drift check when code is final (most expensive check).
- **Lazy re-detection** — All check commands are re-detected after each feature if empty. Handles greenfield projects where Feature 1 creates the infrastructure (package.json, tsconfig, etc.) that didn't exist at startup. Newly detected commands are persisted back to `.env.local`.
- **Infrastructure hint** — For the first 2 features, the build prompt includes a reminder to update `.env.local` with verification commands if the feature creates project infrastructure.

### Fixed
- **`xargs` quoting bug** — Agent output containing single quotes (e.g., "what's") caused `xargs: unterminated quote` errors in signal parsing. Replaced all `xargs` calls with a `trim()` function using `sed`.

### Changed
- Post-build verification ordering: build → migration → test → lint (was: build → test).
- E2E runs after drift check (was: not available).
- Startup output shows all 5 verification commands in a table with "auto-detect" for empty commands.
- Lint failure output is included in retry agent context.

### Config (.env.local)

New options:
```
LINT_CHECK_CMD=""       # Auto-detected (npm run lint, ruff, clippy)
MIGRATION_CMD=""        # Auto-detected (drizzle push, prisma push, alembic)
E2E_CHECK_CMD=""        # Auto-detected (playwright, cypress)
```

All check commands now support `"skip"` to explicitly disable.

## 2.1.0 — Red-Green-Refactor TDD

### New
- **`/tdd` command** — Run the full Red-Green-Refactor cycle from an approved spec. Use after `/spec-first` shows you the spec and you're ready to build.
- **Refactor phase** in build scripts — After tests pass (GREEN), a fresh agent cleans up the code while ensuring tests still pass. Auto-reverts if refactor breaks anything.
- **Two-layer drift checking** — Layer 1 self-check after GREEN, Layer 1b re-check after REFACTOR, Layer 2 fresh-agent check in build scripts.
- **Compound as separate phase** — Learnings are now extracted after refactor+drift (sees final code state), not during the build agent's run.
- **Rate limit handling** — `run_agent()` detects rate limits (429, overloaded) and retries with exponential backoff. Configurable via `RATE_LIMIT_BACKOFF` and `RATE_LIMIT_MAX_WAIT`.
- **Per-phase model selection** — New `REFACTOR_MODEL` and `COMPOUND_MODEL` config options.
- **`REFACTOR` and `COMPOUND` toggles** — Set to `false` in `.env.local` to skip these phases.

### Fixed
- **Premature roadmap completion** — Build agents no longer mark features ✅ in the roadmap. The script itself marks completion only after ALL verification phases pass (build, test, refactor, drift, compound).
- **`fail` function bug** in `overnight-autonomous.sh` — Was calling undefined `fail` instead of `error` in drift check.

### Changed
- `/spec-first` pause prompt now says "Run `/tdd` when ready" instead of separate test/implement pauses.
- `/spec-first --full` now includes the REFACTOR step.
- `/refactor` command has an "Automated Mode" section for build-loop integration.
- Build scripts use 5-phase pipeline: Spec → Build → Refactor → Drift → Compound.
- `/sdd-migrate` is now version-agnostic — detects stock vs custom commands dynamically instead of using hardcoded lists. Works for any version upgrade, not just 1.0→2.0.

### Config (.env.local)

New options:
```
REFACTOR=true              # Enable/disable refactor phase
COMPOUND=true              # Enable/disable compound phase
REFACTOR_MODEL=""          # Model for refactor agent
COMPOUND_MODEL=""          # Model for compound agent
RATE_LIMIT_BACKOFF=60      # Initial backoff (seconds)
RATE_LIMIT_MAX_WAIT=18000  # Max wait (seconds, ~5h)
```

## 2.0.0 — Compound Learning & Automation

- Compound learning system (`.specs/learnings/`)
- Overnight automation (`build-loop-local.sh`, `overnight-autonomous.sh`)
- Vision, roadmap, and clone-app commands
- Persona-driven specs and design tokens
- Auto-generated mapping from YAML frontmatter
- Drift enforcement (Layer 1 self-check + Layer 2 fresh-agent)
- Git hooks for mapping regeneration
- Per-step model selection for build scripts
