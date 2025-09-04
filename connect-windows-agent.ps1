# Windows Jenkins Agent Connection Script
# This script will connect the Windows agent to Jenkins

Write-Host "=== Windows Jenkins Agent Connection ===" -ForegroundColor Green
Write-Host ""

# Jenkins configuration
$jenkinsUrl = "http://localhost:8080"
$agentName = "windows-hyperv-agent"
$agentSecret = "935a3519d2f1a2107479242f08ba6bea471f11e631030ef5620e2b29e5236819"
$agentWorkDir = "C:\Jenkins\workspace"

# Create agent directory if it doesn't exist
if (!(Test-Path $agentWorkDir)) {
    New-Item -ItemType Directory -Path $agentWorkDir -Force
    Write-Host "✅ Created agent workspace directory: $agentWorkDir" -ForegroundColor Green
}

# Download agent.jar if it doesn't exist
$agentJarPath = "$agentWorkDir\agent.jar"
if (!(Test-Path $agentJarPath)) {
    Write-Host "Downloading Jenkins agent JAR..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "$jenkinsUrl/jnlpJars/agent.jar" -OutFile $agentJarPath -UseBasicParsing
        Write-Host "✅ Jenkins agent JAR downloaded" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download agent JAR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Jenkins agent JAR already exists" -ForegroundColor Green
}

# Check if Java is available
$javaPath = "C:\Program Files\Java\jdk-17\bin\java.exe"
if (!(Test-Path $javaPath)) {
    Write-Host "❌ Java not found at: $javaPath" -ForegroundColor Red
    Write-Host "Please install Java JDK 17 or update the path in this script" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Java found at: $javaPath" -ForegroundColor Green

# Stop any existing agent processes
Write-Host "Stopping any existing Jenkins agent processes..." -ForegroundColor Yellow
Get-Process java -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like "*agent.jar*"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Connect to Jenkins
Write-Host "Connecting Windows agent to Jenkins..." -ForegroundColor Yellow
Write-Host "Jenkins URL: $jenkinsUrl" -ForegroundColor Cyan
Write-Host "Agent Name: $agentName" -ForegroundColor Cyan
Write-Host "Work Directory: $agentWorkDir" -ForegroundColor Cyan
Write-Host ""

try {
    $process = Start-Process -FilePath $javaPath -ArgumentList @(
        "-jar", $agentJarPath,
        "-url", $jenkinsUrl,
        "-secret", $agentSecret,
        "-name", $agentName,
        "-webSocket",
        "-workDir", $agentWorkDir
    ) -PassThru -NoNewWindow

    Write-Host "✅ Jenkins agent started successfully!" -ForegroundColor Green
    Write-Host "Process ID: $($process.Id)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The agent is now connecting to Jenkins..." -ForegroundColor Yellow
    Write-Host "You can check the agent status in Jenkins at: $jenkinsUrl/computer/$agentName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To stop the agent, press Ctrl+C or close this window" -ForegroundColor Yellow
    
    # Wait for the process
    $process.WaitForExit()
    
} catch {
    Write-Host "❌ Failed to start Jenkins agent: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
