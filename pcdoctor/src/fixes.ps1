# Davan PC Doctor - fixes.ps1 (ROADMAP-pcdoctor.md 7). Every fix returns @{ ok; txt; undo } and is logged to lab/fixlog/<date>/<hwid>.
# Light fixes run at once (also during lab); heavy ones run at low priority and pause when the PC is busy; restart-needing ones wait for
# shutdown / a free period with nobody logged in / ✅ now; on a Frozen PC a permanent fix goes to the "needs Thawed" queue.
# Never deletes student source code. Never restarts a PC in use.

$PD_FIX = [ordered]@{
  # name            kind      label (Console button / log)               switch in lab/cfg/fix/sw
  'clean_temp'    = @{ k = 'light';   l = 'Clean temp + crash dumps';       sw = 'clean_temp'; del = $true }
  'stop_program'  = @{ k = 'light';   l = 'Stop a program';                 sw = 'stop_hung' }
  'spooler'       = @{ k = 'light';   l = 'Restart print spooler + clear stuck jobs'; sw = 'spooler'; del = $true }
  'net_private'   = @{ k = 'light';   l = 'Network Private + discovery + File & Printer Sharing'; sw = 'net_private'; perm = $true }
  'rpc_print'     = @{ k = 'light';   l = 'Printer RPC settings (0x11b / 0x709 / 0xbcb)'; sw = 'rpc_print'; perm = $true }
  'printer_driver'= @{ k = 'light';   l = 'Install printer driver';         sw = 'printer_driver'; perm = $true }
  'printer_ip'    = @{ k = 'light';   l = 'Add printer by IP';              sw = 'printer_driver'; perm = $true }
  'smb_share'     = @{ k = 'light';   l = 'Shared folder / printer (SMB 24H2) + saved login'; sw = 'smb_share'; perm = $true }
  'startup_off'   = @{ k = 'light';   l = 'Turn off a startup item';        sw = 'startup_off'; perm = $true; del = $true }
  'repair_windows'= @{ k = 'heavy';   l = 'Repair Windows (sfc / DISM)';    sw = 'sfc_dism'; perm = $true }
  'android_clean' = @{ k = 'heavy';   l = 'Android clean';                  sw = 'android_clean'; del = $true }
  'clean'         = @{ k = 'heavy';   l = 'Clean now';                      sw = 'android_clean'; del = $true }
  'winget'        = @{ k = 'heavy';   l = 'Software updates (winget)';      sw = 'winget'; perm = $true }
  'win_update_dl' = @{ k = 'heavy';   l = 'Download Windows updates';       sw = 'win_update_dl' }
  'check_disk'    = @{ k = 'restart'; l = 'Check disk (chkdsk at restart)'; sw = 'chkdsk'; perm = $true }
  'ram_test'      = @{ k = 'restart'; l = 'RAM test (at restart)';          sw = 'ram_test'; perm = $true }
  'update_install'= @{ k = 'restart'; l = 'Install Windows updates';        sw = 'update_install'; perm = $true }
  'rename'        = @{ k = 'restart'; l = 'Rename this PC';                 sw = 'rename'; perm = $true }
  'restart'       = @{ k = 'restart'; l = 'Restart';                        sw = $null }
  'rollback_driver'=@{ k = 'restart'; l = 'Roll back driver';               sw = $null; perm = $true; del = $true }
  'uninstall_update'=@{ k = 'restart'; l = 'Uninstall update + block it';   sw = $null; perm = $true; del = $true }
  'crash_reader'  = @{ k = 'heavy';   l = 'Install the crash reader (cdb)'; sw = $null }
  # 1.71 (user, 07-Nov-2026 - 🩺 Fixes): NUTANANEW's ADMIN has no password and Windows refuses a no-password login from another PC -> printers
  # gave 0x709 / 0x40. user = runs in the logged-in user's own Windows session (a saved login belongs to that user): only the tray's ▶ Fix now runs it.
  'blank_pw_net'  = @{ k = 'light';   l = 'Let other PCs log in without a password (printer / folder sharing)'; sw = $null; perm = $true }
  'save_login'    = @{ k = 'user';    l = 'Save the login for a sharing PC (this user)'; sw = $null; user = $true }
  # 1.74 (user, 07-Nov-2026: "truly no password"): Windows 11 refuses a GUEST printer install (0x40 / 0x709 - the printer service needs a real login since 2021).
  # So the sharing PC offers its printer DRIVERS in a read-only share, and each other PC adds the printer as a direct port to \\PC\printer (no printer service, no password).
  'driver_share'  = @{ k = 'light';   l = 'Share this PC''s printer drivers with the other PCs (no-password printing)'; sw = $null; perm = $true }
  'printer_guest' = @{ k = 'light';   l = 'Add the shared printers of another PC without a password'; sw = $null; perm = $true }
  # 1.78 (user, 07-Nov-2026, option 1): one normal Windows user "print" on the printer PC; every other PC saves that login once (PC Doctor fills the password in)
  'print_user'    = @{ k = 'light';   l = 'Printer login "print" for the other PCs (shared printers + folder)'; sw = $null; perm = $true }
  # 1.80 (user, 08-Nov-2026: Gujjar laptop, "BT DONGLE10 - Driver error"): Bluetooth fixes. bt_check = read-only; bt_restart removes nothing;
  # bt_reinstall removes the device so Windows installs the driver again -> del = $true: only after the Super Admin taps it.
  'bt_check'      = @{ k = 'light';   l = 'Check Bluetooth (devices + driver error code)'; sw = $null }
  'bt_restart'    = @{ k = 'light';   l = 'Restart Bluetooth (service + dongle off / on)'; sw = $null }
  'bt_reinstall'  = @{ k = 'restart'; l = 'Reinstall the Bluetooth driver (remove device + rescan)'; sw = $null; perm = $true; del = $true }
}
function PD-FixLog([string]$fix, $res, [string]$by, [string]$cid = '') {
  $t = PD-NowMs
  PD-Db PUT ('lab/fixlog/' + (PD-ISTDate $t) + '/' + (PD-Hwid) + '/f' + $t) @{ t = $t; fix = $fix; label = $PD_FIX[$fix].l; ok = [bool]$res.ok; txt = [string]$res.txt; by = $by; cid = $cid; undo = $res.undo } | Out-Null
  $hist = PD-ReadJson (Join-Path $PD.Root 'state\fixhist.json'); if (!$hist) { $hist = @{} } else { $h2 = @{}; $hist.PSObject.Properties | ForEach-Object { $h2[$_.Name] = $_.Value }; $hist = $h2 }
  $hist[$fix] = $t; PD-WriteJson (Join-Path $PD.Root 'state\fixhist.json') $hist
  # 1.71 🩺 Fixes: every fix that ran (auto-fix, Console, Claude, tray) also goes into this PC's fix book with its result, check and ↩ Undo.
  # A fix started FROM the book updates its own entry instead (A-BookRun) - no second line.
  if (!$script:PDBookCur -and !$res.queued) { try { PD-BookNew 'fix' @{ fix = $fix; args = $script:PDFixArgs; title = $PD_FIX[$fix].l; by = $by; st = $(if ($res.ok) { 'done' } else { 'failed' }); need = 'auto'
      res = @{ ok = [bool]$res.ok; txt = [string]$res.txt; t = $t }; chk = (PD-Verify $fix $script:PDFixArgs); undo = $res.undo } | Out-Null } catch { PD-Log ('book: ' + $_.Exception.Message) } }
}
function PD-FixAllowed([string]$fix, [switch]$Auto) {
  $c = PD-Cfg; $f = $c.fix
  if ($Auto) {
    # STRICT RULE (user, 04-Nov-2026): "never delete anything from a PC - especially my laptop - tell me what you want to delete and delete only
    # if I say yes". A fix that deletes or removes anything (del = $true) never runs by itself: it is offered on the Console and runs only
    # after the Super Admin taps it. The Super Admin laptop never runs any fix by itself.
    if ($PD_FIX[$fix].del) { return 'deletes files - waits for the Super Admin''s OK' }
    if (Test-Path (Join-Path $PD.Root 'state\laptop.flag')) { return 'Super Admin laptop - no automatic fixes' }
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
  $meta = $PD_FIX[$fix]; $script:PDFixArgs = $a   # 1.71: the fix book keeps the arguments too
  if ($meta.del -and $by -eq 'auto') { return @{ ok = $false; txt = 'not run: it deletes files - only after the Super Admin''s OK' } }   # strict rule, 2nd lock
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
# 1.71 (user, 07-Nov-2026): Windows never lets another PC log in to an account without a password (LimitBlankPasswordUse = 1). NUTANANEW's
# ADMIN has none and the user wants to keep it that way - this lets the other PCs in (they then use it for printers / folders). ↩ Undo puts it back.
function Fix-blank_pw_net($a) {
  $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'; $old = (Get-ItemProperty $k -ErrorAction SilentlyContinue).LimitBlankPasswordUse
  Set-ItemProperty $k LimitBlankPasswordUse 0 -Type DWord
  @{ ok = $true; txt = 'Other PCs can now log in to accounts without a password (printer / folder sharing). ↩ Undo puts the protection back.'; undo = @{ fix = 'blank_pw_net'; old = $old } }
}
function Fix-save_login($a) { @{ ok = $false; txt = 'A saved login belongs to the person logged in - press ▶ Fix now in the PC Doctor tray (🩺 Fixes) on this PC.' } }
# ---------- 1.74 no-password printing (user, 07-Nov-2026) ----------
$PD_DRVSHARE = 'PCDoctor-Drivers'
# a "Local Port" named \\PC\printer: Add-PrinterPort first; some Windows builds refuse a UNC name there, then the classic way (Ports key + spooler restart)
function PD-AddLocalPort([string]$port) {
  if (Get-PrinterPort -Name $port -ErrorAction SilentlyContinue) { return 'exists' }
  try { Add-PrinterPort -Name $port -ErrorAction Stop; return 'added' } catch { $e1 = $_.Exception.Message }
  New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ports' -Name $port -Value '' -PropertyType String -Force | Out-Null
  Restart-Service Spooler -Force -ErrorAction SilentlyContinue; Start-Sleep 3
  if (Get-PrinterPort -Name $port -ErrorAction SilentlyContinue) { return 'added (Ports key)' }
  throw ('could not add the port ' + $port + ': ' + $e1)
}
function PD-FindPrinterInf([string]$name) {
  foreach ($f in @(Get-ChildItem "$env:windir\INF\oem*.inf" -ErrorAction SilentlyContinue)) { if (Select-String -Path $f.FullName -SimpleMatch -Pattern ('"' + $name + '"') -Quiet -ErrorAction SilentlyContinue) { return $f.Name } }
  ''
}
# ---------- 1.78 option 1: the office printer login (password = Console Settings, encrypted; worker /lab/pcsecret) ----------
function PD-GetPrintPw {
  if ($PD.Test) { return $null }
  try { $r = Invoke-RestMethod -Method Post -Uri ($PD.Worker + '/lab/pcsecret') -Body (PD-Json @{ idToken = (PD-Token) }) -ContentType 'text/plain' -TimeoutSec 30
    if ($r.ok -and $r.has) { return @{ pw = [string]$r.text; at = [int64]$r.at } } } catch { PD-Log ('printer login password not read: ' + $_.Exception.Message) }
  $null
}
function Fix-print_user($a) {
  $nm = if ($a -and $a.user) { [string]$a.user } else { 'print' }
  $sp = if ($a -and $a.pwTest) { @{ pw = [string]$a.pwTest; at = 1 } } else { PD-GetPrintPw }
  if (!$sp -or !$sp.pw) { return @{ ok = $false; txt = 'Set the printer login password first: PC Doctor Console -> Settings -> Printer login. Then press ▶ again.' } }
  $sec = ConvertTo-SecureString $sp.pw -AsPlainText -Force
  $u0 = Get-LocalUser -Name $nm -ErrorAction SilentlyContinue; $new = !$u0
  if ($new) { New-LocalUser -Name $nm -Password $sec -FullName 'Printer login (PC Doctor)' -Description 'PC Doctor: shared printers + folder login' -PasswordNeverExpires -UserMayNotChangePassword -AccountNeverExpires -ErrorAction Stop | Out-Null
    $grp = (Get-LocalGroup -SID 'S-1-5-32-545').Name; Add-LocalGroupMember -Group $grp -Member $nm -ErrorAction SilentlyContinue }
  else { Set-LocalUser -Name $nm -Password $sec -PasswordNeverExpires $true -ErrorAction Stop; Enable-LocalUser -Name $nm -ErrorAction SilentlyContinue }
  $ul = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList'; New-Item $ul -Force | Out-Null; New-ItemProperty $ul -Name $nm -Value 0 -PropertyType DWord -Force | Out-Null
  if (!($a -and $a.pwTest)) { PD-WriteJson (Join-Path $PD.Root 'state\printuser.json') @{ user = $nm; at = $sp.at } }
  @{ ok = $true; txt = "Printer login $env:COMPUTERNAME\$nm " + $(if ($new) { 'made' } else { 'updated' }) + ' (normal user, hidden from the login screen, password from the Console). The other PCs: "Save the login" once.'; undo = @{ fix = 'print_user'; user = $nm; new = $new } }
}
# on the SHARING PC: every shared printer's driver package -> ProgramData\DavanPCDoctor\drivers-share\<printer> + manifest.json, shared read-only as PCDoctor-Drivers
function Fix-driver_share($a) {
  $dir = Join-Path $env:ProgramData 'DavanPCDoctor\drivers-share'; New-Item -ItemType Directory -Force $dir | Out-Null
  $man = @(); $got = @(); $miss = @()
  foreach ($p in @(Get-Printer -ErrorAction SilentlyContinue | Where-Object Shared)) {
    $dv = Get-PrinterDriver -Name $p.DriverName -ErrorAction SilentlyContinue; $fd = ([string]$p.ShareName -replace '[^A-Za-z0-9]', '_'); $dst = Join-Path $dir $fd
    New-Item -ItemType Directory -Force $dst | Out-Null
    if (!@(Get-ChildItem $dst -Recurse -Filter *.inf -ErrorAction SilentlyContinue).Count) {
      $inf = [string]$dv.InfPath
      if ($inf -and (Test-Path $inf)) { Copy-Item -Path (Join-Path (Split-Path $inf) '*') -Destination $dst -Recurse -Force -ErrorAction SilentlyContinue }
      else { $o = PD-FindPrinterInf ([string]$p.DriverName); if ($o) { pnputil /export-driver $o $dst 2>&1 | Out-Null } } }
    $n = @(Get-ChildItem $dst -Recurse -Filter *.inf -ErrorAction SilentlyContinue).Count
    $man += @{ share = [string]$p.ShareName; printer = [string]$p.Name; driver = [string]$p.DriverName; folder = $fd; ok = ($n -gt 0) }
    if ($n) { $got += [string]$p.ShareName } else { $miss += [string]$p.ShareName } }
  PD-WriteJson (Join-Path $dir 'manifest.json') @{ t = (PD-NowMs); host = $env:COMPUTERNAME; printers = $man }
  $new = !(Get-SmbShare -Name $PD_DRVSHARE -ErrorAction SilentlyContinue)
  if ($new) { New-SmbShare -Name $PD_DRVSHARE -Path $dir -ReadAccess 'Everyone' -Description 'Davan PC Doctor - printer drivers for no-password printing (read-only)' -ErrorAction Stop | Out-Null }
  icacls $dir /grant '*S-1-1-0:(OI)(CI)RX' '*S-1-5-32-546:(OI)(CI)RX' /T /Q 2>&1 | Out-Null
  @{ ok = ($got.Count -gt 0); txt = 'Drivers ready for the other PCs: ' + $(if ($got.Count) { $got -join ', ' } else { 'none' }) + $(if ($miss.Count) { ' | no driver package found: ' + ($miss -join ', ') } else { '' }) + ' (share \\' + $env:COMPUTERNAME + '\' + $PD_DRVSHARE + ', read-only)'; undo = $(if ($new) { @{ fix = 'driver_share' } } else { $null }) }
}
# on the OTHER PCs: driver from \\host\PCDoctor-Drivers, then a printer whose port is \\host\<printer share> (args: host, shares = only these, else all)
function Fix-printer_guest($a) {
  $hst = ([string]$a.host).Trim().ToUpper(); if (!$hst) { return @{ ok = $false; txt = 'Which PC shares the printers? (args.host)' } }
  $src = "\\$hst\$PD_DRVSHARE"
  $m0 = $null; $er0 = ''
  try { $m0 = Get-Content "$src\manifest.json" -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json } catch { $er0 = $_.Exception.Message }
  if (!$m0) { return @{ ok = $false; txt = "Cannot open $src - run 'Share this PC's printer drivers' on $hst first, and allow guest connections here ($er0)" } }
  $want = @($a.shares | Where-Object { $_ }); $added = @(); $ports = @(); $out = @()
  foreach ($m in @($m0.printers)) {
    if ($want.Count -and [string]$m.share -notin $want) { continue }
    $pn = [string]$m.share + ' (' + $hst + ')'; $port = '\\' + $hst + '\' + [string]$m.share
    try {
      if ($a.forceDriver -or !(Get-PrinterDriver -Name ([string]$m.driver) -ErrorAction SilentlyContinue)) {
        if (!$m.ok) { $out += "$($m.share): $hst has no driver package for it"; continue }
        $loc = Join-Path $PD.Root ('drv\' + $hst + '_' + [string]$m.folder); New-Item -ItemType Directory -Force $loc | Out-Null
        Copy-Item -Path ("$src\" + [string]$m.folder + '\*') -Destination $loc -Recurse -Force -ErrorAction Stop
        foreach ($i in @(Get-ChildItem $loc -Recurse -Filter *.inf)) { pnputil /add-driver $i.FullName /install 2>&1 | Out-Null }
        Add-PrinterDriver -Name ([string]$m.driver) -ErrorAction Stop }
      $null = PD-AddLocalPort $port
      if (!(Get-Printer -Name $pn -ErrorAction SilentlyContinue)) { Add-Printer -Name $pn -DriverName ([string]$m.driver) -PortName $port -ErrorAction Stop; $added += $pn; $ports += $port }
      $out += "$pn ready"
    } catch { $out += "$($m.share): " + $_.Exception.Message }
  }
  $ok = @($out | Where-Object { $_ -match ' ready$' }).Count -gt 0
  @{ ok = $ok; txt = ($out -join ' | ') + $(if ($ok) { ' - print to it like any printer (no password)' } else { '' }); undo = $(if ($added.Count) { @{ fix = 'printer_guest'; names = $added; ports = $ports } } else { $null }) }
}
# ---------- 🩺 Fixes: did the fix really change what it should? (read-only, right after the fix) - $null = cannot be checked by itself ----------
# ---------- 1.80 Bluetooth ----------
function PD-BtDevices { @(Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -notmatch 'Enumerator|RFCOMM|Device \(|Service|Protocol|LE Generic' -or $_.Status -ne 'OK' }) }
function Fix-bt_check($a) {
  $d = PD-BtDevices; $sv = Get-Service bthserv -ErrorAction SilentlyContinue
  if (!$d.Count) { return @{ ok = $false; txt = 'No Bluetooth device found - dongle not plugged in or not seen by Windows (try another USB port)' } }
  $l = foreach ($x in $d) { $c = (Get-PnpDeviceProperty -InstanceId $x.InstanceId -KeyName 'DEVPKEY_Device_ProblemCode' -ErrorAction SilentlyContinue).Data
    $dv = (Get-PnpDeviceProperty -InstanceId $x.InstanceId -KeyName 'DEVPKEY_Device_DriverProvider' -ErrorAction SilentlyContinue).Data
    "$($x.FriendlyName): $($x.Status), problem code $c, driver by $dv" }
  @{ ok = (@($d | Where-Object { $_.Status -ne 'OK' }).Count -eq 0); txt = (($l -join "`n") + "`nBluetooth Support Service: " + $(if ($sv) { [string]$sv.Status } else { 'missing' })) }
}
function Fix-bt_restart($a) {
  Set-Service bthserv -StartupType Manual -ErrorAction SilentlyContinue; Restart-Service bthserv -Force -ErrorAction SilentlyContinue
  $n = 0; foreach ($x in @(Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'OK' -and $_.InstanceId -match '^USB' })) {
    try { Disable-PnpDevice -InstanceId $x.InstanceId -Confirm:$false -ErrorAction Stop; Start-Sleep 2; Enable-PnpDevice -InstanceId $x.InstanceId -Confirm:$false -ErrorAction Stop; $n++ } catch {} }
  Start-Sleep 3; $bad = @(PD-BtDevices | Where-Object { $_.Status -ne 'OK' }).Count
  @{ ok = ($bad -eq 0); txt = "Bluetooth service restarted, $n dongle(s) switched off / on, $bad device(s) still in error"; undo = 'Nothing to undo (only a restart)' }
}
function Fix-bt_reinstall($a) {
  $n = 0; $o = ''; foreach ($x in @(Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'OK' -and $_.InstanceId -match '^USB' })) {
    $o += pnputil /remove-device $x.InstanceId 2>&1 | Out-String; $n++ }
  pnputil /scan-devices 2>&1 | Out-Null; Start-Sleep 5; $bad = @(PD-BtDevices | Where-Object { $_.Status -ne 'OK' }).Count
  @{ ok = ($n -gt 0 -and $bad -eq 0); txt = "$n Bluetooth dongle device(s) removed + rescanned, $bad still in error. If it stays in error the chipset driver is wrong - send the check (hardware id) to Claude"; restart = $true; undo = 'Windows installs the driver again by itself on the rescan' }
}

function PD-Verify([string]$fix, $a) {
  try {
    switch ($fix) {
      'spooler'      { $sp = [string](Get-Service Spooler).Status; $n = @(Get-ChildItem "$env:SystemRoot\System32\spool\PRINTERS\*" -ErrorAction SilentlyContinue).Count
                       return @{ ok = ($sp -eq 'Running'); txt = "Print spooler $sp, $n job file(s) waiting"; t = (PD-NowMs) } }
      { $_ -in 'net_private', 'smb_share' } { $pr = @(Get-NetConnectionProfile -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.NetworkCategory }); $fw = @(Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -Direction Inbound -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq 'True' -and $_.Profile -match 'Private|Any' }).Count
                       return @{ ok = (($pr -notcontains 'Public') -and $fw -gt 0); txt = 'Network ' + ($pr -join ', ') + ', ' + $fw + ' sharing rules on'; t = (PD-NowMs) } }
      'rpc_print'    { $x = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' -ErrorAction SilentlyContinue).RpcAuthnLevelPrivacyEnabled; $y = (Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC' -ErrorAction SilentlyContinue).RpcUseNamedPipeProtocol
                       return @{ ok = ($x -eq 0 -and $y -eq 1); txt = "RpcAuthnLevelPrivacyEnabled=$x, RpcUseNamedPipeProtocol=$y"; t = (PD-NowMs) } }
      'blank_pw_net' { $x = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -ErrorAction SilentlyContinue).LimitBlankPasswordUse
                       return @{ ok = ($x -eq 0); txt = "LimitBlankPasswordUse=$x (0 = other PCs may log in without a password)"; t = (PD-NowMs) } }
      'printer_ip'   { $n = if ($a -and $a.name) { [string]$a.name } elseif ($a -and $a.ip) { 'Printer ' + $a.ip } else { '' }; if (!$n) { return $null }
                       $p = Get-Printer $n -ErrorAction SilentlyContinue; return @{ ok = [bool]$p; txt = $(if ($p) { "Printer '$n' is there ($($p.PrinterStatus))" } else { "Printer '$n' not found" }); t = (PD-NowMs) } }
      'print_user'   { $nm = if ($a -and $a.user) { [string]$a.user } else { 'print' }; $u0 = Get-LocalUser -Name $nm -ErrorAction SilentlyContinue
                       return @{ ok = [bool]($u0 -and $u0.Enabled); txt = $(if ($u0) { "User $nm is there (enabled: $($u0.Enabled), password never expires: $(!$u0.PasswordExpires))" } else { "No user $nm" }); t = (PD-NowMs) } }
      'driver_share' { $sh = Get-SmbShare -Name $PD_DRVSHARE -ErrorAction SilentlyContinue; $mf = PD-ReadJson (Join-Path $env:ProgramData 'DavanPCDoctor\drivers-share\manifest.json')
                       $n = @($mf.printers | Where-Object ok).Count; return @{ ok = ([bool]$sh -and $n -gt 0); txt = $(if ($sh) { "Share $PD_DRVSHARE is on, drivers for $n printer(s)" } else { 'Share not found' }); t = (PD-NowMs) } }
      'printer_guest' { if (!$a -or !$a.host) { return $null }; $hs = ([string]$a.host).ToUpper(); $ps = @(Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*($hs)" })
                       return @{ ok = ($ps.Count -gt 0); txt = $(if ($ps.Count) { 'Printers here: ' + (($ps | ForEach-Object { $_.Name + ' [' + $_.PrinterStatus + ']' }) -join ', ') } else { "No printer of $hs here" }); t = (PD-NowMs) } }
      { $_ -in 'bt_check', 'bt_restart', 'bt_reinstall' } { $bad = @(PD-BtDevices | Where-Object { $_.Status -ne 'OK' }).Count; return @{ ok = ($bad -eq 0); txt = "Bluetooth devices in error: $bad"; t = (PD-NowMs) } }
      'printer_driver' { if (!$a -or !$a.driver) { return $null }; $d = Get-PrinterDriver -Name ([string]$a.driver) -ErrorAction SilentlyContinue; return @{ ok = [bool]$d; txt = $(if ($d) { 'Driver installed' } else { 'Driver not found' }); t = (PD-NowMs) } }
    }
  } catch { return @{ ok = $false; txt = 'check failed: ' + $_.Exception.Message; t = (PD-NowMs) } }
  $null
}
# ---------- 🩺 Fixes: the same fix as a command (📋 Copy in the tray / Console) - for somebody who prefers the terminal (PowerShell as admin) ----------
$PD_CMD = @{
  'spooler'      = @{ c = 'Stop-Service Spooler -Force; Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force; Start-Service Spooler'; u = '' }
  'net_private'  = @{ c = "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private; Enable-NetFirewallRule -DisplayGroup 'Network Discovery','File and Printer Sharing'"; u = 'Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Public' }
  'rpc_print'    = @{ c = "Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' RpcAuthnLevelPrivacyEnabled 0 -Type DWord; `$p='HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC'; New-Item `$p -Force | Out-Null; Set-ItemProperty `$p RpcUseNamedPipeProtocol 1 -Type DWord; Set-ItemProperty `$p RpcProtocols 7 -Type DWord; Restart-Service Spooler -Force"
                     u = "Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' RpcAuthnLevelPrivacyEnabled; Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC' RpcUseNamedPipeProtocol,RpcProtocols; Restart-Service Spooler -Force" }
  'blank_pw_net' = @{ c = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f'; u = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 1 /f' }
  'save_login'   = @{ c = 'cmdkey /add:{host} /user:{user} /pass:THE-PASSWORD   (normal Command Prompt, NOT as admin; leave /pass: empty for no password)'; u = 'cmdkey /delete:{host}' }
  'printer_guest' = @{ c = 'Add-PrinterPort -Name "\\{host}\<printer share>"; Add-Printer -Name "<printer share> ({host})" -DriverName "<driver name>" -PortName "\\{host}\<printer share>"   (driver installed first)'; u = 'Remove-Printer -Name "<printer share> ({host})"' }
  'print_user'   = @{ c = 'net user print THE-PASSWORD /add /passwordchg:no /expires:never   (PC Doctor fills the password in from the Console)'; u = 'net user print /delete' }
  'driver_share' = @{ c = '(PC Doctor fix: copies each shared printer''s driver to ProgramData\DavanPCDoctor\drivers-share and shares it read-only as PCDoctor-Drivers)'; u = 'Remove-SmbShare -Name PCDoctor-Drivers -Force' }
  'restart'      = @{ c = 'shutdown /r /t 60'; u = '' }
  'repair_windows' = @{ c = 'DISM /Online /Cleanup-Image /RestoreHealth; sfc /scannow'; u = '' }
  'check_disk'   = @{ c = 'echo Y | chkdsk C: /scan /perf'; u = '' }
  'win_update_dl' = @{ c = 'UsoClient StartScan; UsoClient StartDownload'; u = '' }
  'winget'       = @{ c = 'winget upgrade --all --silent --accept-package-agreements --accept-source-agreements'; u = '' }
}
function PD-FixCmd([string]$fix, $a) {
  $x = $PD_CMD[$fix]; if (!$x) { return @{ c = '(PC Doctor fix - no single command; press ▶ Fix now)'; u = '' } }
  $c = [string]$x.c; $u = [string]$x.u
  foreach ($k in 'host', 'user', 'name', 'ip', 'driver', 'kb', 'inf') { $v = if ($a -and $null -ne $a.$k) { [string]$a.$k } else { '' }; if ($v) { $c = $c.Replace('{' + $k + '}', $v); $u = $u.Replace('{' + $k + '}', $v) } }
  @{ c = $c; u = $u }
}
# ---------- 🩺 Fixes: this PC's fix book = DB5 lab/book/<hwid>/<id> + state\book.json (the tray reads it, also offline) ----------
# type fix: { fix, args, title, why, by, need: auto | person | user, st: wait | ready | running | done | failed | undo | undone, res, chk, undo, cmd, undoCmd, prob, user: worked | not }
# type prob: { cat, choice, text, photo (Cloudinary link), who, st: open | fixed, fix (the fix it is about), ev (evidence saved) }
$script:BookCache = @{}; $script:PDBookCur = $null
function PD-H($o) { if ($null -eq $o) { return @{} }; if ($o -is [hashtable]) { return $o }; $h2 = @{}; foreach ($pp in $o.PSObject.Properties) { $h2[$pp.Name] = $pp.Value }; $h2 }
function PD-BookLoad { $b = PD-ReadJson (Join-Path $PD.Root 'state\book.json'); $script:BookCache = @{}; if ($b -and $b.items) { foreach ($x in @($b.items)) { if ($x.id) { $script:BookCache[[string]$x.id] = (PD-H $x) } } } }
function PD-BookSave {
  $it = @($script:BookCache.Values | Sort-Object { -[int64]$_.t } | Select-Object -First 80)
  PD-WriteJson (Join-Path $PD.Root 'state\book.json') @{ t = (PD-NowMs); online = [bool]$PD.Online; items = $it }
}
function PD-BookNew([string]$type, [hashtable]$e) {
  $id = 'b' + (PD-NowMs) + (Get-Random -Minimum 10 -Maximum 99); $e.id = $id; $e.type = $type; if (!$e.t) { $e.t = PD-NowMs }
  if ($null -ne $e.args) { $ah = PD-H $e.args; if ($ah.ContainsKey('pass')) { $ah.pass = '***' }; $e.args = $ah }   # passwords never go to DB5
  if ($type -eq 'fix' -and !$e.cmd) { $cx = PD-FixCmd ([string]$e.fix) $e.args; $e.cmd = $cx.c; $e.undoCmd = $cx.u }
  $e.u = PD-NowMs; PD-Db PUT ('lab/book/' + (PD-Hwid) + '/' + $id) $e | Out-Null; $script:BookCache[$id] = $e; PD-BookSave; $id
}
function PD-BookPatch([string]$id, [hashtable]$p) {
  $p.u = PD-NowMs; PD-Db PATCH ('lab/book/' + (PD-Hwid) + '/' + $id) $p | Out-Null
  $e = PD-H $script:BookCache[$id]; foreach ($k in $p.Keys) { $e[$k] = $p[$k] }; $e.id = $id; $script:BookCache[$id] = $e; PD-BookSave
}
PD-BookLoad
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
    'blank_pw_net' { Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' LimitBlankPasswordUse $(if ($null -eq $u.old) { 1 } else { [int]$u.old }) -Type DWord; 'other PCs need a password again (no-password logins blocked)' }
    'print_user'   { if ($u.new) { Remove-LocalUser -Name ([string]$u.user) -ErrorAction SilentlyContinue; Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Name ([string]$u.user) -ErrorAction SilentlyContinue; Remove-Item (Join-Path $PD.Root 'state\printuser.json') -ErrorAction SilentlyContinue; 'printer login ' + $u.user + ' removed' } else { 'the user was there before - left as it was' } }
    'driver_share' { Remove-SmbShare -Name $PD_DRVSHARE -Force -ErrorAction SilentlyContinue; 'driver share PCDoctor-Drivers switched off (the copied driver files stay)' }
    'printer_guest' { foreach ($n in @($u.names | Where-Object { $_ })) { Remove-Printer -Name ([string]$n) -ErrorAction SilentlyContinue }; foreach ($pq in @($u.ports | Where-Object { $_ })) { Remove-PrinterPort -Name ([string]$pq) -ErrorAction SilentlyContinue }; 'printers removed: ' + (@($u.names) -join ', ') }
    default       { 'nothing to undo' }
  }
}
