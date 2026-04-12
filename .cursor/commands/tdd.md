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

1. Implement the feature incrementally, following the `## Technical Design` contract (data model, API shapes, state management)
2. Use design tokens from `.specs/design-system/tokens.md`
3. Follow component patterns from `.specs/design-system/components/`
4. Run tests frequently — loop until ALL pass
5. **Track failure signals**: If tests fail multiple times, note the root cause mentally (bad test, bad implementation, ambiguous spec, missing mock). These feed into compound.
6. Update spec frontmatter: `status: implemented`, add components to `components: []`
7. Do NOT update the roadmap status — that happens after all verification passes

### 3. Drift Check — Layer 1 (Self-Check)

Re-read your Gherkin scenarios and compare to what you just implemented:

1. For each scenario, verify the code implements it
2. Check for behaviors in code not described in the spec
3. Check for scenarios in the spec you didn't implement
4. **If drift found**: fix the code to match the spec, or update the spec to document reality
5. **Track drift as a failure signal**: Note what drifted and why — this feeds into compound
6. Ensure tests still pass after any changes

### 4. REFACTOR — Clean Up

Now that tests pass and spec aligns, improve the code without changing behavior:

1. Look for opportunities: extract functions, simplify conditionals, improve naming, remove duplication, add types
2. Make incremental changes
3. **Do NOT change test assertions** — if you need to, that's a behavior change, not a refactor
4. Run tests after each change — they MUST still pass
5. If tests fail, fix the refactor (don't change the tests)

### 5. Drift Check — Layer 1b (Post-Refactor)

Re-verify spec↔code alignment after refactoring:

1. Re-read the Gherkin scenarios
2. Verify the refactored code still implements every scenario
3. Check that refactoring didn't subtly change behavior (e.g., error handling, validation)
4. **If drift found**: fix it, ensure tests pass

### 6. Compound — Extract Learnings (Automatic)

**Always run** — this is not optional. Extract learnings including failure signals:

1. Feature-specific patterns → spec's `## Learnings` section
2. Cross-cutting patterns → `.specs/learnings/{category}.md`
3. **Failure signals** → spec's `## Learnings` section AND `.specs/learnings/{category}.md`:
   - Drift caught during Layer 1 or 1b (what drifted, root cause, prevention)
   - Test retries (what failed, why, how to avoid)
   - Spec revisions made during implementation (what was missing or wrong)
   - Build/lint failures encountered
4. Update `.specs/learnings/index.md`

### 7. Commit

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
