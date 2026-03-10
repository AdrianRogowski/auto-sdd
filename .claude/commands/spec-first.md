---
description: Create or update a feature spec with Gherkin scenarios and ASCII mockups (TDD step 1)
---

Create or update the feature specification for: $ARGUMENTS

## Mode Detection

Check if `--full` or `--auto` flag is present in the arguments:

| Mode | Behavior |
|------|----------|
| Normal (default) | Stop for approval at each step |
| Full (`--full` or `--auto`) | Complete Red-Green-Refactor TDD cycle without pauses (create OR update, then RED → GREEN → drift check → REFACTOR → drift check → compound → commit) |

## Instructions

### 0. Resolve Spec File (Create vs Update)
- Parse feature description from args (strip `--full`, `--auto`)
- Search `.specs/features/**/*.feature.md` for matching spec (by path or frontmatter `feature:`)
- **If match found** → UPDATE mode: read spec, preserve status/tests/components/created, update scenarios/mockup, set updated date. **Full mode**: continue through tests → implement → compound → commit
- **If no match** → CREATE mode: proceed to step 1

### 1. Load Context

**Before writing anything**, read what exists:

- **Personas** (`.specs/personas/*.md`): Load primary persona's vocabulary, patience level, frustrations. Load anti-persona to know what NOT to build. If no personas exist, note it: "⚠️ No personas found. Run /personas for better specs."
- **Design tokens** (`.specs/design-system/tokens.md`): If missing or still template, auto-create via `/design-tokens` flow (reads vision + personas, determines personality, produces tailored tokens). If exists, read for token names and personality.
- **Vision** (`.specs/vision.md`): For additional context about the app.

### 2. Create or Update Feature Spec with YAML Frontmatter
- CREATE: Create `.specs/features/{domain}/{feature}.feature.md`
- UPDATE: Revise existing spec, preserve status/tests/components
- Include YAML frontmatter:
  ```yaml
  ---
  feature: Feature Name
  domain: domain-name
  source: path/to/feature.tsx
  tests: []
  components: []
  design_refs: []
  personas: [primary, anti-persona]
  status: stub
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
  ---
  ```
- Write Gherkin scenarios: happy path, edge cases, error states, loading states
- **Use persona vocabulary** in all scenario text and UI labels
- **Match flow length to persona patience level** (Very Low → 1-2 interactions for primary task)
- Include empty `## Learnings` section at the end

### 3. Create ASCII Mockup
- Add `## UI Mockup` section with ASCII art
- Show component layout, interactive elements, states
- Reference design tokens
- **Use persona vocabulary** in all labels and placeholder text

### 4. Add User Journey
- Add `## User Journey` section (3-5 lines)
- Show where user comes from, this feature, where they go next
- Prevents orphaned features with no entry/exit

### 5. Create Component Stubs
- If mockup references components not in `.specs/design-system/components/`, create stubs

### 6. Persona Revision Pass

After drafting, re-read through persona eyes and revise:

1. **Walk through the mockup as the primary persona.** Would they understand every label? Would they know what to click first?
2. **Check flow length** against patience level (Very Low: 1-2 interactions, Low: 2-3, Medium: up to 5, High: complex ok)
3. **Check vocabulary.** Replace any developer-speak with persona's words.
4. **Check against anti-persona.** Cut any scenario that's really for the anti-persona.
5. **Track what you changed** for the report.

### 7. Pause Point
- **Normal Mode**: STOP — show spec summary plus persona revision notes (what you changed and why). Ask "Does this look right? Run `/tdd` when ready, or say 'go ahead' to start the Red-Green-Refactor cycle."
- **Full Mode**: Skip pause, immediately proceed to the TDD cycle

## After Approval (or immediately in Full Mode)

**Both create and update paths continue through the full Red-Green-Refactor loop.** The steps below follow the `/tdd` command flow.

**Step 2: RED — Write Failing Tests**
1. Write failing tests covering all scenarios
2. Update frontmatter: `status: tested`, add test files to `tests: []`
3. Proceed immediately to GREEN (no pause between RED and GREEN)

**Step 3: GREEN — Implement Until Tests Pass**
1. Implement until tests pass using design tokens
2. Update frontmatter: `status: implemented`, add components to `components: []`
3. Do NOT update roadmap status — that happens after all verification passes

**Step 4: Drift Check — Layer 1 (Self-Check)**
1. Re-read your Gherkin scenarios
2. Verify each scenario is implemented in the code you wrote
3. Check for behaviors in code not in spec (or vice versa)
4. Fix any drift, ensure tests still pass

**Step 5: REFACTOR — Clean Up Code**
1. Extract functions, simplify, improve naming, remove duplication
2. Do NOT change test assertions
3. Tests MUST still pass after each change
4. If tests fail, fix the refactor (don't change tests)

**Step 6: Drift Check — Layer 1b (Post-Refactor)**
1. Re-verify spec↔code alignment after refactoring
2. Check that refactoring didn't subtly change behavior
3. Fix any drift, ensure tests pass

**Step 7: Compound (Full Mode runs automatically)**
1. Run `/compound` to extract learnings from the final (refactored) code
2. Update `.specs/learnings/{category}.md`

**Step 8: Commit (Full Mode only)**
1. Regenerate mapping: `./scripts/generate-mapping.sh`
2. Commit all changes: `feat: {feature name} (TDD: red-green-refactor)`
3. Output these signals (REQUIRED for build loop):
   ```
   FEATURE_BUILT: {feature name}
   SPEC_FILE: {path to .feature.md file}
   SOURCE_FILES: {comma-separated source file paths}
   ```
