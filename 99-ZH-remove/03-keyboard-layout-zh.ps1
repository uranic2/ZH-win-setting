$LayoutsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts"

function Find-KeyboardLayout {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $Layout = Get-ChildItem $LayoutsPath | Where-Object {
        (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).'Layout Text' -eq $Name
    } | Select-Object -First 1

    if (-not $Layout) {
        throw "Раскладка '$Name' не найдена среди установленных раскладок Windows."
    }

    return $Layout.PSChildName
}

$EnglishKlid = Find-KeyboardLayout "United States / EN ZH-60 v01"
$RussianKlid = Find-KeyboardLayout "Russian / RU ZH60 v01"

$Languages = New-WinUserLanguageList "en-US"
$Languages[0].InputMethodTips.Clear()
$Languages[0].InputMethodTips.Add("0409:$EnglishKlid")

$Russian = New-WinUserLanguageList "ru-RU"
$Russian[0].InputMethodTips.Clear()
$Russian[0].InputMethodTips.Add("0419:$RussianKlid")
$Languages.Add($Russian[0])

Set-WinUserLanguageList $Languages -Force
Set-WinDefaultInputMethodOverride -InputTip "0409:$EnglishKlid"

Write-Host "Готово. Оставлены только:"
Write-Host "United States / EN ZH-60 v01 — 0409:$EnglishKlid"
Write-Host "Russian / RU ZH60 v01 — 0419:$RussianKlid"