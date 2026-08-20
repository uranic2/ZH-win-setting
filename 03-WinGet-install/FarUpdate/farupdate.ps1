# ============================================================
# Скрипт обновления Far Manager
# Чуть больше чем полностью этот скрипт написан с помощью ИИ
# ============================================================

# 0. Резервное копирование настроек перед обновлением
$backupScript = "C:\USR\Zhukov\GDisk_uranic2\Conf\FAR\Far-save-setting.ps1"
if (Test-Path $backupScript) {
    Write-Host ">>> Запуск резервного копирования настроек..." -ForegroundColor Cyan
    try {
        & $backupScript
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Резервное копирование выполнено успешно." -ForegroundColor Green
        } else {
            Write-Warning "   Резервное копирование завершилось с кодом ошибки: $LASTEXITCODE"
        }
    } catch {
        Write-Warning "   Ошибка при выполнении бэкапа: $_"
    }
} else {
    Write-Warning "Скрипт бэкапа не найден: $backupScript"
}

# ============================================================
# 1. Определение параметров
# ============================================================
$repo = "FarGroup/FarManager"
$targetDir = "C:\WinApp\Far3"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
$tempDir = Join-Path $env:TEMP "FarUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Создаем временную папку для скачивания
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
}

# ============================================================
# 2. Получение информации о последнем релизе
# ============================================================
Write-Host ">>> Получение информации о последнем релизе..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell-Script" } -TimeoutSec 30
    $remoteVersion = $response.tag_name
    Write-Host "   Найдена версия: $remoteVersion" -ForegroundColor Green
} catch {
    Write-Error "Не удалось получить данные от GitHub API. Проверьте подключение к интернету."
    Write-Error "   Ошибка: $_"
    exit 1
}

# ============================================================
# 3. Проверка текущей установленной версии
# ============================================================
$versionFile = Join-Path $targetDir "version.txt"
if (Test-Path $versionFile) {
    # Используем -Raw для чтения всего файла, но потом удаляем пробелы и переводы строк
    $localVersion = (Get-Content $versionFile -Raw).Trim()
    
    # Удаляем префикс "ci/" если он есть, для сравнения только версии
    $localVersionClean = $localVersion -replace "^ci/", ""
    $remoteVersionClean = $remoteVersion -replace "^ci/", ""
    
    Write-Host "   Локальная версия: $localVersionClean" -ForegroundColor Gray
    Write-Host "   Удаленная версия: $remoteVersionClean" -ForegroundColor Gray
    
    if ($localVersionClean -eq $remoteVersionClean) {
        Write-Host "   Уже установлена последняя версия ($localVersionClean). Пропускаем обновление." -ForegroundColor Green
        Start-Sleep -Seconds 2
        exit 0
    } else {
        Write-Host "   Текущая версия: $localVersionClean. Доступно обновление до: $remoteVersionClean" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Файл версии не найден. Будет выполнено обновление." -ForegroundColor Yellow
}

# ============================================================
# 4. Поиск нужного файла в релизе
# ============================================================
Write-Host ">>> Поиск установочного архива..." -ForegroundColor Cyan
$asset = $response.assets | Where-Object { 
    $_.name -like "Far_*_x64_*.7z" -and 
    $_.name -notlike "*.pdb.7z" 
} | Select-Object -First 1

if (-not $asset) {
    Write-Error "Не удалось найти 64-битный архив (.7z) в последнем релизе."
    exit 1
}

$downloadUrl = $asset.browser_download_url
$archiveName = $asset.name
$archivePath = Join-Path $tempDir $archiveName

Write-Host "   Найден файл: $archiveName" -ForegroundColor Green
Write-Host "   Размер: $([math]::Round($asset.size / 1MB, 2)) MB"

# ============================================================
# 5. Скачивание архива
# ============================================================
Write-Host ">>> Скачивание архива..." -ForegroundColor Cyan
try {
    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -Headers @{ "User-Agent" = "PowerShell-Script" }
    $progressPreference = 'continue'
    Write-Host "   Файл успешно скачан: $archivePath" -ForegroundColor Green
} catch {
    Write-Error "Не удалось скачать файл. Ошибка: $_"
    exit 1
}

# ============================================================
# 6. Подготовка целевой директории
# ============================================================
if (!(Test-Path $targetDir)) {
    Write-Host ">>> Создание целевой директории: $targetDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
}

# ============================================================
# 7. Корректное завершение Far Manager
# ============================================================
Write-Host ">>> Закрытие работающих процессов far.exe..." -ForegroundColor Cyan
$farProcesses = Get-Process -Name "far" -ErrorAction SilentlyContinue
if ($farProcesses) {
    Write-Host "   Найдено процессов: $($farProcesses.Count)" -ForegroundColor Yellow
    Stop-Process -Name "far" -Force -ErrorAction SilentlyContinue
    # Даем время на закрытие
    Start-Sleep -Seconds 2
} else {
    Write-Host "   Far Manager не запущен." -ForegroundColor Green
}

# ============================================================
# 8. Распаковка архива с помощью 7-Zip
# ============================================================
Write-Host ">>> Распаковка архива в $targetDir..." -ForegroundColor Cyan

# Поиск 7-Zip в системе
$7zipPaths = @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe",
    (Get-Command 7z -ErrorAction SilentlyContinue).Source
)

