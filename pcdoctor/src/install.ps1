# Davan PC Doctor - install.ps1 (run by PCDoctor-Setup.cmd as admin, PC Thawed). Re-running repairs / updates; a reinstalled Windows is
# recognised by its hardware ("♻️ Known PC: PUC2") and gets its name, group, notes and settings back.
param([string]$Here = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Root = "$env:ProgramData\DavanPCDoctor"; $Raw = 'https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/pcdoctor/'
function Say($t, $c = 'Gray') { Write-Host ('  ' + $t) -ForegroundColor $c }
# 05-Nov-2026 (user: "setup takes long and does not show what it is doing"): numbered steps with the time so far; the deep first check and the
# MeshCentral agent are no longer inside the setup - the agent does both by itself in the background right after (about 2 minutes)
$T0 = Get-Date; $NS = 7
function Step($n, $t, $est) { Write-Host ''; Write-Host ("  [$n/$NS] $t") -ForegroundColor Cyan -NoNewline; Write-Host ("   (" + $est + ', ' + [int]((Get-Date) - $T0).TotalSeconds + ' s so far)') -ForegroundColor DarkGray }
Write-Host ''; Write-Host '  Davan PC Doctor - setup  (7 steps, usually under 1 minute)' -ForegroundColor Yellow
Step 1 'Checking Windows' 'a second'
$os = Get-CimInstance Win32_OperatingSystem
if ([int]$os.BuildNumber -lt 10240) { Say 'Windows 10 or 11 is needed.' Red; exit 1 }
if ($PSVersionTable.PSVersion.Major -lt 5) { Say 'PowerShell 5.1 is needed (Windows Update).' Red; exit 1 }
if (Get-Service DFServ -ErrorAction SilentlyContinue) { Say 'Deep Freeze found - this PC must be THAWED now, or the install is lost at the next restart.' Yellow }
New-Item -ItemType Directory -Force $Root, "$Root\bin", "$Root\setup", "$Root\state", "$Root\req", "$Root\log", "$Root\dl", "$Root\out", "$Root\good" | Out-Null
# files: newest from GitHub, SHA-256 checked against lab-version.json (offline: the src folder next to the installer)
Step 2 'Downloading PC Doctor' 'about 10-30 s'
$v = $null; try { $v = Invoke-RestMethod ($Raw + 'lab-version.json?t=' + [DateTime]::UtcNow.Ticks) -TimeoutSec 40 } catch {}
if ($v) {
  $fl = @($v.files.PSObject.Properties); $fi = 0
  Say ('version ' + $v.agent.ver + ' (build ' + $v.agent.build + ', ' + $v.agent.ist + ')')
  foreach ($f in $fl) { $o = "$Root\setup\" + $f.Name; $fi++; Say ("  ($fi/" + $fl.Count + ') ' + $f.Name)
    Invoke-WebRequest -UseBasicParsing ($Raw + 'src/' + $f.Name + '?v=' + $f.Value) -OutFile $o -TimeoutSec 120
    if ((Get-FileHash -Algorithm SHA256 $o).Hash.ToLower() -ne $f.Value) { Say "REFUSED $($f.Name) - its SHA-256 does not match" Red; exit 1 } }
  @{ ver = $v.agent.ver; build = $v.agent.build; at = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); prev = 0 } | ConvertTo-Json | Set-Content "$Root\state\running.json" -Encoding UTF8
} elseif ($Here -and (Test-Path "$Here\src\agent.ps1")) {
  # 1.32 offline install (pendrive: PCDoctor-Setup.cmd + the src folder from the Console's "Make offline install pendrive"): every file is
  # checked against the lab-version.json that came with it, then the same steps as online
  Say 'No internet - installing from the pendrive (src folder).' Yellow
  $lvf = "$Here\src\lab-version.json"; $lv = $null; try { $lv = Get-Content $lvf -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
  if ($lv -and $lv.files) { foreach ($f in $lv.files.PSObject.Properties) { $o = "$Here\src\" + $f.Name
      if (!(Test-Path $o) -or (Get-FileHash -Algorithm SHA256 $o).Hash.ToLower() -ne $f.Value) { Say "REFUSED $($f.Name) - missing or not the same as lab-version.json (make the pendrive again)" Red; exit 1 }
      Copy-Item $o "$Root\setup" -Force }
    @{ ver = $lv.agent.ver; build = $lv.agent.build; at = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); prev = 0 } | ConvertTo-Json | Set-Content "$Root\state\running.json" -Encoding UTF8
    Copy-Item $lvf "$Root\state\labver.json" -Force; Say ('version ' + $lv.agent.ver + ' (build ' + $lv.agent.build + ') from the pendrive') }
  else { Copy-Item "$Here\src\*.ps1" "$Root\setup" -Force; Copy-Item "$Here\src\notes.txt" "$Root\setup" -Force -ErrorAction SilentlyContinue } }
else { Say 'No internet - connect the PC and run again.' Red; exit 1 }
Copy-Item "$Root\setup\*.ps1" "$Root\bin" -Force; Copy-Item "$Root\setup\notes.txt" "$Root\bin" -Force -ErrorAction SilentlyContinue; Copy-Item "$Root\setup\loader.ps1" "$Root\loader.ps1" -Force
# rights: id.json (the per-PC key) only SYSTEM + Administrators; the tray (a normal user) reads state\ and writes requests to req\
icacls $Root /inheritance:r /grant:r 'SYSTEM:(OI)(CI)F' 'Administrators:(OI)(CI)F' 'Users:(OI)(CI)RX' /Q | Out-Null
icacls "$Root\req" /grant 'Users:(OI)(CI)M' /Q | Out-Null
. "$Root\bin\common.ps1"
Step 3 'Registering this PC with DB5' 'about 5 s'
$old = PD-LoadId
$r = $null; try { $r = PD-Register } catch { $r = $null; $em = $_.Exception.Message
  if ($em -match 'key does not match') { try { $r = PD-Register -New } catch { $em = $_.Exception.Message } } else { Say ('Could not register now (' + $em + ')') Yellow } }
if (!$r) { Say 'PC Doctor is installed; this PC registers by itself as soon as it has internet. Keep a Deep Freeze PC THAWED until it shows on the Console.' Yellow }
elseif ($r.known) { Say ("♻️ Known PC: " + $r.name + ' - its name, group, notes and history are kept') Green }
elseif ($r.merge) { Say ('New PC - looks like a known PC (same disk / RAM). The Console asks "Merge?"') Yellow }
else { Say ('New PC: ' + $env:COMPUTERNAME + ' (hwid ' + $r.hwid + ')') Green }
if (Test-Path "$Root\id.json") { icacls "$Root\id.json" /inheritance:r /grant:r 'SYSTEM:F' 'Administrators:F' /Q | Out-Null }
# a known PC whose Windows name differs -> give Windows its old name back (at the next restart)
if ($r -and $r.known -and $r.name -and $r.name -ne $env:COMPUTERNAME -and $r.name -match '^[A-Z0-9-]{1,15}$') { try { Rename-Computer -NewName $r.name -Force; Say ("Windows will be named " + $r.name + ' after the restart') Green } catch {} }
# service (Safe Mode too): a tiny service built HERE from C# source (no downloaded .exe) that keeps loader.ps1 running
Step 4 'Building the PC Doctor service (also runs in Safe Mode)' 'about 10 s'
# a re-run must not leave the OLD copies running (they hold their locks, so the new loader / tray would quit at once): stop them first
foreach ($pp in @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'DavanPCDoctor\\(loader|bin\\agent|bin\\tray)\.ps1' -and $_.ProcessId -ne $PID })) {
  try { Invoke-CimMethod -InputObject $pp -MethodName Terminate | Out-Null } catch {} }
