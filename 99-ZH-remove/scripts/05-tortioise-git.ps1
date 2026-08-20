# ============================================================
# Очистка сохраненных учетных данных TortoiseGit / Git
# Windows 10 / 11
# ============================================================

Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Очистка паролей TortoiseGit / Git" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Будут проверены:"
Write-Host "  - Windows Credential Manager"
Write-Host "  - ~/.git-credentials"
Write-Host "  - ~/_netrc"
Write-Host "  - ~/.netrc"
Write-Host ""

$Confirm = Read-Host "Продолжить? (Y/N)"

if ($Confirm -notin @("Y", "y")) {
    Write-Host "Операция отменена." -ForegroundColor Yellow
    exit 0
}


# ============================================================
# 1. Windows Credential Manager
# ============================================================

Write-Host ""
Write-Host "Поиск Git credentials в Windows Credential Manager..." `
    -ForegroundColor Cyan

try {

    $CredentialList = cmdkey /list

    $Targets = @()

    foreach ($Line in $CredentialList) {

        if ($Line -match '^\s*Target:\s*(.+)$') {

            $Target = $Matches[1].Trim()

            # Типичные записи Git Credential Manager
            if (
                $Target -match '(?i)git:' -or
                $Target -match '(?i)github' -or
                $Target -match '(?i)gitlab' -or
                $Target -match '(?i)bitbucket'
            ) {
                $Targets += $Target
            }
        }
    }


    if ($Targets.Count -eq 0) {

        Write-Host "  Git credentials не найдены." `
            -ForegroundColor DarkGray

    }
    else {

        foreach ($Target in $Targets) {

            Write-Host "  Удаляю: $Target"

            cmdkey /delete:"$Target" | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "    [OK]" -ForegroundColor Green
            }
            else {
                Write-Host "    [ОШИБКА]" -ForegroundColor Red
            }
        }
    }

}
catch {

    Write-Host "Ошибка при работе с Credential Manager:" `
        -ForegroundColor Red

    Write-Host $_.Exception.Message
}


# ============================================================
# 2. ~/.git-credentials
# ============================================================

$GitCredentials = Join-Path $HOME ".git-credentials"

Write-Host ""
Write-Host "Проверка .git-credentials..." -ForegroundColor Cyan

if (Test-Path -LiteralPath $GitCredentials) {

    try {

        Remove-Item `
            -LiteralPath $GitCredentials `
            -Force `
            -ErrorAction Stop

        Write-Host "  [OK] Удалено: $GitCredentials" `
            -ForegroundColor Green
    }
    catch {

        Write-Host "  [ОШИБКА] $($_.Exception.Message)" `
            -ForegroundColor Red
    }

}
else {

    Write-Host "  Файл не найден." `
        -ForegroundColor DarkGray
}


# ============================================================
# 3. _netrc
# ============================================================

$Netrc = Join-Path $HOME "_netrc"

Write-Host ""
Write-Host "Проверка _netrc..." -ForegroundColor Cyan

if (Test-Path -LiteralPath $Netrc) {

    try {

        Remove-Item `
            -LiteralPath $Netrc `
            -Force `
            -ErrorAction Stop

        Write-Host "  [OK] Удалено: $Netrc" `
            -ForegroundColor Green
    }
    catch {

        Write-Host "  [ОШИБКА] $($_.Exception.Message)" `
            -ForegroundColor Red
    }

}
else {

    Write-Host "  Файл не найден." `
        -ForegroundColor DarkGray
}


# ============================================================
# 4. .netrc
# ============================================================

$DotNetrc = Join-Path $HOME ".netrc"

Write-Host ""
Write-Host "Проверка .netrc..." -ForegroundColor Cyan

if (Test-Path -LiteralPath $DotNetrc) {

    try {

        Remove-Item `
            -LiteralPath $DotNetrc `
            -Force `
            -ErrorAction Stop

        Write-Host "  [OK] Удалено: $DotNetrc" `
            -ForegroundColor Green
    }
    catch {

        Write-Host "  [ОШИБКА] $($_.Exception.Message)" `
            -ForegroundColor Red
    }

}
else {

    Write-Host "  Файл не найден." `
        -ForegroundColor DarkGray
}


# ============================================================
# Результат
# ============================================================

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Очистка завершена" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "При следующем обращении по HTTPS Git/TortoiseGit"
Write-Host "может снова запросить логин и пароль."
Write-Host ""

Read-Host "Нажмите Enter для завершения"