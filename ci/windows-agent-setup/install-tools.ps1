# Install Required Tools for Jenkins Windows Agent
# Run this script as Administrator

Write-Host "Installing required tools for Jenkins Windows Agent..." -ForegroundColor Green

# Check if Chocolatey is installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey package manager..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}

# Install required tools
Write-Host "Installing Terraform..." -ForegroundColor Cyan
choco install terraform -y

Write-Host "Installing Git..." -ForegroundColor Cyan
choco install git -y

Write-Host "Installing Python..." -ForegroundColor Cyan
choco install python -y

Write-Host "Installing Ansible..." -ForegroundColor Cyan
pip install ansible

Write-Host "Installing Nomad CLI..." -ForegroundColor Cyan
choco install nomad -y

Write-Host "Installing Consul CLI..." -ForegroundColor Cyan
choco install consul -y

Write-Host "Installing kubectl..." -ForegroundColor Cyan
choco install kubernetes-cli -y

# Refresh environment
refreshenv

Write-Host "Tool installation completed!" -ForegroundColor Green
Write-Host "Please restart your terminal for PATH changes to take effect." -ForegroundColor Yellow

# Verify installations
Write-Host "`nVerifying installations..." -ForegroundColor Cyan
Write-Host "Terraform: $(terraform version)" -ForegroundColor Green
Write-Host "Ansible: $(ansible --version | Select-Object -First 1)" -ForegroundColor Green
Write-Host "Nomad: $(nomad version)" -ForegroundColor Green
Write-Host "Consul: $(consul version)" -ForegroundColor Green
Write-Host "kubectl: $(kubectl version --client)" -ForegroundColor Green
