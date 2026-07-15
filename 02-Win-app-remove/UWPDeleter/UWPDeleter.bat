@echo off

rem Фикс, если запущено из Terminal UWP
	tasklist /fi "imagename eq WindowsTerminal.exe" 2>nul | find /i "WindowsTerminal" >nul && (
		for %%p in (DelegationConsole DelegationTerminal) do reg add "HKCU\Console\%%%%Startup" /v "%%p" /t REG_SZ /d "{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}" /f >nul
		echo. && echo  Restarting with cmd .. && timeout /t 3 /nobreak >nul && start "" "%~f0" && exit
	)
	
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0script.ps1"
