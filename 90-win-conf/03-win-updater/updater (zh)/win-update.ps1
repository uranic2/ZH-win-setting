# 1. БЛОКИРОВКА ЧЕРЕЗ РЕЕСТР (АНАЛОГ ГРУППОВОЙ ПОЛИТИКИ)
Write-Host "Блокировка автоматических обновлений в реестре..." -ForegroundColor Cyan
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "WindowsUpdate" -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "AU" -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path $RegistryPath -Name "NoAutoUpdate" -Value 1

# 2. ОТКЛЮЧЕНИЕ СЛУЖБЫ ЦЕНТРА ОБНОВЛЕНИЯ И ЗАПРЕТ НА РЕАНИМАЦИЮ (ЧЕРЕЗ РЕЕСТР)
Write-Host "Остановка службы и сброс действий при сбое..." -ForegroundColor Cyan
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Set-Service -Name "wuauserv" -StartupType Disabled

# Зануляем действия при сбое напрямую в реестре (эквивалент "Не предпринимать никаких действий")
$ServicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv"
Set-ItemProperty -Path $ServicePath -Name "FailureActions" -Value ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00))

# 3. ОТКЛЮЧЕНИЕ СКРЫТЫХ ЗАДАЧ ПЛАНИРОВЩИКА
Write-Host "Отключение триггеров в Планировщике задач..." -ForegroundColor Cyan
$Tasks = @(
    "Microsoft\Windows\WindowsUpdate\Scheduled Start",
    "Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
    "Microsoft\Windows\UpdateOrchestrator\ReportPolicies"
)

foreach ($Task in $Tasks) {
    $TaskName = $Task.Split("\")[-1]
    $TaskPath = $Task.Substring(0, $Task.LastIndexOf("\")) + "\"
    
    Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue | 
    Disable-ScheduledTask | Out-Null
}

Write-Host "Готово! Все механизмы обновления успешно заблокированы." -ForegroundColor Green
Write-Host "Для применения изменений рекомендуется перезагрузить компьютер." -ForegroundColor Yellow
