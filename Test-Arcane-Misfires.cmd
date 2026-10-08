@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\start-arcane-test.ps1" %*
if errorlevel 1 pause
