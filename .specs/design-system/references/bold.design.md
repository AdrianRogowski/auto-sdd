---
version: alpha
name: bold-archetype
description: "Reference only. Confident consumer/dev brand: vivid purple or blue accent, large display type, gradient-friendly, generous radii."
colors:
  primary: "#635bff"
  on-primary: "#ffffff"
  primary-hover: "#4f46e5"
  gradient-start: "#635bff"
  gradient-end: "#a855f7"
  canvas: "#0a0a0f"
  surface-1: "#12121a"
  surface-2: "#1a1a24"
  ink: "#f8fafc"
  ink-muted: "#94a3b8"
  ink-subtle: "#64748b"
  border: "#2e2e3a"
  success: "#22c55e"
  warning: "#f59e0b"
  error: "#ef4444"
typography:
  display:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 56px
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: -0.03em
  headline:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: -0.02em
  body:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.6
  button:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.2
rounded:
  sm: 8px
  md: 12px
  lg: 16px
  full: 9999px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  section: 80px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.full}"
    padding: 12px 24px
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.full}"
  button-secondary:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.full}"
    padding: 12px 24px
  card:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: 24px
---

## Overview

Bold archetype sells confidence: dark canvas, luminous text, vivid accent, large display headlines. Marketing and product chrome share the same energy. Gradients accent hero sections and primary CTAs, not every surface.

**Use when:** developer platforms, fintech landing pages, PLG products, premium consumer apps.

## Colors

Dark `{colors.canvas}` with stepped surfaces. Primary accent is saturated purple or blue. Gradients from `{colors.gradient-start}` to `{colors.gradient-end}` on hero CTAs and feature bands only.

## Typography

Large display with tight negative tracking. Body remains readable at 16px on dark (`{colors.ink}` on `{colors.canvas}` ≥ 4.5:1).

## Layout

Section rhythm `{spacing.section}`. Asymmetric marketing grids OK. App shells may simplify to professional density while keeping accent and dark theme.

## Elevation & Depth

Glow and gradient over flat gray shadows. Cards use `{colors.surface-1}` plus subtle border `{colors.border}`.

## Shapes

Pill primary buttons (`{rounded.full}`). Cards at `{rounded.lg}`. Marketing may use `{rounded.xl}` feature tiles.

## Do's and Don'ts

### Do

- Pair one gradient hero with mostly flat app surfaces.
- Use display type only in marketing headers, not dense app tables.
- Keep one primary CTA per hero.

### Don't

- Don't gradient every button.
- Don't use low-contrast gray text on dark backgrounds for body copy.
- Don't mix pill marketing buttons with square app buttons without reason.
