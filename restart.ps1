# Restart Jenkins Environment Script for Windows
# This script stops and starts the Jenkins environment

param(
    [switch]$SkipPrerequisites,
    [switch]$SkipSSH
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    White = "White"
}

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
}

# Main execution
function Main {
    Write-Host "🔄 Restarting Nomad + Consul Jenkins Environment (Windows)" -ForegroundColor $Colors.Yellow
    Write-Host "=========================================================" -ForegroundColor $Colors.Yellow
    Write-Host ""
    
    # Stop first
    Write-Info "Stopping Jenkins environment..."
    .\stop.ps1
    
    Write-Host ""
    Write-Info "Waiting 5 seconds before restarting..."
    Start-Sleep -Seconds 5
    
    Write-Host ""
    # Start again
    Write-Info "Starting Jenkins environment..."
    .\bootstrap.ps1 -SkipPrerequisites:$SkipPrerequisites -SkipSSH:$SkipSSH
    
    Write-Host ""
    Write-Success "Restart completed successfully! 🎉"
}

# Run main function
Main
