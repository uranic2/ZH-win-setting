# Основные папки для очистки: пользовательские, системные, кэши видеокарт и эскизы
$tempFolders = @(
    "$env:TEMP\*",
    "C:\Windows\Temp\*",
    "$env:LOCALAPPDATA\D3DSCache\*",
    "$env:LOCALAPPDATA\NVIDIA\DXCache\*",
    "$env:LOCALAPPDATA\AMD\DxCache\*",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db"
)

$tempFolders | ForEach-Object {
    Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Временные файлы и кэш шейдеров успешно удалены!' -ForegroundColor Green
