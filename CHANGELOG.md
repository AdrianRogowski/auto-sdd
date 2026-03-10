# Changelog

Versioning: MAJOR.MINOR.PATCH — MAJOR = breaking changes (renamed commands, changed directory structure, removed config), MINOR = new features (new commands, new phases, new config), PATCH = bug fixes only.

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
