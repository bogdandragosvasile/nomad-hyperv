# Simple VM Creation Script
param(
    [string]$VhdBasePath = "C:\Hyper-V\VHDs",
    [string]$VmBasePath = "C:\Hyper-V\VMs",
    [string]$SwitchName = "NAT-Switch",
    [switch]$DestroyExisting = $false,
    [switch]$DryRun = $false
)

Write-Host "=== Creating Hyper-V VMs ===" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

# VM configurations
$vmConfigs = @(
    @{Name="consul-server-1"; IP="192.168.1.100"},
    @{Name="consul-server-2"; IP="192.168.1.101"},
    @{Name="consul-server-3"; IP="192.168.1.102"},
    @{Name="nomad-server-1"; IP="192.168.1.103"},
    @{Name="nomad-server-2"; IP="192.168.1.104"},
    @{Name="nomad-server-3"; IP="192.168.1.105"},
    @{Name="nomad-client-1"; IP="192.168.1.106"},
    @{Name="nomad-client-2"; IP="192.168.1.107"},
    @{Name="nomad-client-3"; IP="192.168.1.108"}
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
}

# Function to create VM
function Create-VM {
    param([string]$VmName, [string]$IpAddress)
    
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
            
            # Disable Secure Boot
            Set-VMFirmware -VM $vm -EnableSecureBoot Off
            
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
if ($DestroyExisting) {
    Destroy-ExistingVMs
    Write-Host ""
}

$successCount = 0
$totalCount = $vmConfigs.Count

foreach ($vmConfig in $vmConfigs) {
    $success = Create-VM -VmName $vmConfig.Name -IpAddress $vmConfig.IP
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
    Write-Host "Note: VMs are created but may need manual network configuration" -ForegroundColor Yellow
    Write-Host "The Ubuntu cloud image may not automatically configure networking" -ForegroundColor Yellow
} else {
    Write-Host "Some VMs failed to create!" -ForegroundColor Red
}

Write-Host "=== VM Creation Complete ===" -ForegroundColor Green

