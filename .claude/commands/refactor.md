# Refactor Mode

Refactor code while ensuring tests still pass. Behavior should NOT change.

## Key Principle

**Tests define behavior.** If you need to change test assertions, that's NOT a refactor—it's a behavior change. Use the normal workflow instead.

## Modes

### Interactive Mode (default — user runs `/refactor`)

User specifies what to refactor. Follow the manual workflow below.

### Automated Mode (build loop — no user input)

Called by the build loop or `/tdd` after GREEN phase. The agent autonomously identifies and applies refactoring opportunities. No user prompts. See "Automated Refactor" section below.

---

## Manual Workflow

### Before Changing Anything
1. Identify which tests cover the code being refactored
2. Run those tests to confirm they pass
3. Note the test IDs for reference

### During Refactoring
1. Make incremental changes
2. Do NOT change test assertions
3. If tests fail, the refactor broke something—fix it
4. Keep commits small and focused

### After Refactoring
1. Run tests again to verify all pass
2. Update test docs ONLY if test names/organization changed
3. Do NOT update feature specs (behavior didn't change)

---

## Automated Refactor (Build Loop / TDD Integration)

When called by the build loop or `/tdd` as Phase 3 (post-GREEN):

1. Read the source files that were just implemented
2. Read the test files to understand what's covered
3. **Identify opportunities** — scan for:
   - Functions longer than ~30 lines that could be extracted
   - Duplicated code blocks
   - Poor variable/function names
   - Overly complex conditionals (nested if/else chains)
   - Missing type annotations
   - Dead code or unused imports
   - Magic numbers/strings that should be constants
4. **Apply refactoring** — make incremental changes
5. **Run tests after each change** — they MUST still pass
6. **If tests fail** — revert that specific change, move on to next opportunity
7. **Do NOT change test assertions**
8. **Do NOT update feature specs** (behavior didn't change)
9. **Commit**: `refactor: clean up {feature name}`

**Output signals** (for build loop):
```
REFACTOR_COMPLETE: {brief summary of changes}
```
Or if no refactoring was needed:
```
REFACTOR_SKIPPED: code already clean
```

---

## Safe Refactoring Examples

✅ **Good refactors** (tests stay the same):
- Extract function/class/module
- Rename variables (not public API)
- Simplify conditionals
- Remove dead code
- Improve performance
- Add type annotations

❌ **Not refactors** (need behavior change workflow):
- Change function return values
- Modify public API signatures
- Change validation rules
- Alter data structures

## Red Flags

Stop and reassess if:
- You need to change test assertions
- You're adding new test cases
- The feature spec seems wrong
- You're "fixing" a test to make it pass

These indicate behavior changes, not refactoring.

## Example Usage

### Manual
```
/refactor extract date formatting into a utility
```

### Automated (build loop prompt)
```
Refactor the source files for "user profile". Clean up the code —
extract functions, simplify, improve naming. Tests MUST still pass.
```

