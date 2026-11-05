@echo off
rem Davan PC Doctor - one installer (ROADMAP-pcdoctor.md 6). Right-click -> Run as administrator, with the PC THAWED (Deep Freeze),
rem about 2 minutes. Asks nothing: the group comes from the PC's name (A5 = Lab 1, PUC2 = PUC office ...). Windows 10 + 11.
title Davan PC Doctor - setup
net session >nul 2>&1 || (echo. & echo  Please right-click PCDoctor-Setup.cmd and choose "Run as administrator". & echo. & pause & exit /b 1)
echo.
echo  Davan PC Doctor - setup is starting ...
echo  Getting the newest installer from GitHub (a few seconds) - the steps show below.
set "U=https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/pcdoctor/src/install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; $f=\"$env:TEMP\pd_install.ps1\"; try { Invoke-WebRequest -UseBasicParsing ('%U%?t='+[DateTime]::UtcNow.Ticks) -OutFile $f } catch { if (Test-Path '%~dp0src\install.ps1') { Copy-Item '%~dp0src\install.ps1' $f } else { Write-Host 'No internet and no src folder next to this file.'; exit 1 } }; & $f -Here '%~dp0'"
echo.
pause