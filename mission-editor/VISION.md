# DCS Dynamic Mission Editor - Vision Document

> **Status**: Draft - 2026-07-02
> **Purpose**: Define requirements and architecture for a visual mission editor
> **Updated**: 2026-07-02 - Revised to bullseye-centric coordinate system

---

## Executive Summary

Build an Electron-based desktop application that allows mission builders (with mixed technical experience) to create and configure dynamic DCS mission elements through a visual interface, without needing to write Lua code.

**Key Change**: The system uses a unified reference point system rather than map overlays. Users configure units relative to:
- **Bullseye** - Global reference point (X/Y)
- **Airbases** - Name-based reference; coordinates resolved via `Airbase.getByName()` in `unit_management.lua` at runtime
- **Trigger Zones** - Mission-defined zones
- **Battle Lines** - Custom line segments

**Design Note**: Airbase coordinates are NOT fetched from `.miz` files in the MVP. Users enter airbase names they see in the DCS Mission Editor. The existing Lua framework (`unit_management.lua:924`) uses `Airbase.getByName()` to resolve coordinates at runtime. This avoids complex `.miz` parsing in Phase 1 while maintaining functionality.

---

## Current Challenges

1. **Repetitive Setup**: Manual configuration in DCS Mission Editor is time-consuming
2. **Error-Prone**: Manual coordinate entry and group setup leads to mistakes
3. **Lua Required**: Dynamic elements require coding knowledge
4. **No Reference System**: Hard to visualize relative positioning from offsets

---

## Target Solution

An Electron desktop app with:
- **Reference Point Configuration** - Define bullseye, airbases, zones, battle lines
- **Offset-Based Positioning** - All units positioned relative to reference points
- **Prebuilt component templates**
- **JSON/Lua export** for integration with existing mission framework

---

## Core Features

### 1. Prebuilt Component Library

**Template Dropdown System:**
```
┌────────────────────────────────────────────┐
│ Select Component Template...  [▼]         │
├────────────────────────────────────────────┤
│ AWACS Patrol (Su-30 + Tanker)             │
│ Air Defense Patrol (MiG-29 x3)            │
│ Ground Convoy (Trucks + SAMs)             │
│ Amphibious Assault (Helicopters +Boats)   │
│ Strategic Bomber Strike (Tu-95 + escorts) │
│ Custom Template...                        │
└────────────────────────────────────────────┘
```

**Template Capabilities:**
- Predefined unit combinations (mixed units in groups)
- Configurable quantities (min/max random counts)
  - Example: "3-5 MiG-29s" → spawns random count each time
- Default configuration profiles
- Reference point configurations (bullseye offset, airbase offset, zone offset)

**Template Sources:**
1. Built-in templates (distributed with app)
2. User's existing `mission_test.lua` - scan for component definitions
3. Custom templates (save/export as JSON)
4. Pattern generators (battle lines, grids, rings, etc.)

---

### 2. Reference Point Configuration

**Reference Point Types:**

#### Bullseye Configuration
```
┌────────────────────────────────────────────────────┐
│ Bullseye Reference                                 │
├────────────────────────────────────────────────────┤
│ Name: [BULLSEYE_ALPHA]                             │
│ X Coordinate: [123456]  Y Coordinate: [654321]     │
│ [Set as Active]                                    │
└────────────────────────────────────────────────────┘
```

#### Airbase Configuration
```
┌────────────────────────────────────────────────────┐
│ Airbase Reference                                  │
├────────────────────────────────────────────────────┤
│ Name: [Kaliningrad]                                │
│ X: [120000]  Y: [700000]  Runway Heading: [180]  │
│                                                    │
│ Note: Airbase name is used with Airbase.getByName│
│ at runtime (via unit_management.lua). Coordinates  │
│ entered for offline reference point configuration. │
│ [+ Add Airbase]                                    │
└────────────────────────────────────────────────────┘
```

#### Trigger Zone Configuration
```
┌────────────────────────────────────────────────────┐
│ Trigger Zone Reference                             │
├────────────────────────────────────────────────────┤
│ Zone Name: [Frontline_Zone]                        │
│ Center X: [150000]  Center Y: [650000]            │
│ Radius: [5000] meters                              │
│ [Set as Active]                                    │
└────────────────────────────────────────────────────┘
```

