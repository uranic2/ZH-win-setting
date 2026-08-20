@echo off
reg delete "HKCU\Software\OpenVPN-GUI\configs" /f
echo Готово! Все сохраненные пароли OpenVPN GUI успешно удалены.
pause