# Davan PC Doctor Agent - agent.ps1 (ROADMAP-pcdoctor.md 4-9). Started by loader.ps1 (service / boot task, SYSTEM), lowest priority.
# Every minute: one row to DB5 (lab/live + lab/now), new Windows events, commands; every 5 min: peer ping + queue; every hour: settings,
# verdict, auto-fixes; once a day: inventory + deep checks. Writes state\hb.txt every minute (the loader rolls back a silent version).
param([string]$Mode = 'run')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\common.ps1"; . "$here\checks.ps1"; . "$here\fixes.ps1"; . "$here\dlh.ps1"
try { [Diagnostics.Process]::GetCurrentProcess().PriorityClass = 'Idle' } catch {}
$mtx = New-Object Threading.Mutex($false, 'Global\DavanPCDoctorAgent')
if ($Mode -eq 'run' -and !$mtx.WaitOne(0)) { exit 0 }   # the service and the boot task both start it - only one runs

$S = @{ ring = New-Object System.Collections.ArrayList; lastEv = $null; lastMin = [datetime]::MinValue; last5 = [datetime]::MinValue; lastHour = [datetime]::MinValue
        lastDay = ''; verdict = $null; pc = $null; ev7 = @(); inv = $null; boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; dfSince = 0; usbSeen = @{}; hangs = @{}
        peers = @{}; laptop = $false; doneCmd = @{} }
function A-Hwid { PD-Hwid }
function A-Ver { PD-AgentVer }

function A-Now([hashtable]$smp) {
  $v = $S.verdict; $df = PD-DeepFreeze
  if ($df.state -eq 'thawed' -and !$S.dfSince) { $S.dfSince = PD-NowMs } elseif ($df.state -ne 'thawed') { $S.dfSince = 0 }
  $tq = @(PD-ReadJson (Join-Path $PD.Root 'state\thawq.json')).Count
  $ip = ''; try { $ip = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress } catch {}
  @{ t = $smp.t; cpu = $smp.cpu; ram = $smp.ram; busy = $smp.busy; lat = $smp.lat; cfree = $smp.cfree; cfreeGB = $smp.cfreeGB; temp = $(if ($smp.temp) { $smp.temp.cpu } else { $null })
     freq = $smp.freq; net = $smp.net; user = $smp.user; top = @($smp.top | Select-Object -First 3); rtop = @($smp.ramTop | Select-Object -First 3)
     lv = $v.lv; v = $v.v; vk = $v.vk; why = $v.why; conf = $v.conf; fix = $v.fix
     df = $df.state; dfSince = $S.dfSince; thaw = [bool]$df.thaw; thawQ = $tq; boot = [int64](([datetimeoffset]$S.boot).ToUnixTimeMilliseconds())
     ver = (A-Ver); name = $env:COMPUTERNAME; ip = $ip; q = (PD-QueueCount); online = $PD.Online; pp = $S.pp; fixing = $S.fixing }
}
function A-Live([hashtable]$smp) {
  @{ t = $smp.t; c = $smp.cpu; r = $smp.ram; b = $smp.busy; l = $smp.lat; q = $smp.q; h = $smp.hf; f = $smp.cfree; n = $smp.net; fr = $smp.freq; u = $smp.user
     tc = $(if ($smp.temp) { $smp.temp.cpu } else { $null }); td = $(if ($smp.temp) { $smp.temp.disk } else { $null })
     p = @($smp.top | ForEach-Object { $_.n + '|' + $_.c + '|' + $_.m + '|' + $_.io }); pr = @($smp.ramTop | ForEach-Object { $_.n + '|' + $_.m }); pi = @($smp.ioTop | ForEach-Object { $_.n + '|' + $_.io }) }
}

# ---------- the PC's own record: name / group / notes both ways (5) ----------
function A-SyncPc {
  $h = A-Hwid; $pc = PD-Db GET ('lab/pcs/' + $h)
  if (!$pc) { $pc = [pscustomobject]@{} }
  $up = @{}
  if (!$pc.win -or $pc.win -ne $env:COMPUTERNAME) {
    if ($pc.win) { PD-Event 'rename' '✏️' ("Windows name changed on the PC: $($pc.win) -> $env:COMPUTERNAME") @{ old = $pc.win; new = $env:COMPUTERNAME } | Out-Null
      $up.winChanged = @{ old = $pc.win; new = $env:COMPUTERNAME; t = (PD-NowMs) }
      PD-Db PUT ('lab/edits/' + $h + '/e' + (PD-NowMs)) @{ t = (PD-NowMs); who = 'Windows (on the PC)'; where = 'PC'; field = 'win'; old = $pc.win; new = $env:COMPUTERNAME } | Out-Null }
    $up.win = $env:COMPUTERNAME }
  if ($pc.uninstalled) { $up.old = $null; $up.oldAt = $null; $up.uninstalled = $null; PD-Event 'install' '♻️' 'PC Doctor installed again - back from Old PCs' | Out-Null }   # 1.19
  if (!$pc.name) { $up.name = $env:COMPUTERNAME }
  # 05-Nov-2026 (user: two laptops both listed as "GUJJAR (duplicate)"): the Console name stayed the FIRST Windows name after a Windows
  # rename - now it follows the new Windows name when nobody set it by hand on the Console (name = the old Windows name)
  elseif ($pc.win -and $pc.win -ne $env:COMPUTERNAME -and [string]$pc.name -eq [string]$pc.win) { $up.name = $env:COMPUTERNAME }
  if (!$pc.grp) { $g = PD-Group ([string]$(if ($up.name) { $up.name } elseif ($pc.name) { $pc.name } else { $env:COMPUTERNAME })); if ($g) { $up.grp = $g } }
  $model = (Get-CimInstance Win32_ComputerSystem); $up.model = ($model.Manufacturer + ' ' + $model.Model).Trim(); $up.seen = PD-NowMs; $up.ver = A-Ver
  # Console renamed the PC (name != Windows name) -> rename Windows (a Frozen PC: at a Thawed restart)
  $want = [string]$(if ($pc.name) { $pc.name } else { '' })
  # 1.16 (05-Nov-2026: two laptops were Assigned "GUJJAR" by mistake and a rename was waiting for the restart): compare with the name Windows
  # will have AFTER the restart; when the Console name is the current name again, the waiting rename is cancelled (no restart, nothing deleted)
  $pend = try { [string](Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -ErrorAction Stop).ComputerName } catch { $env:COMPUTERNAME }
  if ($want -and $pc.renameReq -and $want -ne $pend) {
    if ($want -eq $env:COMPUTERNAME) {
      try { Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' ComputerName $want -ErrorAction Stop
        Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' 'NV Hostname' $want -ErrorAction Stop
        PD-Event 'rename' '↩' ("Waiting Windows rename to $pend cancelled - the name stays $want") @{ old = $pend; new = $want } | Out-Null; $S.renamed = $want } catch {} }
    elseif ($want -ne $S.renamed) { $r = PD-Fix 'rename' @{ name = $want } 'Console'; $S.renamed = $want } }
  if ($pc.winChangeBack -and $pc.winChanged) { PD-Fix 'rename' @{ name = $pc.winChanged.old } 'Console (change back)' | Out-Null; $up.winChangeBack = $null; $up.winChanged = $null }
  PD-Db PATCH ('lab/pcs/' + $h) $up | Out-Null
  foreach ($k in $up.Keys) { $pc | Add-Member -NotePropertyName $k -NotePropertyValue $up[$k] -Force }
  $S.pc = $pc
  PD-WriteJson (Join-Path $PD.Root 'state\pc.json') $pc
}
# 13: this PC's version + update log (lab/ver/<hwid>) and a rollback done by the loader
function A-VerReport {
  $h = A-Hwid; $run = PD-ReadJson (Join-Path $PD.Root 'state\running.json'); if (!$run) { return }
  $old = PD-Db GET ('lab/ver/' + $h + '/build')
  if ($old -ne $run.build) { PD-Db PUT ('lab/ver/' + $h + '/log/v' + (PD-NowMs)) @{ t = (PD-NowMs); old = $old; new = $run.build; ver = $run.ver; ok = $true } | Out-Null }
  PD-Db PATCH ('lab/ver/' + $h) @{ ver = $run.ver; build = $run.build; at = $run.at; seen = (PD-NowMs); ps = $PSVersionTable.PSVersion.ToString() } | Out-Null
  $rb = Join-Path $PD.Root 'state\rolledback.json'; $x = PD-ReadJson $rb
  if ($x) { PD-Db PUT ('lab/ver/' + $h + '/log/v' + (PD-NowMs)) @{ t = (PD-NowMs); old = $x.build; new = $run.build; ok = $false; why = $x.why; rolledBack = $true } | Out-Null
    PD-Db PATCH ('lab/ver/' + $h) @{ rolledBack = @{ t = $x.t; build = $x.build; why = $x.why } } | Out-Null
    PD-Alert 'rollback' "↩ $env:COMPUTERNAME: update rolled back" ("Build $($x.build): $($x.why). Running build $($run.build) again.") 'amber'; Remove-Item $rb -Force }
}
# a change typed in the tray window (req\edit.json) -> DB5 + the edit log
# requests from the tray window (a normal user): 💾 save to pendrive, 🔧 fix from pendrive (password checked by the tray), ✨ Ask AI (laptop)
function A-TrayReq {
  $r = Join-Path $PD.Root 'req'
  if (Test-Path "$r\usb.flag") { Remove-Item "$r\usb.flag" -Force; $d = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2') | Select-Object -First 1
    $o = if ($d) { PD-MakeDlh ($d.DeviceID + '\DavanLab') } else { '' }; PD-WriteJson (Join-Path $PD.Root 'state\usb.json') @{ t = (PD-NowMs); file = $o; ok = [bool]$o } }
  if (Test-Path "$r\usbfix.flag") { Remove-Item "$r\usbfix.flag" -Force; $d = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2' | Where-Object { Test-Path ($_.DeviceID + '\DavanFix\fix.json') }) | Select-Object -First 1
    $o = if ($d) { PD-RunUsbFix $d.DeviceID -Asked } else { $null }; PD-WriteJson (Join-Path $PD.Root 'state\usbfix.json') @{ t = (PD-NowMs); done = @($o); ok = [bool]$d }
    if ($o) { foreach ($x in $o) { PD-FixLog 'clean_temp' @{ ok = $x.ok; txt = ('pendrive: ' + $x.file + ' ' + $x.txt) } 'pendrive' } } }
  $lc = PD-ReadJson "$r\labcmd.json"; if ($lc) { Remove-Item "$r\labcmd.json" -Force; A-LabCmd $lc; return }
  $uu = PD-ReadJson "$r\usbupd.json"; if ($uu) { Remove-Item "$r\usbupd.json" -Force; A-UsbUpdate $uu; return }
  $un = PD-ReadJson "$r\uninstall.json"; if ($un) { Remove-Item "$r\uninstall.json" -Force; A-Uninstall $un; return }
  $q = PD-ReadJson "$r\ai.json"
  if ($q) { Remove-Item "$r\ai.json" -Force
    $a = try { Invoke-RestMethod -Method Post -Uri ($PD.Worker + '/lab/ai') -Body (PD-Json @{ token = (PD-Token); prompt = [string]$q.prompt; history = @($q.history) }) -ContentType 'text/plain' -TimeoutSec 60 } catch { @{ ok = $false; msg = $_.Exception.Message } }
    PD-WriteJson (Join-Path $PD.Root 'state\ai.json') @{ t = (PD-NowMs); ok = $a.ok; text = $a.text; msg = $a.msg; left = $a.left } }
}
# 1.19 (user, 05-Nov-2026: "an option with password to uninstall the tray software on a laptop or desktop"): the tray asks the password
# and shows the list; the agent (SYSTEM - the user cannot remove a service) checks the password AGAIN here, marks the PC "uninstalled"
# in DB5 (moves to Old PCs, history kept) and hands over to a one-time SYSTEM task, because removing the service also stops this agent.
function A-Uninstall($u) {
  $c = PD-Cfg; $want = if ($c -and $c.trayPw) { [string]$c.trayPw } else { '' }
  $hp = -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('davanlab:' + [string]$u.pw)) | ForEach-Object { $_.ToString('x2') })
  $def = -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('davanlab:2531')) | ForEach-Object { $_.ToString('x2') })
  if (!(($want -and $hp -eq $want) -or (!$want -and $hp -eq $def))) { PD-WriteJson (Join-Path $PD.Root 'state\uninst.json') @{ t = (PD-NowMs); ok = $false; msg = 'Wrong password - nothing removed.' }; return }
  if ((PD-DeepFreeze).state -eq 'frozen') { PD-WriteJson (Join-Path $PD.Root 'state\uninst.json') @{ t = (PD-NowMs); ok = $false; msg = 'This PC is Frozen - Deep Freeze would put PC Doctor back at the restart. Boot Thawed first, then uninstall.' }; return }
  $h = A-Hwid; $who = [string]$u.who
  PD-Event 'uninstall' '🗑️' ("PC Doctor uninstalled on the PC by " + $who) @{ who = $who; mesh = [bool]$u.mesh } | Out-Null
  PD-Db PATCH ('lab/pcs/' + $h) @{ old = $true; oldAt = (PD-NowMs); uninstalled = @{ t = (PD-NowMs); who = $who; mesh = [bool]$u.mesh } } | Out-Null
  PD-Alert 'uninstall' ("🗑️ " + $env:COMPUTERNAME + ': PC Doctor uninstalled') ("By " + $who + ' on the PC (password given). Moved to Old PCs; history kept.') 'amber'
  PD-WriteJson (Join-Path $PD.Root 'state\uninst.json') @{ t = (PD-NowMs); ok = $true; msg = 'Uninstalling - PC Doctor closes in about a minute.' }
  $mesh = if ($u.mesh) { '$true' } else { '$false' }
  $us = @"
