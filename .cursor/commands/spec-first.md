# Spec-First Mode (TDD + Design Flow)

Create the feature specification with Gherkin scenarios and ASCII mockups without implementing anything. This is step 1 of the TDD flow.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   DESIGN    │ ──▶ │    SPEC     │ ──▶ │    TEST     │ ──▶ │ IMPLEMENT   │
│ (tokens +   │     │ (Gherkin +  │     │  (failing)  │     │ (loop until │
│  stubs)     │     │  mockup)    │     │             │     │ tests pass) │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      ▲                   │
      │                   │
      └───────────────────┘
      (create if not exists)
```

## Behavior

### 1. Check/Create Design System

If this is the first feature (no `.specs/design-system/tokens.md` exists):
- Auto-create `.specs/design-system/tokens.md` with default tokens
- Auto-create `.cursor/rules/design-tokens.mdc` cursor rule
- Inform user: "Created default design system. Customize tokens.md as needed."

### 2. Create Feature Spec

- Create `.specs/features/{domain}/{feature}.feature.md`
- Write detailed **Gherkin scenarios** covering:
  - Happy path
  - Edge cases
  - Error states
  - Loading states (if applicable)

### 3. Create ASCII Mockup

- Add `## UI Mockup` section with ASCII art showing:
  - Component layout and structure
  - Key interactive elements
  - States (default, hover, active, disabled, loading, error)
- Reference design tokens where applicable

### 4. Create Component Stubs

If the mockup references components that don't exist in `.specs/design-system/components/`:
- Create **stub** files for each new component
- Stubs include: name, purpose, status "pending implementation"

### 5. Do NOT Implement

- Do NOT write any implementation code
- Do NOT write tests yet (that's step 2)
- STOP and wait for user approval

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

After creating the spec, provide this summary:

```markdown
## Summary

**Feature**: [Name]
**Spec File**: `.specs/features/{domain}/{feature}.feature.md`
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

## Next Steps After Approval

When user says "go", "yes", "looks good", or approves:

### Step 2: Write Failing Tests
1. Write tests that cover ALL Gherkin scenarios
2. Tests should **FAIL** initially (no implementation yet)
3. Document tests in `.specs/test-suites/{path}.tests.md`
4. Update spec frontmatter: `status: tested`, add test files to `tests: []`
5. mapping.md will auto-regenerate via hook
6. Ask: "Tests written (failing). Ready to implement?"

### Step 3: Implement
When user approves implementation:
1. Implement feature incrementally
2. Use design tokens from `.specs/design-system/tokens.md`
3. Follow component patterns from design system
4. Run tests frequently
5. Loop until all tests pass
6. Update spec frontmatter: `status: implemented`, add components to `components: []`

### Step 4: Document Components
After implementation:
1. Fill in component stubs with actual implementation details
2. Update stub status from "📝 Stub" to "✅ Documented"
3. Or use `/design-component {name}` to auto-document

### Step 5: Compound Learnings (Optional)
At end of session:
1. Run `/compound` to extract learnings
2. Adds patterns/gotchas to spec's `## Learnings` section
3. Cross-cutting patterns go to `.specs/learnings/{category}.md`

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

1. **Check design system** - Create if not exists
2. **Create spec file**: `.specs/features/users/profile-page.feature.md`
3. **Write scenarios**:
   - Display profile information
   - Edit profile (happy path)
   - Edit profile validation errors
   - Avatar upload
   - Cancel editing
4. **Create ASCII mockups**:
   - View mode
   - Edit mode
   - Loading state
   - Error states
5. **Create component stubs**:
   - Avatar component
   - ProfileForm component
   - EditableField component
6. **List design tokens** used
7. **Identify questions** (image size limits? required fields?)
8. **STOP** and wait for approval

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
