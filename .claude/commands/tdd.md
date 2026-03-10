---
description: Run the full TDD cycle (Red-Green-Refactor) from an approved spec
---

Build feature from approved spec: $ARGUMENTS

## Instructions

### 0. Find the Spec
- Search `.specs/features/**/*.feature.md` for matching spec (by path or frontmatter `feature:`)
- If no spec found → error: "No spec found. Run `/spec-first {feature}` first."

### 1. RED — Write Failing Tests
1. Read the spec and ALL Gherkin scenarios
2. Write tests covering every scenario (happy path, edge cases, error states)
3. Tests should FAIL initially
4. Update frontmatter: `status: tested`, add test files to `tests: []`

### 2. GREEN — Implement Until Tests Pass
1. Implement incrementally using design tokens
2. Loop until ALL tests pass
3. Update frontmatter: `status: implemented`, add components to `components: []`
4. Do NOT update roadmap status (that's done after all verification passes)

### 3. Drift Check — Layer 1 (Self-Check)
1. Re-read Gherkin scenarios, compare to implementation
2. Check for behaviors in code not in spec (and vice versa)
3. Fix any drift, ensure tests still pass

### 4. REFACTOR — Clean Up
1. Extract functions, simplify, improve naming, remove duplication
2. Do NOT change test assertions
3. Tests MUST still pass after each change
4. If tests fail, fix the refactor (don't change tests)

### 5. Drift Check — Layer 1b (Post-Refactor)
1. Re-verify spec↔code alignment after refactoring
2. Check that refactoring didn't subtly change behavior
3. Fix any drift, ensure tests pass

### 6. Compound
1. Run `/compound` to extract learnings
2. Feature-specific → spec's `## Learnings`
3. Cross-cutting → `.specs/learnings/{category}.md`

### 7. Commit
1. Regenerate mapping: `./scripts/generate-mapping.sh`
2. Commit: `feat: {feature name} (TDD: red-green-refactor)`
3. Output signals:
   ```
   FEATURE_BUILT: {feature name}
   SPEC_FILE: {path to .feature.md file}
   SOURCE_FILES: {comma-separated source file paths}
   ```
