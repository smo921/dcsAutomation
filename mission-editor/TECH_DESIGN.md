# DCS Dynamic Mission Editor - Technical Design Document (MVP)

> **Status**: Draft - 2026-07-02
> **Focus**: Foundational architecture and MVP scope
> **Updated**: 2026-07-06 - Template creation/editing in-app, GroupManager, scrollbar fixes
> **Deprioritized**: Battle lines, pattern generators, advanced map visualization

---

## Executive Summary

Build a minimal Electron-based desktop application that allows mission builders to create dynamic DCS mission elements through a simple form-based UI. The MVP focuses on core functionality: group creation, waypoint configuration, and JSON export.

**Key Architecture**: The system uses a unified coordinate reference system that supports multiple reference points:
- **Bullseye** - Global reference point (X/Y coordinates)
- **Airbases** - Named locations with dynamic lookup
- **Trigger Zones** - Mission-defined zones for placement relative to
- **Battle Lines** - Custom lines for offset-based spawning

This approach eliminates the need for complex map overlays while supporting the most common DCS mission planning patterns.

---

## MVP Scope - What We Build (and What We Don't)

### In Scope (MVP)
- [x] Electron app skeleton with basic window management
- [x] Group configuration form (name, unit type, quantity, coalition, reference point)
- [x] Waypoint editor (add/remove waypoints with basic fields)
- [x] Template library (built-in JSON templates)
- [x] JSON configuration export
- [x] Unified reference point system (bullseye, airbase, trigger zones)
- [x] Coordinate conversion utilities
- [x] Route planning via offset-based coordinates

### Out of Scope (Deprioritized)
- [ ] Visual map overlay with Leaflet/OpenLayers
- [ ] Static map image display
- [ ] Pixel-to-coordinate conversions
- [ ] Battle line / pattern generators (draw line on map)
- [ ] .miz file read/write (injection)
- [ ] Mission parsing from existing Lua files
- [ ] Zone drawing tool (trigger zone creation)
- [ ] Trigger configuration UI
- [ ] Advanced map features (overlays, zones, terrain)
- [ ] Template creation/editing in-app
- [ ] Multi-theater support
- [ ] Cloud sync or collaboration features

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DCS Mission Editor (Electron)                    │
│                                                                       │
│  ┌──────────────────┐         ┌──────────────────┐                  │
│  │   Renderer       │         │     Main         │                  │
│  │   (UI Layer)     │◄───────►│   (Logic)        │                  │
│  │                  │         │                  │                  │
│  │  - Vue Components│         │  - Reference     │                  │
│  │  - FormHandlers │         │    Point Manager │                  │
│  │      │           │         │  - Config        │                  │
│  │      ▼           │         │    Generator     │                  │
│  │  +------------+  │         │                  │                  │
│  │  | CoordEntry |  │         │  +------------+  │                  │
│  │  +------------+  │         │  | JSONWriter|  │                  │
│  └──────────────────┘         └──────────────────┘                  │
│                                └──────────────────┘                  │
│                                      │                               │
│                                      ▼                               │
│                            ┌──────────────────┐                     │
│                            │  Lua Generator  │                     │
│                            └──────────────────┘                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Architectural Shift**: Instead of visual map preview, the UI focuses on coordinate input relative to reference points (bullseye, airbases, trigger zones).

---

## Core Concept: Reference Point System

### Why Reference Points?

DCS missions use coordinate-based positioning, but mission planners typically think in terms of:
- **Bullseye** - Global reference for theater-wide positioning
- **Airbases** - Known locations that can be dynamically looked up
- **Trigger Zones** - Mission-specific zones for relative placement
- **Battle Lines** - Custom reference lines for offset-based spawning

This approach is simpler than map overlays while supporting all common DCS mission planning patterns.

### Reference Point Types

| Type | Description | Source | Use Case |
|------|-------------|--------|----------|
| `bullseye` | Global X/Y coordinates | User input | Theater-wide positioning |
| `airbase` | Named airbase location | DCS mission | Air operations from bases |
| `trigger_zone` | Zone defined in mission | Mission file | Relative to battle areas |
| `battle_line` | Custom line segment | User input | Linear deployment patterns |
| `direct_xy` | Absolute coordinates | User input | Exact positioning |

