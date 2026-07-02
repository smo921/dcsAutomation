@echo off
REM Run the tests using the installed Lua path
"C:/Program Files (x86)/Lua/5.1/lua.exe" tests/run_tests.lua

REM Capture the exit code
set exit_code=%errorlevel%

echo.
if %exit_code% equ 0 (
    echo All tests completed successfully!
) else (
    echo Some tests failed!
)

exit /b %exit_code%