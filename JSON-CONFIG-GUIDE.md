# JSON Configuration Guide for DCS Mission Editor

This document explains how to create mission configurations using the JSON file format for the DCS mission scripting framework.

## Overview

The JSON configuration file defines:
- **Reference points** - Bullseyes, airbases, trigger zones, and battle lines
- **Route templates** - Reusable route patterns for units
- **Unit templates** - Reusable unit definitions (groups of units)
- **Units** - The actual mission units that will be spawned

## File Structure

```json
{
  "refpoints": {
    "bullseyes": [...],
    "airbases": [...],
    "zones": [...],
    "lines": [...]
  },
  "route_templates": {
    "template_name": {
      "name": "Display Name",
      "route": [...]
    }
  },
  "unit_templates": {
    "ground": [...],
    "air": [...],
    "naval": [...],
    "support": [...]
  },
  "units": [...]
}
```

## Naming Conventions

The JSON configuration uses **snake_case** for top-level keys to match the Lua naming convention:
- `refpoints` - Reference points (bullseyes, airbases, zones, lines)
- `route_templates` - Reusable route patterns
- `unit_templates` - Reusable unit definitions
- `units` - Active mission units

When referencing templates within units:
- `routeTemplate` - String reference to a route template
- `unitTemplate` - String reference to a unit template

## Reference Points

### Bullseyes
Global reference coordinates for the theater. Used for positioning units relative to coalition fronts.

```json
{
  "bullseyes": [
    {"name": "blue", "description": "Blue Coalition Bullseye"},
    {"name": "red", "description": "Red Coalition Bullseye"}
  ]
}
```

**Required fields:**
- `name` - Must be one of: "blue", "neutral", "red"

### Zones
Trigger zones defined in the DCS Mission Editor. Units can spawn when entering these zones.

```json
{
  "zones": [
    {
      "name": "Frontline_Zone",
      "description": "Primary combat area"
    }
  ]
}
```

**Required fields:**
- `name` - Exact name as defined in DCS Mission Editor

**Optional fields:**
- `description` - Human-readable description

**Note:** Zones do not have `x`, `y`, or `radius` fields in the configuration. These are defined directly in the DCS Mission Editor when you create trigger zones. The `name` field is the only reference needed - it must match the exact name of the trigger zone as it appears in DCS.

### Airbases
Named airbases in the theater. Used for positioning relative to specific locations.

```json
{
  "airbases": [
    {"name": "Kaliningrad", "description": "Kretchmer Air Base"}
  ]
}
```

**Required fields:**
- `name` - Exact name as defined in DCS Mission Editor

### Lines
Custom battle lines for linear deployment patterns.

```json
{
  "lines": [
    {
      "name": "Blue Front",
      "startX": 100000,
      "startY": 600000,
      "endX": 200000,
      "endY": 700000
    }
  ]
}
```

## Route Templates

Predefined route patterns that can be referenced by units. Routes consist of waypoints.

### Route Template Structure

```json
{
  "route_templates": {
    "awacs_orbit": {
      "name": "AWACS Orbit Pattern",
      "route": [
        {
          "type": "orbit",
          "altitude": 25000,
          "speed": 350,
          "radius": 5,
          "pattern": "clockwise",
          "alt_type": "BARO"
        }
      ]
    },
    "ground_patrol": {
      "name": "Ground Patrol Route",
      "route": [
        {"type": "On Road", "speed": 35},
        {"type": "Off Road", "speed": 25}
      ]
    }
  }
}
```

### Route Waypoint Fields

Each waypoint in a route can have the following fields:

| Field | Required | Description | Units |
|-------|----------|-------------|-------|
| `type` | Yes | Waypoint type (see table below) | String |
| `altitude` | No | Flight level for air units | Feet |
| `speed` | No | Ground/air speed | Knots |
| `radius` | No | Orbit radius | Nautical Miles |
| `pattern` | No | Orbit direction | "clockwise" or "counter-clockwise" |
| `alt_type` | No | Altitude type | "BARO" or "RAD" |
| `offsetX` | No | X coordinate offset | Nautical Miles |
| `offsetY` | No | Y coordinate offset | Nautical Miles |
| `roe` | No | Rules of engagement | "OPEN_FIRE", "HOLD_FIRE", etc. |

