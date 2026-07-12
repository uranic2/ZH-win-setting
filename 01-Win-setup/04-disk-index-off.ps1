# 1. Укажите букву диска
$DriveLetter = "C"

# 2. Отключение индексации на уровне тома
$Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter='$($DriveLetter):'"
if ($Drive) {
    Set-CimInstance -InputObject $Drive -Property @{IndexingEnabled = $false}
    Write-Host "Индексация тома $($DriveLetter): отключена." -ForegroundColor Green
}

# 3. Безопасный рекурсивный обход без мусорных ошибок
Write-Host "Применение настроек к файлам (защищенные папки будут пропущены)..." -ForegroundColor Yellow

# Глобально глушим вывод ошибок на время выполнения
$OldErrorAction = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

Get-ChildItem -Path "$($DriveLetter):\" -Recurse -Force | ForEach-Object {
    try {
        # Проверяем, что объект существует и к нему есть базовый доступ
        if ($_.Attributes -and (-not ($_.Attributes -band [System.IO.FileAttributes]::NotContentIndexed))) {
            $_.Attributes = $_.Attributes -bor [System.IO.FileAttributes]::NotContentIndexed
        }
    } catch {
        # Сюда попадут файлы, заблокированные процессами, они просто пропустятся
    }
}

# Возвращаем настройки ошибок обратно
$ErrorActionPreference = $OldErrorAction
Write-Host "Процесс завершен!" -ForegroundColor Green


# Остановка службы и её полное отключение в автозагрузке
Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
Set-Service -Name "WSearch" -StartupType Disabled

Write-Host "Служба поиска и индексации Windows Search полностью отключена." -ForegroundColor Green
