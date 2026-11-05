# Davan PC Doctor loader (ROADMAP-pcdoctor.md 6). Installed by PCDoctor-Setup.cmd; started at boot (SYSTEM task, before login) and by the
# PCDoctorSvc service (also in Safe Mode). Every boot + every hour: reads pcdoctor/lab-version.json from GitHub, downloads newer files,
# checks the SHA-256 of every file (a changed / fake file is refused), runs agent.ps1. Channel: the test PCs (lab/cfg/test) get a new
# version at once; everyone else when lab/cfg/relOk says the test PCs are healthy, or testHoldH (2 h) after it was published.
# A new version that stays silent 10 min (no heartbeat) -> back to the last good version + ☁️ alert.
$ErrorActionPreference = 'Continue'
$Root = "$env:ProgramData\DavanPCDoctor"; $Bin = "$Root\bin"; $Good = "$Root\good"
$Raw = 'https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/pcdoctor/'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force $Bin, $Good, "$Root\state", "$Root\log", "$Root\req" | Out-Null
$mtx = New-Object Threading.Mutex($false, 'Global\DavanPCDoctorLoader'); if (!$mtx.WaitOne(0)) { exit 0 }
function L-Log($m) { Add-Content "$Root\log\loader.log" ((Get-Date).ToString('dd-MMM HH:mm:ss') + '  ' + $m) -Encoding UTF8 }
function L-Json($f) { try { Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $null } }
function L-Sha($f) { (Get-FileHash -Algorithm SHA256 $f).Hash.ToLower() }
function L-Safe { (Get-CimInstance Win32_ComputerSystem).BootupState -ne 'Normal boot' }
# 04-Nov-2026 (user: "Update now in the tray + which version, when, what's new"): every check saves the version list (state\labver.json, the
# tray's What's new) and its result (state\upd.json); a check asked from the tray (req\update.flag) skips the 2-h wait for the test PCs
function L-Res([string]$t, [bool]$m) { @{ at = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); res = $t; manual = $m } | ConvertTo-Json | Set-Content "$Root\state\upd.json" -Encoding UTF8 }
# 1.23 (user, 05-Nov-2026: "show the update progress in the tray so I know what is happening"): every step goes to state\updp.json
function L-P([string]$ph, [int]$i = 0, [int]$n = 0, [string]$file = '', [string]$to = '') {
  try { @{ t = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); ph = $ph; i = $i; n = $n; file = $file; to = $to } | ConvertTo-Json -Compress | Set-Content "$Root\state\updp.json" -Encoding UTF8 } catch {} }
# 1.25 (user, 05-Nov-2026: "Update now says no internet" while the PC was online): one try at one address was all - now 3 tries, then
# GitHub's API as a second road (another server), the real reason in the message, and a failed check tries again in 5 minutes
function L-Get([string]$path, [string]$out = '') {
  $urls = @(($Raw + $path), ('https://api.github.com/repos/harshgujjar/davan-attendance/contents/pcdoctor/' + ($path -replace '\?.*$', '') + '?ref=main')); $err = ''
  foreach ($n in 1..3) { foreach ($u in $urls) {
    try { $h = @{ 'User-Agent' = 'DavanPCDoctor'; 'Cache-Control' = 'no-cache' }; if ($u -like '*api.github.com*') { $h.Accept = 'application/vnd.github.raw' }
      if ($out) { Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $h -OutFile $out -TimeoutSec 120; return $true }
      return (Invoke-RestMethod -Uri $u -Headers $h -TimeoutSec 30) } catch { $err = $_.Exception.Message } }
    Start-Sleep -Seconds (3 * $n) }
  $script:lastErr = $err; L-Log ("could not get $path : $err"); $null }
