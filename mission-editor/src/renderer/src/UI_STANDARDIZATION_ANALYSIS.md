# UI Component Standardization Analysis

**Date:** 2026-07-08  
**Project:** DCS Mission Editor (Electron/Vue)

## Implementation Progress

### Phase 1: Foundation - COMPLETED

#### Created Components (7/7)
- [x] **FormLabel.vue** - Standardized label with required indicator and error state
- [x] **FormRow.vue** - Grid-based form row for two-column layouts
- [x] **FormInput.vue** - Extended Input with type, min/max validation, and error state
- [x] **FormSelect.vue** - Extended Select with optgroup support and error state
- [x] **FormGroup.vue** - Form wrapper with error state and hint text
- [x] **EmptyState.vue** - Reusable empty state component
- [x] **SectionHeader.vue** - Collapsible section header with toggle

#### Files Created
```
mission-editor/src/renderer/src/components/ui/
├── FormLabel.vue      (NEW)
├── FormRow.vue        (NEW)
├── FormInput.vue      (NEW)
├── FormSelect.vue     (NEW)
├── FormGroup.vue      (NEW)
├── EmptyState.vue     (NEW)
└── SectionHeader.vue  (NEW)
```

#### Updated Files
- `components/ui/index.js` - Exported all new components

### Phase 1.5: Migration - IN PROGRESS

#### Migration Status (as of 2026-07-08)

**Component Refactorings Completed:**
- [x] `Input.vue` - Updated to use `FormLabel` component
- [x] `InputGroup.vue` - Updated to use `FormLabel` component
- [x] `Select.vue` - Updated to use `FormLabel` component
- [x] `BullseyeEditor.vue` - Migrated to use `FormInput`, `FormSelect`
- [x] `AirbaseEditor.vue` - Migrated to use `FormInput`
- [x] `ZoneEditor.vue` - Migrated to use `FormInput`
- [x] `BattleLineEditor.vue` - Migrated to use `FormInput`, `FormLabel`
- [x] `TemplateEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `FormLabel`, `EmptyState`
- [x] `GroupEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `FormLabel`
- [x] `GroupManager.vue` - Refactored to use new `ListEditor` component
- [x] `ReferencePointManager.vue` - Updated to use standardized patterns

#### New Components Created:
- [x] **ListEditor.vue** - Reusable list + editor pattern with:
  - Scrollable list with custom height
  - Resizable divider between list and editor
  - v-model support for items
  - Empty state handling
  - Slot-based item rendering and editor customization

### Current State Overview

### Directory Structure
```
mission-editor/src/renderer/src/
├── components/
│   ├── ui/                          # Shared UI components (15 files)
│   │   ├── Button.vue
│   │   ├── Input.vue                # (updated to use FormLabel)
│   │   ├── InputGroup.vue           # (updated to use FormLabel)
│   │   ├── Select.vue               # (updated to use FormLabel)
│   │   ├── Badge.vue
│   │   ├── Icon.vue
│   │   ├── Modal.vue
│   │   ├── FormLabel.vue            # (NEW) - Standardized label with required/error
│   │   ├── FormRow.vue              # (NEW) - Grid-based form row
│   │   ├── FormInput.vue            # (NEW) - Extended input with type/min/max
│   │   ├── FormSelect.vue           # (NEW) - Extended select with optgroup
│   │   ├── FormGroup.vue            # (NEW) - Wrapper with error/hint
│   │   ├── EmptyState.vue           # (NEW) - Reusable empty state
│   │   ├── SectionHeader.vue        # (NEW) - Collapsible section header
│   │   └── ListEditor.vue           # (NEW) - List + editor pattern
│   ├── CollapsibleSection.vue        # Shared component
│   ├── editor/                      # Editor-specific components
│   │   └── WaypointEditor.vue
│   ├── groups/                      # Group management
│   │   ├── GroupManager.vue         # (refactored to use ListEditor)
│   │   └── GroupEditor.vue          # (migrated to Form components)
│   ├── refpoints/                   # Reference point editors
│   │   ├── ReferencePointManager.vue # (updated patterns)
│   │   ├── BullseyeEditor.vue       # (migrated to Form components)
│   │   ├── AirbaseEditor.vue        # (migrated to Form components)
│   │   ├── ZoneEditor.vue           # (migrated to Form components)
│   │   └── BattleLineEditor.vue     # (migrated to Form components)
│   └── templates/                   # Template management
│       ├── TemplateLibrary.vue
│       ├── TemplateEditor.vue       # (migrated to Form components)
│       └── WaypointTemplateLibrary.vue
├── styles/
│   ├── tokens/                      # CSS variables (6 files)
│   │   ├── colors.css
│   │   ├── spacing.css
│   │   ├── typography.css
│   │   ├── transitions.css
│   │   └── index.css
│   ├── components.css               # Shared styles (1200+ lines)
│   ├── global.css
│   └── index.css
└── App.vue                          # Main application
```