`$ErrorActionPreference = 'SilentlyContinue'; `$R = "`$env:ProgramData\DavanPCDoctor"
Start-Sleep 3
Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' 'DavanPCDoctor'
Unregister-ScheduledTask -TaskName 'Davan PC Doctor' -Confirm:`$false
Unregister-ScheduledTask -TaskName 'Davan PC Doctor Tray' -Confirm:`$false
Stop-Service PCDoctorSvc -Force; sc.exe delete PCDoctorSvc | Out-Null
foreach (`$m in 'Minimal','Network') { Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\`$m\PCDoctorSvc" -Recurse -Force }
foreach (`$p in @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { `$_.CommandLine -match 'DavanPCDoctor\\(loader|bin\\agent|bin\\tray)\.ps1' })) { Invoke-CimMethod -InputObject `$p -MethodName Terminate | Out-Null }
if ($mesh) { `$x = "`$env:ProgramFiles\Mesh Agent\MeshAgent.exe"; if (Test-Path `$x) { Start-Process `$x -ArgumentList '-fulluninstall' -Wait -WindowStyle Hidden } }
Start-Sleep 3; Remove-Item `$R -Recurse -Force
Unregister-ScheduledTask -TaskName 'Davan PC Doctor Uninstall' -Confirm:`$false
Remove-Item `$PSCommandPath -Force
"@
  $f = Join-Path $env:windir 'Temp\DavanPCDoctor-uninstall.ps1'
  [IO.File]::WriteAllText($f, $us, (New-Object Text.UTF8Encoding($true)))
  $act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$f`""
  Register-ScheduledTask -TaskName 'Davan PC Doctor Uninstall' -Action $act -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
  Start-ScheduledTask -TaskName 'Davan PC Doctor Uninstall'
}
# 1.29 (user, 05-Nov-2026: "build with pendrive also"): offline update. The tray sends req\usbupd.json {pw}; the password is checked HERE again
# (as the Uninstall does), then every file of DavanUpdate\src on the pendrive must match the fingerprint in the pendrive's lab-version.json
# and the build must be newer. Old copy -> good\ (the loader rolls back a version that stays silent), new copy -> bin\, then this agent
# ends and the loader starts the new one.
function A-PwOk([string]$pw) {
  $c = PD-Cfg; $want = if ($c -and $c.trayPw) { [string]$c.trayPw } else { '' }
  $hp = -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('davanlab:' + $pw)) | ForEach-Object { $_.ToString('x2') })
  $def = -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('davanlab:2531')) | ForEach-Object { $_.ToString('x2') })
  ($want -and $hp -eq $want) -or (!$want -and $hp -eq $def)
}
function A-UsbRes([bool]$ok, [string]$msg) { PD-WriteJson (Join-Path $PD.Root 'state\usbupd.json') @{ t = (PD-NowMs); ok = $ok; msg = $msg } }
function A-UsbProg([string]$ph, [int]$i, [int]$n, [string]$file, [string]$to) { PD-WriteJson (Join-Path $PD.Root 'state\updp.json') @{ t = (PD-NowMs); ph = $ph; i = $i; n = $n; file = $file; to = $to } }
function A-UsbUpdate($rq) {
  if (!(A-PwOk ([string]$rq.pw))) { A-UsbRes $false 'Wrong password - nothing installed.'; return }
  $d = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2' | Where-Object { Test-Path ($_.DeviceID + '\DavanUpdate\lab-version.json') }) | Select-Object -First 1
  if (!$d) { A-UsbRes $false 'No update pendrive found (it needs a DavanUpdate folder). Plug it in and try again.'; return }
  $dir = $d.DeviceID + '\DavanUpdate'; $v = PD-ReadJson "$dir\lab-version.json"
  if (!$v -or !$v.agent -or !$v.files) { A-UsbRes $false 'The lab-version.json on the pendrive cannot be read - make the pendrive again.'; return }
  $run = PD-ReadJson (Join-Path $PD.Root 'state\running.json')
  if ($run -and [int]$run.build -ge [int]$v.agent.build) { A-UsbRes $true ('This PC already has ' + $run.ver + ' (build ' + $run.build + '); the pendrive has ' + $v.agent.ver + '. Nothing to install.'); return }
  $tmp = Join-Path $PD.Root 'dl\usb'; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force $tmp | Out-Null
  $props = @($v.files.PSObject.Properties); $n = $props.Count; $k = 0; $to = [string]$v.agent.ver
  foreach ($f in $props) { $k++; A-UsbProg 'usb' $k $n $f.Name $to
    $src = Join-Path "$dir\src" $f.Name
    if (!(Test-Path $src)) { A-UsbRes $false ('A file is missing on the pendrive: ' + $f.Name + ' - make the pendrive again.'); return }
    Copy-Item $src (Join-Path $tmp $f.Name) -Force
    if ((PD-Sha256File (Join-Path $tmp $f.Name)) -ne [string]$f.Value) { A-UsbRes $false ('Refused: ' + $f.Name + ' does not match its fingerprint (the pendrive is damaged or was changed).'); return } }
  $bin = Join-Path $PD.Root 'bin'; $good = Join-Path $PD.Root 'good'
  Remove-Item "$good\*" -Force -ErrorAction SilentlyContinue; Copy-Item "$bin\*" $good -Force; Copy-Item (Join-Path $PD.Root 'state\running.json') "$good\running.json" -ErrorAction SilentlyContinue
  Copy-Item "$tmp\*" $bin -Force
  PD-WriteJson (Join-Path $PD.Root 'state\running.json') @{ ver = [string]$v.agent.ver; build = [int]$v.agent.build; at = (PD-NowMs); prev = $(if ($run) { [int]$run.build } else { 0 }) }
  if (Test-Path "$bin\loader.ps1") { Copy-Item "$bin\loader.ps1" (Join-Path $PD.Root 'loader.ps1') -Force }
  try { $v | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $PD.Root 'state\labver.json') -Encoding UTF8 } catch {}
  PD-WriteJson (Join-Path $PD.Root 'state\upd.json') @{ at = (PD-NowMs); res = ('Updated to ' + $to + ' (build ' + $v.agent.build + ') from the pendrive'); manual = $true }
  PD-Event 'update' '💾' ('PC Doctor updated to ' + $to + ' from a pendrive by ' + [string]$rq.who) | Out-Null
  A-UsbProg 'usbdone' $n $n '' $to; A-UsbRes $true ('Installed ' + $to + ' from the pendrive - PC Doctor restarts in a few seconds.')
  Start-Sleep 4; exit 0
}
# 1.36 (user, 05-Nov-2026: "the web app takes time to check and reply - give the tray these options"): on the Super Admin laptop the tray sends
# req\labcmd.json {op: send|purge, pcs: [hwid], kind, days, dry, pw}. Deleting steps (Clean now, purge) check the password HERE again.
# The worker (POST /lab/cmd, /lab/cmdres, /lab/purge) does the DB5 side; the answers come back into state\labres.json for the tray.
$script:LabPend = @(); $script:LabRows = @{}
function A-LabOut($o) { $o.t = (PD-NowMs); PD-WriteJson (Join-Path $PD.Root 'state\labres.json') $o }
function A-LabPost([string]$route, $body) { $body.token = (PD-Token); Invoke-RestMethod -Method Post -Uri ($PD.Worker + $route) -Body (PD-Json $body) -ContentType 'text/plain' -TimeoutSec 60 }
function A-LabCmd($rq) {
  if (!$S.laptop) { A-LabOut @{ op = [string]$rq.op; ok = $false; msg = 'Only the Super Admin laptop can do this.' }; return }
  $del = (([string]$rq.op -eq 'purge') -and !$rq.dry) -or (([string]$rq.op -eq 'send') -and ([string]$rq.kind -eq 'clean'))
  if ($del -and !(A-PwOk ([string]$rq.pw))) { A-LabOut @{ op = [string]$rq.op; ok = $false; msg = 'Wrong password - nothing deleted.' }; return }
  try {
    if ([string]$rq.op -eq 'purge') {
      $x = A-LabPost '/lab/purge' @{ pcs = @($rq.pcs); days = [int]$rq.days; dry = [bool]$rq.dry; confirm = $del }
      if (!$x.ok) { A-LabOut @{ op = 'purge'; ok = $false; msg = [string]$x.msg }; return }
      A-LabOut @{ op = 'purge'; ok = $true; dry = [bool]$x.dry; days = $x.days; rows = @($x.rows); done = $true }
    } else {
      $x = A-LabPost '/lab/cmd' @{ pcs = @($rq.pcs); kind = [string]$rq.kind; confirm = $del; why = 'laptop tray' }
      if (!$x.ok) { A-LabOut @{ op = 'send'; ok = $false; msg = [string]$x.msg }; return }
      $script:LabPend = @($x.ids); $script:LabRows = @{}; foreach ($i in $x.ids) { $script:LabRows[[string]$i.id] = @{ pc = [string]$i.pc; st = 'sent'; txt = '' } }
      $script:LabKind = [string]$rq.kind; $script:LabAt = Get-Date
      A-LabOut @{ op = 'send'; ok = $true; kind = [string]$rq.kind; rows = @($script:LabRows.Values); done = (!$x.ids.Count) }
    }
  } catch { A-LabOut @{ op = [string]$rq.op; ok = $false; msg = 'Could not reach the server: ' + $_.Exception.Message } }
}
function A-LabPoll {
  if (!$script:LabPend.Count) { return }
  try {
    $x = A-LabPost '/lab/cmdres' @{ ids = @($script:LabPend | ForEach-Object { @{ h = $_.h; id = $_.id } }) }
    foreach ($i in @($x.res)) { if ($script:LabRows.ContainsKey([string]$i.id)) { $script:LabRows[[string]$i.id].st = [string]$i.st; $script:LabRows[[string]$i.id].txt = [string]$i.txt } }
    $left = @($script:LabPend | Where-Object { $script:LabRows[[string]$_.id].st -notin 'done', 'failed' })
    $over = ((Get-Date) - $script:LabAt).TotalMinutes -gt 5
    if (!$left.Count -or $over) { $script:LabPend = @() }
    A-LabOut @{ op = 'send'; ok = $true; kind = $script:LabKind; rows = @($script:LabRows.Values); done = (!$left.Count -or $over) }
  } catch {}
}
# 1.48 (user, 05-Nov-2026: "Show me this PC is not working" - the agent answered but the PC showed nothing: an OLD tray was still running, e.g. its window left open
# since before an update). The tray writes req\tray_run.json {sha} at its start; if the file on disk is different (or an old tray wrote nothing), the agent stops that
# tray and starts the "Davan PC Doctor Tray" task (runs in the signed-in user's session). Tried at most once per 30 minutes; a window open is closed once.
function A-TrayFresh {
  try { $f = Join-Path $PD.Root 'bin\tray.ps1'; if (!(Test-Path $f)) { return }
    $want = (Get-FileHash $f -Algorithm SHA256).Hash; $tr = PD-ReadJson (Join-Path $PD.Root 'req\tray_run.json')
    $procs = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'DavanPCDoctor\\bin\\tray\.ps1' })
    if (!$procs.Count) { Start-ScheduledTask -TaskName 'Davan PC Doctor Tray' -ErrorAction SilentlyContinue; return }
    if ($tr -and [string]$tr.sha -eq $want) { return }
    if ($script:trayKill -and ((Get-Date) - $script:trayKill).TotalMinutes -lt 30) { return }
    $script:trayKill = Get-Date
    foreach ($pp in $procs) { Invoke-CimMethod -InputObject $pp -MethodName Terminate | Out-Null }
    PD-Log 'an old tray was running - stopped; the tray task starts the new one'; Start-Sleep 2; Start-ScheduledTask -TaskName 'Davan PC Doctor Tray' -ErrorAction SilentlyContinue
  } catch { PD-Log ('tray check: ' + $_.Exception.Message) }
}
function A-TrayEdits {
  foreach ($f in @(Get-ChildItem (Join-Path $PD.Root 'req') -Filter 'edit*.json' -ErrorAction SilentlyContinue)) {
    $e = PD-ReadJson $f.FullName; Remove-Item $f.FullName -Force
    if (!$e) { continue }
    $h = A-Hwid; $up = @{}
    foreach ($k in 'name','grp','place','user','notes','df','keep') { if ($null -ne $e.$k -and [string]$e.$k -ne [string]$S.pc.$k) {
      PD-Db PUT ('lab/edits/' + $h + '/e' + (PD-NowMs) + $k.Length) @{ t = (PD-NowMs); who = [string]$e.who; where = 'PC (tray)'; field = $k; old = [string]$S.pc.$k; new = [string]$e.$k } | Out-Null
      $up[$k] = $e.$k } }
    if ($up.Count) { if ($up.name) { $up.renameReq = $true; $up.name = ([string]$up.name).ToUpper() }; $up.trayEdit = PD-NowMs; PD-Db PATCH ('lab/pcs/' + $h) $up | Out-Null; A-SyncPc }
  }
}

