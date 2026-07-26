# Design Component Documentation

Document a component pattern in the design system. Use this to fill in component stubs or document new components.

## When to Use

- After implementing a component (fill in stub)
- Documenting existing components for design system
- Creating component patterns before implementation

## Behavior

### Fill In Existing Stub

If component stub exists in `.specs/design-system/components/{name}.md`:
1. Read the actual component source code
2. Extract props, variants, states
3. Fill in the stub template sections
4. Update status from "📝 Stub" to "✅ Documented"
5. Document design tokens used

### Create New Component Doc

If no stub exists:
1. Read the component source code
2. Create new component doc from template
3. Fill in all sections
4. Mark as "✅ Documented"

## Usage

### Document Specific Component
```
/design-component button
```
Documents the button component.

### Document Multiple Components
```
/design-component button card input
```
Documents multiple components in sequence.

### Document All Stubs
```
/design-component --all-stubs
```
Fills in all pending component stubs.

## Output Format

```markdown
## Component Documented: Button

**File**: `.specs/design-system/components/button.md`
**Status**: ✅ Documented (was: 📝 Stub)

### Props Documented
| Prop | Type | Description |
|------|------|-------------|
| variant | 'primary' \| 'secondary' \| 'ghost' | Button style variant |
| size | 'sm' \| 'md' \| 'lg' | Button size |
| disabled | boolean | Disabled state |
| loading | boolean | Loading state |

### Variants Documented
- Primary (default)
- Secondary
- Ghost
- Destructive

### States Documented
- Default ✅
- Hover ✅
- Active ✅
- Focused ✅
- Disabled ✅
- Loading ✅

### Design Tokens Used
- `color-primary`, `color-primary-hover`
- `spacing-3`, `spacing-4`
- `radius-md`
- `text-sm`, `text-base`

### Related Components
- IconButton
- ButtonGroup
```

## Component Documentation Structure

Each component doc should include:

### Required Sections
1. **Purpose** - What the component does
2. **Props/API** - All props with types and defaults
3. **Variants** - Visual variations
4. **States** - Interactive states

### Recommended Sections
5. **Anatomy** - ASCII diagram of internal structure
6. **Design Tokens Used** - Which tokens the component uses
7. **Accessibility** - A11y considerations
8. **Usage Examples** - Code examples

### Optional Sections
9. **Related Components** - Links to related components
10. **Changelog** - History of changes

## Example Component Doc

```markdown
# Button

**Status**: ✅ Documented
**Source File**: `components/ui/button.tsx`
**Last Updated**: 2024-01-15

---

## Purpose

Buttons trigger actions. Use buttons for form submissions, 
confirmations, and primary user actions.

---

## Props / API

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| variant | `'primary' \| 'secondary' \| 'ghost' \| 'destructive'` | `'primary'` | Visual style |
| size | `'sm' \| 'md' \| 'lg'` | `'md'` | Button size |
| disabled | `boolean` | `false` | Disabled state |
| loading | `boolean` | `false` | Shows spinner |
| leftIcon | `ReactNode` | - | Icon before text |
| rightIcon | `ReactNode` | - | Icon after text |
| fullWidth | `boolean` | `false` | Expands to container |

---

## Variants

| Variant | Usage |
|---------|-------|
| Primary | Main actions, form submissions |
| Secondary | Alternative actions |
| Ghost | Tertiary actions, less emphasis |
| Destructive | Delete, remove, dangerous actions |

---

## States

### Default
```
┌─────────────────────┐
│      Button         │
└─────────────────────┘
```

### Loading
```
┌─────────────────────┐
│   ◠ Loading...      │
└─────────────────────┘
```

---

## Design Tokens Used

| Token | Property |
|-------|----------|
| `color-primary` | Background (primary variant) |
| `color-primary-hover` | Background on hover |
| `color-text-inverse` | Text color (primary) |
| `spacing-3` | Horizontal padding (sm) |
| `spacing-4` | Horizontal padding (md) |
| `radius-md` | Border radius |
| `text-sm` | Font size (sm) |
| `text-base` | Font size (md, lg) |
| `duration-fast` | Hover transition |

---

## Accessibility

- ✅ Keyboard accessible (Enter, Space to activate)
- ✅ Focus ring visible
- ✅ Disabled state announced
- ✅ Loading state announced with aria-busy

---

## Usage Examples

```tsx
// Primary button
<Button>Submit</Button>

// Secondary with icon
<Button variant="secondary" leftIcon={<PlusIcon />}>
  Add Item
</Button>

// Loading state
<Button loading>Saving...</Button>

// Destructive
<Button variant="destructive">Delete</Button>
```
```

## Integration

- Stubs are created automatically by `/spec-first` when ASCII mockups reference new components
- Use `/design-component` after implementation to fill in details
- Component docs are referenced in feature specs under "Component References"
