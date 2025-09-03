# Install Windows Jenkins Agent as a Service
# Run this script as Administrator

param(
    [string]$JenkinsUrl = "http://localhost:8080",
    [string]$AgentName = "windows-hyperv-agent",
    [string]$AgentSecret = "",
    [string]$WorkDir = "C:\Jenkins\workspace",
    [string]$ServiceName = "JenkinsAgent"
)

Write-Host "Installing Windows Jenkins Agent as a Service..." -ForegroundColor Green

# Check if Java is available
if (!(Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Error "Java is not installed or not in PATH. Please run install-java.ps1 first."
    exit 1
}

# Check if agent.jar exists, download if not
$agentJar = "C:\Jenkins\agent.jar"
if (!(Test-Path $agentJar)) {
    Write-Host "Downloading agent.jar..." -ForegroundColor Cyan
    if (!(Test-Path "C:\Jenkins")) {
        New-Item -ItemType Directory -Path "C:\Jenkins" -Force
    }
    Invoke-WebRequest -Uri "$JenkinsUrl/jnlpJars/agent.jar" -OutFile $agentJar
}

# Create work directory
if (!(Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force
}

# If no secret provided, get it from Jenkins
if ([string]::IsNullOrEmpty($AgentSecret)) {
    Write-Host "No agent secret provided. Please get it from Jenkins UI:" -ForegroundColor Yellow
    Write-Host "1. Go to $JenkinsUrl/computer/new" -ForegroundColor Yellow
    Write-Host "2. Choose 'Permanent Agent'" -ForegroundColor Yellow
    Write-Host "3. Set Name: $AgentName" -ForegroundColor Yellow
    Write-Host "4. Set Labels: windows-hyperv-agent" -ForegroundColor Yellow
    Write-Host "5. Copy the secret from the agent setup page" -ForegroundColor Yellow
    Write-Host "6. Run this script again with: -AgentSecret YOUR_SECRET" -ForegroundColor Yellow
    exit 1
}

# Check if NSSM is available (Non-Sucking Service Manager)
$nssmPath = "C:\nssm\nssm.exe"
if (!(Test-Path $nssmPath)) {
    Write-Host "Downloading NSSM..." -ForegroundColor Cyan
    if (!(Test-Path "C:\nssm")) {
        New-Item -ItemType Directory -Path "C:\nssm" -Force
    }
    
    # Download NSSM
    $nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
    $nssmZip = "$env:TEMP\nssm.zip"
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip
    
    # Extract NSSM
    Expand-Archive -Path $nssmZip -DestinationPath "C:\nssm" -Force
    Remove-Item $nssmZip -Force
}

# Remove existing service if it exists
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Removing existing service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    & $nssmPath remove $ServiceName confirm
}

# Create the service
Write-Host "Creating service..." -ForegroundColor Cyan
& $nssmPath install $ServiceName "C:\Program Files\Java\jdk-17\bin\java.exe"
& $nssmPath set $ServiceName AppParameters "-jar $agentJar -url $JenkinsUrl -secret $AgentSecret -name $AgentName -workDir $WorkDir"
& $nssmPath set $ServiceName AppDirectory "C:\Jenkins"
& $nssmPath set $ServiceName Description "Jenkins Windows Agent for Hyper-V deployment"
& $nssmPath set $ServiceName Start SERVICE_AUTO_START

# Set service to run as Local System
& $nssmPath set $ServiceName ObjectName LocalSystem

Write-Host "Service installed successfully!" -ForegroundColor Green
Write-Host "Service Name: $ServiceName" -ForegroundColor Cyan
Write-Host "To start the service: Start-Service -Name '$ServiceName'" -ForegroundColor Yellow
Write-Host "To stop the service: Stop-Service -Name '$ServiceName'" -ForegroundColor Yellow
Write-Host "To remove the service: & '$nssmPath' remove '$ServiceName' confirm" -ForegroundColor Yellow
