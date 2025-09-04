# Enable WinRM for Hyper-V Terraform Provider
# This script enables WinRM which is required for the Hyper-V Terraform provider

Write-Host "=== Enabling WinRM for Hyper-V Terraform Provider ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Enable WinRM service
Write-Host "Enabling WinRM service..." -ForegroundColor Yellow
Set-Service -Name "WinRM" -StartupType Automatic
Start-Service -Name "WinRM"
Write-Host "✅ WinRM service enabled and started" -ForegroundColor Green

# Configure WinRM for HTTPS
Write-Host "Configuring WinRM for HTTPS..." -ForegroundColor Yellow
try {
    # Create self-signed certificate
    $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"
    
    # Configure WinRM HTTPS listener
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"localhost`"; CertificateThumbprint=`"$($cert.Thumbprint)`"}"
    
    Write-Host "✅ WinRM HTTPS listener configured" -ForegroundColor Green
} catch {
    Write-Host "⚠️  WinRM HTTPS configuration failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Trying HTTP configuration instead..." -ForegroundColor Yellow
    
    # Configure WinRM HTTP listener as fallback
    try {
        winrm create winrm/config/Listener?Address=*+Transport=HTTP
        Write-Host "✅ WinRM HTTP listener configured" -ForegroundColor Green
    } catch {
        Write-Host "❌ WinRM HTTP configuration also failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Configure WinRM authentication
Write-Host "Configuring WinRM authentication..." -ForegroundColor Yellow
try {
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/client '@{AllowUnencrypted="true"}'
    winrm set winrm/config/client '@{TrustedHosts="*"}'
    Write-Host "✅ WinRM authentication configured" -ForegroundColor Green
} catch {
    Write-Host "❌ WinRM authentication configuration failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Configure Windows Firewall
Write-Host "Configuring Windows Firewall for WinRM..." -ForegroundColor Yellow
try {
    # Enable WinRM firewall rules
    Enable-NetFirewallRule -DisplayGroup "Windows Remote Management"
    Write-Host "✅ Windows Firewall configured for WinRM" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Windows Firewall configuration failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test WinRM connectivity
Write-Host "Testing WinRM connectivity..." -ForegroundColor Yellow
try {
    $result = winrm identify
    if ($result) {
        Write-Host "✅ WinRM connectivity test successful" -ForegroundColor Green
    } else {
        Write-Host "❌ WinRM connectivity test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ WinRM connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Show WinRM configuration
Write-Host ""
Write-Host "WinRM Configuration:" -ForegroundColor Cyan
winrm get winrm/config

Write-Host ""
Write-Host "🎉 WinRM Setup Completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart your computer if prompted" -ForegroundColor White
Write-Host "2. Run the Jenkins pipeline again with HYBRID_MODE=false" -ForegroundColor White
Write-Host ""
Write-Host "WinRM should now be accessible on:" -ForegroundColor Cyan
Write-Host "- HTTP: http://localhost:5985" -ForegroundColor White
Write-Host "- HTTPS: https://localhost:5986" -ForegroundColor White
