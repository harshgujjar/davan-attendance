@echo off
rem Davan Caller - ONE start for the laptop (put a shortcut to this file in shell:startup).
rem Opens the voice page in Edge, then runs the dialer minimised: each start downloads the newest davan-dialer.ps1;
rem when the script exits (new version published, or an error) it starts again after 10 s.
if not "%~1"=="min" (start "Davan Caller" /min cmd /c ""%~f0" min" & exit /b)
title Davan Caller (keep open)
cd /d "%~dp0"
start "" msedge "https://harshgujjar.github.io/davan-attendance/caller-voice.html"
:loop
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -UseBasicParsing -Uri ('https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/tools/davan-dialer.ps1?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -OutFile '%~dp0davan-dialer.ps1' } catch { Write-Host 'offline - using the saved copy' }"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0davan-dialer.ps1"
timeout /t 10 /nobreak >nul
goto loop
