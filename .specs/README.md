# Specs Directory

This directory contains the spec-driven development documentation for this project.

## Directory Structure

```
.specs/
├── features/              # Gherkin feature specifications
│   └── {domain}/          # Grouped by domain/feature area
│       └── {feature}.feature.md
│   └── auto/              # Auto-generated specs (overnight)
│
├── test-suites/           # Test documentation
│   └── {mirrors test structure}
│       └── {Component}.tests.md
│
├── design-system/         # Design tokens and component patterns
│   ├── tokens.md          # Color, spacing, typography tokens
│   ├── components/        # Component pattern documentation
│   │   └── {component}.md
│   └── layouts/           # Page/section layout patterns
│       └── {layout}.md
│
├── learnings/             # Cross-cutting patterns (by category)
│   ├── index.md           # Summary + recent learnings
│   ├── testing.md         # Mocking, assertions, test patterns
│   ├── performance.md     # Optimization, lazy loading, caching
│   ├── security.md        # Auth, cookies, validation
│   ├── api.md             # Endpoints, data handling, errors
│   ├── design.md          # Tokens, components, accessibility
│   └── general.md         # Other patterns
│
├── mapping.md             # AUTO-GENERATED from spec frontmatter
├── codebase-summary.md    # Generated overview (after /spec-init)
├── needs-review.md        # Files needing manual attention
└── README.md              # This file
```

---

## File Conventions

### Feature Specs (`.feature.md`)

Location: `.specs/features/{domain}/{feature}.feature.md`

**Important:** Every feature spec must have YAML frontmatter for the auto-generated mapping.

```markdown
---
feature: Feature Name
domain: domain-name
source: path/to/implementation.tsx
tests:
  - tests/feature.test.ts
components:
  - ComponentName
design_refs:
  - .specs/design-system/components/button.md
status: stub | specced | tested | implemented
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Feature Name

**Source File**: `path/to/implementation.tsx`
**Design System**: `.specs/design-system/tokens.md`

## Feature: [Name]

### Scenario: [Name]
Given [precondition]
When [action]
Then [expected result]

## UI Mockup

[ASCII art representation]

## Component References

[Links to design system components]

## Learnings

<!-- Updated via /compound - patterns, gotchas, decisions -->
```

### Test Suite Docs (`.tests.md`)

Location: `.specs/test-suites/{path}/{Component}.tests.md`

```markdown
# Component Tests

**Test File**: `tests/{path}/{Component}.test.tsx`
**Component**: `{path}/{Component}.tsx`
**Feature Spec**: `.specs/features/{domain}/{feature}.feature.md`

## Test Coverage

| Test ID | Test Name | Scenario |
|---------|-----------|----------|
| CMP-001 | renders correctly | Display component |
| CMP-002 | handles click | User interaction |
```

### Component Docs (design system)

Location: `.specs/design-system/components/{component}.md`

```markdown
# Component Name

**Status**: 📝 Stub | ✅ Documented
**Source File**: `components/{name}.tsx`

## Purpose
[What this component does]

## Props / API
[Prop table]

## Variants
[Visual variations]

## Design Tokens Used
[Which tokens this component uses]
```

---

## Test ID Conventions

Use 2-3 letter prefixes for test IDs:

| Prefix | Component/Module |
|--------|------------------|
| UT | utils |
| API | api handlers |
| SVC | services |
| CMP | components |
| PG | pages |
| HK | hooks |

Example: `CMP-001`, `API-015`, `UT-003`

---

## Workflow

### New Features (Manual)

```
1. /spec-first {feature}      → Creates spec with YAML frontmatter
2. Review and approve
3. Tests written (failing)    → Update frontmatter: status: tested
4. Implement until tests pass → Update frontmatter: status: implemented
5. /compound                  → Extract learnings (optional)
6. /design-component {name}   → Fill in component stubs
```

### Overnight Autonomous

```
10:30 PM  nightly-review.sh   → Extract learnings from day's commits
11:00 PM  overnight-autonomous.sh → Scan Slack/Jira → Spec → Implement → PR
Morning   Review draft PRs     → Approve, request changes, or close
```

### Existing Codebase

```
1. /spec-init                 → Scans and documents everything
2. Review needs-review.md     → Fix any issues
3. /spec-first for new features going forward
```

### Bug Fixes

```
1. /fix-bug                   → Creates regression test
2. Update spec if behavior gap found
3. Document new test
```

---

## Status Indicators

### Feature Specs
- No indicator = active/current

### Test Suites
- ✅ All tests passing
- ⚠️ Some tests failing
- 🔴 No tests yet

### Component Docs
- 📝 Stub (pending implementation)
- ✅ Documented
- ⚠️ Needs update (code changed)

---

## Mapping File

The `mapping.md` file is **auto-generated** from feature spec YAML frontmatter.

**Do NOT edit mapping.md directly.** Instead:
1. Update the feature spec's YAML frontmatter
2. Run `./scripts/generate-mapping.sh` (or it auto-runs via Cursor hook)

The mapping provides a routing table for the agent to find specs, tests, and components.

---

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/spec-first` | Create feature spec + mockup |
| `/spec-init` | Bootstrap existing codebase |
| `/compound` | Extract learnings from session |
| `/design-tokens` | Manage design tokens |
| `/design-component` | Document component patterns |
| `/check-coverage` | Find gaps in coverage |
| `/catch-drift` | Detect spec ↔ code drift |
| `/verify-test-counts` | Reconcile test counts |

---

## Learnings Folder

Cross-cutting learnings are organized by category in `.specs/learnings/`:

| File | Category |
|------|----------|
| `index.md` | Summary + recent learnings (read this first) |
| `testing.md` | Mocking, assertions, test structure |
| `performance.md` | Lazy loading, caching, bundle size |
| `security.md` | Auth, cookies, validation, secrets |
| `api.md` | Endpoints, error handling, data shapes |
| `design.md` | Tokens, components, a11y, responsive |
| `general.md` | Everything else |

Feature-specific learnings go in each spec's `## Learnings` section.

Run `/compound` at the end of sessions to extract and route learnings.

---

## Best Practices

1. **Spec before code** - Always create the feature spec first
2. **Use frontmatter** - Every spec needs YAML frontmatter for mapping
3. **Update status** - Change frontmatter status as you progress (stub → specced → tested → implemented)
4. **ASCII mockups** - Include mockups for UI features
5. **Reference tokens** - Use design token names in mockups
6. **Extract learnings** - Run `/compound` at end of sessions
7. **Don't edit mapping.md** - It's auto-generated from frontmatter
8. **Document components** - Fill in stubs after implementation
