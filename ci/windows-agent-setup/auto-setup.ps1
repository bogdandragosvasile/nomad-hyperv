# Windows Jenkins Agent Auto-Setup Script
# This script automatically sets up the Windows Jenkins agent

param(
    [switch]$InstallJava,
    [switch]$InstallTools,
    [switch]$StartAgent,
    [switch]$InstallService,
    [switch]$All
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

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install Java
function Install-Java {
    Write-Info "Installing Java..."
    
    if (Test-Path "install-java.ps1") {
        & .\install-java.ps1
        Write-Success "Java installation completed!"
    }
    else {
        Write-Error "install-java.ps1 not found in current directory"
    }
}

# Install tools
function Install-Tools {
    Write-Info "Installing tools..."
    
    if (Test-Path "install-tools.ps1") {
        & .\install-tools.ps1
        Write-Success "Tools installation completed!"
    }
    else {
        Write-Error "install-tools.ps1 not found in current directory"
    }
}

# Start agent
function Start-Agent {
    Write-Info "Starting Windows Jenkins agent..."
    
    if (Test-Path "start-windows-agent.ps1") {
        & .\start-windows-agent.ps1
        Write-Success "Windows agent started!"
    }
    else {
        Write-Error "start-windows-agent.ps1 not found in current directory"
    }
}

# Install as service
function Install-Service {
    Write-Info "Installing Windows agent as service..."
    
    if (Test-Path "install-windows-service.ps1") {
        & .\install-windows-service.ps1
        Write-Success "Windows agent service installed!"
    }
    else {
        Write-Error "install-windows-service.ps1 not found in current directory"
    }
}

# Main execution
function Main {
    Write-Host "🚀 Windows Jenkins Agent Auto-Setup" -ForegroundColor $Colors.Green
    Write-Host "===================================" -ForegroundColor $Colors.Green
    Write-Host ""
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator. Please run PowerShell as Administrator."
        exit 1
    }
    
    # Determine what to do based on parameters
    if ($All) {
        $InstallJava = $true
        $InstallTools = $true
        $StartAgent = $true
        $InstallService = $true
    }
    
    # If no parameters specified, show help
    if (-not ($InstallJava -or $InstallTools -or $StartAgent -or $InstallService)) {
        Write-Host "Usage: .\auto-setup.ps1 [options]" -ForegroundColor $Colors.White
        Write-Host ""
        Write-Host "Options:" -ForegroundColor $Colors.White
        Write-Host "  -InstallJava     Install Java" -ForegroundColor $Colors.White
        Write-Host "  -InstallTools    Install required tools (Terraform, Ansible, etc.)" -ForegroundColor $Colors.White
        Write-Host "  -StartAgent      Start the Windows Jenkins agent" -ForegroundColor $Colors.White
        Write-Host "  -InstallService  Install the Windows agent as a service" -ForegroundColor $Colors.White
        Write-Host "  -All             Do everything" -ForegroundColor $Colors.White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor $Colors.White
        Write-Host "  .\auto-setup.ps1 -All" -ForegroundColor $Colors.White
        Write-Host "  .\auto-setup.ps1 -InstallJava -InstallTools" -ForegroundColor $Colors.White
        exit 0
    }
    
    # Execute requested actions
    if ($InstallJava) {
        Install-Java
        Write-Host ""
    }
    
    if ($InstallTools) {
        Install-Tools
        Write-Host ""
    }
    
    if ($StartAgent) {
        Start-Agent
        Write-Host ""
    }
    
    if ($InstallService) {
        Install-Service
        Write-Host ""
    }
    
    Write-Success "Windows Jenkins agent setup completed! 🎉"
}

# Run main function
Main
