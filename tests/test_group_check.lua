-- Test groupCheck function (shared group lifecycle logic)

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Load test utilities
local TestUtils = dofile("tests/test_utils.lua")

-- Tests for groupCheck
describe("groupCheck", function()
    it("should return false for nil group name when checkAlive=true", function()
        local result = groupCheck(nil, true)
        assert_false(result)
    end)

    it("should return true for nil group name when checkAlive=false", function()
        local result = groupCheck(nil, false)
        assert_true(result)
    end)

    it("should return false when group does not exist and checkAlive=true", function()
        local result = groupCheck("NonExistent_Group", true)
        assert_false(result)
    end)

    it("should return true when group does not exist and checkAlive=false", function()
        local result = groupCheck("NonExistent_Group", false)
        assert_true(result)
    end)

    it("should return true for existing alive group when checkAlive=true", function()
        local result = groupCheck("Test_Group", true)
        assert_true(result)
    end)

    it("should return false for existing group when checkAlive=false", function()
        local result = groupCheck("Test_Group", false)
        assert_false(result)
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
