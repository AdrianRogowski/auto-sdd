# Spec-Init: Bootstrap Spec-Driven Workflow

Initialize the spec-driven development workflow on an existing codebase. This command scans the entire codebase and generates specs, tests, and documentation until 100% coverage is achieved.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           PHASE 1: DISCOVERY                             │
│  Build complete inventory of codebase. Understand what needs to be done. │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                         PHASE 2: PROCESSING LOOP                         │
│   Pick uncovered file → Generate spec → Write tests → Document → Repeat  │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          PHASE 3: VERIFICATION                           │
│   Run all tests. Compare actual vs documented. Confirm 100% coverage.    │
└──────────────────────────────────────────────────────────────────────────┘
```

## When to Use

- First time adopting spec-driven workflow on existing project
- Onboarding legacy codebase into documentation
- After `git auto` or `git sdd` on an existing project

## Behavior

### Autonomous Execution

This command runs **autonomously**. No stopping. No questions. Loop until done.

| Situation | Automatic Behavior |
|-----------|-------------------|
| **Monorepo** | Process all packages. Each gets its own domain grouping. |
| **Existing `.specs/`** | Merge mode—add new, preserve existing. Never delete. |
| **Large codebase (100+)** | Process everything. No shortcuts. |
| **Test fails after 3 attempts** | Log to `needs-review.md`, continue to next file. |
| **Complex file can't be analyzed** | Create minimal spec, flag for review, continue. |
| **Mixed naming conventions** | Detect per-directory, adapt accordingly. |
| **No clear domains** | Use directory path as domain. |
| **Source file with no exports** | Skip (config/entry). Log in discovery. |

---

## Phase 1: Discovery

### 1.1 Environment Detection

Automatically detect:
- **Language/Framework**: TypeScript, Python, Go, React, Next.js, Django, etc.
- **Test Runner**: Jest, Vitest, pytest, go test (from config files)
- **Test Patterns**: `*.test.ts`, `test_*.py`, `*_test.go`
- **Source Directories**: `src/`, `app/`, `lib/`, `components/`
- **Existing Design System**: Look for CSS variables, Tailwind config, theme files

### 1.2 Build Work Queue

Scan codebase and categorize every source file:

| Included | Excluded |
|----------|----------|
| Components (`*.tsx`, `*.vue`) | Config files (`*.config.ts`) |
| Services/utilities (`*.ts`, `*.py`) | Type definitions (`*.d.ts`) |
| API routes | Entry points (`index.ts` re-exports) |
| Hooks | Test files themselves |
| Models/schemas | Generated files, `node_modules`, `dist` |

### 1.3 Check Existing Coverage

For each source file, check:
- [ ] Feature spec exists (`.specs/features/{domain}/{name}.feature.md`)
- [ ] Test file exists
- [ ] Tests pass
- [ ] Test doc exists (`.specs/test-suites/{path}/{Name}.tests.md`)
- [ ] Mapping entry exists

### 1.4 Detect/Create Design System

Check for existing design system:
- CSS custom properties in stylesheets
- Tailwind config with custom theme
- Theme files (colors, tokens, etc.)

If found: Create `.specs/design-system/tokens.md` documenting existing tokens
If not found: Create default tokens file

### 1.5 Create Codebase Summary

Create `.specs/codebase-summary.md`:

```markdown
# Codebase Summary

## Project Overview
[Auto-generated description]

## Directory Structure
[Key directories and purposes]

## Components Catalog
| Component | Location | Purpose | Has Tests |
|-----------|----------|---------|-----------|

## Test Coverage Analysis
**Total Files in Scope**: X
**Files with Tests**: Y
**Starting Coverage**: Z%

## Design System Status
[Detected/Created with token summary]
```

### 1.6 Discovery Output

```
═══════════════════════════════════════════════════════════════════
                        PHASE 1: DISCOVERY COMPLETE
═══════════════════════════════════════════════════════════════════

Environment
├── Language: TypeScript
├── Framework: Next.js 14
├── Test Runner: Jest
└── Test Command: npm test

Work Queue
├── ✅ Fully covered: 23 files
├── 🟡 Partially covered: 12 files (have test but missing spec)
├── 🔴 No coverage: 30 files
└── Total in scope: 65 files

Starting Coverage: 35% (23/65)

Design System: Created default tokens
└── .specs/design-system/tokens.md

Ready to begin processing loop...
```

---

## Phase 2: Processing Loop

For each uncovered file in the queue:

```
┌─────────────────────────────────────────────────────────────────┐
│ PROCESSING: components/user-card.tsx (15/65)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Read & Understand                                      │
│  └─▶ Read source file, understand exports, props, behavior      │
│                                                                 │
│  Step 2: Generate Feature Spec                                  │
│  └─▶ Create .specs/features/{domain}/{file}.feature.md          │
│  └─▶ Gherkin scenarios for all behaviors                        │
│  └─▶ ASCII mockup (if UI component)                             │
│                                                                 │
│  Step 3: Write Tests (PASSING)                                  │
│  └─▶ Create test file if missing                                │
│  └─▶ Write tests that PASS against current implementation       │
│  └─▶ Cover all scenarios from feature spec                      │
│                                                                 │
│  Step 4: Run Tests                                              │
│  └─▶ Execute test file                                          │
│  └─▶ Verify all tests pass                                      │
│  └─▶ If fail: fix tests, re-run (max 3 attempts)                │
│  └─▶ If still fail: log to needs-review.md, continue            │
│                                                                 │
│  Step 5: Document Test Suite                                    │
│  └─▶ Create .specs/test-suites/{path}/{Name}.tests.md           │
│  └─▶ Parse test file for describe blocks and test names         │
│  └─▶ Assign test IDs                                            │
│                                                                 │
│  Step 6: Mapping (Auto-Generated)                               │
│  └─▶ YAML frontmatter triggers auto-regeneration                │
│                                                                 │
│  Step 7: Create Component Stubs (if UI)                         │
│  └─▶ If component, create stub in design-system/components/     │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│ ✅ COMPLETE: components/user-card.tsx                           │
│ Progress: 16/65 (25%) ████████░░░░░░░░░░░░░░░░░░░░░░░░         │
└─────────────────────────────────────────────────────────────────┘
```

### Progress Tracking

After each file:

```markdown
## Progress Update

