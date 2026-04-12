---
description: Create or update a feature spec with Gherkin scenarios and ASCII mockups (TDD step 1)
---

# Spec-First Mode (TDD + Design Flow)

Create or update the feature specification for: $ARGUMENTS

```
Per feature:
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │    SPEC      │ ──▶ │  RED (test)  │ ──▶ │ GREEN (impl) │ ──▶ │  REFACTOR    │
  │ (Gherkin +   │     │  (failing)   │     │ (until tests │     │ (clean up,   │
  │  mockup +    │     │              │     │  pass)       │     │  tests must  │
  │  persona     │     │              │     │              │     │  still pass) │
  │  revision)   │     │              │     │              │     │              │
  └──────┬───────┘     └──────────────┘     └──────┬───────┘     └──────┬───────┘
         │                                         │                     │
      [PAUSE]                                      ▼                     ▼
    user approves                           ┌──────────────┐     ┌──────────────┐
    then /tdd                               │ DRIFT CHECK  │     │ DRIFT CHECK  │
                                            │ (layer 1)    │     │ (layer 1b)   │
                                            └──────────────┘     └──────┬───────┘
                                                                        │
                                                                        ▼
                                                                 ┌──────────────┐
                                                                 │  COMPOUND    │
                                                                 │ (learnings)  │
                                                                 └──────────────┘

Reads from: .specs/strategy.md, .specs/constitution.md, .specs/personas/, .specs/design-system/, .specs/learnings/index.md
Writes to: .specs/features/, .specs/design-system/components/ (stubs)
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

If `--full` or `--auto` flag is present, execute the ENTIRE Red-Green-Refactor TDD cycle without stopping:

1. Create OR update spec (see Step 0)
2. **Do NOT pause** - immediately write failing tests (RED)
3. **Do NOT pause** - immediately implement until tests pass (GREEN)
4. Self-check drift (Layer 1) — compare spec to code, fix mismatches
5. **REFACTOR** — clean up code, tests MUST still pass
6. Post-refactor drift check (Layer 1b) — re-verify spec↔code after refactor
7. Run `/compound` to extract learnings
8. Update all frontmatter (status: implemented)
9. Commit with descriptive message

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

### 1. Load Context

Before writing anything, read what exists. This shapes the entire spec.

#### Strategy

Read `.specs/strategy.md` if it exists and has real content (not just the template). The strategy provides:
- **Target customer** — who the feature should serve (validates feature is for the right segment)
- **Buying motion** — PLG features need fast time-to-value; enterprise features can have setup flows
- **Value proposition** — every feature should connect to the core value
- **Anti-goals** — features that serve anti-goals should be flagged or deferred

If strategy exists, the spec will include a **Strategy Alignment** section.
If no strategy exists, note it:

```
ℹ️ No strategy.md found. Spec will not include strategy alignment.
Run /strategy to define product positioning.
```

#### Constitution

Read `.specs/constitution.md` if it exists and has real rules (not just the template). Constitutional constraints are non-negotiable rules (security, data handling, error handling) that every feature must satisfy.

If constitution exists, the spec will include a **Constitutional Compliance** section.
If no constitution exists, note it:

```
ℹ️ No constitution.md found. Spec will not include compliance section.
Run /constitution to define project-wide constraints.
```

#### Personas (required for good specs)

Read all files in `.specs/personas/`:
- **Primary persona**: Drives vocabulary, flow complexity, and patience constraints
- **Anti-persona**: Reminds you what NOT to build

If no personas exist, check if `.specs/vision.md` has target user info. If so, mentally construct a persona from it. If neither exists, note it in the output:

```
⚠️ No personas found. Spec will use generic language.
Run /personas to create user personas for better specs.
```

#### Design System

If `.specs/design-system/tokens.md` doesn't exist or is still the unmodified template:
- Auto-create tokens via the `/design-tokens` flow (reads vision, determines personality, produces tailored tokens)
- Inform user: "Created design system. Customize tokens.md as needed."

If it exists and is customized, read it for token names and personality.

#### Learnings

Read `.specs/learnings/index.md` for cross-cutting patterns from previous features. This prevents repeating mistakes and ensures consistency with established patterns.

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

**When writing scenarios and mockups, use the personas:**
- Use the primary persona's vocabulary for all labels and copy (their words, not developer words)
- Match flow length to persona's patience level (Very Low → fewest possible steps)
- Reference the persona's frustrations as anti-patterns to avoid
- Ensure the happy path achieves the persona's success metric

Include YAML frontmatter:
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

Include empty `## Learnings` section at the end.

### 3. Add Technical Design

