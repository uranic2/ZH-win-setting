# 1. ВОССТАНОВЛЕНИЕ ЦЕЛОСТНОСТИ СИСТЕМНЫХ ФАЙЛОВ И ОБРАЗА WINDOWS
Write-Host "1/3 Проверка и восстановление хранилища компонентов (DISM)..." -ForegroundColor Cyan
Write-Host "Это может занять несколько минут. Не закрывайте окно." -ForegroundColor DarkGray
# Сканирует образ Windows на наличие повреждений и автоматически восстанавливает их через сеть
DISM.exe /Online /Cleanup-Image /RestoreHealth

Write-Host "`n2/3 Проверка целостности системных файлов (SFC)..." -ForegroundColor Cyan
# Сканирует все защищенные системные файлы и заменяет поврежденные версии правильными копиями Microsoft
sfc /scannow

# 2. ЗАПУСК ВСТРОЕННОГО УСТРАНЕНИЯ НЕПОЛАДОК ЦЕНТРА ОБНОВЛЕНИЙ
Write-Host "`n3/3 Запуск встроенной утилиты диагностики Windows Update..." -ForegroundColor Cyan
# Автоматически открывает стандартный графический мастер устранения неполадок обновлений
msdt.exe /id WindowsUpdateDiagnostic

Write-Host "`nДиагностика завершена!" -ForegroundColor Green
Write-Host "Если утилиты DISM/SFC нашли ошибки, обязательно перезагрузите ПК." -ForegroundColor Yellow
