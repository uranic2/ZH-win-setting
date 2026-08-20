#requires -version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Close all Chrome processes automatically. Unsaved browser work can be lost.
    [switch] $ForceCloseChrome
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$chromeUserData = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'

if (-not (Test-Path -LiteralPath $chromeUserData -PathType Container)) {
    Write-Host "Папка профилей Google Chrome не найдена: $chromeUserData"
    return
}

$chromeProcesses = @(Get-Process -Name chrome -ErrorAction SilentlyContinue)
if ($chromeProcesses.Count -gt 0) {
    if (-not $ForceCloseChrome) {
        throw "Google Chrome запущен. Закройте его и повторите команду либо добавьте -ForceCloseChrome."
    }

    if ($PSCmdlet.ShouldProcess('Google Chrome', 'принудительно закрыть все процессы')) {
        $chromeProcesses | Stop-Process -Force
        Start-Sleep -Milliseconds 750
    }
}

$profileDirectories = @(
    Get-ChildItem -LiteralPath $chromeUserData -Directory -Force |
        Where-Object {
            $_.Name -eq 'Default' -or
            $_.Name -match '^Profile \d+$' -or
            $_.Name -eq 'Guest Profile'
        }
)

if ($profileDirectories.Count -eq 0) {
    Write-Host 'Профили Google Chrome не найдены.'
    return
}

# Authentication/session stores only. History, bookmarks and extensions are retained.
$relativeTargets = @(
    'Login Data',
    'Login Data-journal',
    'Login Data For Account',
    'Login Data For Account-journal',
    'Web Data',
    'Web Data-journal',
    'Account Web Data',
    'Account Web Data-journal',
    'Cookies',
    'Cookies-journal',
    'Network\Cookies',
    'Network\Cookies-journal',
    'Network\Trust Tokens',
    'Network\Trust Tokens-journal',
    'Network\TransportSecurity'
)

$targets = foreach ($profile in $profileDirectories) {
    foreach ($relativeTarget in $relativeTargets) {
        $path = Join-Path $profile.FullName $relativeTarget
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Get-Item -LiteralPath $path -Force
        }
    }
}

$targets = @($targets | Sort-Object FullName -Unique)
if ($targets.Count -eq 0) {
    Write-Host 'Аутентификационные данные Chrome не найдены.'
    return
}

Write-Host "Будут удалены файлы аутентификации: $($targets.Count)"
$targets | Select-Object FullName, Length | Format-Table -AutoSize

$deleted = 0
foreach ($target in $targets) {
    if ($PSCmdlet.ShouldProcess($target.FullName, 'безвозвратно удалить')) {
        Remove-Item -LiteralPath $target.FullName -Force
        $deleted++
    }
}

Write-Host "Удалено файлов: $deleted"
if ($deleted -gt 0) {
    Write-Host 'При следующем запуске Chrome сайты потребуют повторный вход; сохранённые локально пароли удалены.'
    Write-Warning 'Если синхронизация Chrome включена, пароли могут снова загрузиться из аккаунта Google.'
}