### Design Philosophy: Airbase Reference Handling

**Key Design Decision**: Airbase coordinates are NOT fetched from `.miz` files in the MVP. This avoids the complexity of `.miz` parsing in Phase 1 while still supporting the common use case.

**How It Works:**
1. User enters airbase name (as seen in DCS Mission Editor)
2. User manually enters X/Y coordinates for offline reference
3. At runtime, the Lua framework uses `mist.getAIRBASE_COORDS()` to resolve coordinates

**Future Enhancement** (Phase 5+): `.miz` parsing can auto-extract airbase coordinates, eliminating manual entry.

---

### Data Model Foundation

All configurations reference one of the supported reference point types:

```json
{
  "bullseye": {
    "name": "BULLSEYE_ALPHA",
    "x": 123456,
    "y": 654321
  },
  "airbases": [
    {
      "name": "Kaliningrad",
      "x": 120000,
      "y": 700000,
      "type": "airbase"
    }
  ],
  "trigger_zones": [
    {
      "name": "Frontline_Zone",
      "center": {"x": 150000, "y": 650000},
      "radius": 5000
    }
  ],
  "battle_lines": [
    {
      "name": "BLUE Front",
      "start": {"x": 100000, "y": 600000},
      "end": {"x": 200000, "y": 700000}
    }
  ],
  "groups": [
    {
      "name": "AWACS Patrol",
      "position": {
        "type": "bullseye_offset",
        "reference": "BULLSEYE_ALPHA",
        "bearing": 45,
        "distance": 50000
      },
      "units": [...]
    }
  ]
}
```

---

## Core Components

### 1. Main Process (Electron)

**File**: `main/index.js`

**Responsibilities:**
- App lifecycle management (startup, shutdown, window management)
- IPC communication with renderer
- File system access (read/write templates, config)
- Template storage management

**Key APIs:**
```javascript
// Window management
createWindow()
on('window-all-closed', ...)

// IPC handlers
ipcMain.handle('template:load', ...)
ipcMain.handle('config:generate', ...)
ipcMain.handle('file:save', ...)
```

---

### 2. Reference Point Manager

**File**: `main/refpoints/manager.js`

**Responsibilities:**
- Define and manage all reference point types (bullseye, airbases, zones, lines)
- Calculate X/Y coordinates from offsets relative to any reference type
- Store/retrieve reference configurations
- Provide named references for Lua generation
- **Airbase name-to-coordinate lookup via existing MIST functions** (no .miz parsing needed)

**Key Design Note**: Airbase coordinates are NOT fetched from `.miz` files in MVP. Instead, users enter airbase names they see in the DCS Mission Editor, and the existing Lua framework (`mist` library) handles coordinate lookup at runtime via `mist.getAIRBASE_COORDS()`.

**API:**
```javascript
// Define bullseye
refpoints.setBullseye(name, x, y)

// Define airbase (user enters name, coordinates come from Lua runtime)
refpoints.addAirbase(name, x, y, type)

// Define trigger zone
refpoints.addTriggerZone(name, centerX, centerY, radius)

// Define battle line
refpoints.setBattleLine(name, startX, startY, endX, endY)

// Calculate position from bullseye offset
refpoints.offsetToXY(bullseyeName, bearing, distance)

// Calculate position from airbase offset
refpoints.airbaseOffsetToXY(airbaseName, bearing, distance)

// Calculate position from zone center offset
refpoints.zoneOffsetToXY(zoneName, bearing, distance)

// Calculate position along battle line
refpoints.alongBattleLine(lineName, distanceFromStart)
```

---

### 3. Template Manager

**File**: `main/templates/manager.js`

**Responsibilities:**
- Load built-in templates from JSON files
- Template validation
- Template searching/filtering
- Provide default values

**Template Storage:**
```
config/templates/
├── air_unit_templates.json
├── ground_unit_templates.json
└── support_unit_templates.json
```

