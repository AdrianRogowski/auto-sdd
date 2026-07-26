# Changelog

Versioning: MAJOR.MINOR.PATCH — MAJOR = breaking changes (renamed commands, changed directory structure, removed config), MINOR = new features (new commands, new phases, new config), PATCH = bug fixes only.

## 2.11.0 — Program Design, Vertical Slices, One Canonical Command Set

Models get no training penalty for eroding codebase structure, and left alone they plan features in stack order (migrations → services → API → frontend) that produces nothing verifiable until everything is done. This release pins the shape of the code before implementation, builds in vertical slices that end in a curl/click/test checkpoint, and stops maintaining two drifting copies of every slash command.

### New
- **Program Design** (in `/spec-first` Technical Design) — File-tree diff, call stack, and key signatures. An agent contract during `/tdd`, and after implementation the documentation of how the code is laid out. Drift checks reconcile it the same way they reconcile Gherkin scenarios (specs are state).
- **Implementation Slices** (M/L features) — 2–4 vertical slices, each ending in a verifiable state. `/tdd` GREEN and the build-loop implement prompts work one slice at a time (verify + commit per slice) instead of horizontal layers. Intermediate mock scaffolding is allowed; the finished feature must still be real end-to-end.
- **Structural Drift** — `/catch-drift` and the Layer-2 prompts in `build-loop-local.sh`, `overnight-autonomous.sh`, and `drift-scan-all.sh` compare Program Design (files, signatures, call stack) against the actual code.
- **Roadmap vertical guardrail** — Every roadmap row must be user-demoable (a screen, flow, or endpoint). Layer-shaped rows ("build the API", "set up the schema") are folded into the feature they serve; slices live in the spec, not on the roadmap.
- **`scripts/sync-commands.sh`** — `.cursor/commands/` is the canonical source; `.claude/commands/` is generated from it as real copies (Claude Code's command discovery has repeatedly broken on symlinks). Custom commands that exist only on the Claude side are adopted into the canonical dir, never deleted. `--check` exits nonzero when out of sync. A Cursor `afterFileEdit` hook keeps the mirror current.

### Changed
- **Command consolidation** — The previously condensed `.claude/commands/` variants are replaced by the full Cursor bodies. Claude-side improvements worth keeping (`compound`'s "When NOT to Compound", `update-test-docs`' generic test paths) were merged into the canonical files first. `sdd-migrate` regenerates `.claude/commands/` via the sync script instead of merging it as a separate file set. `CLAUDE.md` documents the canonical-source rule.
- **`CLAUDE.md` and `specs-workflow.mdc`** — Spec format and TDD flow mention Program Design, Implementation Slices, and structural drift.

## 2.10.0 — Specs Are State, Not Deltas

A spec describes the entire expected behavior of the feature as it exists now; the delta belongs in git history and the pause-point summary. Without this rule, spec updates drift toward change-request language ("add three fields to the form"), and current expected behavior has to be reconstructed from a pile of change notes — the exact failure mode that makes ticket systems miserable to read.

### Changed
- **`/spec-first`** — New "Specs are state, not deltas" principle in the Create or Update step (both Cursor and Claude Code commands): scenario titles describe behavior, never instructions; mockups show the resulting UI in full, not annotations of what changed; mid-flight requirement changes rewrite the spec to the new truth rather than layering change notes on stale scenarios.
- **UPDATE mode** — Now explicitly rewrites affected scenarios so the spec reads as the complete current behavior, and removes or rewrites superseded scenarios instead of leaving old and new behavior side by side.
- **`CLAUDE.md` and `specs-workflow.mdc`** — The principle is stated in the always-loaded context so every agent (not just `/spec-first` invocations) holds specs to it.

## 2.9.0 — Parallel Mode: Merge Resolution That Actually Merges

Parallel worktree mode previously punted on any source-file merge conflict: the feature was marked ⏸️ blocked, and a cascade bug (uncommitted roadmap edits on the integration branch) could fail an entire batch and strand 5+ roadmap features per run. Conflicts between parallel agent branches are the expected case on a young codebase (every early feature touches `package.json`, the schema, route/layout hub files), not an edge case — so the merge gate now has a real resolution pipeline with the same shape as every other phase: agent attempt, deterministic verification, revert-and-degrade fallback.

### New
- **Merge-resolution agent** — Source-file conflicts are no longer an instant abort. The conflicted index is left in place mid-merge and a fresh agent (`MERGE_MODEL`, defaults to `AGENT_MODEL`) resolves each file semantically — a union of both features' behavior — then stages the results. The orchestrator verifies no unmerged paths or conflict markers remain before committing, and the existing post-merge build/test/drift gates revert to the pre-merge commit if the resolution is wrong.
- **Rebuild pass** (`REBUILD_ON_CONFLICT=true`, default) — Features whose merge can't be resolved (or that break build/tests/drift after merging) are rebuilt sequentially in a fresh worktree forked from the current integration branch, so the agent implements against the already-integrated code, then merged again. Worst case degrades to chained-mode speed for that feature; ⏸️ is now the last resort instead of the first response.
- **Three-way JSON union for `package.json`** — Replaces the lossy `--theirs` rule that silently dropped one side's dependencies. Dependencies and scripts from both sides survive; on true value conflicts the incoming side wins and the build/test gate validates. Lockfiles are regenerated via `--lockfile-only` install (npm/pnpm) instead of taken wholesale from either branch.
- **Line-level union merge for learnings** — `.specs/learnings/*` conflicts keep both sides' entries (`git merge-file --union`), plus a new `.gitattributes` with `merge=union` for `.specs/learnings/**` so most of these never conflict at all.

### Fixed
- **Dirty-roadmap cascade** — `mark_roadmap_status` edited `roadmap.md` on the integration branch but never committed, so the next merge refused to start ("local changes would be overwritten"), which was misread as an auto-resolve success, whose failing commit triggered a `reset --hard` that erased earlier status marks. Roadmap status updates are now committed immediately (`mark_roadmap_status_committed`), the tree is verified clean before every merge, and "merge refused to start" is detected separately from "merge conflicted" via `MERGE_HEAD`.
- **Failure reverts** now reset to a recorded pre-merge commit instead of `HEAD~1`, which was wrong whenever the drift agent had committed fixes between the merge and the failure.
- **Stale batch state** — The ready-feature list was parsed once per run; now it is re-parsed before every batch, so features whose dependencies completed in an earlier batch are built in the same run. The integration-branch advance decision uses a per-batch counter instead of the run-wide total (which could advance onto an empty integration branch).

### Changed
- **Parallel workers no longer touch shared files** — Worker spec/implement prompts forbid writing `.specs/mapping.md`, `.specs/roadmap.md`, and `.specs/learnings/*`; the merge phase owns them. Mapping is regenerated and committed once post-merge. This removes two guaranteed conflicts per branch.
- **`/ralph-setup`** — When parallel is selected, asks about `REBUILD_ON_CONFLICT` and `MERGE_MODEL` (a stronger merge model pays off since a bad resolution costs a full rebuild). Per-phase model list now includes merge.
- Startup banner and header docs describe the merge pipeline and new config.

## 2.8.0 — Database Migration Strategy

A migration strategy layered onto SDD across four seams, mirroring how strategy → constitution → spec → tdd already work. Previously the framework only had an *operational* migration step (`MIGRATION_CMD` applies whatever exists, non-blocking); there was no *design* discipline for schema changes and no way to infer a brownfield project's existing migration conventions.

### New
- **`/infer-migrations` command** — The schema analog of `/spec-init`. On a brownfield project it *infers* the migration conventions already in use (tool, naming, ordering, reversibility, backfill habits, expand-contract patterns) by reading the migrations directory; on a greenfield project it *defines* a strategy from the tech stack and constitution. Writes `.specs/migrations.md` (full playbook) and `.cursor/rules/migrations.mdc` (thin always-applied summary). Detects Prisma, Drizzle, Knex, TypeORM, Alembic, Django, Rails, Flyway, Sqitch, golang-migrate, and raw SQL. Available in both Cursor and Claude Code.
- **`.specs/migrations.md`** — Migration playbook: tool & layout, going-forward conventions, change classification table (additive / destructive / data transform), the expand-contract rule, and the reversibility checklist used by `/tdd`.
- **`.cursor/rules/migrations.mdc`** (`alwaysApply: true`) — Guarantees the core migration rules are in every agent's context window (mirrors `design-tokens.mdc`'s relationship to `tokens.md`), pointing to the full playbook for depth.
- **`## Migration Plan` subsection in specs** — `/spec-first` now emits a Migration Plan inside `## Technical Design` whenever a feature adds, changes, or drops a persisted entity/column/type/index/constraint: change class, forward + rollback, backfill strategy, expand-contract phasing, and apply command. Lives in the spec so it's auto-loaded by `/tdd`.
- **Migration Verify step in `/tdd`** — New Step 3 (after GREEN): when the schema changed, run the reversibility checklist (up → down → up on a scratch DB, then tests against the migrated schema). Non-blocking and gated on database availability, matching `build-loop-local.sh`. TDD steps renumbered (Drift L1 → 4, Refactor → 5, Drift L1b → 6, Compound → 7, Commit → 8).
- **"Schema & Migrations" constitution category** — `/constitution` now detects a migrations directory and generates rules (reversible migrations, expand-contract for destructive changes, separate backfills). Enforced via the per-spec Constitutional Compliance table.

