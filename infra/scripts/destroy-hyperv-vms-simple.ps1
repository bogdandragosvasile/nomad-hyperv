# Simple VM Destruction Script
param(
    [switch]$DryRun = $false
)

Write-Host "=== Destroying Hyper-V VMs ===" -ForegroundColor Red

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    exit 1
}

# VM names to destroy
$vmNames = @(
    "consul-server-1", "consul-server-2", "consul-server-3",
    "nomad-server-1", "nomad-server-2", "nomad-server-3",
    "nomad-client-1", "nomad-client-2", "nomad-client-3"
)

$successCount = 0
$totalCount = $vmNames.Count

foreach ($vmName in $vmNames) {
    Write-Host "Processing VM: $vmName" -ForegroundColor Yellow
    
    try {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host "VM $vmName not found (already destroyed)" -ForegroundColor Green
            $successCount++
            continue
        }
        
        Write-Host "Found VM: $vmName (State: $($vm.State))" -ForegroundColor Cyan
        
        if (-not $DryRun) {
            # Stop VM if running
            if ($vm.State -eq "Running") {
                Write-Host "Stopping VM: $vmName" -ForegroundColor Cyan
                Stop-VM -Name $vmName -Force
                Start-Sleep -Seconds 5
            }
            
            # Remove VM
            Write-Host "Removing VM: $vmName" -ForegroundColor Cyan
            Remove-VM -Name $vmName -Force
            
            Write-Host "VM $vmName destroyed successfully" -ForegroundColor Green
        } else {
            Write-Host "DRY RUN: Would destroy VM $vmName" -ForegroundColor Yellow
        }
        
        $successCount++
        
    } catch {
        Write-Host "Error destroying VM $vmName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "VM Destruction Summary:" -ForegroundColor Red
Write-Host "Successfully destroyed: $successCount/$totalCount VMs" -ForegroundColor White

if ($successCount -eq $totalCount) {
    Write-Host "All VMs destroyed successfully!" -ForegroundColor Green
} else {
    Write-Host "Some VMs failed to destroy!" -ForegroundColor Red
}

Write-Host "=== VM Destruction Complete ===" -ForegroundColor Red

