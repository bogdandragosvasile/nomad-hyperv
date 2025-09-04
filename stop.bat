@echo off
REM Stop Jenkins Environment Script for Windows (Batch)
REM This script calls the PowerShell stop script

echo.
echo ========================================
echo   Stopping Jenkins Environment
echo ========================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available or not in PATH
    echo Please install PowerShell or use the .ps1 script directly
    pause
    exit /b 1
)

echo Stopping Jenkins environment...
echo.

REM Call the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0stop.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   Jenkins environment stopped!
    echo ========================================
    echo.
) else (
    echo.
    echo ========================================
    echo   Stop failed!
    echo ========================================
    echo.
    echo Check the error messages above for details.
    echo.
)

pause