### Changed
- **`/spec-init`** — Brownfield discovery now detects database/migration tooling and runs the `/infer-migrations` flow as a discovery step (new Step 9 in Cursor, Step 7 in Claude Code), writing `.specs/migrations.md` + `.cursor/rules/migrations.mdc` the same way Step 8 handles the design system.
- **`/spec-first`** — Load Context step reads `.specs/migrations.md`; Technical Design step and the spec template include the Migration Plan subsection.
- **`/build-next`** — Context loading reads the migration playbook when a feature may touch the schema.
- **CLAUDE.md, README.md, `.cursor/rules/specs-workflow.mdc`** — Document `/infer-migrations`, the migration playbook, the Migration Plan, and the new `/tdd` verify step.

## 2.7.0 — Design System: DESIGN.md, Preview, Archetype References

### New
- **Three design system outputs** — `/design-tokens` now creates `.specs/design-system/DESIGN.md` (Google DESIGN.md spec for agents), `tokens.md` (spec shorthand), and `preview.html` (single-page visual showcase).
- **Archetype references** — `.specs/design-system/references/*.design.md` (Professional, Minimal, Friendly, Bold, Technical) teach structure and depth before generating project-specific systems.
- **Golden demo** — `.specs/design-system/examples/demo/` (Fieldnote: synced DESIGN.md, tokens.md, preview.html). Pattern inspo from Linear via getdesign.md.
- **getdesign catalog** — `.specs/design-system/examples/README.md` with install commands for Linear, Notion, Stripe, Supabase, and other picks by personality.
- **`preview.template.html`** — Shell for generating project preview pages (palette, typography, components, Do's/Don'ts, light/dark toggle).
- **`.specs/design-system/PLAN.md`** — Design system enhancement plan and success criteria.

