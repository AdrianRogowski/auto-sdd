# Document Existing Code (Reverse TDD)

Generate specs and tests from existing code. Use when code was written first and needs documentation.

```
CODE → SPEC → TEST
 │      ▲      ▲
 │      │      │
 └──────┴──────┘ (document what exists)
```

## When to Use

- Code was written without specs (vibe coding, prototyping, legacy code)
- Quick iteration happened after initial implementation
- Onboarding existing features into spec-driven workflow
- After `/prototype` when you want to skip `/formalize` and just document
- Called by `doc-loop-local.sh` in batch mode

## Philosophy: Document, Don't Fix

- **Be honest**: Document what the code does, even if it seems wrong
- **Flag issues**: Note potential bugs as "Potential Issues", don't fix them
- **No code changes**: Do NOT modify any source files. Only create `.specs/` and test files.
- **Passing tests**: Tests must pass against CURRENT code. If they don't, re-read the code.
- **One retry**: If tests fail, fix the TEST (not the source). If still failing, log as discovered issue.

## Behavior

### 1. Read the Code
- Analyze the specified component/module
- Understand what it does, not what it should do
- Identify all behaviors, edge cases handled, error states

### 2. Generate Feature Spec
- Create Gherkin scenarios that describe **actual current behavior**
- Document edge cases the code handles
- Note any implicit business rules
- Flag any behaviors that seem unintentional

### 3. Write Passing Tests
- Write tests that **pass against current implementation**
- Cover all identified behaviors
- These are not aspirational—they document reality
- **If tests fail**: Re-read the code and fix the test (you misread something)
- **If still failing after one retry**: Log as "discovered behavior gap" in the spec, move on

### 4. Update Documentation
- Create/update `.specs/test-suites/*.tests.md`
- Update `.specs/mapping.md` (or run `./scripts/generate-mapping.sh`)
- Add change log entries

## Key Difference from `/spec-first`

| Aspect | `/spec-first` | `/document-code` |
|--------|---------------|------------------|
| Flow | Spec → Test → Code | Code → Spec → Test |
| Tests | Written to fail first | Written to pass |
| Spec | Defines desired behavior | Documents actual behavior |
| Use | New features | Existing code |

## Modes

### Single Component (default)
```
/document-code the DealCard component
```
Documents one component/module with full detail.

### Batch Mode (used by doc-loop-local.sh)
When given multiple related files (a domain group):
```
/document-code auth — src/lib/auth.ts, src/middleware.ts, src/hooks/useAuth.ts
```
1. Read ALL listed files together for cross-file context
2. Create one or more specs depending on how behaviors group
3. Write tests covering all files
4. More efficient than documenting each file separately

### Recent Changes
```
/document-code the changes I just made
```
Look at recent edits, document new/changed behavior, update existing specs.

## Output Format

```markdown
## Code Documentation: [Component/Feature]

**Source File(s)**: [paths]
**Analyzed**: [date]

### Behaviors Documented

| Behavior | Spec Scenario | Test ID |
|----------|---------------|---------|
| Renders user name | Display user info | USR-001 |
| Shows loading state | Loading indicator | USR-002 |
| Handles empty data | Empty state | USR-003 |

### Files Created/Updated

- `.specs/features/{domain}/{feature}.feature.md` - Feature spec
- `.specs/test-suites/{path}.tests.md` - Test documentation
- `tests/frontend/{path}.test.tsx` - Actual tests

### Potential Issues Found

⚠️ These behaviors might be unintentional:
- Returns `undefined` instead of `null` for missing users
- No error handling for network failures

### Discovered Behavior Gaps

🔍 These couldn't be fully tested (logged for review):
- Concurrent session handling requires Redis (can't test locally)
- Race condition in debounced search — needs integration test

### Suggested Follow-ups

- [ ] Verify edge case X is intentional
- [ ] Consider adding error boundary
- [ ] Review with team: should Y behavior change?

---

**Tests written and passing. Documentation complete.**
```

## Output Signals (for automation)

When called by `doc-loop-local.sh`, output these signals at the end:

```
DOC_COMPLETE: {item number}
SPEC_FILES: {comma-separated spec paths}
TEST_FILES: {comma-separated test paths}
```

Or if partially documented:
```
DOC_PARTIAL: {item number} — {reason}
```

Or if failed:
```
DOC_FAILED: {item number} — {reason}
```

## Important Notes

1. **This is not TDD** - We're documenting reality, not defining desired behavior
2. **Tests should pass** - Unlike `/spec-first`, tests are written to pass immediately
3. **Be honest in specs** - Document what code does, even if it seems wrong
4. **Flag issues** - Note potential bugs or unintentional behaviors for review
5. **Don't fix code** - Source files are read-only. Only create documentation and test files.
6. **One retry max** - If tests fail after re-reading the code, log and move on
