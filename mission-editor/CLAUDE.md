# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Electron-based desktop application for creating and configuring dynamic DCS World missions through a visual interface. The editor provides a user-friendly alternative to writing Lua code directly, targeting mission builders with mixed technical experience.

**Key Features:**
- Reference point system (bullseye, airbases, trigger zones, battle lines)
- Unit template library for prebuilt mission configurations
- Unit configuration with visual forms
- Route template editor for waypoint building
- JSON/Lua export for integration with the existing mission framework

## Architecture

### High-Level Structure

```
main/              # Electron main process (Node.js)
├── index.js       # Main process entry point, window management, IPC
└── preload/       # Context bridge configuration

renderer/          # Vue.js renderer (UI layer)
└── src/
    ├── main.js    # Vue app entry point
    ├── App.vue    # Root component
    ├── components/# Vue components organized by feature:
    │   ├── refpoints/       # Reference point editors (Bullseye, Airbase, Zone, BattleLine)
    │   ├── unitTemplates/   # Unit template library components
    │   ├── routeTemplates/  # Route template library components
    │   ├── units/           # Unit management
    │   └── editor/          # Waypoint editor
    ├── stores/      # Pinia state management
    └── utils/       # Helper utilities
```

### Core Concepts

**Reference Point System:** All positioning is relative to configured reference points:
- **Bullseye** - Global X/Y coordinates for theater-wide positioning
- **Airbases** - Named locations; coordinates resolved via `Airbase.getByName()` at runtime
- **Trigger Zones** - Mission-defined zones for relative placement
- **Battle Lines** - Custom line segments for offset-based spawning

**Unit Templates:** Prebuilt configurations stored in `config/unit_templates/`:
- `air.json` - Air units (AWACS, patrols, bombers)
- `ground.json` - Ground units (convoy, SAM, armor)
- `naval.json` - Naval units
- `support.json` - Support assets (tankers, command posts)

**Route Templates:** Prebuilt waypoint sequences stored in `config/route_templates/`:
- Reusable route definitions for units

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Desktop | Electron | Desktop framework for cross-platform |
| Build | Vite | Fast development server and production build |
| UI | Vue 3 | Reactive UI with Composition API |
| State | Pinia | Vue-native state management |
| IPC | Native IPC | Main/renderer process communication |

## Development Commands

### Installation
```bash
npm install
```

### Development
```bash
npm run dev
```
Starts Vite dev server and Electron app simultaneously.

### Build
```bash
npm run build
```
Outputs to `out/` directory:
- `out/main/index.js` - Electron main process
- `out/renderer/` - Built Vue application

### Preview Build
```bash
npm run preview
```
Runs the built Electron application for testing.

### Linting
```bash
npm run lint
```
Fixes ESLint issues automatically.

### Formatting
```bash
npm run format
```
Formats code with Pretter.

### UI Component Library

The app includes a library of reusable UI components in `src/renderer/src/components/ui/`:

**Modal** (`Modal.vue`):
- `v-model:open` - Control visibility
- `title` - Modal title
- `close-text` - Close button text (default: "Close")
- `closable` - Show close button (default: true)
- `closeOnBackground` - Close on background click (default: true)
- Slots: `content`, `actions`
- Features: Focus trap, Escape key close, accessible

**Button** (`Button.vue`):
- `variant` - Button style: `primary`, `danger`, `secondary`, `ghost`
- `size` - Button size: `sm`, `md`, `lg`
- `type` - HTML type: `button`, `submit`, `reset`
- `disabled` - Disabled state
- `block` - Full width
- `iconOnly` - Circular icon button
- Slots: Default (label), `icon`

### Styling
The app uses CSS design tokens for consistent theming. All styles are located in `src/renderer/src/styles/`:

- **Token files** (`styles/tokens/`): Define CSS custom properties for colors, spacing, typography, and transitions
- **Global styles** (`styles/global.css`): Reset, utility classes, and universal styles
- **Component styles** (`styles/components.css`): Reusable component patterns

#### Design Tokens

