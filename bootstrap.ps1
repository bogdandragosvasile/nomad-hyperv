# Nomad + Consul Jenkins Environment Bootstrap Script for Windows
# This script automates the complete setup of the Jenkins environment on Windows

param(
    [switch]$SkipPrerequisites,
    [switch]$SkipSSH,
    [switch]$Verbose
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

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator. Please run PowerShell as Administrator."
        exit 1
    }
    
    # Check Docker
    try {
        $dockerVersion = docker --version 2>$null
        if (-not $dockerVersion) {
            throw "Docker not found"
        }
        Write-Info "Docker found: $dockerVersion"
    }
    catch {
        Write-Error "Docker is not installed or not in PATH. Please install Docker Desktop first."
        exit 1
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        if (-not $composeVersion) {
            throw "Docker Compose not found"
        }
        Write-Info "Docker Compose found: $composeVersion"
    }
    catch {
        Write-Error "Docker Compose is not installed or not in PATH. Please install Docker Compose first."
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker info | Out-Null
        Write-Info "Docker is running"
    }
    catch {
        Write-Error "Docker is not running. Please start Docker Desktop first."
        exit 1
    }
    
    # Check Java (for Windows agent)
    try {
        $javaVersion = java -version 2>&1 | Select-String "version"
        if (-not $javaVersion) {
            throw "Java not found"
        }
        Write-Info "Java found: $javaVersion"
    }
    catch {
        Write-Warning "Java not found in PATH. Windows agent may not work properly."
        Write-Info "You can install Java manually or use the install-java.ps1 script in ci/windows-agent-setup/"
    }
    
    Write-Success "Prerequisites check completed!"
}

# Create necessary directories
function New-RequiredDirectories {
    Write-Info "Creating necessary directories..."
    
    $directories = @(
        "ci\jenkins-bootstrap\nginx\conf.d",
        "ci\jenkins-bootstrap\nginx\ssl",
        "$env:USERPROFILE\.ssh",
        "logs"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "Created directory: $dir"
        }
    }
    
    Write-Success "Directories created!"
}

# Setup SSH keys
function New-SSHKeys {
    Write-Info "Setting up SSH keys..."
    
    $sshDir = "$env:USERPROFILE\.ssh"
    $privateKey = "$sshDir\id_rsa"
    $publicKey = "$sshDir\id_rsa.pub"
    
    if (-not (Test-Path $privateKey)) {
        Write-Info "Generating SSH key pair..."
        
        # Generate SSH key using ssh-keygen
        $sshKeygenPath = Get-Command ssh-keygen -ErrorAction SilentlyContinue
        if ($sshKeygenPath) {
            & ssh-keygen -t rsa -b 4096 -f $privateKey -N '""' -C "jenkins-agent@nomad-consul"
            Write-Success "SSH key pair generated!"
        }
        else {
            Write-Warning "ssh-keygen not found. Please install OpenSSH or Git for Windows."
            Write-Info "You can generate SSH keys manually or use PuTTYgen."
        }
    }
    else {
        Write-Info "SSH key pair already exists, skipping generation."
    }
    
    # Display public key if it exists
    if (Test-Path $publicKey) {
        Write-Info "SSH Public Key (add this to your VMs for Ansible access):"
        Write-Host "----------------------------------------" -ForegroundColor $Colors.White
        Get-Content $publicKey
        Write-Host "----------------------------------------" -ForegroundColor $Colors.White
    }
}

