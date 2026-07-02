-- Test ConfigStandards module

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Tests for ConfigStandards
describe("ConfigStandards.createSector", function()
    it("should create a sector with default values", function()
        local config = ConfigStandards.createSector({
            groupName = "Test_Group"
        })

        assert_equal("Test_Group", config.groupName)
        assert_equal("GROUND", config.category)
        assert_equal("IMMEDIATE", config.triggerType)
        assert_equal("Russia", config.country)
    end)

    it("should override default values", function()
        local config = ConfigStandards.createSector({
            groupName = "Test_Group",
            category = "AIRPLANE",
            country = "USA"
        })

        assert_equal("Test_Group", config.groupName)
        assert_equal("AIRPLANE", config.category)
        assert_equal("USA", config.country)
    end)
end)

describe("ConfigStandards.createWaypoint", function()
    it("should create a waypoint with default values (converted to meters/m/s)", function()
        local wp = ConfigStandards.createWaypoint({
            offsetX = 100
        })

        assert_equal("Turning Point", wp.type)
        -- Speed: 200 knots converted to m/s
        assert_true(math.abs(wp.speed - mist.utils.knotsToMps(200)) < 0.1)
        -- Altitude: 3000 feet converted to meters
        assert_true(math.abs(wp.alt - mist.utils.feetToMeters(3000)) < 0.1)
        -- offsetX: 100 NM converted to meters
        assert_true(math.abs(wp.offsetX - mist.utils.NMToMeters(100)) < 0.1)
    end)
end)

describe("ConfigStandards.createDrone", function()
    it("should create a drone with default values (converted to meters/m/s)", function()
        local drone = ConfigStandards.createDrone({
            groupName = "Test_Drone"
        })

        assert_equal("Test_Drone", drone.groupName)
        assert_equal("MQ-9 Reaper", drone.unitType)
        assert_equal("USA", drone.country)
        -- Altitude: 15000 feet converted to meters
        assert_true(math.abs(drone.altitude - mist.utils.feetToMeters(15000)) < 0.1)
        -- Speed: 200 knots converted to m/s
        assert_true(math.abs(drone.speed - mist.utils.knotsToMps(200)) < 0.1)
    end)
end)

describe("ConfigStandards.createRadarSector", function()
    it("should create a radar sector with merged properties", function()
        local radar = ConfigStandards.createRadarSector({
            groupName = "Test_Radar",
            maxDetectRange = 150000.0
        })

        assert_equal("Test_Radar", radar.groupName)
        assert_equal(150000.0, radar.maxDetectRange)
        assert_equal(false, radar.radarFilterEnabled) -- from template
    end)
end)

describe("ConfigStandards.deepCopy", function()
    it("should create a deep copy of a table", function()
        local original = {
            a = 1,
            b = {
                c = 2,
                d = {
                    e = 3
                }
            }
        }

        local copy = ConfigStandards.deepCopy(original)

        -- Should be equal
        assert_equal(original.a, copy.a)
        assert_equal(original.b.c, copy.b.c)
        assert_equal(original.b.d.e, copy.b.d.e)

        -- But not the same reference
        assert_true(original ~= copy)
        assert_true(original.b ~= copy.b)
        assert_true(original.b.d ~= copy.b.d)
    end)
end)

describe("ConfigStandards.mergeConfig", function()
    it("should merge two configurations", function()
        local defaults = {
            a = 1,
            b = 2,
            c = {
                d = 3,
                e = 4
            }
        }

        local overrides = {
            b = 5,
            c = {
                e = 6,
                f = 7
            },
            g = 8
        }

        local result = ConfigStandards.mergeConfig(defaults, overrides)

        assert_equal(1, result.a) -- from defaults
        assert_equal(5, result.b) -- from overrides
        assert_equal(3, result.c.d) -- from defaults (not overridden)
        assert_equal(6, result.c.e) -- from overrides
        assert_equal(7, result.c.f) -- from overrides
        assert_equal(8, result.g) -- from overrides
    end)
end)

describe("ConfigStandards.validateConfig", function()
    it("should validate correct configuration", function()
        local config = ConfigStandards.createSector({
            groupName = "Test_Group"
        })

        local valid, error = ConfigStandards.validateConfig(config, ConfigStandards.SECTOR_TEMPLATE)

        assert_true(valid)
        assert_nil(error)
    end)

    it("should detect type mismatches", function()
        -- Test with a minimal template that has no required fields
        local minimalTemplate = {
            value = 100  -- number type
        }
        local config = {
            value = "not_a_number"
        }

        local valid, error = ConfigStandards.validateConfig(config, minimalTemplate)

        assert_false(valid)
        assert_true(string.find(error or "", "Type mismatch") ~= nil)
    end)

    it("should detect missing required fields", function()
        local config = {
            -- Missing required groupName
            triggerType = "RADAR"
        }

        local valid, error = ConfigStandards.validateConfig(config, ConfigStandards.SECTOR_TEMPLATE)

        assert_false(valid)
        assert_true(string.find(error or "", "Missing required field") ~= nil)
    end)
end)

describe("ConfigStandards.validateEnum", function()
    it("should pass when value is in allowed list", function()
        local config = {
            triggerType = "RADAR"
        }

        local valid, error = ConfigStandards.validateEnum(config, "triggerType", {
            "IMMEDIATE", "RADAR", "TRIGGER_ZONE", "OBJECTIVE_COMPLETE"
        }, "root")

        assert_true(valid)
        assert_nil(error)
    end)

    it("should fail when value is not in allowed list", function()
        local config = {
            triggerType = "INVALID_TYPE"
        }

        local valid, error = ConfigStandards.validateEnum(config, "triggerType", {
            "IMMEDIATE", "RADAR", "TRIGGER_ZONE", "OBJECTIVE_COMPLETE"
        }, "root")

        assert_false(valid)
        assert_true(string.find(error or "", "Invalid value") ~= nil)
    end)

    it("should pass when value is nil", function()
        local config = {
            -- triggerType is nil (optional in some contexts)
        }

        local valid, error = ConfigStandards.validateEnum(config, "triggerType", {
            "IMMEDIATE", "RADAR", "TRIGGER_ZONE", "OBJECTIVE_COMPLETE"
        }, "root")

        assert_true(valid)
        assert_nil(error)
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
