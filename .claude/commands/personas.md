---
description: Create or update user personas that inform every feature spec
---

Create or update user personas: $ARGUMENTS

## What Personas Are For

Personas are reference files that `/spec-first` reads before writing any spec. They drive:
- **Vocabulary** — UI labels use the persona's words, not developer words
- **Flow complexity** — patience level determines how many steps are acceptable
- **What NOT to build** — anti-persona prevents scope creep

## Instructions

### Step 1: Read Context

Read these files if they exist:
- `.specs/strategy.md` — target customer segment, buying motion, anti-segment. **Strategy determines who the personas are.** If strategy says "selling bottom-up to individual sales reps," your primary persona is a rep, not a VP Sales. If strategy says "enterprise top-down," the personas flip.
- `.specs/vision.md` — target users, app purpose, design principles
- `.specs/personas/*.md` — any existing personas (to avoid duplicates)

If no vision or strategy exists and no description was provided, ask:
1. Who is the primary user? (role, not name)
2. What's their typical day like? (busy/relaxed, desk/mobile, technical/non-technical)
3. Is there a secondary user with different needs?
4. Who is this NOT for? (anti-persona)

### Step 2: Write Personas

Create files in `.specs/personas/`:

**Most projects need 2:**
- `primary.md` — the main user, every feature must work for them
- `anti-persona.md` — who you're NOT building for, prevents scope creep

Only add `secondary.md` if the app genuinely serves two different user types.

### Persona Format

```markdown
# [Role]

## Context
- [How they spend their day]
- [Devices and environment]
- [Technical sophistication]
- [How many tools they juggle]

## What They Care About
- [Real-world outcome they're after]
- [Why they'd choose this tool]
- [What would make them recommend it]

## What Frustrates Them
- [Interaction patterns they hate]
- [Time wasters]
- [Complexity they avoid]

## Their Vocabulary
- [Their term] not [developer term]

## Patience Level
[Very Low / Low / Medium / High] — [why]

## Success Metric
[How they measure if the app works for them]
```

### Anti-Persona Format

```markdown
# Anti-Persona: [Role]

## Who This Is
- [Description of the user type we're NOT targeting]

## Why They're Out of Scope
- [What they'd need that would distort the product]
- [How serving them would hurt the primary persona's experience]

## What to Say If Requested
[How to redirect feature requests from this persona]
```

### Step 3: Report

Show:
- Primary persona summary (role + key constraint)
- Anti-persona summary (role + why excluded)
- Files created
- Note: "These will be loaded by /spec-first when writing feature specs."

## Update Mode

If personas already exist:
1. Read current personas
2. Read `.specs/strategy.md` for any target customer changes
3. Read `.specs/learnings/` for user-behavior insights
4. Read vision.md for any audience changes
5. Check for strategy↔persona drift (e.g., strategy says "individual reps" but primary persona is "VP Sales")
6. Update personas, noting what changed and why

## Add Mode

If `add` subcommand:
1. Read existing personas to avoid overlap
2. Create new persona file
3. Explain how it differs from existing ones
