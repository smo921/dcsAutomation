# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DCS World mission scripting project that uses Lua and the MIST framework to create dynamic, automated mission elements. The system implements a data-driven framework for orchestrating complex dynamic theater operations in Digital Combat Simulator (DCS).

Key features:
- Dynamic group spawning based on various trigger types (immediate, radar detection, zone entry, objective completion)
- Automated AWACS and tanker deployment with orbit patterns
- Air and ground unit management with proper route planning
- Radar detection systems with threat filtering
- Drone reconnaissance systems with F10 map integration
- Tactical marker systems for player feedback
- Standardized configuration system with validation

## Key Files and Structure

### Core Engine Files:
- `mission_test.lua` - Main mission entry point that defines the sector manifest and orchestrates all dynamic theatre elements
- `unit_management.lua` - Core logic for unit management, spatial calculations, trigger evaluation, and sector handling. Contains the standardized configuration system.
- `asset_factories.lua` - Factory functions for creating different types of assets (aircraft, ground units, radar, drones, etc.)
- `respawnOrActivate.lua` - Logic for respawning or activating existing groups
- `unitsAlive.lua` - Helper function to check if a group is alive

### Core Architecture Components:

1. **MissionDirector** - Main orchestrator that manages sector instances and initializes the engine loop
2. **Sector/RadarSector** - Object-oriented classes representing mission elements with different trigger types
3. **TriggerRegistry** - Centralized trigger monitoring system that evaluates conditions and spawns assets
4. **AssetFactories** - Factory pattern implementation for creating various DCS assets with proper configuration
5. **SpatialSolver** - Handles coordinate calculations, terrain checking, and safe placement logic
6. **ConfigStandards** - Standardized configuration system with templates and validation utilities
7. **MapMarkerRegistry** - F10 map marker management system for tactical feedback

## Development Commands

### Lua Configuration Generation

To regenerate Lua from JSON configuration after editing the mission in the Electron app:

```bash
# Run the Lua generation test script (validates output against unit_management.lua templates)
node ./tests/lua-generation-test.js ./missions/<config>.json ./missions/<config>.lua
```

This command:
1. Loads the JSON configuration from `missions/`
2. Uses the mission-editor stores to generate Lua code
3. Validates the output against `unit_management.lua` templates
4. Reports which units pass/fail validation

### Commit Messages
When making commits, use the `git commit` command directly with `-m` flag for short messages, or write the message in a text editor. Avoid using PowerShell here-strings (`@'...'@`) for commit messages as they can introduce unwanted symbols.

### Running Tests
This project includes a unit testing framework using Busted (installed via LuaRocks). Tests verify the configuration system, spatial solvers, radar handlers, and asset factories.

**To run tests:**
```bash
# Using the batch script (recommended)
run_tests.bat

# Or directly with Lua
"C:/Program Files (x86)/Lua/5.1/lua.exe" tests/run_tests.lua
```

**To run a single test file (for development):**
```bash
lua tests/test_config_standards.lua
lua tests/test_spatial_solver.lua
# etc.
```

**To install testing dependencies:**
```bash
# Install Lua and Busted using Chocolatey
install_tests.bat
```

**Test files:**
- `tests/test_config_standards.lua` - Configuration template and validation tests
- `tests/test_spatial_solver.lua` - Coordinate and terrain calculation tests
- `tests/test_radar_handler.lua` - Radar detection and threat filtering tests
- `tests/test_sector.lua` - Sector class and configuration parsing tests
- `tests/test_waypoint_builder.lua` - Waypoint and route building tests
- `tests/test_awacs_tanker.lua` - AWACS/Tanker asset factory tests
- `tests/test_group_check.lua` - Group lifecycle tests

### Script Loading Order
When initializing in DCS Mission Editor, load scripts in this strict sequence:

1. **`mist.lua`** - Mission Scripting Tools library (prerequisite)
2. **`asset_factories.lua`** - Low-level unit payload compilation and formatting
3. **`unit_management.lua`** - Core solver engine, map marker registry, radar loops, and sector classes
4. **`mission_test.lua`** - Centralized configuration manifest and launch engine loop

