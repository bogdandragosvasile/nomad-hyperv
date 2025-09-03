# Start Windows Jenkins Agent
# This script starts the Jenkins agent on Windows

param(
    [string]$JenkinsUrl = "http://localhost:8080",
    [string]$AgentName = "windows-hyperv-agent",
    [string]$AgentSecret = "",
    [string]$WorkDir = "C:\Jenkins\workspace"
)

Write-Host "Starting Windows Jenkins Agent..." -ForegroundColor Green
Write-Host "Jenkins URL: $JenkinsUrl" -ForegroundColor Cyan
Write-Host "Agent Name: $AgentName" -ForegroundColor Cyan
Write-Host "Work Directory: $WorkDir" -ForegroundColor Cyan

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

Write-Host "Starting agent with secret..." -ForegroundColor Green

# Start the agent
try {
    java -jar $agentJar -url $JenkinsUrl -secret $AgentSecret -name $AgentName -workDir $WorkDir
} catch {
    Write-Error "Failed to start agent: $_"
    exit 1
}
