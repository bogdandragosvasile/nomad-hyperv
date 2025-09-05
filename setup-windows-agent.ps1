# Windows Jenkins Agent Setup Script for Hyper-V Deployment
# This script will set up a Windows Jenkins agent with all required tools

Write-Host "=== Windows Jenkins Agent Setup for Hyper-V Deployment ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Check if Chocolatey is installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey package manager..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "✅ Chocolatey installed" -ForegroundColor Green
} else {
    Write-Host "✅ Chocolatey already installed" -ForegroundColor Green
}

# Install required tools
Write-Host "Installing required tools..." -ForegroundColor Yellow

$tools = @(
    "terraform",
    "ansible",
    "git",
    "docker-desktop",
    "7zip",
    "curl"
)

foreach ($tool in $tools) {
    Write-Host "Installing $tool..." -ForegroundColor Cyan
    choco install $tool -y --no-progress
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $tool installed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install $tool" -ForegroundColor Red
    }
}

# Install HashiCorp tools
Write-Host "Installing HashiCorp tools..." -ForegroundColor Yellow

$hashicorpTools = @(
    "consul",
    "nomad"
)

foreach ($tool in $hashicorpTools) {
    Write-Host "Installing $tool..." -ForegroundColor Cyan
    choco install $tool -y --no-progress
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $tool installed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install $tool" -ForegroundColor Red
    }
}

# Enable Hyper-V if not already enabled
Write-Host "Checking Hyper-V status..." -ForegroundColor Yellow
$hypervFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
if ($hypervFeature.State -ne "Enabled") {
    Write-Host "Enabling Hyper-V..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
    Write-Host "✅ Hyper-V enabled (restart required)" -ForegroundColor Green
} else {
    Write-Host "✅ Hyper-V already enabled" -ForegroundColor Green
}

# Check if Hyper-V service is running
Write-Host "Checking Hyper-V services..." -ForegroundColor Yellow
$hypervServices = @("vmms", "vds")
foreach ($service in $hypervServices) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "✅ $service service is running" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $service service is not running" -ForegroundColor Yellow
    }
}

# Create Hyper-V network switch if it doesn't exist
Write-Host "Checking Hyper-V network switch..." -ForegroundColor Yellow
$switchName = "External Switch"
$switch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
if (!$switch) {
    Write-Host "Creating Hyper-V network switch: $switchName" -ForegroundColor Yellow
    try {
        New-VMSwitch -Name $switchName -NetAdapterName (Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.Name -notlike "*Hyper-V*"} | Select-Object -First 1).Name -AllowManagementOS $true
        Write-Host "✅ Hyper-V network switch created" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create Hyper-V network switch: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You may need to create this manually in Hyper-V Manager" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Hyper-V network switch already exists" -ForegroundColor Green
}

# Create directory for VM images
Write-Host "Creating VM images directory..." -ForegroundColor Yellow
$vmImagesPath = "C:\Images"
if (!(Test-Path $vmImagesPath)) {
    New-Item -ItemType Directory -Path $vmImagesPath -Force
    Write-Host "✅ VM images directory created: $vmImagesPath" -ForegroundColor Green
} else {
    Write-Host "✅ VM images directory already exists: $vmImagesPath" -ForegroundColor Green
}

# Download Ubuntu 22.04 LTS ISO if not present
$ubuntuIsoPath = "$vmImagesPath\ubuntu-22.04-server-amd64.iso"
if (!(Test-Path $ubuntuIsoPath)) {
    Write-Host "Downloading Ubuntu 22.04 LTS ISO..." -ForegroundColor Yellow
    $ubuntuUrl = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-server-amd64.iso"
    try {
        Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuIsoPath -UseBasicParsing
        Write-Host "✅ Ubuntu ISO downloaded" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download Ubuntu ISO: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please download manually from: https://ubuntu.com/download/server" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ Ubuntu ISO already exists" -ForegroundColor Green
}

# Set up Jenkins agent directory
Write-Host "Setting up Jenkins agent directory..." -ForegroundColor Yellow
$jenkinsAgentPath = "C:\Jenkins\agent"
if (!(Test-Path $jenkinsAgentPath)) {
    New-Item -ItemType Directory -Path $jenkinsAgentPath -Force
    Write-Host "✅ Jenkins agent directory created: $jenkinsAgentPath" -ForegroundColor Green
} else {
    Write-Host "✅ Jenkins agent directory already exists: $jenkinsAgentPath" -ForegroundColor Green
}

# Refresh environment variables
Write-Host "Refreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host ""
Write-Host "🎉 Windows Jenkins Agent Setup Completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart your computer if Hyper-V was enabled" -ForegroundColor White
Write-Host "2. Connect the Windows agent to Jenkins" -ForegroundColor White
Write-Host "3. Run the pipeline with HYBRID_MODE=false" -ForegroundColor White
Write-Host ""
Write-Host "Tools installed:" -ForegroundColor Cyan
Write-Host "- Terraform: $(terraform --version 2>$null | Select-Object -First 1)" -ForegroundColor White
Write-Host "- Ansible: $(ansible --version 2>$null | Select-Object -First 1)" -ForegroundColor White
Write-Host "- Git: $(git --version 2>$null)" -ForegroundColor White
Write-Host "- Consul: $(consul version 2>$null | Select-Object -First 1)" -ForegroundColor White
Write-Host "- Nomad: $(nomad version 2>$null | Select-Object -First 1)" -ForegroundColor White

