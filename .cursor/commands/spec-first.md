# Spec-First Mode (TDD + Design Flow)

Create or update the feature specification with Gherkin scenarios and ASCII mockups. This is step 1 of the TDD flow.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   DESIGN    │ ──▶ │    SPEC     │ ──▶ │    TEST     │ ──▶ │ IMPLEMENT   │
│ (tokens +   │     │ (Gherkin +  │     │  (failing)  │     │ (loop until │
│  stubs)     │     │  mockup)    │     │             │     │ tests pass) │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      ▲                   │
      │                   │
      └───────────────────┘
      (create if not exists, update if exists)
```

## Mode Detection

Check if the user included `--full` or `--auto` flag:

| Command | Mode | Behavior |
|---------|------|----------|
| `/spec-first user auth` | Normal | Stop for approval at each step |
| `/spec-first user auth --full` | Full | Complete TDD cycle without pauses |
| `/spec-first --full user auth` | Full | Same (flag position flexible) |
| `/spec-first user auth --auto` | Full | Alias for --full |

### Full Mode Behavior

If `--full` or `--auto` flag is present, execute the ENTIRE TDD cycle without stopping:

1. Create OR update spec (see Step 0)
2. **Do NOT pause** - immediately write failing tests (or update tests if spec was updated)
3. **Do NOT pause** - immediately implement until tests pass
4. Update all frontmatter (status: implemented)
5. Run `/compound` to extract learnings
6. Commit with descriptive message

**Skip all "Ready to...?" prompts in full mode. Both create and update paths continue through the full loop.**

### Normal Mode Behavior (default)

Stop for user approval at each step (existing behavior).

---

## Behavior

### 0. Resolve Spec File (Create vs Update)

**Before creating anything**, determine whether to create or update:

1. Parse the feature description from arguments (strip `--full`, `--auto`).
2. Search for an existing spec:
   - List `.specs/features/**/*.feature.md`
   - Derive candidate path from input: e.g. "user profile" → `users/user-profile.feature.md`, "Auth: Signup" → `auth/signup.feature.md`
   - For each spec, check if frontmatter `feature:` matches (case-insensitive, normalize spaces/hyphens)
   - If a file exists at the derived path, it's a match
3. **If match found** → **UPDATE mode**:
   - Read the existing spec
   - Preserve: `status`, `tests`, `components`, `created`, `design_refs`
   - Update: scenarios, mockup, description per user's request
   - Set `updated: YYYY-MM-DD`
   - **Full mode**: continue through tests → implement → compound → commit (same as create)
4. **If no match** → **CREATE mode** (proceed to Step 1)

### 1. Check/Create Design System

If this is the first feature (no `.specs/design-system/tokens.md` exists):
- Auto-create `.specs/design-system/tokens.md` with default tokens
- Auto-create `.cursor/rules/design-tokens.mdc` cursor rule
- Inform user: "Created default design system. Customize tokens.md as needed."

### 2. Create or Update Feature Spec

**CREATE mode:**
- Create `.specs/features/{domain}/{feature}.feature.md`
- Write detailed **Gherkin scenarios** covering:
  - Happy path
  - Edge cases
  - Error states
  - Loading states (if applicable)

**UPDATE mode:**
- Update the existing spec file
- Revise scenarios and mockup per user's request
- Add new scenarios if user is expanding the feature
- Preserve existing `status`, `tests`, `components` in frontmatter
- Set `updated: YYYY-MM-DD`

### 3. Create or Update ASCII Mockup

- Add or update `## UI Mockup` section with ASCII art showing:
  - Component layout and structure
  - Key interactive elements
  - States (default, hover, active, disabled, loading, error)
- Reference design tokens where applicable

### 4. Create Component Stubs

If the mockup references components that don't exist in `.specs/design-system/components/`:
- Create **stub** files for each new component
- Stubs include: name, purpose, status "pending implementation"

### 5. Pause Point (Normal Mode Only)

