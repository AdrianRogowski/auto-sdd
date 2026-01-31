# /compound - Extract Session Learnings

Extract and persist learnings from the current coding session.

## Instructions

1. **Reflect** on what was accomplished this session
2. **Identify** patterns, gotchas, decisions, and bug fixes
3. **Categorize** each learning:
   - Feature-specific → add to that spec's `## Learnings` section
   - Cross-cutting → add to `.specs/learnings/{category}.md`:
     - Testing patterns → `testing.md`
     - Performance → `performance.md`
     - Security → `security.md`
     - API & Data → `api.md`
     - Design System → `design.md`
     - General → `general.md`
   - Also add brief entry to `.specs/learnings/index.md` under "Recent Learnings"
4. **Update** the `updated:` date in any modified spec frontmatter
5. **Commit** changes with message `compound: learnings from [brief description]`
6. **Summarize** what was captured and where

## Learning Format

```markdown
### YYYY-MM-DD
- **Pattern**: [What worked well]
- **Gotcha**: [Edge case or pitfall]
- **Decision**: [Choice made and rationale]
```

## Category Routing

| Type | Where |
|------|-------|
| Mocking, assertions, test structure | `testing.md` |
| Lazy loading, caching, bundle size | `performance.md` |
| Auth, cookies, validation, secrets | `security.md` |
| Endpoints, error handling, data shapes | `api.md` |
| Tokens, components, a11y, responsive | `design.md` |
| Everything else | `general.md` |