**Colors** (`src/renderer/src/styles/tokens/colors.css`):
- Backgrounds: `--color-bg-0` through `--color-bg-4`
- Text: `--color-text-0` through `--color-text-4`
- Primary: `--color-primary`, `--color-primary-hover`
- Status: `--color-success`, `--color-success-hover`, `--color-error`, `--color-error-hover`, `--color-warning`
- Borders: `--color-border`, `--color-border-focus`

**Spacing** (`src/renderer/src/styles/tokens/spacing.css`):
- Scale: `--spacing-xxs` (2px) through `--spacing-4xl` (40px)

**Typography** (`src/renderer/src/styles/tokens/typography.css`):
- Font family, sizes (`--font-size-xxs` through `--font-size-3xl`)
- Weights (`--font-weight-normal`, `--font-weight-medium`, `--font-weight-semibold`, `--font-weight-bold`)
- Line heights, letter spacing

**Transitions** (`src/renderer/src/styles/tokens/transitions.css`):
- `--transition-fast`, `--transition-normal`, `--transition-slow`

#### Reusable Component Classes

**Buttons** (`styles/components.css`):
- `.btn-primary`, `.btn-danger`, `.btn-secondary`, `.btn-ghost`
- Size modifiers: `.btn-sm`, `.btn-lg`
- Icon buttons: `.btn-icon-only`
- Block buttons: `.btn-block`

**Forms**:
- `.form-row`, `.form-group`, `.form-input`, `.form-select`

**Layout**:
- `.resizer`, `.resizer-line`
- `.list-container`, `.list-item`, `.list-header`
- `.editor-panel`, `.editor-section`

**Badges**:
- `.badge-primary`, `.badge-success`, `.badge-error`, `.badge-info`

**Collapsible Section**:
- `.collapsible-section`, `.section-header`, `.section-title`
- `.toggle-icon` (rotates with `.expanded` class)
- `.section-content` (slides down with animation)

### UI Component Development Guidelines

**Before creating new components or CSS:**

1. **Check existing shared components** in `src/renderer/src/components/ui/`:
   - `FormLabel`, `FormInput`, `FormSelect`, `FormRow` - Form input components
   - `Button`, `Badge`, `Input`, `InputGroup`, `Select` - UI components
   - `EditorPanel`, `CollapsiblePanel` - Layout components
   - `EmptyState`, `SectionHeader`, `ListEditor` - Utility components
   - `BaseReferenceEditor` - Base component for reference point editors

2. **Check existing shared styles** in `src/renderer/src/styles/components/_components.css`:
   - `.editor-panel`, `.editor-content`, `.editor-section` - Editor layout
   - `.empty-state` - Empty state display
   - `.unit-row`, `.waypoint-row` - Unit/waypoint list items
   - `.btn-remove`, `.btn-icon-only` - Button styles
   - `.resizer-line`, `.content-resizer` - Resizable divider styles

3. **Check composables** in `src/renderer/src/composables/`:
   - `useResize` - For resizable dividers between list and detail panes

4. **Follow existing patterns** in:
   - `UnitEditor.vue` - Standard 2-pane editor pattern
   - `UnitTemplateEditor.vue` - Unit template editor with list + form
   - `RouteTemplateEditor.vue` - Route template editor with list + form
   - `ReferencePointManager.vue` - Reference point management with detail editor

**When to create new components:**
- Only when no existing component provides the required functionality
- New components should extend shared patterns, not duplicate them
- All new components must use shared form components (`FormLabel`, `FormInput`, etc.)

**Component structure template:**
```vue
<template>
  <EditorPanel title="My Editor" variant="primary">
    <div class="editor-content">
      <CollapsiblePanel title="Section">
        <div class="editor-section">
          <FormRow>
            <div class="form-group">
              <FormLabel label="Field Name" />
              <FormInput v-model="fieldValue" />
            </div>
          </FormRow>
        </div>
      </CollapsiblePanel>
    </div>
  </EditorPanel>
</template>

<script setup>
import { FormLabel, FormInput, FormRow, EditorPanel, CollapsiblePanel } from '../ui'
</script>

<style scoped>
/* Only add styles not covered by shared components */
</style>
```

