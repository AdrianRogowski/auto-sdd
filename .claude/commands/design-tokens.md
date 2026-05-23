---
description: Create or update personality-driven design system (tokens + DESIGN.md + preview)
---

Manage design system: $ARGUMENTS

## Outputs (always sync all three)

- `.specs/design-system/DESIGN.md` — Google spec, agents read for UI
- `.specs/design-system/tokens.md` — spec/mockup shorthand
- `.specs/design-system/preview.html` — visual showcase (from `preview.template.html`)

References: `.specs/design-system/references/*.design.md` · Golden example: `examples/demo/` · Catalog: `examples/README.md`

## `init` / no args — Create

1. Read strategy, vision, personas, existing theme
2. Pick personality → read `references/{personality}.design.md` + `examples/demo/*`
3. Optional: getdesign.md inspo per `examples/README.md`
4. Write **DESIGN.md** (YAML + Overview…Do's/Don'ts) with **project** values, archetype **structure**
5. Write **tokens.md** summary from DESIGN.md
6. Generate **preview.html** from `preview.template.html` + DESIGN.md tokens
7. `npx @google/design.md lint .specs/design-system/DESIGN.md` (warn if missing)
8. Update `.cursor/rules/design-tokens.mdc`

## Personalities → references

| Personality | Reference | getdesign inspo |
|-------------|-----------|-----------------|
| Professional | professional.design.md | linear.app, ibm, resend |
| Minimal | minimal.design.md | linear.app, apple |
| Friendly | friendly.design.md | notion, slack, airtable |
| Bold | bold.design.md | stripe, vercel, framer |
| Technical | technical.design.md | supabase, cursor, posthog |

## Subcommands

- `update {token} to {value}` — sync DESIGN.md, tokens.md, preview.html
- `preview` — regenerate preview.html only
- `inspiration {brand}` — getdesign add + merge patterns into project DESIGN.md
- `import from {file}` — extract → all three artifacts

## Rails

- Archetypes teach depth; strategy/personas own values
- Don't copy brand colors from getdesign without user intent
- DESIGN.md is source of truth for agents; tokens.md for specs

See `.cursor/commands/design-tokens.md` for full steps.