### Waypoint Types

#### Air Unit Types
| Type | Description |
|------|-------------|
| `orbit` | Circular loiter pattern around a point |
| `turn_point` | A point in the flight path |
| `heading` | Direct course to next point |
| `landing` | Landing at an airbase |

#### Ground Unit Types
| Type | Description |
|------|-------------|
| `On Road` | Movement along roads |
| `Off Road` | Off-road movement |

## Unit Templates

Predefined unit configurations that can be referenced by units.

### Structure

```json
{
  "unit_templates": {
    "ground": [
      {
        "id": "recon_squad",
        "name": "Reconnaissance Squad",
        "units": [
          {"name": "Lead Vehicle", "type": "BMP-2", "quantity": 3},
          {"name": "Support Vehicle", "type": "BRDM-2", "quantity": 2}
        ],
        "routeTemplate": "ground_patrol"
      }
    ],
    "air": [
      {
        "id": "interceptor_squadron",
        "name": "Interceptor Squadron",
        "units": [
          {"name": "Lead Flight", "type": "MiG-29", "quantity": 4},
          {"name": "Wingman", "type": "MiG-29", "quantity": 4}
        ],
        "routeTemplate": "air_patrol"
      }
    ]
  }
}
```

### Unit Template Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier for template |
| `name` | Yes | Display name |
| `units` | Yes | Array of unit objects in the group |
| `routeTemplate` | No | Reference to route template |

### Unit Objects (inside units array)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unit name in the group |
| `type` | Yes | DCS unit type (e.g., "MiG-29", "BMP-2") |
| `quantity` | Yes | Number of units in this slot |
| `groundSpot` | No | Specific parking spot at airbase |

## Units (Active Mission Elements)

These are the actual units that will be spawned in the mission.

### Unit Structure

```json
{
  "units": [
    {
      "unitName": "Red Patrol Alpha",
      "category": "GROUND",
      "triggerType": "IMMEDIATE",
      "country": "Russia",
      "placement": {...},
      "units": [...],
      "routeTemplate": "ground_patrol"
    }
  ]
}
```

### Unit Fields

| Field | Required | Description |
|-------|----------|-------------|
| `unitName` | Yes | Unique name for this unit instance |
| `category` | Yes | "GROUND", "AIRPLANE", "HELICOPTER", "SHIP", "SUBMARINE" |
| `triggerType` | Yes | How/when the unit spawns (see below) |
| `country` | Yes | Country/coalition | "Russia", "USA", "UK", etc. |
| `unitTemplate` | No | Reference to unit template - merged with inline `units` array |
| `units` | No | Array of unit objects - merged with template `units` array |
| `routeTemplate` | No | Reference to route template - merged with inline `route` array |
| `route` | No | Array of route waypoints - merged with template `route` array |
| `parentUnitName` | No | For OBJECTIVE_COMPLETE triggers |

**Merge Behavior:** When using templates, the system merges template and inline definitions with a priority order:
1. **Inline values** (unit, route, placement) come **first** (highest priority)
2. **Template values** are **appended** or used as defaults for missing fields
3. **Unit properties** (category, triggerType, country, etc.) from template are overridden by inline values

**Example:**
```json
{
  "unitTemplate": "interceptor_squadron",  // Gets units from template
  "units": [                                // Inline units come first
    {"name": "Custom Lead", "type": "F-22", "quantity": 2}
  ]
}
```
Result: The `units` array will have the custom lead first, then the template's units appended after.

### Trigger Types

| Type | Description |
|------|-------------|
| `IMMEDIATE` | Spawns immediately at mission start |
| `TRIGGER_ZONE` | Spawns when player enters a trigger zone |
| `RADAR` | Spawns when enemy radar detects threats |
| `OBJECTIVE_COMPLETE` | Spawns when parent unit is destroyed |

### Placement Modes

Placement defines how and where the unit is positioned.

#### Mode 1: ZONE_CENTER
Spawns at the center of a trigger zone.

