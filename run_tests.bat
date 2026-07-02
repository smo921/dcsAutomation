@echo off
echo === DCS Mission Scripting Unit Tests ===
echo.

REM Check if Lua is installed
lua -v >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Lua is not installed or not in PATH
    echo Please install Lua from https://lua.org/download.html
    echo Or add Lua to your system PATH
    exit /b 1
)

REM Run the tests
lua tests/run_tests.lua

REM Capture the exit code
set exit_code=%errorlevel%

echo.
if %exit_code% equ 0 (
    echo All tests completed successfully!
) else (
    echo Some tests failed!
)

exit /b %exit_code%