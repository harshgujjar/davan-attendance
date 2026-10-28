@echo off
rem Davan Dialer starter (put a shortcut to this file in shell:startup). Each start downloads the newest davan-dialer.ps1 and runs it;
rem when the script exits (new version published, or an error) it starts again after 10 s.
title Davan Dialer
cd /d "%~dp0"
:loop
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -Uri ('https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/tools/davan-dialer.ps1?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -OutFile '%~dp0davan-dialer.ps1' } catch { Write-Host 'offline - using the saved copy' }"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0davan-dialer.ps1"
timeout /t 10 /nobreak >nul
goto loop
