# Design System Learnings

Patterns for UI and design system in this codebase.

---

## Token Usage

- **DESIGN.md is source of truth for agents** — `tokens.md` is spec shorthand; keep them in sync via `/design-tokens`.
- **Read archetype references** before generating a new system — structure (component variants, Do's/Don'ts) matters as much as hex values.
- **preview.html** — regenerate after DESIGN.md edits (`/design-tokens preview`).

## Component Patterns

- Define button/input/card variants in DESIGN.md YAML (`button-primary-hover`, etc.) not only in prose.

## External References

- Archetypes: `.specs/design-system/references/`
- Optional brand depth: [getdesign.md](https://getdesign.md/) — adapt, don't copy identity
- Format: [Google DESIGN.md spec](https://github.com/google-labs-code/design.md)

---

## Responsive Design

<!-- Breakpoints, mobile-first patterns -->

_No learnings yet._

---

## Accessibility

<!-- ARIA, keyboard nav, screen readers -->

_No learnings yet._

---

## Animation

<!-- Motion patterns, transitions -->

_No learnings yet._
