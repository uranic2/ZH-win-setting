# 1. ОСТАНОВКА СЛУЖБ ОБНОВЛЕНИЙ
Write-Host "Остановка служб обновлений..." -ForegroundColor Cyan
$Services = @("wuauserv", "bits", "cryptsvc", "msiserver")
foreach ($Service in $Services) {
    Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
}

# 2. ОЧИСТКА ПАПОК С КЭШЕМ
Write-Host "Удаление временных файлов и кэша..." -ForegroundColor Cyan

# Сброс папки SoftwareDistribution
$SoftDistPath = "$env:SystemRoot\SoftwareDistribution"
if (Test-Path $SoftDistPath) {
    Remove-Item -Path $SoftDistPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Сброс папки Catroot2 (требует остановленной cryptsvc)
$Catroot2Path = "$env:SystemRoot\System32\catroot2"
if (Test-Path $Catroot2Path) {
    Remove-Item -Path $Catroot2Path -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. ЗАПУСК СЛУЖБ ОБРАТНО
Write-Host "Запуск служб..." -ForegroundColor Cyan
foreach ($Service in $Services) {
    Start-Service -Name $Service -ErrorAction SilentlyContinue
}

# 4. СБРОС СЕТЕВОГО КЭША И РЕГИСТРАЦИЯ
Write-Host "Принудительный вызов проверки обновлений..." -ForegroundColor Cyan
wuauclt /detectnow /updatenow

Write-Host "Готово! Кэш обновлений полностью очищен." -ForegroundColor Green
Write-Host "Рекомендуется открыть 'Центр обновления Windows' и нажать 'Проверить наличие обновлений'." -ForegroundColor Yellow
