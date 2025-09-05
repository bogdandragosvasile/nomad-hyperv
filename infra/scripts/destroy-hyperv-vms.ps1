# Destroy Hyper-V VMs
# This script destroys all VMs created for the Nomad-Consul cluster

param(
    [string]$VmBasePath = "C:\Hyper-V\VMs",
    [switch]$DryRun = $false
)

Write-Host "=== Destroying Hyper-V VMs ===" -ForegroundColor Red
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# VM names to destroy
$vmNames = @(
    "consul-server-1", "consul-server-2", "consul-server-3",
    "nomad-server-1", "nomad-server-2", "nomad-server-3",
    "nomad-client-1", "nomad-client-2", "nomad-client-3"
)

# Function to destroy a single VM
function Destroy-VM {
    param([string]$VmName)
    
    Write-Host "Destroying VM: $VmName" -ForegroundColor Yellow
    
    try {
        $vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "VM $VmName not found (already destroyed)" -ForegroundColor Green
            return $true
        }
        
        Write-Host "Found VM: $VmName (State: $($vm.State))" -ForegroundColor Cyan
        
        if (-not $DryRun) {
            # Stop VM if running
            if ($vm.State -eq "Running") {
                Write-Host "Stopping VM: $VmName" -ForegroundColor Cyan
                Stop-VM -Name $VmName -Force
                
                # Wait for VM to stop
                $timeout = 30
                $elapsed = 0
                while ((Get-VM -Name $VmName).State -ne "Off" -and $elapsed -lt $timeout) {
                    Start-Sleep -Seconds 2
                    $elapsed += 2
                }
                
                if ((Get-VM -Name $VmName).State -ne "Off") {
                    Write-Host "Warning: VM $VmName did not stop gracefully" -ForegroundColor Yellow
                }
            }
            
            # Remove VM
            Write-Host "Removing VM: $VmName" -ForegroundColor Cyan
            Remove-VM -Name $VmName -Force
            
            # Remove VM directory and files
            $vmPath = Join-Path $VmBasePath $VmName
            if (Test-Path $vmPath) {
                Write-Host "Removing VM directory: $vmPath" -ForegroundColor Cyan
                Remove-Item -Path $vmPath -Recurse -Force
            }
            
            Write-Host "✅ VM $VmName destroyed successfully" -ForegroundColor Green
        } else {
            Write-Host "🔍 DRY RUN: Would destroy VM $VmName" -ForegroundColor Yellow
        }
        
        return $true
        
    } catch {
        Write-Host "❌ Error destroying VM $VmName : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "Starting VM destruction process..." -ForegroundColor Red

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

$successCount = 0
$totalCount = $vmNames.Count

foreach ($vmName in $vmNames) {
    $success = Destroy-VM -VmName $vmName
    if ($success) {
        $successCount++
    }
}

Write-Host ""
Write-Host "VM Destruction Summary:" -ForegroundColor Red
Write-Host "Successfully destroyed: $successCount/$totalCount VMs" -ForegroundColor White

if ($successCount -eq $totalCount) {
    Write-Host "✅ All VMs destroyed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Some VMs failed to destroy!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== VM Destruction Complete ===" -ForegroundColor Red

