---
version: alpha
name: professional-archetype
description: "Reference only. Dense professional SaaS: cool neutrals, single indigo accent, 4px spacing base, subtle elevation. Adapt all values to your product."
colors:
  primary: "#4f46e5"
  on-primary: "#ffffff"
  primary-hover: "#4338ca"
  primary-light: "#eef2ff"
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
    fontSize: 32px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.02em
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 24px
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
---

## Overview

Professional archetype targets users who scan dense information quickly: operators, admins, analysts. The UI feels authoritative and calm. One chromatic accent carries all primary actions. Neutrals are cool-tinted, not pure gray. Whitespace is earned, not decorative.

**Use when:** enterprise dashboards, B2B SaaS, internal tools, data-heavy workflows.

## Colors

- **Primary** (`{colors.primary}`): Primary buttons, links, focus rings, selected nav.
- **Canvas / surfaces**: `{colors.canvas}` page, `{colors.surface-1}` zebra rows and subtle panels, `{colors.surface-2}` hovered rows.
- **Ink scale**: `{colors.ink}` body and headings, `{colors.ink-muted}` labels, `{colors.ink-subtle}` placeholders.
- **Semantic**: success/warning/error at muted saturation to match the palette.

## Typography

Single sans family. Display and headline use semibold with slight negative tracking. Body stays 14px for density; 16px for marketing-style intros only. Labels at 12px medium for table headers and form labels.

## Layout

4px spacing base. Common gaps: 8px inside components, 16px card padding, 24px section gaps. Max content width ~1280px. Tables and filters are first-class; hero marketing blocks are rare.

## Elevation & Depth

Prefer 1px `{colors.border}` over shadow. `{shadow-sm}` on dropdowns only. Selected rows use `{colors.primary-light}` background, not heavy borders.

## Shapes

`{rounded.sm}` inputs and buttons, `{rounded.lg}` cards. Avoid pills except status badges.

## Components

Document primary/secondary buttons, cards, inputs with default and hover variants in YAML. Tables: compact row height, right-aligned numerics, sticky header on scroll.

## Do's and Don'ts

### Do

- Use `{colors.primary}` for one primary action per view.
- Keep body text at 14px in app surfaces.
- Align labels above inputs in forms; inline only for compact filters.

### Don't

- Don't use more than one vivid accent on the same screen.
- Don't use display sizes inside data tables.
- Don't round CTAs to pills in app chrome (reserve pills for badges).
