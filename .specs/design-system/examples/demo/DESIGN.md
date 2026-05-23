---
version: alpha
name: Fieldnote
description: "B2B workflow tool for ops teams. Cool indigo accent on white canvas, 4px spacing base, table-first UI. Golden demo output — not a real product."
colors:
  primary: "#4f46e5"
  on-primary: "#ffffff"
  primary-hover: "#4338ca"
  primary-light: "#eef2ff"
  primary-focus: "#6366f1"
  canvas: "#ffffff"
  surface-1: "#f9fafb"
  surface-2: "#f3f4f6"
  ink: "#111827"
  ink-muted: "#6b7280"
  ink-subtle: "#9ca3af"
  border: "#e5e7eb"
  border-strong: "#d1d5db"
  success: "#059669"
  warning: "#d97706"
  error: "#dc2626"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.02em
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: -0.01em
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  body-lg:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.25
  button:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.2
  mono:
    fontFamily: "JetBrains Mono, ui-monospace, Menlo, monospace"
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.5
rounded:
  sm: 4px
  md: 6px
  lg: 8px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  xxl: 32px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: 8px 14px
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
  button-secondary:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: 8px 14px
  button-ghost:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: 8px 14px
  card:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: 16px
  input:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: 8px 12px
  table-row-selected:
    backgroundColor: "{colors.primary-light}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
  status-badge:
    backgroundColor: "{colors.surface-2}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: 2px 8px
---

## Overview

Fieldnote helps ops teams track recurring workflows: handoffs, checklists, and SLA timers. The UI is **table-first and calm**: white canvas, cool gray surfaces, one indigo accent for primary actions and selection states. Users scan hundreds of rows per session, so body text stays 14px and decorative chrome is minimal.

Structural patterns (surface ladder, component variants, restrained accent) are informed by professional SaaS references such as Linear on [getdesign.md](https://getdesign.md/linear.app/design-md). Colors and product framing are original to this demo.

**Use when:** workflow tools, ops dashboards, internal B2B apps with dense data.

## Colors

- **Primary** (`{colors.primary}`): Create workflow, save, primary nav emphasis.
- **Primary hover** (`{colors.primary-hover}`): Hovered primary buttons.
- **Primary light** (`{colors.primary-light}`): Selected table rows, active filter chips.
- **Canvas** (`{colors.canvas}`): Page background.
- **Surface 1 / 2** (`{colors.surface-1}`, `{colors.surface-2}`): Zebra rows, panel backgrounds, hovered cards.
- **Ink scale**: `{colors.ink}` headings and body, `{colors.ink-muted}` column headers, `{colors.ink-subtle}` placeholders and disabled text.
- **Borders** (`{colors.border}`, `{colors.border-strong}`): Table rules, input outlines, card edges.

## Typography

System sans throughout. `{typography.display}` for empty-state titles only (28px). `{typography.headline}` for page titles (20px). `{typography.body}` at 14px is the default in tables and forms. `{typography.mono}` for workflow IDs and API keys.

## Layout

4px spacing base. Table cell padding 8px vertical, 12px horizontal. Page gutters 24px. Filter bar stacks horizontally on desktop; wraps on mobile. Max app width 1280px.

## Elevation & Depth

Borders over shadows. Cards use 1px `{colors.border}`. Dropdowns may use subtle shadow. Selected rows use `{colors.primary-light}` fill, not elevation.

## Shapes

`{rounded.md}` on buttons and inputs. `{rounded.lg}` on cards and modals. `{rounded.full}` on status badges only.

## Components

### Buttons

- **button-primary**: Save, Create workflow, Confirm.
- **button-secondary**: Cancel, Export (outlined feel via border in implementation).
- **button-ghost**: Tertiary actions in toolbars.

### Data surfaces

- **card**: Summary metrics above tables.
- **table-row-selected**: Active row in workflow list.
- **status-badge**: On track / At risk / Overdue.

### Forms

- **input**: Search, filter, rename workflow. Focus ring uses `{colors.primary-focus}` at 2px.

## Do's and Don'ts

### Do

- Use `{colors.primary}` for one primary action per panel.
- Keep table body at `{typography.body}` 14px.
- Right-align numeric SLA columns.
- Show workflow ID in `{typography.mono}`.

### Don't

- Don't use pill-shaped primary buttons in the app shell.
- Don't add a second accent color for decoration.
- Don't use display typography inside table cells.
- Don't rely on color alone for status (pair badge color with text label).

## Responsive Behavior

Below 768px: stack filter bar vertically, hide non-essential columns, keep primary CTA full-width in empty states.