# ---------- events ----------
function A-Events {
  $since = if ($S.lastEv) { $S.lastEv } else { $S.boot.AddMinutes(-2) }
  $evs = @(PD-ReadEvents $since)
  $S.lastEv = Get-Date
  $h = A-Hwid
  foreach ($e in $evs) {
    PD-Db PUT ('lab/events/' + $h + '/e' + $e.t + $e.id) $e | Out-Null
    if ($e.k -eq 'bsod') { $c = PD-Cfg; $w = if ($e.code -and $c.bsod.($e.code)) { $c.bsod.($e.code).w } else { 'Blue screen' }
      PD-Alert ('bsod_' + $e.code) ("💙 $env:COMPUTERNAME blue screen $($e.code)") $w 'red' }
    if ($e.k -in 'whea','ntfs') { PD-Alert $e.k ("🔴 $env:COMPUTERNAME: " + $e.txt) $e.msg 'red' }
    if ($e.k -eq 'hang' -and $e.prog) { $S.hangs[$e.prog] = 1 + [int]$S.hangs[$e.prog] }
    if ($e.k -eq 'kp41' -or $e.k -eq 'unexpected') { A-FreezeMark $e }
  }
  if ($evs.Count) { $S.verdict = $null }
}
# 6: "just before the freeze" - the minute rows before the cut are already in DB5; mark where they stop
function A-FreezeMark($e) {
  $prev = PD-ReadJson (Join-Path $PD.Root 'state\lastrow.json')
  $t = if ($prev -and $prev.t) { [int64]$prev.t } else { 0 }
  $tp = PD-ThawPath; if (!$t -and $tp) { $x = PD-ReadJson "$tp\lastrow.json"; if ($x) { $t = [int64]$x.t } }
  if ($S.freezeDone) { return }; $S.freezeDone = $true
  PD-Event 'freeze' '🧊' ('Stopped without shutdown - last minute row ' + $(if ($t) { PD-IST $t } else { 'unknown (Frozen PC wiped it; DB5 has the rows)' })) @{ lastRow = $t; code = $e.code; nobsod = $e.nobsod } | Out-Null
}

