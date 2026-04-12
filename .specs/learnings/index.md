# Learnings Index

Cross-cutting patterns learned in this codebase. Updated via `/compound`.

## Quick Reference

| Category | File | Summary |
|----------|------|---------|
| Testing | [testing.md](./testing.md) | Mocking, assertions, test patterns |
| Performance | [performance.md](./performance.md) | Optimization, lazy loading, caching |
| Security | [security.md](./security.md) | Auth, cookies, validation |
| API & Data | [api.md](./api.md) | Endpoints, data handling, errors |
| Design System | [design.md](./design.md) | Tokens, components, accessibility |
| General | [general.md](./general.md) | Other patterns |

---

## Recent Learnings

<!-- /compound adds recent learnings here - newest first -->

_No learnings yet. Run `/compound` at the end of implementation sessions._

---

## Recent Failure Signals

<!-- /compound adds failure signals here - newest first. These are the highest-value learnings. -->

_No failure signals yet. These are captured automatically during `/tdd` cycles._

---

## How This Works

1. **Feature-specific learnings** → Go in the spec file's `## Learnings` section
2. **Cross-cutting learnings** → Go in category files below
3. **Failure signals** → Go in BOTH the spec's `## Learnings` AND the appropriate category file
4. **General patterns** → Go in `general.md`

The `/compound` command analyzes your session and routes learnings to the right place.

### Failure Signal Types

| Signal | What happened | Where it goes |
|--------|--------------|---------------|
| **Failure (drift)** | Spec↔code mismatch caught by drift check | Feature spec + `general.md` |
| **Failure (test-retry)** | Tests failed multiple times before passing | Feature spec + `testing.md` |
| **Failure (human-correction)** | User corrected the spec or rejected a scenario | Feature spec + `general.md` |
| **Failure (spec-gap)** | Spec was updated during implementation because it was incomplete | Feature spec + `general.md` |
| **Failure (build)** | Build or lint failed during implementation | Feature spec + appropriate category |

Failure signals must include: what went wrong, root cause, and a **"Fix for future"** directive.
