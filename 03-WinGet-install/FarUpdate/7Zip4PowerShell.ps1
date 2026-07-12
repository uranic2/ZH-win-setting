# 1. Принудительная тихая установка провайдера NuGet без запроса подтверждения
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# 2. Добавление доверия к репозиторию (чтобы не было вопросов о ненадежном источнике)
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# 3. Тихая установка самого модуля 7Zip4PowerShell
Install-Module -Name 7Zip4PowerShell -Force -Scope AllUsers
