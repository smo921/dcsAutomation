# DCS Mission Scripting Unit Tests

This directory contains unit tests for the DCS World mission scripting codebase. The tests can be run outside of DCS World using a standalone Lua interpreter.

## Prerequisites

To run these tests, you need to have Lua installed on your system:

1. Download and install Lua from [https://lua.org/download.html](https://lua.org/download.html)
2. Or install via a package manager:
   - Windows: `choco install lua` (using Chocolatey)
   - macOS: `brew install lua` (using Homebrew)
   - Linux: `sudo apt-get install lua5.3` (Ubuntu/Debian) or equivalent

## Running Tests

### On Windows

Double-click the `run_tests.bat` file in the root directory, or run from command prompt:

```cmd
run_tests.bat
```

### On macOS/Linux

From the root directory, run:

```bash
lua tests/run_tests.lua
```

Or make the script executable and run it:

```bash
chmod +x tests/run_tests.lua
./tests/run_tests.lua
```

## Test Structure

- `mocks/` - Mock implementations of DCS World APIs
- `test_config_standards.lua` - Tests for the configuration system
- `test_spatial_solver.lua` - Tests for spatial calculation functions
- `test_radar_handler.lua` - Tests for radar detection logic
- `run_tests.lua` - Main test runner that executes all tests

## Adding New Tests

1. Create a new test file following the pattern of existing test files
2. Add the new test file to the `test_files` array in `run_tests.lua`
3. Run the tests to ensure everything works

## Mock Implementation

The tests use mock implementations of DCS World APIs to allow testing outside of the game environment. The mocks are designed to provide enough functionality to test the core logic while being simple enough to maintain.

Key mocked components:
- `env` - Logging functions
- `trigger` - Action functions
- `Group` - Unit group management
- `mist` - Mission scripting tools
- `land` - Terrain functions
- `timer` - Time management

## Test Framework

A simple custom test framework is included that provides:
- `describe` - Test suite grouping
- `it` - Individual test cases
- `assert_equal`, `assert_true`, `assert_false`, `assert_nil`, `assert_not_nil` - Assertion functions

## Continuous Integration

These tests can be integrated into a CI/CD pipeline by:
1. Installing Lua in the build environment
2. Running `lua tests/run_tests.lua` as part of the build process
3. Failing the build if tests do not pass (exit code non-zero)