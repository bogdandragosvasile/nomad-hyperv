# Restart Hyper-V VMs to apply storage configuration changes
# This script restarts all VMs to ensure they pick up the latest configuration

param(
    [switch]$DryRun = $false
)

Write-Host "=== Restarting Hyper-V VMs ===" -ForegroundColor Green
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

# Function to restart a VM
function Restart-VM {
    param([string]$VMName)
    
    Write-Host "Restarting VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would restart VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "⚠️  VM not found: $VMName" -ForegroundColor Yellow
            return
        }
        
        # Stop VM if running
        if ($vm.State -eq 'Running') {
            Stop-VM -Name $VMName -Force -Confirm:$false
            Write-Host "✅ Stopped VM: $VMName" -ForegroundColor Green
            Start-Sleep -Seconds 5
        }
        
        # Start VM
        Start-VM -Name $VMName
        Write-Host "✅ Started VM: $VMName" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to restart VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check VM status
function Check-VMStatus {
    param([string]$VMName)
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "❌ VM not found: $VMName" -ForegroundColor Red
            return
        }
        
        $drives = Get-VMHardDiskDrive -VMName $VMName
        $dvdDrives = Get-VMDvdDrive -VMName $VMName
        $firmware = Get-VMFirmware -VMName $VMName
        
        Write-Host "VM: $VMName" -ForegroundColor Cyan
        Write-Host "  State: $($vm.State)" -ForegroundColor White
        Write-Host "  Memory: $([math]::Round($vm.MemoryAssigned / 1GB, 2)) GB" -ForegroundColor White
        Write-Host "  CPU: $($vm.ProcessorCount)" -ForegroundColor White
        Write-Host "  Hard Drives: $($drives.Count)" -ForegroundColor White
        Write-Host "  DVD Drives: $($dvdDrives.Count)" -ForegroundColor White
        Write-Host "  Boot Order: $($firmware.BootOrder -join ', ')" -ForegroundColor White
        
        if ($drives.Count -gt 0) {
            Write-Host "  VHD Path: $($drives[0].Path)" -ForegroundColor White
        }
        
        if ($dvdDrives.Count -gt 0) {
            Write-Host "  ISO Path: $($dvdDrives[0].Path)" -ForegroundColor White
        }
        
        Write-Host ""
        
    } catch {
        Write-Host "❌ Failed to check VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Write-Host "Restarting all VMs..." -ForegroundColor Yellow
    
    foreach ($vm in $allVMs) {
        Restart-VM -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "Waiting for VMs to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host ""
    Write-Host "=== VM Status After Restart ===" -ForegroundColor Cyan
    
    foreach ($vm in $allVMs) {
        Check-VMStatus -VMName $vm.Name
    }
    
    Write-Host "🎉 VM Restart Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs have been restarted and should now:" -ForegroundColor Cyan
    Write-Host "  • Have proper storage configuration" -ForegroundColor White
    Write-Host "  • Boot from the correct device (hard drive or ISO)" -ForegroundColor White
    Write-Host "  • Be ready for OS installation if needed" -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