**Example Template Structure:**
```json
{
  "id": "awacs_patrol_su30",
  "name": "AWACS Patrol",
  "category": "air",
  "description": "Su-30 AWACS patrol with tanker support",
  "units": [
    {
      "name": "AWACS Lead",
      "type": "Su-30SM",
      "quantity": 1,
      "role": "awacs",
      "airbase": "Kaliningrad"
    },
    {
      "name": "Tanker 1",
      "type": "IL-78M",
      "quantity": 1,
      "role": "tanker",
      "airbase": "Kaliningrad"
    }
  ],
  "defaultRoute": {
    "type": "orbit",
    "radius": 15,
    "altitude": 5000,
    "speed": 700,
    "pattern": "clockwise"
  },
  "defaultPosition": {
    "type": "airbase",
    "reference": "Kaliningrad",
    "offset": {"bearing": 0, "distance": 0}
  }
}
```

---

### 4. Configuration Generator

**File**: `main/config/generator.js`

**Responsibilities:**
- Convert UI state to Lua configuration
- Generate group definitions
- Generate waypoint definitions
- Format output for `mission_test.lua`

**Input (UI State with Reference Point):**
```javascript
{
  groupName: "AWACS Patrol Alpha",
  coalition: "blue",
  units: [
    { type: "Su-30SM", quantity: 2, role: "awacs" },
    { type: "IL-78M", quantity: 1, role: "tanker" }
  ],
  position: {
    type: "airbase_offset",
    reference: "Kaliningrad",
    bearing: 45,
    distance: 10000
  },
  route: [
    { type: "takeoff", airbase: "Kaliningrad" },
    { type: "orbit", x: 12000, y: 70000, radius: 15, altitude: 5000 },
    { type: "land", airbase: "Kaliningrad" }
  ]
}
```

**Output (Lua Code):**
```lua
-- AWACS Patrol Alpha
createSector({
    name = "AWACS_Patrol_Alpha",
    triggerType = "IMMEDIATE",
    groups = {
        createGroup("AWACS_Patrol_Lead", "air", "Su-30SM", 2,
            getPointFromReference("Kaliningrad", 45, 10000), 180, "Hot start"),
        createGroup("AWACS_Patrol_Tanker", "air", "IL-78M", 1,
            getPointFromReference("Kaliningrad", 45, 10000), 180, "Hot start"),
    }
})
```

---

### 5. Waypoint Service

**File**: `main/waypoints/service.js`

**Responsibilities:**
- Waypoint type validation
- Coordinate calculations
- Route path generation
- Speed/altitude constraints per unit type

**Waypoint Types:**
```javascript
const WAYPOINT_TYPES = {
  TAKEOFF: 'takeoff',      // Airbase takeoff
  LANDING: 'landing',      // Airbase landing
  WAYPOINT: 'waypoint',    // Basic coordinate waypoint
  ORBIT: 'orbit',          // Loiter pattern
  DEAD_HEAD: 'dead_head',  // Target heading without orbit
  ATTACK: 'attack'         // Attack run
};
```

---

### 6. Reference Point Helpers

**File**: `main/refpoints/helpers.js`

**Responsibilities:**
- Convert all reference types to DCS-compatible `getPointFromReference()` format
- **Validation Layer**: Check all references exist in config before export
- Handle edge cases (invalid coordinates, missing references)

**Helper Functions:**
```javascript
// Generate Lua reference syntax
function toLuaReference(refType, refName, bearing, distance) {
  switch(refType) {
    case 'bullseye':
      return `getPointFromBullseye(${bearing}, ${distance})`;
    case 'airbase':
      // Airbase coordinates resolved via Airbase.getByName() at runtime
      return `getPointFromReference("${refName}", ${bearing}, ${distance})`;
    case 'trigger_zone':
      return `getPointFromZone("${refName}", ${bearing}, ${distance})`;
    case 'battle_line':
      return `getPointFromLine("${refName}", ${distance})`;
    default:
      return `{x=0, y=0}`;
  }
}

// Validation Layer: Check all references exist in config before export
function validateGeneratedConfig(config, refpoints) {
  const errors = [];
  
  // Check all referenced reference points exist
  if (config.position && config.position.reference) {
    if (!refpoints.has(config.position.reference)) {
      errors.push(`Reference point "${config.position.reference}" not defined`);
    }
  }
  
  // Check all referenced airbases exist
  if (config.route) {
    config.route.forEach((wp, idx) => {
      if (wp.airbase && !refpoints.airbases.find(ab => ab.name === wp.airbase)) {
        errors.push(`Waypoint ${idx}: airbase "${wp.airbase}" not found`);
      }
    });
  }
  
  // Check all referenced trigger zones exist
  if (config.trigger && config.trigger.zone && 
      !refpoints.trigger_zones.find(z => z.name === config.trigger.zone)) {
    errors.push(`Trigger zone "${config.trigger.zone}" not found`);
  }
  
  return errors;
}
```