#### Battle Line Configuration
```
┌────────────────────────────────────────────────────┐
│ Battle Line Reference                              │
├────────────────────────────────────────────────────┤
│ Line Name: [BLUE Front]                            │
│ Start X: [100000]  Start Y: [600000]              │
│ End X: [200000]  End Y: [700000]                  │
│ Side: [Blue ▼] / [Red]                             │
│ [Set as Active]                                    │
└────────────────────────────────────────────────────┘
```

**Visual Reference Manager:**
- List all configured reference points
- Set active reference for group positioning
- Edit/delete existing references
- Import references from saved configuration

---

### 3. Waypoint Editor with Visual Preview

**Waypoint Configuration:**
```
┌────────────────────────────────────────────────────────────┐
│ Waypoint 1: Takeoff                                        │
│   Type: [Takeoff ▼]                                        │
│   Altitude: 0m  Speed: 0 km/h                             │
│                                                            │
│ Waypoint 2: Transit to Objective                           │
│   Type: [Heading ▼]  [Enter heading: 240°]                │
│   Altitude: 3000m  Speed: 600 km/h  Distance: 100km      │
│                                                            │
│ Waypoint 3: Orbit Pattern                                  │
│   Type: [Orbit ▼]  [Clockwise ▼]  Radius: 10km           │
│   Altitude: 4500m  Speed: 700 km/h  Pattern: [Figure-8]  │
│                                                            │
│ [+ Add Waypoint]  [Preview Route on Map]                  │
└────────────────────────────────────────────────────────────┘
```

**Visual Map Preview:**
- Static map of current theater (Takistan, Livonia, etc.)
- Overlay drawn route showing:
  - All waypoints connected by lines
  - Direction arrows
  - Turn points highlighted
  - Route segments with distance labels
- Mouse hover shows coordinate details
- Click waypoint to edit

**Coordinate Systems:**
- Ground coordinates (X, Y)
- Bearing + Distance from reference point
- Direct X/Y coordinate entry
- Visual feedback showing what the route actually looks like

---

### 4. Group Configuration

**Basic Group Settings:**
```
Group: [AWACS Patrol Alpha]
├─ Unit Type: [Su-30SM ▼]
├─ Quantity: [3] (or random: 3-5)
├─ Coalition: [Blue ▼] / [Red]
├─ Country: [Russia ▼]
├─ Reference Point Type: [Airbase Offset ▼]
│  └─ Reference: [Kaliningrad ▼]
│  └─ Bearing: [45°]  Distance: [10000m]
├─ Airbase: [Kaliningrad ▼]
├─ Parking: [Hot start ▼] / [Cold start] / [Ramp slot #5]
└─ Configuration Profile: [AWACS pattern ▼]
```

**Dynamic Configuration:**
- Trigger type selection (IMMEDIATE, RADAR, TRIGGER_ZONE, OBJECTIVE_COMPLETE)
- Radar detection settings
- Zone trigger boundaries
- Objective dependencies
- Respawn configuration

---

### 5. Pattern-Based Spawning (Battle Lines, etc.)

**Use Case: CAS-Style Missions with Random Unit Generation**

**Scenario:** Build mock battle lines and spawn random units along that line for CAS (Close Air Support) style missions.

**Feature: Battle Line Generator**

```
┌────────────────────────────────────────────────────────────┐
│ Battle Line Generator                                      │
├────────────────────────────────────────────────────────────┤
│ Draw line on map: [Click to draw]                          │
│  └──> Line segment 1: (12345, 67890) to (12800, 67500)    │
│  └──> Line segment 2: (12800, 67500) to (13200, 67100)    │
│                                                            │
│ Configuration:                                             │
│  Line Length: 45 km                                        │
│  Total Units: 12 (max 15)                                 │
│  Spawn Interval: 500m between units                       │
│                                                            │
│ Unit Configuration:                                        │
│  [✓] Frontline AA (S-300 x2)    [Min: 2] [Max: 4]        │
│  [✓] Armor Column (T-72 x3)     [Min: 3] [Max: 6]        │
│  [✓] Infantry Support (BTR x2)  [Min: 2] [Max: 4]        │
│  [✓] Mobile AA (ZSU-23 x2)      [Min: 1] [Max: 3]        │
│                                                            │
│ Distribution:                                              │
│  [✓] Randomize positions (±200m jitter)                   │
│  [✓] Alternate sides of road (flanking pattern)           │
│  [✓] Group by type (clusters of 2-3 units)                │
│                                                            │
│ [Preview on Map]  [Add to Mission]                        │
└────────────────────────────────────────────────────────────┘
```

