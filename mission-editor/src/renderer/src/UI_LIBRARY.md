# UI Library Documentation

This document describes the standardized UI component library for the DCS Mission Editor Vue app.

## Table of Contents
- [Core Components](#core-components)
- [Form Components](#form-components)
- [Layout Components](#layout-components)
- [CSS Utilities](#css-utilities)
- [Design Tokens](#design-tokens)
- [Patterns & Best Practices](#patterns--best-practices)

---

## Core Components

### Button.vue
**Location:** `components/ui/Button.vue`

Standardized button component with variants and sizes.

**Props:**
```javascript
{
  variant: 'primary' | 'danger' | 'secondary' | 'ghost',
  size: 'sm' | 'md' | 'lg',
  type: 'button' | 'submit' | 'reset',
  disabled: boolean,
  block: boolean,  // full width
  iconOnly: boolean  // square button with just icon
}
```

**Usage:**
```vue
<Button variant="primary" @click="handleSave">Save</Button>
<Button variant="danger" size="sm">Delete</Button>
<Button variant="ghost" iconOnly>
  <template #icon>✕</template>
</Button>
```

**Available Variants:**
| Variant | Use Case |
|---------|----------|
| `primary` | Main actions (Save, Add, Submit) |
| `danger` | Destructive actions (Delete, Remove) |
| `secondary` | Secondary actions (Cancel, Close) |
| `ghost` | Minimal actions (icon-only, links) |

---

### Modal.vue
**Location:** `components/ui/Modal.vue`

Accessibility-focused modal dialog with focus trapping and keyboard support.

**Props:**
```javascript
{
  modelValue: boolean,        // controls open state
  title: string,              // modal title
  closable: boolean,          // show close button
  closeOnBackground: boolean, // click background to close
  closeText: string           // text on close button
}
```

**Slots:**
- `default` (actions): Footer content
- `content`: Main content area

**Usage:**
```vue
<Modal v-model:open="showModal" title="Confirm Action">
  <template #content>
    <p>Are you sure you want to proceed?</p>
  </template>
  <template #actions>
    <Button @click="confirm">Yes</Button>
    <Button variant="secondary" @click="cancel">No</Button>
  </template>
</Modal>
```

---

### Icon.vue
**Location:** `components/ui/Icon.vue`

Provides multiple SVG icons.

| Icon Name | Usage |
|-----------|-------|
| `plus` | Add new items |
| `minus` | Remove items |
| `trash` | Delete |
| `edit` | Modify |
| `x` | Close/dismiss |
| `chevronDown` | Expand/collapse down |
| `chevronUp` | Expand/collapse up |
| `search` | Search |
| `settings` | Settings |
| `alert` | Warning/alert |
| `check` | Success/checkmark |
| `info` | Information |

**Usage:**
```vue
<Button iconOnly>
  <template #icon><Icon name="plus" /></template>
</Button>
<Icon name="trash" />
```

---

### InputGroup.vue
**Location:** `components/ui/InputGroup.vue`

Standardized input with label and optional validation. This component combines label and input into a single component.

**Props:**
```javascript
{
  modelValue: string | number,
  label: string,
  placeholder?: string,
  type?: 'text' | 'number' | 'email' | 'password',
  error?: string,
  disabled?: boolean,
  required?: boolean,
  hint?: string
}
```

**Usage:**
```vue
<InputGroup v-model="name" label="Group Name" placeholder="Enter group name" />
<InputGroup v-model="count" label="Quantity" type="number" required />
<InputGroup v-model="description" label="Description" hint="Optional description" />
```

**Note:** For simpler cases, use `Input.vue` directly.

---

### Input.vue
**Location:** `components/ui/Input.vue`

Standardized input with label and optional validation. More flexible than InputGroup as it allows custom layout.

**Props:** Same as InputGroup.

**Usage:**
```vue
<Input v-model="name" label="Group Name" placeholder="Enter group name" />
<Input v-model="count" label="Quantity" type="number" required />
<Input v-model="description" label="Description" hint="Optional description" />
```

---

### Select.vue
**Location:** `components/ui/Select.vue`

Standardized select dropdown with label.

**Props:**
```javascript
{
  modelValue: any,
  label: string,
  options: Array<{ value: any, label: string }>,
  valueKey?: string,
  labelKey?: string,
  placeholder?: string,
  disabled?: boolean,
  required?: boolean,
  hint?: string
}
```

**Usage:**
```vue
<Select 
  v-model="category" 
  label="Category" 
  :options="[{ value: 'air', label: 'Air' }, { value: 'ground', label: 'Ground' }]" 
/>
```

---

### Badge.vue
**Location:** `components/ui/Badge.vue`

**Props:**
```javascript
{
  variant: 'primary' | 'success' | 'error' | 'info' | 'warning',
  size: 'sm' | 'md' | 'lg'
}
```

**Usage:**
```vue
<Badge variant="success">Completed</Badge>
<Badge variant="info" size="sm">{{ count }} items</Badge>
```

---

## Layout Components

### CollapsibleSection.vue
**Location:** `components/CollapsibleSection.vue`

Expansible section with header and content.

**Props:**
```javascript
{
  title: string,
  expanded: boolean  // v-model supported
}
```

**Usage:**
```vue
<CollapsibleSection v-model:expanded="showSettings" title="Settings">
  <div class="editor-section">
    <!-- content here -->
  </div>
</CollapsibleSection>
```

---

### EditorPanel.vue
**Location:** `components/layout/EditorPanel.vue`

Container for editor sections with header and scrollable content.

**Props:**
```javascript
{
  title: string,
  showHeader?: boolean
}
```

**Usage:**
```vue
<EditorPanel title="Configuration">
  <div class="editor-content">
    <CollapsibleSection title="Basic Settings">
      <!-- form content -->
    </CollapsibleSection>
  </div>
</EditorPanel>
```

---

### ListEditor.vue
**Location:** `components/layout/ListEditor.vue`

Reusable list + editor pattern for managing collections.

**Props:**
```javascript
{
  items: Array,
  labelKey: string,
  title: string,
  emptyStateText?: string
}
```

**Usage:**
```vue
<ListEditor 
  v-model="groups" 
  title="Groups" 
  :labelKey="'groupName'"
>
  <template #item="{ item }">
    <div class="editor-content">
      <!-- form for editing item -->
    </div>
  </template>
</ListEditor>
```

---

## CSS Utilities

### Button Classes (from `components.css`)
```css
/* Base button */
.btn

/* Variants */
.btn-primary, .btn-danger, .btn-secondary, .btn-ghost

/* Sizes */
.btn-sm, .btn-md, .btn-lg

/* Special */
.btn-icon, .btn-icon-only, .btn-block

/* Icon spacing */
.btn-icon-only .btn-icon { margin: 0; }
.btn:not(.btn-icon-only) .btn-icon { margin-right: var(--spacing-xs); }
```

### Form Classes (from `components.css`)
```css
/* Grid layout for form rows */
.form-row

/* Individual form group */
.form-group

/* Input elements */
.form-input, .form-select

/* Focus states (shared) */
.form-input:focus, .form-select:focus {
  outline: none;
  border-color: var(--color-border-focus);
  box-shadow: 0 0 0 2px rgba(14, 99, 156, 0.1);
}
```

### Layout Classes (from `components.css`)
```css
/* Flex fill for containers */
.flex-fill, .flex-fill-scroll

/* Resizer handle */
.resizer, .resizer-line

/* List items */
.list-container, .list-item, .list-header, .list-item-content, .list-item-actions

/* Editor panels */
.editor-panel, .editor-section, .editor-content

/* Modal */
.modal-overlay, .modal-content, .modal-header, .modal-body, .modal-actions

/* Tab buttons */
.tab-btn

/* Empty state */
.empty-state

/* Custom scrollbar */
.scrollbar-custom

/* Animations */
.fadeIn, .zoomIn, .slideDown
```

---

## Design Tokens

### Spacing (`styles/tokens/spacing.css`)
| Token | Value | Usage |
|-------|-------|-------|
| `--spacing-xxs` | 2px | Tight spacing |
| `--spacing-xs` | 4px | Small spacing |
| `--spacing-sm` | 8px | Regular spacing |
| `--spacing-md` | 12px | Medium spacing |
| `--spacing-lg` | 16px | Large spacing |
| `--spacing-xl` | 20px | Extra large spacing |
| `--spacing-2xl` | 24px | Section spacing |
| `--spacing-3xl` | 32px | Large section spacing |
| `--spacing-4xl` | 40px | Hero spacing |

### Colors (`styles/tokens/colors.css`)
**Backgrounds:**
| Token | Value | Usage |
|-------|-------|-------|
| `--color-bg-0` | #1e1e1e | App background |
| `--color-bg-1` | #252526 | Sidebar, panels |
| `--color-bg-2` | #3c3c3c | Inputs, badges |
| `--color-bg-3` | #454545 | Hover states |
| `--color-bg-4` | #2d2d30 | Active list items |

**Text:**
| Token | Value | Usage |
|-------|-------|-------|
| `--color-text-0` | #d4d4d4 | Primary text |
| `--color-text-1` | #888 | Secondary text |
| `--color-text-2` | #666 | Tertiary text |
| `--color-text-3` | #aaa | Labels |
| `--color-text-4` | #ffffff | Light text on dark |

**Status:**
| Token | Value | Usage |
|-------|-------|-------|
| `--color-primary` | #0e639c | Primary actions |
| `--color-success` | #1e7a3b | Success states |
| `--color-error` | #a31313 | Error states |
| `--color-warning` | #d69e2e | Warning states |

**Borders:**
| Token | Value | Usage |
|-------|-------|-------|
| `--color-border` | #3e3e42 | Default borders |
| `--color-border-focus` | #0e639c | Focus state |

### Typography (`styles/tokens/typography.css`)
**Font Sizes:**
| Token | Value | Usage |
|-------|-------|-------|
| `--font-size-xxs` | 10px | Tiny text |
| `--font-size-xs` | 11px | Small text |
| `--font-size-sm` | 12px | Body text |
| `--font-size-md` | 13px | Regular text |
| `--font-size-lg` | 14px | Headings |
| `--font-size-xl` | 16px | Subheadings |
| `--font-size-2xl` | 18px | Large headings |
| `--font-size-3xl` | 20px | Hero headings |

---

## Patterns & Best Practices

### 1. Editor Pattern
Use collapsible sections for grouping related settings:
```vue
<EditorPanel title="Editor">
  <CollapsibleSection v-model:expanded="expanded.section1" title="Section 1">
    <div class="editor-section">
      <!-- content -->
    </div>
  </CollapsibleSection>
  
  <CollapsibleSection v-model:expanded="expanded.section2" title="Section 2">
    <div class="editor-section">
      <!-- content -->
    </div>
  </CollapsibleSection>
</EditorPanel>
```

### 2. Form Pattern
Use form-row for two-column layouts:
```vue
<div class="form-row">
  <div class="form-group">
    <label>Label 1</label>
    <input class="form-input" v-model="value1" />
  </div>
  <div class="form-group">
    <label>Label 2</label>
    <input class="form-input" v-model="value2" />
  </div>
</div>
```

### 3. List Item Pattern
```vue
<div class="list-container">
  <div class="list-item">
    <div class="list-item-content">
      <h4>Item Name</h4>
      <p class="list-item-desc">Description</p>
    </div>
    <div class="list-item-actions">
      <Button variant="danger" size="sm" @click="remove">Remove</Button>
    </div>
  </div>
</div>
```

### 4. Empty State Pattern
```vue
<div v-if="items.length === 0" class="empty-state">
  <p>No items configured.</p>
  <p class="note">Click "Add Item" to create one.</p>
</div>
```

### 5. Modal Pattern
```vue
<Modal v-model:open="showModal" title="Title" closable>
  <template #content>
    <p>Message content here.</p>
  </template>
  <template #actions>
    <Button @click="confirm">Confirm</Button>
    <Button variant="secondary" @click="cancel">Cancel</Button>
  </template>
</Modal>
```

---

## Migration Guide

### Current Issues
1. **Inconsistent tab button styles** - Some components have their own tab styles instead of using shared CSS
2. **Duplicate scrollbar styles** - Scrollbar CSS repeated in many components
3. **Missing Input/Select components** - All forms inline their styles

### Steps to Fix

1. **Add missing tab button styles** to `components.css` - DONE
2. **Create standardized Input/Select components** - DONE
3. **Create Badge component** - DONE
4. **Create InputGroup wrapper component** - DONE
5. **Refactor existing components** to use standardized components - IN PROGRESS
6. **Update App.vue** to use new standardized components - IN PROGRESS

### Components Already Updated
- `GroupManager.vue` - Now uses shared `.list-container`, `.list-item`, and `.tab-btn` classes
- `components.css` - Contains all shared CSS classes

### New Components Created
| Component | File | Purpose |
|-----------|------|---------|
| `Input.vue` | `components/ui/Input.vue` | Standardized input with label |
| `Select.vue` | `components/ui/Select.vue` | Standardized select with label |
| `Badge.vue` | `components/ui/Badge.vue` | Colored badges for status indicators |
| `InputGroup.vue` | `components/ui/InputGroup.vue` | Combined label + input wrapper |
| `Icon.vue` | `components/ui/Icon.vue` | SVG icon component with multiple icons |

---

## File Structure

```
mission-editor/src/renderer/src/
├── components/
│   ├── ui/              # Reusable UI components
│   │   ├── Button.vue
│   │   ├── Modal.vue
│   │   ├── Icon.vue
│   │   ├── Input.vue
│   │   ├── InputGroup.vue
│   │   ├── Select.vue
│   │   └── Badge.vue
│   ├── layout/          # Layout components (future)
│   │   └── [feature]/
│   ├── groups/          # Group-specific components
│   │   ├── GroupManager.vue
│   │   └── GroupEditor.vue
│   ├── templates/       # Template-specific components
│   │   ├── TemplateLibrary.vue
│   │   ├── TemplateEditor.vue
│   │   └── WaypointTemplateLibrary.vue
│   ├── refpoints/       # Reference point components
│   │   ├── ReferencePointManager.vue
│   │   ├── BullseyeEditor.vue
│   │   ├── AirbaseEditor.vue
│   │   ├── ZoneEditor.vue
│   │   └── BattleLineEditor.vue
│   └── editor/          # Editor-specific components
│       └── WaypointEditor.vue
├── styles/
│   ├── tokens/          # Design tokens
│   │   ├── colors.css
│   │   ├── spacing.css
│   │   ├── typography.css
│   │   └── transitions.css
│   ├── components.css   # Shared component styles
│   └── global.css       # Global utilities
└── UI_LIBRARY.md        # This documentation
```
