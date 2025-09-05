# Simple NAT Configuration Fix
param(
    [string]$NatName = "NAT-Switch",
    [string]$NatSubnet = "192.168.1.0/24",
    [string]$NatGateway = "192.168.1.1"
)

Write-Host "=== Fixing NAT Configuration ===" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

try {
    # Get the virtual adapter for the NAT switch
    $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$NatName*" }
    if (-not $adapter) {
        Write-Host "Virtual adapter for NAT switch not found!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Found virtual adapter: $($adapter.Name)" -ForegroundColor Green
    
    # Remove existing NAT configuration if it exists
    $existingNat = Get-NetNat -Name $NatName -ErrorAction SilentlyContinue
    if ($existingNat) {
        Write-Host "Removing existing NAT configuration..." -ForegroundColor Yellow
        Remove-NetNat -Name $NatName -Confirm:$false
    }
    
    # Configure the virtual adapter with static IP
    Write-Host "Configuring virtual adapter with IP: $NatGateway" -ForegroundColor Yellow
    $adapter | Get-NetIPAddress | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $NatGateway -PrefixLength 24 -ErrorAction SilentlyContinue
    
    # Create NAT configuration
    Write-Host "Creating NAT configuration for subnet: $NatSubnet" -ForegroundColor Yellow
    New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $NatSubnet
    
    Write-Host "NAT configuration completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

