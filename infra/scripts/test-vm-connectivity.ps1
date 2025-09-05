# Test VM connectivity and try different approaches
param(
    [string]$VmName = "test-vm",
    [string]$ExpectedIP = "192.168.1.200"
)

Write-Host "=== Testing VM Connectivity ===" -ForegroundColor Green
Write-Host "VM: $VmName" -ForegroundColor Cyan
Write-Host "Expected IP: $ExpectedIP" -ForegroundColor Cyan
Write-Host ""

# Check VM status
$vm = Get-VM -Name $VmName
Write-Host "VM State: $($vm.State)" -ForegroundColor Yellow
Write-Host "Current IPs: $($vm.NetworkAdapters[0].IPAddresses -join ', ')" -ForegroundColor Yellow

# Test different IP ranges
Write-Host ""
Write-Host "Testing connectivity to various IP addresses..." -ForegroundColor Yellow

$testIPs = @(
    "192.168.1.200",  # Expected IP
    "192.168.1.100",  # Common DHCP range start
    "192.168.1.101",  # Common DHCP range
    "192.168.1.102",  # Common DHCP range
    "192.168.1.50",   # Common DHCP range
    "192.168.1.10",   # Common DHCP range
    "192.168.1.1"     # Gateway
)

foreach ($ip in $testIPs) {
    Write-Host "Testing $ip..." -ForegroundColor Cyan
    try {
        $pingResult = Test-NetConnection -ComputerName $ip -Port 22 -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($pingResult) {
            Write-Host "✅ $ip:22 is accessible!" -ForegroundColor Green
            Write-Host "   This might be our VM!" -ForegroundColor Green
        } else {
            Write-Host "❌ $ip:22 is not accessible" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ $ip:22 connection failed" -ForegroundColor Red
    }
}

# Test SSH with different credentials
Write-Host ""
Write-Host "Testing SSH connectivity with different credentials..." -ForegroundColor Yellow

$testCredentials = @(
    @{User="ubuntu"; Password="ubuntu"},
    @{User="ubuntu"; Password=""},
    @{User="root"; Password="ubuntu"},
    @{User="admin"; Password="admin"}
)

foreach ($cred in $testCredentials) {
    Write-Host "Testing SSH with user: $($cred.User), password: $($cred.Password)" -ForegroundColor Cyan
    # Note: This would require SSH client tools
    Write-Host "   (SSH testing requires additional tools)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "1. Check Hyper-V console to see VM boot status" -ForegroundColor White
Write-Host "2. Try to access VM console and configure networking manually" -ForegroundColor White
Write-Host "3. Consider using a different Ubuntu image with pre-configured networking" -ForegroundColor White
Write-Host "4. Use cloud-init with proper ISO attachment" -ForegroundColor White

Write-Host "=== Connectivity Test Complete ===" -ForegroundColor Green