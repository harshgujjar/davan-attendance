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
function L-Fetch {
  try { $v = Invoke-RestMethod -Uri ($Raw + 'lab-version.json?t=' + [DateTime]::UtcNow.Ticks) -TimeoutSec 30 } catch { L-Log ('version file not reached: ' + $_.Exception.Message); return $null }
  $run = L-Json "$Root\state\running.json"
  if ($run -and $run.build -ge $v.agent.build) { return $null }
  $bad = @(L-Json "$Root\state\bad.json"); if ($bad -contains $v.agent.build) { return $null }
  # channel: test PCs at once; others after relOk / testHoldH
  $cfg = L-Json "$Root\state\cfg.json"; $id = L-Json "$Root\id.json"
  $test = $cfg -and (@($cfg.test) -contains $env:COMPUTERNAME -or ($id -and @($cfg.test) -contains $id.hwid))
  if (Test-Path "$Root\state\laptop.flag") { $test = $true }   # 04-Nov: the Super Admin laptop always gets a new build at once
  $hold = if ($cfg -and $cfg.testHoldH) { [double]$cfg.testHoldH } else { 2 }
  $age = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - [int64]$v.agent.at) / 3600000
  if (!$test -and $run -and !($cfg -and $cfg.relOk -ge $v.agent.build) -and $age -lt $hold) { L-Log "build $($v.agent.build) waits for the test PCs ($([math]::Round($age,1)) h of $hold h)"; return $null }
  $tmp = "$Root\dl\new"; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force $tmp | Out-Null
  foreach ($f in $v.files.PSObject.Properties) {
    $o = Join-Path $tmp $f.Name
    try { Invoke-WebRequest -UseBasicParsing -Uri ($Raw + 'src/' + $f.Name + '?v=' + $f.Value) -OutFile $o -TimeoutSec 120 } catch { L-Log "download $($f.Name) failed"; return $null }
    if ((L-Sha $o) -ne $f.Value) { L-Log "REFUSED $($f.Name): SHA-256 does not match lab-version.json"; return $null }
  }
  if (Test-Path "$Bin\agent.ps1") { Remove-Item "$Good\*" -Force -ErrorAction SilentlyContinue; Copy-Item "$Bin\*" $Good -Force; Copy-Item "$Root\state\running.json" "$Good\running.json" -ErrorAction SilentlyContinue }
  Copy-Item "$tmp\*" $Bin -Force
  @{ ver = $v.agent.ver; build = $v.agent.build; at = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); prev = $(if ($run) { $run.build } else { 0 }) } | ConvertTo-Json | Set-Content "$Root\state\running.json" -Encoding UTF8
  if (Test-Path "$Bin\loader.ps1") { Copy-Item "$Bin\loader.ps1" "$Root\loader.ps1" -Force }   # the loader updates itself (used from the next start)
  L-Log "updated to $($v.agent.ver) (build $($v.agent.build))"
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
    if (((Get-Date) - $lastCheck).TotalMinutes -ge 60 -or (Test-Path "$Root\req\update.flag")) {
      Remove-Item "$Root\req\update.flag" -Force -ErrorAction SilentlyContinue; $lastCheck = Get-Date
      $nv = L-Fetch
      if ($nv) { if ($p -and !$p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }; $p = $null; $newAt = Get-Date }
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
  Start-Sleep 60
}
