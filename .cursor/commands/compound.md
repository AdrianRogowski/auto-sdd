# /compound - Extract Session Learnings

Extract and persist learnings from the current coding session.

## When to Run

**Automatic**: `/compound` runs automatically at the end of every `/tdd` cycle — both Normal and Full mode. You don't need to invoke it separately after TDD.

**Manual**: Run `/compound` standalone at the end of non-TDD sessions (debugging, prototyping, refactoring) to capture learnings.

## Instructions

1. **Reflect** on what was accomplished this session
2. **Identify** patterns, gotchas, decisions, and bug fixes
3. **Actively look for failure signals** — these are the highest-value learnings:
   - **Drift caught**: Did the drift check find mismatches between spec and code? What was the root cause?
   - **Test retries**: Did tests fail multiple times before passing? What was wrong — bad test, bad implementation, or bad spec?
   - **Human corrections**: Did the user correct the spec, reject a scenario, or redirect the implementation?
   - **Spec revisions**: Was the spec updated during implementation because it was wrong or incomplete?
   - **Build/lint failures**: Did the build or linter fail? What pattern caused it?
   Failure signals prevent future agents from repeating the same mistakes. They are **more valuable** than success patterns.
4. **Categorize** each learning:
   - Feature-specific → add to that spec's `## Learnings` section
   - Cross-cutting → add to `.specs/learnings/{category}.md`:
     - Testing patterns → `testing.md`
     - Performance → `performance.md`
     - Security → `security.md`
     - API & Data → `api.md`
     - Design System → `design.md`
     - General → `general.md`
   - Also add brief entry to `.specs/learnings/index.md` under "Recent Learnings" (and "Recent Failure Signals" for failures)
5. **Update** the `updated:` date in any modified spec frontmatter
6. **Commit** changes with message `compound: learnings from [brief description]`
7. **Summarize** what was captured and where

## Learning Format

```markdown
### YYYY-MM-DD
- **Pattern**: [What worked well]
- **Gotcha**: [Edge case or pitfall]
- **Decision**: [Choice made and rationale]
- **Failure**: [What went wrong, root cause, how to avoid next time]
```

### Failure Signal Format

Failure signals have a specific format to make them actionable for future agents:

```markdown
### YYYY-MM-DD
- **Failure (drift)**: Spec said "redirect to dashboard on login" but implementation redirected to profile page. Root cause: spec didn't specify the redirect target URL, agent defaulted to /profile. **Fix for future specs**: Always specify redirect targets explicitly in Gherkin Then clauses.
- **Failure (test-retry)**: Tests failed 3x because component used `useRouter` which wasn't mocked in test setup. **Fix for future tests**: Always mock Next.js router in component test setup files.
- **Failure (human-correction)**: User rejected "Advanced Settings" scenario — anti-persona feature that crept in. **Fix for future specs**: Re-read anti-persona before adding any "advanced" or "power user" scenarios.
- **Failure (spec-gap)**: Technical design didn't specify pagination strategy. Agent implemented offset-based, but cursor-based was needed for real-time data. **Fix for future specs**: Always specify pagination strategy in Technical Design when listing endpoints exist.
```

## Category Routing

| Type | Where |
|------|-------|
| Mocking, assertions, test structure, test retries | `testing.md` |
| Lazy loading, caching, bundle size | `performance.md` |
| Auth, cookies, validation, secrets | `security.md` |
| Endpoints, error handling, data shapes | `api.md` |
| Tokens, components, a11y, responsive | `design.md` |
| Drift caught, spec gaps, human corrections | `general.md` |
| Everything else | `general.md` |
