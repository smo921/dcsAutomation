# Configuration Files

This directory contains configuration files for the DCS Mission Editor. These files define reference points, templates, and waypoint patterns that can be used when building missions.

## File Structure

```
config/
├── refpoints.json              # Reference points (bullseye, airbases, zones, lines)
├── templates/                  # Reusable mission group templates
│   ├── air_templates.json      # Air unit templates (AWACS, patrols, bombers)
│   ├── ground_templates.json   # Ground unit templates (convoy, SAM, armor)
│   └── support_templates.json  # Support asset templates (tankers, command posts)
└── waypoint_templates.json     # Predefined flight path patterns (optional)
```

## File Descriptions

### refpoints.json

Defines all reference points used for positioning mission elements. Reference points act as anchors for placing groups relative to known locations.

**Structure:**
- `bullseyes` - Global theater reference points (named X/Y coordinate pairs)
- `airbases` - Named airbase locations (resolved at runtime via DCS)
- `zones` - Mission-defined trigger zones
- `lines` - Custom battle lines for linear deployment patterns

**Usage:** The editor loads these to enable relative positioning of groups (e.g., "50nm at 45 degrees from Bullseye").

### templates/ Directory

Contains JSON files with prebuilt group configurations. Templates provide starting points for common mission elements that can be applied with a single click.

#### air_templates.json

Air unit templates with common configurations:
- **AWACS Patrol** - Airborne early warning with tanker support
- **Air Defense Patrol** - Interceptors for air superiority
- **Strike Groups** - Bomber formations with escort
- **Close Air Support** - Ground attack aircraft

**Template Fields:**
- `id` - Unique identifier for the template
- `name` - Display name
- `category` - Must be `"air"`
- `units` - Array of unit definitions (type, quantity, role)
- `defaultRoute` - Default route pattern (orbit, heading, or waypoint)
- `defaultPosition` - Default placement method (bullseye_offset, airbase_offset, etc.)

#### ground_templates.json

Ground unit templates:
- **Convoy** - Truck formations with light defense
- **SAM Battery** - Air defense batteries with radar and launchers
- **Armor** - Tank and mechanized unit combinations

**Template Fields:**
- `id` - Unique identifier
- `name` - Display name
- `category` - Must be `"ground"`
- `units` - Array of unit definitions
- `defaultRoute` - Default ground route (optional)
- `defaultPosition` - Default placement method

#### support_templates.json

Support asset templates:
- **AWACS Support** - Combined AWACS and tanker packages
- **Air Defense HQ** - Command and control elements

### waypoint_templates.json (Optional)

Predefined flight path patterns that can be applied to groups. This file is optional - if missing, the editor uses in-app defaults.

**Structure:**
- Each template has an `id` key and a `waypoints` array
- Waypoints define the flight path with types:
  - `orbit` - Circular loiter pattern
  - `turn_point` - Waypoint with heading
  - `heading` - Direct course

**Usage:** Templates like "awacs_orbit" or "cas_sweep" can be applied to groups to define their route without manually creating each waypoint.

## Template Format Reference

### Basic Template Structure

```json
{
  "id": "template_id",
  "name": "Display Name",
  "category": "air",
  "units": [
    {
      "name": "Unit Name",
      "type": "Aircraft/Unit Type",
      "quantity": 2,
      "role": "primary_role"
    }
  ],
  "defaultRoute": {
    "type": "orbit",
    "radius": 10,
    "altitude": 30000,
    "speed": 300,
    "pattern": "clockwise"
  },
  "defaultPosition": {
    "type": "bullseye_offset",
    "reference": "BULLSEYE_ALPHA",
    "bearing": 0,
    "distance": 100000
  }
}
```

### Placement Types for `defaultPosition`

| Type | Description | Required Fields |
|------|-------------|-----------------|
| `bullseye_offset` | Relative to bullseye | `reference` (bullseye name), `bearing`, `distance` |
| `airbase_offset` | Relative to airbase | `reference` (airbase name), `bearing`, `distance` |
| `battle_line_offset` | Relative to battle line | `reference` (line name), `distance` |
| `zone_offset` | Relative to trigger zone | `reference` (zone name), `bearing`, `distance` |

### Route Types for `defaultRoute`

| Type | Description | Required Fields |
|------|-------------|-----------------|
| `orbit` | Circular loiter | `radius`, `altitude`, `speed`, `pattern` (`clockwise`/`counter-clockwise`) |
| `heading` | Straight course | `altitude`, `speed` |
| `waypoint` | Simple waypoints | `altitude`, `speed` |

## Editing Templates

1. Edit JSON files in a text editor
2. Reload the editor or restart the application
3. Templates appear in the Templates panel in the sidebar

## Using Templates in the Editor

1. Click "Load Config" in the sidebar to load templates from `config/templates/`
2. Select a template from the list
3. Click "Apply" to create a new group based on that template
4. The group will appear in the Groups panel with preconfigured units and route
