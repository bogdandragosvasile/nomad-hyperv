# Create a single test VM for experimentation
param(
    [string]$VhdBasePath = "C:\Hyper-V\VHDs",
    [string]$VmBasePath = "C:\Hyper-V\VMs",
    [string]$SwitchName = "NAT-Switch",
    [string]$VmName = "test-vm",
    [string]$VmIP = "192.168.1.200"
)

Write-Host "=== Creating Test VM: $VmName ===" -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

try {
    # Create VM directory
    $vmPath = Join-Path $VmBasePath $VmName
    if (-not (Test-Path $vmPath)) {
        New-Item -ItemType Directory -Path $vmPath -Force | Out-Null
        Write-Host "Created VM directory: $vmPath" -ForegroundColor Cyan
    }
    
    # Create VHD path
    $vhdPath = Join-Path $vmPath "$VmName.vhd"
    
    # Create VM
    Write-Host "Creating VM: $VmName" -ForegroundColor Yellow
    $vm = New-VM -Name $VmName -Path $vmPath -MemoryStartupBytes 2GB -Generation 2 -SwitchName $SwitchName
    
    # Create VHD from Ubuntu template
    $ubuntuVhd = Join-Path $VhdBasePath "livecd.ubuntu-cpc.azure.vhd"
    if (Test-Path $ubuntuVhd) {
        Write-Host "Copying Ubuntu VHD..." -ForegroundColor Yellow
        Copy-Item $ubuntuVhd $vhdPath
        Add-VMHardDiskDrive -VM $vm -Path $vhdPath
        Write-Host "VHD attached successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Ubuntu VHD not found at: $ubuntuVhd" -ForegroundColor Red
        exit 1
    }
    
    # Configure VM
    Write-Host "Configuring VM..." -ForegroundColor Yellow
    Set-VM -VM $vm -ProcessorCount 2
    Set-VMMemory -VM $vm -DynamicMemoryEnabled $false
    Set-VMFirmware -VM $vm -EnableSecureBoot Off
    
    # Start VM
    Write-Host "Starting VM..." -ForegroundColor Yellow
    Start-VM -VM $vm
    
    Write-Host "✅ Test VM '$VmName' created and started successfully!" -ForegroundColor Green
    Write-Host "   VM Path: $vmPath" -ForegroundColor Cyan
    Write-Host "   VHD Path: $vhdPath" -ForegroundColor Cyan
    Write-Host "   Expected IP: $VmIP" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Wait for VM to boot (2-3 minutes)" -ForegroundColor White
    Write-Host "2. Check VM IP address" -ForegroundColor White
    Write-Host "3. Test SSH connectivity" -ForegroundColor White
    Write-Host "4. Configure networking manually if needed" -ForegroundColor White
    
} catch {
    Write-Host "❌ Error creating test VM: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "=== Test VM Creation Complete ===" -ForegroundColor Green