**How Airbase Lookup Works in Generated Lua:**
The generated Lua code uses helper functions that call `Airbase.getByName()` to resolve coordinates (from `unit_management.lua:924`):
```lua
-- Example: Resolve airbase coordinates
local airbaseObj = Airbase.getByName("Kaliningrad")
if airbaseObj then
    local basePos = airbaseObj:getPosition().p
    -- Use basePos.x, basePos.z for coordinates
end
```

---

### 7. Coordinate Utilities

**File**: `renderer/utils/coords.js`

**Responsibilities:**
- All reference type offset calculations
- Direct X/Y coordinate entry
- Distance between two points
- Heading calculation between points

**Key Functions:**
```javascript
// Bullseye offset → X/Y
function bullseyeOffsetToXY(bullseyeX, bullseyeY, bearing, distance) {
  const rad = bearing * (Math.PI / 180);
  return {
    x: bullseyeX + distance * Math.sin(rad),
    y: bullseyeY + distance * Math.cos(rad)
  };
}

// Airbase offset → X/Y
function airbaseOffsetToXY(airbaseX, airbaseY, bearing, distance) {
  return bullseyeOffsetToXY(airbaseX, airbaseY, bearing, distance);
}

// Zone center offset → X/Y
function zoneOffsetToXY(zoneX, zoneY, bearing, distance) {
  return bullseyeOffsetToXY(zoneX, zoneY, bearing, distance);
}

// Position along battle line
function alongBattleLine(startX, startY, endX, endY, distance) {
  const totalLength = Math.sqrt((endX - startX) ** 2 + (endY - startY) ** 2);
  const ratio = Math.min(distance / totalLength, 1);
  return {
    x: startX + (endX - startX) * ratio,
    y: startY + (endY - startY) * ratio
  };
}

// X/Y → Bearing + Distance from reference
function xyToBearingDistance(refX, refY, targetX, targetY) {
  const dx = targetX - refX;
  const dy = targetY - refY;
  const distance = Math.sqrt(dx * dx + dy * dy);
  const bearing = (Math.atan2(dx, dy) * 180 / Math.PI + 360) % 360;
  return { bearing, distance };
}

// Distance between two points
function distanceBetween(x1, y1, x2, y2) {
  return Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2);
}

// Heading from point A to point B
function headingFromTo(x1, y1, x2, y2) {
  return (Math.atan2(x2 - x1, y2 - y1) * 180 / Math.PI + 360) % 360;
}
```

---

## Data Models (MVP)

### Group Model
```json
{
  "groupName": "string (required)",
  "coalition": "blue|red (required)",
  "country": "string (required)",
  "position": {
    "type": "bullseye_offset|airbase_offset|zone_offset|battle_line_offset|direct_xy",
    "reference": "string (name of reference point)",
    "bearing": "number (0-360, optional for some types)",
    "distance": "number (meters)",
    "x": "number (if direct_xy)",
    "y": "number (if direct_xy)"
  },
  "units": [
    {
      "type": "string (required)",
      "quantity": "integer (required)",
      "role": "string (optional)"
    }
  ],
  "airbase": "string (required for air units)",
  "parking": "hot_start|cold_start|parking_slot (required)",
  "parkingSlot": "number (optional)",
  "route": [
    {
      "type": "takeoff|waypoint|orbit|landing (required)",
      "x": "number (optional)",
      "y": "number (optional)",
      "altitude": "number (optional)",
      "speed": "number (optional)",
      "heading": "number (optional)",
      "radius": "number (optional for orbit)"
    }
  ]
}
```

