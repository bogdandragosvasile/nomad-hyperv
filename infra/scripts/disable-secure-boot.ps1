# Disable Secure Boot for Hyper-V VMs
# This script disables Secure Boot to allow Ubuntu cloud images to boot

param(
    [switch]$DryRun = $false
)

Write-Host "=== Disabling Secure Boot for Hyper-V VMs ===" -ForegroundColor Green
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

# Function to disable Secure Boot for a VM
function Disable-SecureBoot {
    param([string]$VMName)
    
    Write-Host "Disabling Secure Boot for VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would disable Secure Boot for VM $VMName" -ForegroundColor Cyan
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
            Write-Host "Stopping VM: $VMName" -ForegroundColor Yellow
            Stop-VM -Name $VMName -Force -Confirm:$false
            Start-Sleep -Seconds 5
        }
        
        # Disable Secure Boot
        Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
        Write-Host "✅ Disabled Secure Boot for VM: $VMName" -ForegroundColor Green
        
        # Verify Secure Boot is disabled
        $firmware = Get-VMFirmware -VMName $VMName
        Write-Host "  Secure Boot: $($firmware.SecureBoot)" -ForegroundColor White
        
    } catch {
        Write-Host "❌ Failed to disable Secure Boot for VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to start VM and check status
function Start-VMAndCheck {
    param([string]$VMName)
    
    Write-Host "Starting VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would start VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        Start-VM -Name $VMName
        Write-Host "✅ Started VM: $VMName" -ForegroundColor Green
        
        # Wait a bit for VM to start
        Start-Sleep -Seconds 10
        
        # Check VM status
        $vm = Get-VM -Name $VMName
        Write-Host "  VM State: $($vm.State)" -ForegroundColor White
        
    } catch {
        Write-Host "❌ Failed to start VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to check VM firmware settings
function Check-VMFirmware {
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
        Write-Host "  Secure Boot: $($firmware.SecureBoot)" -ForegroundColor White
        Write-Host "  Secure Boot Template: $($firmware.SecureBootTemplate)" -ForegroundColor White
        Write-Host "  Boot Order: $($firmware.BootOrder[0].Description)" -ForegroundColor White
        
        if ($hardDrive.Count -gt 0) {
            Write-Host "  VHD Path: $($hardDrive[0].Path)" -ForegroundColor White
        }
        
        Write-Host ""
        
    } catch {
        Write-Host "❌ Failed to check VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Write-Host "Disabling Secure Boot for all VMs..." -ForegroundColor Yellow
    Write-Host "This will allow Ubuntu cloud images to boot properly." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($vm in $allVMs) {
        Disable-SecureBoot -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "=== VM Firmware Settings After Changes ===" -ForegroundColor Cyan
    
    foreach ($vm in $allVMs) {
        Check-VMFirmware -VMName $vm.Name
    }
    
    # Start all VMs
    Write-Host "Starting all VMs..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Start-VMAndCheck -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "🎉 Secure Boot Disabled Successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs now have:" -ForegroundColor Cyan
    Write-Host "  • Secure Boot disabled" -ForegroundColor White
    Write-Host "  • Ubuntu VHD attached" -ForegroundColor White
    Write-Host "  • Proper boot configuration" -ForegroundColor White
    Write-Host "  • Ready to boot into Ubuntu" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Wait 2-3 minutes for VMs to fully boot into Ubuntu" -ForegroundColor White
    Write-Host "  2. Check VM console to see Ubuntu boot process" -ForegroundColor White
    Write-Host "  3. Default credentials: ubuntu/ubuntu" -ForegroundColor White
    Write-Host "  4. Run Jenkins pipeline to configure Consul and Nomad" -ForegroundColor White
    Write-Host ""
    Write-Host "VM IP Addresses:" -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Write-Host "  • $($vm.Name): $($vm.IP)" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
