# Connect Windows Jenkins Agent with Elevated Privileges
# This script runs the Jenkins agent with elevated privileges for Hyper-V access

Write-Host "=== Connecting Windows Jenkins Agent with Elevated Privileges ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Set working directory
$workDir = "C:\Jenkins\workspace"
if (-not (Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir -Force
    Write-Host "✅ Created workspace directory: $workDir" -ForegroundColor Green
}

# Download Jenkins agent JAR if not exists
$agentJar = "agent.jar"
if (-not (Test-Path $agentJar)) {
    Write-Host "Downloading Jenkins agent JAR..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "http://localhost:8080/jnlpJars/agent.jar" -OutFile $agentJar
        Write-Host "✅ Jenkins agent JAR downloaded" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download Jenkins agent JAR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Get the agent secret from Jenkins
Write-Host "Getting agent secret from Jenkins..." -ForegroundColor Yellow
try {
    $secret = Invoke-RestMethod -Uri "http://localhost:8080/computer/windows-hyperv-agent/slave-agent.jnlp" -UseBasicParsing | Select-String -Pattern 'secret="([^"]*)"' | ForEach-Object { $_.Matches[0].Groups[1].Value }
    if ($secret) {
        Write-Host "✅ Agent secret retrieved: $secret" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to retrieve agent secret" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Failed to get agent secret: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Connect the agent with elevated privileges
Write-Host "Connecting Jenkins agent with elevated privileges..." -ForegroundColor Yellow
Write-Host "Working directory: $workDir" -ForegroundColor Cyan
Write-Host "Agent secret: $secret" -ForegroundColor Cyan

try {
    # Run the agent with elevated privileges
    $process = Start-Process -FilePath "java" -ArgumentList @(
        "-jar", $agentJar,
        "-url", "http://localhost:8080/",
        "-secret", $secret,
        "-name", "windows-hyperv-agent",
        "-webSocket",
        "-workDir", $workDir
    ) -PassThru -WindowStyle Hidden
    
    Write-Host "✅ Jenkins agent started with PID: $($process.Id)" -ForegroundColor Green
    Write-Host "✅ Agent is running with elevated privileges" -ForegroundColor Green
    Write-Host ""
    Write-Host "The agent should now be able to access Hyper-V and WinRM with full privileges!" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Failed to start Jenkins agent: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Jenkins Agent with Elevated Privileges Started!" -ForegroundColor Green
Write-Host ""
Write-Host "The agent is now running with Administrator privileges and should be able to:" -ForegroundColor Cyan
Write-Host "  • Access Hyper-V management APIs" -ForegroundColor White
Write-Host "  • Authenticate with WinRM properly" -ForegroundColor White
Write-Host "  • Create and manage VMs" -ForegroundColor White
Write-Host ""
Write-Host "You can now run the real deployment pipeline!" -ForegroundColor Green

