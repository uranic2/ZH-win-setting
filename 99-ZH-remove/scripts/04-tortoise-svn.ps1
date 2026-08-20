# ============================================================
# Очистка сохраненных учетных данных TortoiseSVN / Subversion
# ============================================================

$AuthPath = Join-Path $env:APPDATA "Subversion\auth"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Очистка паролей TortoiseSVN" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Каталог авторизации:"
Write-Host $AuthPath
Write-Host ""

if (-not (Test-Path -LiteralPath $AuthPath)) {
    Write-Host "Кэш авторизации Subversion не найден." -ForegroundColor Yellow
    Write-Host "Удалять нечего."
    exit 0
}

$Confirm = Read-Host "Удалить все сохраненные SVN-пароли и учетные данные? (Y/N)"

if ($Confirm -notin @("Y", "y")) {
    Write-Host "Операция отменена." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Удаление учетных данных..." -ForegroundColor Cyan

try {

    # Удаляем содержимое auth, но оставляем сам каталог
    Get-ChildItem -LiteralPath $AuthPath -Force -ErrorAction Stop |
        Remove-Item -Recurse -Force -ErrorAction Stop

    Write-Host ""
    Write-Host "[OK] Кэш авторизации SVN очищен." -ForegroundColor Green
    Write-Host ""
    Write-Host "При следующем обращении к репозиторию"
    Write-Host "TortoiseSVN снова запросит логин и пароль."
}
catch {

    Write-Host ""
    Write-Host "[ОШИБКА] Не удалось очистить кэш." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
}

Write-Host ""
Read-Host "Нажмите Enter для завершения"