# Trust WinRM Self-Signed Certificate
# This script adds the self-signed certificate to the trusted store

Write-Host "=== Trusting WinRM Self-Signed Certificate ===" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green

# Find the WinRM certificate
Write-Host "Finding WinRM self-signed certificate..." -ForegroundColor Yellow
try {
    $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -eq "CN=localhost" -and $_.Issuer -eq "CN=localhost" } | Select-Object -First 1
    
    if ($cert) {
        Write-Host "✅ Found WinRM certificate with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
    } else {
        Write-Host "❌ WinRM certificate not found. Creating new one..." -ForegroundColor Yellow
        $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"
        Write-Host "✅ Created new certificate with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to find or create certificate: $($_.Exception.Message)" -ForegroundColor Red
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

# Add certificate to Trusted People store
Write-Host "Adding certificate to Trusted People store..." -ForegroundColor Yellow
try {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()
    Write-Host "✅ Certificate added to Trusted People store" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to add certificate to Trusted People store: $($_.Exception.Message)" -ForegroundColor Red
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

# Show certificate details
Write-Host ""
Write-Host "Certificate Details:" -ForegroundColor Cyan
Write-Host "Subject: $($cert.Subject)" -ForegroundColor White
Write-Host "Issuer: $($cert.Issuer)" -ForegroundColor White
Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor White
Write-Host "Valid From: $($cert.NotBefore)" -ForegroundColor White
Write-Host "Valid To: $($cert.NotAfter)" -ForegroundColor White

Write-Host ""
Write-Host "🎉 Certificate Trust Setup Completed!" -ForegroundColor Green
Write-Host ""
Write-Host "The self-signed certificate is now trusted by the system." -ForegroundColor Cyan
Write-Host "The Hyper-V Terraform provider should now be able to connect without certificate errors!" -ForegroundColor Green

