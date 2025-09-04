# Stop Jenkins Environment Script for Windows
# This script gracefully stops the Jenkins environment

param(
    [switch]$Force
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

# Stop Jenkins environment
function Stop-JenkinsEnvironment {
    Write-Info "Stopping Jenkins environment..."
    
    Push-Location "ci\jenkins-bootstrap"
    
    try {
        # Stop all services
        Write-Info "Stopping Docker Compose services..."
        docker-compose down
        
        # Remove any remaining containers
        Write-Info "Cleaning up remaining containers..."
        $containers = docker ps -a --filter "name=nomad-consul" --format "{{.Names}}"
        if ($containers) {
            $containers | ForEach-Object { docker rm -f $_ }
        }
        
        # Remove networks
        Write-Info "Cleaning up networks..."
        $networks = docker network ls --filter "name=jenkins-bootstrap" --format "{{.Name}}"
        if ($networks) {
            $networks | ForEach-Object { docker network rm $_ }
        }
    }
    finally {
        Pop-Location
    }
    
    Write-Success "Jenkins environment stopped successfully!"
}

# Stop any running Java processes (Windows agents)
function Stop-JavaProcesses {
    Write-Info "Checking for running Java processes..."
    
    try {
        $javaProcesses = Get-Process java -ErrorAction SilentlyContinue
        if ($javaProcesses) {
            Write-Info "Stopping $($javaProcesses.Count) Java process(es)..."
            $javaProcesses | Stop-Process -Force
            Write-Success "Java processes stopped successfully!"
        }
        else {
            Write-Info "No Java processes found running."
        }
    }
    catch {
        Write-Warning "Could not stop Java processes: $($_.Exception.Message)"
    }
}

# Display final status
function Show-Status {
    Write-Info "Final status check..."
    
    # Check if any containers are still running
    $runningContainers = docker ps --filter "name=nomad-consul" --format "{{.Names}}"
    $containerCount = if ($runningContainers) { ($runningContainers -split "`n").Count } else { 0 }
    
    if ($containerCount -eq 0) {
        Write-Success "All Jenkins containers stopped successfully!"
    }
    else {
        Write-Warning "Some containers may still be running:"
        docker ps --filter "name=nomad-consul"
    }
    
    Write-Host ""
    Write-Host "🛑 Jenkins Environment Stopped" -ForegroundColor $Colors.White
    Write-Host "==============================" -ForegroundColor $Colors.White
    Write-Host ""
    Write-Host "📊 Status:" -ForegroundColor $Colors.White
    try {
        docker ps -a --filter "name=nomad-consul"
    }
    catch {
        Write-Host "No Jenkins containers found" -ForegroundColor $Colors.White
    }
    Write-Host ""
    Write-Host "📝 To start again:" -ForegroundColor $Colors.White
    Write-Host "  .\bootstrap.ps1" -ForegroundColor $Colors.White
    Write-Host ""
}

# Main execution
function Main {
    Write-Host "🛑 Stopping Nomad + Consul Jenkins Environment (Windows)" -ForegroundColor $Colors.Red
    Write-Host "=======================================================" -ForegroundColor $Colors.Red
    Write-Host ""
    
    Stop-JenkinsEnvironment
    Stop-JavaProcesses
    Show-Status
    
    Write-Host ""
    Write-Success "Stop completed successfully! 🎉"
}

# Run main function
Main
