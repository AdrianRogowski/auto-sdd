---
description: Bootstrap spec-driven workflow on existing codebase (autonomous, runs to completion)
---

Initialize the spec-driven development workflow on this codebase.

## Autonomous Execution

Run continuously until complete. No stopping for questions.

## Phase 1: Discovery

1. **Detect Environment**: Language, framework, test runner, test patterns
2. **Scan Codebase**: Categorize all source files (include components, services, APIs, hooks; exclude configs, types, generated)
3. **Check Existing Coverage**: For each file check if spec, test, and docs exist
4. **Detect/Create Design System**: Look for CSS vars, Tailwind config, theme files. Create `.specs/design-system/tokens.md`
5. **Create Codebase Summary**: `.specs/codebase-summary.md` with project overview

## Phase 2: Processing Loop

For each uncovered file:
1. Read and understand the code
2. Generate feature spec with Gherkin scenarios
3. Write PASSING tests (document reality, not aspirations)
4. Run tests, fix if needed (max 3 attempts, then log to needs-review.md)
5. Document test suite
6. Add YAML frontmatter to spec (mapping auto-generates)
7. Create component stubs if UI

Show progress after each file.

## Phase 3: Verification

1. Run full test suite
2. Verify coverage matrix
3. Reconcile test counts
4. Output final coverage report

## Scope Options

- Default: Full repo scan
- With path argument: Only process that directory
