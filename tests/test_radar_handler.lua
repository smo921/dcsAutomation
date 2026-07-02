-- Test RadarHandler module

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Load test utilities
local TestUtils = dofile("tests/test_utils.lua")

-- Mock radar unit for testing
local mock_radar_unit = TestUtils.createMockRadarUnit("Mock_Radar")

-- Mock target unit for testing
local mock_target_unit = TestUtils.createMockTargetUnit("Mock_Target", "F-16C_50")

-- Tests for RadarHandler
describe("RadarHandler.KmToNm", function()
    it("should convert kilometers to nautical miles", function()
        -- Use mist.utils.NMToMeters to get the conversion factor
        local metersPerNm = mist.utils.NMToMeters(1)
        -- 1852 km = 1852000 meters = 1000 NM * 1852 meters/NM
        local km = 1852
        local nm = RadarHandler.KmToNm(km)
        -- Should be approximately 1000 NM
        assert_true(math.abs(nm - 1000) < 1)
    end)
end)

describe("RadarHandler.getDistanceInNM", function()
    it("should calculate distance between units", function()
        local distance = RadarHandler.getDistanceInNM(mock_radar_unit, mock_target_unit)

        -- Should return a numeric distance
        assert_not_nil(distance)
        assert_true(type(distance) == "number")
        assert_true(distance > 0)
    end)

    it("should return nil for missing units", function()
        local distance = RadarHandler.getDistanceInNM(nil, mock_target_unit)
        assert_nil(distance)

        distance = RadarHandler.getDistanceInNM(mock_radar_unit, nil)
        assert_nil(distance)
    end)
end)

describe("RadarHandler.formatDetection", function()
    it("should format detection information", function()
        local detection = {
            object = mock_target_unit
        }

        local formatted = RadarHandler.formatDetection(mock_radar_unit, detection)

        -- Should contain the unit name and distance
        assert_true(string.find(formatted, "Mock_Target") ~= nil)
        assert_true(string.find(formatted, "nm") ~= nil)
    end)
end)

describe("RadarHandler.isThreat", function()
    it("should identify threats correctly", function()
        local threat_detection = {
            object = mock_target_unit -- F-16 should be a threat
        }

        local is_threat = RadarHandler.isThreat(threat_detection)
        assert_true(is_threat)
    end)

    it("should filter non-threats", function()
        local non_threat_unit = TestUtils.createMockTargetUnit("Mock_Tanker", "KC-135")

        local non_threat_detection = {
            object = non_threat_unit
        }

        local is_threat = RadarHandler.isThreat(non_threat_detection)
        assert_false(is_threat)
    end)

    it("should handle missing aircraft data", function()
        local is_threat = RadarHandler.isThreat(nil)
        assert_false(is_threat)

        is_threat = RadarHandler.isThreat({})
        assert_false(is_threat)
    end)
end)

describe("RadarHandler.logThreat", function()
    it("should log threat information", function()
        local detection = {
            object = mock_target_unit
        }

        -- This should not throw an error
        RadarHandler.logThreat(mock_radar_unit, detection)
        assert_true(true) -- If we get here, it worked
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