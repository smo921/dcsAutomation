# UI Component Standardization Analysis

**Date:** 2026-07-09  
**Project:** DCS Mission Editor (Electron/Vue)

> **Note:** This is a standalone app with no external users. Documentation and migration path are not maintained separately.

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

### Phase 1.5: Migration - COMPLETED (2026-07-09)

#### Migration Status

**Component Refactorings Completed:**
- [x] `Input.vue` - Updated to use `FormLabel` component
- [x] `InputGroup.vue` - Updated to use `FormLabel` component
- [x] `Select.vue` - Updated to use `FormLabel` component
- [x] `BullseyeEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `BaseReferenceEditor`
- [x] `AirbaseEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `BaseReferenceEditor`
- [x] `ZoneEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `BaseReferenceEditor`
- [x] `BattleLineEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `BaseReferenceEditor` with custom fields
- [x] `TemplateEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `FormLabel`, `EmptyState`
- [x] `GroupEditor.vue` - Migrated to use `FormInput`, `FormSelect`, `FormLabel`
- [x] `GroupManager.vue` - Refactored to use new `ListEditor` component
- [x] `ReferencePointManager.vue` - Container using standardized tab pattern
- [x] `TemplateLibrary.vue` - Uses `FormInput`, `EmptyState`, shared classes
- [x] `WaypointEditor.vue` - Uses `FormInput`, `FormSelect`, `FormGroup`

#### New Components Created:
- [x] **ListEditor.vue** - Reusable list + editor pattern with:
  - Scrollable list with custom height
  - Resizable divider between list and editor
  - v-model support for items
  - Empty state handling
  - Slot-based item rendering and editor customization

#### Base Components Created:
- [x] **BaseReferenceEditor.vue** - Base component for reference point editors with:
  - Shared header with title and add button
  - Empty state when list is empty
  - List items with name input and remove button
  - Modal for adding new items
  - Custom field slots for specialized data (coordinates, etc.)

### Current State Overview

### Directory Structure
```
mission-editor/src/renderer/src/
├── components/
│   ├── ui/                          # Shared UI components (15+ files)
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
│   │   ├── ReferencePointManager.vue # Container for different reference point types
│   │   ├── BaseReferenceEditor.vue  # (NEW) - Base component for editors
│   │   ├── BullseyeEditor.vue       # Uses BaseReferenceEditor
│   │   ├── AirbaseEditor.vue        # Uses BaseReferenceEditor
│   │   ├── ZoneEditor.vue           # Uses BaseReferenceEditor
│   │   └── BattleLineEditor.vue     # Uses BaseReferenceEditor with custom fields
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
│   ├── components/                  # Modular CSS (9 files)
│   │   ├── _buttons.css
│   │   ├── _forms.css
│   │   ├── _layout.css
│   │   ├── _components.css
│   │   ├── _list-editor.css
│   │   ├── _refpoint.css
│   │   ├── _templates.css
│   │   ├── _typography.css
│   │   └── _utils.css
│   ├── components.css               # (deprecated - use modular files)
│   ├── global.css
│   └── index.css
└── App.vue                          # Main application
```

## Remaining Work

### Priority 3: CSS Organization - COMPLETED

**components.css has been split** into modular files at `styles/components/`:
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

**Semantic CSS Variables Added:**
See `styles/tokens/colors.css`:
```css
/* Form (semantic) */
--color-form-background: var(--color-bg-2);
--color-form-border: var(--color-border);
--color-form-text: var(--color-text-0);
```

All components now use the modular CSS structure.

### Future Enhancements (Optional)

- **Data Display Components:**
  - `DataList.vue` - Consistent list display with badges
  - `DataGrid.vue` - Grid-based data display
  - `BadgeList.vue` - Group of badges

- **Component Enhancements:**
  - `EditorPanel.vue` - Standard editor container with toolbar
  - `CollapsiblePanel.vue` - More flexible than CollapsibleSection

## Benefits of Standardization

1. **Reduced Maintenance** - Less duplicated code
2. **Consistent UX** - Same look/feel everywhere
3. **Faster Development** - Reusable components
4. **Easier Testing** - Isolated components
5. **Smoother Onboarding** - Predictable patterns

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
| BullseyeEditor | COMPLETED | Uses BaseReferenceEditor base component |
| AirbaseEditor | COMPLETED | Uses BaseReferenceEditor base component |
| ZoneEditor | COMPLETED | Uses BaseReferenceEditor base component |
| BattleLineEditor | COMPLETED | Uses BaseReferenceEditor with custom fields |
| ReferencePointManager | COMPLETED | Container component for all reference point types |
| TemplateLibrary | COMPLETED | Uses FormInput, EmptyState, shared classes |
| WaypointEditor | COMPLETED | Uses FormInput, FormSelect, FormGroup |
