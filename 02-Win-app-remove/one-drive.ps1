Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait