# ============================================================
# Очистка данных Яндекс Браузера
#
# Режимы:
#   1 - удалить только историю
#   2 - удалить историю + сохраненные пароли
#   3 - удалить историю + пароли + cookies + автозаполнение + кеш
#   4 - полностью удалить все локальные профили Яндекс Браузера
#
# ВАЖНО:
#   Режим 4 удаляет также закладки, расширения и настройки профилей.
# ============================================================

$UserDataPath = Join-Path $env:LOCALAPPDATA "Yandex\YandexBrowser\User Data"

function Remove-PathSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (Test-Path -LiteralPath $Path) {
        try {
            Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction Stop
            Write-Host "  [OK] $Description" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ОШИБКА] $Description" -ForegroundColor Red
            Write-Host "           $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

function Remove-ProfileFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfilePath,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $Path = Join-Path $ProfilePath $RelativePath
    Remove-PathSafe -Path $Path -Description $Description
}


Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Очистка данных Яндекс Браузера" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $UserDataPath)) {
    Write-Host "Папка Яндекс Браузера не найдена:" -ForegroundColor Red
    Write-Host $UserDataPath
    exit 1
}

Write-Host "Выберите режим:"
Write-Host ""
Write-Host "  1 - удалить только историю"
Write-Host "  2 - удалить историю + сохраненные пароли"
Write-Host "  3 - удалить историю + пароли + cookies + автозаполнение + кеш"
Write-Host "  4 - ПОЛНОСТЬЮ удалить все локальные профили Яндекс Браузера"
Write-Host ""

$Mode = Read-Host "Введите 1, 2, 3 или 4"

if ($Mode -notin @("1", "2", "3", "4")) {
    Write-Host ""
    Write-Host "Неверный режим." -ForegroundColor Red
    exit 1
}


# ------------------------------------------------------------
# Дополнительное подтверждение для полного удаления
# ------------------------------------------------------------

if ($Mode -eq "4") {

    Write-Host ""
    Write-Host "ВНИМАНИЕ!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Будут удалены ВСЕ локальные профили Яндекс Браузера,"
    Write-Host "включая:"
    Write-Host ""
    Write-Host "  - историю"
    Write-Host "  - пароли"
    Write-Host "  - cookies"
    Write-Host "  - закладки"
    Write-Host "  - расширения"
    Write-Host "  - настройки"
    Write-Host "  - автозаполнение"
    Write-Host "  - кеш"
    Write-Host ""

    $Confirm = Read-Host 'Для продолжения введите DELETE'

    if ($Confirm -ne "DELETE") {
        Write-Host ""
        Write-Host "Операция отменена." -ForegroundColor Yellow
        exit 0
    }
}


# ------------------------------------------------------------
# Закрываем Яндекс Браузер
# ------------------------------------------------------------

Write-Host ""
Write-Host "Закрываю Яндекс Браузер..." -ForegroundColor Cyan

$Processes = Get-Process -ErrorAction SilentlyContinue |
    Where-Object {
        $_.ProcessName -eq "browser" -or
        $_.ProcessName -like "yandex*"
    }

if ($Processes) {
    $Processes | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Write-Host "Готово."
Write-Host ""


# ============================================================
# РЕЖИМ 4
# Полностью удаляем User Data
# ============================================================

if ($Mode -eq "4") {

    Write-Host "Полное удаление локальных профилей..." -ForegroundColor Cyan

    try {
        Remove-Item -LiteralPath $UserDataPath -Recurse -Force -ErrorAction Stop

        Write-Host ""
        Write-Host "Все локальные данные Яндекс Браузера удалены." -ForegroundColor Green
        Write-Host ""
        Write-Host "При следующем запуске браузер создаст новый профиль."
    }
    catch {
        Write-Host ""
        Write-Host "Не удалось удалить папку:" -ForegroundColor Red
        Write-Host $UserDataPath
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }

    exit
}


# ------------------------------------------------------------
# Ищем профили
# ------------------------------------------------------------

$Profiles = Get-ChildItem -LiteralPath $UserDataPath -Directory -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -eq "Default" -or
        $_.Name -match '^Profile \d+$'
    }

if (-not $Profiles) {
    Write-Host "Профили Яндекс Браузера не найдены." -ForegroundColor Yellow
    exit 0
}


Write-Host "Найдено профилей: $($Profiles.Count)" -ForegroundColor Cyan
Write-Host ""


foreach ($Profile in $Profiles) {

    Write-Host "----------------------------------------------"
    Write-Host "Профиль: $($Profile.Name)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------"


    # ========================================================
    # ИСТОРИЯ
    # ========================================================

    Remove-ProfileFile `
        -ProfilePath $Profile.FullName `
        -RelativePath "History" `
        -Description "История посещений"

    Remove-ProfileFile `
        -ProfilePath $Profile.FullName `
        -RelativePath "History-journal" `
        -Description "Журнал истории"

    Remove-ProfileFile `
        -ProfilePath $Profile.FullName `
        -RelativePath "Archived History" `
        -Description "Архив истории"

    Remove-ProfileFile `
        -ProfilePath $Profile.FullName `
        -RelativePath "Archived History-journal" `
        -Description "Журнал архива истории"


    # ========================================================
    # ПАРОЛИ
    # ========================================================

    if ($Mode -in @("2", "3")) {

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Login Data" `
            -Description "Сохраненные логины и пароли"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Login Data-journal" `
            -Description "Журнал паролей"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Login Data For Account" `
            -Description "Пароли аккаунта"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Login Data For Account-journal" `
            -Description "Журнал паролей аккаунта"
    }


    # ========================================================
    # РЕЖИМ 3
    # ========================================================

    if ($Mode -eq "3") {

        # Cookies

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Network\Cookies" `
            -Description "Cookies"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Network\Cookies-journal" `
            -Description "Журнал Cookies"


        # Старое расположение cookies

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Cookies" `
            -Description "Cookies (старое расположение)"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Cookies-journal" `
            -Description "Журнал Cookies (старое расположение)"


        # Автозаполнение

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Web Data" `
            -Description "Автозаполнение форм"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Web Data-journal" `
            -Description "Журнал автозаполнения"


        # Кеш

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Cache" `
            -Description "Кеш"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Code Cache" `
            -Description "Code Cache"

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "GPUCache" `
            -Description "GPU Cache"


        # Service Worker Cache

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Service Worker\CacheStorage" `
            -Description "Service Worker Cache"


        # Session Storage

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Session Storage" `
            -Description "Session Storage"


        # Local Storage
        #
        # ВНИМАНИЕ:
        # Это может разлогинить пользователя на сайтах.
        # Закладки и расширения не удаляются.

        Remove-ProfileFile `
            -ProfilePath $Profile.FullName `
            -RelativePath "Local Storage" `
            -Description "Local Storage"
    }

    Write-Host ""
}


# ------------------------------------------------------------
# Результат
# ------------------------------------------------------------

Write-Host "==============================================" -ForegroundColor Cyan

switch ($Mode) {

    "1" {
        Write-Host "Удалена история посещений." -ForegroundColor Green
    }

    "2" {
        Write-Host "Удалены история и локально сохраненные пароли." -ForegroundColor Green
    }

    "3" {
        Write-Host "Удалены:" -ForegroundColor Green
        Write-Host "  - история"
        Write-Host "  - пароли"
        Write-Host "  - cookies"
        Write-Host "  - автозаполнение"
        Write-Host "  - кеш"
        Write-Host "  - данные локального хранения сайтов"
        Write-Host ""
        Write-Host "Закладки, расширения и основные настройки профиля сохранены."
    }
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Нажмите Enter для завершения..."
Read-Host