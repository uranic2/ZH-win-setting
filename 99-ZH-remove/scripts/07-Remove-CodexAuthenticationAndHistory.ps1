#requires -version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Close the Codex desktop app and CLI processes automatically.
    [switch] $ForceCloseCodex
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$codexHome = if ($env:CODEX_HOME) {
    [System.IO.Path]::GetFullPath($env:CODEX_HOME)
}
else {
    Join-Path $env:USERPROFILE '.codex'
}

if (-not (Test-Path -LiteralPath $codexHome -PathType Container)) {
    Write-Host "Каталог данных Codex не найден: $codexHome"
    return
}

$currentPid = $PID
$codexProcesses = @(
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Id -ne $currentPid -and
            ($_.ProcessName -eq 'ChatGPT' -or $_.ProcessName -match '^codex($|-.*)')
        }
)

if ($codexProcesses.Count -gt 0) {
    if (-not $ForceCloseCodex) {
        throw 'Codex запущен. Полностью закройте приложение и повторите команду либо добавьте -ForceCloseCodex.'
    }

    if ($PSCmdlet.ShouldProcess('Codex', 'принудительно закрыть все процессы')) {
        $codexProcesses | Stop-Process -Force
        Start-Sleep -Milliseconds 1000
    }
}

# Prefer the supported logout command when it is available. It also handles a
# system credential store selected by the Codex authentication configuration.
$codexCommand = Get-Command codex -ErrorAction SilentlyContinue
if ($null -ne $codexCommand -and $PSCmdlet.ShouldProcess('Codex authentication', 'выполнить codex logout')) {
    & $codexCommand.Source logout
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Команда 'codex logout' завершилась с кодом $LASTEXITCODE; локальный auth.json всё равно будет удалён."
    }
}

$literalTargets = @(
    'auth.json',
    'sessions',
    'archived_sessions',
    'session_index.jsonl',
    'thread-writer-locks',
    'dictation-history',
    'transcription-history.jsonl',
    'realtime-voice-continuity.json',
    'ambient-suggestions',
    'computer-use',
    'sqlite',
    '.codex-global-state.json',
    '.codex-global-state.json.bak'
)

$targets = foreach ($relativePath in $literalTargets) {
    $path = Join-Path $codexHome $relativePath
    if (Test-Path -LiteralPath $path) {
        Get-Item -LiteralPath $path -Force
    }
}

# These databases contain task state, request/response logs, and queued work.
$databasePatterns = @(
    'state_*.sqlite*',
    'logs_*.sqlite*',
    'queue_*.sqlite*'
)

foreach ($pattern in $databasePatterns) {
    $targets += @(Get-ChildItem -LiteralPath $codexHome -Filter $pattern -Force -ErrorAction SilentlyContinue)
}

# Remove abandoned temporary copies of the global state as well.
$targets += @(
    Get-ChildItem -LiteralPath $codexHome -Filter '..codex-global-state.json.tmp-*' -Force -ErrorAction SilentlyContinue
)

$targets = @($targets | Sort-Object FullName -Unique)
if ($targets.Count -eq 0) {
    Write-Host 'Локальные данные аутентификации и истории Codex не найдены.'
    return
}

Write-Host "Каталог Codex: $codexHome"
Write-Host "Будут удалены объектов: $($targets.Count)"
$targets | Select-Object FullName, PSIsContainer, Length | Format-Table -AutoSize

$deleted = 0
foreach ($target in $targets) {
    $action = if ($target.PSIsContainer) {
        'безвозвратно удалить каталог со всем содержимым'
    }
    else {
        'безвозвратно удалить файл'
    }

    if ($PSCmdlet.ShouldProcess($target.FullName, $action)) {
        Remove-Item -LiteralPath $target.FullName -Force -Recurse
        $deleted++
    }
}

Write-Host "Удалено объектов: $deleted"
if ($deleted -gt 0) {
    Write-Host 'Локальная авторизация и история Codex удалены. При следующем запуске потребуется войти снова.'
    Write-Warning 'Удаление локальных данных не удаляет облачную историю или данные аккаунта OpenAI.'
}