# Create nginx configuration
function New-NginxConfig {
    Write-Info "Creating nginx configuration..."
    
    $nginxConf = @"
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    include /etc/nginx/conf.d/*.conf;
}
"@

    $jenkinsConf = @"
upstream jenkins {
    server jenkins:8080;
}

server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://jenkins;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
"@

    $nginxConf | Out-File -FilePath "ci\jenkins-bootstrap\nginx\nginx.conf" -Encoding UTF8
    $jenkinsConf | Out-File -FilePath "ci\jenkins-bootstrap\nginx\conf.d\jenkins.conf" -Encoding UTF8
    
    Write-Success "Nginx configuration created!"
}

# Start Jenkins environment
function Start-JenkinsEnvironment {
    Write-Info "Starting Jenkins environment..."
    
    Push-Location "ci\jenkins-bootstrap"
    
    try {
        # Start Jenkins master
        Write-Info "Starting Jenkins master..."
        docker-compose up -d jenkins
        
        # Wait for Jenkins to be ready
        Write-Info "Waiting for Jenkins to be ready..."
        $timeout = 300
        $counter = 0
        $jenkinsReady = $false
        
        while (-not $jenkinsReady -and $counter -lt $timeout) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8080/login" -UseBasicParsing -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    $jenkinsReady = $true
                }
            }
            catch {
                # Jenkins not ready yet
            }
            
            if (-not $jenkinsReady) {
                Start-Sleep -Seconds 5
                $counter += 5
                Write-Info "Waiting for Jenkins... ($counter/$timeout seconds)"
            }
        }
        
        if (-not $jenkinsReady) {
            Write-Error "Jenkins failed to start within $timeout seconds"
            exit 1
        }
        
        Write-Success "Jenkins is ready!"
        
        # Start agent
        Write-Info "Starting Jenkins agent..."
        docker-compose --profile agent up -d jenkins-agent
        
        # Wait for agent to connect
        Write-Info "Waiting for agent to connect..."
        Start-Sleep -Seconds 10
        
        # Check agent status
        try {
            $agentStatus = Invoke-RestMethod -Uri "http://localhost:8080/computer/nomad-consul-agent/api/json" -UseBasicParsing
            if ($agentStatus.offline -eq $false) {
                Write-Success "Jenkins agent connected successfully!"
            }
            else {
                Write-Warning "Agent is offline. Check Jenkins UI for details."
            }
        }
        catch {
            Write-Warning "Could not check agent status. Check Jenkins UI manually."
        }
    }
    finally {
        Pop-Location
    }
}

# Display status and access information
function Show-Status {
    Write-Success "Jenkins environment is ready!"
    Write-Host ""
    Write-Host "🌐 Access URLs:" -ForegroundColor $Colors.White
    Write-Host "  Jenkins UI: http://localhost:8080" -ForegroundColor $Colors.White
    Write-Host "  Jenkins via Nginx: http://localhost (if reverse proxy is enabled)" -ForegroundColor $Colors.White
    Write-Host ""
    Write-Host "🔑 Default Credentials:" -ForegroundColor $Colors.White
    Write-Host "  Username: admin" -ForegroundColor $Colors.White
    Write-Host "  Password: admin" -ForegroundColor $Colors.White
    Write-Host ""
    Write-Host "📊 Status:" -ForegroundColor $Colors.White
    docker-compose -f ci\jenkins-bootstrap\docker-compose.yml ps
    Write-Host ""
    Write-Host "📝 Useful Commands:" -ForegroundColor $Colors.White
    Write-Host "  Stop: .\stop.ps1" -ForegroundColor $Colors.White
    Write-Host "  Restart: .\restart.ps1" -ForegroundColor $Colors.White
    Write-Host "  Logs: docker-compose -f ci\jenkins-bootstrap\docker-compose.yml logs -f" -ForegroundColor $Colors.White
    Write-Host "  Agent Logs: docker-compose -f ci\jenkins-bootstrap\docker-compose.yml logs -f jenkins-agent" -ForegroundColor $Colors.White
}

# Main execution
function Main {
    Write-Host "🚀 Nomad + Consul Jenkins Environment Bootstrap (Windows)" -ForegroundColor $Colors.Green
    Write-Host "=========================================================" -ForegroundColor $Colors.Green
    Write-Host ""
    
    if (-not $SkipPrerequisites) {
        Test-Prerequisites
    }
    
    New-RequiredDirectories
    
    if (-not $SkipSSH) {
        New-SSHKeys
    }
    
    New-NginxConfig
    Start-JenkinsEnvironment
    Show-Status
    
    Write-Host ""
    Write-Success "Bootstrap completed successfully! 🎉"
}

# Run main function
Main
