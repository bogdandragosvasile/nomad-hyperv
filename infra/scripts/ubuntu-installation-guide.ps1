# Ubuntu Installation Guide for Hyper-V VMs
# This script provides instructions and automation for Ubuntu installation

param(
    [switch]$ShowInstructions = $true,
    [switch]$OpenHyperVManager = $false
)

Write-Host "=== Ubuntu Installation Guide for Hyper-V VMs ===" -ForegroundColor Green
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

# Function to open Hyper-V Manager
function Open-HyperVManager {
    Write-Host "Opening Hyper-V Manager..." -ForegroundColor Yellow
    try {
        Start-Process "virtmgmt.msc"
        Write-Host "✅ Hyper-V Manager opened" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to open Hyper-V Manager: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Write-Host "=== Current VM Status ===" -ForegroundColor Cyan
    foreach ($vm in $allVMs) {
        Check-VMStatus -VMName $vm.Name
    }
    
    if ($ShowInstructions) {
        Write-Host "=== Ubuntu Installation Instructions ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "STEP 1: Download Ubuntu ISO" -ForegroundColor Yellow
        Write-Host "  1. Go to: https://ubuntu.com/download/server" -ForegroundColor White
        Write-Host "  2. Download Ubuntu 22.04 LTS Server ISO" -ForegroundColor White
        Write-Host "  3. Save it to: C:\Hyper-V\ISOs\ubuntu-22.04-server-amd64.iso" -ForegroundColor White
        Write-Host ""
        Write-Host "STEP 2: Attach ISO to VMs" -ForegroundColor Yellow
        Write-Host "  1. Open Hyper-V Manager" -ForegroundColor White
        Write-Host "  2. For each VM, right-click → Settings → DVD Drive" -ForegroundColor White
        Write-Host "  3. Select 'Image file' and browse to the Ubuntu ISO" -ForegroundColor White
        Write-Host "  4. Set boot order to DVD first" -ForegroundColor White
        Write-Host ""
        Write-Host "STEP 3: Install Ubuntu on each VM" -ForegroundColor Yellow
        Write-Host "  1. Start each VM" -ForegroundColor White
        Write-Host "  2. Connect to VM console" -ForegroundColor White
        Write-Host "  3. Follow Ubuntu installation wizard" -ForegroundColor White
        Write-Host "  4. Use these settings:" -ForegroundColor White
        Write-Host ""
        
        Write-Host "     🔧 VM Configuration Settings:" -ForegroundColor Cyan
        foreach ($vm in $allVMs) {
            Write-Host "     • $($vm.Name): IP $($vm.IP)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "     🔧 Ubuntu Installation Settings:" -ForegroundColor Cyan
        Write-Host "     • Username: ubuntu" -ForegroundColor White
        Write-Host "     • Password: ubuntu (or your choice)" -ForegroundColor White
        Write-Host "     • Hostname: Use VM name (e.g., consul-server-1)" -ForegroundColor White
        Write-Host "     • Static IP: Use the IPs shown above" -ForegroundColor White
        Write-Host "     • Enable SSH: Yes" -ForegroundColor White
        Write-Host "     • Install OpenSSH Server: Yes" -ForegroundColor White
        Write-Host ""
        
        Write-Host "📋 STEP 4: Verify Installation" -ForegroundColor Yellow
        Write-Host "  1. Test SSH access: ssh ubuntu@<VM_IP>" -ForegroundColor White
        Write-Host "  2. Verify network connectivity" -ForegroundColor White
        Write-Host "  3. Run Jenkins pipeline to configure Consul and Nomad" -ForegroundColor White
        Write-Host ""
        
        Write-Host "📋 STEP 5: Run Jenkins Pipeline" -ForegroundColor Yellow
        Write-Host "  1. Go to: http://localhost:8080" -ForegroundColor White
        Write-Host "  2. Run job: nomad-consul-deployment" -ForegroundColor White
        Write-Host "  3. Set HYBRID_MODE=false for real deployment" -ForegroundColor White
        Write-Host "  4. Pipeline will configure Consul and Nomad automatically" -ForegroundColor White
        Write-Host ""
    }
    
    if ($OpenHyperVManager) {
        Open-HyperVManager
    }
    
    Write-Host "🎉 Installation Guide Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Quick Tips:" -ForegroundColor Cyan
    Write-Host "  • Install Ubuntu on 1-2 VMs first to test the process" -ForegroundColor White
    Write-Host "  • Use the same username/password for all VMs" -ForegroundColor White
    Write-Host "  • Enable SSH during installation for remote access" -ForegroundColor White
    Write-Host "  • The Jenkins pipeline will handle the rest automatically" -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
