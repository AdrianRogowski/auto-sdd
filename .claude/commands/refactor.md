---
description: Refactor code while ensuring tests still pass (manual or automated)
---

Refactor: $ARGUMENTS

## Key Principle

**Tests define behavior.** If you need to change test assertions, that's NOT a refactor—use normal workflow instead.

## Before Changing

1. Identify which tests cover the code
2. Run those tests (confirm they pass)
3. Note test IDs for reference

## During Refactoring

1. Make incremental changes
2. Do NOT change test assertions
3. If tests fail, the refactor broke something—fix it
4. Keep commits small and focused

## After Refactoring

1. Run tests again (verify all pass)
2. Update test docs ONLY if test names/organization changed
3. Do NOT update feature specs (behavior didn't change)

## Automated Mode (Build Loop / TDD)

When called by build loop or `/tdd` as Phase 3 (post-GREEN):
1. Read source files just implemented + test files
2. Identify: long functions, duplication, poor names, complex conditionals, missing types, dead code
3. Apply incremental refactoring, run tests after each change
4. If tests fail, revert that change, move to next opportunity
5. Commit: `refactor: clean up {feature name}`
6. Output: `REFACTOR_COMPLETE: {summary}` or `REFACTOR_SKIPPED: code already clean`

## Safe Refactors

✅ Extract function/class, rename variables, simplify conditionals, remove dead code, improve performance, add types

❌ NOT refactors (need behavior change workflow): Change return values, modify public API, change validation rules, alter data structures

## Red Flags

Stop and reassess if:
- Need to change test assertions
- Adding new test cases
- Feature spec seems wrong
- "Fixing" a test to make it pass