### Template Model
```json
{
  "id": "string (required, unique)",
  "name": "string (required)",
  "description": "string",
  "category": "air|ground|naval|support",
  "units": [
    {
      "name": "string",
      "type": "string",
      "quantity": "integer",
      "role": "string"
    }
  ],
  "defaultRoute": "Route Model (optional)",
  "defaultPosition": {
    "type": "bullseye_offset|airbase_offset|zone_offset|battle_line_offset",
    "reference": "string",
    "bearing": "number",
    "distance": "number"
  }
}
```

### Reference Point Model
```json
{
  "bullseyes": [
    {
      "name": "BULLSEYE_ALPHA",
      "x": 123456,
      "y": 654321,
      "color": "#FF0000"
    }
  ],
  "airbases": [
    {
      "name": "Kaliningrad",
      "x": 120000,
      "y": 700000,
      "type": "airbase",
      "runwayHeading": 180,
      "freq": 125.0
    }
  ],
  "trigger_zones": [
    {
      "name": "Frontline_Zone",
      "x": 150000,
      "y": 650000,
      "radius": 5000,
      "color": "#00FF00"
    }
  ],
  "battle_lines": [
    {
      "name": "BLUE Front",
      "start": {"x": 100000, "y": 600000},
      "end": {"x": 200000, "y": 700000},
      "side": "blue"
    }
  ]
}
```

**Reference Point Notes:**
- **Airbases**: The `name` field is required. The `x` and `y` fields are optional (for offline configuration); at runtime, coordinates are resolved via `Airbase.getByName()` in `unit_management.lua`.
- **Battle Lines**: The `side` field (`blue` or `red`) is optional but recommended for coalition-specific positioning.

---

## Implementation Phases

### Phase 0: Foundation (Week 1)

**Goal**: Working Electron app skeleton

**Tasks:**
1. Initialize Electron project with Vite + Vue
2. Basic window layout with main menu
3. IPC communication setup
4. Template loading from JSON files
5. Reference point manager (bullseye, airbases, zones, lines)

**Deliverable**: App opens, shows template list, reference points configured

---

### Phase 1: Reference Point Configuration (Week 1)

**Goal**: Define and manage reference points

**Tasks:**
1. Bullseye editor (set X/Y coordinates)
2. Airbase manual entry (user enters name - coordinates come from Lua runtime)
3. Trigger zone editor (center + radius)
4. Battle line editor (start/end coordinates)
5. Reference point manager API

**Deliverable**: All reference point types configurable in UI

---

### Phase 2: Group Editor (Week 1-2)

**Goal**: Form to configure a group

**Tasks:**
1. Group configuration form (name, coalition, units)
2. Unit type selector (dropdown with DCS unit types)
3. Airbase selector
4. Parking configuration
5. Position input (select reference type + configure)

**Deliverable**: Complete group configuration form in UI

---

### Phase 3: Coordinate Utilities (Week 2)

**Goal**: Offset-based coordinate system

**Tasks:**
1. Bullseye offset (bearing + distance) to X/Y conversion
2. Airbase offset conversion
3. Zone offset conversion
4. Battle line offset conversion
5. Direct X/Y coordinate entry
6. Distance and heading calculations

**Deliverable**: Coordinate conversion utilities working correctly

---

### Phase 4: Waypoint Editor (Week 2)

**Goal**: Add/edit waypoint sequences

**Tasks:**
1. Waypoint list UI (add/remove/reorder)
2. Waypoint form (type, coordinates, altitude, speed)
3. Waypoint type-specific fields (orbit radius, heading)

**Deliverable**: Working waypoint editor with multiple waypoint types

---

### Phase 5: Template Library (Week 3)

**Goal**: Browse and apply templates

**Tasks:**
1. Template browser UI
2. Template search/filter
3. Apply template to current configuration
4. Save custom templates
5. Reference point configuration UI

**Deliverable**: Template library working with search and application

---

### Phase 6: JSON Export (Week 4)

**Goal**: Generate Lua configuration

**Tasks:**
1. Lua code generator
2. Export configuration to JSON file
3. Export Lua code to file
4. Preview generated Lua

**Deliverable**: JSON and Lua export working correctly

---

### Phase 7: Testing & Validation (Week 4)

**Goal**: Ensure generated config works with existing framework

**Tasks:**
1. Validate generated JSON against schema
2. Test with existing unit_management.lua
3. Fix any compatibility issues
4. Documentation

**Deliverable**: Validated configuration passes all tests

---

