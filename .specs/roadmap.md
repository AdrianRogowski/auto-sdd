# Build Roadmap

> Ordered list of features to implement. Each row should be a demoable vertical (prefer L) — after any ✅ you can stop and still show something real.
> Updated by `/roadmap`, `/clone-app`, `/roadmap-triage`, and `/build-next`.

## Implementation Rules

**Every feature in this roadmap must be implemented with real data, real API calls, and real database operations.** No exceptions.

- **No mock data** — never use hardcoded arrays, fake JSON, or placeholder content to simulate functionality. If a feature needs data, it reads from the database or calls a real API.
- **No fake API endpoints** — every endpoint must do real work. No routes that return static JSON.
- **No placeholder UI** — components must be wired to real data sources. If the data isn't available yet, show a proper empty state, not fake data.
- **No "demo mode"** — features either work end-to-end or they aren't done. A feature is only ✅ when a real user can use it with their real data.
- **Real validation** — forms validate against real constraints, not just "is this field filled in?"
- **Real error handling** — API failures, empty results, rate limits, and edge cases must be handled, not ignored.
- **Test against real flows** — when verifying a feature, use the app as a user would. Trigger real API calls, see real results.
- **No layer rows** — never add "project setup", "database schema", or "API endpoints" as standalone features; fold them into a user-demoable vertical. Sub-steps go in the feature spec's Implementation Slices.
- **Core loop before auth** — unless auth is the product, sequence signup/login after the first demoable loop. Still include an ownership stub (`user_id` / scoped queries) in the first domain feature.

---

## Progress

<!-- Auto-updated summary -->

| Status | Count |
|--------|-------|
| ✅ Completed | 0 |
| 🔄 In Progress | 0 |
| ⬜ Pending | 0 |
| ⏸️ Blocked | 0 |

**Last updated**: <!-- timestamp -->

---

## Phase 1: Core loop

> First demoable value. Scaffold + store fuse into the first vertical — not separate rows. Auth deferred unless it is the aha.

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| <!-- 1 --> | <!-- App spine + store + primary create/list flow --> | <!-- clone-app --> | <!-- PROJ-101 --> | <!-- L --> | <!-- - --> | <!-- ⬜ --> |

---

## Phase 2: Expand the loop

> Adjacent capabilities that deepen the same value. Each row still demoable alone.

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| <!-- 10 --> | <!-- Secondary capability on the core loop --> | <!-- clone-app --> | <!-- PROJ-110 --> | <!-- L --> | <!-- 1 --> | <!-- ⬜ --> |

---

## Phase 3: Accounts & polish

> Auth/sync when needed, then nice-to-haves. Auth is usually here, not Phase 1.

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| <!-- 20 --> | <!-- Dark mode --> | <!-- slack:C123/ts --> | <!-- PROJ-120 --> | <!-- S --> | <!-- - --> | <!-- ⬜ --> |

---

## Ad-hoc Requests

> Features added from Slack/Jira that don't fit a phase. Processed after current phase.

| # | Feature | Source | Jira | Complexity | Deps | Status |
|---|---------|--------|------|------------|------|--------|
| <!-- 100 --> | <!-- Export to CSV --> | <!-- jira:PROJ-456 --> | <!-- PROJ-456 --> | <!-- S --> | <!-- 10 --> | <!-- ⬜ --> |

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ⬜ | Pending - not started |
| 🔄 | In Progress - currently being built |
| ✅ | Completed - PR merged |
| ⏸️ | Blocked - waiting on dependency or decision |
| ❌ | Cancelled - no longer needed |

## Complexity Legend

| Symbol | Meaning | Typical Scope |
|--------|---------|---------------|
| L | Large (default) | Full demoable vertical; prefer this for roadmap rows |
| M | Medium | Smaller vertical that is still demoable alone |
| S | Small | Polish / bugs / tiny additive UX — not bootstrap layers |

---

## Notes

<!-- Any important context for the roadmap -->
<!-- Greenfield: ~10–15 demoable verticals; ownership stub in first domain feature; auth usually Phase 3 -->

---

_This file is the single source of truth for `/build-next`. Features are picked in order, respecting dependencies._
_Create with `/roadmap create`, add features with `/roadmap add`, restructure with `/roadmap reprioritize`._
