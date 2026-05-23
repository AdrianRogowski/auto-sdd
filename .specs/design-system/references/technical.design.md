---
version: alpha
name: technical-archetype
description: "Reference only. Developer/data UI: cool gray dark theme, green or cyan accent, mono for code, flat borders, compact spacing."
colors:
  primary: "#3ecf8e"
  on-primary: "#0a0a0a"
  primary-hover: "#2eb872"
  canvas: "#0f0f0f"
  surface-1: "#171717"
  surface-2: "#1f1f1f"
  ink: "#ededed"
  ink-muted: "#a1a1a1"
  ink-subtle: "#737373"
  border: "#2a2a2a"
  border-strong: "#404040"
  code-bg: "#0a0a0a"
  success: "#3ecf8e"
  warning: "#f5a623"
  error: "#f87171"
typography:
  body:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.5
  body-lg:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  headline:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.3
  mono:
    fontFamily: "JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.5
  button:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.2
rounded:
  sm: 2px
  md: 4px
  lg: 6px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: 6px 12px
  button-secondary:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: 6px 12px
  input:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.mono}"
    rounded: "{rounded.md}"
    padding: 6px 10px
  card:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: 12px
  code-block:
    backgroundColor: "{colors.code-bg}"
    textColor: "{colors.ink}"
    typography: "{typography.mono}"
    rounded: "{rounded.md}"
    padding: 12px
---

## Overview

Technical archetype optimizes for scanning logs, tables, API keys, and config. Dark flat surfaces, monospace for machine-readable strings, accent color reserved for success states and primary actions. Density over decoration.

**Use when:** dev tools, observability dashboards, CLIs with GUI, admin panels for engineers.

## Colors

Dark `{colors.canvas}` ladder. Accent often green or cyan (terminal association). Semantic success may equal `{colors.primary}`. Errors stay red but desaturated.

## Typography

13px default body. Mono for code, IDs, timestamps. Headlines small (18px) relative to marketing sites.

## Layout

4px base. Compact table rows (32-36px). Sidebar + main split common. Filters inline, not wizard-heavy.

## Elevation & Depth

Borders only: `{colors.border}` default, `{colors.border-strong}` on focus. No drop shadows.

## Shapes

`{rounded.md}` max on chrome. Sharp feels OK for data grids.

## Do's and Don'ts

### Do

- Use `{typography.mono}` for anything the user might copy.
- Truncate with copy affordance, not hover-only tooltips.
- Show keyboard shortcuts in labels where relevant.

### Don't

- Don't use marketing display sizes in app chrome.
- Don't animate decorative transitions on data refresh.
- Don't use friendly empty-state illustration when a one-line error + retry suffices.
