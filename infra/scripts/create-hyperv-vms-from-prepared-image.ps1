param(
    [switch]$DestroyExisting,
    [switch]$DryRun,
    [switch]$UsePreparedImage
)

# Configuration
$VMPath = "C:\Hyper-V\VMs"
$VHDPath = "C:\Hyper-V\VHDs"
# Use the original Ubuntu VHD instead of prepared image (format compatibility issues)
$OriginalUbuntuVHD = "C:\Hyper-V\VHDs\livecd.ubuntu-cpc.azure.vhd"

if (Test-Path $OriginalUbuntuVHD) {
    $PreparedImagePath = $OriginalUbuntuVHD
    Write-Host "Using original Ubuntu VHD: $PreparedImagePath" -ForegroundColor Green
} else {
    Write-Host "Original Ubuntu VHD not found at: $OriginalUbuntuVHD" -ForegroundColor Red
    Write-Host "Please ensure the Ubuntu VHD is available" -ForegroundColor Red
    exit 1
}
$NetworkSwitch = "NAT-Switch"
$Memory = 2GB
$ProcessorCount = 2

# Function to create cloud-init ISO
function Create-CloudInitISO {
    param(
        [string]$VMName,
        [string]$IP,
        [string]$Role
    )
    
    $isoPath = Join-Path $VHDPath "$VMName-cloud-init.iso"
    $tempDir = Join-Path $env:TEMP "cloud-init-$VMName"
    
    # Create temporary directory
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Create user-data
    $userData = @"
#cloud-config
hostname: $VMName
fqdn: $VMName.local
manage_etc_hosts: true

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7vbqajDhA... jenkins@nomad-consul

package_update: true
package_upgrade: true

packages:
  - openssh-server
  - curl
  - wget
  - unzip

runcmd:
  - systemctl enable ssh
  - systemctl start ssh
  - echo "VM $VMName with role $Role is ready" > /var/log/vm-ready.log
"@
    
    # Create network-config
    $networkConfig = @"
version: 2
ethernets:
  eth0:
    dhcp4: true
    dhcp6: false
"@
    
    # Create meta-data
    $metaData = @"
instance-id: $VMName
local-hostname: $VMName
"@
    
    # Write files
    $userData | Out-File -FilePath "$tempDir\user-data" -Encoding ASCII
    $networkConfig | Out-File -FilePath "$tempDir\network-config" -Encoding ASCII
    $metaData | Out-File -FilePath "$tempDir\meta-data" -Encoding ASCII
    
    # Create ISO
    try {
        $oscdimgPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        if (Test-Path $oscdimgPath) {
            & $oscdimgPath -m -o -u2 -udfver102 -bootdata:2#p0,e,b"$tempDir"#pEF,e,b"$tempDir" "$tempDir" "$isoPath"
        } else {
            # Fallback: use PowerShell to create a simple ISO
            Write-Host "oscdimg not found, creating simple ISO structure" -ForegroundColor Yellow
            # This is a simplified approach - in production you'd want proper ISO creation
            Copy-Item -Path "$tempDir\*" -Destination "$tempDir\cloud-init" -Recurse
        }
    } catch {
        Write-Host "Error creating ISO: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Cleanup temp directory
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    return $isoPath
}

# VM Configuration
$VMs = @(
    @{Name="consul-server-1"; IP="192.168.1.100"; Role="consul-server"},
    @{Name="consul-server-2"; IP="192.168.1.101"; Role="consul-server"},
    @{Name="consul-server-3"; IP="192.168.1.102"; Role="consul-server"},
    @{Name="nomad-server-1"; IP="192.168.1.103"; Role="nomad-server"},
    @{Name="nomad-server-2"; IP="192.168.1.104"; Role="nomad-server"},
    @{Name="nomad-server-3"; IP="192.168.1.105"; Role="nomad-server"},
    @{Name="nomad-client-1"; IP="192.168.1.106"; Role="nomad-client"},
    @{Name="nomad-client-2"; IP="192.168.1.107"; Role="nomad-client"},
    @{Name="nomad-client-3"; IP="192.168.1.108"; Role="nomad-client"}
)

Write-Host "=== Hyper-V VM Deployment with Prepared Image ===" -ForegroundColor Green
Write-Host "Prepared Image: $PreparedImagePath" -ForegroundColor Yellow
Write-Host "Network Switch: $NetworkSwitch" -ForegroundColor Yellow
Write-Host "Total VMs: $($VMs.Count)" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "DRY RUN MODE - No actual changes will be made" -ForegroundColor Cyan
}

# Check if prepared image exists
if (-not $DryRun -and -not (Test-Path $PreparedImagePath)) {
    Write-Error "Prepared image not found at: $PreparedImagePath"
    Write-Host "Please run the VM image preparation pipeline first." -ForegroundColor Red
    exit 1
}

# Create directories if they don't exist
if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path $VMPath | Out-Null
    New-Item -ItemType Directory -Force -Path $VHDPath | Out-Null
    New-Item -ItemType Directory -Force -Path (Split-Path $PreparedImagePath) | Out-Null
}