$7zip = $7zipPaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($7zip) {
    Write-Host "   Используется 7-Zip: $7zip" -ForegroundColor Green
    try {
        & $7zip x $archivePath "-o$targetDir" -aoa -y | Out-Default
        if ($LASTEXITCODE -ne 0) {
            throw "7-Zip завершился с кодом ошибки: $LASTEXITCODE"
        }
        Write-Host "   Распаковка успешно завершена." -ForegroundColor Green
    } catch {
        Write-Error "Ошибка при распаковке: $_"
        exit 1
    }
} else {
    Write-Warning "7-Zip не найден в системе. Используем встроенный Expand-Archive..."
    try {
        Expand-Archive -Path $archivePath -DestinationPath $targetDir -Force
        Write-Host "   Распаковка успешно завершена." -ForegroundColor Green
    } catch {
        Write-Error "Ошибка при распаковке через Expand-Archive: $_"
        exit 1
    }
}

# ============================================================
# 9. Сохранение версии
# ============================================================
$remoteVersion | Out-File -FilePath $versionFile -Encoding utf8
Write-Host "   Версия сохранена: $remoteVersion" -ForegroundColor Green

# ============================================================
# 10. Очистка временных файлов
# ============================================================
Write-Host ">>> Очистка временных файлов..." -ForegroundColor Cyan
try {
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
        Write-Host "   Временный архив удален." -ForegroundColor Green
    }
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Force -ErrorAction SilentlyContinue
        Write-Host "   Временная папка удалена." -ForegroundColor Green
    }
} catch {
    Write-Warning "   Не удалось удалить временные файлы: $_"
}

# ============================================================
# 11. Запуск Far Manager
# ============================================================
Write-Host "`n>>> Обновление успешно завершено!" -ForegroundColor Green
Write-Host "   Версия: $remoteVersion" -ForegroundColor Green
Write-Host "   Путь: $targetDir" -ForegroundColor Green

# Проверяем наличие ярлыка
$shortcutPath = "C:\WinApp\Far3\Farr.lnk"
if (Test-Path $shortcutPath) {
    Write-Host "`nЗапуск Far Manager..." -ForegroundColor Cyan
    try {
        Invoke-Item $shortcutPath
        Write-Host "   Far Manager запущен." -ForegroundColor Green
    } catch {
        Write-Warning "   Не удалось запустить Far по ярлыку. Пробуем запустить far.exe..."
        $farExe = Join-Path $targetDir "far.exe"
        if (Test-Path $farExe) {
            Start-Process $farExe
            Write-Host "   Far Manager запущен." -ForegroundColor Green
        } else {
            Write-Warning "   Исполняемый файл не найден: $farExe"
        }
    }
} else {
    Write-Warning "   Ярлык не найден: $shortcutPath"
    $farExe = Join-Path $targetDir "far.exe"
    if (Test-Path $farExe) {
        Start-Process $farExe
        Write-Host "   Far Manager запущен." -ForegroundColor Green
    }
}

# ============================================================
# 12. Завершение
# ============================================================
Write-Host "`nСкрипт завершен." -ForegroundColor Cyan

if ($LASTEXITCODE -eq 0) {
    exit
} else {

    Read-Host "Нажмите Enter для выхода"
}