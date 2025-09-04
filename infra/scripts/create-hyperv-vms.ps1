# Create Hyper-V VMs for Nomad and Consul cluster
# This script creates and configures Hyper-V VMs

param(
    [string]$BasePath = "C:\Hyper-V\VMs",
    [string]$SwitchName = "NAT-Switch",
    [int]$MemoryMB = 2048,
    [int]$CpuCount = 2,
    [string]$DiskSize = "40GB",
    [string]$IsoPath = "C:\Hyper-V\ISOs\ubuntu-22.04.3-server-amd64.iso",
    [string]$IsoUrl = "https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso",
    [switch]$DryRun = $false
)

Write-Host "=== Creating Hyper-V VMs for Nomad and Consul Cluster ===" -ForegroundColor Green
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

# Function to create a VM
function Create-VM {
    param(
        [string]$VMName,
        [string]$VMPath,
        [string]$VHDPath,
        [string]$IP
    )
    
    Write-Host "Creating VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would create VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        # Create VM directory
        if (-not (Test-Path $VMPath)) {
            New-Item -ItemType Directory -Path $VMPath -Force | Out-Null
            Write-Host "✅ Created VM directory: $VMPath" -ForegroundColor Green
        }
        
        # Create VM if it doesn't exist
        if (-not (Get-VM -Name $VMName -ErrorAction SilentlyContinue)) {
            New-VM -Name $VMName -Path $VMPath -MemoryStartupBytes ($MemoryMB * 1MB) -Generation 2 | Out-Null
            Set-VM -Name $VMName -ProcessorCount $CpuCount | Out-Null
            
            # Connect to switch
            Connect-VMNetworkAdapter -VMName $VMName -SwitchName $SwitchName | Out-Null
            
            # Create and attach VHD
            $diskSizeBytes = [uint64]($DiskSize -replace 'GB', '') * 1GB
            New-VHD -Path $VHDPath -SizeBytes $diskSizeBytes -Dynamic | Out-Null
            Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath | Out-Null
            
            # Attach ISO if available
            if (Test-Path $IsoPath) {
                Add-VMDvdDrive -VMName $VMName -Path $IsoPath | Out-Null
                Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMDvdDrive -VMName $VMName) | Out-Null
                Write-Host "✅ Attached ISO to VM: $VMName" -ForegroundColor Green
            } else {
                # Set boot order to hard drive first when no ISO is available
                Set-VMFirmware -VMName $VMName -FirstBootDevice (Get-VMHardDiskDrive -VMName $VMName) | Out-Null
                Write-Host "⚠️  No ISO available for VM: $VMName (will need manual OS installation)" -ForegroundColor Yellow
                Write-Host "✅ Set boot order to hard drive first for VM: $VMName" -ForegroundColor Green
            }
            
            Write-Host "✅ Created VM: $VMName" -ForegroundColor Green
        } else {
            Write-Host "⚠️  VM already exists: $VMName" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Failed to create VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Function to fix existing VM storage
function Fix-ExistingVMStorage {
    param([string]$VMName, [string]$VHDPath)
    
    Write-Host "Checking storage for existing VM: $VMName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would check storage for existing VM $VMName" -ForegroundColor Cyan
        return
    }
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "⚠️  VM not found: $VMName" -ForegroundColor Yellow
            return
        }
        
        # Check if VHD exists
        if (-not (Test-Path $VHDPath)) {
            Write-Host "Creating missing VHD for VM: $VMName" -ForegroundColor Yellow
            $diskSizeBytes = [uint64]($DiskSize -replace 'GB', '') * 1GB
            New-VHD -Path $VHDPath -SizeBytes $diskSizeBytes -Dynamic | Out-Null
            Write-Host "✅ Created VHD: $VHDPath" -ForegroundColor Green
        }
        
        # Check if VHD is attached
        $existingDrives = Get-VMHardDiskDrive -VMName $VMName
        if (-not $existingDrives) {
            Write-Host "Attaching VHD to existing VM: $VMName" -ForegroundColor Yellow
            Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath | Out-Null
            Write-Host "✅ Attached VHD to VM: $VMName" -ForegroundColor Green
        }
        
        # Set boot order to hard drive first
        $hardDrive = Get-VMHardDiskDrive -VMName $VMName
        if ($hardDrive) {
            Set-VMFirmware -VMName $VMName -FirstBootDevice $hardDrive | Out-Null
            Write-Host "✅ Set boot order to hard drive first for VM: $VMName" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "❌ Failed to fix storage for existing VM $VMName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to create VM switch
function Create-VMSwitch {
    param([string]$SwitchName)
    
    Write-Host "Creating VM switch: $SwitchName" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would create VM switch $SwitchName" -ForegroundColor Cyan
        return
    }
    
    try {
        if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
            New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
            Write-Host "✅ Created VM switch: $SwitchName" -ForegroundColor Green
        } else {
            Write-Host "⚠️  VM switch already exists: $SwitchName" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Failed to create VM switch $SwitchName : $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

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
        Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing
        Write-Host "✅ Ubuntu ISO downloaded successfully: $Path" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Failed to download Ubuntu ISO: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    # Create base directory
    if (-not (Test-Path $BasePath)) {
        New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
        Write-Host "✅ Created base directory: $BasePath" -ForegroundColor Green
    }
    
    # Download Ubuntu ISO (optional)
    $isoDownloaded = Download-UbuntuISO -Url $IsoUrl -Path $IsoPath
    if (-not $isoDownloaded) {
        Write-Host "⚠️  Ubuntu ISO download failed, but continuing with VM creation" -ForegroundColor Yellow
        Write-Host "VMs will be created without OS and can be configured later" -ForegroundColor Yellow
    }
    
    # Create VM switch
    Create-VMSwitch -SwitchName $SwitchName
    
    # Create all VMs
    foreach ($vm in $allVMs) {
        $vmPath = Join-Path $BasePath $vm.Name
        $vhdPath = Join-Path $vmPath "$($vm.Name).vhdx"
        
        # Check if VM already exists
        if (Get-VM -Name $vm.Name -ErrorAction SilentlyContinue) {
            Write-Host "VM already exists: $($vm.Name), checking storage configuration..." -ForegroundColor Yellow
            Fix-ExistingVMStorage -VMName $vm.Name -VHDPath $vhdPath
        } else {
            Create-VM -VMName $vm.Name -VMPath $vmPath -VHDPath $vhdPath -IP $vm.IP
        }
    }
    
    # Start all VMs
    Write-Host "Starting all VMs..." -ForegroundColor Yellow
    if (-not $DryRun) {
        foreach ($vm in $allVMs) {
            $vmObj = Get-VM -Name $vm.Name -ErrorAction SilentlyContinue
            if ($vmObj -and $vmObj.State -ne 'Running') {
                Start-VM -Name $vm.Name | Out-Null
                Write-Host "✅ Started VM: $($vm.Name)" -ForegroundColor Green
            } else {
                Write-Host "⚠️  VM already running or not found: $($vm.Name)" -ForegroundColor Yellow
            }
        }
    }
    
    # Wait for VMs to initialize
    Write-Host "Waiting for VMs to initialize..." -ForegroundColor Yellow
    if (-not $DryRun) {
        Start-Sleep -Seconds 30
    }
    
    # Display VM status
    Write-Host "=== VM Status ===" -ForegroundColor Cyan
    if (-not $DryRun) {
        Get-VM | Where-Object { $_.Name -match "consul-|nomad-" } | Format-Table Name, State, CPUUsage, MemoryAssigned -AutoSize
    }
    
    # Generate inventory file
    Write-Host "Generating Ansible inventory..." -ForegroundColor Yellow
    $inventoryPath = "inventory.ini"
    $inventoryContent = @"
# Ansible inventory for Nomad and Consul cluster
# Generated by Hyper-V VM creation script

[consul_servers]
"@
    
    foreach ($server in $consulServers) {
        $inventoryContent += "`n$($server.Name) ansible_host=$($server.IP) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa"
    }
    
    $inventoryContent += "`n`n[nomad_servers]"
    foreach ($server in $nomadServers) {
        $inventoryContent += "`n$($server.Name) ansible_host=$($server.IP) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa"
    }
    
    $inventoryContent += "`n`n[nomad_clients]"
    foreach ($client in $nomadClients) {
        $inventoryContent += "`n$($client.Name) ansible_host=$($client.IP) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa"
    }
    
    $inventoryContent += @"

[consul:children]
consul_servers

[nomad:children]
nomad_servers
nomad_clients

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
"@
    
    $inventoryContent | Out-File -FilePath $inventoryPath -Encoding UTF8
    Write-Host "✅ Generated inventory file: $inventoryPath" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🎉 Hyper-V VM Creation Completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Created VMs:" -ForegroundColor Cyan
    Write-Host "  Consul Servers: $($consulServers.Count)" -ForegroundColor White
    Write-Host "  Nomad Servers: $($nomadServers.Count)" -ForegroundColor White
    Write-Host "  Nomad Clients: $($nomadClients.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Install Ubuntu on each VM" -ForegroundColor White
    Write-Host "  2. Configure SSH keys" -ForegroundColor White
    Write-Host "  3. Run Ansible configuration playbooks" -ForegroundColor White
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
