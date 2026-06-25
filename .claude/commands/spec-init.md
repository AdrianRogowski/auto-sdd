---
description: Discover codebase structure and create documentation queue (discovery only, no specs/tests)
---

Scan this codebase and create a documentation queue. Discovery only — do NOT write specs or tests.

## Autonomous Execution

Run continuously until complete. No stopping for questions.

## Steps

1. **Detect Environment**: Language, framework, test runner, test patterns, source directories, ORM/migration tooling
2. **Scan Codebase**: Categorize all source files (include components, services, APIs, hooks; exclude configs, types, generated, node_modules, dist)
3. **Check Existing Coverage**: For each file check if spec, test, and docs already exist in .specs/
4. **Group by Domain**: Related files that should be documented together (component + hook, API route + service). Max 5 files per group. Order: infrastructure first, features middle, pages last.
5. **Run Baseline (read-only)**: Run existing test suite and build check. Record results but do NOT fix anything. This is pre-existing status.
6. **Detect/Create Design System**: Look for CSS vars, Tailwind config, theme files. Create `.specs/design-system/tokens.md` if needed.
7. **Detect & Document Migration Strategy**: If a database is detected (migrations dir / ORM config), run the `/infer-migrations` flow — infer the project's migration conventions and write `.specs/migrations.md` + `.cursor/rules/migrations.mdc`. Skip (and note) if no DB tooling exists.
8. **Create `.specs/codebase-summary.md`**: Project overview, environment, directory structure, baseline status, coverage analysis
9. **Create `.specs/doc-queue.md`** with this EXACT format (parsed by automation):

```markdown
# Documentation Queue

Generated: YYYY-MM-DD
Environment: {language} + {framework}, {test runner}
Scope: full codebase
Total files: {X}
Already documented: {Y}
Items to document: {Z}

## Baseline

Test suite: {X passing, Y failing} (pre-existing, not our problem)
Build status: {clean | N errors} (pre-existing)

## Queue

| # | Domain | Files | Type | Status |
|---|--------|-------|------|--------|
| 1 | {domain} | {comma-separated file paths} | {type} | ⬜ |
| 2 | {domain} | {file paths} | {type} | ⬜ |
```

## Scope

- Default: Full repo scan
- With path argument: Only scan that directory

## What This Does NOT Do

- Does NOT write specs or tests (use /document-code or doc-loop-local.sh)
- Does NOT fix failing tests (pre-existing tech debt)
- Does NOT modify source code

## After Discovery

Print summary and tell the user:

```
Next steps:
├── Review the queue: .specs/doc-queue.md
├── Process automatically: ./scripts/doc-loop-local.sh --continue
└── Process one at a time: /document-code {feature}
```
