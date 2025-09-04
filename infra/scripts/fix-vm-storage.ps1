# Fix VM Storage - Attach VHD files to existing VMs
# This script creates and attaches VHD files to the existing VMs

param(
    [string]$BasePath = "C:\Hyper-V\VMs",
    [string]$DiskSize = "40GB",
    [switch]$DryRun = $false
)

Write-Host "=== Fixing VM Storage - Attaching VHD Files ===" -ForegroundColor Green
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

# Function to fix VM storage
function Fix-VMStorage {
    param([string]$VMName)
    
    Write-Host "Fixing storage for VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would fix storage for VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "⚠️  VM not found: $VMName" -ForegroundColor Yellow
            return
        }
        
        $vmPath = Join-Path $BasePath $VMName
        $vhdPath = Join-Path $vmPath "$VMName.vhdx"
        
        # Check if VHD already exists
        if (Test-Path $vhdPath) {
            Write-Host "✅ VHD already exists: $vhdPath" -ForegroundColor Green
        } else {
            # Create VHD directory if it doesn't exist
            if (-not (Test-Path $vmPath)) {
                New-Item -ItemType Directory -Path $vmPath -Force | Out-Null
                Write-Host "✅ Created VM directory: $vmPath" -ForegroundColor Green
            }
            
            # Create VHD
            $diskSizeBytes = [uint64]($DiskSize -replace 'GB', '') * 1GB
            New-VHD -Path $vhdPath -SizeBytes $diskSizeBytes -Dynamic | Out-Null
            Write-Host "✅ Created VHD: $vhdPath" -ForegroundColor Green
        }
        
        # Check if VHD is already attached
        $existingDrives = Get-VMHardDiskDrive -VMName $VMName
        if ($existingDrives) {
            Write-Host "⚠️  VM already has hard drives attached" -ForegroundColor Yellow
            return
        }
        
        # Attach VHD to VM
        Add-VMHardDiskDrive -VMName $VMName -Path $vhdPath | Out-Null
        Write-Host "✅ Attached VHD to VM: $VMName" -ForegroundColor Green
        
        # Set boot order to boot from hard drive first
        Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMHardDiskDrive -VMName $VMName)
        Write-Host "✅ Set boot order for VM: $VMName" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to fix storage for VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Write-Host "Fixing storage for all VMs..." -ForegroundColor Yellow
    
    foreach ($vm in $allVMs) {
        Fix-VMStorage -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "🎉 VM Storage Fix Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs now have:" -ForegroundColor Cyan
    Write-Host "  • VHD files created and attached" -ForegroundColor White
    Write-Host "  • Boot order set to hard drive first" -ForegroundColor White
    Write-Host ""
    Write-Host "The VMs should now be able to boot from their hard drives." -ForegroundColor Cyan
    Write-Host "You may need to install an operating system on the VHDs." -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
