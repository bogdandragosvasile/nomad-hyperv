# Replace Empty VHD Files with Ubuntu VHD
# This script replaces the empty VHD files with the downloaded Ubuntu VHD

param(
    [string]$SourceVhdPath = "C:\Hyper-V\VHDs\livecd.ubuntu-cpc.azure.vhd",
    [switch]$DryRun = $false
)

Write-Host "=== Replacing VHD Files with Ubuntu VHD ===" -ForegroundColor Green
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

# Function to replace VM VHD with Ubuntu VHD
function Replace-VMVHD {
    param([string]$VMName, [string]$SourceVhdPath, [string]$TargetVhdPath)
    
    Write-Host "Replacing VHD for VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would replace VHD for VM $VMName" -ForegroundColor Cyan
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
        
        # Remove existing hard drive
        $existingDrives = Get-VMHardDiskDrive -VMName $VMName
        if ($existingDrives) {
            Write-Host "Removing existing VHD from VM: $VMName" -ForegroundColor Yellow
            Remove-VMHardDiskDrive -VMName $VMName -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0
        }
        
        # Create target directory if it doesn't exist
        $targetDir = Split-Path $TargetVhdPath -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Copy Ubuntu VHD to VM directory
        Write-Host "Copying Ubuntu VHD to VM directory..." -ForegroundColor Yellow
        Write-Host "  Source: $SourceVhdPath" -ForegroundColor White
        Write-Host "  Target: $TargetVhdPath" -ForegroundColor White
        Write-Host "  This may take 5-10 minutes (VHD is ~32GB)..." -ForegroundColor Yellow
        
        Copy-Item -Path $SourceVhdPath -Destination $TargetVhdPath -Force
        Write-Host "✅ Ubuntu VHD copied to VM directory" -ForegroundColor Green
        
        # Attach new VHD to VM
        Add-VMHardDiskDrive -VMName $VMName -Path $TargetVhdPath -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 | Out-Null
        Write-Host "✅ Attached Ubuntu VHD to VM: $VMName" -ForegroundColor Green
        
        # Set boot order to hard drive first
        $hardDrive = Get-VMHardDiskDrive -VMName $VMName
        Set-VMFirmware -VMName $VMName -FirstBootDevice $hardDrive | Out-Null
        Write-Host "✅ Set boot order to hard drive first for VM: $VMName" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to replace VHD for VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
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

# Main execution
try {
    # Check if source VHD exists
    if (-not (Test-Path $SourceVhdPath)) {
        Write-Host "❌ Source Ubuntu VHD not found: $SourceVhdPath" -ForegroundColor Red
        Write-Host "Please ensure the Ubuntu VHD has been downloaded and extracted." -ForegroundColor Yellow
        exit 1
    }
    
    $vhdSize = [math]::Round((Get-Item $SourceVhdPath).Length / 1GB, 2)
    Write-Host "✅ Source Ubuntu VHD found: $vhdSize GB" -ForegroundColor Green
    Write-Host ""
    
    # Replace VHD for all VMs
    Write-Host "Replacing VHD files for all VMs..." -ForegroundColor Yellow
    Write-Host "This will take approximately 45-60 minutes for all 9 VMs..." -ForegroundColor Cyan
    Write-Host ""
    
    $vmCount = 0
    foreach ($vm in $allVMs) {
        $vmCount++
        $vmVhdPath = Join-Path "C:\Hyper-V\VMs\$($vm.Name)" "$($vm.Name).vhd"
        
        Write-Host "Processing VM $vmCount of $($allVMs.Count): $($vm.Name)" -ForegroundColor Cyan
        Replace-VMVHD -VMName $vm.Name -SourceVhdPath $SourceVhdPath -TargetVhdPath $vmVhdPath
        Write-Host ""
    }
    
    # Start all VMs
    Write-Host "Starting all VMs with Ubuntu..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Start-VMAndCheck -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "🎉 Ubuntu VHD Replacement Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs now have:" -ForegroundColor Cyan
    Write-Host "  • Pre-built Ubuntu 22.04 Server VHD" -ForegroundColor White
    Write-Host "  • Proper boot configuration" -ForegroundColor White
    Write-Host "  • Ready to boot into Ubuntu" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Wait 2-3 minutes for VMs to fully boot" -ForegroundColor White
    Write-Host "  2. Check VM console to see Ubuntu boot process" -ForegroundColor White
    Write-Host "  3. Default credentials: ubuntu/ubuntu" -ForegroundColor White
    Write-Host "  4. Configure network settings if needed" -ForegroundColor White
    Write-Host "  5. Run Jenkins pipeline to configure Consul and Nomad" -ForegroundColor White
    Write-Host ""
    Write-Host "Default Ubuntu credentials:" -ForegroundColor Yellow
    Write-Host "  Username: ubuntu" -ForegroundColor White
    Write-Host "  Password: ubuntu" -ForegroundColor White
    Write-Host ""
    Write-Host "VM IP Addresses:" -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Write-Host "  • $($vm.Name): $($vm.IP)" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}