# ---------- verdict: 7 days of events from DB5 (Deep Freeze cannot wipe them) + today's checks ----------
function A-Metrics {
  $h = A-Hwid; $since = (PD-NowMs) - 7 * 86400000
  if ($S.test) { $list = @($S.ev7) } else {   # test mode (Windows runner): no DB5 at all
    $ev = PD-Db GET ('lab/events/' + $h) $null ('orderBy="$key"&startAt="e' + $since + '"')
    $list = @(); if ($ev) { $list = @($ev.PSObject.Properties | ForEach-Object { $_.Value }) }
    $S.ev7 = $list }
  $cnt = { param($k) @($list | Where-Object { $_.k -eq $k }).Count }
  $hang = $list | Where-Object { $_.k -eq 'hang' -and $_.prog } | Group-Object prog | Sort-Object Count -Descending | Select-Object -First 1
  $inv = $S.inv; $sm = @(); if ($inv) { $sm = @($inv.disks) }
  $sysDisk = $sm | Select-Object -First 1
  $perf = @($S.ring); $live = if ($S.test) { $null } else { PD-Db GET ('lab/live/' + $h) $null 'orderBy="$key"&limitToLast=600' }
  if ($live) { $perf = @($live.PSObject.Properties | ForEach-Object { $_.Value }) }
  $p95 = { param($xs) $a = @($xs | Where-Object { $null -ne $_ } | Sort-Object); if (!$a.Count) { return $null }; $a[[math]::Min($a.Count - 1, [int]($a.Count * 0.95))] }
  $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  $andGB = 0; if ($inv -and $inv.drives) { foreach ($k in 'sdk','avd','gradle') { foreach ($x in @($inv.drives.$k)) { $andGB += [double]$x.gb } } }
  $bs = @($list | Where-Object { $_.k -eq 'bsod' })
  $bsk = @{}; $cb = PD-Cfg; foreach ($b in $bs) { $w = if ($b.code) { $cb.bsod.($b.code) } else { $null }; if ($w) { $bsk[$w.vk] = 1 + [int]$bsk[$w.vk] } }
  $pr = $S.prn; $ul = PD-UpdateLoop $list; $st = $S.startup; $nc = $S.net
  # 1.33 (user, 05-Nov-2026: new lab PC B1 at 41-45 C was called "Overheating"): a low CPU speed while the PC is IDLE is normal power saving, and
  # Windows logs "speed limited" (Kernel-Processor-Power 37) on healthy PCs - so a slow-down only counts as heat when the CPU was really hot (80 C+)
  # and the speed drop only when the CPU was busy (50%+)
  $tmax = ($perf | ForEach-Object { $_.tc } | Where-Object { $_ } | Measure-Object -Maximum).Maximum
  @{
    smart = @{ realloc = [int]($sm | Measure-Object realloc -Sum).Sum; pending = [int]($sm | Measure-Object pending -Sum).Sum; uncorr = [int]($sm | Measure-Object uncorr -Sum).Sum; crc = [int]($sm | Measure-Object crc -Maximum).Maximum; wear = [int]($sm | Measure-Object wear -Maximum).Maximum }
    ev = @{ disk7 = @($list | Where-Object { $_.k -eq 'disk' -and $_.id -eq 7 }).Count; whea = (& $cnt 'whea'); scm = (& $cnt 'scm'); apperr = (& $cnt 'apperr'); throttle = $(if ($tmax -ge 80) { & $cnt 'throttle' } else { 0 })
            hangTop = [string]$hang.Name; hangTopN = [int]$hang.Count; kp41nob = @($list | Where-Object { $_.k -eq 'kp41' -and $_.nobsod }).Count; clockJump = @($list | Where-Object { $_.k -eq 'clock' -and $_.jump -lt -60 }).Count }
    mdiag = @{ fail = @($list | Where-Object { $_.k -eq 'mdiag' -and $_.id -in 1202,1102 }).Count }
    bsod = @{ n7 = $bs.Count; ram = [int]$bsk['ram']; windows = [int]$bsk['windows']; last = $(if ($bs.Count) { ($bs | Select-Object -Last 1).code } else { '' }) }
    perf = @{ latP95 = (& $p95 ($perf | ForEach-Object { if ($_.l -ne $null) { $_.l } else { $_.lat } })); busyP95 = (& $p95 ($perf | ForEach-Object { if ($_.b -ne $null) { $_.b } else { $_.busy } }))
              ramP95 = (& $p95 ($perf | ForEach-Object { if ($_.r -ne $null) { $_.r } else { $_.ram } })); faultsP95 = (& $p95 ($perf | ForEach-Object { if ($_.h -ne $null) { $_.h } else { $_.hf } }))
              tempMax = ($perf | ForEach-Object { $_.tc } | Measure-Object -Maximum).Maximum; freqMin = ($perf | Where-Object { ($_.c -ge 50) -or ($_.cpu -ge 50) } | ForEach-Object { $_.fr } | Where-Object { $_ } | Measure-Object -Minimum).Minimum }
    inv = @{ ramGB = $(if ($inv) { $inv.ramGB }); ramMismatch = $(if ($inv -and $inv.ramMismatch) { 1 } else { 0 }); ramSticks = $(if ($inv) { (@($inv.ram) | ForEach-Object { "$($_.gb) GB $($_.mhz) MHz" }) -join ', ' }) }
    top = @{ ram = $(if ($S.ring.Count) { (@($S.ring[-1].ramTop) | Select-Object -First 2 | ForEach-Object { $_.n }) -join ' + ' }) }
    disk = @{ cFreePct = [math]::Round(100 * $c.FreeSpace / $c.Size, 1); cFreeGB = [math]::Round($c.FreeSpace / 1GB, 1); androidGB = [math]::Round($andGB, 1); cleanGB = $S.cleanGB }
    upd = $ul; prn = @{ err = [int]$pr.err; stuck = [int]$pr.stuck; code = [string]$pr.code; name = [string](@($pr.jobs) | Select-Object -First 1).prn }
    boot = @{ sec = $st.sec; top = [string]$st.stuck }; sfc = @{ bad = [int]$S.sfc.bad }
    net = @{ ipConflict = (& $cnt 'ipconflict'); gwMs = $nc.gwMs; loss = $nc.loss }
  }
}
function A-Verdict { $m = A-Metrics; $v = PD-Verdict $m; $S.metrics = $m; $S.verdict = $v
  $old = PD-ReadJson (Join-Path $PD.Root 'state\verdict.json')
  if ($v.lv -eq 'red' -and (!$old -or $old.vk -ne $v.vk)) { PD-Alert ('red_' + $v.vk) ("🔴 $env:COMPUTERNAME: " + $v.v) $v.why 'red' }
  PD-WriteJson (Join-Path $PD.Root 'state\verdict.json') $v
  PD-Db PUT ('lab/pcs/' + (A-Hwid) + '/verdict') @{ t = (PD-NowMs); lv = $v.lv; v = $v.v; vk = $v.vk; why = $v.why; conf = $v.conf; fix = $v.fix; all = $v.all; m = $m } | Out-Null
}

# ---------- daily: inventory + deep checks + summary of yesterday ----------
function A-Daily([switch]$Force) {
  $d = PD-ISTDate; if (!$Force -and $S.lastDay -eq $d) { return }
  $S.lastDay = $d; $h = A-Hwid
  PD-Log 'daily inventory'
  $inv = PD-Inventory | ConvertTo-Json -Depth 8 -Compress | ConvertFrom-Json; $S.inv = $inv   # objects, not hashtables: Measure-Object / Group-Object need properties (PS 5.1)
  $old = PD-ReadJson (Join-Path $PD.Root 'state\inv.json')
  if ($old) { A-InvDiff $old $inv }
  PD-WriteJson (Join-Path $PD.Root 'state\inv.json') $inv
  $S.startup = PD-Startup; $S.net = PD-NetCheck; $S.prn = PD-PrintCheck; $S.sfc = PD-SfcState; $S.bsod = PD-Bsod
  $S.cleanGB = (PD-AndroidPlan).gb
  PD-Db PUT ('lab/inv/' + $h) @{ t = (PD-NowMs); inv = $inv; startup = $S.startup; net = $S.net; prn = $S.prn; sfc = $S.sfc; bsod = $S.bsod; cleanGB = $S.cleanGB } | Out-Null
  PD-Db PATCH ('lab/pcs/' + $h) @{ model = $inv.model; cpu = $inv.cpu.n; ramGB = $inv.ramGB; disk = (@($inv.disks) | Select-Object -First 1 | ForEach-Object { $_.model + ' ' + $_.sizeGB + ' GB ' + $_.media }); win = $env:COMPUTERNAME; winBuild = $inv.win.build; meshId = $inv.mesh; dfVer = $inv.df.ver } | Out-Null
  # yesterday's summary from the minute rows (the Console reads summaries, not raw rows)
  $y = PD-ISTDate ((PD-NowMs) - 86400000)
  $rows = PD-Db GET ('lab/live/' + $h) $null 'orderBy="$key"&limitToLast=1500'
  if ($rows) {
    $r = @($rows.PSObject.Properties | ForEach-Object { $_.Value } | Where-Object { (PD-ISTDate ([int64]$_.t)) -eq $y })
    if ($r.Count) {
      $avg = { param($k) [math]::Round((@($r | ForEach-Object { $_.$k } | Where-Object { $null -ne $_ }) | Measure-Object -Average).Average, 1) }
      $mx = { param($k) (@($r | ForEach-Object { $_.$k } | Where-Object { $null -ne $_ }) | Measure-Object -Maximum).Maximum }
      $evy = @($S.ev7 | Where-Object { (PD-ISTDate ([int64]$_.t)) -eq $y })
      PD-Db PUT ('lab/daily/' + $h + '/' + $y) @{ mins = $r.Count; cpu = (& $avg 'c'); cpuMax = (& $mx 'c'); ram = (& $avg 'r'); ramMax = (& $mx 'r'); busy = (& $avg 'b'); lat = (& $avg 'l'); latMax = (& $mx 'l')
        tMax = (& $mx 'tc'); cfree = ($r | Select-Object -Last 1).f; users = @($r | ForEach-Object { $_.u } | Where-Object { $_ } | Select-Object -Unique)
        ev = @($evy | Group-Object k | ForEach-Object { @{ k = $_.Name; n = $_.Count } }); lv = $S.verdict.lv; v = $S.verdict.v; boot = $S.startup.sec } | Out-Null
    }
  }
}
# 5: a part changed on a known PC -> one event per part (the worker does the same at re-install)
function A-InvDiff($o, $n) {
  $od = @($o.disks | ForEach-Object { $_.serial } | Where-Object { $_ }); $nd = @($n.disks | ForEach-Object { $_.serial } | Where-Object { $_ })
  foreach ($x in $od) { if ($nd -notcontains $x) { $old = $o.disks | Where-Object serial -eq $x | Select-Object -First 1
    PD-Event 'part' '💾' ("Disk replaced: old $($old.model) $x" + $(if ($old.realloc) { " had $($old.realloc) bad sectors" } else { '' })) @{ part = 'disk'; old = $x } | Out-Null } }
  $or = @($o.ram | ForEach-Object { $_.serial } | Where-Object { $_ }); $nr = @($n.ram | ForEach-Object { $_.serial } | Where-Object { $_ })
  foreach ($x in $or) { if ($nr -notcontains $x) { PD-Event 'part' '🧠' "RAM stick changed (old $x)" @{ part = 'ram'; old = $x } | Out-Null } }
  if ($o.ramGB -ne $n.ramGB) { PD-Event 'part' '🧠' "RAM $($o.ramGB) GB -> $($n.ramGB) GB" @{ part = 'ram' } | Out-Null }
  if ($o.bios.ver -ne $n.bios.ver) { PD-Event 'bios' '🧬' "BIOS $($o.bios.ver) -> $($n.bios.ver)" | Out-Null }
  if ($o.win.build -ne $n.win.build) { PD-Event 'winver' '🪟' "Windows $($o.win.build) -> $($n.win.build)" | Out-Null }
  $os = @($o.software | ForEach-Object { $_.n }); $ns = @($n.software | ForEach-Object { $_.n })
  $add = @($ns | Where-Object { $os -notcontains $_ }); $del = @($os | Where-Object { $ns -notcontains $_ })
  if ($add.Count) { PD-Event 'install' '📦' ('Installed: ' + (($add | Select-Object -First 8) -join ', ')) | Out-Null }
  if ($del.Count) { PD-Event 'install' '📦' ('Removed: ' + (($del | Select-Object -First 8) -join ', ')) | Out-Null }
}

