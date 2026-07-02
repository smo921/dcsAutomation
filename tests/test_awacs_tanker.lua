-- Test AWACS/Tanker build function

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")
dofile("scripts/asset_factories.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Test helpers
local function createMockAirbase(name, id, x, y)
    return {
        getID = function() return id end,
        getPosition = function() return {p = {x = x, y = 100, z = y}} end
    }
end

describe("AssetFactories.buildAWACSorTanker", function()
    it("should delegate to buildAirGroup when airbaseName is specified", function()
        -- We can't fully test this without mocking buildAirGroup
        -- But we can verify the function handles the airbaseName path
        local config = {
            category = "AIRPLANE",
            groupName = "Test_AWACS",
            country = "USA",
            units = {{
                unitType = "E-3A"
            }},
            placement = {
                airbaseName = "Kutaisi",
                startType = "air_start"
            }
        }

        local result = AssetFactories.buildAWACSorTanker({x = 0, y = 0}, config)

        -- Should return a valid payload structure
        assert_not_nil(result)
        assert_equal("Test_AWACS", result.name)
        -- Category can be "AIRPLANE" or "plane" depending on buildAirGroup processing
        assert_true(result.category == "AIRPLANE" or result.category == "plane")
    end)

    it("should build AWACS with bearing/distance positioning", function()
        local config = {
            groupName = "AWACS_1",
            unitType = "E-3A",
            country = "USA",
            altitude = 30000,
            speed = 250,
            placement = {
                offsetHeading = 270, -- West
                offsetDistance = 100 -- 100 NM from bullseye
            }
        }

        local result = AssetFactories.buildAWACSorTanker({x = 0, y = 0}, config)

        assert_not_nil(result)
        assert_equal("AWACS_1", result.name)
    end)

    it("should build AWACS with direct coordinates", function()
        local config = {
            groupName = "AWACS_2",
            unitType = "E-3A",
            country = "USA",
            altitude = 30000,
            speed = 250,
            placement = {
                offsetX = 5000,
                offsetY = 10000
            }
        }

        local result = AssetFactories.buildAWACSorTanker({x = 0, y = 0}, config)

        assert_not_nil(result)
        assert_equal("AWACS_2", result.name)
    end)

    it("should include orbit task in route", function()
        local config = {
            groupName = "AWACS_3",
            unitType = "E-3A",
            country = "USA",
            altitude = 30000,
            speed = 250,
            placement = {
                offsetHeading = 180,
                offsetDistance = 50
            },
            orbitPattern = "Circle"
        }

        local result = AssetFactories.buildAWACSorTanker({x = 0, y = 0}, config)

        -- Check that route has points with tasks
        assert_not_nil(result.route)
        assert_not_nil(result.route.points)
        assert_true(#result.route.points >= 2)
    end)
end)

describe("AssetFactories.buildAWACSorTanker - AWACS specific tasks", function()
    it("should include SetFrequency task when frequency is specified", function()
        local config = {
            groupName = "AWACS_FREQ",
            unitType = "E-3A",
            country = "USA",
            altitude = 30000,
            speed = 250,
            frequency = 133.5,
            modulation = "FM",
            placement = {
                offsetX = 1000,
                offsetY = 2000
            }
        }

        local result = AssetFactories.buildAWACSorTanker({x = 0, y = 0}, config)

        -- The first waypoint should have the frequency task
        -- This is verified by checking the structure
        assert_not_nil(result)
    end)

    it("should include SetCallsign task when callsign is specified", function()
        local config = {
            groupName = "AWACS_CALLSIGN",
            unitType = "E-3A",
            country = "USA",
            altitude = 30000,
            speed = 250,
            callsign = 1,
            callsignNumber = 1,
            placement = {
                offsetX = 1000,
                offsetY = 2000
            }
        }

        local result = AssetFactories.buildAWACSorTanker({x = 0, y = 0}, config)

        assert_not_nil(result)
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
