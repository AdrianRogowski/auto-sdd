# Design Tokens — Fieldnote (Demo)

**Status**: ✅ Example output (golden reference — copy pattern, not values)  
**Personality**: Professional  
**Last Updated**: 2026-05-22

> **Demo only.** Shows what `/design-tokens` produces for a fictional B2B ops product.  
> Full spec: [DESIGN.md](./DESIGN.md) · Preview: [preview.html](./preview.html)

---

## Personality

**Chosen**: Professional  
**Why**: Ops users scan dense tables all day; 14px body, tight spacing, single indigo accent.

---

## Colors

### Primary

| Token | Value | Usage |
|-------|-------|-------|
| `color-primary` | `#4f46e5` | Primary actions, links, focus |
| `color-primary-hover` | `#4338ca` | Hover on primary buttons |
| `color-primary-light` | `#eef2ff` | Selected rows, active filters |

### Neutrals

| Token | Value | Usage |
|-------|-------|-------|
| `color-background` | `#ffffff` | Page canvas |
| `color-surface` | `#f9fafb` | Panels, zebra stripes |
| `color-surface-2` | `#f3f4f6` | Hovered rows, badges |
| `color-border` | `#e5e7eb` | Tables, inputs, cards |
| `color-text` | `#111827` | Primary text |
| `color-text-secondary` | `#6b7280` | Labels, headers |
| `color-text-muted` | `#9ca3af` | Placeholders |

### Semantic

| Token | Value | Usage |
|-------|-------|-------|
| `color-success` | `#059669` | On track |
| `color-warning` | `#d97706` | At risk |
| `color-error` | `#dc2626` | Overdue, errors |

---

## Typography

| Token | Value | Usage |
|-------|-------|-------|
| `font-sans` | system stack | All UI |
| `font-mono` | JetBrains Mono, Menlo | Workflow IDs |
| `text-display` | 28px / 600 | Empty states |
| `text-headline` | 20px / 600 | Page titles |
| `text-base` | 14px / 400 | Tables, forms |
| `text-lg` | 16px / 400 | Intro copy |
| `text-sm` | 12px / 500 | Labels, badges |

---

## Spacing

**Base unit**: 4px

| Token | Value | Usage |
|-------|-------|-------|
| `spacing-1` | 4px | Tight gaps |
| `spacing-2` | 8px | Cell padding, icon gaps |
| `spacing-3` | 12px | Input padding |
| `spacing-4` | 16px | Card padding |
| `spacing-6` | 24px | Section gaps, page gutter |
| `spacing-8` | 32px | Large breaks |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 4px | Badges |
| `radius-md` | 6px | Buttons, inputs |
| `radius-lg` | 8px | Cards, modals |
| `radius-full` | 9999px | Status pills |

---

## Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `shadow-sm` | `0 1px 2px rgba(0,0,0,0.06)` | Dropdowns only |

---

## What's Intentionally Missing

| Omitted | Why |
|---------|-----|
| Dark mode | Demo ships light-only |
| Secondary accent | One indigo is enough |
| Marketing display sizes | App is table-first |

---

## Why These Choices

Indigo reads trustworthy for B2B without default "SaaS blue." Cool-tinted grays match the primary hue. 14px body and 4px spacing base keep workflow lists scannable.

---

## ASCII Mockup Reference

```
┌─ Card (bg: surface, radius: lg, border) ────────────────────┐
│  Active workflows (text: headline, color: text)             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ ID (mono) │ Name │ Status (badge) │ SLA               │  │
│  │ selected row (bg: primary-light)                     │  │
│  └──────────────────────────────────────────────────────┘  │
│  [Button primary: Create workflow]                          │
└─────────────────────────────────────────────────────────────┘
```
