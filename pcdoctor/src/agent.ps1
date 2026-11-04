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

function A-Now([hashtable]$s) {
  $v = $S.verdict; $df = PD-DeepFreeze
  if ($df.state -eq 'thawed' -and !$S.dfSince) { $S.dfSince = PD-NowMs } elseif ($df.state -ne 'thawed') { $S.dfSince = 0 }
  $tq = @(PD-ReadJson (Join-Path $PD.Root 'state\thawq.json')).Count
  $ip = ''; try { $ip = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress } catch {}
  @{ t = $s.t; cpu = $s.cpu; ram = $s.ram; busy = $s.busy; lat = $s.lat; cfree = $s.cfree; cfreeGB = $s.cfreeGB; temp = $(if ($s.temp) { $s.temp.cpu } else { $null })
     freq = $s.freq; net = $s.net; user = $s.user; top = @($s.top | Select-Object -First 3)
     lv = $v.lv; v = $v.v; vk = $v.vk; why = $v.why; conf = $v.conf; fix = $v.fix
     df = $df.state; dfSince = $S.dfSince; thaw = [bool]$df.thaw; thawQ = $tq; boot = [int64](([datetimeoffset]$S.boot).ToUnixTimeMilliseconds())
     ver = (A-Ver); name = $env:COMPUTERNAME; ip = $ip; q = (PD-QueueCount); online = $PD.Online; pp = $S.pp; fixing = $S.fixing }
}
function A-Live([hashtable]$s) {
  @{ t = $s.t; c = $s.cpu; r = $s.ram; b = $s.busy; l = $s.lat; q = $s.q; h = $s.hf; f = $s.cfree; n = $s.net; fr = $s.freq; u = $s.user
     tc = $(if ($s.temp) { $s.temp.cpu } else { $null }); td = $(if ($s.temp) { $s.temp.disk } else { $null })
     p = @($s.top | ForEach-Object { $_.n + '|' + $_.c + '|' + $_.m + '|' + $_.io }); pr = @($s.ramTop | ForEach-Object { $_.n + '|' + $_.m }); pi = @($s.ioTop | ForEach-Object { $_.n + '|' + $_.io }) }
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
  if (!$pc.name) { $up.name = $env:COMPUTERNAME }
  if (!$pc.grp) { $g = PD-Group ([string]$(if ($pc.name) { $pc.name } else { $env:COMPUTERNAME })); if ($g) { $up.grp = $g } }
  $model = (Get-CimInstance Win32_ComputerSystem); $up.model = ($model.Manufacturer + ' ' + $model.Model).Trim(); $up.seen = PD-NowMs; $up.ver = A-Ver
  # Console renamed the PC (name != Windows name) -> rename Windows (a Frozen PC: at a Thawed restart)
  $want = [string]$(if ($pc.name) { $pc.name } else { '' })
  if ($want -and $want -ne $env:COMPUTERNAME -and $pc.renameReq -and $want -ne $S.renamed) { $r = PD-Fix 'rename' @{ name = $want } 'Console'; $S.renamed = $want }
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
  $q = PD-ReadJson "$r\ai.json"
  if ($q) { Remove-Item "$r\ai.json" -Force
    $a = try { Invoke-RestMethod -Method Post -Uri ($PD.Worker + '/lab/ai') -Body (PD-Json @{ token = (PD-Token); prompt = [string]$q.prompt; history = @($q.history) }) -ContentType 'text/plain' -TimeoutSec 60 } catch { @{ ok = $false; msg = $_.Exception.Message } }
    PD-WriteJson (Join-Path $PD.Root 'state\ai.json') @{ t = (PD-NowMs); ok = $a.ok; text = $a.text; msg = $a.msg; left = $a.left } }
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
  @{
    smart = @{ realloc = [int]($sm | Measure-Object realloc -Sum).Sum; pending = [int]($sm | Measure-Object pending -Sum).Sum; uncorr = [int]($sm | Measure-Object uncorr -Sum).Sum; crc = [int]($sm | Measure-Object crc -Maximum).Maximum; wear = [int]($sm | Measure-Object wear -Maximum).Maximum }
    ev = @{ disk7 = @($list | Where-Object { $_.k -eq 'disk' -and $_.id -eq 7 }).Count; whea = (& $cnt 'whea'); scm = (& $cnt 'scm'); apperr = (& $cnt 'apperr'); throttle = (& $cnt 'throttle')
            hangTop = [string]$hang.Name; hangTopN = [int]$hang.Count; kp41nob = @($list | Where-Object { $_.k -eq 'kp41' -and $_.nobsod }).Count; clockJump = @($list | Where-Object { $_.k -eq 'clock' -and $_.jump -lt -60 }).Count }
    mdiag = @{ fail = @($list | Where-Object { $_.k -eq 'mdiag' -and $_.id -in 1202,1102 }).Count }
    bsod = @{ n7 = $bs.Count; ram = [int]$bsk['ram']; windows = [int]$bsk['windows']; last = $(if ($bs.Count) { ($bs | Select-Object -Last 1).code } else { '' }) }
    perf = @{ latP95 = (& $p95 ($perf | ForEach-Object { if ($_.l -ne $null) { $_.l } else { $_.lat } })); busyP95 = (& $p95 ($perf | ForEach-Object { if ($_.b -ne $null) { $_.b } else { $_.busy } }))
              ramP95 = (& $p95 ($perf | ForEach-Object { if ($_.r -ne $null) { $_.r } else { $_.ram } })); faultsP95 = (& $p95 ($perf | ForEach-Object { if ($_.h -ne $null) { $_.h } else { $_.hf } }))
              tempMax = ($perf | ForEach-Object { $_.tc } | Measure-Object -Maximum).Maximum; freqMin = ($perf | ForEach-Object { $_.fr } | Where-Object { $_ } | Measure-Object -Minimum).Minimum }
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
    '^(update_now)$' { Set-Content (Join-Path $PD.Root 'req\update.flag') '1'; @{ ok = $true; txt = 'Update check asked' } }
    '^(mesh_install)$' { @{ ok = $true; txt = (A-MeshInstall) } }
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
    $why = PD-FixAllowed $fx -Auto; if ($why) { return }
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
  if (!$q.Count -or (PD-DeepFreeze).state -ne 'thawed') { return }
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
function A-MeshInstall {
  if (Get-Service 'Mesh Agent' -ErrorAction SilentlyContinue) { return 'MeshCentral agent already installed' }
  $c = PD-Cfg -Force; if (!$c.meshGroup) { return 'Remote server not set up yet (no device group)' }
  $u = ([string]$c.meshUrl).TrimEnd('/') + '/meshagents?id=4&meshid=' + ($c.meshGroup -replace '^mesh//','') + '&installflags=0'
  $x = Join-Path $PD.Root 'dl\meshagent.exe'
  Invoke-WebRequest -UseBasicParsing $u -OutFile $x -TimeoutSec 300
  Start-Process $x -ArgumentList '-fullinstall' -Wait -WindowStyle Hidden
  if (Get-Service 'Mesh Agent' -ErrorAction SilentlyContinue) { 'MeshCentral agent installed' } else { 'MeshCentral agent did not install' }
}

# ---------- main ----------
function A-Minute {
  $s = PD-Sample
  [void]$S.ring.Add($s); while ($S.ring.Count -gt 10) { $S.ring.RemoveAt(0) }
  PD-WriteJson (Join-Path $PD.Root 'state\ring.json') @($S.ring)
  if (!$S.verdict) { A-Verdict }
  $h = A-Hwid; $now = A-Now $s
  PD-Db PUT ('lab/live/' + $h + '/m' + [int64]([math]::Floor($s.t / 60000))) (A-Live $s) | Out-Null
  PD-Db PUT ('lab/now/' + $h) $now | Out-Null
  PD-WriteJson (Join-Path $PD.Root 'state\now.json') $now
  # hourly lab load (lab/load/<IST date>/<HH>/<hwid> = running averages of this hour) - the Console's load chart reads this, not raw rows
  $ist = [DateTime]::UtcNow.AddHours(5.5); $hk = $ist.ToString('yyyy-MM-dd') + '/' + $ist.ToString('HH')
  if ($S.hk -ne $hk) { $S.hk = $hk; $S.hn = 0; $S.hc = 0; $S.hr = 0; $S.hb = 0; $S.hu = 0 }
  $S.hn++; $S.hc += $s.cpu; $S.hr += $s.ram; $S.hb += $s.busy; if ($s.user) { $S.hu++ }
  PD-Db PUT ('lab/load/' + $hk + '/' + $h) @{ c = [math]::Round($S.hc / $S.hn); r = [math]::Round($S.hr / $S.hn); b = [math]::Round($S.hb / $S.hn); n = $S.hn; u = $S.hu } | Out-Null
  PD-WriteJson (Join-Path $PD.Root 'state\lastrow.json') @{ t = $s.t }
  $tp = PD-ThawPath; if ($tp) { PD-WriteJson "$tp\lastrow.json" @{ t = $s.t } }
  Set-Content (Join-Path $PD.Root 'state\hb.txt') (PD-NowMs)
}
function A-Laptop {
  # 8: the Super Admin laptop reads the whole grid (DB5 rules allow it only for lab/salap PCs)
  $g = PD-Db GET 'lab/now'; if (!$g) { $S.laptop = $false; return }
  $S.laptop = $true; $pcs = PD-Db GET 'lab/pcs'
  PD-WriteJson (Join-Path $PD.Root 'state\grid.json') @{ t = (PD-NowMs); now = $g; pcs = $pcs; sum = (PD-Db GET ('lab/sum/' + (PD-ISTDate))); fix = (PD-Db GET ('lab/fixlog/' + (PD-ISTDate))) }
}

if ($Mode -eq 'mesh') { PD-LoadId | Out-Null; A-MeshInstall; exit 0 }
if ($Mode -eq 'once') { PD-Token | Out-Null; A-SyncPc; A-Daily -Force; A-Events; A-Verdict; A-Minute; A-Peers; exit 0 }
if ($Mode -eq 'test') {
  $S.test = $true
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
while (!(PD-LoadId)) { PD-Log 'no id.json yet - waiting for PCDoctor-Setup'; Start-Sleep 300 }
$first = $true
while ($true) {
  try {
    $t0 = Get-Date
    if ($first -or ($t0 - $S.lastHour).TotalMinutes -ge 60) {
      PD-Cfg -Force | Out-Null; A-SyncPc; A-VerReport; A-Daily; $S.verdict = $null; $S.lastHour = $t0
      if (!$first) { A-AutoFix }
      # 7: restart-needing work (chkdsk / RAM test / updates / rename) waits for a free period with nobody logged in - never a PC in use
      if (!$first -and (PD-ReadJson (Join-Path $PD.Root 'state\fixhist.json')) -and [string]$S.pc.autoRst -ne (PD-ISTDate) -and (A-NeedRestart) -and (A-FreePeriod)) { PD-Log 'free period, nobody logged in - restart for the waiting fixes'; PD-Db PATCH ('lab/pcs/' + (A-Hwid)) @{ autoRst = (PD-ISTDate) } | Out-Null; Fix-restart @{} | Out-Null }   # once a day at most (a Frozen PC can never clear its flags)
      if ($S.pc.mesh -ne $false -and !(Get-Service 'Mesh Agent' -ErrorAction SilentlyContinue)) { PD-Log (A-MeshInstall) }
    }
    A-Events; A-Minute; A-Cmds; A-TrayEdits; A-TrayReq
    if ($first -or ($t0 - $S.last5).TotalMinutes -ge 5) { $S.last5 = $t0; A-Peers; PD-FlushQueue | Out-Null; A-ThawRun; A-Laptop; A-Usb | Out-Null; A-Verdict }
    $first = $false
    foreach ($i in 1..4) { Start-Sleep -Seconds 14; if (Test-Path (Join-Path $PD.Root 'req\now.flag')) { Remove-Item (Join-Path $PD.Root 'req\now.flag') -Force; A-Daily -Force; A-Verdict; A-Minute }; A-TrayEdits; A-TrayReq; if ($i -eq 2) { A-Cmds } }
  } catch { PD-Log ('loop error: ' + $_.Exception.Message + ' @ ' + $_.InvocationInfo.ScriptLineNumber); Start-Sleep 30 }
}
