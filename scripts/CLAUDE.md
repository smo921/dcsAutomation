# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DCS World mission scripting project that uses Lua and the MIST framework to create dynamic, automated mission elements. The system implements:

- Dynamic group spawning based on various trigger types (immediate, radar detection, zone entry, objective completion)
- Automated AWACS and tanker deployment
- Air and ground unit management with proper route planning
- Radar detection systems with threat filtering
- Drone reconnaissance systems with F10 map integration
- Tactical marker systems for player feedback

## Key Files and Structure

### Core Engine Files:
- `mission_test.lua` - Main mission entry point that defines the sector manifest and orchestrates all dynamic theatre elements
- `unit_management.lua` - Core logic for unit management, spatial calculations, trigger evaluation, and sector handling
- `asset_factories.lua` - Factory functions for creating different types of assets (aircraft, ground units, radar, drones, etc.)
- `respawnOrActivate.lua` - Logic for respawning or activating existing groups
- `unitsAlive.lua` - Helper function to check if a group is alive

### Key Concepts:
- **Sectors**: Logical units that define where and when assets should spawn based on trigger conditions
- **Triggers**: Various ways to activate sector spawning (immediate, radar detection, zone entry, objective completion)
- **Asset Factories**: Functions that build different types of DCS groups with proper configuration
- **Spatial Solver**: Handles coordinate calculations, terrain checking, and safe placement logic

## Development Commands

### Running Tests
This project is primarily a mission script for DCS World. Testing involves:
1. Loading the mission in DCS World
2. Using the mission's built-in triggers to verify functionality
3. Manual verification of spawning behavior, radar detection, and drone operations

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

### Important Constants/Variables
- `SpatialSolver` - Contains all spatial calculation and terrain checking logic
- `TriggerRegistry` - Centralized trigger monitoring system
- `AssetFactories` - Factory functions for creating various DCS assets
- `MissionDirector` - Main orchestrator that manages sector instances

The codebase uses MIST library extensively for:
- Group management
- Route building 
- Spatial calculations
- Unit spawning