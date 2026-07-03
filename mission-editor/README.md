# DCS Mission Editor

An Electron-based desktop application for creating and configuring dynamic DCS World missions through a visual interface.

## Overview

The DCS Mission Editor provides a user-friendly interface for building dynamic mission elements without needing to write Lua code directly. It features:

- **Reference Point System** - Configure bullseye, airbases, trigger zones, and battle lines
- **Template Library** - Prebuilt component templates for common mission configurations
- **Group Configuration** - Visual form for configuring aircraft, ground units, and support assets
- **Waypoint Editor** - Build flight routes with multiple waypoint types
- **JSON/Lua Export** - Generate configuration files compatible with the DCS mission framework

## Project Structure

```
mission-editor/
├── main/                 # Electron main process
│   ├── index.js         # Main process entry
│   └── preload.js       # Context bridge for IPC
├── renderer/            # Vue.js renderer (UI)
│   ├── index.html       # HTML entry
│   └── src/
│       ├── main.js      # Vue app entry
│       ├── App.vue      # Root component
│       ├── stores/      # Pinia state management
│       └── components/  # Vue components
├── config/
│   └── templates/       # Template JSON files
├── electron.vite.config.js
└── package.json
```

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- DCS World installed (for testing generated missions)

### Installation

```bash
cd mission-editor
npm install
```

### Development

```bash
npm run dev
```

This starts:
1. Vite dev server on `http://localhost:5173`
2. Electron app that loads the renderer

### Build

```bash
npm run build
```

Output is placed in the `out/` directory:
- `out/main/index.js` - Electron main process
- `out/renderer/` - Built Vue app (HTML, JS, CSS)

### Run Build

```bash
npm run preview
```

This runs the built Electron app.

## Configuration

### Reference Points

The editor uses a unified coordinate reference system:

| Type | Description |
|------|-------------|
| Bullseye | Global X/Y coordinates for theater-wide positioning |
| Airbases | Named locations with dynamic lookup via `Airbase.getByName()` |
| Trigger Zones | Mission-defined zones for relative placement |
| Battle Lines | Custom line segments for offset-based spawning |

### Templates

Built-in templates are located in `config/templates/`:
- `air_templates.json` - Air units (AWACS, patrols, bombers)
- `ground_templates.json` - Ground units (convoy, SAM, armor)
- `support_templates.json` - Support assets (tankers, command posts)

Templates can be:
- Applied directly in the UI
- Modified as JSON files and reloaded
- Saved as custom templates

## Export

### JSON Export
Exports configuration as JSON with all reference points and groups. Useful for:
- Version control
- Sharing configurations
- Integration with external tools

### Lua Export
Generates Lua code compatible with `mission_test.lua` and the MIST framework. This output can be:
- Copied directly into DCS missions
- Used to generate complete `mission_test.lua` files
- Referenced for understanding the generated code structure

## Development

### Adding Components

Components are located in `renderer/src/components/`:
- `refpoints/` - Reference point editors (Bullseye, Airbase, Zone, Battle Line)
- `templates/` - Template library components
- `editor/` - Group and waypoint editors

### Adding Templates

Add JSON files to `config/templates/`:
```json
{
  "id": "custom_template",
  "name": "Custom Template",
  "description": "My custom configuration",
  "category": "air",
  "units": [...],
  "defaultPosition": {...}
}
```

## Technical Details

### Tech Stack
- **Electron** - Desktop framework
- **Vite** - Build tool and dev server
- **Vue 3** - UI framework with Composition API
- **Pinia** - State management

### Communication
Main and renderer processes communicate via IPC:
- `refpoints:load/save` - Reference point management
- `template:load-all` - Template library
- `file:save-json/lua` - Export operations

### Generated Lua Code

The editor generates Lua code using the existing mission framework patterns:
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

## Troubleshooting

### Build Errors
- Ensure all dependencies are installed: `npm install`
- Clear cache: `rm -rf node_modules out/` then `npm install`

### Dev Server Not Loading
- Verify the renderer is at the project root or update `root` in `electron.vite.config.js`
- Check `win.loadURL()` path in `main/index.js` matches the `outDir`

## License

ISC