# Destroy existing VMs if requested
if ($DestroyExisting) {
    Write-Host "`n=== Destroying Existing VMs ===" -ForegroundColor Red
    
    foreach ($vm in $VMs) {
        $vmName = $vm.Name
        Write-Host "Checking VM: $vmName" -ForegroundColor Yellow
        
        if (Get-VM -Name $vmName -ErrorAction SilentlyContinue) {
            if ($DryRun) {
                Write-Host "DRY RUN: Would destroy VM: $vmName" -ForegroundColor Cyan
            } else {
                Write-Host "Stopping and removing VM: $vmName" -ForegroundColor Red
                Stop-VM -Name $vmName -Force -ErrorAction SilentlyContinue
                Remove-VM -Name $vmName -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "VM not found: $vmName" -ForegroundColor Gray
        }
    }
    
    Write-Host "Existing VMs cleanup completed" -ForegroundColor Green
}

# Create VMs using prepared image
Write-Host "`n=== Creating VMs with Prepared Image ===" -ForegroundColor Green

foreach ($vm in $VMs) {
    $vmName = $vm.Name
    $vmIP = $vm.IP
    $vmRole = $vm.Role
    
    Write-Host "`nCreating VM: $vmName ($vmRole) - IP: $vmIP" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would create VM: $vmName" -ForegroundColor Cyan
        Write-Host "  - Memory: $Memory" -ForegroundColor Gray
        Write-Host "  - Processors: $ProcessorCount" -ForegroundColor Gray
        Write-Host "  - Network: $NetworkSwitch" -ForegroundColor Gray
        Write-Host "  - VHD: $PreparedImagePath" -ForegroundColor Gray
        continue
    }
    
    # Create VM
    $vmPath = Join-Path $VMPath $vmName
    $vmVHDPath = Join-Path $VHDPath "$vmName.vhdx"
    
    try {
        # Copy original Ubuntu VHD for this VM
        Write-Host "Copying Ubuntu VHD for $vmName..." -ForegroundColor Gray
        Copy-Item -Path $PreparedImagePath -Destination $vmVHDPath -Force
        
        # Create cloud-init ISO
        Write-Host "Creating cloud-init ISO for $vmName..." -ForegroundColor Gray
        $isoPath = Create-CloudInitISO -VMName $vmName -IP $vm.IP -Role $vm.Role
        
        # Create VM
        Write-Host "Creating VM: $vmName" -ForegroundColor Gray
        New-VM -Name $vmName -Path $vmPath -MemoryStartupBytes $Memory -Generation 2 -ErrorAction Stop
        
        # Configure VM
        Write-Host "Configuring VM: $vmName" -ForegroundColor Gray
        
        # Set processor count
        Set-VMProcessor -VMName $vmName -Count $ProcessorCount
        
        # Disable dynamic memory
        Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false
        
        # Disable secure boot
        Set-VMFirmware -VMName $vmName -EnableSecureBoot Off
        
        # Add VHD
        Add-VMHardDiskDrive -VMName $vmName -Path $vmVHDPath
        
        # Add cloud-init ISO
        Add-VMDvdDrive -VMName $vmName -Path $isoPath
        
        # Connect to network
        Connect-VMNetworkAdapter -VMName $vmName -SwitchName $NetworkSwitch
        
        # Set boot order (VHD first)
        $bootOrder = Get-VMFirmware -VMName $vmName | Select-Object -ExpandProperty BootOrder
        $vhdBoot = $bootOrder | Where-Object { $_.BootType -eq "Drive" -and $_.Device.Path -eq $vmVHDPath }
        if ($vhdBoot) {
            Set-VMFirmware -VMName $vmName -FirstBootDevice $vhdBoot
        }
        
        Write-Host "✅ VM created successfully: $vmName" -ForegroundColor Green
        
    } catch {
        Write-Error "Failed to create VM $vmName`: $($_.Exception.Message)"
        # Clean up on failure
        if (Get-VM -Name $vmName -ErrorAction SilentlyContinue) {
            Remove-VM -Name $vmName -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $vmVHDPath) {
            Remove-Item -Path $vmVHDPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Start all VMs
Write-Host "`n=== Starting VMs ===" -ForegroundColor Green

foreach ($vm in $VMs) {
    $vmName = $vm.Name
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would start VM: $vmName" -ForegroundColor Cyan
    } else {
        if (Get-VM -Name $vmName -ErrorAction SilentlyContinue) {
            Write-Host "Starting VM: $vmName" -ForegroundColor Yellow
            Start-VM -Name $vmName
            Write-Host "✅ VM started: $vmName" -ForegroundColor Green
        } else {
            Write-Warning "VM not found: $vmName"
        }
    }
}

Write-Host "`n=== VM Deployment Summary ===" -ForegroundColor Green
Write-Host "Total VMs: $($VMs.Count)" -ForegroundColor Yellow
Write-Host "Consul Servers: 3 (192.168.1.100-102)" -ForegroundColor Yellow
Write-Host "Nomad Servers: 3 (192.168.1.103-105)" -ForegroundColor Yellow
Write-Host "Nomad Clients: 3 (192.168.1.106-108)" -ForegroundColor Yellow

if (-not $DryRun) {
    Write-Host "`nVMs are starting up with pre-configured networking and SSH access." -ForegroundColor Green
    Write-Host "The prepared image includes:" -ForegroundColor Yellow
    Write-Host "  - SSH key authentication configured" -ForegroundColor Gray
    Write-Host "  - Network configuration (DHCP)" -ForegroundColor Gray
    Write-Host "  - Cloud-init ready for further configuration" -ForegroundColor Gray
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Wait for VMs to boot (2-3 minutes)" -ForegroundColor Gray
    Write-Host "2. Run cluster configuration with Ansible" -ForegroundColor Gray
    Write-Host "3. Deploy Nomad and Consul services" -ForegroundColor Gray
} else {
    Write-Host "`nDRY RUN completed - no actual changes made" -ForegroundColor Cyan
}

Write-Host "`n=== Deployment Completed ===" -ForegroundColor Green
