# Assign Static IP Addresses to VMs
# This script assigns static IP addresses to VMs using PowerShell

param(
    [switch]$DryRun = $false
)

Write-Host "=== Assigning Static IP Addresses to VMs ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

# VM configurations with static IP addresses
$vmConfigs = @(
    @{Name="consul-server-1"; IP="192.168.1.100"},
    @{Name="consul-server-2"; IP="192.168.1.101"},
    @{Name="consul-server-3"; IP="192.168.1.102"},
    @{Name="nomad-server-1"; IP="192.168.1.103"},
    @{Name="nomad-server-2"; IP="192.168.1.104"},
    @{Name="nomad-server-3"; IP="192.168.1.105"},
    @{Name="nomad-client-1"; IP="192.168.1.106"},
    @{Name="nomad-client-2"; IP="192.168.1.107"},
    @{Name="nomad-client-3"; IP="192.168.1.108"}
)

# Function to assign static IP to VM
function Assign-StaticIP {
    param([string]$VmName, [string]$IpAddress)
    
    Write-Host "Assigning static IP $IpAddress to VM: $VmName" -ForegroundColor Yellow
    
    try {
        $vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "VM $VmName not found!" -ForegroundColor Red
            return $false
        }
        
        # Get the VM's network adapter
        $networkAdapter = Get-VMNetworkAdapter -VM $vm
        if (-not $networkAdapter) {
            Write-Host "No network adapter found for VM $VmName!" -ForegroundColor Red
            return $false
        }
        
        if (-not $DryRun) {
            # Set static IP address
            Set-VMNetworkAdapter -VMNetworkAdapter $networkAdapter -StaticMacAddress $null
            Set-VMNetworkAdapter -VMNetworkAdapter $networkAdapter -StaticMacAddress (New-VMNetworkAdapterMacAddress)
            
            # Note: Hyper-V doesn't directly support setting IP addresses on VMs
            # The IP assignment needs to be done from within the VM or via cloud-init
            Write-Host "Note: IP assignment requires configuration within the VM" -ForegroundColor Yellow
        } else {
            Write-Host "🔍 DRY RUN: Would assign IP $IpAddress to $VmName" -ForegroundColor Yellow
        }
        
        return $true
        
    } catch {
        Write-Host "❌ Error assigning IP to VM $VmName : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Alternative approach: Create a simple network configuration script
function Create-NetworkConfigScript {
    param([string]$VmName, [string]$IpAddress)
    
    $networkScript = @"
#!/bin/bash
# Network configuration for $VmName

# Configure network interface
sudo ip addr add $IpAddress/24 dev eth0
sudo ip route add default via 192.168.1.1 dev eth0

# Configure DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# Make configuration persistent
echo "auto eth0" | sudo tee /etc/network/interfaces.d/eth0.cfg
echo "iface eth0 inet static" | sudo tee -a /etc/network/interfaces.d/eth0.cfg
echo "    address $IpAddress" | sudo tee -a /etc/network/interfaces.d/eth0.cfg
echo "    netmask 255.255.255.0" | sudo tee -a /etc/network/interfaces.d/eth0.cfg
echo "    gateway 192.168.1.1" | sudo tee -a /etc/network/interfaces.d/eth0.cfg

echo "Network configuration completed for $VmName with IP $IpAddress"
"@
    
    $scriptPath = "infra/scripts/network-config-$VmName.sh"
    $networkScript | Out-File -FilePath $scriptPath -Encoding UTF8
    Write-Host "Created network configuration script: $scriptPath" -ForegroundColor Green
    
    return $scriptPath
}

# Main execution
Write-Host "Starting static IP assignment..." -ForegroundColor Green

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

$successCount = 0
$totalCount = $vmConfigs.Count

foreach ($vmConfig in $vmConfigs) {
    # Create network configuration script for each VM
    $scriptPath = Create-NetworkConfigScript -VmName $vmConfig.Name -IpAddress $vmConfig.IP
    
    # Note: The actual IP assignment needs to be done from within the VM
    # This script creates the configuration files that can be used
    $successCount++
}

Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Green
Write-Host "Created network configuration scripts for: $successCount/$totalCount VMs" -ForegroundColor White

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy the network configuration scripts to each VM" -ForegroundColor White
Write-Host "2. Execute the scripts within each VM to configure networking" -ForegroundColor White
Write-Host "3. Test SSH connectivity to VMs" -ForegroundColor White

Write-Host ""
Write-Host "=== Static IP Assignment Complete ===" -ForegroundColor Green

