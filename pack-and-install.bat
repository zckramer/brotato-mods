@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack-and-install.ps1"
pause
