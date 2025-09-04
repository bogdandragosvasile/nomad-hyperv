# Attach Ubuntu ISO to VMs for OS installation
# This script downloads Ubuntu ISO and attaches it to all VMs

param(
    [string]$IsoPath = "C:\Hyper-V\ISOs\ubuntu-22.04.4-server-amd64.iso",
    [string]$IsoUrl = "https://releases.ubuntu.com/22.04/ubuntu-22.04.4-server-amd64.iso",
    [switch]$DryRun = $false
)

Write-Host "=== Attaching Ubuntu ISO to VMs ===" -ForegroundColor Green
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
            Write-Host "✅ Created ISO directory: $isoDir" -ForegroundColor Green
        }
        
        if (Test-Path $Path) {
            Write-Host "✅ Ubuntu ISO already exists: $Path" -ForegroundColor Green
            return $true
        }
        
        Write-Host "Downloading from: $Url" -ForegroundColor Cyan
        Write-Host "This may take several minutes..." -ForegroundColor Yellow
        
        # Use Invoke-WebRequest with progress
        $ProgressPreference = 'Continue'
        Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing
        $ProgressPreference = 'SilentlyContinue'
        
        Write-Host "✅ Ubuntu ISO downloaded successfully: $Path" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Failed to download Ubuntu ISO: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to attach ISO to a VM
function Attach-ISOToVM {
    param([string]$VMName, [string]$IsoPath)
    
    Write-Host "Attaching ISO to VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would attach ISO to VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "⚠️  VM not found: $VMName" -ForegroundColor Yellow
            return
        }
        
        # Check if ISO is already attached
        $existingDvdDrives = Get-VMDvdDrive -VMName $VMName
        if ($existingDvdDrives) {
            Write-Host "⚠️  VM already has DVD drive attached: $VMName" -ForegroundColor Yellow
            return
        }
        
        # Attach ISO
        Add-VMDvdDrive -VMName $VMName -Path $IsoPath | Out-Null
        Write-Host "✅ Attached ISO to VM: $VMName" -ForegroundColor Green
        
        # Set boot order to DVD first
        $dvdDrive = Get-VMDvdDrive -VMName $VMName
        Set-VMFirmware -VMName $VMName -FirstBootDevice $dvdDrive | Out-Null
        Write-Host "✅ Set boot order to DVD first for VM: $VMName" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to attach ISO to VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to restart VM
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

# Main execution
try {
    # Download Ubuntu ISO
    $isoDownloaded = Download-UbuntuISO -Url $IsoUrl -Path $IsoPath
    if (-not $isoDownloaded) {
        Write-Host "❌ Failed to download Ubuntu ISO. Cannot proceed." -ForegroundColor Red
        exit 1
    }
    
    # Attach ISO to all VMs
    Write-Host "Attaching ISO to all VMs..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Attach-ISOToVM -VMName $vm.Name -IsoPath $IsoPath
    }
    
    # Restart all VMs to boot from ISO
    Write-Host "Restarting all VMs to boot from ISO..." -ForegroundColor Yellow
    foreach ($vm in $allVMs) {
        Restart-VM -VMName $vm.Name
    }
    
    Write-Host ""
    Write-Host "🎉 Ubuntu ISO Attachment Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All VMs now have:" -ForegroundColor Cyan
    Write-Host "  • Ubuntu ISO attached" -ForegroundColor White
    Write-Host "  • Boot order set to DVD first" -ForegroundColor White
    Write-Host "  • Restarted to begin OS installation" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Connect to each VM console to complete Ubuntu installation" -ForegroundColor White
    Write-Host "  2. Install Ubuntu Server on each VM" -ForegroundColor White
    Write-Host "  3. Configure SSH access for Ansible automation" -ForegroundColor White
    Write-Host "  4. Run the Jenkins pipeline to configure Consul and Nomad" -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