Add a `## Technical Design` section that bridges the gap between WHAT (Gherkin) and HOW (implementation). This reduces variance during the GREEN phase by giving the implementing agent a concrete contract instead of forcing it to invent data models and API shapes.

Include only what's relevant to this feature:

- **Data model**: Key entities, their fields, and relationships. What gets persisted vs. computed?
- **API contracts** (if applicable): Endpoints, request/response shapes, error codes. Skip for purely client-side features.
- **State management**: Where does state live? (URL params, local state, global store, server cache) What are the key state transitions?
- **Key dependencies**: Which existing modules/services does this feature depend on? What new ones does it introduce?

Keep it lightweight — a few bullet points per section, not a full design doc. The goal is to constrain implementation choices enough that two different agents would build roughly the same thing.

```markdown
## Technical Design

### Data Model
- `Deal` entity: { id, name, stage, value, assignee_id, created_at, updated_at }
- Relates to: `Contact` (many-to-one), `Activity` (one-to-many)

### API Contracts
- `POST /api/deals` — Create deal. Body: { name, stage, value, contact_id }. Returns: Deal object. Errors: 422 (validation), 401 (unauth)
- `GET /api/deals` — List deals. Query: ?stage=&sort=&page=. Returns: { data: Deal[], meta: { total, page } }

### State Management
- Deal list: server cache (React Query / SWR) keyed by filter params
- Form state: local component state, reset on submit success
- Optimistic update on stage change (revert on error)

### Key Dependencies
- Uses: AuthContext (current user), existing Button/Input components
- Introduces: DealService (new), useDealList hook (new)
```

### 4. Create or Update ASCII Mockup

- Add or update `## UI Mockup` section with ASCII art showing:
  - Component layout and structure
  - Key interactive elements
  - States (default, hover, active, disabled, loading, error)
- Reference design tokens where applicable
- Use persona vocabulary in all labels and placeholder text

### 5. Create Component Stubs

If the mockup references components that don't exist in `.specs/design-system/components/`:
- Create **stub** files for each new component
- Stubs include: name, purpose, status "pending implementation"

### 6. Persona Revision Pass

After drafting the spec, re-read it through each persona's eyes and revise:

1. **Walk through the mockup as the primary persona.** Would they understand every label? Would they know what to click first? Would any step make them hesitate or bail?

2. **Check flow length against patience level.**
   - Very Low: Can the primary task complete in 1-2 interactions?
   - Low: 2-3 interactions max
   - Medium: Up to 5 steps is fine
   - High: Complex flows are acceptable

3. **Check vocabulary.** Scan every label, button, heading, and error message. Replace any developer-speak with the persona's words.

4. **Check against anti-persona.** Is any scenario here really for the anti-persona? Cut it or defer to roadmap.

5. **Revise the spec.** Apply changes directly. Track what you changed so you can report it.

### 7. Add Strategy Alignment (if strategy.md exists)

If `.specs/strategy.md` has real content, add a `## Strategy Alignment` section:

```markdown
## Strategy Alignment

- **Target segment**: [From strategy — who this feature serves]
- **Buying motion fit**: [How this feature supports the buying motion — e.g., "Reduces time-to-value for PLG onboarding"]
- **Success metric**: [Which strategy success metric this feature moves]
- **Anti-goal check**: [Confirm this feature doesn't serve a stated anti-goal]
```

If the feature conflicts with strategy (e.g., building an enterprise admin panel when strategy says PLG), flag it:

```markdown
## Strategy Alignment

⚠️ **Potential misalignment**: This feature requires org-wide SSO setup before individual users get value.
Strategy says bottom-up PLG — individual adoption without IT involvement.
Consider: defer to Phase N, or redesign for individual-first with optional SSO upgrade.
```

### 8. Add Constitutional Compliance (if constitution.md exists)

If `.specs/constitution.md` has real rules, add a `## Constitutional Compliance` section.

For each rule in the constitution:
- Mark **✅ Applies** if the feature touches that constraint area, and note how it's addressed
- Mark **N/A** if the rule doesn't apply to this feature
- Mark **⚠️ CONFLICT** if the feature cannot satisfy a rule, with explanation

```markdown
## Constitutional Compliance

| Rule | Applies | Status |
|------|---------|--------|
| Auth: Server-side session verification | ✅ Yes | Addressed in Scenario: Auth redirect |
| Data: No PII in logs | ✅ Yes | Email redacted in error handler |
| API: Rate limiting on public endpoints | N/A | Internal endpoint only |
| Error: Graceful degradation | ✅ Yes | Addressed in Scenario: API failure |
```

### 9. Add User Journey