## MVP Success Criteria

The MVP is complete when:

1. User can open app and see template library
2. User can configure bullseye reference point (set X/Y coordinates)
3. User can configure trigger zones
4. User can manually enter airbase references (name-based, coordinates come from Lua runtime)
5. User can select a template and see configuration in UI
6. User can edit group settings (name, units, quantity)
7. User can configure position (any reference type: bullseye, airbase, zone, line)
8. User can edit waypoints (add, remove, modify)
9. User can export configuration as JSON
10. User can export configuration as Lua code
11. Generated Lua code runs without errors in DCS
12. Validation layer catches missing reference points before export

---

## Tech Stack (MVP)

| Layer | Technology | Reason |
|-------|------------|--------|
| Framework | Electron | Desktop app without web hosting |
| UI Framework | Vue 3 | Reactive, lightweight, familiar to developers |
| Build Tool | Vite | Fast development, simple config |
| State Management | Pinia | Simple, Vue-native |
| File System | Node.js fs | Read/write files |

---

## Out of Scope - Future Work

These features are explicitly deferred from MVP:

1. **Visual Map Display**
   - Leaflet/OpenLayers integration
   - Static map image overlays
   - Pixel-to-coordinate projections
   - *Reason*: Reference point system is sufficient for MVP; visual feedback can be added later

2. **Battle Line / Pattern Generators**
   - Draw lines on map
   - Auto-generate units along path
   - Flanking patterns, grids, etc.
   - *Reason*: Complex geometry, not core to group configuration

3. **.miz File Integration**
   - Read existing .miz files
   - Inject Lua into existing missions
   - Backup and restore functionality
   - *Reason*: Requires robust zip handling and Lua parsing in JS

4. **Template Creation in App**
   - Build custom templates from scratch
   - Template editor UI
   - *Reason*: Basic templates can be edited in JSON files

5. **Trigger Configuration UI**
   - RADAR, TRIGGER_ZONE, OBJECTIVE_COMPLETE
   - Zone selection
   - *Reason*: Can use default IMMEDIATE for MVP

6. **Multi-Theater Support**
   - Select theater on startup
   - Load appropriate map
   - Coordinate system per theater
   - *Reason*: Start with single theater, expand later

7. **Cloud Sync / Collaboration**
   - Share templates
   - Sync configuration
   - *Reason*: Requires backend service

---

## Configuration Files (MVP)

```
mission-editor/
├── config/
│   ├── templates/
│   │   ├── air_templates.json
│   │   ├── ground_templates.json
│   │   └── support_templates.json
│   ├── refpoints.json        (bullseyes, airbases, zones, lines)
│   └── default_config.json
├── main/
│   ├── index.js
│   ├── refpoints/
│   │   ├── manager.js
│   │   ├── utils.js
│   │   └── helpers.js
│   ├── templates/
│   │   ├── manager.js
│   │   └── loader.js
│   ├── config/
│   │   ├── generator.js
│   │   └── validator.js
│   ├── waypoints/
│   │   └── service.js
│   └── utils/
│       └── coords.js
└── renderer/
    ├── main.js
    ├── components/
    │   ├── editor/
    │   │   ├── GroupEditor.vue
    │   │   └── WaypointEditor.vue
    │   ├── refpoints/
    │   │   ├── BullseyeEditor.vue
    │   │   ├── AirbaseEditor.vue
    │   │   ├── ZoneEditor.vue
    │   │   └── BattleLineEditor.vue
    │   └── templates/
    │       ├── TemplateLibrary.vue
    │       └── TemplateItem.vue
    └── utils/
        └── coords.js
```

---

## Next Steps After MVP

Once MVP is validated:

1. **Add .miz Injection** - Read existing missions, inject dynamic elements
2. **Visual Map Display** - Optional Leaflet overlay for visual verification
3. **Multi-Theater Support** - Add Livonia, Peloponnese, etc.
4. **Advanced Map Features** - Zones, terrain, overlays
5. **Template Creation UI** - Build templates in-app
6. **Trigger Configuration** - Full trigger type support
7. **Performance Optimization** - Large mission handling

---

*Document last updated: 2026-07-02 - Revised to include multiple reference point types (bullseye, airbase, trigger zones, battle lines)*