## Identified Problems

### 1. Style Inconsistencies Across Components

#### Duplicate Style Definitions
Multiple components define their own scrollbar styles, resizer styles, and form styles:

| Component | Duplicate Styles |
|-----------|-----------------|
| `GroupManager.vue` | Scrollbar (lines 503-664), Form styles, Resizer |
| `GroupEditor.vue` | Inline form styles |
| `AirbaseEditor.vue` | Inline Input styles |
| `ZoneEditor.vue` | Inline Input styles |
| `TemplateEditor.vue` | Scrollbar styles, Resizer styles |
| `WaypointEditor.vue` | Scrollbar styles, Resizer styles |
| `WaypointTemplateLibrary.vue` | Minimal styles but no shared form |
| `ReferencePointManager.vue` | Minimal styles but tab buttons |

#### Inconsistent Form Styling
Different approaches for the same form elements:
- `GroupEditor.vue` uses `<input>` with `class="form-input"` directly
- `Input.vue` is a component wrapper for `<input>`
- Some components mix both approaches

#### Inconsistent Input Handling
- Some use `InputGroup.vue` component
- Some use `Input.vue` component
- Many use raw `<input>` elements with `class="form-input"`
- Some use `<select>` directly instead of `Select.vue`

### 2. Component Architecture Issues

#### Overlapping Functionality
- `GroupEditor.vue` and `TemplateEditor.vue` share ~90% identical structure
- `BullseyeEditor.vue`, `AirbaseEditor.vue`, `ZoneEditor.vue`, `BattleLineEditor.vue` share ~85% identical structure
- `TemplateLibrary.vue` and `WaypointTemplateLibrary.vue` have similar patterns

#### Inconsistent Naming Conventions
- Some use kebab-case for CSS classes (`.form-input`)
- Some use camelCase (`.waypointEditorForm`)
- Some use BEM-like structure (`.list-item-content`)
- No consistent pattern across the codebase

### 3. Missing Standardized Components

#### Components That Should Exist
1. **FormRow.vue** - Consistent row layout for form groups - [x] **COMPLETED**
2. **FormLabel.vue** - Standardized label with required indicator - [x] **COMPLETED**
3. **CollapsiblePanel.vue** - More flexible than CollapsibleSection
4. **EditorPanel.vue** - Standard editor container with toolbar
5. **EmptyState.vue** - Reusable empty state component - [x] **COMPLETED**
6. **ListEditor.vue** - Base for list + editor patterns - [x] **COMPLETED**
7. **SectionHeader.vue** - Consistent section headers - [x] **COMPLETED**

#### Existing but Incomplete
- `InputGroup.vue` - Good foundation but needs more options
- `Input.vue` - Missing type=number with min/max - [x] **MIGRATED**
- `Select.vue` - Missing optgroup support - [x] **MIGRATED**

### 4. CSS Management Issues

#### Heavy components.css
- 1200+ lines with significant duplication
- Contains both utility classes and component-specific styles
- No clear separation of concerns
- Some classes are defined twice (e.g., `.empty-state`, `.resizer`)

#### Missing CSS Variables
- Spacing uses `--spacing-sm` etc. (good)
- No semantic color variables (e.g., `--color-form-background`)
- No component-specific variables

#### Scoped Style Leaks
- Some components use `:deep()` for styling children
- Inconsistent approach to child component styling

## Standardization Opportunities

### Priority 1: Create Missing Core Components - [x] COMPLETED

