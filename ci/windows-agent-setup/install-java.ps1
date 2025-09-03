# Install Java for Jenkins Windows Agent
# Run this script as Administrator

Write-Host "Installing Java for Jenkins Windows Agent..." -ForegroundColor Green

# Check if Java is already installed
if (Get-Command java -ErrorAction SilentlyContinue) {
    Write-Host "Java is already installed!" -ForegroundColor Yellow
    java -version
    exit 0
}

# Download OpenJDK 17
$javaUrl = "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_windows-x64_bin.zip"
$javaZip = "$env:TEMP\openjdk-17.zip"
$javaDir = "C:\Program Files\Java\jdk-17"

Write-Host "Downloading OpenJDK 17..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip

# Extract Java
Write-Host "Extracting Java..." -ForegroundColor Cyan
if (!(Test-Path "C:\Program Files\Java")) {
    New-Item -ItemType Directory -Path "C:\Program Files\Java" -Force
}
Expand-Archive -Path $javaZip -DestinationPath "C:\Program Files\Java" -Force

# Rename extracted folder
$extractedFolder = Get-ChildItem "C:\Program Files\Java" | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1
if ($extractedFolder) {
    Rename-Item -Path $extractedFolder.FullName -NewName "jdk-17" -Force
}

# Set environment variables
Write-Host "Setting environment variables..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaDir, "Machine")
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$javaDir\bin", "Machine")

# Clean up
Remove-Item $javaZip -Force

Write-Host "Java installation completed!" -ForegroundColor Green
Write-Host "Please restart your terminal or log out/in for PATH changes to take effect." -ForegroundColor Yellow
Write-Host "JAVA_HOME: $javaDir" -ForegroundColor Cyan
