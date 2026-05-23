---
version: alpha
name: friendly-archetype
description: "Reference only. Warm, approachable product UI: cream surfaces, soft radii, teal or coral accent, comfortable 8px spacing."
colors:
  primary: "#0d9488"
  on-primary: "#ffffff"
  primary-hover: "#0f766e"
  primary-light: "#ccfbf1"
  canvas: "#faf9f7"
  surface-1: "#ffffff"
  surface-2: "#f5f4f1"
  ink: "#1c1917"
  ink-muted: "#57534e"
  ink-subtle: "#78716c"
  border: "#e7e5e4"
  success: "#16a34a"
  warning: "#eab308"
  error: "#ef4444"
typography:
  display:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 36px
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: -0.02em
  headline:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.3
  button:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.2
rounded:
  sm: 8px
  md: 10px
  lg: 12px
  xl: 16px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: 10px 16px
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
  button-secondary:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: 10px 16px
  card:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: 20px
  input:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: 10px 14px
---

## Overview

Friendly archetype feels human and inviting. Warm off-white canvas, white cards that lift slightly, rounded corners, and copy-forward layouts. Users may be less technical; flows stay short and labels use plain language.

**Use when:** collaboration tools, consumer productivity, onboarding-heavy products, teams products.

## Colors

Warm neutrals on `{colors.canvas}`. Primary is teal, coral, or soft purple depending on brand. `{colors.primary-light}` for selected states and info banners, not full-width fills.

## Typography

Rounded sans (Inter or similar). Slightly larger body (15px). Headlines friendly but not shouty. Sentence case for buttons and nav.

## Layout

8px spacing base. Card padding 20px+. Generous gaps between form fields (16px). Wizards and empty states are first-class.

## Elevation & Depth

Light shadow on cards: `0 1px 3px rgba(28,25,23,0.08)`. Modals slightly stronger. Prefer lift over heavy borders.

## Shapes

`{rounded.lg}` on cards, `{rounded.md}` on buttons and inputs. Avatars and tags may use `{rounded.full}`.

## Do's and Don'ts

### Do

- Use encouraging empty states with one clear CTA.
- Write button labels as verbs ("Create project", not "Submit").
- Show progress in multi-step flows.

### Don't

- Don't use jargon in labels when persona vocabulary is plain.
- Don't pack more than one primary action in a card.
- Don't use harsh pure black `#000000` on warm backgrounds.