**Generated Lua Output:**
```lua
-- Battle Line: Frontline Defense (CAS Threat)
createSector({
    name = "CAS_BattleLine_East",
    triggerType = "IMMEDIATE",
    groups = {
        -- Frontline AA
        createGroup("AA_Frontline_1", "land", "S-300", 2, 
            {x=12345, y=67890}, 180, "Hot start"),
        createGroup("AA_Frontline_2", "land", "S-300", 2, 
            {x=12400, y=67950}, 180, "Hot start"),
        
        -- Armor Column
        createGroup("Armor_1", "land", "T-72", 4, 
            {x=12500, y=68000}, 180, "Hot start"),
        createGroup("Armor_2", "land", "T-72", 3, 
            {x=12550, y=67900}, 180, "Hot start"),
        
        -- Mobile AA
        createGroup("MobileAA_1", "land", "ZSU-23", 2, 
            {x=12600, y=67850}, 180, "Hot start"),
    }
})
```

**Pattern Types:**

1. **Battle Line** - Units spread along a line (CAS threat simulation)
2. **Battle Grid** - Units in a grid pattern (defensive position)
3. **Concentric Rings** - Units in rings around a point (base defense)
4. **Echelon Right** - Units staggered in formation (attack formation)
5. **Echelon Left** - Units staggered opposite (attack formation)
6. **V-Formation** - Units in V shape (air assault)
7. **L-Formation** - Units in L shape (flanking position)

**Configuration Options:**
- Randomize positions with jitter (±N meters)
- Alternate sides of line/point (flanking)
- Group by type (clusters of N units)
- Random direction/heading per unit
- Mixed unit types per group
- Dynamic quantity (min/max random)

**Visual Preview:**
- Draw battle line on map
- Show unit positions as markers
- Color-code by unit type
- Show coverage zones (radar/engagement)
- 3D elevation preview (if terrain data available)

**Use Cases:**
- CAS threat simulation (enemy armor/AAA along front)
- Battle line reinforcement (what happens when line breaks)
- Ambush patterns (units hidden along road)
- Defensive positions (anti-aircraft coverage)
- Convoy routes (escort + threat patterns)

---

### 6. Trigger Configuration

**Trigger Types:**

1. **Immediate Spawn**
   - Spawns at mission start
   - Optional delay

2. **Radar Detection**
   - Trigger when enemy detected by radar
   - Configure radar parameters
   - Threat filtering settings

3. **Zone Entry**
   - Trigger when unit enters geographical zone
   - Draw zone on map
   - Configure entry conditions

4. **Objective Complete**
   - Trigger when parent group destroyed
   - Chain reaction setup

---

### 7. .miz File Integration

**Workflow:**
```
1. User opens .miz file in app
2. App extracts and parses existing mission
3. User adds/edits dynamic elements via UI
4. App generates Lua configuration
5. User clicks "Save to .miz"
6. App:
   - Creates backup of original .miz
   - Extracts files from zip
   - Injects/updates Lua configuration
   - Repackages .miz file
   - Shows diff of changes
```

**.miz File Structure:**
```
mission.miz (zip archive)
├── mission              (main Lua script)
├── scripts/
│   ├── mission_test.lua (dynamic loader)
│   └── other scripts...
└── [other assets...]
```

**Injection Strategy:**
- Append new dynamic configs to `mission_test.lua`
- Maintain existing static units unchanged
- Use clear markers for injected sections
- Support multiple injection sessions (idempotent updates)

---

## Technical Architecture

### Electron App Structure

```
dcs-mission-editor/
├── main/
│   ├── index.js              (Electron entry point)
│   ├── refpoints/
│   │   ├── manager.js        (bullseye, airbases, zones, lines)
│   │   └── helpers.js        (Lua reference generation)
│   ├── templates/
│   │   ├── loader.js         (template management)
│   │   └── defaults.js       (built-in templates)
│   ├── config/
│   │   ├── generator.js      (Lua code generation)
│   │   └── validator.js      (schema validation)
│   └── waypoints/
│       └── service.js        (waypoint validation)
├── renderer/
│   ├── main-window.html
│   ├── components/
│   │   ├── refpoints/
│   │   │   ├── BullseyeEditor.vue
│   │   │   ├── AirbaseEditor.vue
│   │   │   ├── ZoneEditor.vue
│   │   │   └── BattleLineEditor.vue
│   │   ├── editor/
│   │   │   ├── GroupEditor.vue
│   │   │   ├── WaypointEditor.vue
│   │   │   └── TriggerEditor.vue
│   │   └── templates/
│   │       ├── TemplateLibrary.vue
│   │       └── TemplatePreview.vue
│   └── utils/
│       ├── coords.js         (coordinate conversions)
│       └── validators.js
└── config/
    ├── templates.json        (built-in templates)
    └── defaults.json
```