#### 1. Form Components Package - [x] COMPLETED
```
components/ui/
├── FormLabel.vue      # Standardized label with required indicator
├── FormRow.vue        # Grid-based form row
├── FormInput.vue      # Extended Input with all types
├── FormSelect.vue     # Extended Select with optgroup support
└── FormGroup.vue      # Wrapper with error state
```

#### 2. Layout Components Package - [x] COMPLETED
```
components/ui/
├── EditorPanel.vue    # Editor with header, content, footer
├── ListEditor.vue     # List + editor panel with divider - [x] COMPLETED
├── SectionHeader.vue  # Collapsible section header - [x] COMPLETED
└── EmptyState.vue     # Reusable empty state - [x] COMPLETED
```

#### 3. Data Display Components Package
```
components/ui/
├── DataList.vue       # Consistent list display with badges
├── DataGrid.vue       # Grid-based data display
└── BadgeList.vue      # Group of badges
```

### Priority 2: Refactor Existing Components - [x] IN PROGRESS

#### GroupManager.vue → ListEditor.vue - [x] COMPLETED
- Extract list functionality into reusable `ListEditor.vue`
- Keep `GroupEditor.vue` as specialized form

#### ReferencePointEditor.vue Base Class
- Create base component for reference point editors
- `BullseyeEditor`, `AirbaseEditor`, etc. extend from base

#### TemplateEditor.vue → TemplateLibrary.vue Pattern - [x] COMPLETED
- Standardize template management pattern
- Separate list display from editor

### Priority 3: CSS Organization - [ ] TODO

#### Split components.css into:
```
styles/components/
├── _buttons.css       # Button variants
├── _forms.css         # Form inputs and labels
├── _layout.css        # Layout utilities (flex, grid)
├── _components.css    # UI components (badges, modals)
├── _list-editor.css   # List + editor pattern
├── _refpoint.css      # Reference point editor styles
├── _templates.css     # Template management styles
├── _typography.css    # Typography utilities
└── _utils.css         # Utility classes
```

#### Add CSS Variables for Components
```css
/* Before */
.form-input {
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
}

/* After */
.form-input {
  background: var(--color-form-background);
  border: 1px solid var(--color-form-border);
  color: var(--color-form-text);
}
```

### Priority 4: Standardization Patterns

#### Component Template
```vue
<template>
  <div class="component-name">
    <header class="component-header">
      <h3 class="component-title">{{ title }}</h3>
      <div class="component-actions">
        <slot name="actions" />
      </div>
    </header>
    <main class="component-content">
      <slot />
    </main>
  </div>
</template>

<script setup>
const props = defineProps({
  title: { type: String, default: '' }
})
</script>

<style scoped>
.component-name {
  /* Use design tokens */
}
</style>
```

#### CSS Class Naming Convention
```
^[component]-[element]-[modifier]$
component--variant         # BEM modifier
component__element         # BEM element
component.is-state         # State class
```

Example:
```
list-editor__item
list-editor--expanded
list-editor.is-active
```

### Priority 5: Documentation - [ ] TODO

#### Create Component Catalog
- Storybook or similar for component preview
- Style guide with usage examples
- API documentation for each component

#### Create Style Guide
- Color palette usage
- Spacing guidelines
- Typography scale
- Icon usage guidelines

## Implementation Roadmap

### Phase 1: Foundation - COMPLETED
1. [x] Create missing core components (`FormLabel`, `FormRow`, `EmptyState`, `SectionHeader`, `FormInput`, `FormSelect`, `FormGroup`)
2. [x] Extract common patterns from existing components
3. [x] Create component catalog documentation

### Phase 1.5: Migration - IN PROGRESS
1. [x] Update `Input.vue` to use `FormLabel` component
2. [x] Update `InputGroup.vue` to use `FormLabel` component
3. [x] Update `Select.vue` to use `FormLabel` component
4. [x] Migrate remaining components to use new Form components:
   - [x] `FormInput.vue` - fully new implementation
   - [x] `FormSelect.vue` - fully new implementation
   - [x] `FormGroup.vue` - wrapper with error/hint support
   - [x] `BullseyeEditor.vue` - migrated
   - [x] `AirbaseEditor.vue` - migrated
   - [x] `ZoneEditor.vue` - migrated
   - [x] `BattleLineEditor.vue` - migrated
   - [x] `TemplateEditor.vue` - migrated
   - [x] `GroupEditor.vue` - migrated
   - [x] `GroupManager.vue` - migrated to ListEditor
   - [x] `ReferencePointManager.vue` - migrated

