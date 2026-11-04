@echo off
rem PC Doctor Rescue (ROADMAP-pcdoctor.md 9) - for the WinRE Command Prompt of a PC whose Windows does not start
rem (Troubleshoot -> Advanced options -> Command Prompt, then:  D:\DavanRescue.cmd  - the pendrive letter may differ).
rem Plain batch: WinRE has no PowerShell. Everything it does is written to the pendrive (DavanLab\Rescue_<PC>_<time>\rescue.log),
rem and the Console's Import reads that folder like a normal report.
setlocal enabledelayedexpansion
set "USB=%~d0"
set "W="
for %%d in (C D E F G H I J K L M N O P Q R S T U V Y Z) do if not defined W if exist "%%d:\Windows\System32\config\SYSTEM" if /i not "%%d:"=="%USB%" if /i not "%%d:"=="X:" set "W=%%d:"
if not defined W ( echo. & echo  No Windows found on this PC's disks. The disk may be dead or not connected - check the cable / BIOS. & pause & exit /b 1 )
set "PC=UNKNOWN"
reg load HKLM\DVSYS "%W%\Windows\System32\config\SYSTEM" >nul 2>&1
for /f "tokens=3" %%n in ('reg query "HKLM\DVSYS\ControlSet001\Control\ComputerName\ComputerName" /v ComputerName 2^>nul ^| find "ComputerName"') do set "PC=%%n"
reg unload HKLM\DVSYS >nul 2>&1
set "T=%date:~-4%-%date:~-7,2%-%date:~-10,2%_%time:~0,2%%time:~3,2%"
set "T=%T: =0%"
set "OUT=%USB%\DavanLab\Rescue_%PC%_%T%"
mkdir "%OUT%" >nul 2>&1
set "LOG=%OUT%\rescue.log"
echo PC Doctor Rescue - %PC% - Windows on %W% - %date% %time%>>"%LOG%"
:menu
cls
echo.
echo   ============ PC Doctor Rescue - %PC% (Windows on %W%) ============
echo.
echo     1  Collect everything to the pendrive (logs, crash files, PC Doctor data)
echo     2  Repair startup (boot files)
echo     3  Repair Windows files offline (sfc + DISM)
echo     4  Check disk (chkdsk)
echo     5  Undo the last update or driver
echo     0  Exit
echo.
set "c="
set /p c="   Choose 1-5 (0 = exit): "
if "%c%"=="1" goto collect
if "%c%"=="2" goto boot
if "%c%"=="3" goto sfc
if "%c%"=="4" goto chk
if "%c%"=="5" goto undo
if "%c%"=="0" goto end
goto menu
:collect
echo [1] collect>>"%LOG%"
mkdir "%OUT%\evtx" "%OUT%\dumps" "%OUT%\pcdoctor" "%OUT%\logs" >nul 2>&1
for %%l in (System Application Setup "Microsoft-Windows-Diagnostics-Performance%%4Operational" "Microsoft-Windows-PrintService%%4Admin" "Microsoft-Windows-Kernel-Power%%4Thermal-Operational") do copy /y "%W%\Windows\System32\winevt\Logs\%%~l.evtx" "%OUT%\evtx\" >nul 2>&1
copy /y "%W%\Windows\Minidump\*.dmp" "%OUT%\dumps\" >nul 2>&1
copy /y "%W%\Windows\LiveKernelReports\*.dmp" "%OUT%\dumps\" >nul 2>&1
copy /y "%W%\Windows\Logs\CBS\CBS.log" "%OUT%\logs\" >nul 2>&1
copy /y "%W%\Windows\INF\setupapi.dev.log" "%OUT%\logs\" >nul 2>&1
copy /y "%W%\Windows\System32\LogFiles\Srt\SrtTrail.txt" "%OUT%\logs\" >nul 2>&1
copy /y "%W%\Windows\Panther\setupact.log" "%OUT%\logs\" >nul 2>&1
xcopy /e /i /y /q "%W%\ProgramData\DavanPCDoctor\state" "%OUT%\pcdoctor\state" >nul 2>&1
copy /y "%W%\ProgramData\DavanPCDoctor\id.json" "%OUT%\pcdoctor\" >nul 2>&1
copy /y "%W%\ProgramData\DavanPCDoctor\log\*.log" "%OUT%\pcdoctor\" >nul 2>&1
for %%d in (C D E F G H I J K L M N O P Q R S T U V Y Z) do if exist "%%d:\DavanPCDoctor\queue.jsonl" copy /y "%%d:\DavanPCDoctor\queue.jsonl" "%OUT%\pcdoctor\" >nul 2>&1
dir /s /-c "%W%\Windows\Minidump" >"%OUT%\logs\dumps-list.txt" 2>&1
bcdedit /enum all >"%OUT%\logs\bcd.txt" 2>&1
echo list disk>"%TEMP%\dp.txt" & echo list volume>>"%TEMP%\dp.txt"
diskpart /s "%TEMP%\dp.txt" >"%OUT%\logs\disks.txt" 2>&1
echo   Saved to %OUT%
echo   collected to %OUT%>>"%LOG%"
pause & goto menu
:boot
echo [2] repair startup>>"%LOG%"
bootrec /fixmbr >>"%LOG%" 2>&1
bootrec /fixboot >>"%LOG%" 2>&1
bootrec /rebuildbcd >>"%LOG%" 2>&1
bcdboot %W%\Windows >>"%LOG%" 2>&1
echo   Done - see %LOG%. Restart and try Windows.
pause & goto menu
:sfc
echo [3] offline sfc + DISM>>"%LOG%"
sfc /scannow /offbootdir=%W%\ /offwindir=%W%\Windows >>"%LOG%" 2>&1
dism /Image:%W%\ /Cleanup-Image /RestoreHealth >>"%LOG%" 2>&1
echo   Done - see %LOG%.
pause & goto menu
:chk
echo [4] chkdsk %W% /f>>"%LOG%"
chkdsk %W% /f /x >>"%LOG%" 2>&1
echo   Done - see %LOG%.
pause & goto menu
:undo
echo [5] undo update / driver>>"%LOG%"
echo.
echo   a  Undo the update that is still installing (pending actions)
echo   b  Remove the newest Windows update package
echo   c  Remove a driver (list shown)
set "u="
set /p u="   a / b / c: "
if /i "%u%"=="a" dism /Image:%W%\ /Cleanup-Image /RevertPendingActions >>"%LOG%" 2>&1
if /i "%u%"=="b" (
  set "LAST="
  for /f "tokens=2 delims=:" %%p in ('dism /Image:%W%\ /Get-Packages ^| find "Package Identity" ^| find "RollupFix"') do set "LAST=%%p"
  if defined LAST ( echo   Removing!LAST! & dism /Image:%W%\ /Remove-Package /PackageName:!LAST: =! >>"%LOG%" 2>&1 ) else echo   No update package found.
)
if /i "%u%"=="c" (
  dism /Image:%W%\ /Get-Drivers /Format:Table
  set "d="
  set /p d="   Published name to remove (e.g. oem12.inf): "
  if defined d dism /Image:%W%\ /Remove-Driver /Driver:!d! >>"%LOG%" 2>&1
)
echo   Done - see %LOG%.
pause & goto menu
:end
echo end %time%>>"%LOG%"
endlocal
