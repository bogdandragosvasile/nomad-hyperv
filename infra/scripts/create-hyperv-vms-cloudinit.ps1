# Create Hyper-V VMs with Cloud-Init Configuration
param(
    [string]$VhdBasePath = "C:\Hyper-V\VHDs",
    [string]$VmBasePath = "C:\Hyper-V\VMs",
    [string]$SwitchName = "NAT-Switch",
    [string]$SshPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMKyQxa9ND05QHJu7fRuoBl2GBcsxqFGFLFkm/JMlvCFAiIqtiCYFMmIp1wAQ0HvcTfVTQeWYHxU06YHb2oVJyHMS30US4eKSSehDSGURyuYV7mjKTrJNlK0QeM5nRn8hJGlZd7w4SCgQQalSlN/lhMBs4/8QNnyO5L6vf/gHwvDH/antZJHOaLIBB15l+SLjRoymRMU1fwu1z1cPXMnW1cXsuvXdZua660m7uTXUBYdIWkdc/7ToR0pfXkYWTxplJ8WDQjvTYsIPKSaTjOVaFz53ukXgRFk/nGC/ZiEEb9gNTz9S5kr1phIE2euzxLNb8pYKfYCsa0LAjdQnvbqeko4ma2+wHhDSicJLSg12Fj87UWuF7jAxKiJk8UOXaXBANevHmX3Qqhr78CQiyVMA9Lbv2X3pSABHokZsc2keP/Aw4s/Q9Hp5kEGrbeDHQN4bJJIQ5prVpIi8TpW/34YudTislHb+8gH0Cg0uvFh46NON6mYeysNDNJyR/bi/cF4Ykv2HUaYWIXYTdveAcixuhXBI2ITS2QKFbG7glIrp/KCNv/t9elJXA4sLwV/sNUkwjU7ITqMP+WZJjUMxOy7BEw/qI/Zy9WkHuQyNNpIjj5gjlq6bvrzoCDK6m9W4Bq+TscyS+e43NLr35mZQXHpoEXvjQsPoaI2UEhy6cjv8xgQ== jenkins@nomad-consul",
    [switch]$DestroyExisting = $false,
    [switch]$DryRun = $false
)

Write-Host "=== Creating Hyper-V VMs with Cloud-Init Configuration ===" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

