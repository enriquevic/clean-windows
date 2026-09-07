@echo off
rem Prepara o kit nesta maquina: desbloqueia os arquivos e cria o CleanWindows.exe
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0preparar.ps1" %*