```json
{
  "placement": {
    "mode": "ZONE_CENTER",
    "referenceName": "Ridge_Line_Alpha",
    "heading": 180,
    "spawnRadius": 0.5
  }
}
```

**Fields:**
- `mode`: "ZONE_CENTER"
- `referenceName`: Name of trigger zone
- `heading`: Initial heading (degrees)
- `spawnRadius`: Radius factor (0.0 to 1.0)

#### Mode 2: BEARING_DISTANCE
Spawns at a bearing and distance from a reference point.

```json
{
  "placement": {
    "mode": "BEARING_DISTANCE",
    "reference": "bullseye",
    "referenceName": "blue",
    "bearing": 0,
    "distance": 5.0,
    "heading": 180
  }
}
```

**Fields:**
- `mode`: "BEARING_DISTANCE"
- `reference`: "bullseye", "airbase", "zone", or "line"
- `referenceName`: Name of reference point
- `bearing`: Bearing in degrees (0-360)
- `distance`: Distance in Nautical Miles
- `heading`: Initial heading (degrees)

#### Mode 3: ZONE_RANDOM
Spawns at a random location within a zone.

```json
{
  "placement": {
    "mode": "ZONE_RANDOM",
    "zoneName": "Frontline_Zone",
    "heading": 180,
    "spawnRadius": 0.5
  }
}
```

#### Mode 4: COORDINATE
Spawns at specific coordinates (offset from reference).

```json
{
  "placement": {
    "mode": "COORDINATE",
    "offsetX": 0,
    "offsetY": 10,
    "heading": 0
  }
}
```

**Fields:**
- `mode`: "COORDINATE"
- `offsetX`: X offset in Nautical Miles
- `offsetY`: Y offset in Nautical Miles
- `heading`: Initial heading (degrees)

### Route Reference

Routes can be defined in two ways:

#### Option 1: Inline Route
```json
{
  "route": [
    {"type": "On Road", "speed": 35},
    {"type": "Off Road", "speed": 25}
  ]
}
```

#### Option 2: Route Template Reference
```json
{
  "routeTemplate": "ground_patrol"
}
```

**Important:** When using `routeTemplate`, the route is expanded from the template. The template's waypoints are **appended** to any inline waypoints in the `route` array. This means you can define some waypoints inline and still use a template for additional waypoints.

### Merge Behavior Summary

The system uses a **merge with priority** approach when combining templates with inline definitions:

| Field Type | Behavior |
|------------|----------|
| **Objects** (placement) | Inline overrides template for existing fields; template provides defaults for missing fields |
| **Arrays** (units, route) | Inline values come **first**, template values are **appended** |
| **Primitives** (category, country, etc.) | Inline value always takes precedence |

**Example:**
```json
{
  "unitTemplate": "interceptor_squadron",  // Template has 4 units
  "units": [                                // Inline adds 2 more units
    {"name": "Custom Lead", "type": "F-22", "quantity": 2}
  ]
}
```
Result: Total of 6 units - 1 inline + 4 from template.

### Route Waypoint Behavior

For **air units**:
- First waypoint is relative to unit's spawn position
- Subsequent waypoints are relative to previous waypoint
- `offsetX`/`offsetY` are ignored for orbit patterns
- `radius` defines orbit radius in Nautical Miles

For **ground units**:
- First waypoint is relative to unit's spawn position
- Subsequent waypoints are relative to previous waypoint
- `offsetX`/`offsetY` define offset from road or off-road path
- `speed` is required for movement

## Complete Example

