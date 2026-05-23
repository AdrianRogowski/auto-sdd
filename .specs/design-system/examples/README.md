# Design System Examples

SDD uses **three layers** of examples. Read them in this order when running `/design-tokens`:

| Layer | Path | Purpose |
|-------|------|---------|
| **1. Archetype** | `references/{personality}.design.md` | Structure: sections, YAML shape, Do's/Don'ts depth |
| **2. Golden output** | `examples/demo/` | End state: synced DESIGN.md + tokens.md + preview.html |
| **3. External inspo** | [getdesign.md](https://getdesign.md/) | Optional brand-level depth (install via CLI) |

**Rule:** Strategy and personas own your values. Examples teach shape and depth, not brand identity.

---

## Golden demo (read this)

Fictional product **Fieldnote** — B2B workflow tool for ops teams (Professional personality).

| File | Description |
|------|-------------|
| [demo/DESIGN.md](./demo/DESIGN.md) | Full agent spec (YAML + prose) |
| [demo/tokens.md](./demo/tokens.md) | Spec shorthand derived from DESIGN.md |
| [demo/preview.html](./demo/preview.html) | Filled visual showcase — open in browser |

Pattern inspired by [Linear on getdesign.md](https://getdesign.md/linear.app/design-md) (surface ladder, restrained accent, dense UI) but **original** product and values.

---

## getdesign.md picks by personality

Install any of these for extra reference when running `/design-tokens inspiration {brand}`:

### Professional
| Brand | Install | Link |
|-------|---------|------|
| Linear | `npx getdesign@latest add linear.app` | [getdesign.md/linear.app](https://getdesign.md/linear.app/design-md) |
| IBM | `npx getdesign@latest add ibm` | [getdesign.md/ibm](https://getdesign.md/ibm/design-md) |
| Resend | `npx getdesign@latest add resend` | [getdesign.md/resend](https://getdesign.md/resend/design-md) |

### Minimal
| Brand | Install | Link |
|-------|---------|------|
| Linear | `npx getdesign@latest add linear.app` | [getdesign.md/linear.app](https://getdesign.md/linear.app/design-md) |
| Apple | `npx getdesign@latest add apple` | [getdesign.md/apple](https://getdesign.md/apple/design-md) |

### Friendly
| Brand | Install | Link |
|-------|---------|------|
| Notion | `npx getdesign@latest add notion` | [getdesign.md/notion](https://getdesign.md/notion/design-md) |
| Slack | `npx getdesign@latest add slack` | [getdesign.md/slack](https://getdesign.md/slack/design-md) |
| Airtable | `npx getdesign@latest add airtable` | [getdesign.md/airtable](https://getdesign.md/airtable/design-md) |

### Bold
| Brand | Install | Link |
|-------|---------|------|
| Stripe | `npx getdesign@latest add stripe` | [getdesign.md/stripe](https://getdesign.md/stripe/design-md) |
| Vercel | `npx getdesign@latest add vercel` | [getdesign.md/vercel](https://getdesign.md/vercel/design-md) |
| Framer | `npx getdesign@latest add framer` | [getdesign.md/framer](https://getdesign.md/framer/design-md) |

### Technical
| Brand | Install | Link |
|-------|---------|------|
| Supabase | `npx getdesign@latest add supabase` | [getdesign.md/supabase](https://getdesign.md/supabase/design-md) |
| Cursor | `npx getdesign@latest add cursor` | [getdesign.md/cursor](https://getdesign.md/cursor/design-md) |
| PostHog | `npx getdesign@latest add posthog` | [getdesign.md/posthog](https://getdesign.md/posthog/design-md) |

Browse the full catalog: [getdesign.md](https://getdesign.md/)

---

## How agents should use examples

```
1. Read references/{personality}.design.md     → structure
2. Read examples/demo/*                        → synced output target
3. Read strategy, vision, personas             → project values
4. [Optional] npx getdesign@latest add {brand} → extra depth
5. Write .specs/design-system/DESIGN.md        → your project
6. Derive tokens.md + preview.html             → keep in sync
```

Validate output:

```bash
npx @google/design.md lint .specs/design-system/DESIGN.md
```