| Metric | Value |
|--------|-------|
| Files processed | 16/65 |
| Coverage | 25% → 26% |
| Tests written | 142 |
| Tests passing | 142 ✅ |

### Just Completed
- `components/user-card.tsx`
  - Feature spec: `.specs/features/users/user-card.feature.md`
  - Test file: `tests/components/UserCard.test.tsx` (9 tests)
  - Test doc: `.specs/test-suites/components/UserCard.tests.md`

### Up Next
- `components/user-profile.tsx`
```

---

## Phase 3: Verification

### 3.1 Run Full Test Suite

```bash
npm test  # or pytest, go test, etc.
```

### 3.2 Verify Coverage Matrix

| Source File | Spec | Test File | Tests Pass | Test Doc | Mapping | Status |
|-------------|------|-----------|------------|----------|---------|--------|
| `components/user-card.tsx` | ✅ | ✅ | ✅ (9/9) | ✅ | ✅ | ✅ |

### 3.3 Reconcile Test Counts

Compare documented test counts vs actual test runner output.

### 3.4 Final Output

```
═══════════════════════════════════════════════════════════════════
                    FINAL COVERAGE: 97%
═══════════════════════════════════════════════════════════════════

Files in scope:        65
Fully covered:         63  ████████████████████████████████░░
Needs attention:        2

Feature specs:         65/65 (100%) ✅
Test files:            65/65 (100%) ✅
Tests passing:        285/287 (99%) ⚠️
Test documentation:    65/65 (100%) ✅
Mapping entries:       65/65 (100%) ✅

Design System
├── Tokens: ✅ Created
└── Component stubs: 12 created (pending documentation)

Files needing review: .specs/needs-review.md

Total time: 19m 39s
```

---

## Key Differences from `/spec-first`

| Aspect | `/spec-init` | `/spec-first` |
|--------|--------------|---------------|
| When | Existing codebase | New features |
| Tests | Written to PASS | Written to FAIL first |
| Spec | Documents actual behavior | Defines desired behavior |
| Design System | Detects or creates | References or creates |
| Scope | Entire codebase | Single feature |
| Interaction | Autonomous loop | Pause for approval |

---

## Scoped Runs

The command can be invoked with different scopes:

| Mode | Behavior |
|------|----------|
| `/spec-init` (default) | Full repo scan, process everything |
| `/spec-init components/` | Only process the specified directory |
| `/spec-init --continue` | Only process uncovered files (resume) |
| `/spec-init --untested` | Skip files that already have tests |

---

## Output Files Created

| File | Purpose |
|------|---------|
| `.specs/codebase-summary.md` | Overview of entire codebase |
| `.specs/features/**/*.feature.md` | Feature specs for each file |
| `.specs/test-suites/**/*.tests.md` | Test documentation |
| `.specs/design-system/tokens.md` | Design tokens (if not exists) |
| `.specs/design-system/components/*.md` | Component stubs |
| `.specs/mapping.md` | Links everything together |
| `.specs/needs-review.md` | Files that couldn't be fully covered |

---

## Example Session

```
User: /spec-init

═══════════════════════════════════════════════════════════════════
                        PHASE 1: DISCOVERY
═══════════════════════════════════════════════════════════════════

[Detecting environment...]
✓ TypeScript + Next.js 14 detected
✓ Jest test runner (jest.config.js)
✓ Test command: npm test

[Scanning for design system...]
✓ Found Tailwind config with custom colors
✓ Created .specs/design-system/tokens.md from existing theme

[Building work queue...]
✓ 65 source files in scope
✓ 23 already have tests (35% starting coverage)
✓ 42 need tests written

Work queue ready. Starting processing loop...

═══════════════════════════════════════════════════════════════════
                     PHASE 2: PROCESSING LOOP
═══════════════════════════════════════════════════════════════════

[1/65] components/button.tsx
  ✓ Feature spec created
  ✓ Tests exist, verified passing (5/5)
  ✓ Test doc created
  ✓ Component stub created
  ✓ Mapping updated
  Progress: 2% ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

[2/65] components/user-card.tsx
  ✓ Feature spec created
  ✓ Tests written (9 tests)
  ✓ Tests passing (9/9)
  ✓ Test doc created
  ✓ Component stub created
  ✓ Mapping updated
  Progress: 3% ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

... (continues autonomously) ...

═══════════════════════════════════════════════════════════════════
                      PHASE 3: VERIFICATION
═══════════════════════════════════════════════════════════════════

[Running full test suite...]
✓ npm test completed
✓ 285 tests run, 283 passing, 2 failing

[Verifying coverage matrix...]
✓ 65/65 have feature specs
✓ 65/65 have test files
✓ 63/65 have all tests passing
✓ 65/65 have test documentation
✓ 65/65 in mapping.md

═══════════════════════════════════════════════════════════════════
                    FINAL COVERAGE: 97%
═══════════════════════════════════════════════════════════════════

2 files need manual review. See .specs/needs-review.md

Total time: 19m 39s
```
