@echo off
rem Deadlock Survivors: extract ALL Deadlock heroes from YOUR copy of the game (local only)
rem Options: extract.bat -Heroes haze,inferno   or   extract.bat -ListOnly
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\extract.ps1" %*
echo.
pause
