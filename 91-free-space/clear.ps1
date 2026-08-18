#При обновлении программ Windows сохраняет старые инсталляторы. Со временем папка C:\Windows\Installer забивается мусором.
DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
Write-Host 'старые инсталляторы успешно удалены!' -ForegroundColor Green

#Кэш оптимизации доставки (Delivery Optimization)
Delete-DeliveryOptimizationCache -Force -IncludePinnedFiles
Stop-Service -Name "DoSvc" -Force
Remove-Item -Path "$env:WINDIR\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name "DoSvc"

# 1. Удаление полных дампов памяти ядра (BSOD)
Remove-Item -Path "$env:SystemRoot\MEMORY.DMP" -Force -ErrorAction SilentlyContinue

# 2. Удаление минидампов (малых дампов ошибок)
Remove-Item -Path "$env:SystemRoot\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Удаление системных отчетов об ошибках (Windows Error Reporting)
Remove-Item -Path "$env:ALLUSERSPROFILE\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\CrashDumps\*" -Recurse -Force -ErrorAction SilentlyContinue


Write-Host 'Дампы и отчеты об ошибках успешно удалены!' -ForegroundColor Green

pnputil /delete-driver * /uninstall /force
Write-Host 'Старые драйвера успешно удалены!' -ForegroundColor Green

Remove-Item -Path "C:\Windows\Logs\CBS\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Логи системных компонентов (CBS Logs) успешно удалены!' -ForegroundColor Green


Remove-Item -Path "$env:LOCALAPPDATA\CrashDumps\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Логи сторонних программ (AppData\Local\CrashDumps) успешно удалены!' -ForegroundColor Green


