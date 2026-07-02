-- Test checkGroupState function (shared group lifecycle logic)

-- Load mocks first
dofile("tests/mocks/dcs_mocks.lua")

-- Load the modules to test
dofile("scripts/unit_management.lua")

-- Load shared test framework
dofile("tests/test_framework.lua")

-- Load test utilities
local TestUtils = dofile("tests/test_utils.lua")

-- Tests for checkGroupState
describe("checkGroupState", function()
    it("should return false for nil group name when expectAlive=true", function()
        local result = checkGroupState(nil, true)
        assert_false(result)
    end)

    it("should return true for nil group name when expectAlive=false", function()
        local result = checkGroupState(nil, false)
        assert_true(result)
    end)

    it("should return false when group does not exist and expectAlive=true", function()
        local result = checkGroupState("NonExistent_Group", true)
        assert_false(result)
    end)

    it("should return true when group does not exist and expectAlive=false", function()
        local result = checkGroupState("NonExistent_Group", false)
        assert_true(result)
    end)

    it("should return true for existing alive group when expectAlive=true", function()
        local result = checkGroupState("Test_Group", true)
        assert_true(result)
    end)

    it("should return false for existing group when expectAlive=false", function()
        local result = checkGroupState("Test_Group", false)
        assert_false(result)
    end)
end)

-- Tests for shouldGroupSpawn (wrapper function)
describe("shouldGroupSpawn", function()
    it("should return false when group exists and is active", function()
        local result = shouldGroupSpawn("Test_Group")
        assert_false(result)
    end)

    it("should return true when group does not exist", function()
        local result = shouldGroupSpawn("NonExistent_Group")
        assert_true(result)
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