# ---------- peers (6): who answers a ping, so the Console can tell "on but stuck" from "off" ----------
function A-Peers {
  $h = A-Hwid; $ip = ''; try { $ip = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress } catch {}
  PD-Db PUT ('lab/peers/' + $h) @{ ip = $ip; name = $env:COMPUTERNAME; grp = [string]$S.pc.grp; t = (PD-NowMs); fixing = $S.fixing } | Out-Null
  $all = PD-Db GET 'lab/peers'; if (!$all) { return }
  $S.peers = $all; $pp = @{}; $tasks = @{}
  foreach ($p in $all.PSObject.Properties) { if ($p.Name -eq $h -or !$p.Value.ip -or [string]$p.Value.grp -ne [string]$S.pc.grp) { continue }
    $tasks[$p.Name] = (New-Object Net.NetworkInformation.Ping).SendPingAsync($p.Value.ip, 800) }
  foreach ($k in $tasks.Keys) { try { $tasks[$k].Wait(1500) | Out-Null; $pp[$k] = $(if ($tasks[$k].Result.Status -eq 'Success') { 1 } else { 0 }) } catch { $pp[$k] = 0 } }
  $S.pp = $pp
}
function A-FixingCount { $n = 0; if ($S.peers) { foreach ($p in $S.peers.PSObject.Properties) { if ($p.Value.fixing -and ((PD-NowMs) - [int64]$p.Value.t) -lt 15 * 60000) { $n++ } } }; $n }

