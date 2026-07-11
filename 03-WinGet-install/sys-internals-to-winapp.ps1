# 1. Принудительно включаем TLS 1.2 (чтобы загрузка не обрывалась)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Удаляем старый поврежденный файл, если он остался
Remove-Item -Path "$env:TEMP\SysinternalsSuite-Nano.zip" -Force -ErrorAction SilentlyContinue

# 3. Скачиваем ПРАВИЛЬНЫЙ ZIP-архив утилит
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/SysinternalsSuite-Nano.zip" -OutFile "$env:TEMP\SysinternalsSuite-Nano.zip"

# 4. Распаковываем утилиты в вашу папку C:\WinApp\SysInternals
Expand-Archive -Path "$env:TEMP\SysinternalsSuite-Nano.zip" -DestinationPath "C:\WinApp\SysInternals" -Force
