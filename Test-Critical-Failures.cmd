@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\start-arcane-test.ps1" -CriticalFailures %*
if errorlevel 1 pause
