@echo off
rem SOMENTE para testar dentro de uma VM: lista tambem discos internos como "pendrive"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0clean-windows.ps1" -AllowFixedDisk