### Data Models

**Waypoint Schema:**
```json
{
  "type": "heading" | "orbit" | "circle" | "takeoff" | "land" | "wp",
  "x": 0,
  "y": 0,
  "altitude": 3000,
  "speed": 600,
  "heading": 240,
  "distance": 100,
  "turn_angle": 0,
  "hold_time": 0
}
```

**Group Schema:**
```json
{
  "groupName": "AWACS Patrol Alpha",
  "unitType": "Su-30SM",
  "quantity": 3,
  "minQuantity": 1,
  "maxQuantity": 5,
  "coalition": "blue",
  "country": "Russia",
  "airbase": "Kaliningrad",
  "parking": "hot_start",
  "parkingSlot": null,
  "position": {
    "type": "bullseye_offset|airbase_offset|zone_offset|battle_line_offset|direct_xy",
    "reference": "BULLSEYE_ALPHA",
    "bearing": 45,
    "distance": 50000
  },
  "route": [/* array of waypoints */],
  "trigger": {
    "type": "IMMEDIATE" | "RADAR" | "TRIGGER_ZONE" | "OBJECTIVE_COMPLETE",
    "zone": null,
    "radarRange": 100,
    "triggerGroup": null
  },
  "configuration": {
    "awacs": true,
    "tanker": false,
    "pattern": "orbit",
    "orbitRadius": 10
  }
}
```

**Reference Point Schema:**
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
- **Airbases**: The `name` field is required. At runtime, coordinates are resolved via `Airbase.getByName()` in `unit_management.lua`. The `x` and `y` fields can be used for offline reference but are not required for MVP.
- **Battle Lines**: The `side` field (`blue` or `red`) is optional but recommended for coalition-specific positioning.

---

## Implementation Phases

### Phase 1: Core Editor
- [ ] Electron app skeleton
- [ ] Basic form UI for group creation
- [ ] Waypoint editor (add/edit)
- [ ] JSON configuration export

### Phase 2: Reference Points
- [ ] Bullseye configuration
- [ ] Airbase loader from .miz
- [ ] Trigger zone editor
- [ ] Battle line editor

### Phase 3: Visualization
- [ ] Static map display (canvas or Leaflet)
- [ ] Route path overlay
- [ ] Waypoint markers
- [ ] Coordinate conversion utilities

### Phase 4: Templates
- [ ] Template library component
- [ ] Template loading from `mission_test.lua`
- [ ] Template saving/exporting
- [ ] Random quantity configuration
- [ ] Pattern generators (battle line, grid, rings, etc.)
- [ ] Visual preview of generated patterns

### Phase 5: .miz Integration
- [ ] .miz file opening (zip extraction)
- [ ] Lua parsing and extraction
- [ ] Configuration injection
- [ ] File repackaging
- [ ] Backup functionality

### Phase 6: Advanced Features
- [ ] Trigger configuration UI
- [ ] Zone drawing tool
- [ ] Multiple group management
- [ ] Mission validation

---

## Future Considerations

- Cloud sync (optional, for collaboration)
- Template marketplace
- Scripted validation (run tests on generated config)
- Integration with existing testing framework
- Export to multiple formats (JSON, YAML, Lua table)
- Version control integration

---

## Success Metrics

1. **Usability**: Non-coders can create functional dynamic elements
2. **Accuracy**: Visual preview matches actual in-game behavior
3. **Speed**: Faster than manual Lua editing
4. **Reliability**: Generated config passes existing tests
5. **Compatibility**: Works with existing mission structure

---

## Open Questions

1. **Which map library to use?** (Leaflet, Mapbox, custom canvas)
2. **How to parse existing .miz files?** (Lua parser in JS)
3. **Should templates be editable in-app or export/modify/reimport?**
4. **Multi-theater support?** (Different coordinate systems per theater)
5. **How to handle DCS API changes?** (Version detection?)

---

*Document last updated: 2026-07-02 - Revised to bullseye-centric coordinate system with multiple reference point types*
