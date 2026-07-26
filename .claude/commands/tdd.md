# TDD Mode (Red-Green-Refactor)

Run the full TDD cycle from an approved spec. Use this after reviewing a spec created by `/spec-first`.

```
/spec-first {feature}     ← creates spec, pauses for review
        │
     [YOU REVIEW]
        │
/tdd {feature}            ← this command: builds it
        │
        ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     RED      │ ──▶ │    GREEN     │ ──▶ │   REFACTOR   │
│ (write       │     │ (implement   │     │ (clean up,   │
│  failing     │     │  until tests │     │  tests must  │
│  tests)      │     │  pass)       │     │  still pass) │
└──────────────┘     └──────┬───────┘     └──────┬───────┘
                            │                     │
                            ▼                     ▼
                     ┌──────────────┐     ┌──────────────┐
                     │ DRIFT CHECK  │     │ DRIFT CHECK  │
                     │ (layer 1)    │     │ (layer 1b)   │
                     └──────────────┘     └──────┬───────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │  COMPOUND    │
                                          │ (learnings)  │
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │   COMMIT     │
                                          └──────────────┘
```

## Behavior

### 0. Find the Spec

1. Parse the feature description from `$ARGUMENTS`
2. Search `.specs/features/**/*.feature.md` for matching spec (by path or frontmatter `feature:`)
3. **If no spec found** → Error: "No spec found for '{feature}'. Run `/spec-first {feature}` first."
4. **If spec found** → Read it and proceed

### 1. RED — Write Failing Tests

1. Read the spec file and ALL Gherkin scenarios
2. Read the `## Technical Design` section — use it to inform test setup (data shapes, API mocking, state management)
3. Write tests covering every scenario: happy path, edge cases, error states, loading states
4. Tests should **FAIL** (no implementation yet)
5. Document tests in `.specs/test-suites/{path}.tests.md`
6. Update spec frontmatter: `status: tested`, add test files to `tests: []`

### 2. GREEN — Implement Until Tests Pass

**Work in vertical slices, not stack order.** If the spec has an `### Implementation Slices` section, implement one slice at a time. If it doesn't (S feature), a single pass is fine — but never plan your own work as horizontal layers (all migrations, then all services, then all API, then all frontend). A slice ends in a verifiable state; verify it before starting the next.

For each slice:
1. Implement the slice, following the `## Technical Design` contract — including `### Program Design` (files, signatures, call stack). If reality forces a deviation from Program Design, deviate, then update the section to describe what you actually built and note it as a failure signal for compound
2. Use design tokens from `.specs/design-system/tokens.md`; read `.specs/design-system/DESIGN.md` before implementing UI; follow component patterns from `.specs/design-system/components/`
3. Run the slice's tests, and verify the slice live where the spec says how (curl the endpoint, load the page). Don't move on with a broken slice
4. Commit the slice: `feat: {feature} — slice {n}: {slice name}` (keeps diffs review-sized and gives the loop rollback points)

After all slices:
5. Run the FULL test suite — loop until ALL pass
6. **Track failure signals**: If tests fail multiple times, note the root cause mentally (bad test, bad implementation, ambiguous spec, missing mock). These feed into compound.
7. Update spec frontmatter: `status: implemented`, add components to `components: []`
8. Do NOT update the roadmap status — that happens after all verification passes

### 3. Migration Verify (only if the schema changed)

If this feature changed the Data Model and the spec has a `## Migration Plan`, verify the migration is safe. This is the schema analog of red-green. **Non-blocking and gated on database availability** — if no dev/test DB is reachable, skip with a logged note (mirrors `build-loop-local.sh`, which treats migration failures as non-blocking).

1. Read `.specs/migrations.md` for the apply command and conventions.
2. Confirm a migration artifact was actually generated (don't rely on auto-sync/push that skips a migration file unless that IS the project's convention).
3. If a scratch/test DB is available, run the **Reversibility Checklist**:
   - Apply forward (up) — must succeed
   - Reverse (down/revert) — must succeed, OR the migration is explicitly marked irreversible in the spec with a reason
   - Apply forward again (up) — must succeed (idempotency/reversibility)
   - Run the test suite against the migrated schema
4. **If it fails** (and a DB was available): fix the migration to match the Migration Plan, or update the plan if reality differs. Treat the failure as a signal for compound.
5. **If no DB is available**: log `Migration verify skipped — no database reachable` and continue. The build loop's `MIGRATION_CMD` step is the operational backstop.

### 4. Drift Check — Layer 1 (Self-Check)

Re-read your Gherkin scenarios and compare to what you just implemented:

1. For each scenario, verify the code implements it
2. Check for behaviors in code not described in the spec
3. Check for scenarios in the spec you didn't implement
4. **Structural check**: compare `### Program Design` (file list, signatures, call stack) to the actual code — the spec is documentation, so it must describe the code as it exists. Update it if they diverged
5. **If drift found**: fix the code to match the spec, or update the spec to document reality
6. **Track drift as a failure signal**: Note what drifted and why — this feeds into compound
7. Ensure tests still pass after any changes

### 5. REFACTOR — Clean Up

Now that tests pass and spec aligns, improve the code without changing behavior:

1. Look for opportunities: extract functions, simplify conditionals, improve naming, remove duplication, add types
2. Make incremental changes
3. **Do NOT change test assertions** — if you need to, that's a behavior change, not a refactor
4. Run tests after each change — they MUST still pass
5. If tests fail, fix the refactor (don't change the tests)

### 6. Drift Check — Layer 1b (Post-Refactor)

Re-verify spec↔code alignment after refactoring:

1. Re-read the Gherkin scenarios
2. Verify the refactored code still implements every scenario
3. Check that refactoring didn't subtly change behavior (e.g., error handling, validation)
4. Refactoring moves code around — re-sync `### Program Design` (files, signatures, call stack) with the refactored layout
5. **If drift found**: fix it, ensure tests pass

### 7. Compound — Extract Learnings (Automatic)

**Always run** — this is not optional. Extract learnings including failure signals:

1. Feature-specific patterns → spec's `## Learnings` section
2. Cross-cutting patterns → `.specs/learnings/{category}.md`
3. **Failure signals** → spec's `## Learnings` section AND `.specs/learnings/{category}.md`:
   - Drift caught during Layer 1 or 1b (what drifted, root cause, prevention)
   - Test retries (what failed, why, how to avoid)
   - Spec revisions made during implementation (what was missing or wrong)
   - Build/lint failures encountered
4. Update `.specs/learnings/index.md`

### 8. Commit

1. Regenerate mapping: `./scripts/generate-mapping.sh`
2. Stage all changes
3. Commit with message: `feat: {feature name} (TDD: red-green-refactor)`

**REQUIRED output signals** (for build loop parsing):
```
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to .feature.md file}
SOURCE_FILES: {comma-separated paths to source files created/modified}
```

---

## Trigger Phrases

This command also runs when the user says any of these after a spec has been shown:
- "go ahead"
- "build it"
- "tdd"
- "implement it"
- "yes, build"
- "looks good, build"
- "approved, go"
- "ship it"

In these cases, use the spec from the current conversation context.

---

## Example Usage

### Standalone (after reviewing a spec in a previous session)
```
/tdd user profile page
```

### After /spec-first approval (same session)
```
User: /spec-first user profile page
Agent: [creates spec, shows summary]
       "Does this look right? Ready to build?"
User: /tdd
Agent: [runs RED → GREEN → REFACTOR → COMPOUND → COMMIT]
```
