# Bug Fix Mode

Investigate and fix a bug with proper regression testing.

## Workflow

### 1. Understand
- Check `.specs/features/` for expected behavior
- If no spec exists, ask: "What should the correct behavior be?"

### 2. Locate
- Find relevant tests in `.specs/test-suites/`
- Identify if existing tests should have caught this

### 3. Reproduce
- Write a failing test that captures the bug
- This test should fail BEFORE the fix

### 4. Fix
- Make the minimal code change to fix the bug
- Avoid unrelated refactoring

### 5. Verify
- Run the new test - it should pass now
- Run related tests - they should still pass

### 6. Document
- Add the test to the test suite doc in `.specs/test-suites/`
- Use format: `{PREFIX}-{NUM} | Regression: {bug description}`
- Add entry to change log

## If No Spec Exists

If there's no feature spec defining expected behavior:
1. I'll ask what the correct behavior should be
2. Add the scenario to the feature spec
3. Then proceed with the fix

This ensures we document the expected behavior for future reference.

## Example Usage

User: "/fix-bug the date formatter returns incorrect timezone"

I will:
1. Check `.specs/features/` for date formatting behavior
2. Check `.specs/test-suites/` for existing date tests
3. Write a failing test for this specific bug
4. Fix the date calculation
5. Verify the test passes
6. Document the regression test

