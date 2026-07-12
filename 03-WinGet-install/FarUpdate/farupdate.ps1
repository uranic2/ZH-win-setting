# 1. Скачивание архива
Invoke-WebRequest -Uri "https://www.farmanager.com/nightly/Far30b6712.x64.20260711.7z" -OutFile "$env:TEMP\far.7z"

# 2. Создание целевой директории, если её нет
if (!(Test-Path "c:\WinApp\Far3")) { New-Item -ItemType Directory -Force -Path "c:\WinApp\Far3" }

Expand-7ZipArchive -Path "$env:TEMP\far.7z" -DestinationPath "c:\WinApp\Far3"

# 3. Распаковка архива с помощью встроенной утилиты tar
tar -xf "$env:TEMP\far.7z" -C "c:\WinApp\Far3"

# 4. Очистка временного файла
Remove-Item "$env:TEMP\far.7z" -Force
