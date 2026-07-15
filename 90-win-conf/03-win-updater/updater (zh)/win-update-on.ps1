# 1. ОТКАТ ИЗМЕНЕНИЙ В РЕЕСТРЕ (УДАЛЕНИЕ БЛОКИРОВКИ)
Write-Host "Восстановление параметров обновления в реестре..." -ForegroundColor Cyan
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (Test-Path $RegistryPath) {
    Remove-ItemProperty -Path $RegistryPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
}

# 2. ВОССТАНОВЛЕНИЕ СЛУЖБЫ ЦЕНТРА ОБНОВЛЕНИЯ И ДЕФОЛТНЫХ ДЕЙСТВИЙ ПРИ СБОЕ
Write-Host "Включение службы wuauserv и восстановление триггеров сбоя..." -ForegroundColor Cyan
Set-Service -Name "wuauserv" -StartupType Automatic

# Восстановление стандартного бинарного значения FailureActions для службы wuauserv
$ServicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv"
$DefaultFailureActions = [byte[]](0x14,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x14,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x60,0xea,0x00,0x00,0x01,0x00,0x00,0x00,0x60,0xea,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)
Set-ItemProperty -Path $ServicePath -Name "FailureActions" -Value $DefaultFailureActions -ErrorAction SilentlyContinue

# Запуск службы
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

# 3. ВКЛЮЧЕНИЕ ЗАДАЧ В ПЛАНИРОВЩИКЕ
Write-Host "Включение задач в Планировщике..." -ForegroundColor Cyan
$Tasks = @(
    "Microsoft\Windows\WindowsUpdate\Scheduled Start",
    "Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
    "Microsoft\Windows\UpdateOrchestrator\ReportPolicies"
)

foreach ($Task in $Tasks) {
    $TaskName = $Task.Split("\")[-1]
    $TaskPath = $Task.Substring(0, $Task.LastIndexOf("\")) + "\"
    
    Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue | 
    Enable-ScheduledTask | Out-Null
}

Write-Host "Готово! Все механизмы обновления успешно восстановлены." -ForegroundColor Green
Write-Host "Обязательно перезагрузите компьютер для применения изменений." -ForegroundColor Yellow
