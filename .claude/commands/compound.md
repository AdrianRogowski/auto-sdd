---
description: Extract and persist learnings from the current coding session
---

# /compound - Extract Session Learnings

When the user says `/compound`, extract learnings from the current session and persist them.

## Behavior

### 1. Reflect on This Session

Review what was accomplished in this session:
- What patterns worked well?
- What gotchas or edge cases were discovered?
- What decisions were made and why?
- What would be done differently next time?
- Any bugs encountered and how they were fixed?

**Actively look for failure signals** — these are the highest-value learnings:
- **Drift caught**: Did the drift check find mismatches between spec and code? What was the root cause?
- **Test retries**: Did tests fail multiple times before passing? What was wrong — bad test, bad implementation, or bad spec?
- **Human corrections**: Did the user correct the spec, reject a scenario, or redirect the implementation? What was the gap in understanding?
- **Spec revisions**: Was the spec updated during implementation because it was wrong or incomplete? What was missing?
- **Build/lint failures**: Did the build or linter fail? What pattern caused it?

Failure signals prevent future agents from repeating the same mistakes. They are **more valuable** than success patterns.

### 2. Categorize Learnings

#### Feature-Specific Learnings
Learnings that apply to a specific feature go in that feature's spec:
- Add to the `## Learnings` section of the relevant `.specs/features/{domain}/{feature}.feature.md`
- Format:
  ```markdown
  ### YYYY-MM-DD
  - **Pattern**: [What worked well]
  - **Gotcha**: [Edge case or pitfall discovered]
  - **Decision**: [Choice made and why]
  ```

#### Cross-Cutting Learnings
Learnings that apply across features go in `.specs/learnings/` by category:

| Category | File |
|----------|------|
| Testing patterns | `.specs/learnings/testing.md` |
| Performance | `.specs/learnings/performance.md` |
| Security | `.specs/learnings/security.md` |
| API & Data | `.specs/learnings/api.md` |
| Design System | `.specs/learnings/design.md` |
| General | `.specs/learnings/general.md` |

Also add a brief entry to `.specs/learnings/index.md` under "Recent Learnings".

### 3. Update Files

1. **Feature spec(s)**: Add learnings to `## Learnings` section
2. **Cross-cutting**: Add to the appropriate `.specs/learnings/{category}.md` file
3. **Index**: Add brief entry to `.specs/learnings/index.md` under "Recent Learnings"
4. **Frontmatter**: Update `updated:` date in any modified specs

### 4. Commit Changes

```bash
git add .specs/
git commit -m "compound: learnings from [brief session description]"
```

### 5. Summarize

Tell the user:
- How many learnings were captured
- Which files were updated
- Which categories were added to

---

## Learning Types

| Type | Example | Where to Store |
|------|---------|----------------|
| **Pattern** | "Always debounce form validation to avoid API spam" | Feature spec or `learnings/general.md` |
| **Gotcha** | "Safari autofill doesn't trigger onChange events" | Feature spec |
| **Decision** | "Using httpOnly cookies for auth (XSS protection)" | `learnings/security.md` |
| **Bug Fix** | "Fixed race condition by adding loading state check" | Feature spec |
| **Performance** | "Memoize expensive calculations in useMemo" | `learnings/performance.md` |
| **Testing** | "Mock timers for debounce tests" | `learnings/testing.md` |
| **Failure (drift)** | "Spec said X but code did Y because spec was ambiguous" | Feature spec + `learnings/general.md` |
| **Failure (test-retry)** | "Tests failed 3x because router wasn't mocked" | Feature spec + `learnings/testing.md` |
| **Failure (human-correction)** | "User rejected scenario — anti-persona feature crept in" | Feature spec + `learnings/general.md` |
| **Failure (spec-gap)** | "Tech design didn't specify pagination strategy" | Feature spec + `learnings/general.md` |
| **Failure (build)** | "Build failed because of missing type export" | Feature spec + appropriate category |

### Failure Signal Format

Failure signals have a specific format — they must include root cause and a "fix for future" directive:

```markdown
### YYYY-MM-DD
- **Failure (drift)**: Spec said "redirect to dashboard on login" but implementation redirected to profile page. Root cause: spec didn't specify the redirect target URL. **Fix for future specs**: Always specify redirect targets explicitly in Gherkin Then clauses.
- **Failure (test-retry)**: Tests failed 3x because component used `useRouter` which wasn't mocked. **Fix for future tests**: Always mock Next.js router in component test setup files.
- **Failure (human-correction)**: User rejected "Advanced Settings" scenario — anti-persona feature. **Fix for future specs**: Re-read anti-persona before adding "advanced" or "power user" scenarios.
```

---

## Learnings Folder Structure

```
.specs/learnings/
├── index.md        # Summary + recent learnings
├── testing.md      # Mocking, assertions, test patterns
├── performance.md  # Optimization, lazy loading, caching
├── security.md     # Auth, cookies, validation
├── api.md          # Endpoints, data handling, errors
├── design.md       # Tokens, components, accessibility
└── general.md      # Other patterns
```

### Format for Category Files

Add learnings under the appropriate section with a date:

```markdown
## [Section Name]

### YYYY-MM-DD
- **Pattern**: [What worked well]
- **Gotcha**: [Edge case or pitfall]

### YYYY-MM-DD
- **Decision**: [Choice made and rationale]
```

### Format for index.md Recent Learnings

Add brief entries under "Recent Learnings":

```markdown
## Recent Learnings

### YYYY-MM-DD
- **Testing**: Mock fetch globally in setupTests.ts
- **Security**: Use httpOnly cookies for auth tokens
```

---

## When to Run

**Automatic**: `/compound` runs automatically at the end of every `/tdd` cycle — both Normal and Full mode. You don't need to invoke it separately after TDD.

**Manual**: Run `/compound` standalone at the end of non-TDD sessions (debugging, prototyping, refactoring) to capture learnings.

## When NOT to Compound

- If the session was just reading/exploring (no implementation)
- If no new learnings or failure signals were discovered
- If learnings are already documented

---

## Example Output

```markdown
## Compound Summary

**Session**: Implemented user login feature

### Learnings Captured: 4 (2 patterns, 1 gotcha, 1 failure signal)

#### Feature-Specific (added to login.feature.md)
- **Gotcha**: Safari autofill requires onBlur handler as backup
- **Pattern**: Debounce email validation to 300ms
- **Failure (test-retry)**: Tests failed 2x because `useRouter` wasn't mocked in test setup. **Fix for future tests**: Always mock Next.js router in component tests.

#### Cross-Cutting (added to learnings/)
- **Testing**: Mock fetch globally in setupTests.ts → `testing.md`
- **Failure (test-retry)**: Mock Next.js router in component tests → `testing.md`

### Files Updated
- `.specs/features/auth/login.feature.md`
- `.specs/learnings/testing.md`
- `.specs/learnings/index.md`
```