# ---------- commands from the Console / Claude (lab/cmd/<hwid>) ----------
function A-Cmds {
  $h = A-Hwid; $cmds = PD-Db GET ('lab/cmd/' + $h); if (!$cmds) { return }
  foreach ($p in $cmds.PSObject.Properties) {
    $id = $p.Name; $c = $p.Value
    if ($S.doneCmd[$id]) { continue }
    if (!$c.ok) { continue }   # a change Claude / AI queued waits for the Super Admin's ✅ Approve
    $res = PD-Db GET ('lab/res/' + $h + '/' + $id + '/st'); if ($res -in 'done','failed','running') { $S.doneCmd[$id] = 1; continue }
    if ($c.at -and ((PD-NowMs) - [int64]$c.at) -gt 7 * 86400000) { $S.doneCmd[$id] = 1; continue }
    $S.doneCmd[$id] = 1
    PD-Db PUT ('lab/res/' + $h + '/' + $id) @{ st = 'running'; t = (PD-NowMs); kind = $c.kind } | Out-Null
    $out = try { A-Do ([string]$c.kind) $c.args ([string]$c.by) $id } catch { @{ ok = $false; txt = 'error: ' + $_.Exception.Message } }
    PD-Db PUT ('lab/res/' + $h + '/' + $id) @{ st = $(if ($out.ok -eq $false) { 'failed' } else { 'done' }); t = (PD-NowMs); kind = $c.kind; txt = [string]$out.txt; data = $out.data } | Out-Null
  }
}
function A-Do([string]$kind, $a, [string]$by, [string]$id) {
  $h = A-Hwid
  switch -regex ($kind) {
    '^(mesh_check)$' {   # 1.52 read-only (user, 05-Nov-2026: Remote screen never connects - the server shows every PC registered but NOT connected): why is this PC's remote agent offline?
      $o = @(); $svc = Get-Service 'Mesh Agent' -ErrorAction SilentlyContinue
      $o += 'service: ' + $(if ($svc) { [string]$svc.Status + ' / start ' + [string]$svc.StartType } else { 'NOT INSTALLED' })
      $md = Join-Path $env:ProgramFiles 'Mesh Agent'; $msh = $null; try { $msh = Get-ChildItem $md -Filter *.msh -ErrorAction Stop | Select-Object -First 1 } catch {}
      $o += 'msh: ' + $(if ($msh) { ((Get-Content $msh.FullName -ErrorAction SilentlyContinue | Where-Object { $_ -match '^(MeshServer|ServerID|MeshName)=' }) -join ' | ') } else { 'none in ' + $md })
      $o += 'files: ' + ((Get-ChildItem $md -ErrorAction SilentlyContinue | ForEach-Object { $_.Name + ' ' + $_.Length + ' ' + $_.LastWriteTime.ToString('dd MMM HH:mm') }) -join ', ')
      $mp = @(Get-Process MeshAgent -ErrorAction SilentlyContinue); $o += 'process: ' + $(if ($mp.Count) { 'running since ' + $mp[0].StartTime.ToString('dd MMM HH:mm') } else { 'NOT running' })
      $mu = [string](PD-Cfg).meshUrl; $mh = ''; try { $mh = ([uri]$mu).Host } catch {}
      if ($mh) {
        try { $tc = New-Object Net.Sockets.TcpClient; $ar = $tc.BeginConnect($mh, 443, $null, $null); $okc = $ar.AsyncWaitHandle.WaitOne(8000); $o += "tcp ${mh}:443 " + $(if ($okc -and $tc.Connected) { 'OK' } else { 'FAILED (blocked or no route)' }); $tc.Close() } catch { $o += 'tcp error: ' + $_.Exception.Message }
        try { $wr = Invoke-WebRequest -UseBasicParsing ('https://' + $mh + '/agent.ashx') -TimeoutSec 15; $o += 'https agent.ashx: ' + $wr.StatusCode } catch { $o += 'https agent.ashx: ' + $_.Exception.Message }
      } else { $o += 'no meshUrl in the settings' }
      # 1.53: every step on its own - Get-WinEvent throws 'The parameter is incorrect' when the Mesh Agent never wrote an event (stopped the whole check on GUJJARHOME)
      try { $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'Mesh Agent'; StartTime = (Get-Date).AddDays(-2) } -MaxEvents 8 -ErrorAction Stop | ForEach-Object { $_.TimeCreated.ToString('dd HH:mm') + ' ' + (([string]$_.Message) -replace '\s+', ' ').Substring(0, [math]::Min(140, ([string]$_.Message).Length)) }); $o += 'agent events (2 days): ' + ($ev -join ' || ') } catch { $o += 'agent events (2 days): none' }
      try { $th = @(Get-MpThreatDetection -ErrorAction Stop | Where-Object { ($_.Resources -join ';') -match 'mesh' } | Select-Object -First 3 | ForEach-Object { $_.InitialDetectionTime.ToString('dd MMM HH:mm') + ' ' + ($_.Resources -join ';') }); $o += 'antivirus: ' + $(if ($th.Count) { 'BLOCKED ' + ($th -join ' | ') } else { 'no Mesh detections' }) } catch { $o += 'antivirus: not readable' }
      try { $o += 'deep freeze: ' + (PD-DeepFreeze).state } catch {}
      @{ ok = $true; txt = ($o -join "`n") } }
    '^(agent_log)$'  { $lf = Join-Path $PD.Root 'log\agent.log'; $rq = @(Get-ChildItem (Join-Path $PD.Root 'req') -ErrorAction SilentlyContinue | ForEach-Object { $_.Name + ' ' + $_.Length + ' bytes ' + $_.LastWriteTime.ToString('HH:mm:ss') })
                       $trs = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'DavanPCDoctor\\bin\\tray\.ps1' } | ForEach-Object { 'tray pid ' + $_.ProcessId + ' since ' + $_.CreationDate.ToString('HH:mm:ss') }); $trj = PD-ReadJson (Join-Path $PD.Root 'req\tray_run.json')
                       @{ ok = $true; txt = ('Agent ' + (A-Ver) + ', trays: ' + ($trs -join ', ') + ', tray file ' + ((Get-Item (Join-Path $PD.Root 'bin\tray.ps1')).LastWriteTime.ToString('HH:mm:ss')) + ', tray said sha ' + $(if ($trj) { ([string]$trj.sha).Substring(0, 8) } else { 'none (old tray)' }) + ', laptop mode ' + [bool]$S.laptop + ', req folder: ' + ($rq -join '; ')); data = @($(if (Test-Path $lf) { Get-Content $lf -Tail 40 } else { 'no log' })) } }   # 1.43 read-only: Claude reads a PC's own log (no screenshot needed)
    # 1.45 (user, 05-Nov-2026: "B1 is not Frozen, I turned Deep Freeze off" - Check disk stayed in "Thaw needed"): the first Thawed boot after a
    # Frozen time always reads Frozen (the marker went back to the frozen image), so the Console's "✅ It is Thawed - run now" tells the agent so:
    # this boot counts as Thawed (df_state.json) and the waiting fixes run at once
    '^(thawed_now)$' { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString('s'); PD-WriteJson (Join-Path $PD.Root 'state\df_state.json') @{ boot = $boot; state = 'thawed'; by = $by }
                       Set-Content (Join-Path $PD.Root 'state\df_marker.txt') $boot; PD-Db PATCH ('lab/pcs/' + $h) @{ dfBoot = $boot } | Out-Null
                       $n = @(PD-ReadJson (Join-Path $PD.Root 'state\thawq.json') | Where-Object { $_ }).Count; if (!$n) { $dbq = PD-Db GET ('lab/pcs/' + $h + '/thawq'); if ($dbq) { $n = @($dbq).Count } }
                       PD-Event 'thaw' '🔥' ('Marked Thawed by ' + $by + ' - ' + $n + ' waiting fix(es) run now') | Out-Null; A-ThawRun; A-Minute
                       @{ ok = $true; txt = $(if ($n) { "Thawed - $n waiting fix(es) ran now (Check disk: restart the PC once, it runs at the start)" } else { 'Thawed - nothing was waiting' }) } }
    '^(identify)$'   { PD-WriteJson (Join-Path $PD.Root 'state\identify.json') @{ t = (PD-NowMs); by = $by; off = [bool]$a.off; name = $(if ($S.pc -and $S.pc.name) { [string]$S.pc.name } else { $env:COMPUTERNAME }) }; @{ ok = $true; txt = $(if ($a.off) { 'Name hidden on the PC screen' } else { 'Name shown on the PC screen (stays until it is hidden)' }) } }   # 1.37 read-only
    '^(check)$'      { A-Verdict; @{ ok = $true; txt = $S.verdict.v + ' - ' + $S.verdict.why } }
    '^(report|send|inventory|deep)$' { A-Daily -Force; A-Verdict; @{ ok = $true; txt = 'Full report sent (inventory, deep checks, verdict)' } }
    '^(events)$'     { $S.lastEv = (Get-Date).AddDays(-7); A-Events; @{ ok = $true; txt = 'Events of the last 7 days sent again' } }
    '^(ping|net)$'   { $S.net = PD-NetCheck; A-Peers; @{ ok = $true; txt = "Gateway $($S.net.gwMs) ms, internet $($S.net.netMs) ms, DNS $($S.net.dnsMs) ms"; data = $S.net } }
    '^(startup)$'    { $S.startup = PD-Startup; @{ ok = $true; txt = "Startup $($S.startup.sec) s. $($S.startup.stuck)"; data = $S.startup } }
    '^(bsod)$'       { $S.bsod = PD-Bsod 90; @{ ok = $true; txt = "$($S.bsod.list.Count) blue screen(s) in 90 days. $($S.bsod.note)"; data = $S.bsod } }
    '^(disk_scan)$'  { $d = PD-Smart; @{ ok = $true; txt = (($d | ForEach-Object { "$($_.model): $($_.health), bad $([int]$_.realloc)/$([int]$_.pending), $($_.hours) h" }) -join '; '); data = $d } }
    '^(printers)$'   { $S.prn = PD-PrintCheck; @{ ok = $true; txt = "Spooler $($S.prn.spooler), $($S.prn.stuck) stuck job(s), $($S.prn.err) error(s) $($S.prn.code)"; data = $S.prn } }
    '^(snapshot)$'   { @{ ok = $true; txt = 'Last 10 minutes sent'; data = @($S.ring) } }
    '^(clean_plan)$' { $p = PD-AndroidPlan; $S.cleanGB = $p.gb; @{ ok = $true; txt = "Clean now will free ≈ $($p.gb) GB ($($p.items.Count) folders)"; data = @{ gb = $p.gb; items = @($p.items | Select-Object -First 60) } } }
    '^(undo)$'       { @{ ok = $true; txt = (PD-Undo $a.undo) } }
    '^(save_usb)$'   { $u = A-Usb -Force; @{ ok = [bool]$u; txt = $(if ($u) { "Saved to $u" } else { 'No pendrive' }) } }
    '^(loader_log)$' { $lf = Join-Path $PD.Root 'log\loader.log'; @{ ok = $true; txt = 'Last updater log lines'; data = @($(if (Test-Path $lf) { Get-Content $lf -Tail 30 } else { 'no log' })) } }   # 1.25 read-only
    '^(update_now)$' { Set-Content (Join-Path $PD.Root 'req\update.flag') '1'; @{ ok = $true; txt = 'Update check asked' } }
    '^(mesh_install)$' { $r = A-MeshInstall $id; @{ ok = $r.ok; txt = $r.txt; data = @{ steps = @($r.steps) } } }
    '^(laptop)$'     { $S.laptop = $true; @{ ok = $true; txt = 'Super Admin laptop mode on' } }
    default {
      $fx = $kind -replace '^fix:',''
      if ($PD_FIX.Contains($fx)) { $S.fixing = $fx; A-Peers; $r = PD-Fix $fx $a $by $id; $S.fixing = $null; @{ ok = $r.ok; txt = $r.txt } }
      else { @{ ok = $false; txt = 'unknown command ' + $kind } }
    }
  }
}

