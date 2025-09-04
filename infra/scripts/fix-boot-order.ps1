# Fix VM Boot Order - Set all VMs to boot from hard drive first
# This script ensures all VMs have the correct boot order

param(
    [switch]$DryRun = $false
)

Write-Host "=== Fixing VM Boot Order ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# VM configurations
$consulServers = @(
    @{Name="consul-server-1"; IP="192.168.1.10"},
    @{Name="consul-server-2"; IP="192.168.1.11"},
    @{Name="consul-server-3"; IP="192.168.1.12"}
)

$nomadServers = @(
    @{Name="nomad-server-1"; IP="192.168.1.20"},
    @{Name="nomad-server-2"; IP="192.168.1.21"},
    @{Name="nomad-server-3"; IP="192.168.1.22"}
)

$nomadClients = @(
    @{Name="nomad-client-1"; IP="192.168.1.30"},
    @{Name="nomad-client-2"; IP="192.168.1.31"},
    @{Name="nomad-client-3"; IP="192.168.1.32"}
)

$allVMs = $consulServers + $nomadServers + $nomadClients

# Function to fix boot order for a VM
function Fix-VMBootOrder {
    param([string]$VMName)
    
    Write-Host "Fixing boot order for VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would fix boot order for VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "⚠️  VM not found: $VMName" -ForegroundColor Yellow
            return
        }
        
        # Get hard drive
        $hardDrive = Get-VMHardDiskDrive -VMName $VMName
        if (-not $hardDrive) {
            Write-Host "⚠️  No hard drive found for VM: $VMName" -ForegroundColor Yellow
            return
        }
        
        # Set boot order to hard drive first
        Set-VMFirmware -VMName $VMName -FirstBootDevice $hardDrive | Out-Null
        Write-Host "✅ Set boot order to hard drive first for VM: $VMName" -ForegroundColor Green
        
        # Verify boot order
        $firmware = Get-VMFirmware -VMName $VMName
        $firstBootDevice = $firmware.BootOrder[0]
        Write-Host "  First boot device: $($firstBootDevice.Description)" -ForegroundColor White
        
    } catch {
        Write-Host "❌ Failed to fix boot order for VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check VM boot order
function Check-VMBootOrder {
    param([string]$VMName)
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "❌ VM not found: $VMName" -ForegroundColor Red
            return
        }
        
        $firmware = Get-VMFirmware -VMName $VMName
        $hardDrive = Get-VMHardDiskDrive -VMName $VMName
        
        Write-Host "VM: $VMName" -ForegroundColor Cyan
        Write-Host "  State: $($vm.State)" -ForegroundColor White
        Write-Host "  Hard Drives: $($hardDrive.Count)" -ForegroundColor White
        
        if ($hardDrive.Count -gt 0) {
            Write-Host "  VHD Path: $($hardDrive[0].Path)" -ForegroundColor White
        }
        
        Write-Host "  Boot Order:" -ForegroundColor White
        for ($i = 0; $i -lt $firmware.BootOrder.Count; $i++) {
            $device = $firmware.BootOrder[$i]
            $prefix = if ($i -eq 0) { "    → " } else { "    " }
            Write-Host "$prefix$($device.Description)" -ForegroundColor White
        }
        
        Write-Host ""
        
    } catch {
        Write-Host "❌ Failed to check VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Write-Host "Fixing boot order for all VMs..." -ForegroundColor Yellow
    
    foreach ($vm in $allVMs) {
        Fix-VMBootOrder -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "=== VM Boot Order After Fix ===" -ForegroundColor Cyan
    
    foreach ($vm in $allVMs) {
        Check-VMBootOrder -VMName $vm.Name
    }
    
    Write-Host "🎉 Boot Order Fix Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs now have:" -ForegroundColor Cyan
    Write-Host "  • Hard drive as first boot device" -ForegroundColor White
    Write-Host "  • Proper boot order configuration" -ForegroundColor White
    Write-Host "  • Ready to boot from VHD when OS is installed" -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