```json
{
  "refpoints": {
    "bullseyes": [
      {"name": "blue"},
      {"name": "red"}
    ],
    "zones": [
      {"name": "Frontline_Zone"}
    ]
  },
  "route_templates": {
    "air_patrol": {
      "name": "Air Patrol Pattern",
      "route": [
        {"type": "orbit", "altitude": 25000, "speed": 350, "radius": 5, "pattern": "clockwise", "alt_type": "BARO"}
      ]
    },
    "ground_patrol": {
      "name": "Ground Patrol",
      "route": [
        {"type": "On Road", "speed": 35, "offsetX": 0.2, "offsetY": 0.1}
      ]
    },
    "scout_infiltration": {
      "name": "Scout Off-Road Movement",
      "route": [
        {"type": "Off Road", "speed": 25, "offsetX": 1.0, "offsetY": 1.0}
      ]
    }
  },
  "unit_templates": {
    "ground": [
      {
        "id": "recon_squad",
        "name": "Reconnaissance Squad",
        "units": [
          {"name": "Scout Lead", "type": "BMP-2", "quantity": 3},
          {"name": "Recon Support", "type": "BRDM-2", "quantity": 2}
        ]
      }
    ],
    "air": [
      {
        "id": "interceptor_squadron",
        "name": "Interceptor Squadron",
        "units": [
          {"name": "Flight Lead", "type": "MiG-29", "quantity": 4},
          {"name": "Wingman", "type": "MiG-29", "quantity": 4}
        ],
        "routeTemplate": "air_patrol"
      }
    ]
  },
  "units": [
    {
      "unitName": "Blue Air Patrol",
      "category": "AIRPLANE",
      "triggerType": "IMMEDIATE",
      "country": "USA",
      "units": [
        {"name": "Flight Lead", "type": "F-15C", "quantity": 4}
      ],
      "placement": {
        "mode": "BEARING_DISTANCE",
        "reference": "bullseye",
        "referenceName": "blue",
        "bearing": 45,
        "distance": 2.0,
        "heading": 180
      },
      "routeTemplate": "air_patrol"
    },
    {
      "unitName": "Red Ground Patrol",
      "category": "GROUND",
      "triggerType": "TRIGGER_ZONE",
      "country": "Russia",
      "units": [
        {"name": "Lead Vehicle", "type": "BMP-2", "quantity": 3}
      ],
      "placement": {
        "mode": "ZONE_CENTER",
        "referenceName": "Frontline_Zone",
        "heading": 180
      },
      "routeTemplate": "ground_patrol"
    },
    {
      "unitName": "Recon Unit A",
      "category": "GROUND",
      "triggerType": "IMMEDIATE",
      "country": "USA",
      "unitTemplate": "recon_squad",
      "placement": {
        "mode": "BEARING_DISTANCE",
        "reference": "bullseye",
        "referenceName": "blue",
        "bearing": 90,
        "distance": 5.0,
        "heading": 180
      },
      "routeTemplate": "scout_infiltration"
    },
    {
      "unitName": "Custom Ground Unit",
      "category": "GROUND",
      "triggerType": "IMMEDIATE",
      "country": "Russia",
      "units": [
        {"name": "Tank Lead", "type": "T-90M", "quantity": 6},
        {"name": "Mech Support", "type": "BMP-3", "quantity": 4}
      ],
      "placement": {
        "mode": "BEARING_DISTANCE",
        "reference": "bullseye",
        "referenceName": "red",
        "bearing": 180,
        "distance": 3.0,
        "heading": 270
      },
      "route": [
        {"type": "On Road", "speed": 35, "offsetX": 0.2, "offsetY": 0.1},
        {"type": "Off Road", "speed": 25, "offsetX": 1.0, "offsetY": 1.0}
      ]
    }
  ]
}
```

### Examples Explained

| Unit | Description |
|------|-------------|
| `Blue Air Patrol` | Uses **routeTemplate** for route; defines **units** array inline |
| `Red Ground Patrol` | Uses **routeTemplate** for route; defines **units** array inline |
| `Recon Unit A` | Uses **unitTemplate** for units; uses **routeTemplate** for route |
| `Custom Ground Unit` | Defines **units** array inline; defines **route** array inline |

## Unit Conversion Notes

The framework automatically handles unit conversion:
- **Altitude**: Feet → Meters
- **Distance**: Nautical Miles → Meters
- **Speed**: Knots → Meters/second

You specify values in the more intuitive units (feet, NM, knots); the system converts to DCS internal units (meters, m/s).

## Validation

Generated Lua configurations are validated against templates in `unit_management.lua`:

- `UNIT_TEMPLATE` - Validates unit structure
- `ROUTE_WAYPOINT_TEMPLATE` - Validates route waypoints
- `AIR_UNIT_TEMPLATE` - Validates units within a group

Missing required fields will cause validation errors when the mission loads.
