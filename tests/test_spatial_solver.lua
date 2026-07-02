-- Test SpatialSolver module

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Tests for SpatialSolver
describe("SpatialSolver.getBullseye", function()
    it("should return bullseye coordinates", function()
        local blue_bullseye = SpatialSolver.getBullseye("blue")
        local red_bullseye = SpatialSolver.getBullseye("red")

        assert_not_nil(blue_bullseye)
        assert_not_nil(red_bullseye)
        assert_equal(0, blue_bullseye.x)
        assert_equal(0, blue_bullseye.y)
        assert_equal(5000, red_bullseye.x)
        assert_equal(5000, red_bullseye.y)
    end)
end)

describe("SpatialSolver.getVector", function()
    it("should calculate vector coordinates", function()
        local origin = {x = 0, y = 0}
        local x, y = SpatialSolver.getVector(origin, 0, 1) -- 0 degrees, 1 NM

        -- Should be pointing north (positive y)
        assert_true(y > 0)
        assert_true(math.abs(x) < 1) -- Should be close to 0
    end)

    it("should use default values when not provided", function()
        local origin = {x = 0, y = 0}
        local x, y = SpatialSolver.getVector(origin) -- No parameters

        -- Should use defaults: heading 180, distance 60
        assert_true(y < 0) -- South direction
    end)
end)

describe("SpatialSolver.getCoordinates", function()
    it("should handle bearing/distance positioning", function()
        local origin = {x = 0, y = 0}
        local placementConfig = {
            offsetHeading = 90, -- East
            offsetDistance = 1 -- 1 NM
        }

        local x, y = SpatialSolver.getCoordinates(origin, placementConfig)

        -- Should be east of origin (positive x)
        assert_true(x > 0)
        assert_true(math.abs(y) < 100) -- Should be close to same y
    end)

    it("should handle direct coordinate positioning (input in NM, output in meters)", function()
        local origin = {x = 0, y = 0}
        local placementConfig = {
            offsetX = 1,    -- 1 NM
            offsetY = 2     -- 2 NM
        }

        local x, y = SpatialSolver.getCoordinates(origin, placementConfig)

        -- Should be converted from NM to meters
        assert_true(math.abs(x - mist.utils.NMToMeters(1)) < 1)
        assert_true(math.abs(y - mist.utils.NMToMeters(2)) < 1)
    end)

    it("should handle group waypoint positioning", function()
        local origin = {x = 0, y = 0}
        local placementConfig = {
            groupName = "Test_Group",
            waypoint = 1
        }

        local x, y = SpatialSolver.getCoordinates(origin, placementConfig)

        -- Should return the waypoint coordinates from mock
        assert_equal(0, x)
        assert_equal(0, y)
    end)

    it("should fall back to origin when no positioning method is specified", function()
        local origin = {x = 100, y = 200}
        local placementConfig = {} -- Empty config

        local x, y = SpatialSolver.getCoordinates(origin, placementConfig)

        assert_equal(100, x)
        assert_equal(200, y)
    end)
end)

describe("SpatialSolver.terrainIsClear", function()
    it("should check terrain clearance", function()
        local isClear = SpatialSolver.terrainIsClear(0, 0, 20)

        -- Should be true based on our mock implementation
        assert_true(isClear)
    end)
end)

describe("SpatialSolver.findStaticObstructions", function()
    it("should check for static obstructions", function()
        local hasObstruction = SpatialSolver.findStaticObstructions(0, 0, 20)

        -- Should be false based on our mock implementation
        assert_false(hasObstruction)
    end)
end)

describe("SpatialSolver.countSceneryObstructions", function()
    it("should count scenery obstructions", function()
        -- Configure mock to find 2 obstructions
        _MOCK_WORLD_SETTINGS.shouldFindObstructions = true
        _MOCK_WORLD_SETTINGS.sceneryObstructionCount = 1  -- 1 for each searchObjects call = 2 total

        local count = SpatialSolver.countSceneryObstructions(0, 0, 20)

        -- Should be 2 based on our mock implementation (calls searchObjects twice)
        assert_equal(2, count)

        -- Reset mock settings
        _MOCK_WORLD_SETTINGS.shouldFindObstructions = false
        _MOCK_WORLD_SETTINGS.sceneryObstructionCount = 0
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
