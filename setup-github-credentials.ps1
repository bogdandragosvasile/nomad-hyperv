# GitHub Credentials Setup Script for Jenkins
# This script will help you set up GitHub credentials for Jenkins

Write-Host "=== GitHub Credentials Setup for Jenkins ===" -ForegroundColor Green
Write-Host ""

# Check if GitHub token is provided
$githubToken = Read-Host "Please enter your GitHub Personal Access Token"

if ([string]::IsNullOrEmpty($githubToken)) {
    Write-Host "Error: GitHub token is required!" -ForegroundColor Red
    Write-Host "Please create a Personal Access Token at: https://github.com/settings/tokens" -ForegroundColor Yellow
    Write-Host "Required scopes: repo, read:org" -ForegroundColor Yellow
    exit 1
}

# Update the credentials XML file
$credentialsXml = @"
<?xml version='1.1' encoding='UTF-8'?>
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github</id>
  <description>GitHub credentials for nomad-hyperv repository</description>
  <username>bogdandragosvasile</username>
  <password>$githubToken</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
"@

# Write the credentials file
$credentialsXml | Out-File -FilePath "github-credentials.xml" -Encoding UTF8

Write-Host "✅ Credentials XML file created!" -ForegroundColor Green

# Import credentials to Jenkins
Write-Host "Importing credentials to Jenkins..." -ForegroundColor Yellow
$result = Get-Content "github-credentials.xml" | & "C:\Program Files\Java\jdk-17\bin\java.exe" -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:admin create-credentials-by-xml system::system::jenkins _

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ GitHub credentials successfully imported to Jenkins!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to import credentials. Error: $result" -ForegroundColor Red
    exit 1
}

# Verify credentials were created
Write-Host "Verifying credentials..." -ForegroundColor Yellow
$verifyResult = & "C:\Program Files\Java\jdk-17\bin\java.exe" -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:admin list-credentials-as-xml system::system::jenkins

if ($verifyResult -match "github") {
    Write-Host "✅ GitHub credentials verified in Jenkins!" -ForegroundColor Green
} else {
    Write-Host "❌ GitHub credentials not found in Jenkins!" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item "github-credentials.xml" -Force

Write-Host ""
Write-Host "🎉 GitHub credentials setup completed successfully!" -ForegroundColor Green
Write-Host "You can now run Jenkins pipelines that access your private repository." -ForegroundColor Cyan
