# Enable WinRM HTTPS for Hyper-V Terraform Provider
# This script enables HTTPS WinRM which is what the Terraform provider expects

Write-Host "=== Enabling WinRM HTTPS for Hyper-V Terraform Provider ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Create self-signed certificate for HTTPS
Write-Host "Creating self-signed certificate for HTTPS WinRM..." -ForegroundColor Yellow
try {
    $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"
    Write-Host "✅ Self-signed certificate created with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create certificate: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Configure WinRM HTTPS listener
Write-Host "Configuring WinRM HTTPS listener..." -ForegroundColor Yellow
try {
    $listenerConfig = "@{Hostname=`"localhost`"; CertificateThumbprint=`"$($cert.Thumbprint)`"}"
    winrm create "winrm/config/Listener?Address=*+Transport=HTTPS" $listenerConfig
    Write-Host "✅ WinRM HTTPS listener configured" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to configure HTTPS listener: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test WinRM HTTPS connectivity
Write-Host "Testing WinRM HTTPS connectivity..." -ForegroundColor Yellow
try {
    $result = winrm identify -r:https://localhost:5986/wsman
    if ($result) {
        Write-Host "✅ WinRM HTTPS connectivity test successful" -ForegroundColor Green
    } else {
        Write-Host "❌ WinRM HTTPS connectivity test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ WinRM HTTPS connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 WinRM HTTPS Setup Completed!" -ForegroundColor Green
Write-Host ""
Write-Host "WinRM is now accessible on:" -ForegroundColor Cyan
Write-Host "- HTTP: http://localhost:5985" -ForegroundColor White
Write-Host "- HTTPS: https://localhost:5986" -ForegroundColor White
Write-Host ""
Write-Host "The Hyper-V Terraform provider should now be able to connect!" -ForegroundColor Green