**If Normal Mode (no --full flag):**
- Do NOT write any implementation code
- Do NOT write tests yet (that's step 2)
- STOP and wait for user approval

**If Full Mode (--full flag present):**
- Skip this pause
- Immediately proceed to write tests (Step 2)
- Then implement (Step 3)
- Then run /compound
- Then commit

---

## Feature Spec Format

Every feature spec has **YAML frontmatter** that powers the auto-generated mapping table.

```markdown
---
feature: Feature Name
domain: domain-name
source: path/to/feature.tsx
tests: []
components: []
design_refs: []
status: stub    # stub → specced → tested → implemented
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Feature Name

**Source File**: `path/to/feature.tsx` (planned)
**Design System**: `.specs/design-system/tokens.md`

## Feature: [Name]

[Brief description of what this feature does]

### Scenario: [Happy path name]
Given [precondition]
When [user action]
Then [expected result]
And [additional expectation]

### Scenario: [Edge case name]
Given [precondition]
When [user action]
Then [expected result]

### Scenario: [Error state name]
Given [precondition that causes error]
When [user action]
Then [error handling behavior]

## UI Mockup

### Default State
```
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Header / Title                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────┐  ┌─────────────────────────────────────────┐   │
│  │         │  │ Content area                            │   │
│  │  Image  │  │                                         │   │
│  │         │  │ Secondary text or description           │   │
│  └─────────┘  └─────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │  Primary Action     │  │  Secondary Action   │          │
│  └─────────────────────┘  └─────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### Loading State
```
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────┐    │
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────┐  ┌─────────────────────────────────────────┐   │
│  │ ░░░░░░░ │  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│   │
│  │ ░░░░░░░ │  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│   │
│  └─────────┘  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Error State
```
┌─────────────────────────────────────────────────────────────┐
│  ┌─ Error (border: error, bg: error-light) ─────────────┐   │
│  │  ⚠️ Error message describing what went wrong         │   │
│  │  [Retry Button]                                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Component References

| Component | Status | File |
|-----------|--------|------|
| Button | ✅ Exists | `.specs/design-system/components/button.md` |
| Card | 📝 Stub created | `.specs/design-system/components/card.md` |
| Input | 📝 Stub created | `.specs/design-system/components/input.md` |

## Design Tokens Used

- `color-primary` - Primary action buttons
- `color-error` - Error states
- `spacing-md` - Component padding
- `radius-lg` - Card border radius

## Open Questions

- [ ] Question about ambiguous requirement?
- [ ] Clarification needed on edge case?

## Suggested Test Cases

- [ ] Test happy path scenario
- [ ] Test edge case scenario
- [ ] Test error handling
- [ ] Test loading state
- [ ] Test accessibility (keyboard nav, screen reader)

## Learnings

<!-- This section grows over time via /compound -->
<!-- Add patterns, gotchas, and decisions discovered during implementation -->
```

---

## Output Format

After creating or updating the spec, provide this summary:

```markdown
## Summary

**Feature**: [Name]
**Spec File**: `.specs/features/{domain}/{feature}.feature.md`
**Mode**: [Created new / Updated existing]
**Design System**: [Created new / Using existing]

### Scenarios Documented
1. [Scenario 1] - Happy path
2. [Scenario 2] - Edge case
3. [Scenario 3] - Error handling

### UI Mockup Created
- Default state ✅
- Loading state ✅
- Error state ✅

### Component Stubs Created
- `.specs/design-system/components/card.md` (new)
- `.specs/design-system/components/input.md` (new)

### Design Tokens Referenced
- `color-primary`, `color-error`, `spacing-md`, `radius-lg`

### Open Questions
- [Question 1]?
- [Question 2]?

### Suggested Test Cases
- [ ] Test for scenario 1
- [ ] Test for scenario 2
- [ ] Test for scenario 3

---

**Does this look right? Ready to write tests?**
```

---

## Next Steps After Approval (or immediately in Full Mode)

**Normal Mode**: When user says "go", "yes", "looks good", or approves
**Full Mode**: Execute immediately without waiting for approval

### Step 2: Write Failing Tests (or Update Tests)
1. Write tests that cover ALL Gherkin scenarios (create new or update existing)
2. Tests should **FAIL** initially if no implementation yet (or fail if spec was updated and code doesn't match)
3. Document tests in `.specs/test-suites/{path}.tests.md`
4. Update spec frontmatter: `status: tested`, add test files to `tests: []`
5. Regenerate mapping: run `./scripts/generate-mapping.sh`
6. **Normal Mode**: Ask: "Tests written (failing). Ready to implement?"
7. **Full Mode**: Skip asking, proceed immediately to Step 3

### Step 3: Implement
**Normal Mode**: When user approves implementation
**Full Mode**: Execute immediately after tests
1. Implement feature incrementally
2. Use design tokens from `.specs/design-system/tokens.md`
3. Follow component patterns from design system
4. Run tests frequently
5. Loop until all tests pass
6. Update spec frontmatter: `status: implemented`, add components to `components: []`

### Step 4: Self-Check Drift (Full Mode: automatic, Normal Mode: optional)

Before documenting or extracting learnings, verify your implementation matches your spec:

1. Re-read the Gherkin scenarios you wrote in Step 1
2. For each scenario, verify the code you just wrote implements it
3. Check for behaviors you implemented that aren't in the spec
4. Check for scenarios in the spec that aren't implemented

**If drift found:**
- Update the spec to match what you actually built (document reality)
- Or fix the code to match the spec (if you missed something)
- Ensure tests still pass after any changes

**Why this matters:** This is Layer 1 of drift enforcement — a quick self-check while you still have full context. The build loop will run a separate Layer 2 check with a fresh agent afterward, but catching obvious drift here is cheaper.

### Step 5: Document Components
After implementation:
1. Fill in component stubs with actual implementation details
2. Update stub status from "📝 Stub" to "✅ Documented"
3. Or use `/design-component {name}` to auto-document

### Step 6: Compound Learnings
**Normal Mode**: Optional - user can run `/compound` at end of session
**Full Mode**: Automatically run /compound after implementation

1. Run `/compound` to extract learnings
2. Adds patterns/gotchas to spec's `## Learnings` section
3. Cross-cutting patterns go to `.specs/learnings/{category}.md`

### Step 7: Commit (Full Mode Only)

**Full Mode only** - after /compound completes:
1. Regenerate mapping: `./scripts/generate-mapping.sh`
2. Stage all changes: `git add .specs/ src/ tests/`
3. Commit with message: `feat: {feature name} (full TDD cycle)`
4. Report completion to user

**REQUIRED output signals** (for build loop parsing):
```
FEATURE_BUILT: {feature name}
SPEC_FILE: {path to .feature.md file}
SOURCE_FILES: {comma-separated paths to source files created/modified}
```

These signals enable the automated drift-check that runs after your commit.

---

## ASCII Mockup Guidelines

### Box Drawing Characters

```
┌─────┐   Top-left corner, horizontal line, top-right corner
│     │   Vertical line
└─────┘   Bottom-left corner, horizontal line, bottom-right corner
├─────┤   T-junctions for subdivisions
┼       Cross for grid intersections
```

### Component Indicators

```
[Button Text]     - Clickable button
(radio option)    - Radio button
[x] Checkbox      - Checked checkbox
[ ] Checkbox      - Unchecked checkbox
[Input field___]  - Text input
[Dropdown ▼]      - Select/dropdown
░░░░░░░░░░░░░░    - Loading skeleton
⚠️ ❌ ✅ ℹ️        - Status icons (use sparingly)
```

### Layout Patterns

```
# Side by side
┌───────┐  ┌───────┐
│ Left  │  │ Right │
└───────┘  └───────┘

# Stacked
┌─────────────────┐
│ Top             │
├─────────────────┤
│ Bottom          │
└─────────────────┘

# Nested
┌─────────────────────────────┐
│ Parent                      │
│  ┌─────────────────────┐    │
│  │ Child               │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
```

### Responsive Hints

```
# Mobile (320px)
┌───────────────┐
│ Stacked       │
│ Layout        │
└───────────────┘

# Desktop (1024px+)
┌───────────────────────────────────────────────────┐
│ Sidebar │ Main Content Area                       │
└───────────────────────────────────────────────────┘
```

---

## Example Usage

### User Request
```
/spec-first user profile page with avatar, bio, and edit functionality
```

### I Will:

1. **Resolve spec** - Search for existing spec matching "user profile"; if found, UPDATE mode; if not, CREATE mode
2. **Check design system** - Create if not exists
3. **Create or update spec file**: `.specs/features/users/profile-page.feature.md`
4. **Write scenarios**:
   - Display profile information
   - Edit profile (happy path)
   - Edit profile validation errors
   - Avatar upload
   - Cancel editing
5. **Create ASCII mockups**:
   - View mode
   - Edit mode
   - Loading state
   - Error states
6. **Create component stubs**:
   - Avatar component
   - ProfileForm component
   - EditableField component
7. **List design tokens** used
8. **Identify questions** (image size limits? required fields?)
9. **STOP** and wait for approval (Normal mode) or continue to tests → implement → compound → commit (Full mode)

---

## Greenfield Project (First Feature)

When `/spec-first` is the first command on a new project:

```
/spec-first landing page with hero section and signup form

[Detecting project state...]
⚠️ No design system found

Creating default design system:
✓ Created .specs/design-system/tokens.md
✓ Created .cursor/rules/design-tokens.mdc

You can customize tokens.md before or after implementation.
Proceeding with feature spec...
```

The default design tokens include:
- Color palette (primary, secondary, neutral, semantic)
- Typography scale
- Spacing scale
- Border radii
- Shadows
- Breakpoints

These can be customized at any point—the spec just references token names, not values.
