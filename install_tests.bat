@echo off
echo === Installing DCS Mission Scripting Test Environment ===
echo.

REM Check if Chocolatey is installed
where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo Chocolatey found. Installing Lua...
    choco install lua -y
    goto check_lua
)

REM Check if LuaRocks is available (indicates Lua is installed)
where luarocks >nul 2>&1
if %errorlevel% equ 0 (
    echo LuaRocks found. Lua is already installed.
    goto install_busted
)

echo Lua is not installed and Chocolatey is not available.
echo Please install Lua manually from https://lua.org/download.html
echo Or install Chocolatey from https://chocolatey.org/install
exit /b 1

:check_lua
REM Check if Lua is now available
lua -v >nul 2>&1
if %errorlevel% neq 0 (
    echo Lua installation failed or not in PATH.
    echo Please ensure Lua is properly installed and in your system PATH.
    exit /b 1
)

echo Lua successfully installed!

:install_busted
echo Installing Busted testing framework...
luarocks install busted
if %errorlevel% neq 0 (
    echo Warning: Failed to install Busted. You can still run the basic tests.
    echo To install Busted manually, run: luarocks install busted
) else (
    echo Busted testing framework installed successfully!
)

echo.
echo === Installation Complete ===
echo You can now run tests using:
echo   run_tests.bat
echo Or with Busted:
echo   busted tests/
echo.