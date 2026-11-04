# Davan PC Doctor - fixes.ps1 (ROADMAP-pcdoctor.md 7). Every fix returns @{ ok; txt; undo } and is logged to lab/fixlog/<date>/<hwid>.
# Light fixes run at once (also during lab); heavy ones run at low priority and pause when the PC is busy; restart-needing ones wait for
# shutdown / a free period with nobody logged in / ✅ now; on a Frozen PC a permanent fix goes to the "needs Thawed" queue.
# Never deletes student source code. Never restarts a PC in use.

$PD_FIX = [ordered]@{
  # name            kind      label (Console button / log)               switch in lab/cfg/fix/sw
  'clean_temp'    = @{ k = 'light';   l = 'Clean temp + crash dumps';       sw = 'clean_temp' }
  'stop_program'  = @{ k = 'light';   l = 'Stop a program';                 sw = 'stop_hung' }
  'spooler'       = @{ k = 'light';   l = 'Restart print spooler + clear stuck jobs'; sw = 'spooler' }
  'net_private'   = @{ k = 'light';   l = 'Network Private + discovery + File & Printer Sharing'; sw = 'net_private'; perm = $true }
  'rpc_print'     = @{ k = 'light';   l = 'Printer RPC settings (0x11b / 0x709 / 0xbcb)'; sw = 'rpc_print'; perm = $true }
  'printer_driver'= @{ k = 'light';   l = 'Install printer driver';         sw = 'printer_driver'; perm = $true }
  'printer_ip'    = @{ k = 'light';   l = 'Add printer by IP';              sw = 'printer_driver'; perm = $true }
  'smb_share'     = @{ k = 'light';   l = 'Shared folder / printer (SMB 24H2) + saved login'; sw = 'smb_share'; perm = $true }
  'startup_off'   = @{ k = 'light';   l = 'Turn off a startup item';        sw = 'startup_off'; perm = $true }
  'repair_windows'= @{ k = 'heavy';   l = 'Repair Windows (sfc / DISM)';    sw = 'sfc_dism'; perm = $true }
  'android_clean' = @{ k = 'heavy';   l = 'Android clean';                  sw = 'android_clean' }
  'clean'         = @{ k = 'heavy';   l = 'Clean now';                      sw = 'android_clean' }
  'winget'        = @{ k = 'heavy';   l = 'Software updates (winget)';      sw = 'winget'; perm = $true }
  'win_update_dl' = @{ k = 'heavy';   l = 'Download Windows updates';       sw = 'win_update_dl' }
  'check_disk'    = @{ k = 'restart'; l = 'Check disk (chkdsk at restart)'; sw = 'chkdsk'; perm = $true }
  'ram_test'      = @{ k = 'restart'; l = 'RAM test (at restart)';          sw = 'ram_test'; perm = $true }
  'update_install'= @{ k = 'restart'; l = 'Install Windows updates';        sw = 'update_install'; perm = $true }
  'rename'        = @{ k = 'restart'; l = 'Rename this PC';                 sw = 'rename'; perm = $true }
  'restart'       = @{ k = 'restart'; l = 'Restart';                        sw = $null }
  'rollback_driver'=@{ k = 'restart'; l = 'Roll back driver';               sw = $null; perm = $true }
  'uninstall_update'=@{ k = 'restart'; l = 'Uninstall update + block it';   sw = $null; perm = $true }
  'crash_reader'  = @{ k = 'heavy';   l = 'Install the crash reader (cdb)'; sw = $null }
}
function PD-FixLog([string]$fix, $res, [string]$by, [string]$cid = '') {
  $t = PD-NowMs
  PD-Db PUT ('lab/fixlog/' + (PD-ISTDate $t) + '/' + (PD-Hwid) + '/f' + $t) @{ t = $t; fix = $fix; label = $PD_FIX[$fix].l; ok = [bool]$res.ok; txt = [string]$res.txt; by = $by; cid = $cid; undo = $res.undo } | Out-Null
  $hist = PD-ReadJson (Join-Path $PD.Root 'state\fixhist.json'); if (!$hist) { $hist = @{} } else { $h2 = @{}; $hist.PSObject.Properties | ForEach-Object { $h2[$_.Name] = $_.Value }; $hist = $h2 }
  $hist[$fix] = $t; PD-WriteJson (Join-Path $PD.Root 'state\fixhist.json') $hist
}
function PD-FixAllowed([string]$fix, [switch]$Auto) {
  $c = PD-Cfg; $f = $c.fix
  if ($Auto) {
    if ($f.auto -eq $false) { return 'Auto-fix is switched off' }
    $sw = $PD_FIX[$fix].sw; if ($sw -and $f.sw -and $f.sw.$sw -eq $false) { return "switch '$sw' is off" }
    $hist = PD-ReadJson (Join-Path $PD.Root 'state\fixhist.json')
    if ($hist -and $hist.$fix -and ((PD-NowMs) - [int64]$hist.$fix) -lt ([double]$(if ($f.weekGap) { $f.weekGap } else { 7 }) * 86400000)) { return 'same fix ran less than a week ago' }
  }
  ''
}
function PD-Busy {
  # heavy work pauses when the disk is > heavyBusy % busy or a student program is waiting on the CPU
  $c = PD-Cfg; $lim = if ($c.fix.heavyBusy) { [int]$c.fix.heavyBusy } else { 80 }
  $d = (Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'").PercentDiskTime
  $q = (Get-CimInstance Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
  ($d -gt $lim) -or ($q -gt 2 * [Environment]::ProcessorCount)
}
function PD-RunLow([string]$exe, [string]$argList, [int]$maxMin = 120) {
  # low CPU + I/O priority, pauses (suspends) while the PC is busy
  $p = Start-Process -FilePath $exe -ArgumentList $argList -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PD.Root 'out\run.txt')
  try { $p.PriorityClass = 'Idle' } catch {}
  $t0 = Get-Date
  while (!$p.HasExited -and ((Get-Date) - $t0).TotalMinutes -lt $maxMin) {
    Start-Sleep 20
    if (PD-Busy) { PD-Suspend $p.Id $true; do { Start-Sleep 30 } while ((PD-Busy) -and ((Get-Date) - $t0).TotalMinutes -lt $maxMin); PD-Suspend $p.Id $false }
  }
  if (!$p.HasExited) { try { $p.Kill() } catch {}; return @{ code = -1; out = 'stopped after ' + $maxMin + ' min' } }
  @{ code = $p.ExitCode; out = (Get-Content (Join-Path $PD.Root 'out\run.txt') -Raw -ErrorAction SilentlyContinue) }
}
Add-Type -ErrorAction SilentlyContinue -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class PDNt { [DllImport("ntdll.dll")] public static extern int NtSuspendProcess(IntPtr h); [DllImport("ntdll.dll")] public static extern int NtResumeProcess(IntPtr h); }
'@
function PD-Suspend([int]$id, [bool]$on) { try { $p = Get-Process -Id $id; if ($on) { [PDNt]::NtSuspendProcess($p.Handle) | Out-Null } else { [PDNt]::NtResumeProcess($p.Handle) | Out-Null } } catch {} }
function PD-Frozen { (PD-DeepFreeze).state -eq 'frozen' }
function PD-ThawQueue([string]$fix, $fargs, [string]$by) {
  $f = Join-Path $PD.Root 'state\thawq.json'; $q = @(PD-ReadJson $f); $q = @($q | Where-Object { $_ -and $_.fix -ne $fix })
  $q += @{ fix = $fix; args = $fargs; by = $by; t = (PD-NowMs) }; PD-WriteJson $f $q
  # the queue must survive the Frozen restart: kept in DB5 too (lab/pcs/<h>/thawq), the Console shows "Thaw needed: N fixes"
  PD-Db PUT ('lab/pcs/' + (PD-Hwid) + '/thawq') $q | Out-Null
  @{ ok = $true; txt = 'Needs Thawed - queued (' + $q.Count + ' waiting). Set Boot Thawed in Deep Freeze; PC Doctor runs it after the restart.'; queued = $true }
}

function PD-Fix([string]$fix, $a, [string]$by = 'auto', [string]$cid = '') {
  if (!$PD_FIX.Contains($fix)) { return @{ ok = $false; txt = 'unknown fix ' + $fix } }
  $meta = $PD_FIX[$fix]
  if ($meta.perm -and $meta.k -ne 'light' -and (PD-Frozen) -and !$a.now) { $r = PD-ThawQueue $fix $a $by; PD-FixLog $fix $r $by $cid; return $r }
  PD-Log "fix $fix by $by"
  $r = try { & ('Fix-' + $fix) $a } catch { @{ ok = $false; txt = 'error: ' + $_.Exception.Message } }
  if ($meta.perm -and $meta.k -eq 'light' -and (PD-Frozen) -and $r.ok) { $r.txt += ' (Frozen PC: lasts until restart - a permanent copy is queued for Thawed)'; PD-ThawQueue $fix $a $by | Out-Null }
  PD-FixLog $fix $r $by $cid
  $r
}

# ---------- light ----------
function Fix-clean_temp($a) {
  $before = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
  foreach ($p in @("$env:SystemRoot\Temp\*", "$env:SystemRoot\Minidump\*.dmp", "$env:SystemRoot\LiveKernelReports\*.dmp", "$env:ProgramData\Microsoft\Windows\WER\ReportArchive\*", "$env:ProgramData\Microsoft\Windows\WER\ReportQueue\*", "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization\Cache\*")) {
    Get-ChildItem $p -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-2) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
  foreach ($u in PD-UserDirs) { foreach ($p in "$($u.FullName)\AppData\Local\Temp\*", "$($u.FullName)\AppData\Local\CrashDumps\*") {
    Get-ChildItem $p -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-2) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }
  $gb = [math]::Round(((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace - $before) / 1GB, 2)
  @{ ok = $true; txt = "Freed $gb GB (temp files + crash dumps)" }
}
function Fix-stop_program($a) {
  $n = [string]$a.name; if (!$n) { $hung = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and !$_.Responding } | Select-Object -First 1; if ($hung) { $n = $hung.Name } }
  if (!$n) { return @{ ok = $false; txt = 'No hung program found' } }
  if ($n -match '^(csrss|wininit|winlogon|lsass|services|smss|svchost|explorer|System|dwm|MeshAgent|powershell)$') { return @{ ok = $false; txt = "$n is part of Windows - not stopped" } }
  $ps = @(Get-Process -Name $n -ErrorAction SilentlyContinue); $ps | Stop-Process -Force -ErrorAction SilentlyContinue
  @{ ok = $ps.Count -gt 0; txt = $(if ($ps.Count) { "Stopped $n ($($ps.Count) process" + $(if ($ps.Count -ne 1) { 'es' }) + ')' } else { "$n is not running" }) }
}
function Fix-spooler($a) {
  Stop-Service Spooler -Force -ErrorAction SilentlyContinue
  $n = @(Get-ChildItem "$env:SystemRoot\System32\spool\PRINTERS\*" -ErrorAction SilentlyContinue).Count
  Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
  Start-Service Spooler -ErrorAction SilentlyContinue
  @{ ok = ((Get-Service Spooler).Status -eq 'Running'); txt = "Print spooler restarted, $n stuck job file(s) cleared" }
}
function Fix-net_private($a) {
  $old = @(Get-NetConnectionProfile | ForEach-Object { @{ i = $_.InterfaceIndex; c = [string]$_.NetworkCategory } })
  Get-NetConnectionProfile | Where-Object NetworkCategory -eq 'Public' | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
  Enable-NetFirewallRule -DisplayGroup 'Network Discovery' -ErrorAction SilentlyContinue
  Enable-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -ErrorAction SilentlyContinue
  foreach ($s in 'FDResPub','fdPHost','SSDPSRV','upnphost') { Set-Service $s -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service $s -ErrorAction SilentlyContinue }
  @{ ok = $true; txt = 'Network set to Private; discovery + File and Printer Sharing on'; undo = @{ fix = 'net_profile'; old = $old } }
}
function Fix-rpc_print($a) {
  # 0x11b / 0x709 / 0xbcb (Windows 11 22H2+ / 24H2 printing to a shared printer): both PCs - the sharing PC and the clients
  $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\Print'; $p = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC'; $pp = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
  $old = @{ a = (Get-ItemProperty $k -ErrorAction SilentlyContinue).RpcAuthnLevelPrivacyEnabled; b = (Get-ItemProperty $p -ErrorAction SilentlyContinue).RpcUseNamedPipeProtocol; c = (Get-ItemProperty $p -ErrorAction SilentlyContinue).RpcProtocols }
  New-Item $p -Force | Out-Null; New-Item $pp -Force | Out-Null
  Set-ItemProperty $k RpcAuthnLevelPrivacyEnabled 0 -Type DWord
  Set-ItemProperty $p RpcUseNamedPipeProtocol 1 -Type DWord; Set-ItemProperty $p RpcProtocols 7 -Type DWord
  Set-ItemProperty $pp RestrictDriverInstallationToAdministrators 0 -Type DWord -ErrorAction SilentlyContinue
  Restart-Service Spooler -Force -ErrorAction SilentlyContinue
  @{ ok = $true; txt = 'Printer RPC settings set (0x11b / 0x709 / 0xbcb fix), spooler restarted'; undo = @{ fix = 'rpc_print'; old = $old } }
}
function Fix-printer_driver($a) {
  # direct driver install: an INF from the Windows driver store / a URL in lab/cfg (args: name, inf or url)
  $n = [string]$a.driver; if (!$n) { return @{ ok = $false; txt = 'Which driver? (args.driver)' } }
  if ($a.url) { $z = Join-Path $PD.Root ('dl\drv_' + [IO.Path]::GetFileName($a.url)); Invoke-WebRequest -UseBasicParsing $a.url -OutFile $z -TimeoutSec 600
    if ($a.sha256 -and (PD-Sha256File $z) -ne $a.sha256) { return @{ ok = $false; txt = 'Driver file refused (SHA-256 does not match)' } }
    $d = $z -replace '\.zip$',''; if ($z -match '\.zip$') { Expand-Archive $z $d -Force }; Get-ChildItem $d -Recurse -Filter *.inf | ForEach-Object { pnputil /add-driver $_.FullName /install | Out-Null } }
  Add-PrinterDriver -Name $n -ErrorAction Stop
  @{ ok = $true; txt = "Printer driver '$n' installed" }
}
function Fix-printer_ip($a) {
  $ip = [string]$a.ip; $n = if ($a.name) { [string]$a.name } else { "Printer $ip" }; $drv = [string]$a.driver
  if (!$ip -or !$drv) { return @{ ok = $false; txt = 'Needs args.ip + args.driver' } }
  $port = "IP_$ip"; if (!(Get-PrinterPort $port -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name $port -PrinterHostAddress $ip }
  if (!(Get-PrinterDriver $drv -ErrorAction SilentlyContinue)) { Add-PrinterDriver -Name $drv -ErrorAction Stop }
  if (!(Get-Printer $n -ErrorAction SilentlyContinue)) { Add-Printer -Name $n -DriverName $drv -PortName $port }
  @{ ok = $true; txt = "Printer '$n' added at $ip"; undo = @{ fix = 'printer_remove'; name = $n } }
}
function Fix-smb_share($a) {
  # 24H2: signing required + guest blocked -> a saved login for the sharing PC (args: host, user, pass) and guest access only when asked
  $old = @{ guest = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' -ErrorAction SilentlyContinue).AllowInsecureGuestAuth }
  if ($a.host -and $a.user) { cmdkey /add:$($a.host) /user:$($a.user) /pass:$($a.pass) | Out-Null }
  if ($a.guest) { Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -RequireSecuritySignature $false -Force -ErrorAction SilentlyContinue }
  Fix-net_private $a | Out-Null
  @{ ok = $true; txt = 'Sharing set up' + $(if ($a.host) { ' + saved login for ' + $a.host } else { '' }) + $(if ($a.guest) { ' + guest access' } else { '' }); undo = @{ fix = 'smb_share'; old = $old } }
}
function Fix-startup_off($a) {
  $n = [string]$a.name; if (!$n) { return @{ ok = $false; txt = 'Which startup item? (args.name)' } }
  $done = $false
  foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
    $v = (Get-ItemProperty $k -ErrorAction SilentlyContinue).$n
    if ($v) { New-Item "$k-DavanOff" -Force | Out-Null; Set-ItemProperty "$k-DavanOff" $n $v; Remove-ItemProperty $k $n; $done = $true } }
  @{ ok = $done; txt = $(if ($done) { "Startup item '$n' turned off (kept a copy for ↩ Undo)" } else { "'$n' not found in the machine Run keys" }); undo = @{ fix = 'startup_on'; name = $n } }
}
# ---------- heavy (background, low priority, pause when busy) ----------
function Fix-repair_windows($a) {
  $d = PD-RunLow "$env:SystemRoot\System32\Dism.exe" '/Online /Cleanup-Image /RestoreHealth /NoRestart' 180
  $s = PD-RunLow "$env:SystemRoot\System32\sfc.exe" '/scannow' 120
  $o = [string]$s.out
  $txt = if ($o -match 'did not find any integrity') { 'Windows files OK' } elseif ($o -match 'successfully repaired') { 'Damaged Windows files repaired' } elseif ($o -match 'unable to fix') { 'Some files could not be repaired - a Windows reinstall may be needed' } else { 'sfc finished (code ' + $s.code + ')' }
  @{ ok = $s.code -eq 0; txt = "DISM code $($d.code); $txt" }
}
function PD-AndroidPlan {
  # 7: what Android clean would delete + "will free ≈ X GB" (never AndroidStudioProjects source; build folders only)
  $c = PD-Cfg; $items = @()
  foreach ($p in @($c.android.paths)) { $x = [Environment]::ExpandEnvironmentVariables($p)
    foreach ($u in PD-UserDirs) { $y = $x -replace [regex]::Escape($env:USERPROFILE), $u.FullName -replace [regex]::Escape($env:LOCALAPPDATA), "$($u.FullName)\AppData\Local" -replace [regex]::Escape($env:TEMP), "$($u.FullName)\AppData\Local\Temp"
      foreach ($i in @(Get-Item $y -Force -ErrorAction SilentlyContinue)) { $items += $i.FullName } } }
  foreach ($u in PD-UserDirs) {
    # old Android Studio version folders (keep the newest), project build folders, unused SDK system images (no AVD uses them), AVD data (keep keepAvd)
    $as = @(Get-ChildItem "$($u.FullName)\AppData\Local\Google","$($u.FullName)\AppData\Roaming\Google" -Directory -Filter 'AndroidStudio*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    if ($as.Count -gt 1) { $items += @($as | Select-Object -Skip 1 | ForEach-Object FullName) }
    $items += @(Get-ChildItem "$($u.FullName)\AndroidStudioProjects" -Recurse -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -in 'build','.gradle','.cxx','intermediates' -and $_.FullName -notmatch '\\src\\' } | ForEach-Object FullName)
    $avds = @(Get-ChildItem "$($u.FullName)\.android\avd\*.avd" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    $keep = if ($c.android.keepAvd) { [int]$c.android.keepAvd } else { 1 }
    foreach ($v in $avds | Select-Object -Skip $keep) { $items += $v.FullName; $ini = $v.FullName -replace '\.avd$','.ini'; if (Test-Path $ini) { $items += $ini } }
    foreach ($v in $avds | Select-Object -First $keep) { $items += @(Get-ChildItem $v.FullName -Filter '*.img' -ErrorAction SilentlyContinue | Where-Object Name -match '^userdata-qemu|^cache' | ForEach-Object FullName) }
    $used = @($avds | Select-Object -First $keep | ForEach-Object { (Get-Content (Join-Path $_.FullName 'config.ini') -ErrorAction SilentlyContinue | Where-Object { $_ -match '^image\.sysdir' }) -replace '.*=\s*','' -replace '/','\' })
    $sdk = "$($u.FullName)\AppData\Local\Android\Sdk\system-images"
    foreach ($img in @(Get-ChildItem $sdk -Directory -ErrorAction SilentlyContinue | ForEach-Object { Get-ChildItem $_.FullName -Directory | ForEach-Object { Get-ChildItem $_.FullName -Directory } })) {
      $rel = $img.FullName.Substring($sdk.Length - 'system-images'.Length); if (!($used | Where-Object { $_ -and $rel -like ($_.TrimEnd('\') + '*') -or $_ -like ($rel + '*') })) { $items += $img.FullName } }
  }
  $items = @($items | Where-Object { $_ -and $_ -notmatch '\\src\\main\\|\.java$|\.kt$|\.xml$' } | Select-Object -Unique)
  $gb = 0; foreach ($i in $items) { $g = PD-DirGB $i; if ($null -eq $g) { try { $g = (Get-Item $i -Force).Length / 1GB } catch { $g = 0 } }; $gb += $g }
  @{ items = $items; gb = [math]::Round($gb, 1) }
}
function Fix-android_clean($a) {
  if (Get-Process -Name 'studio64','studio','qemu-system-x86_64','emulator' -ErrorAction SilentlyContinue) { return @{ ok = $false; txt = 'Android Studio / emulator is open - Android clean waits until it is closed'; later = $true } }
  $before = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
  $plan = PD-AndroidPlan
  foreach ($i in $plan.items) { if (PD-Busy) { Start-Sleep 30 }; Remove-Item $i -Recurse -Force -ErrorAction SilentlyContinue }
  Fix-clean_temp $a | Out-Null
  $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  $gb = [math]::Round(($c.FreeSpace - $before) / 1GB, 1); $pct = [math]::Round(100 * $c.FreeSpace / $c.Size)
  @{ ok = $true; txt = "Freed $gb GB (planned ≈ $($plan.gb) GB). C: now $pct% free"; freePct = $pct }
}
function Fix-clean($a) { Fix-android_clean $a }
function Fix-winget($a) {
  $wg = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
  if (!$wg) { return @{ ok = $false; txt = 'winget is not on this PC' } }
  $c = PD-Cfg; $keep = @($c.keep)
  $list = & $wg.FullName upgrade --accept-source-agreements --include-unknown 2>$null | Out-String
  $ids = @(); foreach ($l in ($list -split "`n")) { if ($l -match '\s([A-Za-z0-9][\w\.\-]+\.[\w\.\-]+)\s+\S+\s+\S+\s+winget') { $ids += $Matches[1] } }
  $done = @(); $skip = @()
  foreach ($id in $ids) { if ($keep -contains $id) { $skip += $id; continue }
    if (PD-Busy) { Start-Sleep 60 }
    $r = PD-RunLow $wg.FullName "upgrade --id $id --silent --accept-package-agreements --accept-source-agreements --disable-interactivity" 30
    $done += ($id + $(if ($r.code -eq 0) { ' ✅' } else { ' ❌' })) }
  PD-Db PUT ('lab/inv/' + (PD-Hwid) + '/winget') @{ t = (PD-NowMs); done = $done; held = $skip } | Out-Null
  @{ ok = $true; txt = "Updated $($done.Count) program(s)" + $(if ($skip.Count) { "; on hold (keep-version list): " + ($skip -join ', ') } else { '' }) }
}
function Fix-win_update_dl($a) {
  $s = New-Object -ComObject Microsoft.Update.Session; $q = $s.CreateUpdateSearcher().Search("IsInstalled=0 and Type='Software' and IsHidden=0")
  $c = PD-Cfg; $col = New-Object -ComObject Microsoft.Update.UpdateColl
  foreach ($u in $q.Updates) { if ($c.featureUpgradeHold -ne $false -and ($u.Title -match 'Feature update|version 2\dH\d|Upgrade to Windows')) { continue }; [void]$col.Add($u) }
  if (!$col.Count) { return @{ ok = $true; txt = 'No updates waiting' } }
  $d = $s.CreateUpdateDownloader(); $d.Updates = $col; $d.Priority = 1; $r = $d.Download()
  @{ ok = ($r.ResultCode -eq 2); txt = "Downloaded $($col.Count) update(s) - they install at a restart (Thawed)"; titles = @($col | ForEach-Object Title) }
}
function Fix-crash_reader($a) {
  # Microsoft Debugging Tools (cdb) once; on a Frozen PC kept in ThawSpace
  $t = PD-ThawPath; $dest = if ($t) { "$t\cdb" } else { "$env:ProgramData\DavanPCDoctor\dl\cdb" }
  $x = Join-Path $PD.Root 'dl\winsdksetup.exe'
  Invoke-WebRequest -UseBasicParsing 'https://go.microsoft.com/fwlink/?linkid=2272610' -OutFile $x -TimeoutSec 600
  $r = PD-RunLow $x '/features OptionId.WindowsDesktopDebuggers /quiet /norestart' 30
  $src = "${env:ProgramFiles(x86)}\Windows Kits\10\Debuggers\x64"; if (Test-Path $src) { New-Item -ItemType Directory -Force $dest | Out-Null; Copy-Item "$src\*" $dest -Recurse -Force }
  @{ ok = (Test-Path "$dest\cdb.exe"); txt = 'Crash reader ' + $(if (Test-Path "$dest\cdb.exe") { 'ready' } else { 'not installed (code ' + $r.code + ')' }) }
}
# ---------- restart-needing (at shutdown / free period with nobody logged in / ✅ now) ----------
function PD-InUse { [bool](PD-LoggedOnUser) }
function Fix-check_disk($a) { $o = cmd /c 'echo Y | chkdsk C: /scan /perf' 2>&1 | Out-String; cmd /c 'echo Y | chkdsk C: /f' | Out-Null; fsutil dirty set C: | Out-Null
  @{ ok = $true; txt = 'Online scan: ' + $(if ($o -match 'found no problems') { 'no problems' } else { 'problems found' }) + '. Full check disk runs at the next restart.'; restart = $true } }
function Fix-ram_test($a) { bcdedit /bootsequence '{memdiag}' | Out-Null; @{ ok = ($LASTEXITCODE -eq 0); txt = 'Windows Memory Diagnostic runs at the next restart; the result comes back as an event.'; restart = $true } }
function Fix-update_install($a) {
  $s = New-Object -ComObject Microsoft.Update.Session; $q = $s.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0'); $col = New-Object -ComObject Microsoft.Update.UpdateColl
  $c = PD-Cfg; foreach ($u in $q.Updates) { if ($c.featureUpgradeHold -ne $false -and ($u.Title -match 'Feature update|version 2\dH\d|Upgrade to Windows')) { continue }; if ($u.IsDownloaded) { [void]$col.Add($u) } }
  if (!$col.Count) { return @{ ok = $true; txt = 'Nothing downloaded to install' } }
  $i = $s.CreateUpdateInstaller(); $i.Updates = $col; $r = $i.Install()
  @{ ok = ($r.ResultCode -eq 2); txt = "Installed $($col.Count) update(s)" + $(if ($r.RebootRequired) { ' - restart needed' } else { '' }); restart = $r.RebootRequired }
}
function Fix-rename($a) { $n = ([string]$a.name).ToUpper(); if ($n -notmatch '^[A-Z0-9-]{1,15}$') { return @{ ok = $false; txt = 'Bad name' } }
  Rename-Computer -NewName $n -Force -ErrorAction Stop; @{ ok = $true; txt = "Windows name -> $n at the next restart"; restart = $true; undo = @{ fix = 'rename'; old = $env:COMPUTERNAME } } }
function Fix-restart($a) {
  if ((PD-InUse) -and !$a.force) { return @{ ok = $false; txt = 'Someone is using this PC - not restarted (it restarts at shutdown / a free period).'; later = $true } }
  shutdown /r /t 60 /c 'Davan PC Doctor: restart in 1 minute' | Out-Null; @{ ok = $true; txt = 'Restarting in 1 minute' }
}
function Fix-rollback_driver($a) {
  # args.inf = oem<N>.inf of the bad driver (from the BSOD / inventory) -> remove it; Windows falls back to the previous / inbox driver
  $inf = [string]$a.inf; if ($inf -notmatch '^oem\d+\.inf$') { return @{ ok = $false; txt = 'Needs args.inf (oemNN.inf)' } }
  $o = pnputil /delete-driver $inf /uninstall /force 2>&1 | Out-String
  @{ ok = ($o -match 'deleted'); txt = "Driver $inf removed - previous driver used after restart"; restart = $true }
}
function Fix-uninstall_update($a) {
  $kb = ([string]$a.kb) -replace '[^0-9]',''; if (!$kb) { return @{ ok = $false; txt = 'Needs args.kb' } }
  $r = PD-RunLow "$env:SystemRoot\System32\wusa.exe" "/uninstall /kb:$kb /quiet /norestart" 30
  # block it: hide the update so Windows does not offer it again
  try { $s = New-Object -ComObject Microsoft.Update.Session; foreach ($u in $s.CreateUpdateSearcher().Search('IsInstalled=0').Updates) { if ($u.KBArticleIDs -contains $kb) { $u.IsHidden = $true } } } catch {}
  @{ ok = ($r.code -in 0, 3010); txt = "KB$kb uninstalled + hidden (code $($r.code))"; restart = $true }
}
# ---------- ↩ Undo for settings ----------
function PD-Undo($u) {
  switch ($u.fix) {
    'net_profile' { foreach ($x in $u.old) { Set-NetConnectionProfile -InterfaceIndex $x.i -NetworkCategory $x.c -ErrorAction SilentlyContinue }; 'network profile put back' }
    'rpc_print'   { $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\Print'; $p = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC'
                    if ($null -eq $u.old.a) { Remove-ItemProperty $k RpcAuthnLevelPrivacyEnabled -ErrorAction SilentlyContinue } else { Set-ItemProperty $k RpcAuthnLevelPrivacyEnabled $u.old.a }
                    if ($null -eq $u.old.b) { Remove-ItemProperty $p RpcUseNamedPipeProtocol -ErrorAction SilentlyContinue } else { Set-ItemProperty $p RpcUseNamedPipeProtocol $u.old.b }
                    if ($null -eq $u.old.c) { Remove-ItemProperty $p RpcProtocols -ErrorAction SilentlyContinue } else { Set-ItemProperty $p RpcProtocols $u.old.c }
                    Restart-Service Spooler -Force; 'printer RPC settings put back' }
    'printer_remove' { Remove-Printer -Name $u.name -ErrorAction SilentlyContinue; "printer $($u.name) removed" }
    'smb_share'   { Set-SmbClientConfiguration -EnableInsecureGuestLogons ([bool]$u.old.guest) -Force -ErrorAction SilentlyContinue; 'sharing settings put back' }
    'startup_on'  { foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') { $v = (Get-ItemProperty "$k-DavanOff" -ErrorAction SilentlyContinue).($u.name); if ($v) { Set-ItemProperty $k $u.name $v; Remove-ItemProperty "$k-DavanOff" $u.name } }; "startup item $($u.name) back on" }
    'rename'      { Rename-Computer -NewName $u.old -Force; "name back to $($u.old) at restart" }
    default       { 'nothing to undo' }
  }
}
