# Verify Test Counts

Run the actual test suite and reconcile test counts with documentation.

```
ACTUAL TESTS ◄──── compare ────► DOCUMENTED COUNTS
     │                                  │
     │         discrepancies?           │
     │              │                   │
     └──────────────┼───────────────────┘
                    ▼
              RECONCILE
```

## When to Use

- Before a release to ensure docs are accurate
- After adding/removing multiple tests
- When test counts in docs seem wrong
- During periodic documentation maintenance
- After running `/update-test-docs` to verify

## Behavior

### 1. Run Test Suite
Execute the test runner to get actual counts:
```bash
yarn test --json --outputFile=test-results.json
# or
npm test -- --json --outputFile=test-results.json
```

### 2. Parse Results
Extract from test output:
- Total test count
- Tests per file
- Test names and describe blocks
- Pass/fail status

### 3. Compare Against Documentation
Check:
- `.specs/mapping.md` - Test ID Quick Reference section
- `.specs/test-suites/README.md` - Coverage Overview table
- Individual `.specs/test-suites/*.tests.md` files

### 4. Report Discrepancies
Show differences between actual and documented counts.

### 5. Reconcile
Update documentation to match reality (or flag tests that need attention).

## Output Format

```markdown
## Test Count Verification Report

**Test Runner**: Jest
**Executed**: [date]
**Total Tests**: 437 (docs say 422)

### Summary

| Source | Documented | Actual | Status |
|--------|------------|--------|--------|
| mapping.md | 422 | 437 | ⚠️ +15 |
| test-suites/README.md | 392 | 437 | ⚠️ +45 |

---

### Discrepancies by Test Suite

| Test Suite | Doc Count | Actual | Diff | Status |
|------------|-----------|--------|------|--------|
| lib/utils | 35 | 35 | 0 | ✅ |
| DealCard | 15 | 18 | +3 | ⚠️ New tests |
| Activities | 100 | 100 | 0 | ✅ |
| DealIntelligence | 69 | 84 | +15 | ⚠️ New tests |

### New Tests Not Documented

Found in `tests/frontend/components/DealCard.test.tsx`:
- `should show priority indicator` (not in DealCard.tests.md)
- `should handle rapid clicks` (not in DealCard.tests.md)
- `should truncate long names` (not in DealCard.tests.md)

Found in `tests/frontend/components/deal-intelligence/`:
- 15 new tests in DealScoring.test.ts (no test doc exists)

### Documented Tests Not Found

⚠️ These tests are documented but don't exist:
- NS-015: `should retry on network failure` (removed?)

---

### Reconciliation Plan

1. **Update mapping.md**: Change total from 422 → 437
2. **Update test-suites/README.md**: Change total from 392 → 437
3. **Update DealCard.tests.md**: Add 3 new test entries (DC-016, DC-017, DC-018)
4. **Create DealScoring.tests.md**: New test suite doc
5. **Remove NS-015**: Test no longer exists

**Apply these updates?**
```

## After Reconciliation

```markdown
## Test Counts Reconciled ✅

### Updates Applied

| File | Change |
|------|--------|
| mapping.md | Total: 422 → 437 |
| test-suites/README.md | Total: 392 → 437, added DealScoring row |
| DealCard.tests.md | Added DC-016, DC-017, DC-018 |
| DealScoring.tests.md | Created (15 tests) |
| lib/news.tests.md | Removed NS-015 |

### Current State
- **Total Tests**: 437
- **Documented**: 437
- **Coverage**: 100% documented ✅

---

**All test counts now match documentation.**
```

## Example Usage

### Full Verification
```
/verify-test-counts
```
Runs entire test suite and checks all documentation.

### Specific Test File
```
/verify-test-counts for DealCard
```
Only verifies DealCard tests against its documentation.

### Quick Count Check
```
/verify-test-counts --quick
```
Just compares totals without running tests (uses last test run or estimates from files).

### After Adding Tests
```
/verify-test-counts for the tests I just added
```
Focuses on recently changed test files.

## Configuration

The command needs to know your test runner:

```markdown
## Test Configuration (in specs-workflow.mdc)

- Test command: `yarn test`
- Test directory: `tests/frontend/`
- Test pattern: `*.test.{ts,tsx}`
- JSON output flag: `--json --outputFile=test-results.json`
```

## Common Issues

### Test Runner Doesn't Support JSON Output
I'll fall back to:
1. Parse test file AST to count `it()` / `test()` calls
2. Run tests and parse console output

### Tests Are Flaky
If some tests fail intermittently:
- Report passing test count
- Note: "X tests skipped/failed - verify they should be counted"

### Snapshot Tests
Snapshot tests are counted but noted:
- "Includes X snapshot tests (may inflate count)"

## Integration with Other Commands

- Run after `/update-test-docs` to verify accuracy
- Run after `/catch-drift` to ensure test counts updated
- Run before releases as part of quality checklist
- Combine with `/check-coverage` for full audit:
  ```
  /check-coverage then /verify-test-counts
  ```

## Why Both mapping.md and README.md?

This command helps maintain both files, but they serve different purposes:

| File | Primary Purpose | Audience |
|------|-----------------|----------|
| `mapping.md` | Feature ↔ Test ↔ Component links | Developers navigating code |
| `test-suites/README.md` | How to run tests, test index | QA, new developers |

If you find maintaining both tedious, consider:
1. Making README.md link to mapping.md for counts
2. Only keeping detailed counts in mapping.md
3. Using this command to sync them automatically

