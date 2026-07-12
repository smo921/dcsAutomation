-- Test Unit class

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")
dofile("scripts/asset_factories.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Load test utilities
local TestUtils = dofile("tests/test_utils.lua")

-- Tests for Unit class
describe("Unit:new", function()
    it("should create a new unit with default values", function()
        local unit_config = {
            groupName = "Test_Unit",
            units = {"T-72B", "BMP-2"}
        }

        local unit = Unit:new(unit_config)

        assert_not_nil(unit)
        assert_equal("Test_Unit", unit.groupName)
        assert_equal("GROUND", unit.category)
        assert_equal("IMMEDIATE", unit.triggerType)
        assert_equal("Russia", unit.country)
        assert_false(unit.hasSpawned)
    end)

    it("should create a unit with custom values", function()
        local unit_config = {
            groupName = "Test_Unit",
            category = "AIRPLANE",
            country = "USA",
            triggerType = "RADAR",
            units = {"F-16C_50"}
        }

        local unit = Unit:new(unit_config)

        assert_equal("Test_Unit", unit.groupName)
        assert_equal("AIRPLANE", unit.category)
        assert_equal("RADAR", unit.triggerType)
        assert_equal("USA", unit.country)
    end)

    it("should handle empty configuration", function()
        local unit = Unit:new(nil)
        assert_not_nil(unit)
    end)
end)

describe("Unit:_checkOwnUnitsDead", function()
    it("should detect when units are dead", function()
        -- Mock a dead group
        local dead_group = {
            isExist = function() return false end,
            getSize = function() return 0 end
        }

        -- Temporarily override Group.getByName
        local original_getByName = Group.getByName
        Group.getByName = function(name)
            if name == "Dead_Group" then
                return dead_group
            end
            return original_getByName(name)
        end

        local unit_config = {
            groupName = "Dead_Group",
            units = {"T-72B"}
        }

        local unit = Unit:new(unit_config)
        local is_dead = unit:_checkOwnUnitsDead()

        -- Restore original function
        Group.getByName = original_getByName

        assert_true(is_dead)
    end)

    it("should detect when units are alive", function()
        local unit_config = {
            groupName = "Alive_Group",
            units = {"T-72B", "BMP-2"}
        }

        local unit = Unit:new(unit_config)
        local is_dead = unit:_checkOwnUnitsDead()

        assert_false(is_dead)
    end)
end)

describe("UnitPlacementConfig", function()
    it("should create a new placement config", function()
        local placement_config = {
            heading = 90,
            offsetX = 1.5,
            offsetY = 2.0,
            spawnRadius = 0.5
        }

        local config = UnitPlacementConfig.new(placement_config)

        assert_not_nil(config)
        assert_equal(90, config.heading)
        -- Use mist.utils for unit conversions
        assert_equal(mist.utils.NMToMeters(1.5), config.offsetX)
        assert_equal(mist.utils.NMToMeters(2.0), config.offsetY)
        assert_equal(mist.utils.NMToMeters(0.5), config.spawnRadius)
    end)
end)

describe("UnitRouteWaypoint", function()
    it("should create a new route waypoint", function()
        local route_config = {
            type = "Turning Point",
            speed = 300, -- knots
            alt = 10000, -- feet
            offsetX = 5.0,
            offsetY = 10.0
        }

        local waypoint = UnitRouteWaypoint.new(route_config)

        assert_not_nil(waypoint)
        assert_equal("Turning Point", waypoint.type)
        -- Use mist.utils for unit conversions
        assert_equal(mist.utils.knotsToMps(300), waypoint.speed)
        assert_equal(mist.utils.feetToMeters(10000), waypoint.alt)
        assert_equal(mist.utils.NMToMeters(5.0), waypoint.offsetX)
        assert_equal(mist.utils.NMToMeters(10.0), waypoint.offsetY)
    end)
end)

-- Run tests and report results
print("\n=== Test Results ===")
print("Total tests: " .. test_count)
print("Passed: " .. pass_count)
print("Failed: " .. fail_count)

if fail_count == 0 then
    print("\nAll tests passed! ✓")
else
    print("\nSome tests failed! ✗")
end