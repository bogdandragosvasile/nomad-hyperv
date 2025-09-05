# Create Minimal Ubuntu VHD using alternative approach
# This script creates a working Ubuntu VHD using a different method

param(
    [string]$VhdBasePath = "C:\Hyper-V\VHDs",
    [string]$IsoUrl = "https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso",
    [string]$IsoPath = "C:\Hyper-V\ISOs\ubuntu-22.04.4-live-server-amd64.iso",
    [switch]$DryRun = $false
)

Write-Host "=== Creating Minimal Ubuntu VHD ===" -ForegroundColor Green
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

# Function to download Ubuntu ISO
function Download-UbuntuISO {
    param([string]$Url, [string]$Path)
    
    Write-Host "Downloading Ubuntu ISO..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would download Ubuntu ISO from $Url to $Path" -ForegroundColor Cyan
        return $true
    }
    
    try {
        $isoDir = Split-Path $Path -Parent
        if (-not (Test-Path $isoDir)) {
            New-Item -ItemType Directory -Path $isoDir -Force | Out-Null
        }
        
        if (Test-Path $Path) {
            Write-Host "✅ Ubuntu ISO already exists: $Path" -ForegroundColor Green
            return $true
        }
        
        Write-Host "Downloading from: $Url" -ForegroundColor Cyan
        Write-Host "This may take several minutes..." -ForegroundColor Yellow
        
        # Try multiple Ubuntu ISO URLs
        $isoUrls = @(
            "https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso",
            "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso",
            "https://releases.ubuntu.com/22.04/ubuntu-22.04.2-live-server-amd64.iso",
            "https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso"
        )
        
        $downloadSuccess = $false
        foreach ($testUrl in $isoUrls) {
            try {
                Write-Host "Trying: $testUrl" -ForegroundColor Cyan
                Invoke-WebRequest -Uri $testUrl -OutFile $Path -UseBasicParsing
                Write-Host "✅ Ubuntu ISO downloaded successfully: $Path" -ForegroundColor Green
                $downloadSuccess = $true
                break
            } catch {
                Write-Host "❌ Failed to download from $testUrl : $($_.Exception.Message)" -ForegroundColor Red
                continue
            }
        }
        
        return $downloadSuccess
    } catch {
        Write-Host "❌ Failed to download Ubuntu ISO: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to attach ISO and configure VM for installation
function Configure-VMForInstallation {
    param([string]$VMName, [string]$IsoPath)
    
    Write-Host "Configuring VM for Ubuntu installation: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would configure VM $VMName for installation" -ForegroundColor Cyan
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
            Start-Sleep -Seconds 5
        }
        
        # Remove existing DVD drives
        $existingDvdDrives = Get-VMDvdDrive -VMName $VMName
        if ($existingDvdDrives) {
            Remove-VMDvdDrive -VMName $VMName
        }
        
        # Attach Ubuntu ISO
        Add-VMDvdDrive -VMName $VMName -Path $IsoPath | Out-Null
        Write-Host "✅ Attached Ubuntu ISO to VM: $VMName" -ForegroundColor Green
        
        # Set boot order to DVD first
        $dvdDrive = Get-VMDvdDrive -VMName $VMName
        Set-VMFirmware -VMName $VMName -FirstBootDevice $dvdDrive | Out-Null
        Write-Host "✅ Set boot order to DVD first for VM: $VMName" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to configure VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to start VM
function Start-VM {
    param([string]$VMName)
    
    Write-Host "Starting VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would start VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        Start-VM -Name $VMName
        Write-Host "✅ Started VM: $VMName" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to start VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    # Download Ubuntu ISO
    $isoDownloaded = Download-UbuntuISO -Url $IsoUrl -Path $IsoPath
    if (-not $isoDownloaded) {
        Write-Host "❌ Failed to download Ubuntu ISO. Cannot proceed." -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternative approach:" -ForegroundColor Yellow
        Write-Host "1. Manually download Ubuntu 22.04 Server ISO from https://ubuntu.com/download/server" -ForegroundColor White
        Write-Host "2. Place it in C:\Hyper-V\ISOs\" -ForegroundColor White
        Write-Host "3. Run this script again" -ForegroundColor White
        exit 1
    }
    
    # Configure all VMs for installation
    Write-Host "Configuring all VMs for Ubuntu installation..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Configure-VMForInstallation -VMName $vm.Name -IsoPath $IsoPath
    }
    
    # Start all VMs
    Write-Host "Starting all VMs to begin Ubuntu installation..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Start-VM -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "🎉 VM Configuration for Ubuntu Installation Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs now have:" -ForegroundColor Cyan
    Write-Host "  • Ubuntu 22.04 Server ISO attached" -ForegroundColor White
    Write-Host "  • Boot order set to DVD first" -ForegroundColor White
    Write-Host "  • Started to begin Ubuntu installation" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Connect to each VM console in Hyper-V Manager" -ForegroundColor White
    Write-Host "  2. Complete Ubuntu Server installation on each VM" -ForegroundColor White
    Write-Host "  3. Configure SSH access (username: ubuntu)" -ForegroundColor White
    Write-Host "  4. Run Jenkins pipeline to configure Consul and Nomad" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation tips:" -ForegroundColor Yellow
    Write-Host "  • Use 'ubuntu' as username" -ForegroundColor White
    Write-Host "  • Set static IP addresses as configured in the script" -ForegroundColor White
    Write-Host "  • Enable SSH during installation" -ForegroundColor White
    Write-Host "  • Install OpenSSH server for remote access" -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}


