# Design System References

Archetype `DESIGN.md` files teach agents **structure and depth**, not brand mimicry. Read the file matching your chosen personality before writing the project's `DESIGN.md`.

**Also read** the golden demo: [`examples/demo/`](../examples/demo/) (synced DESIGN.md + tokens.md + preview.html).

Full getdesign.md catalog: [`examples/README.md`](../examples/README.md).

## When to use

| SDD personality | Read this archetype | Vibe |
|-----------------|---------------------|------|
| **Professional** | `professional.design.md` | Dense SaaS, muted palette, tight spacing, single accent |
| **Minimal** | `minimal.design.md` | Near-monochrome, whitespace, borders over shadows |
| **Friendly** | `friendly.design.md` | Warm surfaces, comfortable radii, approachable copy density |
| **Bold** | `bold.design.md` | Vivid accent, display type, confident CTAs |
| **Technical** | `technical.design.md` | Flat, mono accents, data-dense, terminal-adjacent |

Adapt values from `.specs/strategy.md`, `.specs/vision.md`, and `.specs/personas/`. Keep the archetype's **sections and guardrails**; replace colors, type, and names with project-specific choices.

## Optional: getdesign.md inspiration

Browse [getdesign.md](https://getdesign.md/) or install a reference into the project root for extra depth:

```bash
npx getdesign@latest add linear.app   # professional / minimal
npx getdesign@latest add notion       # friendly
npx getdesign@latest add stripe       # bold
npx getdesign@latest add supabase     # technical
```

Use installed files as **reference only**. Merge patterns (surface ladders, component variants, Do's and Don'ts) into `.specs/design-system/DESIGN.md`. Do not copy brand colors or trademarks into production UI unless the product strategy requires it.

| Personality | getdesign.md picks |
|-------------|-------------------|
| Professional | [Linear](https://getdesign.md/linear.app/design-md), [IBM](https://getdesign.md/ibm/design-md), [Resend](https://getdesign.md/resend/design-md) |
| Minimal | [Linear](https://getdesign.md/linear.app/design-md), [Apple](https://getdesign.md/apple/design-md) |
| Friendly | [Notion](https://getdesign.md/notion/design-md), [Slack](https://getdesign.md/slack/design-md), [Airtable](https://getdesign.md/airtable/design-md) |
| Bold | [Stripe](https://getdesign.md/stripe/design-md), [Vercel](https://getdesign.md/vercel/design-md), [Framer](https://getdesign.md/framer/design-md) |
| Technical | [Supabase](https://getdesign.md/supabase/design-md), [Cursor](https://getdesign.md/cursor/design-md), [PostHog](https://getdesign.md/posthog/design-md) |

## Format

All archetypes follow the [Google DESIGN.md spec](https://github.com/google-labs-code/design.md):

- YAML frontmatter: `colors`, `typography`, `rounded`, `spacing`, `components`
- Markdown body: Overview, Colors, Typography, Layout, Elevation, Shapes, Components, Do's and Don'ts

Validate project output:

```bash
npx @google/design.md lint .specs/design-system/DESIGN.md
```

## Preview

Generate `.specs/design-system/preview.html` from `preview.template.html` when running `/design-tokens`. Open in a browser to review palette, typography, and components before building features.
