# DCS Mission Scripting Unit Testing Framework

This project provides a comprehensive unit testing framework for DCS World mission scripting code that can run outside of the DCS environment.

## Features

1. **Mock DCS APIs**: Complete mock implementations of DCS World functions and classes
2. **Modular Tests**: Organized test structure for different components
3. **Multiple Test Runners**: Both simple custom runner and Busted framework support
4. **Cross-Platform**: Works on Windows, macOS, and Linux

## Directory Structure

```
tests/
├── mocks/
│   └── dcs_mocks.lua          # Mock DCS World APIs
├── test_framework.lua         # Shared test framework functions
├── test_utils.lua             # Shared test utilities and mock data
├── test_config_standards.lua  # Tests for configuration system
├── test_spatial_solver.lua    # Tests for spatial calculations
├── test_radar_handler.lua     # Tests for radar detection logic
├── test_sector.lua            # Tests for Sector class
├── run_tests.lua             # Simple test runner
├── busted_example_spec.lua   # Busted framework example
├── README.md                 # This file
install_tests.bat             # Installation script (Windows)
run_tests.bat                 # Test runner script (Windows)
```

## Installation

### Option 1: Simple Installation (Windows)
```cmd
install_tests.bat
```

### Option 2: Manual Installation
1. Install Lua from https://lua.org/download.html
2. (Optional) Install Busted: `luarocks install busted`

## Running Tests

### Simple Test Runner
```cmd
run_tests.bat
```
or
```bash
lua tests/run_tests.lua
```

### Busted Framework
```bash
busted tests/busted_example_spec.lua
```

## Adding New Tests

1. Create a new test file in the `tests/` directory
2. Follow the pattern in existing test files:
   - Load mocks first
   - Load modules to test
   - Load shared test framework (`dofile("tests/test_framework.lua")`)
   - Load test utilities if needed (`local TestUtils = dofile("tests/test_utils.lua")`)
   - Use `describe` and `it` for organization
   - Use assertion functions for validation
3. Add the new test file to `test_files` array in `run_tests.lua`
   - Use assertion functions for validation
3. Add the new test file to `test_files` array in `run_tests.lua`

## Mocked Components

The framework mocks the following DCS World components:
- `env` - Logging functions
- `trigger` - Action functions
- `Group`, `Unit` - Unit management
- `mist` - Mission scripting tools
- `land`, `world` - Terrain functions
- `timer` - Time management
- `coalition`, `country` - Coalition management
- `missionCommands` - Menu commands
- `Airbase` - Airbase management

## Benefits

1. **Fast Development**: Test logic without starting DCS
2. **CI/CD Integration**: Run tests in automated builds
3. **Regression Testing**: Catch bugs before they reach DCS
4. **Documentation**: Tests serve as usage examples
5. **Refactoring Safety**: Confidence when modifying code

## Limitations

1. **Mock Accuracy**: Mocks may not perfectly replicate DCS behavior
2. **Integration Testing**: Still need DCS for full integration testing
3. **Performance Testing**: Cannot test actual performance in DCS environment

## Best Practices

1. **Test Pure Functions**: Focus on logic that doesn't require DCS state
2. **Mock External Dependencies**: Isolate the code under test
3. **Use Descriptive Test Names**: Make it clear what each test verifies
4. **Test Edge Cases**: Include boundary conditions and error cases
5. **Keep Tests Independent**: Each test should be able to run alone