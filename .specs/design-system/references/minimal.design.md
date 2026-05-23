---
version: alpha
name: minimal-archetype
description: "Reference only. Restrained monochrome UI: near-black text, white canvas, one muted accent, borders instead of shadows."
colors:
  primary: "#18181b"
  on-primary: "#ffffff"
  primary-hover: "#27272a"
  accent: "#71717a"
  canvas: "#ffffff"
  surface: "#fafafa"
  ink: "#09090b"
  ink-muted: "#52525b"
  ink-subtle: "#a1a1aa"
  border: "#e4e4e7"
  success: "#16a34a"
  warning: "#ca8a04"
  error: "#b91c1c"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 40px
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: -0.03em
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.02em
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.6
  caption:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.4
  button:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.2
rounded:
  sm: 4px
  md: 6px
  lg: 8px
spacing:
  xs: 8px
  sm: 16px
  md: 24px
  lg: 32px
  xl: 48px
  section: 96px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.sm}"
    padding: 10px 18px
  button-ghost:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.sm}"
    padding: 10px 18px
  card:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: 24px
---

## Overview

Minimal archetype removes everything that does not serve reading or a single action. Typography and spacing do the hierarchy work. Color is almost entirely neutral; accent appears sparingly on primary actions and focus.

**Use when:** writing tools, settings-light apps, marketing pages with editorial tone, premium consumer products.

## Colors

Near-black `{colors.ink}` on white `{colors.canvas}`. `{colors.primary}` is often near-black rather than a hue. Secondary accent `{colors.accent}` for links and meta only if needed.

## Typography

Strong weight contrast: display at 600, body at 400. Generous line-height on body (1.6). Few sizes: display, headline, body, caption.

## Layout

8px base with large section gaps (`{spacing.section}`). Content max-width ~720px for reading, ~1120px for marketing grids. Asymmetric whitespace is acceptable.

## Elevation & Depth

No shadows on cards. Separate sections with `{colors.border}` hairlines or `{spacing.xl}` gaps only.

## Shapes

Small radii (`{rounded.sm}` on buttons). Avoid pill buttons and heavy rounded cards.

## Do's and Don'ts

### Do

- Let whitespace define sections.
- Use one primary button per viewport when possible.
- Prefer serif or humanist sans for editorial products if vision calls for it.

### Don't

- Don't add decorative gradients or illustration-heavy chrome by default.
- Don't use semantic colors as decoration.
- Don't stack more than two font weights on one screen.
