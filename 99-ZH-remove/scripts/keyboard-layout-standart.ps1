$Languages = New-WinUserLanguageList "en-US"
$Languages[0].InputMethodTips.Clear()
$Languages[0].InputMethodTips.Add("0409:00000409")

$Russian = New-WinUserLanguageList "ru-RU"
$Russian[0].InputMethodTips.Clear()
$Russian[0].InputMethodTips.Add("0419:00000419")
$Languages.Add($Russian[0])

Set-WinUserLanguageList $Languages -Force
Set-WinDefaultInputMethodOverride -InputTip "0409:00000409"