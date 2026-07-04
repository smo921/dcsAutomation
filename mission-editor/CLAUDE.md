# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Electron-based desktop application for creating and configuring dynamic DCS World missions through a visual interface. The editor provides a user-friendly alternative to writing Lua code directly, targeting mission builders with mixed technical experience.

**Key Features:**
- Reference point system (bullseye, airbases, trigger zones, battle lines)
- Template library for prebuilt mission configurations
- Group configuration with visual forms
- Waypoint editor for route building
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
    │   ├── refpoints/   # Reference point editors (Bullseye, Airbase, Zone, BattleLine)
    │   ├── templates/   # Template library components
    │   ├── editor/      # Group/waypoint editors
    │   └── groups/      # Group management
    ├── stores/      # Pinia state management
    └── utils/       # Helper utilities
```

### Core Concepts

**Reference Point System:** All positioning is relative to configured reference points:
- **Bullseye** - Global X/Y coordinates for theater-wide positioning
- **Airbases** - Named locations; coordinates resolved via `Airbase.getByName()` at runtime
- **Trigger Zones** - Mission-defined zones for relative placement
- **Battle Lines** - Custom line segments for offset-based spawning

**Templates:** Prebuilt configurations stored in `config/templates/`:
- `air_templates.json` - Air units (AWACS, patrols, bombers)
- `ground_templates.json` - Ground units (convoy, SAM, armor)
- `support_templates.json` - Support assets (tankers, command posts)

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
Formats code with Prettier.

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

### Templates (`config/templates/`)
JSON files defining reusable mission configurations. Templates can be applied directly in the UI or modified as JSON.

## Export Formats

### JSON Export
Configuration exported as JSON with all reference points and groups. Useful for version control and external integration.

### Lua Export
Generates Lua code compatible with `mission_test.lua` and the MIST framework. Output follows the existing pattern:
```lua
createSector({
    name = "Group_Name",
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
| `template:load-all` | Load all templates from `config/templates/` |
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
