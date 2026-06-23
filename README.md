# DCS Dynamic Theater Orchestration Framework

A data-driven Lua framework for Digital Combat Simulator (DCS) designed to automate theater generation, unit routing, radar detection logic, and conditional mission staging.

## Script Loading Order

To initialize the framework correctly within your Mission Editor (ME), you must configure **MISSION START** or **ONCE** triggers with the **DO SCRIPT FILE** action following this strict sequence:

1. **`mist.lua`** (Mission Scripting Tools library prerequisite)
2. **`asset_factories.lua`** (Handles low-level unit payload compilation and formatting)
3. **`unit_management.lua`** (The core solver engine, map marker registry, radar loops, and sector classes)
4. **`mission_test.lua`** (Your centralized configuration manifest and launch engine loop)

---

## Basic Deployment Example

Below is a minimal profile config deploying a single ground asset instantly at mission start, placed 5 nautical miles North of the blue theater Bullseye:

```lua
local SectorManifest = {
    ["red"] = {
        {
            enabled = true,
            triggerType = "IMMEDIATE",
            groupName = "Alpha_Scout_Element",
            country = "Russia",
            units = {"T-72B"},
            placement = {
                heading = 360,
                offsetX = 0.0,
                offsetY = 5.0,     -- 5 NM North of Bullseye
                spawnRadius = 0.2  -- Allowed scatter radius
            }
        }
    }
}
```

## Placement Options & Strategies

The framework converts distances from Nautical Miles (NM) to meters automatically during generation. Positions are computed via the `placement` block using the following fields:

* **`heading`**: The orientation of units upon spawning (in degrees).
* **`spawnRadius`**: The randomization radius (in NM) allowed around the target area for surface obstruction clearance loops.
* **`offsetX` / `offsetY**`: Coordinate offset values (in NM) from the theater center point (Bullseye).
* **`groupName` / `waypoint**`: Positions assets directly at the specified waypoint number of an existing flight plan instead of Bullseye.
* **`strategy`**: Set to `"ZONE_RANDOM"` to utilize a Mission Editor zone layout.
* **`zoneName`**: Combined with `"ZONE_RANDOM"`, it selects a random coordinate point inside the designated ME trigger zone. If a water body or obstruction is hit, the framework safely falls back to the zone's center.

---

## Trigger Types & Spawning Rules

### 1. `IMMEDIATE`

Spawns configured units immediately during the initial theater initialization sweep without registering background evaluation jobs.

### 2. `RADAR`

Deploys early-warning systems that screen the airspace for incoming threats:

* **Spawning Architecture**: Spawns an Early Warning Radar unit at the targeted coordinates and automatically forces its internal state to `ALARM_STATE = RED` for active tracking.
* **Air Defense Ring (`pointDefense`)**: Optionally specify a `pointDefense` sub-table containing `units`, `minRadius`, and `maxRadius`. The engine generates a radial scatter defense perimeter around the main radar station.
* **Intercept Gate Processing**: The background tracker polls the sensor array at specified `checkInterval` increments up to its `maxDetectRangeNM` parameter. When non-filtered coalition threats enter the zone, the radar triggers the execution of its associated `triggeredUnits` profile.

### 3. `TRIGGER_ZONE`

Binds deployment execution directly to Mission Editor geographical spaces:

* Scans the designated ME `zoneName` at regular intervals.
* When a human-controlled or blue coalition airframe/hull penetrates the defined zone threshold, the engine executes a deployment action for that sector.

### 4. `OBJECTIVE_COMPLETE` - work in progress

Enables staged, progressive mission profiles and chain reactions:

* Accepts a `parentGroupName` string parameter pointing to an active mission asset.
* The ticker registry monitors the parent asset's status. As soon as all units in the parent group are confirmed neutralized or destroyed (life pool points drop to 0), the downstream secondary objective sector spawns instantly (e.g., Quick Reaction Forces).



## Example Configuration(s)

### Zone placement with drone overwatch

```lua
-- ==============================================================================
-- COMPLEX SECTOR DEPLOYMENT EXAMPLE
-- ==============================================================================
-- This scenario demonstrates an armored vanguard squad randomized inside a 
-- Mission Editor zone that immediately maneuvers along a multi-point road path.
-- Once deployed, a dedicated overwatch drone tracks its combat performance.

local SectorManifest = {
    ["red"] = {
        {
            enabled = true,
            triggerType = "IMMEDIATE", -- Evaluates instantly at mission startup
            groupName = "Heavy_Vanguard_Platoon",
            country = "Russia",
            units = {"T-72B", "BMP-2", "BMP-2", "ZSU-23-4 Shilka"}, -- Combined arms squad

            -- ZONE PLACEMENT CONFIGURATION
            placement = {
                heading = 120,            -- Initial facing direction of the units
                strategy = "ZONE_RANDOM", -- Directs engine to look for an ME zone instead of Bullseye
                zoneName = "Northern_Staging_Area", -- Exact name of the trigger zone in the ME
                spawnRadius = 1.5         -- 1.5 NM search radius for obstacle clearance loops
            },

            -- PRE-DEFINED ROUTING INFRASTRUCTURE
            -- Offsets are calculated in NM relative to the dynamic spawn coordinates
            route = {
                {
                    type = "On Road",     -- Units converge on local roads to travel quickly
                    speed = 45,           -- Speed target in km/h
                    offsetX = 0.5,
                    offsetY = 1.2
                }, 
                {
                    type = "Off Road",    -- Squad fans out into combat formation at destination
                    speed = 25,           -- Cross-country tactical advance speed
                    offsetX = 2.8,
                    offsetY = 4.1,
                    roe = "OPEN_FIRE",     -- Forces AI behavior to engage hostiles on sight
                    threat = "EVADE_FIRE" -- Enables defensive reaction behaviors when targeted
                }
            },

            -- ATTACHED OVERWATCH RECON ASSET
            -- Automatically spawns 2 seconds after the group to handle F10 map marking loops
            drone = {
                enabled = true,
                groupName = "Overwatch_Reaper_Bravo",
                unitType = "MQ-9 Reaper",
                country = "USA",
                frequency = 133.5,        -- Radio menu broadcast link channel
                callsign = 1,             -- Darkstar flight prefix code
                altitude = 18000,         -- Orbit altitude floor (Feet)
                speed = 120               -- Cruise airspeed velocity (Knots)
            }
        }
    }
}
```