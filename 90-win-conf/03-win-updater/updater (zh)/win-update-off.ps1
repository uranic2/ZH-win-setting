# 1. БЛОКИРОВКА ЧЕРЕЗ REЕСТР (Windows Update + Дополнительные ключи)
Write-Host "Блокировка автоматических обновлений в реестре..." -ForegroundColor Cyan
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "WindowsUpdate" -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "AU" -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path $RegistryPath -Name "NoAutoUpdate" -Value 1
Set-ItemProperty -Path $RegistryPath -Name "AUOptions" -Value 2 # Только уведомлять о загрузке

# 2. ПОЛНОЕ ОТКЛЮЧЕНИЕ СЛУЖБ ЧЕРЕЗ РЕЕСТР (wuauserv, medic, orchestrator)
Write-Host "Остановка и жесткое отключение служб обновления..." -ForegroundColor Cyan

$Services = @("wuauserv", "WaaSMedicSvc", "UsoSvc")
foreach ($Service in $Services) {
    Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
    # Меняем тип запуска на "Отключено" (4) напрямую в реестре, обходя защиту Windows
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" -Name "Start" -Value 4 -ErrorAction SilentlyContinue
}

# Обнуляем действия при сбое для всех трех служб
foreach ($Service in $Services) {
    $ServicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\$Service"
    Set-ItemProperty -Path $ServicePath -Name "FailureActions" -Value ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
}

