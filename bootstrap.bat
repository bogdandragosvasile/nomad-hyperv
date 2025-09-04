@echo off
REM Nomad + Consul Jenkins Environment Bootstrap Script for Windows (Batch)
REM This script calls the PowerShell bootstrap script

echo.
echo ========================================
echo   Jenkins Environment Bootstrap
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

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Starting Jenkins environment bootstrap...
echo.

REM Call the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0bootstrap.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   Bootstrap completed successfully!
    echo ========================================
    echo.
    echo Jenkins is available at: http://localhost:8080
    echo Username: admin
    echo Password: admin
    echo.
) else (
    echo.
    echo ========================================
    echo   Bootstrap failed!
    echo ========================================
    echo.
    echo Check the error messages above for details.
    echo.
)

pause
