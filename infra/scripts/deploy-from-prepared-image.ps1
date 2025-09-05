# Deploy VMs from prepared images
param(
    [string]$PreparedImagePath = "C:\Hyper-V\PreparedImages\ubuntu-nomad-consul-prepared.vhd",
    [string]$VmBasePath = "C:\Hyper-V\VMs",
    [string]$SwitchName = "NAT-Switch",
    [switch]$DestroyExisting = $false,
    [switch]$DryRun = $false
)

Write-Host "=== Deploying VMs from Prepared Image ===" -ForegroundColor Green
Write-Host "Prepared Image: $PreparedImagePath" -ForegroundColor Cyan
Write-Host "VM Base Path: $VmBasePath" -ForegroundColor Cyan
Write-Host "Switch Name: $SwitchName" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

# Check if prepared image exists
if (-not (Test-Path $PreparedImagePath)) {
    Write-Host "❌ Prepared image not found: $PreparedImagePath" -ForegroundColor Red
    Write-Host "Please run the image preparation pipeline first!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prepared image found" -ForegroundColor Green

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

# Function to destroy existing VMs
function Destroy-ExistingVMs {
    Write-Host "Destroying existing VMs..." -ForegroundColor Yellow
    
    foreach ($vmConfig in $vmConfigs) {
        $vm = Get-VM -Name $vmConfig.Name -ErrorAction SilentlyContinue
        if ($vm) {
            Write-Host "Destroying VM: $($vmConfig.Name)" -ForegroundColor Cyan
            if (-not $DryRun) {
                if ($vm.State -eq "Running") {
                    Stop-VM -Name $vmConfig.Name -Force -ErrorAction SilentlyContinue
                }
                Remove-VM -Name $vmConfig.Name -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Write-Host "✅ Existing VMs destroyed" -ForegroundColor Green
}

# Function to create VM from prepared image
function Create-VMFromPreparedImage {
    param([string]$VmName, [string]$IpAddress, [string]$Role)
    
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
            # Copy prepared image
            Write-Host "Copying prepared image..." -ForegroundColor Cyan
            Copy-Item $PreparedImagePath $vhdPath
            
            # Create VM
            Write-Host "Creating VM..." -ForegroundColor Cyan
            $vm = New-VM -Name $VmName -Path $vmPath -MemoryStartupBytes 2GB -Generation 2 -SwitchName $SwitchName
            
            # Attach VHD
            Write-Host "Attaching VHD..." -ForegroundColor Cyan
            Add-VMHardDiskDrive -VM $vm -Path $vhdPath
            
            # Configure VM
            Write-Host "Configuring VM..." -ForegroundColor Cyan
            Set-VM -VM $vm -ProcessorCount 2
            Set-VMMemory -VM $vm -DynamicMemoryEnabled $false
            Set-VMFirmware -VM $vm -EnableSecureBoot Off
            
            # Set boot order (hard drive first)
            $firmware = Get-VMFirmware -VM $vm
            $bootOrder = $firmware.BootOrder
            $driveBoot = $bootOrder | Where-Object { $_.BootType -eq 'Drive' }
            $fileBoot = $bootOrder | Where-Object { $_.BootType -eq 'File' }
            $networkBoot = $bootOrder | Where-Object { $_.BootType -eq 'Network' }
            $newBootOrder = @($driveBoot, $fileBoot, $networkBoot)
            Set-VMFirmware -VM $vm -BootOrder $newBootOrder
            
            # Start VM
            Write-Host "Starting VM..." -ForegroundColor Cyan
            Start-VM -VM $vm
            
            Write-Host "✅ VM $VmName created and started successfully!" -ForegroundColor Green
            Write-Host "   IP: $IpAddress" -ForegroundColor Cyan
            Write-Host "   Role: $Role" -ForegroundColor Cyan
        } else {
            Write-Host "🔍 DRY RUN: Would create VM $VmName with IP $IpAddress" -ForegroundColor Yellow
        }
        
        return $true
        
    } catch {
        Write-Host "❌ Error creating VM $VmName : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "Starting VM deployment from prepared image..." -ForegroundColor Green

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Destroy existing VMs if requested
if ($DestroyExisting) {
    Destroy-ExistingVMs
    Write-Host ""
}

# Create VMs
$successCount = 0
$totalCount = $vmConfigs.Count

foreach ($vmConfig in $vmConfigs) {
    $success = Create-VMFromPreparedImage -VmName $vmConfig.Name -IpAddress $vmConfig.IP -Role $vmConfig.Role
    if ($success) {
        $successCount++
    }
}

Write-Host ""
Write-Host "VM Deployment Summary:" -ForegroundColor Green
Write-Host "Successfully created: $successCount/$totalCount VMs" -ForegroundColor White

if ($successCount -eq $totalCount) {
    Write-Host "✅ All VMs created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Wait for VMs to boot and configure networking (2-3 minutes)" -ForegroundColor White
    Write-Host "2. Test SSH connectivity to VMs" -ForegroundColor White
    Write-Host "3. Run Ansible playbooks to configure Consul and Nomad" -ForegroundColor White
    Write-Host ""
    Write-Host "VM IP Addresses:" -ForegroundColor Cyan
    foreach ($vmConfig in $vmConfigs) {
        Write-Host "  $($vmConfig.Name): $($vmConfig.IP)" -ForegroundColor White
    }
} else {
    Write-Host "❌ Some VMs failed to create!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== VM Deployment Complete ===" -ForegroundColor Green
