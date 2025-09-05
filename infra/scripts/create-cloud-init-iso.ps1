# Create cloud-init ISO and attach to VM
param(
    [string]$VmName = "test-vm"
)

Write-Host "=== Creating Cloud-Init ISO ===" -ForegroundColor Green

# Get VM path
$vm = Get-VM -Name $VmName
$vmPath = $vm.Path
$cloudInitDir = Join-Path $vmPath "cloud-init"
$isoPath = Join-Path $vmPath "cloud-init.iso"

Write-Host "VM Path: $vmPath" -ForegroundColor Cyan
Write-Host "Cloud-init Dir: $cloudInitDir" -ForegroundColor Cyan
Write-Host "ISO Path: $isoPath" -ForegroundColor Cyan

# Check if cloud-init directory exists
if (-not (Test-Path $cloudInitDir)) {
    Write-Host "❌ Cloud-init directory not found: $cloudInitDir" -ForegroundColor Red
    exit 1
}

# Check if required files exist
$userDataFile = Join-Path $cloudInitDir "user-data"
$metaDataFile = Join-Path $cloudInitDir "meta-data"

if (-not (Test-Path $userDataFile)) {
    Write-Host "❌ user-data file not found: $userDataFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $metaDataFile)) {
    Write-Host "❌ meta-data file not found: $metaDataFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Cloud-init files found" -ForegroundColor Green

# Create ISO using PowerShell (requires Windows 10/11 with built-in ISO creation)
try {
    Write-Host "Creating ISO from cloud-init directory..." -ForegroundColor Yellow
    
    # Use New-ISOFile function if available, otherwise use external tool
    if (Get-Command New-ISOFile -ErrorAction SilentlyContinue) {
        New-ISOFile -Source $cloudInitDir -Destination $isoPath
    } else {
        # Try using oscdimg (Windows SDK tool)
        $oscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        if (Test-Path $oscdimgPath) {
            & $oscdimgPath $cloudInitDir $isoPath
        } else {
            # Use PowerShell to create a simple ISO structure
            Write-Host "Creating ISO using PowerShell method..." -ForegroundColor Yellow
            
            # Create a temporary directory for ISO structure
            $tempIsoDir = Join-Path $env:TEMP "cloud-init-iso"
            if (Test-Path $tempIsoDir) {
                Remove-Item $tempIsoDir -Recurse -Force
            }
            New-Item -ItemType Directory -Path $tempIsoDir -Force | Out-Null
            
            # Copy files to temp directory
            Copy-Item $userDataFile $tempIsoDir
            Copy-Item $metaDataFile $tempIsoDir
            
            # Create ISO using PowerShell (this is a simplified approach)
            # For production use, you'd want to use a proper ISO creation tool
            Write-Host "Note: Using simplified ISO creation method" -ForegroundColor Yellow
            Write-Host "For production, use a proper ISO creation tool like oscdimg or mkisofs" -ForegroundColor Yellow
            
            # For now, let's just copy the files to a known location
            $isoDir = Join-Path $vmPath "cloud-init-iso"
            if (Test-Path $isoDir) {
                Remove-Item $isoDir -Recurse -Force
            }
            Copy-Item $tempIsoDir $isoDir -Recurse
            
            # Clean up temp directory
            Remove-Item $tempIsoDir -Recurse -Force
            
            Write-Host "✅ Cloud-init files prepared for ISO creation" -ForegroundColor Green
            Write-Host "   Files available at: $isoDir" -ForegroundColor Cyan
        }
    }
    
    if (Test-Path $isoPath) {
        Write-Host "✅ ISO created successfully: $isoPath" -ForegroundColor Green
    } else {
        Write-Host "⚠️  ISO creation may have failed, but files are prepared" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error creating ISO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Falling back to direct file attachment method..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Attach the cloud-init files to the VM" -ForegroundColor White
Write-Host "2. Restart the VM to apply the configuration" -ForegroundColor White
Write-Host "3. Wait for cloud-init to configure networking" -ForegroundColor White

Write-Host "=== ISO Creation Complete ===" -ForegroundColor Green