---

## Unit Conventions
Configurations use non-metric units for user clarity; the framework handles conversion to DCS internal units:
- **Altitude**: Feet (converted to meters)
- **Distance**: Nautical Miles (converted to meters)
- **Speed**: Knots (converted to m/s)

### Debugging
- Use `env.info()` calls throughout the codebase for logging
- Check DCS World's `dcs.log` file for output
- Monitor F10 map markers for tactical feedback
- Use DCS World's built-in debugging tools to inspect group states

### Code Structure Notes
The code is organized in a modular fashion:
- Object-oriented patterns with metatables for sectors and radar sectors
- Factory pattern for creating different types of assets (air, ground, radar, drones)
- Event-driven architecture using timer scheduling and trigger registries
- Spatial math utilities for coordinate calculations and terrain validation
- Standardized configuration system for consistent data structures and validation

## Standardized Configuration System

The project includes a comprehensive standardized configuration system that provides:
- Consistent data structures for all configuration types using templates
- Validation to catch configuration errors early
- Helper functions for creating and working with configurations
- Support for inheritance and merging of configurations

Key templates available:
- `ConfigStandards.SECTOR_TEMPLATE` - Base sector configuration
- `ConfigStandards.ROUTE_WAYPOINT_TEMPLATE` - Route waypoint configuration
- `ConfigStandards.DRONE_TEMPLATE` - Drone configuration
- `ConfigStandards.RADAR_SECTOR_TEMPLATE` - Radar sector specific configuration
- `ConfigStandards.POINT_DEFENSE_TEMPLATE` - Point defense configuration

Key utility functions:
- `ConfigStandards.createSector(config)` - Create a sector from template
- `ConfigStandards.createWaypoint(config)` - Create a waypoint from template
- `ConfigStandards.createDrone(config)` - Create a drone from template
- `ConfigStandards.createRadarSector(config)` - Create a radar sector from template
- `ConfigStandards.validateConfig(config, template)` - Validate a configuration against a template

## Unified Air Placement System

The system implements a unified air placement system with three modes:
1. **Mode 1: Airbase ramp slot anchoring** - Uses specific parking spots at airbases
2. **Mode 2: Bearing + distance positioning** - Places units at a specific bearing and distance from an origin point
3. **Mode 3: Direct coordinate positioning** - Places units at specific X/Y coordinates

This system is used by aircraft, drones, AWACS, and tanker assets for consistent placement logic.

## Reference Point System

The framework uses a unified reference point system for coordinate positioning. All positions are computed relative to:
- **Bullseye**: Global theater reference point (X/Y coordinates)
- **Airbases**: Name-based lookup via `Airbase.getByName()` at runtime (coordinates stored in `mission_test.lua`)
- **Trigger Zones**: Mission-defined zones in the DCS Mission Editor
- **Battle Lines**: Custom line segments for linear deployment patterns

This reference point system is also used by the **DCS Mission Editor** Electron app (`mission-editor/`), which provides a visual interface for creating configurations without writing Lua code.

## Trigger Types

The framework supports multiple trigger types for dynamic asset spawning:
- `IMMEDIATE` - Spawns assets immediately at mission start
- `RADAR` - Spawns early-warning systems that trigger when threats are detected
- `TRIGGER_ZONE` - Binds deployment to Mission Editor geographical zones
- `OBJECTIVE_COMPLETE` - Enables chain reactions based on parent group destruction

## Important Constants/Variables
- `SpatialSolver` - Contains all spatial calculation and terrain checking logic
- `TriggerRegistry` - Centralized trigger monitoring system
- `AssetFactories` - Factory functions for creating various DCS assets
- `MissionDirector` - Main orchestrator that manages sector instances
- `ConfigStandards` - Standardized configuration templates and utilities
- `MapMarkerRegistry` - F10 map marker management system

The codebase uses MIST library extensively for:
- Group management
- Route building 
- Spatial calculations
- Unit spawning