@echo off
net session >nul 2>&1 || (powershell start -verb runas '%~f0' & exit /b)
net accounts /maxpwage:unlimited
pause