# ---------- auto-fix (7): limits from lab/cfg/fix; heavy work pauses when busy; max N PCs at once ----------
function A-AutoFix {
  $c = PD-Cfg; if ($c.fix.auto -eq $false) { return }
  $m = $S.metrics; if (!$m) { return }
  $max = if ($c.fix.maxPcs) { [int]$c.fix.maxPcs } else { 5 }
  $try = {
    param($fx, $a)
    $why = PD-FixAllowed $fx -Auto
    if ($why -like 'deletes files*') {   # strict rule: ask, never delete by itself - one note a day per fix on the Console (+ laptop toast)
      $dk = 'ask_' + $fx + '_' + (PD-ISTDate); if (!$S.asked) { $S.asked = @{} }
      if (!$S.asked[$dk]) { $S.asked[$dk] = 1; $t = '🧹 ' + $env:COMPUTERNAME + ': ' + $PD_FIX[$fx].l + ' suggested - ' + $(if ($m.disk.cleanGB) { 'would free about ' + $m.disk.cleanGB + ' GB. ' } else { '' }) + 'Nothing is deleted until you tap it on the Console.'
        PD-Event 'ask' '🧹' $t @{ fix = $fx } | Out-Null; PD-Alert ('ask_' + $fx) $t 'Open the PC on the PC Doctor Console to see exactly what would be deleted, then tap the fix if you agree.' 'amber' }
      return }
    if ($why) { return }
    if ($PD_FIX[$fx].k -ne 'light' -and (A-FixingCount) -ge $max) { PD-Log "auto $fx waits: $max PCs already fixing"; return }
    $S.fixing = $fx; A-Peers; $r = PD-Fix $fx $a 'auto'; $S.fixing = $null; $r
  }
  # C: free < androidFreePct -> Android clean (only when Android Studio is closed), alert only if still red after
  $lim = if ($c.fix.androidFreePct) { [double]$c.fix.androidFreePct } else { 15 }
  if ($m.disk.cFreePct -lt $lim) { $r = & $try 'android_clean' @{}; if ($r -and $r.freePct -and $r.freePct -lt (PD-Thr 'cFreeRed' 5)) { PD-Alert 'cfull' "🟠 $env:COMPUTERNAME: C: still full after cleaning" $r.txt 'amber' } }
  # a program hung N times today and hangs now -> stop it (toast on the laptop: "hang fixed")
  $hung = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and !$_.Responding }
  foreach ($p in $hung) { if ([int]$S.hangs[$p.Name] -ge (PD-Thr 'hangN' 3)) { $r = & $try 'stop_program' @{ name = $p.Name }; if ($r -and $r.ok) { PD-Event 'fix' '🛠️' ("Hang fixed: stopped $($p.Name) (hung $($S.hangs[$p.Name]) times today)") | Out-Null } } }
  # stuck print jobs -> spooler restart
  if ($S.prn -and $S.prn.stuck -gt 0) { & $try 'spooler' @{} | Out-Null; $S.prn = PD-PrintCheck }
  # printer RPC errors -> RPC settings
  if ($S.prn -and $S.prn.code -match '11b|709|bcb') { & $try 'rpc_print' @{} | Out-Null }
  # damaged Windows -> sfc / DISM (heavy, background)
  if ($S.sfc -and $S.sfc.bad -gt 0) { & $try 'repair_windows' @{} | Out-Null }
  # downloads only (installs wait for a Thawed restart / free period)
  if ((Get-Date).Hour -ge 17 -or (Get-Date).Hour -lt 8) { & $try 'win_update_dl' @{} | Out-Null; & $try 'winget' @{} | Out-Null }
}
# 7: free timetable period (lab/tt via lab/cfg room) with nobody logged in -> restart-needing work may run
function A-FreePeriod {
  if (PD-InUse) { return $false }
  $c = PD-Cfg; $room = ''; if ($S.pc.grp -and $c.groups.($S.pc.grp)) { $room = [string]$c.groups.($S.pc.grp).room }
  $tt = PD-Db GET 'lab/cfg/tt'; if (!$tt -or !$room) { return $true }
  $ist = [DateTime]::UtcNow.AddHours(5.5); $day = $ist.ToString('ddd').ToUpper(); $hm = $ist.ToString('HH:mm')
  foreach ($sp in @($tt.labs.$room.$day)) { if ($sp -and $hm -ge $sp[0] -and $hm -lt $sp[1]) { return $false } }
  $true
}
function A-NeedRestart { $r = PD-SfcState; $mem = (& bcdedit /enum '{bootmgr}' 2>$null | Out-String) -match 'bootsequence\s+\{memdiag\}'; $dirty = (fsutil dirty query C: 2>$null | Out-String) -match 'is Dirty'
  $ren = $env:COMPUTERNAME -ne (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName').ComputerName
  $r.pendingReboot -or $mem -or $dirty -or $ren }
# 7: Deep Freeze Standard - run every queued fix once the PC is Thawed, then ask for Boot Frozen
function A-ThawRun {
  $q = @(PD-ReadJson (Join-Path $PD.Root 'state\thawq.json') | Where-Object { $_ })
  if (!$q.Count) { $dbq = PD-Db GET ('lab/pcs/' + (A-Hwid) + '/thawq'); if ($dbq) { $q = @($dbq) } }
  if (!$q.Count) { return }
  # 1.22 (user, 05-Nov-2026: "Thaw needed: GUJJAR, GUJJAR" on two laptops WITHOUT Deep Freeze): a queue left from an early wrong Frozen
  # reading waited forever - a PC with no Deep Freeze needs no Thaw: the queue is cleared (nothing is run by itself) and logged
  $dfs = (PD-DeepFreeze).state
  if ($dfs -eq 'none') { PD-WriteJson (Join-Path $PD.Root 'state\thawq.json') @(); PD-Db PUT ('lab/pcs/' + (A-Hwid) + '/thawq') $null | Out-Null
    PD-Event 'thaw' '🧹' ('No Deep Freeze on this PC - "Thaw needed" cleared (' + (@($q | ForEach-Object { [string]$_.fix }) -join ', ') + ' not run; run it from the Console if still needed)') | Out-Null; return }
  if ($dfs -ne 'thawed') { return }
  $done = @(); $restart = $false
  foreach ($x in $q) { $a = if ($x.args) { $x.args } else { @{} }; $a | Add-Member -NotePropertyName now -NotePropertyValue $true -Force -ErrorAction SilentlyContinue; if ($a -is [hashtable]) { $a.now = $true }
    $r = PD-Fix ([string]$x.fix) $a ([string]$x.by + ' (Thawed)'); $done += ($PD_FIX[[string]$x.fix].l + $(if ($r.ok) { ' ✅' } else { ' ❌' })); if ($r.restart) { $restart = $true } }
  PD-WriteJson (Join-Path $PD.Root 'state\thawq.json') @(); PD-Db PUT ('lab/pcs/' + (A-Hwid) + '/thawq') $null | Out-Null
  PD-Db PATCH ('lab/pcs/' + (A-Hwid)) @{ thawDone = @{ t = (PD-NowMs); list = $done; restart = $restart } } | Out-Null
  PD-Event 'thaw' '✅' ('Thawed fixes done: ' + ($done -join ', ') + ' - now set Boot Frozen') | Out-Null
  PD-Alert 'thaw_done' "✅ $env:COMPUTERNAME: Thawed fixes done" (($done -join ', ') + '. Now set Boot Frozen in Deep Freeze.') 'green'
}

# ---------- pendrive (9): auto-copy to a pendrive with DAVANLAB.key, no click ----------
function A-Usb([switch]$Force) {
  foreach ($d in @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2' -ErrorAction SilentlyContinue)) {
    $k = $d.DeviceID + '\DAVANLAB.key'; if (!(Test-Path $k)) { continue }
    $sig = $d.VolumeSerialNumber + (Get-Item $k).LastWriteTime.Ticks
    if (!$Force -and $S.usbSeen[$sig]) { continue }
    $S.usbSeen[$sig] = 1
    $f = PD-MakeDlh ($d.DeviceID + '\DavanLab'); PD-Log "pendrive: saved $f"
    PD-Event 'usb' '💾' ('Report saved to pendrive: ' + (Split-Path $f -Leaf)) | Out-Null
    PD-RunUsbFix $d.DeviceID
    return $f
  }
  $null
}
function A-MeshInstall([string]$cid = '') {
  # 1.47 (user, 05-Nov-2026: "show the progress here, what is happening, make a log"): every step goes to the agent log and, for a Console
  # command, to lab/res/<h>/<cid>.steps so the Remote screen page shows it live (📋 Copy); a failure says which step and why
  $h = A-Hwid; $st = New-Object System.Collections.ArrayList
  $step = { param($txt) [void]$st.Add(((Get-Date).ToString('HH:mm:ss') + ' ' + $txt)); PD-Log ('remote agent: ' + $txt)
    if ($cid) { PD-Db PATCH ('lab/res/' + $h + '/' + $cid) @{ st = 'running'; t = (PD-NowMs); kind = 'mesh_install'; steps = @($st) } | Out-Null } }
  try {
    & $step ('Agent ' + (A-Ver) + ', Deep Freeze: ' + (PD-DeepFreeze).state + ', Windows ' + $env:COMPUTERNAME)
    $svc = Get-Service 'Mesh Agent' -ErrorAction SilentlyContinue
    if ($svc) { & $step ('Remote agent already installed - service ' + $svc.Status)
      if ($svc.Status -ne 'Running') { Start-Service 'Mesh Agent' -ErrorAction SilentlyContinue; Start-Sleep 5; & $step ('Service started: ' + (Get-Service 'Mesh Agent').Status) } }
    else {
      $c = PD-Cfg -Force; if (!$c.meshGroup) { & $step 'FAILED: remote server not set up yet (no device group in lab/cfg)'; return @{ ok = $false; txt = 'No device group'; steps = @($st) } }
      $u = ([string]$c.meshUrl).TrimEnd('/') + '/meshagents?id=4&meshid=' + ($c.meshGroup -replace '^mesh//','') + '&installflags=0'
      $x = Join-Path $PD.Root 'dl\meshagent.exe'; New-Item -ItemType Directory -Force (Split-Path $x) | Out-Null
      & $step ('1/4 Downloading the remote agent from ' + ([string]$c.meshUrl))
      try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing $u -OutFile $x -TimeoutSec 300 }
      catch { & $step ('FAILED at download: ' + $_.Exception.Message); return @{ ok = $false; txt = 'Download failed: ' + $_.Exception.Message; steps = @($st) } }
      $kb = [math]::Round((Get-Item $x).Length / 1KB); & $step ("2/4 Downloaded $kb KB")
      if ($kb -lt 500) { & $step 'FAILED: the file is too small - the server sent an error page, not the agent'; return @{ ok = $false; txt = 'Bad download'; steps = @($st) } }
      & $step '3/4 Installing (meshagent -fullinstall)'
      $pr = Start-Process $x -ArgumentList '-fullinstall' -Wait -WindowStyle Hidden -PassThru
      & $step ('Installer finished, exit code ' + $pr.ExitCode)
    }
    $id = ''; foreach ($i in 1..12) { $svc = Get-Service 'Mesh Agent' -ErrorAction SilentlyContinue; $id = PD-MeshNode; if ($svc -and $svc.Status -eq 'Running' -and $id) { break }; Start-Sleep 5 }
    if (!$svc) { & $step 'FAILED: no "Mesh Agent" service after the install (antivirus may have blocked meshagent.exe)'; return @{ ok = $false; txt = 'Service missing'; steps = @($st) } }
    & $step ('4/4 Service ' + $svc.Status + ', remote id ' + $(if ($id) { $id.Substring(0, [math]::Min(12, $id.Length)) + '…' } else { 'NOT found yet (registry Open Source\MeshAgent2 NodeId)' }))
    if ($id) { PD-Db PATCH ('lab/pcs/' + $h) @{ meshId = $id } | Out-Null; $S.meshSent = $id; & $step 'Remote id sent to the Console - tap 🖥️ Screen'
      if ((PD-DeepFreeze).state -eq 'frozen') { & $step 'Note: this PC reads Frozen - Deep Freeze removes the remote agent at the next restart (it installs again by itself)' }
      return @{ ok = $true; txt = 'Remote screen ready'; steps = @($st) } }
    $rk = @(foreach ($root in 'HKLM:\SOFTWARE\Open Source', 'HKLM:\SOFTWARE\WOW6432Node\Open Source') { foreach ($k in @(Get-ChildItem $root -ErrorAction SilentlyContinue)) { $pn = @((Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { $_.Name }); ($k.PSChildName + ' [' + ($pn -join ',') + ']') } })
    & $step ('Registry Open Source keys: ' + $(if ($rk.Count) { $rk -join '; ' } else { 'none' }))
    @{ ok = $false; txt = 'Installed, but no remote id found'; steps = @($st) }
  } catch { & $step ('FAILED: ' + $_.Exception.Message); @{ ok = $false; txt = 'error: ' + $_.Exception.Message; steps = @($st) } }
}

# ---------- main ----------
function A-Minute {
  # 1.4: the sample is $smp - PowerShell names are case-blind, "$s =" here replaced the agent state $S (ring null, no minute rows)
  $smp = PD-Sample
  [void]$S.ring.Add($smp); while ($S.ring.Count -gt 10) { $S.ring.RemoveAt(0) }
  PD-WriteJson (Join-Path $PD.Root 'state\ring.json') @($S.ring)
  if (!$S.verdict) { A-Verdict }
  $h = A-Hwid; $now = A-Now $smp
  PD-Db PUT ('lab/live/' + $h + '/m' + [int64]([math]::Floor($smp.t / 60000))) (A-Live $smp) | Out-Null
  PD-Db PUT ('lab/now/' + $h) $now | Out-Null
  PD-WriteJson (Join-Path $PD.Root 'state\now.json') $now
  # hourly lab load (lab/load/<IST date>/<HH>/<hwid> = running averages of this hour) - the Console's load chart reads this, not raw rows
  $ist = [DateTime]::UtcNow.AddHours(5.5); $hk = $ist.ToString('yyyy-MM-dd') + '/' + $ist.ToString('HH')
  if ($S.hk -ne $hk) { $S.hk = $hk; $S.hn = 0; $S.hc = 0; $S.hr = 0; $S.hb = 0; $S.hu = 0 }
  $S.hn++; $S.hc += $smp.cpu; $S.hr += $smp.ram; $S.hb += $smp.busy; if ($smp.user) { $S.hu++ }
  PD-Db PUT ('lab/load/' + $hk + '/' + $h) @{ c = [math]::Round($S.hc / $S.hn); r = [math]::Round($S.hr / $S.hn); b = [math]::Round($S.hb / $S.hn); n = $S.hn; u = $S.hu } | Out-Null
  PD-WriteJson (Join-Path $PD.Root 'state\lastrow.json') @{ t = $smp.t }
  $tp = PD-ThawPath; if ($tp) { PD-WriteJson "$tp\lastrow.json" @{ t = $smp.t } }
  Set-Content (Join-Path $PD.Root 'state\hb.txt') (PD-NowMs)
}
function A-Laptop {
  # 8: the Super Admin laptop reads the whole grid (DB5 rules allow it only for lab/salap PCs)
  $g = PD-Db GET 'lab/now'; if (!$g) { $S.laptop = $false; Remove-Item (Join-Path $PD.Root 'state\laptop.flag') -ErrorAction SilentlyContinue; return }
  $S.laptop = $true; try { Set-Content (Join-Path $PD.Root 'state\laptop.flag') '1' } catch {}; $pcs = PD-Db GET 'lab/pcs'
  PD-WriteJson (Join-Path $PD.Root 'state\grid.json') @{ t = (PD-NowMs); now = $g; pcs = $pcs; sum = (PD-Db GET ('lab/sum/' + (PD-ISTDate))); fix = (PD-Db GET ('lab/fixlog/' + (PD-ISTDate))) }
}

if ($Mode -eq 'mesh') { PD-LoadId | Out-Null; A-MeshInstall; exit 0 }
try { PD-TrayLauncher | Out-Null } catch {}
if ($Mode -eq 'once') { PD-Token | Out-Null; A-SyncPc; A-Daily -Force; A-Events; A-Verdict; A-Minute; A-Peers; exit 0 }
if ($Mode -eq 'test') {
  $S.test = $true; $PD.Test = $true
  # used by the Windows runner check: everything that reads the PC, no DB5
  $r = @{ sample = (PD-Sample); inv = (PD-Inventory); startup = (PD-Startup); net = (PD-NetCheck); prn = (PD-PrintCheck); sfc = (PD-SfcState); bsod = (PD-Bsod); events = @(PD-ReadEvents (Get-Date).AddDays(-2) 5).Count; plan = (PD-AndroidPlan).gb }
  $S.inv = ($r.inv | ConvertTo-Json -Depth 8 -Compress | ConvertFrom-Json); $PD.Cfg = (Get-Content "$here\..\cfg-default.json" -Raw -Encoding UTF8 | ConvertFrom-Json); $PD.CfgAt = (Get-Date).AddYears(1)
  $v = PD-Verdict @{ smart = @{ realloc = 3 }; disk = @{ cFreePct = 50 } }
  $r.verdictTest = $v.v + ' | ' + $v.why
  $S.ev7 = @(PD-ReadEvents (Get-Date).AddDays(-7) 20 | ConvertTo-Json -Depth 4 | ConvertFrom-Json); $S.startup = $r.startup; $S.net = $r.net; $S.prn = $r.prn; $S.sfc = $r.sfc
  $mm = A-Metrics; $r.metricsTest = 'C: free ' + $mm.disk.cFreePct + '% · RAM sticks ' + $mm.inv.ramSticks + ' · hang top ' + $mm.ev.hangTop; $r.verdictNow = (PD-Verdict $mm).v
  $r | ConvertTo-Json -Depth 6 | Set-Content "$env:TEMP\pd_test.json" -Encoding UTF8
  "sample cpu=$($r.sample.cpu) ram=$($r.sample.ram) busy=$($r.sample.busy) | inv model=$($r.inv.model) disks=$(@($r.inv.disks).Count) sw=$(@($r.inv.software).Count) | events=$($r.events) | verdict test: $($r.verdictTest) | metrics: $($r.metricsTest) | this PC: $($r.verdictNow)"
  exit 0
}

PD-Log ('agent start, version ' + (A-Ver))
# 1.32: a new loader.ps1 (e.g. the 5-minute check) is used by the running loader only after it restarts - the service restarts it within 30 s,
# so: when loader.ps1 on disk is newer than the running loader, stop that loader and end this agent; the new loader starts a fresh agent
try { $lf = Get-Item (Join-Path $PD.Root 'loader.ps1') -ErrorAction Stop; $svc = Get-Service PCDoctorSvc -ErrorAction SilentlyContinue
  if ($svc -and $svc.Status -eq 'Running') { $stale = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'DavanPCDoctor\\loader\.ps1' -and $_.CreationDate -lt $lf.LastWriteTime })
    if ($stale.Count) { foreach ($pp in $stale) { Invoke-CimMethod -InputObject $pp -MethodName Terminate | Out-Null }; PD-Log 'loader.ps1 is newer than the running loader - loader restarted by the service, agent restarts with it'; exit 0 } } } catch {}
