# Create Proper WinRM Certificate with IP SANs
# This script creates a certificate that includes both localhost and 127.0.0.1

Write-Host "=== Creating Proper WinRM Certificate with IP SANs ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Remove existing WinRM HTTPS listener
Write-Host "Removing existing WinRM HTTPS listener..." -ForegroundColor Yellow
try {
    winrm delete "winrm/config/Listener?Address=*+Transport=HTTPS"
    Write-Host "✅ Existing HTTPS listener removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  No existing HTTPS listener to remove" -ForegroundColor Yellow
}

# Remove old certificate
Write-Host "Removing old certificate..." -ForegroundColor Yellow
try {
    Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -eq "CN=localhost" } | Remove-Item -Force
    Write-Host "✅ Old certificate removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  No old certificate to remove" -ForegroundColor Yellow
}

# Create new certificate with proper SANs
Write-Host "Creating new certificate with IP SANs..." -ForegroundColor Yellow
try {
    $cert = New-SelfSignedCertificate -DnsName @("localhost", "127.0.0.1") -CertStoreLocation "Cert:\LocalMachine\My" -KeyUsage DigitalSignature, KeyEncipherment -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2")
    Write-Host "✅ New certificate created with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create certificate: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Add certificate to Trusted Root Certification Authorities
Write-Host "Adding certificate to Trusted Root Certification Authorities..." -ForegroundColor Yellow
try {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()
    Write-Host "✅ Certificate added to Trusted Root Certification Authorities" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to add certificate to trusted store: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Configure WinRM HTTPS listener with new certificate
Write-Host "Configuring WinRM HTTPS listener with new certificate..." -ForegroundColor Yellow
try {
    $listenerConfig = "@{Hostname=`"localhost`"; CertificateThumbprint=`"$($cert.Thumbprint)`"}"
    winrm create "winrm/config/Listener?Address=*+Transport=HTTPS" $listenerConfig
    Write-Host "✅ WinRM HTTPS listener configured with new certificate" -ForegroundColor Green
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

# Test with IP address
Write-Host "Testing WinRM HTTPS connectivity with IP address..." -ForegroundColor Yellow
try {
    $result = winrm identify -r:https://127.0.0.1:5986/wsman
    if ($result) {
        Write-Host "✅ WinRM HTTPS connectivity test with IP successful" -ForegroundColor Green
    } else {
        Write-Host "❌ WinRM HTTPS connectivity test with IP failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ WinRM HTTPS connectivity test with IP failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Show certificate details
Write-Host ""
Write-Host "Certificate Details:" -ForegroundColor Cyan
Write-Host "Subject: $($cert.Subject)" -ForegroundColor White
Write-Host "Issuer: $($cert.Issuer)" -ForegroundColor White
Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor White
Write-Host "Valid From: $($cert.NotBefore)" -ForegroundColor White
Write-Host "Valid To: $($cert.NotAfter)" -ForegroundColor White
Write-Host "DNS Names: $($cert.DnsNameList.Unicode)" -ForegroundColor White
Write-Host "IP Addresses: $($cert.IPAddressList.IPAddress)" -ForegroundColor White

Write-Host ""
Write-Host "🎉 Proper Certificate Setup Completed!" -ForegroundColor Green
Write-Host ""
Write-Host "The certificate now includes both localhost and 127.0.0.1" -ForegroundColor Cyan
Write-Host "The Hyper-V Terraform provider should now be able to connect without certificate errors!" -ForegroundColor Green
