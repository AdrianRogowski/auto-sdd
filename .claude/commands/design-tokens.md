# Design Tokens & Design System

Create or update the design system for your project. Produces a **tailored** system with three outputs: spec-friendly tokens, agent-native DESIGN.md, and a visual preview page.

## Usage

```
/design-tokens                                    # Create full design system
/design-tokens init                              # Same as above
/design-tokens update primary to #FF6B6B          # Update tokens (syncs all artifacts)
/design-tokens import from tailwind.config        # Extract from existing config
/design-tokens import from styles/vars.css        # Extract from CSS variables
/design-tokens inspiration linear.app             # Optional: pull getdesign.md reference, then customize
/design-tokens preview                            # Regenerate preview.html from DESIGN.md
```

---

## Outputs

| File | Audience | Purpose |
|------|----------|---------|
| `.specs/design-system/tokens.md` | Specs, ASCII mockups | Lightweight tables for `/spec-first` |
| `.specs/design-system/DESIGN.md` | Coding agents | [Google DESIGN.md spec](https://github.com/google-labs-code/design.md): YAML + rationale + Do's/Don'ts |
| `.specs/design-system/preview.html` | Humans | Open in browser: palette, typography, components |

**Bundled references** (read, never copy verbatim): `.specs/design-system/references/*.design.md`  
**Golden output example**: `.specs/design-system/examples/demo/` (synced DESIGN.md + tokens.md + preview.html)  
See `.specs/design-system/examples/README.md` for getdesign.md brand picks and `.specs/design-system/references/_README.md` for personality mapping.

---

## Behavior: Create New Design System

If `.specs/design-system/tokens.md` doesn't exist or is still the unmodified template:

### Step 1: Read Context

| File | What You Learn |
|------|---------------|
| `.specs/strategy.md` | Target customer, buying motion, brand positioning |
| `.specs/vision.md` | App purpose, design principles, tool category |
| `.specs/personas/*.md` | Patience level, vocabulary, technical level |
| `package.json` / theme files | Tech stack, existing colors |
| `.specs/design-system/references/` | Archetype structure and depth |

If insufficient context, ask:

```
I need context to create your design system:

1. What kind of app is this?
2. Vibe: professional / friendly / minimal / bold / technical
3. Brand color? (hex or description)

Or run /vision and /personas first.
```

### Step 2: Determine Personality

| Personality | Archetype reference | getdesign.md inspo (optional) |
|-------------|---------------------|-------------------------------|
| **Professional** | `references/professional.design.md` | linear.app, ibm, resend |
| **Minimal** | `references/minimal.design.md` | linear.app, apple |
| **Friendly** | `references/friendly.design.md` | notion, slack, airtable |
| **Bold** | `references/bold.design.md` | stripe, vercel, framer |
| **Technical** | `references/technical.design.md` | supabase, cursor, posthog |

State your choice and why (from vision/personas/strategy).

### Step 3: Read Archetype + Golden Example + Optional Inspiration

1. **Always read** `.specs/design-system/references/{personality}.design.md` (structure)
2. **Always read** `.specs/design-system/examples/demo/` — synced DESIGN.md, tokens.md, preview.html showing target output quality
3. See `.specs/design-system/examples/README.md` for getdesign.md brand picks (Linear, Notion, Stripe, Supabase, etc.)
4. **Optional**: If user wants brand inspo:
   ```bash
   npx getdesign@latest add {brand}
   ```
   Read installed `DESIGN.md`, adapt patterns into project files. Do not copy brand identity.

### Step 4: Build the Palette

Start from one color; derive the rest (same rules as before):

- Primary from brand or personality default
- `primary-hover`, surfaces, tinted neutrals, semantic colors
- WCAG AA: text on background ≥ 4.5:1

### Step 5: Write `.specs/design-system/DESIGN.md`

Follow [Google DESIGN.md spec](https://github.com/google-labs-code/design.md):

**YAML frontmatter** (required groups for v1):
- `version: alpha`, `name`, `description`
- `colors`, `typography`, `rounded`, `spacing`
- `components` with at least: `button-primary`, `button-primary-hover`, `button-secondary`, `card`, `input`

**Markdown body** (in order):
1. Overview (atmosphere, when to use)
2. Colors
3. Typography
4. Layout
5. Elevation & Depth
6. Shapes
7. Components
8. Do's and Don'ts

Values must come from **this project's** strategy/vision/personas, not the archetype hex codes.

### Step 6: Write `.specs/design-system/tokens.md`

Derive a **summary** from DESIGN.md for specs:
- Personality + rationale
- Token tables mapping to DESIGN.md (use names agents will see in mockups)
- "Why These Choices" and "What's Intentionally Missing"

Keep v1 constrained (see table below).

| Category | v1 Needs | Defer to v2 |
|----------|----------|-------------|
| Colors | Primary + hover + light, neutrals, semantic | Secondary, dark mode tokens |
| Typography | 1 family, 4-5 sizes, 3 weights | Display fonts |
| Spacing | 6 values on one base | spacing-0, extras |
| Radii | sm, md, lg, full | xl, 2xl |
| Shadows | sm, lg (if used) | md, xl |

### Step 7: Generate `.specs/design-system/preview.html`

1. Copy structure from `.specs/design-system/preview.template.html`
2. Replace `:root` CSS variables with values from DESIGN.md YAML
3. Fill Overview, swatch labels, Do's/Don'ts from DESIGN.md prose
4. Set project name and personality in header
5. Add dark theme overrides if DESIGN.md defines dark surfaces

Open locally: `open .specs/design-system/preview.html` (macOS) or open file in browser.

### Step 8: Validate & Cursor Rule

```bash
npx @google/design.md lint .specs/design-system/DESIGN.md
```

If CLI unavailable, note in report. Fix obvious spec violations.

Create/update `.cursor/rules/design-tokens.mdc` with this project's token names. Mention DESIGN.md and preview.html in the rule.

### Step 9: Report

```markdown
## Design System Created

**Personality**: [name]
**Rationale**: [1 sentence from vision/personas]
**Archetype reference**: references/[personality].design.md
**Inspiration**: [getdesign brand or "none"]

### Files
- `.specs/design-system/DESIGN.md` — agents read before UI work
- `.specs/design-system/tokens.md` — specs and ASCII mockups
- `.specs/design-system/preview.html` — open in browser to review
- `.cursor/rules/design-tokens.mdc`

### Review
Open preview.html and confirm colors/type match intent before `/spec-first`.

### Lint
[pass / skipped / warnings]
```

---

## Behavior: Update Existing Tokens

When `tokens.md` or `DESIGN.md` already exists:

1. Read current `DESIGN.md` and `tokens.md`
2. Apply requested changes
3. **Sync all three artifacts** (DESIGN.md is source of truth for agents; tokens.md summary; regenerate preview.html)
4. Re-run lint if possible
5. Update `.cursor/rules/design-tokens.mdc` if names changed

---

## Behavior: `preview` subcommand

Regenerate only `.specs/design-system/preview.html` from current `DESIGN.md` using `preview.template.html`. Use after hand-editing DESIGN.md.

---

## Behavior: `inspiration {brand}` subcommand

1. Run `npx getdesign@latest add {brand}` in project root (or read if already present)
2. Read installed `DESIGN.md` alongside project files
3. Merge useful patterns into `.specs/design-system/DESIGN.md` while keeping project-specific values
4. Sync tokens.md and preview.html
5. Do not leave a duplicate root `DESIGN.md` if project canonical path is `.specs/design-system/DESIGN.md` (move or merge, then delete stray copy)

---

## Behavior: Import from Existing Config

Same as before, but output all three artifacts:
1. Extract values from Tailwind/CSS
2. Write DESIGN.md (full spec)
3. Derive tokens.md
4. Generate preview.html

---

## Design Principles for Token Selection

(Unchanged — tinted neutrals, one font v1, 4px vs 8px base, personality-matched radii, two shadows max.)

---

## Integration

| Command | Uses design system |
|---------|-------------------|
| `/spec-first` | `tokens.md` in mockups; instruct agents to read `DESIGN.md` for UI |
| `/design-component` | Token names from DESIGN.md / tokens.md |
| `/spec-init` | Detect existing tokens, DESIGN.md, preview |
| `/vision` | Personality input for `/design-tokens` |
| `/tdd` | Implement UI per DESIGN.md + feature spec |

When implementing UI, agents must read `.specs/design-system/DESIGN.md` before writing components.
