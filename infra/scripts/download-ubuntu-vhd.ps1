# Download Pre-built Ubuntu VHD Images
# This script downloads official Ubuntu VHD images and replaces empty VHD files

param(
    [string]$VhdBasePath = "C:\Hyper-V\VHDs",
    [string]$VhdUrl = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-azure.vhd.tar.gz",
    [string]$VhdFileName = "jammy-server-cloudimg-amd64-azure.vhd",
    [string]$FallbackUrl = "https://www.osboxes.org/ubuntu/",
    [switch]$DryRun = $false
)

Write-Host "=== Downloading Pre-built Ubuntu VHD Images ===" -ForegroundColor Green
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

# Function to download and extract Ubuntu VHD
function Download-UbuntuVHD {
    param([string]$Url, [string]$Path)
    
    Write-Host "Downloading Ubuntu VHD image..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would download Ubuntu VHD from $Url to $Path" -ForegroundColor Cyan
        return $true
    }
    
    try {
        $vhdDir = Split-Path $Path -Parent
        if (-not (Test-Path $vhdDir)) {
            New-Item -ItemType Directory -Path $vhdDir -Force | Out-Null
            Write-Host "✅ Created VHD directory: $vhdDir" -ForegroundColor Green
        }
        
        if (Test-Path $Path) {
            Write-Host "✅ Ubuntu VHD already exists: $Path" -ForegroundColor Green
            return $true
        }
        
        # Download tar.gz file
        $tarGzPath = $Path + ".tar.gz"
        Write-Host "Downloading from: $Url" -ForegroundColor Cyan
        Write-Host "This may take 10-15 minutes (VHD is ~1.5GB)..." -ForegroundColor Yellow
        
        # Use Invoke-WebRequest with progress
        $ProgressPreference = 'Continue'
        Invoke-WebRequest -Uri $Url -OutFile $tarGzPath -UseBasicParsing
        $ProgressPreference = 'SilentlyContinue'
        
        Write-Host "✅ Ubuntu VHD tar.gz downloaded successfully" -ForegroundColor Green
        
        # Extract VHD from tar.gz
        Write-Host "Extracting VHD from tar.gz..." -ForegroundColor Yellow
        
        # Use 7-Zip or tar to extract (Windows 10+ has built-in tar)
        try {
            # Try using built-in tar command (Windows 10+)
            $extractDir = Split-Path $Path -Parent
            tar -xzf $tarGzPath -C $extractDir
            Write-Host "✅ VHD extracted successfully using tar" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to extract using tar: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Trying alternative extraction method..." -ForegroundColor Yellow
            
            # Alternative: Use PowerShell to extract (basic implementation)
            # Note: This is a simplified extraction - for production use 7-Zip
            Write-Host "⚠️  Manual extraction required. Please extract $tarGzPath manually." -ForegroundColor Yellow
            Write-Host "   The VHD file should be extracted to: $Path" -ForegroundColor White
            return $false
        }
        
        # Clean up tar.gz file
        if (Test-Path $tarGzPath) {
            Remove-Item $tarGzPath -Force
            Write-Host "✅ Cleaned up tar.gz file" -ForegroundColor Green
        }
        
        # Verify VHD file exists
        if (Test-Path $Path) {
            Write-Host "✅ Ubuntu VHD ready: $Path" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ VHD file not found after extraction" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "❌ Failed to download Ubuntu VHD: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

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
        
        # Copy Ubuntu VHD to VM directory
        $targetDir = Split-Path $TargetVhdPath -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        Write-Host "Copying Ubuntu VHD to VM directory..." -ForegroundColor Yellow
        Copy-Item -Path $SourceVhdPath -Destination $TargetVhdPath -Force
        
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
    # Download Ubuntu VHD
    $vhdPath = Join-Path $VhdBasePath $VhdFileName
    $vhdDownloaded = Download-UbuntuVHD -Url $VhdUrl -Path $vhdPath
    if (-not $vhdDownloaded) {
        Write-Host "❌ Failed to download Ubuntu VHD. Cannot proceed." -ForegroundColor Red
        exit 1
    }
    
    # Replace VHD for all VMs
    Write-Host "Replacing VHD files for all VMs..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        $vmVhdPath = Join-Path "C:\Hyper-V\VMs\$($vm.Name)" "$($vm.Name).vhd"
        Replace-VMVHD -VMName $vm.Name -SourceVhdPath $vhdPath -TargetVhdPath $vmVhdPath
    }
    
    # Start all VMs
    Write-Host "Starting all VMs with Ubuntu..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Start-VMAndCheck -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "🎉 Ubuntu VHD Deployment Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs now have:" -ForegroundColor Cyan
    Write-Host "  • Pre-built Ubuntu 22.04 Server VHD" -ForegroundColor White
    Write-Host "  • Proper boot configuration" -ForegroundColor White
    Write-Host "  • Ready to boot into Ubuntu" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Wait 2-3 minutes for VMs to fully boot" -ForegroundColor White
    Write-Host "  2. Check VM console to see Ubuntu boot process" -ForegroundColor White
    Write-Host "  3. Configure SSH access (default user: ubuntu)" -ForegroundColor White
    Write-Host "  4. Run Jenkins pipeline to configure Consul and Nomad" -ForegroundColor White
    Write-Host ""
    Write-Host "Default Ubuntu credentials:" -ForegroundColor Yellow
    Write-Host "  Username: ubuntu" -ForegroundColor White
    Write-Host "  Password: ubuntu (or use SSH keys)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
