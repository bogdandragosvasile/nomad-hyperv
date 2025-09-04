# Attach Ubuntu ISO to VMs and restart them
# This script attaches the Ubuntu ISO to existing VMs and restarts them for installation

param(
    [string]$IsoPath = "C:\Hyper-V\ISOs\ubuntu-22.04.3-server-amd64.iso",
    [switch]$DryRun = $false
)

Write-Host "=== Attaching Ubuntu ISO to VMs and Restarting ===" -ForegroundColor Green
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

# Check if ISO exists
if (-not (Test-Path $IsoPath)) {
    Write-Host "❌ Ubuntu ISO not found at: $IsoPath" -ForegroundColor Red
    Write-Host "Please download the Ubuntu ISO first." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Ubuntu ISO found at: $IsoPath" -ForegroundColor Green

# Function to attach ISO and restart VM
function Attach-ISOAndRestart {
    param([string]$VMName)
    
    Write-Host "Processing VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would attach ISO and restart VM $VMName" -ForegroundColor Cyan
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
            Stop-VM -Name $VMName -Force
            Write-Host "✅ Stopped VM: $VMName" -ForegroundColor Green
            Start-Sleep -Seconds 5
        }
        
        # Remove existing DVD drives
        $dvdDrives = Get-VMDvdDrive -VMName $VMName
        foreach ($dvd in $dvdDrives) {
            Remove-VMDvdDrive -VMName $VMName -ControllerNumber $dvd.ControllerNumber -ControllerLocation $dvd.ControllerLocation
        }
        
        # Add new DVD drive with ISO
        Add-VMDvdDrive -VMName $VMName -Path $IsoPath
        Write-Host "✅ Attached Ubuntu ISO to VM: $VMName" -ForegroundColor Green
        
        # Set boot order to boot from DVD first
        Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMDvdDrive -VMName $VMName)
        Write-Host "✅ Set boot order for VM: $VMName" -ForegroundColor Green
        
        # Start VM
        Start-VM -Name $VMName
        Write-Host "✅ Started VM: $VMName" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to process VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Write-Host "Attaching Ubuntu ISO to all VMs and restarting them..." -ForegroundColor Yellow
    
    foreach ($vm in $allVMs) {
        Attach-ISOAndRestart -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "🎉 VM ISO Attachment and Restart Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs have been:" -ForegroundColor Cyan
    Write-Host "  • Stopped (if running)" -ForegroundColor White
    Write-Host "  • Ubuntu ISO attached" -ForegroundColor White
    Write-Host "  • Boot order set to DVD first" -ForegroundColor White
    Write-Host "  • Restarted" -ForegroundColor White
    Write-Host ""
    Write-Host "The VMs should now boot from the Ubuntu ISO and start the installation process." -ForegroundColor Cyan
    Write-Host "You can monitor the installation through the Hyper-V Manager." -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
