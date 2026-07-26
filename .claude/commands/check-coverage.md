# Check Test Coverage

Compare feature specs against test suites to find gaps.

## When to Use

- Before a release to verify coverage
- After writing a feature spec to plan tests
- During code review
- When auditing test quality

## Behavior

1. **Read** the specified feature spec (or all specs if none specified)
2. **Read** the related test suite docs
3. **Compare** Gherkin scenarios to documented tests
4. **Report** coverage status

## Output Format

```markdown
## Coverage Report: [Feature Name]

**Feature Spec**: .specs/features/{path}
**Test Suite**: .specs/test-suites/{path}

### Covered Scenarios ✅
| Scenario | Tests |
|----------|-------|
| [Scenario name] | XX-001, XX-002 |

### Uncovered Scenarios ⚠️
| Scenario | Suggested Tests |
|----------|-----------------|
| [Scenario name] | Test for X, Test for Y |

### Orphan Tests ❓
Tests without corresponding scenarios (consider adding to spec):
| Test ID | Test Name |
|---------|-----------|
| XX-010 | [test name] |

### Coverage Score
- Scenarios: X/Y covered (Z%)
- Recommendation: [action needed]
```

## After Report

I'll ask: "Want me to add tests for the uncovered scenarios?"

If yes, I'll:
1. Write the missing tests
2. Update the test suite documentation
3. Re-run the coverage check to confirm

## Example Usage

- `/check-coverage for deals` → Check all deal-related features
- `/check-coverage for DealCard` → Check specific component
- `/check-coverage` → Check entire project (may be slow)