function L-Fetch([switch]$Manual) {
  L-P 'check'
  $v = L-Get ('lab-version.json?t=' + [DateTime]::UtcNow.Ticks); if ($v -is [string]) { try { $v = $v | ConvertFrom-Json } catch { $v = $null } }
  if (!$v -or !$v.agent) { $script:failAt = Get-Date; L-Res ('Could not reach the update server (' + $script:lastErr + ') - tries again in 5 minutes') $Manual; return $null }
  try { $v | ConvertTo-Json -Depth 6 | Set-Content "$Root\state\labver.json" -Encoding UTF8 } catch {}
  $run = L-Json "$Root\state\running.json"
  if ($run -and $run.build -ge $v.agent.build) { L-Res ('Already the newest: ' + $run.ver + ' (build ' + $run.build + ')') $Manual; return $null }
  $bad = @(L-Json "$Root\state\bad.json"); if ($bad -contains $v.agent.build) { L-Res ('Build ' + $v.agent.build + ' was rolled back on this PC - waiting for a newer one') $Manual; return $null }
  # channel: test PCs at once; others after relOk / testHoldH
  $cfg = L-Json "$Root\state\cfg.json"; $id = L-Json "$Root\id.json"
  $test = $cfg -and (@($cfg.test) -contains $env:COMPUTERNAME -or ($id -and @($cfg.test) -contains $id.hwid))
  if (Test-Path "$Root\state\laptop.flag") { $test = $true }
  if ($Manual) { $test = $true }   # asked from the tray: no waiting   # 04-Nov: the Super Admin laptop always gets a new build at once
  $hold = if ($cfg -and $cfg.testHoldH) { [double]$cfg.testHoldH } else { 2 }
  $age = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - [int64]$v.agent.at) / 3600000
  if (!$test -and $run -and !($cfg -and $cfg.relOk -ge $v.agent.build) -and $age -lt $hold) { L-Log "build $($v.agent.build) waits for the test PCs ($([math]::Round($age,1)) h of $hold h)"; L-Res ('Build ' + $v.agent.build + ' comes here in ' + [math]::Ceiling($hold - $age) + ' h (after the test PCs) - or tap Update now') $false; return $null }
  $nf = @($v.files.PSObject.Properties).Count; $k = 0; $to = [string]$v.agent.ver
  $tmp = "$Root\dl\new"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force $tmp | Out-Null
  foreach ($f in $v.files.PSObject.Properties) {
    $o = Join-Path $tmp $f.Name; $k++; L-P 'download' $k $nf $f.Name $to
    if (!(L-Get ('src/' + $f.Name + '?v=' + $f.Value) $o)) { $script:failAt = Get-Date; L-Res ('Download of ' + $f.Name + ' failed (' + $script:lastErr + ') - tries again in 5 minutes') $Manual; return $null }
    if ((L-Sha $o) -ne $f.Value) { L-Log "REFUSED $($f.Name): SHA-256 does not match lab-version.json"; L-Res 'Update refused: a file did not match its fingerprint (safety check)' $Manual; return $null }
  }
  L-P 'install' $nf $nf '' $to
  if (Test-Path "$Bin\agent.ps1") { Remove-Item "$Good\*" -Force -ErrorAction SilentlyContinue; Copy-Item "$Bin\*" $Good -Force; Copy-Item "$Root\state\running.json" "$Good\running.json" -ErrorAction SilentlyContinue }
  Copy-Item "$tmp\*" $Bin -Force
  @{ ver = $v.agent.ver; build = $v.agent.build; at = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); prev = $(if ($run) { $run.build } else { 0 }) } | ConvertTo-Json | Set-Content "$Root\state\running.json" -Encoding UTF8
  if (Test-Path "$Bin\loader.ps1") { Copy-Item "$Bin\loader.ps1" "$Root\loader.ps1" -Force }   # the loader updates itself (used from the next start)
  L-Log "updated to $($v.agent.ver) (build $($v.agent.build))"; L-Res ('Updated to ' + $v.agent.ver + ' (build ' + $v.agent.build + ')') $Manual
  $v
}
function L-Start {
  $a = "$Bin\agent.ps1"; if (!(Test-Path $a)) { return $null }
  Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$a`"" -WindowStyle Hidden -PassThru
}
function L-Rollback($why) {
  $run = L-Json "$Root\state\running.json"; $bad = @(L-Json "$Root\state\bad.json") + @($run.build) | Where-Object { $_ }
  $bad | ConvertTo-Json | Set-Content "$Root\state\bad.json"
  if (Test-Path "$Good\agent.ps1") { Copy-Item "$Good\*.ps1" $Bin -Force; if (Test-Path "$Good\running.json") { Copy-Item "$Good\running.json" "$Root\state\running.json" -Force } }
  L-Log "ROLLED BACK build $($run.build): $why"
  @{ t = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); build = $run.build; why = $why } | ConvertTo-Json | Set-Content "$Root\state\rolledback.json"
  # the agent reports it (lab/ver + ☁️ alert) once it runs again
}
# first copy from the installer if GitHub is not reachable
if (!(Test-Path "$Bin\agent.ps1") -and (Test-Path "$Root\setup\agent.ps1")) { Copy-Item "$Root\setup\*.ps1" $Bin -Force }
$p = $null; $lastCheck = [datetime]::MinValue; $newAt = $null
while ($true) {
  try {
    # 1.32 (user, 05-Nov-2026: "for my laptop and PC make the update reach in 5 min, not one hour"): the Super Admin laptop and the test PCs
    # (lab/cfg test list) look every 5 minutes (cfg fastMin changes it); every other PC keeps the hourly look
    $ivm = 60; $c0 = L-Json "$Root\state\cfg.json"; $id0 = L-Json "$Root\id.json"
    if ((Test-Path "$Root\state\laptop.flag") -or ($c0 -and (@($c0.test) -contains $env:COMPUTERNAME -or ($id0 -and @($c0.test) -contains $id0.hwid)))) { $ivm = $(if ($c0 -and $c0.fastMin) { [double]$c0.fastMin } else { 5 }) }
    if (((Get-Date) - $lastCheck).TotalMinutes -ge $ivm -or (Test-Path "$Root\req\update.flag") -or ($script:failAt -and ((Get-Date) - $script:failAt).TotalMinutes -ge 5)) { $script:failAt = $null
      $man = Test-Path "$Root\req\update.flag"; Remove-Item "$Root\req\update.flag" -Force -ErrorAction SilentlyContinue; $lastCheck = Get-Date
      $nv = L-Fetch -Manual:$man
      if ($nv) { L-P 'restart' 0 0 '' ([string]$nv.agent.ver); if ($p -and !$p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }; $p = $null; $newAt = Get-Date }
    }
    if (!$p -or $p.HasExited) { $p = L-Start; if (!$newAt) { $newAt = Get-Date } }
    # heartbeat: state\hb.txt written by the agent every minute
    $hb = 0; try { $hb = [int64](Get-Content "$Root\state\hb.txt" -ErrorAction Stop) } catch {}
    $age = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $hb) / 60000
    $cfg = L-Json "$Root\state\cfg.json"; $rb = if ($cfg -and $cfg.rollbackMin) { [double]$cfg.rollbackMin } else { 10 }
    if ($newAt -and ((Get-Date) - $newAt).TotalMinutes -gt $rb -and $age -gt $rb -and (Test-Path "$Good\agent.ps1")) {
      if ($p -and !$p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }; L-Rollback "silent $([math]::Round($age)) min after the update"; $p = $null; $newAt = $null; continue }
    if ($newAt -and $age -lt 3) { $newAt = $null }   # the new version is alive
  } catch { L-Log ('loader: ' + $_.Exception.Message) }
  foreach ($w in 1..12) { Start-Sleep 5; if (Test-Path "$Root\req\update.flag") { break } }   # 1.23: Update now starts within 5 s (was up to 60 s)
}
