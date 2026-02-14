---
description: Create a feature spec with Gherkin scenarios and ASCII mockups (TDD step 1)
---

Create the feature specification for: $ARGUMENTS

## Mode Detection

Check if `--full` or `--auto` flag is present in the arguments:

| Mode | Behavior |
|------|----------|
| Normal (default) | Stop for approval at each step |
| Full (`--full` or `--auto`) | Complete TDD cycle without pauses |

## Instructions

1. **Check/Create Design System**
   - If no `.specs/design-system/tokens.md` exists, create default tokens
   - Inform user of created files

2. **Create Feature Spec with YAML Frontmatter**
   - Create `.specs/features/{domain}/{feature}.feature.md`
   - Include YAML frontmatter:
     ```yaml
     ---
     feature: Feature Name
     domain: domain-name
     source: path/to/feature.tsx
     tests: []
     components: []
     design_refs: []
     status: stub
     created: YYYY-MM-DD
     updated: YYYY-MM-DD
     ---
     ```
   - Write Gherkin scenarios: happy path, edge cases, error states, loading states
   - Include empty `## Learnings` section at the end

3. **Create ASCII Mockup**
   - Add `## UI Mockup` section with ASCII art
   - Show component layout, interactive elements, states
   - Reference design tokens

4. **Create Component Stubs**
   - If mockup references components not in `.specs/design-system/components/`, create stubs

5. **Pause Point**
   - **Normal Mode**: STOP - ask "Does this look right? Ready to write tests?"
   - **Full Mode**: Skip pause, immediately proceed to tests

## After Approval (or immediately in Full Mode)

**Step 2: Write Tests**
1. Write failing tests covering all scenarios
2. Update frontmatter: `status: tested`, add test files to `tests: []`
3. **Normal Mode**: Ask "Tests written (failing). Ready to implement?"
4. **Full Mode**: Skip pause, immediately implement

**Step 3: Implement**
1. Implement until tests pass using design tokens
2. Update frontmatter: `status: implemented`, add components to `components: []`

**Step 4: Self-Check Drift (Full Mode: automatic, Normal Mode: optional)**
1. Re-read your Gherkin scenarios
2. Verify each scenario is implemented in the code you wrote
3. Check for behaviors in code not in spec (or vice versa)
4. Fix any drift: update spec to match code, or fix code to match spec
5. Ensure tests still pass

**Step 5: Compound (Full Mode runs automatically)**
1. Run `/compound` to extract learnings
2. Update `.specs/learnings/{category}.md`

**Step 6: Commit (Full Mode only)**
1. Regenerate mapping: `./scripts/generate-mapping.sh`
2. Commit all changes: `feat: {feature name} (full TDD cycle)`
3. Output these signals (REQUIRED for build loop):
   ```
   FEATURE_BUILT: {feature name}
   SPEC_FILE: {path to .feature.md file}
   SOURCE_FILES: {comma-separated source file paths}
   ```
