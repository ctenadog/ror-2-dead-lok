@echo off
rem Deadlock Survivors: build and install into Risk of Rain 2 (no Melty)
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\install.ps1"
echo.
pause
