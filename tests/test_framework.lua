-- Shared test framework for DCS mission scripting tests

-- Global test counters
test_count = 0
pass_count = 0
fail_count = 0

-- Test framework functions
function describe(description, test_func)
    print("\n" .. description .. ":")
    test_func()
end

function it(description, test_func)
    test_count = test_count + 1
    local status, err = pcall(test_func)
    if status then
        pass_count = pass_count + 1
        print("  ✓ " .. description)
    else
        fail_count = fail_count + 1
        print("  ✗ " .. description .. " - FAILED: " .. tostring(err))
    end
end

function assert_equal(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: expected %s, got %s",
            message or "Assertion failed",
            tostring(expected),
            tostring(actual)))
    end
end

function assert_true(value, message)
    if not value then
        error(message or "Expected true, got false")
    end
end

function assert_false(value, message)
    if value then
        error(message or "Expected false, got true")
    end
end

function assert_nil(value, message)
    if value ~= nil then
        error(string.format("%s: expected nil, got %s",
            message or "Assertion failed",
            tostring(value)))
    end
end

function assert_not_nil(value, message)
    if value == nil then
        error(message or "Expected not nil, got nil")
    end
end