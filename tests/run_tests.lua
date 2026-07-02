#!/usr/bin/env lua

-- Main test runner for DCS mission scripting code

print("=== DCS Mission Scripting Unit Tests ===\n")

-- Track overall results
local total_tests = 0
local total_passed = 0
local total_failed = 0

-- Function to run a test file
function run_test_file(filename)
    print("Running " .. filename .. "...")

    -- Capture current counts
    local test_count = _G.test_count or 0
    local pass_count = _G.pass_count or 0
    local fail_count = _G.fail_count or 0

    -- Reset globals for this test
    _G.test_count = 0
    _G.pass_count = 0
    _G.fail_count = 0

    -- Run the test file
    local success, err = pcall(dofile, filename)

    if not success then
        print("  ERROR running test file: " .. tostring(err))
        return false
    end

    -- Add to totals
    total_tests = total_tests + _G.test_count
    total_passed = total_passed + _G.pass_count
    total_failed = total_failed + _G.fail_count

    print("  Tests: " .. _G.test_count .. ", Passed: " .. _G.pass_count .. ", Failed: " .. _G.fail_count .. "\n")
    return true
end

-- List of test files to run
local test_files = {
    "tests/test_config_standards.lua",
    "tests/test_spatial_solver.lua",
    "tests/test_radar_handler.lua",
    "tests/test_sector.lua"
}

-- Run all test files
for _, test_file in ipairs(test_files) do
    local success = run_test_file(test_file)
    if not success then
        print("Failed to run " .. test_file)
    end
end

-- Print final summary
print("=== Final Test Results ===")
print("Total tests: " .. total_tests)
print("Passed: " .. total_passed)
print("Failed: " .. total_failed)

if total_failed == 0 then
    print("\nAll tests passed! ✓")
    os.exit(0)
else
    print("\nSome tests failed! ✗")
    os.exit(1)
end