$svcExe = "$Root\PCDoctorSvc.exe"
$cs = @'
using System; using System.Diagnostics; using System.ServiceProcess; using System.Threading;
public class PCDoctorSvc : ServiceBase {
  Process p; volatile bool stop;
  public PCDoctorSvc() { ServiceName = "PCDoctorSvc"; CanStop = true; CanShutdown = true; }
  protected override void OnStart(string[] a) { new Thread(Loop) { IsBackground = true }.Start(); }
  void Loop() { while (!stop) { try { if (p == null || p.HasExited) {
    var i = new ProcessStartInfo("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData) + "\\DavanPCDoctor\\loader.ps1\"");
    i.CreateNoWindow = true; i.UseShellExecute = false; p = Process.Start(i); } } catch { } Thread.Sleep(30000); } }
  protected override void OnStop() { stop = true; try { if (p != null && !p.HasExited) p.Kill(); } catch { } }
  protected override void OnShutdown() { OnStop(); }
  public static void Main() { ServiceBase.Run(new PCDoctorSvc()); }
}
'@
if (Get-Service PCDoctorSvc -ErrorAction SilentlyContinue) { Stop-Service PCDoctorSvc -Force -ErrorAction SilentlyContinue; sc.exe delete PCDoctorSvc | Out-Null; Start-Sleep 2 }
Remove-Item $svcExe -Force -ErrorAction SilentlyContinue
Add-Type -TypeDefinition $cs -ReferencedAssemblies System.ServiceProcess -OutputAssembly $svcExe -OutputType ConsoleApplication
sc.exe create PCDoctorSvc binPath= "`"$svcExe`"" start= auto DisplayName= "Davan PC Doctor Agent" | Out-Null
sc.exe description PCDoctorSvc "Davan PC Doctor Agent - lab health checks (davan-attendance/pcdoctor)" | Out-Null
sc.exe failure PCDoctorSvc reset= 86400 actions= restart/30000/restart/60000/restart/120000 | Out-Null
foreach ($m in 'Minimal','Network') { New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\$m\PCDoctorSvc" -Force | Out-Null; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\$m\PCDoctorSvc" '(default)' 'Service' }
# boot task (SYSTEM, before login) - a second way in; the loader's lock keeps one copy running
Step 5 'Boot task (starts PC Doctor before anyone logs in)' 'a second'
$act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Root\loader.ps1`""
$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 99 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable -Priority 7
Register-ScheduledTask -TaskName 'Davan PC Doctor' -Action $act -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings $set -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
# tray app for every user
Step 6 'Tray app (the 🖥️ icon, password 2531)' 'a second'
$trayVbs = PD-TrayLauncher   # wscript launcher: no console window (Windows 11 Terminal ignores -WindowStyle Hidden)
Step 7 'Starting PC Doctor' 'a few seconds'
Start-Service PCDoctorSvc
Start-ScheduledTask -TaskName 'Davan PC Doctor' -ErrorAction SilentlyContinue   # same loader (its lock keeps one copy)
Say 'The first full check (inventory + deep checks) and the remote-screen agent now run by themselves in the background.' DarkGray
Say 'This PC shows on the Console in about 2 minutes. Tray -> 🔍 Check now runs a deep check any time.' DarkGray
Start-Process wscript.exe -ArgumentList "`"$trayVbs`""
Write-Host ''; Say ('✅ Davan PC Doctor is installed on ' + $env:COMPUTERNAME + ' in ' + [int]((Get-Date) - $T0).TotalSeconds + ' s.' + $(if (Get-Service DFServ -ErrorAction SilentlyContinue) { ' Now set the PC back to Boot Frozen.' } else { '' })) Green; Write-Host ''
