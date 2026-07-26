# Update Test Documentation

Regenerate or update test suite documentation to match actual tests.

## When to Use

- After adding multiple tests without documenting
- When test docs are out of sync with test files
- During cleanup/maintenance
- After a large refactor

## Behavior

For the specified test file (or all if none specified):

1. **Read** the test file(s) in the project's test directory (wherever tests live — `tests/`, `src/**/__tests__/`, `*.test.*` colocated, etc.)
2. **Extract** all test names and describe blocks
3. **Update/create** the corresponding `.specs/test-suites/` doc
4. **Assign** sequential test IDs if missing
5. **Update** the coverage summary table
6. **Add** entry to change log with today's date
7. **Update** `.specs/test-suites/README.md` totals if needed

## Test Doc Format

```markdown
# Test Suite: [Component]

**Test File**: `{path to test file}`
**Component**: `{path to component/module under test}`
**Last Updated**: YYYY-MM-DD

## Coverage Summary
| Category | Tests | Status |
|----------|-------|--------|
| Rendering | X | ✅ |
| Interactions | X | ✅ |
| **Total** | **X** | ✅ |

## Test Catalog

### [Category]

| ID | Test Name | Verifies |
|----|-----------|----------|
| XX-001 | test name | what it checks |

## Change Log
| Date | Change | Tests Affected |
|------|--------|----------------|
| YYYY-MM-DD | Description | IDs |
```

## Example Usage

- `/update-test-docs for DealCard` → Updates DealCard.tests.md
- `/update-test-docs for all components` → Updates all component test docs
- `/update-test-docs` → I'll ask which file(s) to update