# VM configurations
$vmConfigs = @(
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

# Function to create cloud-init user-data
function Create-UserData {
    param([string]$VmName, [string]$IpAddress, [string]$Role, [string]$SshKey)
    
    $userData = @"
#cloud-config
hostname: $VmName
fqdn: $VmName.local
manage_etc_hosts: true

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $SshKey
    lock_passwd: false
    passwd: `$6`$rounds=4096`$salt`$hash

ssh_pwauth: true

network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - $IpAddress/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4

package_update: true
package_upgrade: true

packages:
  - openssh-server
  - curl
  - wget
  - unzip
  - python3
  - python3-pip
  - git
  - htop
  - vim
  - net-tools
  - dnsutils

write_files:
  - path: /etc/ssh/sshd_config.d/99-cloud-init.conf
    content: |
      PasswordAuthentication yes
      PubkeyAuthentication yes
      AuthorizedKeysFile .ssh/authorized_keys
      PermitRootLogin no
    permissions: '0644'
  - path: /etc/hosts
    content: |
      127.0.0.1 localhost
      $IpAddress $VmName $VmName.local
      192.168.1.100 consul-server-1 consul-server-1.local
      192.168.1.101 consul-server-2 consul-server-2.local
      192.168.1.102 consul-server-3 consul-server-3.local
      192.168.1.103 nomad-server-1 nomad-server-1.local
      192.168.1.104 nomad-server-2 nomad-server-2.local
      192.168.1.105 nomad-server-3 nomad-server-3.local
      192.168.1.106 nomad-client-1 nomad-client-1.local
      192.168.1.107 nomad-client-2 nomad-client-2.local
      192.168.1.108 nomad-client-3 nomad-client-3.local
    permissions: '0644'

runcmd:
  - systemctl enable ssh
  - systemctl restart ssh
  - ufw allow ssh
  - ufw --force enable
  - echo "VM $VmName ($Role) is ready with IP $IpAddress" > /var/log/vm-ready.log
  - systemctl restart networking

final_message: "VM $VmName ($Role) is ready with IP $IpAddress"
"@
    
    return $userData
}

# Function to create VM
function Create-VM {
    param([string]$VmName, [string]$IpAddress, [string]$Role, [string]$SshKey)
    
    Write-Host "Creating VM: $VmName with IP: $IpAddress" -ForegroundColor Yellow
    
    try {
        # Create VM directory
        $vmPath = Join-Path $VmBasePath $VmName
        if (-not (Test-Path $vmPath)) {
            New-Item -ItemType Directory -Path $vmPath -Force | Out-Null
        }
        
        # Create VHD path
        $vhdPath = Join-Path $vmPath "$VmName.vhd"
        
        if (-not $DryRun) {
            # Create VM
            $vm = New-VM -Name $VmName -Path $vmPath -MemoryStartupBytes 2GB -Generation 2 -SwitchName $SwitchName
            
            # Create VHD from Ubuntu template
            $ubuntuVhd = Join-Path $VhdBasePath "livecd.ubuntu-cpc.azure.vhd"
            if (Test-Path $ubuntuVhd) {
                Copy-Item $ubuntuVhd $vhdPath
                Add-VMHardDiskDrive -VM $vm -Path $vhdPath
            } else {
                Write-Host "Ubuntu VHD not found at: $ubuntuVhd" -ForegroundColor Red
                return $false
            }
            
            # Configure VM
            Set-VM -VM $vm -ProcessorCount 2
            Set-VMMemory -VM $vm -DynamicMemoryEnabled $false
            Set-VMFirmware -VM $vm -EnableSecureBoot Off
            
            # Create cloud-init configuration
            $cloudInitDir = Join-Path $vmPath "cloud-init"
            New-Item -ItemType Directory -Path $cloudInitDir -Force | Out-Null
            
            # Create user-data
            $userData = Create-UserData -VmName $VmName -IpAddress $IpAddress -Role $Role -SshKey $SshKey
            $userData | Out-File -FilePath (Join-Path $cloudInitDir "user-data") -Encoding UTF8
            
            # Create meta-data
            $metaData = @"
instance-id: $VmName
local-hostname: $VmName
"@
            $metaData | Out-File -FilePath (Join-Path $cloudInitDir "meta-data") -Encoding UTF8
            
            # Start VM
            Start-VM -VM $vm
            
            Write-Host "VM $VmName created and started successfully!" -ForegroundColor Green
        } else {
            Write-Host "DRY RUN: Would create VM $VmName with IP $IpAddress" -ForegroundColor Yellow
        }
        
        return $true
        
    } catch {
        Write-Host "Error creating VM $VmName : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

$successCount = 0
$totalCount = $vmConfigs.Count

foreach ($vmConfig in $vmConfigs) {
    $success = Create-VM -VmName $vmConfig.Name -IpAddress $vmConfig.IP -Role $vmConfig.Role -SshKey $SshPublicKey
    if ($success) {
        $successCount++
    }
}

Write-Host ""
Write-Host "VM Creation Summary:" -ForegroundColor Green
Write-Host "Successfully created: $successCount/$totalCount VMs" -ForegroundColor White

if ($successCount -eq $totalCount) {
    Write-Host "All VMs created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "VM IP Addresses:" -ForegroundColor Cyan
    foreach ($vmConfig in $vmConfigs) {
        Write-Host "  $($vmConfig.Name): $($vmConfig.IP)" -ForegroundColor White
    }
} else {
    Write-Host "Some VMs failed to create!" -ForegroundColor Red
}

Write-Host "=== VM Creation Complete ===" -ForegroundColor Green
