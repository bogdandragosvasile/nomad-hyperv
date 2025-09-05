# Configure VM networking manually
param(
    [string]$VmName = "test-vm",
    [string]$TargetIP = "192.168.1.200",
    [string]$Gateway = "192.168.1.1"
)

Write-Host "=== Configuring VM Networking ===" -ForegroundColor Green
Write-Host "VM: $VmName" -ForegroundColor Cyan
Write-Host "Target IP: $TargetIP" -ForegroundColor Cyan
Write-Host "Gateway: $Gateway" -ForegroundColor Cyan
Write-Host ""

# Check if VM is running
$vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if (-not $vm) {
    Write-Host "❌ VM '$VmName' not found!" -ForegroundColor Red
    exit 1
}

if ($vm.State -ne "Running") {
    Write-Host "❌ VM '$VmName' is not running!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ VM '$VmName' is running" -ForegroundColor Green

# Check current IP addresses
$currentIPs = $vm.NetworkAdapters[0].IPAddresses
Write-Host "Current IP addresses: $($currentIPs -join ', ')" -ForegroundColor Yellow

# Try to ping the VM to see if it's responding
Write-Host "Testing connectivity to VM..." -ForegroundColor Yellow
try {
    $pingResult = Test-NetConnection -ComputerName $TargetIP -Port 22 -WarningAction SilentlyContinue
    if ($pingResult.TcpTestSucceeded) {
        Write-Host "✅ VM is accessible on $TargetIP:22" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "❌ VM is not accessible on $TargetIP:22" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Connection test failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "The VM needs manual network configuration." -ForegroundColor Yellow
Write-Host "Options:" -ForegroundColor White
Write-Host "1. Use Hyper-V console to configure networking manually" -ForegroundColor White
Write-Host "2. Create a cloud-init ISO with network configuration" -ForegroundColor White
Write-Host "3. Use a different Ubuntu image with pre-configured networking" -ForegroundColor White
Write-Host ""
Write-Host "For now, let's try to create a cloud-init ISO..." -ForegroundColor Cyan

# Create cloud-init ISO
$isoPath = Join-Path $vm.Path "cloud-init.iso"
$cloudInitDir = Join-Path $vm.Path "cloud-init"

Write-Host "Creating cloud-init configuration..." -ForegroundColor Yellow

# Create cloud-init directory
if (-not (Test-Path $cloudInitDir)) {
    New-Item -ItemType Directory -Path $cloudInitDir -Force | Out-Null
}

# Create user-data
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
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMKyQxa9ND05QHJu7fRuoBl2GBcsxqFGFLFkm/JMlvCFAiIqtiCYFMmIp1wAQ0HvcTfVTQeWYHxU06YHb2oVJyHMS30US4eKSSehDSGURyuYV7mjKTrJNlK0QeM5nRn8hJGlZd7w4SCgQQalSlN/lhMBs4/8QNnyO5L6vf/gHwvDH/antZJHOaLIBB15l+SLjRoymRMU1fwu1z1cPXMnW1cXsuvXdZua660m7uTXUBYdIWkdc/7ToR0pfXkYWTxplJ8WDQjvTYsIPKSaTjOVaFz53ukXgRFk/nGC/ZiEEb9gNTz9S5kr1phIE2euzxLNb8pYKfYCsa0LAjdQnvbqeko4ma2+wHhDSicJLSg12Fj87UWuF7jAxKiJk8UOXaXBANevHmX3Qqhr78CQiyVMA9Lbv2X3pSABHokZsc2keP/Aw4s/Q9Hp5kEGrbeDHQN4bJJIQ5prVpIi8TpW/34YudTislHb+8gH0Cg0uvFh46NON6mYeysNDNJyR/bi/cF4Ykv2HUaYWIXYTdveAcixuhXBI2ITS2QKFbG7glIrp/KCNv/t9elJXA4sLwV/sNUkwjU7ITqMP+WZJjUMxOy7BEw/qI/Zy9WkHuQyNNpIjj5gjlq6bvrzoCDK6m9W4Bq+TscyS+e43NLr35mZQXHpoEXvjQsPoaI2UEhy6cjv8xgQ== jenkins@nomad-consul
    lock_passwd: false
    passwd: `$6`$rounds=4096`$salt`$hash

ssh_pwauth: true

network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - $TargetIP/24
      gateway4: $Gateway
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

runcmd:
  - systemctl enable ssh
  - systemctl restart ssh
  - ufw allow ssh
  - ufw --force enable
  - echo "VM $VmName is ready with IP $TargetIP" > /var/log/vm-ready.log
  - systemctl restart networking

final_message: "VM $VmName is ready with IP $TargetIP"
"@

$userData | Out-File -FilePath (Join-Path $cloudInitDir "user-data") -Encoding UTF8

# Create meta-data
$metaData = @"
instance-id: $VmName
local-hostname: $VmName
"@
$metaData | Out-File -FilePath (Join-Path $cloudInitDir "meta-data") -Encoding UTF8

Write-Host "✅ Cloud-init configuration created" -ForegroundColor Green
Write-Host "   User-data: $(Join-Path $cloudInitDir 'user-data')" -ForegroundColor Cyan
Write-Host "   Meta-data: $(Join-Path $cloudInitDir 'meta-data')" -ForegroundColor Cyan

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Attach the cloud-init ISO to the VM" -ForegroundColor White
Write-Host "2. Restart the VM to apply the configuration" -ForegroundColor White
Write-Host "3. Wait for cloud-init to configure networking" -ForegroundColor White
Write-Host "4. Test SSH connectivity" -ForegroundColor White

Write-Host "=== Configuration Complete ===" -ForegroundColor Green