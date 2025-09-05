# Fix NAT Switch Configuration for Hyper-V VMs
# This script configures the NAT switch to provide proper IP addresses to VMs

param(
    [string]$NatName = "NAT-Switch",
    [string]$NatSubnet = "192.168.1.0/24",
    [string]$NatGateway = "192.168.1.1",
    [switch]$DryRun = $false
)

Write-Host "=== Fixing NAT Switch Configuration ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Function to configure NAT switch
function Fix-NATConfiguration {
    param([string]$SwitchName, [string]$Subnet, [string]$Gateway)
    
    Write-Host "Configuring NAT switch: $SwitchName" -ForegroundColor Yellow
    
    try {
        # Check if NAT switch exists
        $switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
        if (-not $switch) {
            Write-Host "❌ NAT switch '$SwitchName' not found!" -ForegroundColor Red
            return $false
        }
        
        Write-Host "✅ Found NAT switch: $SwitchName" -ForegroundColor Green
        
        # Get the virtual adapter for the NAT switch
        $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
        if (-not $adapter) {
            Write-Host "❌ Virtual adapter for NAT switch not found!" -ForegroundColor Red
            return $false
        }
        
        Write-Host "✅ Found virtual adapter: $($adapter.Name)" -ForegroundColor Green
        
        # Remove existing NAT configuration if it exists
        $existingNat = Get-NetNat -Name $SwitchName -ErrorAction SilentlyContinue
        if ($existingNat) {
            Write-Host "Removing existing NAT configuration..." -ForegroundColor Yellow
            if (-not $DryRun) {
                Remove-NetNat -Name $SwitchName -Confirm:$false
            }
        }
        
        # Configure the virtual adapter with static IP
        Write-Host "Configuring virtual adapter with IP: $Gateway" -ForegroundColor Yellow
        if (-not $DryRun) {
            # Remove existing IP addresses
            $adapter | Get-NetIPAddress | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
            
            # Add new IP address
            New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $Gateway -PrefixLength 24 -ErrorAction SilentlyContinue
        }
        
        # Create NAT configuration
        Write-Host "Creating NAT configuration for subnet: $Subnet" -ForegroundColor Yellow
        if (-not $DryRun) {
            New-NetNat -Name $SwitchName -InternalIPInterfaceAddressPrefix $Subnet
        }
        
        Write-Host "✅ NAT configuration completed successfully!" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "❌ Error configuring NAT: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to restart VMs to get new IP addresses
function Restart-VMsForNewIPs {
    Write-Host "Restarting VMs to get new IP addresses..." -ForegroundColor Yellow
    
    $vmNames = @(
        "consul-server-1", "consul-server-2", "consul-server-3",
        "nomad-server-1", "nomad-server-2", "nomad-server-3",
        "nomad-client-1", "nomad-client-2", "nomad-client-3"
    )
    
    foreach ($vmName in $vmNames) {
        try {
            $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
            if ($vm) {
                Write-Host "Restarting VM: $vmName" -ForegroundColor Cyan
                if (-not $DryRun) {
                    Restart-VM -Name $vmName -Force
                }
            } else {
                Write-Host "VM not found: $vmName" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error restarting VM $vmName : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Main execution
Write-Host "Starting NAT configuration fix..." -ForegroundColor Green

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Fix NAT configuration
$success = Fix-NATConfiguration -SwitchName $NatName -Subnet $NatSubnet -Gateway $NatGateway

if ($success) {
    Write-Host ""
    Write-Host "✅ NAT configuration fixed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Restart VMs to get new IP addresses" -ForegroundColor White
    Write-Host "2. Wait for VMs to boot and get IP addresses" -ForegroundColor White
    Write-Host "3. Test SSH connectivity to VMs" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to restart VMs
    $restart = Read-Host "Do you want to restart VMs now? (y/N)"
    if ($restart -eq 'y' -or $restart -eq 'Y') {
        Restart-VMsForNewIPs
    }
} else {
    Write-Host ""
    Write-Host "❌ Failed to fix NAT configuration!" -ForegroundColor Red
    Write-Host "Please check the error messages above and try again." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== NAT Configuration Fix Complete ===" -ForegroundColor Green

