@echo off
echo Fixing PATH environment variable...
echo Adding C:\ProgramData\chocolatey\bin to PATH...

setx PATH "%PATH%;C:\ProgramData\chocolatey\bin" /M

echo PATH updated successfully!
echo Please restart your terminal for changes to take effect.
pause