### Changed
- **`/design-tokens`** — Reads archetype references; syncs all three artifacts on create/update; new `preview` and `inspiration` subcommands; validates with `@google/design.md lint` when available.
- **`.cursor/rules/design-tokens.mdc`** — Agents must read DESIGN.md before UI work.
- **`/spec-first` and `/tdd`** — Reference DESIGN.md for implementation; mention preview.html for human review.
- **CLAUDE.md, README.md, specs-workflow.mdc, .specs/README.md** — Updated design system documentation.

## 2.6.0 — Technical Design, Failure Signals, Auto-Compound

### New
- **Technical Design section in specs** — Every feature spec now includes a `## Technical Design` section between Gherkin scenarios and ASCII mockup. Contains Data Model (entities, fields, relationships), API Contracts (endpoints, shapes, errors), State Management (where state lives, transitions), and Key Dependencies (existing + new modules). This bridges the gap between WHAT (Gherkin) and HOW (implementation), reducing variance during the GREEN phase — two different agents reading the same spec will build roughly the same thing. The RED step reads Technical Design for test setup, and the GREEN step follows it as an implementation contract.
- **Failure signal capture** — The `/compound` step now actively looks for failure signals alongside success patterns. Five failure types are tracked: `Failure (drift)` (spec↔code mismatch caught by drift check), `Failure (test-retry)` (tests that failed multiple times), `Failure (human-correction)` (user corrections to spec or implementation), `Failure (spec-gap)` (spec updated during implementation because it was incomplete), and `Failure (build)` (build/lint failures). Each failure must include root cause and a "Fix for future" directive. Failure signals go to BOTH the feature spec's `## Learnings` section AND the appropriate `.specs/learnings/{category}.md` file. The learnings index now has a "Recent Failure Signals" section.
- **Failure tracking during TDD** — The GREEN step now explicitly tracks test retries and build failures. Both drift check steps (Layer 1 and 1b) track drift as a failure signal. These are collected and persisted by compound.

