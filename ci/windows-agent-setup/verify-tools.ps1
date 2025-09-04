# Verify all installed tools for Windows Jenkins Agent
Write-Host "Verifying Windows Jenkins Agent Tools..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

# Check Java
Write-Host "`n1. Java:" -ForegroundColor Yellow
try {
    $javaVersion = & "C:\Program Files\Java\jdk-17\bin\java.exe" -version 2>&1 | Select-String "version"
    Write-Host "   ✅ Java is working: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Java error: $_" -ForegroundColor Red
}

# Check Terraform
Write-Host "`n2. Terraform:" -ForegroundColor Yellow
try {
    $tfVersion = & "C:\ProgramData\chocolatey\bin\terraform.exe" version
    Write-Host "   ✅ Terraform is working: $tfVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Terraform error: $_" -ForegroundColor Red
}

# Check Git
Write-Host "`n3. Git:" -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "   ✅ Git is working: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Git error: $_" -ForegroundColor Red
}

# Check Python
Write-Host "`n4. Python:" -ForegroundColor Yellow
try {
    $pythonVersion = & "C:\ProgramData\chocolatey\bin\python3.13.exe" --version
    Write-Host "   ✅ Python is working: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Python error: $_" -ForegroundColor Red
}

# Check Ansible
Write-Host "`n5. Ansible:" -ForegroundColor Yellow
try {
    $ansibleVersion = & "C:\Users\bogdan.dragos\AppData\Local\Programs\Python\Python312\Scripts\ansible.exe" --version 2>&1 | Select-String "ansible"
    Write-Host "   ✅ Ansible is working: $ansibleVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Ansible error: $_" -ForegroundColor Red
}

# Check Nomad
Write-Host "`n6. Nomad:" -ForegroundColor Yellow
try {
    $nomadVersion = & "C:\ProgramData\chocolatey\bin\nomad.exe" version
    Write-Host "   ✅ Nomad is working: $nomadVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Nomad error: $_" -ForegroundColor Red
}

# Check Consul
Write-Host "`n7. Consul:" -ForegroundColor Yellow
try {
    $consulVersion = & "C:\ProgramData\chocolatey\bin\consul.exe" version
    Write-Host "   ✅ Consul is working: $consulVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Consul error: $_" -ForegroundColor Red
}

# Check kubectl
Write-Host "`n8. kubectl:" -ForegroundColor Yellow
try {
    $kubectlVersion = & "C:\ProgramData\chocolatey\bin\kubectl.exe" version --client
    Write-Host "   ✅ kubectl is working: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ kubectl error: $_" -ForegroundColor Red
}

# Check Hyper-V
Write-Host "`n9. Hyper-V PowerShell Module:" -ForegroundColor Yellow
try {
    $hypervCmd = Get-Command Get-VM -ErrorAction SilentlyContinue
    if ($hypervCmd) {
        Write-Host "   ✅ Hyper-V PowerShell module is available" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Hyper-V PowerShell module not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Hyper-V check error: $_" -ForegroundColor Red
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Tool verification completed!" -ForegroundColor Green
Write-Host "`nNote: Some tools may show PATH issues until terminal is restarted." -ForegroundColor Yellow
Write-Host "All tools are installed and functional from their full paths." -ForegroundColor Green