Add a brief `## User Journey` section (3-5 lines) showing where this feature sits in the user's workflow. What screen do they come from? Where do they go after?

```markdown
## User Journey

1. User is on the Dashboard (existing)
2. Clicks "New Deal" → **sees this feature's form**
3. Submits → redirected to Deal Detail page (future feature)
```

This prevents orphaned features with no way in and no way out.

### 10. Pause Point (Normal Mode Only)

**If Normal Mode (no --full flag):**
- Do NOT write any implementation code
- Do NOT write tests yet (that's step 2)
- STOP and wait for user approval

Show the spec summary plus persona revision notes:

```markdown
## Summary

**Feature**: [Name]
**Spec File**: `.specs/features/{domain}/{feature}.feature.md`
**Mode**: [Created new / Updated existing]
**Design System**: [Created new / Using existing]
**Personas Referenced**: [Primary: role, Anti: role]

### Scenarios Documented
1. [Scenario 1] - Happy path
2. [Scenario 2] - Edge case
3. [Scenario 3] - Error handling

### Strategy Alignment
- [Target segment + buying motion fit — or "No strategy.md found"]

### Constitutional Compliance
- [X of Y rules applicable, all addressed — or "No constitution.md found"]
- [Any CONFLICT flags noted here]

### Persona Revision Applied
- [What changed and why — e.g., "Renamed 'Query Parameters' → 'Search Filters' (broker vocabulary)"]
- [e.g., "Collapsed filter panel by default (Very Low patience — too many options upfront)"]
- [e.g., "Cut bulk export scenario (anti-persona need, deferred to roadmap)"]

### UI Mockup Created
- Default state ✅
- Loading state ✅
- Error state ✅

### Component Stubs Created
- `.specs/design-system/components/card.md` (new)

### Open Questions
- [Question 1]?

---

**Does this look right? Run `/tdd` when ready, or say "go ahead" to start the Red-Green-Refactor cycle.**
```

**If Full Mode (--full flag present):**
- Skip this pause
- Immediately proceed to the TDD cycle (RED → GREEN → REFACTOR → COMPOUND)

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
personas: [primary, anti-persona]
status: stub    # stub → specced → tested → implemented
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Feature Name

**Source File**: `path/to/feature.tsx` (planned)
**Design System**: `.specs/design-system/tokens.md`
**Personas**: `.specs/personas/primary.md`, `.specs/personas/anti-persona.md`

## Feature: [Name]

[Brief description of what this feature does and who it's for]

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

## User Journey

1. [Where user comes from]
2. **[This feature]**
3. [Where user goes next]

## Technical Design

### Data Model
- [Entity]: { [key fields] }
- Relationships: [how entities connect]

### API Contracts
<!-- Skip if purely client-side -->
- `[METHOD] [endpoint]` — [purpose]. Body/Query: { [shape] }. Returns: [shape]. Errors: [codes]

### State Management
- [What state lives where: URL params, local state, global store, server cache]
- [Key state transitions]

### Key Dependencies
- Uses: [existing modules, services, components]
- Introduces: [new modules this feature creates]

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
│  │  ⚠️ [Error message in persona's language]             │   │
│  │  [Retry Button]                                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Strategy Alignment

<!-- Included when .specs/strategy.md exists -->
- **Target segment**: [from strategy]
- **Buying motion fit**: [how this feature supports the buying motion]
- **Success metric**: [which strategy metric this moves]
- **Anti-goal check**: [confirm no anti-goal conflict]

## Constitutional Compliance

<!-- Included when .specs/constitution.md exists -->

| Rule | Applies | Status |
|------|---------|--------|
| [Rule from constitution] | ✅ / N/A / ⚠️ | [How addressed or why N/A] |

## Component References

| Component | Status | File |
|-----------|--------|------|
| Button | ✅ Exists | `.specs/design-system/components/button.md` |
| Card | 📝 Stub created | `.specs/design-system/components/card.md` |

## Design Tokens Used

- `color-primary` - Primary action buttons
- `color-error` - Error states
- `spacing-4` - Component padding
- `radius-md` - Card border radius

## Open Questions

- [ ] Question about ambiguous requirement?

## Learnings

<!-- This section grows over time via /compound -->
```

---

## Next Steps After Approval (or immediately in Full Mode)

**Normal Mode**: When user says "go ahead", "build it", runs `/tdd`, or approves — execute the full Red-Green-Refactor cycle
**Full Mode**: Execute immediately without waiting for approval

The steps below follow the `/tdd` command flow. See `/tdd` for the standalone version.

### Step 2: RED — Write Failing Tests
1. Write tests that cover ALL Gherkin scenarios (create new or update existing)
2. Tests should **FAIL** initially if no implementation yet
3. Document tests in `.specs/test-suites/{path}.tests.md`
4. Update spec frontmatter: `status: tested`, add test files to `tests: []`
5. Regenerate mapping: run `./scripts/generate-mapping.sh`
6. Proceed immediately to GREEN (no pause between RED and GREEN)

### Step 3: GREEN — Implement Until Tests Pass
1. Implement feature incrementally
2. Use design tokens from `.specs/design-system/tokens.md`
3. Follow component patterns from design system
4. Run tests frequently
5. Loop until all tests pass
6. Update spec frontmatter: `status: implemented`, add components to `components: []`
7. Do NOT update roadmap status — that happens after all verification passes

### Step 4: Drift Check — Layer 1 (Self-Check)

Verify your implementation matches your spec while you still have full context:

1. Re-read the Gherkin scenarios you wrote in Step 1
2. For each scenario, verify the code you just wrote implements it
3. Check for behaviors you implemented that aren't in the spec
4. Check for scenarios in the spec that aren't implemented

**If drift found:**
- Update the spec to match what you actually built (document reality)
- Or fix the code to match the spec (if you missed something)
- Ensure tests still pass after any changes

### Step 5: REFACTOR — Clean Up Code

Now that tests pass and spec aligns, improve the code without changing behavior:

1. Look for: extract functions, simplify conditionals, improve naming, remove duplication, add types
2. Make incremental changes
3. **Do NOT change test assertions** — if you need to, that's a behavior change
4. Run tests after each change — they MUST still pass
5. If tests fail, fix the refactor (don't change the tests)

### Step 6: Drift Check — Layer 1b (Post-Refactor)

Re-verify spec↔code alignment after refactoring:

1. Re-read the Gherkin scenarios
2. Verify the refactored code still implements every scenario
3. Check that refactoring didn't subtly change behavior
4. Fix any drift found, ensure tests pass

### Step 7: Document Components
After refactoring:
1. Fill in component stubs with actual implementation details
2. Update stub status from "📝 Stub" to "✅ Documented"
3. Or use `/design-component {name}` to auto-document

### Step 8: Compound Learnings (Automatic — Always Runs)

**Both Normal and Full Mode**: Always run `/compound` after refactor. This is not optional — learnings compound over time and failure signals prevent recurring mistakes.

1. Run `/compound` to extract learnings from the final (refactored) code state
2. Adds patterns/gotchas to spec's `## Learnings` section
3. Cross-cutting patterns go to `.specs/learnings/{category}.md`
4. **Failure signals** (drift, test retries, spec gaps, human corrections) go to BOTH the spec AND the category file with root cause and "fix for future" directive

### Step 9: Commit (Full Mode Only)

**Full Mode only** - after /compound completes:
1. Regenerate mapping: `./scripts/generate-mapping.sh`
2. Stage all changes: `git add .specs/ src/ tests/`
3. Commit with message: `feat: {feature name} (TDD: red-green-refactor)`
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
2. **Load context** - Read strategy, constitution, personas (vocabulary, patience level, frustrations), design tokens (personality, values), learnings index
3. **Create or update spec file**: `.specs/features/users/profile-page.feature.md`
4. **Write scenarios** (using persona vocabulary):
   - Display profile information
   - Edit profile (happy path)
   - Edit profile validation errors
   - Avatar upload
   - Cancel editing
5. **Add technical design** — data model, API contracts, state management, key dependencies
6. **Create ASCII mockups** (referencing design tokens):
   - View mode
   - Edit mode
   - Loading state
   - Error states
7. **Add strategy alignment** (if strategy.md exists)
8. **Add constitutional compliance** (if constitution.md exists)
9. **Add user journey** (where does this fit in the app?)
10. **Create component stubs**
11. **Persona revision pass** — re-read through persona's eyes, revise, note changes
12. **STOP** and wait for approval (Normal mode) or continue to tests → implement → compound → commit (Full mode)

---

## Greenfield Project (First Feature)

When `/spec-first` is the first command on a new project:

```
/spec-first landing page with hero section and signup form

[Detecting project state...]
⚠️ No personas found. Run /personas to create user personas for better specs.
⚠️ No design system found.

Creating design system:
✓ Read vision.md for context
✓ Determined personality: Friendly (consumer-facing signup flow)
✓ Created .specs/design-system/tokens.md

Proceeding with feature spec...
```

If vision.md also doesn't exist, the spec will still be written but with generic language. The output will recommend running `/vision` and `/personas` to improve future specs.