# 1.32: installed with no internet (offline pendrive install) = no id.json yet: register by itself as soon as there is internet (keep a Deep Freeze PC THAWED until it shows on the Console)
while (!(PD-LoadId)) { PD-Log 'no id.json yet - registering when the internet is there'; try { PD-Register -New | Out-Null } catch { PD-Log ('register failed: ' + $_.Exception.Message) }; if (PD-LoadId) { break }; Start-Sleep 120 }
$first = $true
while ($true) {
  try {
    $t0 = Get-Date
    if ($first -or ($t0 - $S.lastHour).TotalMinutes -ge 60) {
      PD-Cfg -Force | Out-Null; A-SyncPc; A-VerReport; A-Daily; $S.verdict = $null; $S.lastHour = $t0
      if (!$first) { A-AutoFix }
      # 7: restart-needing work (chkdsk / RAM test / updates / rename) waits for a free period with nobody logged in - never a PC in use
      if (!$first -and (PD-ReadJson (Join-Path $PD.Root 'state\fixhist.json')) -and [string]$S.pc.autoRst -ne (PD-ISTDate) -and (A-NeedRestart) -and (A-FreePeriod)) { PD-Log 'free period, nobody logged in - restart for the waiting fixes'; PD-Db PATCH ('lab/pcs/' + (A-Hwid)) @{ autoRst = (PD-ISTDate) } | Out-Null; Fix-restart @{} | Out-Null }   # once a day at most (a Frozen PC can never clear its flags)
      if ($S.pc.mesh -ne $false -and !(Get-Service 'Mesh Agent' -ErrorAction SilentlyContinue)) { $r = A-MeshInstall; PD-Log ('remote agent: ' + $r.txt) }
      # 1.46 (user, 05-Nov-2026: "can't connect B1 Remote screen" - no PC had a meshId): the remote agent's id was sent only with the daily
      # inventory, which runs BEFORE the agent installs it (and a Frozen PC installs it again, with a new id, at every start) - now sent every hour
      $mn = PD-MeshNode; if ($mn -and $mn -ne [string]$S.meshSent) { PD-Db PATCH ('lab/pcs/' + (A-Hwid)) @{ meshId = $mn } | Out-Null; $S.meshSent = $mn; PD-Log 'remote agent id sent' }
    }
    A-Events; A-Minute; A-Cmds; A-TrayEdits; A-TrayReq
    if ($first -or ($t0 - $S.last5).TotalMinutes -ge 5) { $S.last5 = $t0; A-Peers; PD-FlushQueue | Out-Null; A-TrayFresh; A-ThawRun; A-Laptop; A-Usb | Out-Null; A-Verdict }
    $first = $false
    foreach ($i in 1..4) { Start-Sleep -Seconds 14; if (Test-Path (Join-Path $PD.Root 'req\now.flag')) { Remove-Item (Join-Path $PD.Root 'req\now.flag') -Force; A-Daily -Force; A-Verdict; A-Minute }; A-TrayEdits; A-TrayReq; A-Cmds; A-LabPoll }   # 1.36: commands are picked up every 14 s (was once a minute)
  } catch { PD-Log ('loop error: ' + $_.Exception.Message + ' @ ' + $_.InvocationInfo.ScriptLineNumber); Start-Sleep 30 }
}