### Changed
- **`/compound` is now automatic after every `/tdd` cycle** — Previously optional in Normal mode (only automatic in Full mode). Now always runs at the end of every TDD cycle regardless of mode. This ensures learnings and failure signals accumulate over time instead of being lost when users forget to run `/compound` manually. Can still be invoked standalone for non-TDD sessions.
- **`/spec-first` Step 8 (Compound)** — Changed from "Normal Mode: Optional" to "Both Normal and Full Mode: Always runs."
- **`/tdd` Step 6 (Compound)** — Changed from "Run /compound" to "Automatic — Always Runs" with explicit failure signal collection.
- **SPEC step numbering** — Now 10 steps (was 9): Technical Design is step 3, subsequent steps renumbered.
- **CLAUDE.md** — Updated TDD step descriptions (RED reads Technical Design, GREEN tracks failures, drift checks track drift, compound always runs with failure signals), updated learnings section, updated feature spec format with Technical Design template, updated compound command description.
- **`.cursor/rules/specs-workflow.mdc`** — Same updates as CLAUDE.md: TDD step descriptions, feature spec format, compound command description.
- **`.specs/learnings/index.md`** — Added "Recent Failure Signals" section and Failure Signal Types table.
- **`.specs/README.md`** — Updated compound description from "optional" to "automatic after /tdd".

## 2.5.0 — GTM Pipeline: Go-to-Market Planning & Early User Discovery

### New
- **`/gtm` command** — Create an actionable go-to-market playbook from strategy.md. Uses WebSearch to find specific channels, communities, and content opportunities where the target customer is active. Outputs `.specs/gtm.md` with tiered channel map, outreach templates (community post, cold DM, feedback request), messaging framework, and 30-day launch timeline with checkboxes. Supports Create, Update, and `--refresh` modes. Available in both Cursor and Claude Code.
- **`/find-early-users` command** — Find specific people, companies, and conversations to reach out to for early feedback. Reads strategy.md, constructs search queries from problem statement and competitor names, then uses WebSearch to find people publicly expressing the pain you're solving — Reddit threads, Twitter complaints, HN discussions, G2 reviews, job postings. Outputs `.specs/gtm/prospects.md` with scored prospect list, draft outreach messages, threads to monitor, and communities to join. Supports `--channel [channel]` for focused deep dives. Available in both Cursor and Claude Code.
- **Phase 5: GTM Sketch in `/strategy`** — After writing strategy.md, `/strategy` now automatically appends a lightweight GTM sketch: primary channels based on buying motion, secondary channels for after first 10 users, and a first-10-users action plan. Points to `/gtm` and `/find-early-users` for going deeper.
- **PMF search workflow** — New documented workflow for finding product-market fit: iterate on `/strategy` → `/gtm` → `/find-early-users` → conversations → `/strategy (update)` before committing to `/vision`. Explicit guidance on when to stay in strategy iteration vs move to vision.
- **Natural language triggers** for new commands: "gtm playbook", "marketing plan", "how do we get users", "launch plan", "find early users", "find prospects", "who should I talk to", "find beta testers", "prospect list", etc.
- **`.specs/gtm/` directory** — New directory for go-to-market artifacts: `gtm.md` (playbook) and `prospects.md` (prospect list).

### Changed
- **"go to market" / "GTM" triggers** now route to `/gtm` instead of `/strategy` (dedicated command exists now).
- **`/strategy` "After Saving" message** — Now includes GTM sketch summary and recommends `/gtm` and `/find-early-users` as next steps.
- **CLAUDE.md** — GTM pipeline section, PMF vs known-product ordering guidance, updated project setup flow diagram with GTM branch, new command triggers, updated directory structure and file locations.
- **`.cursor/rules/specs-workflow.mdc`** — GTM command triggers, updated setup flow, directory structure, command tables, file locations.
- **README.md** — GTM commands in setup flow, command tables, directory structure, and quick start examples.

## 2.4.0 — Product Strategy & Constitutional Constraints

### New
- **`/strategy` command** — Define business strategy (target customer, buying motion, value proposition, success metrics, anti-goals) through a guided conversation before building. Outputs `.specs/strategy.md`. Available in both Cursor and Claude Code.
- **`/constitution` command** — Define non-negotiable project constraints (security, data handling, error patterns, dependencies) tailored to the project's tech stack and strategy. Outputs `.specs/constitution.md`. Includes `--audit` mode to scan all specs for compliance. Available in both Cursor and Claude Code.
- **Strategy Alignment section in specs** — `/spec-first` reads `strategy.md` and adds a Strategy Alignment section to every feature spec, showing which customer segment the feature serves, how it supports the buying motion, and which success metric it moves. Flags misalignment (e.g., "enterprise feature in a PLG strategy").
- **Constitutional Compliance section in specs** — `/spec-first` reads `constitution.md` and adds a Constitutional Compliance section to every feature spec. Each rule is marked as applicable, N/A, or flagged as a conflict.
- **Learnings index in /spec-first** — `/spec-first` now reads `.specs/learnings/index.md` during context loading, so specs benefit from cross-cutting patterns discovered in previous features.
- **Pre-populated security learnings** — `.specs/learnings/security.md` ships with 9 starter entries covering common web security patterns (CWE-referenced), replacing the empty "No learnings yet" stubs.
- **Natural language triggers** for new commands: "strategy", "product strategy", "business strategy", "shape this", "GTM", "constitution", "project constraints", "security rules", "invariants", "audit specs".

