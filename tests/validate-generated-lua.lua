-- Lua validation script for generated mission configuration
-- Usage: "C:/Program Files (x86)/Lua/5.1/lua.exe" tests/validate-generated-lua.lua generated.lua
--
-- This script:
-- 1. Loads the generated Lua configuration
-- 2. Validates each unit against ConfigStandards templates
-- 3. Reports any validation errors

-- Load DCS mocks (provides Group, Event, timer, etc.)
dofile("tests/mocks/dcs_mocks.lua")

-- Load the validation modules
dofile("scripts/unit_management.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Track validation results
validation_passed = 0
validation_failed = 0

-- Helper to validate a unit configuration
function validateUnitConfig(unitConfig, unitIndex)
    local valid, errorMsg = ConfigStandards.validateConfig(unitConfig, ConfigStandards.UNIT_TEMPLATE)
    if valid then
        validation_passed = validation_passed + 1
        print(string.format("  Unit %d (%s): VALID", unitIndex, unitConfig.groupName or "unnamed"))
    else
        validation_failed = validation_failed + 1
        print(string.format("  Unit %d (%s): INVALID", unitIndex, unitConfig.groupName or "unnamed"))
        print(string.format("    Error: %s", errorMsg or "unknown"))
    end
    return valid
end

-- Helper to validate a waypoint configuration
function validateWaypointConfig(waypointConfig, unitName, wpIndex)
    local valid, errorMsg = ConfigStandards.validateConfig(waypointConfig, ConfigStandards.ROUTE_WAYPOINT_TEMPLATE)
    if valid then
        print(string.format("    Waypoint %d: VALID", wpIndex))
    else
        print(string.format("    Waypoint %d: INVALID", wpIndex))
        print(string.format("      Error: %s", errorMsg or "unknown"))
    end
    return valid
end

-- Test suite
describe("GeneratedLuaValidation", function()
    -- Test that ConfigStandards templates work correctly
    it("should have valid UNIT_TEMPLATE", function()
        local template = ConfigStandards.UNIT_TEMPLATE
        assert_not_nil(template)
        assert_equal("GROUND", template.category)
        assert_equal("IMMEDIATE", template.triggerType)
    end)

    it("should have valid ROUTE_WAYPOINT_TEMPLATE", function()
        local template = ConfigStandards.ROUTE_WAYPOINT_TEMPLATE
        assert_not_nil(template)
        assert_equal("Turning Point", template.type)
    end)
end)

-- Function to run validation on a loaded config
function validateLoadedConfig(config)
    print("\n=== Validating Generated Configuration ===\n")

    if not config or not config.UnitManifest then
        print("ERROR: No UnitManifest found in configuration")
        return false
    end

    local units = config.UnitManifest
    local manifestValid = true

    for i, unit in ipairs(units) do
        -- Validate the unit itself
        local valid = validateUnitConfig(unit, i)

        -- Validate units array within each unit
        if unit.units and #unit.units > 0 then
            for j, u in ipairs(unit.units) do
                local uValid, uErr = ConfigStandards.validateConfig(u, ConfigStandards.AIR_UNIT_TEMPLATE)
                if not uValid then
                    print(string.format("    Unit[%d].units[%d]: INVALID - %s", i, j, uErr or "unknown"))
                end
            end
        end

        -- Validate route waypoints
        if unit.route and #unit.route > 0 then
            for j, wp in ipairs(unit.route) do
                local wpValid, wpErr = ConfigStandards.validateConfig(wp, ConfigStandards.ROUTE_WAYPOINT_TEMPLATE)
                if not wpValid then
                    print(string.format("    Unit[%d].route[%d]: INVALID - %s", i, j, wpErr or "unknown"))
                end
            end
        end

        if not valid then
            manifestValid = false
        end
    end

    print(string.format("\n=== Validation Summary ==="))
    print(string.format("Passed: %d", validation_passed))
    print(string.format("Failed: %d", validation_failed))

    return manifestValid
end

-- If run directly, try to load the generated Lua file
if arg and arg[0] then
    -- Get the generated file from command line args
    local generatedFile = arg[1] or "generated-mission.lua"

    -- Read and evaluate the generated Lua
    print(string.format("Loading configuration from: %s", generatedFile))

    -- Load and execute the file - the UnitManifest will be defined in the global scope
    local status, result = pcall(dofile, generatedFile)

    -- After loading, UnitManifest should be available (not local at file scope)
    -- But since the file uses 'local UnitManifest', we need to check if it's defined
    if status then
        -- Try to access UnitManifest - it might be in the global table if not local
        local manifest = UnitManifest or _G.UnitManifest
        if manifest then
            validateLoadedConfig({ UnitManifest = manifest })
        else
            -- Try loading as a module
            print("Note: UnitManifest not found, trying alternative access...")
            -- Re-execute with pcall returning the value
            local loaded = assert(loadfile(generatedFile))()
            -- After loadfile execution, check globals
            print("Global UnitManifest:", UnitManifest ~= nil and "exists" or "not found")
            local manifest = UnitManifest
            if manifest then
                validateLoadedConfig({ UnitManifest = manifest })
            else
                print("ERROR: Could not access UnitManifest from generated file")
            end
        end
    else
        print(string.format("ERROR: Failed to load configuration: %s", result))
    end
end
