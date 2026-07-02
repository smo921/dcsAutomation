-- Test unified waypoint builder (BuildWaypoints)

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")
dofile("scripts/asset_factories.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Load test utilities
local TestUtils = dofile("tests/test_utils.lua")

-- Tests for BuildWaypoints
describe("UnitFormationBuilder.BuildWaypoints", function()
    it("should build ground waypoints with ROE", function()
        local waypoints = {
            {type = "Turning Point", speed = 30, roe = "OPEN_FIRE"},
            {type = "Off Road", speed = 25, roe = "RETURN_FIRE"}
        }

        local result = UnitFormationBuilder.BuildWaypoints(0, 0, waypoints, "GROUND")

        assert_not_nil(result)
        assert_equal(2, #result)
        -- Ground waypoints default to "Turning Point" type
        assert_equal("Turning Point", result[1].type)
    end)

    it("should build air waypoints with landing", function()
        local waypoints = {
            {type = "Turning Point", speed = 200, alt = 3000},
            {type = "landing", airbaseName = "Kutaisi"}
        }

        local result = UnitFormationBuilder.BuildWaypoints(0, 0, waypoints, "AIRPLANE")

        assert_not_nil(result)
        assert_equal(2, #result)
        assert_equal("Land", result[2].type)
    end)

    it("should build helicopter waypoints", function()
        local waypoints = {
            {type = "Turning Point", speed = 100, alt = 500, alt_type = "AGL"}
        }

        local result = UnitFormationBuilder.BuildWaypoints(0, 0, waypoints, "HELICOPTER")

        assert_not_nil(result)
        assert_equal(1, #result)
        -- Verify heli builder was used (check alt_type is AGL)
        assert_equal("AGL", result[1].alt_type)
    end)

    it("should add ROE task to all unit types", function()
        local waypoints = {
            {type = "Turning Point", speed = 150, roe = "WEAPON_FREE"}
        }

        local resultGround = UnitFormationBuilder.BuildWaypoints(0, 0, waypoints, "GROUND")
        local resultAir = UnitFormationBuilder.BuildWaypoints(0, 0, waypoints, "AIRPLANE")

        assert_not_nil(resultGround[1].task)
        assert_not_nil(resultAir[1].task)
    end)

    it("should add THREAT_REACTION only for ground units", function()
        local waypoints = {
            {type = "Turning Point", speed = 30, threat = "EVADE_FIRE"}
        }

        local resultGround = UnitFormationBuilder.BuildWaypoints(0, 0, waypoints, "GROUND")
        local resultAir = UnitFormationBuilder.BuildWaypoints(0, 0, waypoints, "AIRPLANE")

        -- Ground should have THREAT_REACTION in task
        local groundHasThreat = false
        if resultGround[1].task and resultGround[1].task.params and resultGround[1].task.params.tasks then
            for _, t in ipairs(resultGround[1].task.params.tasks) do
                if t.params and t.params.name == AssetFactories.OPTION_IDS.THREAT_REACTION then
                    groundHasThreat = true
                    break
                end
            end
        end

        -- Air should NOT have THREAT_REACTION
        local airHasThreat = false
        if resultAir[1].task and resultAir[1].task.params and resultAir[1].task.params.tasks then
            for _, t in ipairs(resultAir[1].task.params.tasks) do
                if t.params and t.params.name == AssetFactories.OPTION_IDS.THREAT_REACTION then
                    airHasThreat = true
                    break
                end
            end
        end

        assert_true(groundHasThreat)
        assert_false(airHasThreat)
    end)

    it("should handle empty waypoints", function()
        local result = UnitFormationBuilder.BuildWaypoints(0, 0, nil, "GROUND")

        assert_not_nil(result)
        assert_equal(0, #result)
    end)
end)

describe("AssetFactories.buildFrequencyTask", function()
    it("should build frequency task for AM", function()
        local task = AssetFactories.buildFrequencyTask(132.5, "AM")
        assert_equal("SetFrequency", task.id)
        assert_equal(132.5 * 1000000, task.params.frequency)
        assert_equal(0, task.params.modulation) -- AM = 0
    end)

    it("should build frequency task for FM", function()
        local task = AssetFactories.buildFrequencyTask(123.0, "FM")
        assert_equal("SetFrequency", task.id)
        assert_equal(123.0 * 1000000, task.params.frequency)
        assert_equal(1, task.params.modulation) -- FM = 1
    end)
end)

describe("AssetFactories.buildCallsignTask", function()
    it("should build callsign task with default number", function()
        local task = AssetFactories.buildCallsignTask("DARKSTAR")
        assert_equal("SetCallsign", task.id)
        assert_equal("DARKSTAR", task.params.callsign)
        assert_equal(1, task.params.number)
    end)

    it("should build callsign task with custom number", function()
        local task = AssetFactories.buildCallsignTask("DARKSTAR", 2)
        assert_equal(2, task.params.number)
    end)
end)

describe("AssetFactories.buildOrbitTask", function()
    it("should build Circle orbit task", function()
        local config = {orbitPattern = "Circle"}
        local task = AssetFactories.buildOrbitTask(config)
        assert_equal("Orbit", task.id)
        assert_equal("Circle", task.params.pattern)
    end)

    it("should build Anchored orbit task", function()
        local config = {
            orbitPattern = "Anchored",
            orbitLength = 5,
            orbitWidth = 2,
            orbitClockwise = true
        }
        local task = AssetFactories.buildOrbitTask(config)
        assert_equal("Anchored", task.params.pattern)
        assert_equal(180, task.params.hotLegDir)
        -- Use mist.utils for NM to meters conversion
        assert_equal(mist.utils.NMToMeters(5), task.params.legLength)
        assert_equal(mist.utils.NMToMeters(2), task.params.width)
        assert_true(task.params.clockWise)
    end)

    it("should use defaults when config values missing", function()
        local config = {}
        local task = AssetFactories.buildOrbitTask(config)
        assert_equal("Circle", task.params.pattern)
        -- Defaults: 15000 feet, 200 knots - converted to meters/m/s
        assert_true(math.abs(task.params.altitude - mist.utils.feetToMeters(15000)) < 1)
        assert_true(math.abs(task.params.speed - mist.utils.knotsToMps(200)) < 1)
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