#### Utility Classes (`styles/global.css`):
- Text sizing: `.u-text-xs`, `.u-text-sm`, etc.
- Spacing: `.u-spacing-xs`, `.u-spacing-sm`, etc.
- Layout: `.u-flex`, `.u-grid`, `.u-hidden`
- Interaction: `.u-pointer`, `.u-select-none`

### UI Component Library

## Configuration

### Reference Points (`config/refpoints.json`)
Defines all reference points used for coordinate positioning:
```json
{
  "bullseyes": [{"name": "BULLSEYE_ALPHA", "x": 123456, "y": 654321}],
  "airbases": [{"name": "Kaliningrad", "x": 120000, "y": 700000}],
  "trigger_zones": [{"name": "Frontline_Zone", "x": 150000, "y": 650000, "radius": 5000}],
  "battle_lines": [{"name": "BLUE Front", "start": {"x": 100000, "y": 600000}, "end": {"x": 200000, "y": 700000}}]
}
```

### Unit Templates (`config/unit_templates/`)
JSON files defining reusable mission unit configurations. Templates can be applied directly in the UI or modified as JSON.

### Route Templates (`config/route_templates/`)
JSON files defining reusable waypoint sequences for unit routes.

## Export Formats

### JSON Export
Configuration exported as JSON with all reference points and units. Useful for version control and external integration.

### Lua Export
Generates Lua code compatible with `mission_test.lua` and the MIST framework. Output follows the existing pattern:
```lua
createSector({
    name = "Unit_Name",
    triggerType = "IMMEDIATE",
    groups = {
        createGroup("Unit_Name", "air", "Unit_Type", 3,
            getPointFromReference("Reference", bearing, distance), 
            heading, "Hot start")
    }
})
```

## Main/Renderer Communication (IPC)

| Channel | Purpose |
|---------|---------|
| `refpoints:load` | Load reference points from config |
| `refpoints:save` | Save reference points to config |
| `refpoints:loadFromFile` | Load reference points from selected file |
| `unit-template:load-all` | Load all unit templates from `config/unit_templates/` |
| `unit-template:save` | Save a unit template to `config/unit_templates/` |
| `unit-templates:load-from-files` | Load unit templates from selected files |
| `unit-templates:clear` | Clear all unit templates |
| `route-templates:load-from-files` | Load route templates from selected files |
| `route-templates:clear` | Clear all route templates |
| `config:load-json` | Load full configuration from JSON file |
| `config:load-sample` | Load sample configuration |
| `config:check` | Check which config files exist |
| `file:save-json` | Export configuration as JSON |
| `file:save-lua` | Export configuration as Lua code |

## Testing

### Running the App
After `npm run dev`, the Electron window loads the Vue renderer at `http://localhost:5173`.

### Build Verification
Run `npm run build` then `npm run preview` to test the packaged application.

## Integration with Lua Framework

The generated Lua code uses helper functions from `unit_management.lua`:
- `getPointFromReference(name, bearing, distance)` - Resolve airbase/zone coordinates
- `getPointFromBullseye(bearing, distance)` - Bullseye-based positioning
- `getPointFromZone(zoneName, bearing, distance)` - Zone-relative positioning
- `getPointFromLine(lineName, distance)` - Battle line positioning

**Important:** Airbase coordinates are NOT fetched from `.miz` files in the MVP. Users enter airbase names as seen in DCS Mission Editor; the Lua runtime resolves coordinates via `Airbase.getByName()`.

## Project Structure Notes

- **Source Location:** `src/main/` and `src/renderer/src/` (not `main/` and `renderer/` at root)
- **Output Location:** `out/` directory with `out/main/index.js` and `out/renderer/`
- **Build Config:** `electron.vite.config.js` - custom Vite configuration for Electron
- **Config Location:** `config/` directory with subdirectories for `unit_templates/`, `route_templates/`, and `refpoints.json`
