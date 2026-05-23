# Design System Enhancement Plan

**Status**: Implemented in SDD template  
**Goal**: Produce production-grade design systems agents can follow, with visual proof humans can review.

---

## Problem

SDD's `/design-tokens` produced `.specs/design-system/tokens.md` only: tables of values with minimal guidance. Agents building UI from that alone tend toward generic output. Humans had no quick way to see "what does this look like?"

[getdesign.md](https://getdesign.md/) demonstrates what works:

1. **DESIGN.md** (Google spec): YAML tokens + markdown rationale, component variants, Do's and Don'ts
2. **Live preview**: single-page HTML showing palette, typography, and components
3. **Reference examples**: curated analyses of real systems as structural inspiration

---

## Solution: Three Artifacts + Reference Library

After `/design-tokens`, each project gets:

| File | Audience | Purpose |
|------|----------|---------|
| `.specs/design-system/tokens.md` | Specs, ASCII mockups | Lightweight token tables for `/spec-first` |
| `.specs/design-system/DESIGN.md` | Coding agents | Google DESIGN.md spec: YAML + rationale + guardrails |
| `.specs/design-system/preview.html` | Humans | Open in browser; palette, type, components rendered |

Bundled in the SDD template (not overwritten per project):

| Path | Purpose |
|------|---------|
| `.specs/design-system/references/*.design.md` | Archetype examples by personality |
| `.specs/design-system/examples/demo/` | Golden output: synced DESIGN.md + tokens.md + preview.html |
| `.specs/design-system/examples/README.md` | getdesign.md brand catalog (Linear, Notion, Stripe, …) |
| `.specs/design-system/preview.template.html` | Shell for generating `preview.html` |

---

## Workflow (unchanged order)

```
/strategy → /vision → /personas → /constitution → /design-tokens
```

### `/design-tokens` steps

1. Read strategy, vision, personas, existing CSS/theme
2. Determine personality (Professional / Friendly / Minimal / Bold / Technical)
3. **Read matching archetype** from `references/{personality}.design.md`
4. **Read golden demo** from `examples/demo/` (target output quality)
5. **Optional inspiration**: see `examples/README.md` for getdesign.md picks; `npx getdesign@latest add {brand}`
6. Write project `DESIGN.md` (structure from archetype + demo, values from strategy/vision/personas)
7. Write project `tokens.md` (derived summary for specs)
8. Generate `preview.html` from `preview.template.html` + DESIGN.md tokens
9. Lint: `npx @google/design.md lint .specs/design-system/DESIGN.md` (warn if unavailable)
10. Update `.cursor/rules/design-tokens.mdc`

### `/spec-first` integration

- Load `tokens.md` for ASCII mockup token names
- Tell implementers to read `DESIGN.md` before UI work
- Link to `preview.html` at spec pause: "Open preview to verify visual direction"

---

## Personality → Reference Mapping

| SDD Personality | Archetype file | getdesign.md inspo (optional) |
|-----------------|----------------|-------------------------------|
| Professional | `professional.design.md` | Linear, IBM, Resend |
| Minimal | `minimal.design.md` | Linear, Apple, iA Writer |
| Friendly | `friendly.design.md` | Notion, Slack, Airtable |
| Bold | `bold.design.md` | Stripe, Vercel, Framer |
| Technical | `technical.design.md` | Supabase, Cursor, GitHub |

---

## What we deliberately do NOT do

- Ship 71 brand DESIGN.md files inside SDD (use getdesign CLI on demand)
- Replace strategy/personas with copied brand aesthetics
- Require network for `/design-tokens` (archetypes work offline)

---

## Success criteria

- [ ] `/design-tokens` creates tokens.md + DESIGN.md + preview.html
- [x] Archetype references in `references/`
- [x] Golden demo in `examples/demo/` (Fieldnote — Linear-pattern, original values)
- [x] getdesign.md catalog in `examples/README.md`
- [ ] `/spec-first` references DESIGN.md for UI implementation
- [ ] preview.html opens locally with no build step
- [ ] DESIGN.md passes `@google/design.md lint` when CLI is available
