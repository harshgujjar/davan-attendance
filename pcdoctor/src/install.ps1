# Davan PC Doctor - install.ps1 (run by PCDoctor-Setup.cmd as admin, PC Thawed). Re-running repairs / updates; a reinstalled Windows is
# recognised by its hardware ("♻️ Known PC: PUC2") and gets its name, group, notes and settings back.
param([string]$Here = '')
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Root = "$env:ProgramData\DavanPCDoctor"; $Raw = 'https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/pcdoctor/'
function Say($t, $c = 'Gray') { Write-Host ('  ' + $t) -ForegroundColor $c }
Write-Host ''; Write-Host '  Davan PC Doctor - setup' -ForegroundColor Yellow; Write-Host ''
$os = Get-CimInstance Win32_OperatingSystem
if ([int]$os.BuildNumber -lt 10240) { Say 'Windows 10 or 11 is needed.' Red; exit 1 }
if ($PSVersionTable.PSVersion.Major -lt 5) { Say 'PowerShell 5.1 is needed (Windows Update).' Red; exit 1 }
if (Get-Service DFServ -ErrorAction SilentlyContinue) { Say 'Deep Freeze found - this PC must be THAWED now, or the install is lost at the next restart.' Yellow }
New-Item -ItemType Directory -Force $Root, "$Root\bin", "$Root\setup", "$Root\state", "$Root\req", "$Root\log", "$Root\dl", "$Root\out", "$Root\good" | Out-Null
# files: newest from GitHub, SHA-256 checked against lab-version.json (offline: the src folder next to the installer)
Say 'Downloading PC Doctor ...'
$v = $null; try { $v = Invoke-RestMethod ($Raw + 'lab-version.json?t=' + [DateTime]::UtcNow.Ticks) -TimeoutSec 40 } catch {}
if ($v) {
  foreach ($f in $v.files.PSObject.Properties) { $o = "$Root\setup\" + $f.Name
    Invoke-WebRequest -UseBasicParsing ($Raw + 'src/' + $f.Name + '?v=' + $f.Value) -OutFile $o -TimeoutSec 120
    if ((Get-FileHash -Algorithm SHA256 $o).Hash.ToLower() -ne $f.Value) { Say "REFUSED $($f.Name) - its SHA-256 does not match" Red; exit 1 } }
  @{ ver = $v.agent.ver; build = $v.agent.build; at = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); prev = 0 } | ConvertTo-Json | Set-Content "$Root\state\running.json" -Encoding UTF8
} elseif ($Here -and (Test-Path "$Here\src\agent.ps1")) { Copy-Item "$Here\src\*.ps1" "$Root\setup" -Force }
else { Say 'No internet - connect the PC and run again.' Red; exit 1 }
Copy-Item "$Root\setup\*.ps1" "$Root\bin" -Force; Copy-Item "$Root\setup\loader.ps1" "$Root\loader.ps1" -Force
# rights: id.json (the per-PC key) only SYSTEM + Administrators; the tray (a normal user) reads state\ and writes requests to req\
icacls $Root /inheritance:r /grant:r 'SYSTEM:(OI)(CI)F' 'Administrators:(OI)(CI)F' 'Users:(OI)(CI)RX' /Q | Out-Null
icacls "$Root\req" /grant 'Users:(OI)(CI)M' /Q | Out-Null
. "$Root\bin\common.ps1"
Say 'Registering this PC with DB5 ...'
$old = PD-LoadId
$r = PD-Register
if ($r.known) { Say ("♻️ Known PC: " + $r.name + ' - its name, group, notes and history are kept') Green }
elseif ($r.merge) { Say ('New PC - looks like a known PC (same disk / RAM). The Console asks "Merge?"') Yellow }
else { Say ('New PC: ' + $env:COMPUTERNAME + ' (hwid ' + $r.hwid + ')') Green }
icacls "$Root\id.json" /inheritance:r /grant:r 'SYSTEM:F' 'Administrators:F' /Q | Out-Null
# a known PC whose Windows name differs -> give Windows its old name back (at the next restart)
if ($r.known -and $r.name -and $r.name -ne $env:COMPUTERNAME -and $r.name -match '^[A-Z0-9-]{1,15}$') { try { Rename-Computer -NewName $r.name -Force; Say ("Windows will be named " + $r.name + ' after the restart') Green } catch {} }
# service (Safe Mode too): a tiny service built HERE from C# source (no downloaded .exe) that keeps loader.ps1 running
Say 'Service (also runs in Safe Mode) ...'
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
Say 'Boot task ...'
$act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Root\loader.ps1`""
$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 99 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable -Priority 7
Register-ScheduledTask -TaskName 'Davan PC Doctor' -Action $act -Trigger (New-ScheduledTaskTrigger -AtStartup) -Settings $set -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
# tray app for every user
Say 'Tray app ...'
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' 'DavanPCDoctor' "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Root\bin\tray.ps1`""
# first full check + MeshCentral agent (remote screen)
Say 'First check (inventory, deep checks) - about a minute ...'
& powershell -NoProfile -ExecutionPolicy Bypass -File "$Root\bin\agent.ps1" -Mode once
Say 'Remote screen (MeshCentral agent) ...'
$m = & powershell -NoProfile -ExecutionPolicy Bypass -File "$Root\bin\agent.ps1" -Mode mesh; Say ([string]$m)
Start-Service PCDoctorSvc
Start-Process powershell.exe -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Root\bin\tray.ps1`""
Write-Host ''; Say ('✅ Davan PC Doctor is installed on ' + $env:COMPUTERNAME + '. Now set the PC back to Boot Frozen (if it has Deep Freeze).') Green; Write-Host ''
