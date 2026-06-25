# Spec-Init: Discover and Queue Codebase for Documentation

Scan an existing codebase, understand its structure, and create a documentation queue. This command performs **discovery only** — it does not write specs or tests.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           PHASE 1: DISCOVERY                             │
│  Build complete inventory of codebase. Group files by domain.            │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        PHASE 2: OUTPUT QUEUE                             │
│   Write .specs/doc-queue.md + .specs/codebase-summary.md                 │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
         "Queue ready. Run ./scripts/doc-loop-local.sh --continue
          to process, or /document-code {feature} one at a time."
```

## When to Use

- First time adopting spec-driven workflow on existing project
- Onboarding legacy codebase into documentation
- After `git auto` or `git sdd` on an existing project
- Before running `doc-loop-local.sh` to review what will be documented

## Behavior

### Discovery (Autonomous)

This command runs autonomously. No stopping. No questions.

| Situation | Automatic Behavior |
|-----------|-------------------|
| **Monorepo** | Process all packages. Each gets its own domain grouping. |
| **Existing `.specs/`** | Merge mode — check existing coverage, only queue uncovered files. |
| **Large codebase (100+)** | Scan everything. Group aggressively (max 5 files per item). |
| **No clear domains** | Use directory path as domain. |
| **Source file with no exports** | Skip (config/entry). Log in discovery. |

---

## Step 1: Environment Detection

Automatically detect:
- **Language/Framework**: TypeScript, Python, Go, React, Next.js, Django, etc.
- **Test Runner**: Jest, Vitest, pytest, go test (from config files)
- **Test Patterns**: `*.test.ts`, `test_*.py`, `*_test.go`
- **Source Directories**: `src/`, `app/`, `lib/`, `components/`
- **Existing Design System**: Look for CSS variables, Tailwind config, theme files
- **Migration Tooling**: Look for an ORM/migration tool (Prisma, Drizzle, Knex, TypeORM, Alembic, Django, Rails, Flyway, Sqitch, golang-migrate, raw SQL) and a migrations directory

## Step 2: Scan and Categorize

Scan codebase and categorize every source file:

| Included | Excluded |
|----------|----------|
| Components (`*.tsx`, `*.vue`) | Config files (`*.config.ts`) |
| Services/utilities (`*.ts`, `*.py`) | Type definitions (`*.d.ts`) |
| API routes | Entry points (`index.ts` re-exports) |
| Hooks | Test files themselves |
| Models/schemas | Generated files, `node_modules`, `dist` |

## Step 3: Check Existing Coverage

For each source file, check:
- [ ] Feature spec exists (`.specs/features/{domain}/{name}.feature.md`)
- [ ] Test file exists
- [ ] Test doc exists (`.specs/test-suites/{path}/{Name}.tests.md`)
- [ ] Mapping entry exists

## Step 4: Group by Domain

Group related files into documentation items:
- A component + its hook → one item
- An API route + its service → one item
- A set of utility functions → one item
- Max 5 files per group (split if more)

Order: infrastructure/utils first → features → pages/views last.

## Step 5: Run Baseline (Read-Only)

Run the existing test suite and build check as **read-only reporting**. Do NOT fix anything.

Record:
- Test suite: X passing, Y failing (pre-existing)
- Build status: clean or N errors (pre-existing)

## Step 6: Create Codebase Summary

Create `.specs/codebase-summary.md`:

```markdown
# Codebase Summary

## Project Overview
[Auto-generated description]

## Environment
- Language: [detected]
- Framework: [detected]
- Test Runner: [detected]

## Directory Structure
[Key directories and purposes]

## Baseline Status
- Test suite: X passing, Y failing (pre-existing)
- Build: clean | N errors (pre-existing)

## Coverage Analysis
**Total Files in Scope**: X
**Already Documented**: Y
**Items Queued**: Z
```

## Step 7: Create Documentation Queue

Create `.specs/doc-queue.md` with this **exact format** (parsed by automation):

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
| 1 | auth | src/lib/auth.ts, src/middleware.ts | service | ⬜ |
| 2 | deals | src/components/DealCard.tsx | component | ⬜ |
```

## Step 8: Detect/Create Design System

Check for existing design system:
- CSS custom properties in stylesheets
- Tailwind config with custom theme
- Theme files (colors, tokens, etc.)

If found: Create `.specs/design-system/tokens.md` documenting existing tokens.
If not found: Create default tokens file.

## Step 9: Detect & Document Migration Strategy

If the project has a database (a migrations directory and/or ORM config was detected in Step 1), run the `/infer-migrations` flow as part of discovery — same "detect existing → document it" pattern as Step 8 for the design system.

1. Follow `/infer-migrations` (read the migrations dir, infer tool, naming, ordering, reversibility, backfill habits, expand-contract patterns).
2. Write `.specs/migrations.md` (the playbook) and `.cursor/rules/migrations.mdc` (thin, always-applied summary).
3. Reconcile the detected apply command against `MIGRATION_CMD` in `.env.local` and flag any mismatch.

If no database tooling is detected, skip this step and note it (do not create the file).

This means new specs created after `/spec-init` automatically get a `## Migration Plan` for schema changes, and `/tdd` can run its migration verify step against the documented conventions.

---

## After Discovery

Print the summary and tell the user:

```
═══════════════════════════════════════════════════════════════════
                    DISCOVERY COMPLETE
═══════════════════════════════════════════════════════════════════

Environment
├── Language: TypeScript
├── Framework: Next.js 14
├── Test Runner: Jest
└── Test Command: npm test

Baseline
├── Tests: 142 passing, 6 failing (pre-existing)
└── Build: clean

Migrations
├── Tool: Prisma (prisma/migrations/)
└── Playbook: .specs/migrations.md

Documentation Queue
├── Items to document: 42
├── Already documented: 23
└── Queue written to: .specs/doc-queue.md

Next steps:
├── Review the queue: .specs/doc-queue.md
├── Process automatically: ./scripts/doc-loop-local.sh --continue
└── Process one at a time: /document-code {feature}
═══════════════════════════════════════════════════════════════════
```

---

## Scoped Runs

| Mode | Behavior |
|------|----------|
| `/spec-init` (default) | Full repo scan |
| `/spec-init components/` | Only scan the specified directory |

---

## Output Files Created

| File | Purpose |
|------|---------|
| `.specs/codebase-summary.md` | Overview of entire codebase + baseline status |
| `.specs/doc-queue.md` | Ordered list of items to document (parsed by doc-loop-local.sh) |
| `.specs/design-system/tokens.md` | Design tokens (if not exists) |
| `.specs/migrations.md` | Migration playbook (if a database is detected) |
| `.cursor/rules/migrations.mdc` | Always-applied migration rules summary (if a database is detected) |

---

## What This Does NOT Do

- Does NOT write specs or tests (that's `/document-code` or `doc-loop-local.sh`)
- Does NOT fix failing tests (that's pre-existing tech debt)
- Does NOT modify source code
- Does NOT run the full processing loop (old behavior — use `doc-loop-local.sh` instead)

---

## Integration with doc-loop-local.sh

This command creates the queue. The script processes it:

```
/spec-init                              # Creates doc-queue.md (in IDE)
  ↓ (review queue)
./scripts/doc-loop-local.sh --continue  # Processes queue (in terminal)
```

Or skip the review step:

```
./scripts/doc-loop-local.sh             # Does its own discovery + processes
```