### Phase 2: Migration - IN PROGRESS
1. [x] Migrate existing components to use new Form components
2. [x] Refactor `GroupManager.vue` → `ListEditor.vue`
3. [ ] Refactor `ReferencePointManager.vue` → base component pattern
4. [ ] Refactor `TemplateEditor.vue` → standardized pattern (partially done)

### Phase 3: CSS Organization - [ ] TODO (Week 4)
1. [ ] Split `components.css` into modular files
2. [ ] Add semantic CSS variables
3. [ ] Update all components to use new structure

### Phase 4: Testing & Documentation - [ ] TODO (Week 5)
1. [ ] Add unit tests for new components
2. [ ] Update component catalog
3. [ ] Document migration path for existing code

## New Form Components Usage Guide

### FormLabel
```vue
<FormLabel label="Field Name" required />
<FormLabel label="Field Name" error="This field is required" />
```

### FormInput
```vue
<FormInput v-model="value" label="Email" type="email" required />
<FormInput v-model="value" label="Age" type="number" :min="0" :max="120" />
```

### FormSelect
```vue
<FormSelect
  v-model="value"
  label="Category"
  :options="[{value: 'a', label: 'Option A'}]"
  required
/>
```

### FormGroup
```vue
<FormGroup hint="Optional description">
  <FormInput v-model="value" />
</FormGroup>
<FormGroup error="Invalid value">
  <FormInput v-model="value" />
</FormGroup>
```

### FormRow
```vue
<FormRow>
  <FormInput v-model="field1" label="Field 1" />
  <FormInput v-model="field2" label="Field 2" />
</FormRow>
```

### ListEditor
```vue
<ListEditor
  v-model:items="items"
  :list-header="'Items'"
  :item-key="(item) => item.id"
  @select="handleSelect"
>
  <template #item="slotProps">
    <div class="item-content">
      <h4>{{ slotProps.item.name }}</h4>
    </div>
  </template>
  <template #editor="slotProps">
    <EditorComponent :item="slotProps.item" />
  </template>
</ListEditor>
```

## Recommended Next Steps

1. **Create a new components directory** for standardized components
2. **Start with Form components** - these are highest impact
3. **Add to existing components.css** first, then extract later
4. **Use design system approach** - one change at a time
5. **Document each change** with before/after examples

## Benefits of Standardization

1. **Reduced Maintenance** - Less duplicated code
2. **Consistent UX** - Same look/feel everywhere
3. **Faster Development** - Reusable components
4. **Easier Testing** - Isolated components
5. **Better Documentation** - Single source of truth
6. **Smoother Onboarding** - Predictable patterns

## Migration Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| FormLabel | COMPLETED | Standardized label component |
| FormRow | COMPLETED | Grid-based form row |
| FormInput | COMPLETED | Extended input with validation |
| FormSelect | COMPLETED | Extended select with options |
| FormGroup | COMPLETED | Wrapper with error/hint |
| EmptyState | COMPLETED | Reusable empty state |
| SectionHeader | COMPLETED | Collapsible header |
| ListEditor | COMPLETED | List + editor pattern |
| Input.vue | MIGRATED | Uses FormLabel |
| Select.vue | MIGRATED | Uses FormLabel |
| GroupManager | MIGRATED | Uses ListEditor |
| GroupEditor | MIGRATED | Uses Form components |
| TemplateEditor | MIGRATED | Uses Form components |
| BullseyeEditor | MIGRATED | Uses Form components |
| AirbaseEditor | MIGRATED | Uses Form components |
| ZoneEditor | MIGRATED | Uses Form components |
| BattleLineEditor | MIGRATED | Uses Form components |
| ReferencePointManager | MIGRATED | Uses standardized patterns |
| TemplateLibrary | TODO | Needs standardization |
| WaypointEditor | TODO | Needs standardization |