### Changed
- **`/vision`** now reads `strategy.md` in both Create and Update modes. Strategy grounds the vision in business decisions.
- **`/personas`** now reads `strategy.md`. Strategy determines who the personas are (target segment → primary persona, anti-segment → anti-persona).
- **`/roadmap`** now reads `strategy.md` in Create and Reprioritize modes. Strategy drives feature prioritization by business value and buying motion fit.
- **`/build-next`** now reads `strategy.md` during context loading alongside vision, personas, and learnings.
- **`/spec-first`** context loading (Step 1) expanded from "personas + design tokens" to "strategy + constitution + personas + design tokens + learnings index".
- **CLAUDE.md** — Updated project setup flow (`/strategy → /vision → /personas → /constitution → /design-tokens`), new command tables, strategy/constitution sections, updated spec format with new sections.
- **`.cursor/rules/specs-workflow.mdc`** — Updated to match CLAUDE.md: new triggers, updated setup flow, expanded context loading, file locations table.
- **README.md** — Updated quick start, setup flow diagrams, command tables, directory structure, and examples to include strategy and constitution.
- **`.specs/` directory** — New template files: `strategy.md`, `constitution.md`.

## 2.3.2 — Fix Parallel Mode Quality Parity

### Fixed
- **Parallel mode skipped 3 of 5 pipeline phases** — Workers only ran spec → implement → refactor. Now runs the full pipeline: workers do spec → implement → verify (build+test) → refactor with retries, then post-merge runs drift check (Layer 2) + compound (learnings) per feature. Parallel `✅` now means the same quality gates as sequential.
- **No retry logic in parallel workers** — Workers got one shot; `MAX_RETRIES` was silently ignored. Now retries up to `MAX_RETRIES` on spec/build/test failure, matching sequential mode.
- **No pre-merge build/test verification** — Workers trusted the agent's `FEATURE_BUILT` signal without independently verifying. Now runs `check_build` + `check_tests` in each worktree before signaling success, so broken features are caught before the merge phase.
- **Refactor had no safety net** — If refactor broke build/tests in a worker, the damage was permanent. Now saves pre-refactor commit and reverts with `git reset --hard` if verification fails.
- **Duration tracking was wrong** — Measured `wait` time instead of actual build time. PID[1]'s duration was "(worker 1 time - worker 0 time)" and PID[2] was ≈0. Now records spawn time per worker and computes actual elapsed.
- **Array misalignment on worktree failure** — When worktree creation failed, `PIDS` was shorter than `FEATURES`/`RESULT_FILES`, causing wrong feature names in success/failure reporting. Failed worktrees are now counted immediately without appending to the PID array.
- **Missing result file not handled** — If a worker's temp file disappeared, the loop silently skipped it. Now reports failure explicitly.
- **No cleanup on SIGINT/SIGTERM** — Background workers became orphans and worktrees persisted. Added trap handler that kills worker PIDs and removes worktrees on unexpected exit.

### Removed
- **`MERGE_STRATEGY` config** — Both `dependency` and `fifo` branches contained identical code (both used spawn order). Removed the config knob; merges always happen in roadmap order, which is the natural order from `parse_ready_features`.

### Changed
- **Roadmap `✅` only after all phases pass** — Previously marked complete after build+test, before drift/compound. Now marks `✅` only after merge verification + drift check + compound all succeed.
- **CLAUDE.md** — Updated parallel builds diagram to show full pipeline (spec → impl → verify → refactor in workers, then merge → drift → compound sequentially).
- **`.env.local.example`** — Removed `MERGE_STRATEGY`, updated parallel docs to describe actual pipeline.

## 2.3.1 — Fix Parallel Mode Roadmap Parsing

### Fixed
- **Parallel mode "No features ready"** — `parse_ready_features()` in `build-loop-local.sh` used hardcoded column positions (`$7`/`$8`) for Deps and Status, which only worked with 7-column roadmap tables (with Jira column). Roadmaps generated by `/roadmap` without a Jira column (6 columns) had Deps and Status at `$6`/`$7`, causing every feature to be skipped. Fixed to use `$(NF-2)`/`$(NF-1)` which reads from the end of the row, supporting both 6 and 7 column formats.
- **`local` outside function** — Three `local total_elapsed=...` assignments at the script's top level (not inside any function) caused `local: can only be used in a function` bash errors in parallel, independent, and both branch strategies.

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
