# Davan PC Doctor - common.ps1 (shared by the PC Doctor Agent, tray and Rescue). PowerShell 5.1 (Windows 10 / 11), no .exe.
# DB5 = Firebase davan-lab. Login: worker davan-release /lab/pc -> custom token -> Firebase ID token; the refresh token is kept in
# id.json (made at install while Thawed) so a PC keeps working even when the worker is down.
$ErrorActionPreference = 'Continue'
$PD = @{
  Root   = "$env:ProgramData\DavanPCDoctor"
  Db     = 'https://davan-lab-default-rtdb.asia-southeast1.firebasedatabase.app'
  Key    = 'AIzaSyAdebhgQpyjd3ZQgUl_UNhLXYUDRJK1C1s'
  Worker = 'https://davan-release.harshgujjar.workers.dev'
  Raw    = 'https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/pcdoctor/'
  Tok = ''; TokExp = [datetime]::MinValue; Id = $null; Cfg = $null; CfgAt = [datetime]::MinValue
  Queue = New-Object System.Collections.ArrayList; Online = $false; LastSent = $null; LastErr = ''
}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
foreach ($d in 'state','log','req','bin','good','dl','out') { New-Item -ItemType Directory -Force -Path (Join-Path $PD.Root $d) | Out-Null }

function PD-Log([string]$m) {
  $f = Join-Path $PD.Root 'log\agent.log'
  try { if ((Test-Path $f) -and (Get-Item $f).Length -gt 2MB) { Move-Item $f "$f.old" -Force }
    Add-Content -Path $f -Value ((Get-Date).ToString('dd-MMM HH:mm:ss') + '  ' + $m) -Encoding UTF8 } catch {}
}
function PD-NowMs { [int64](([datetimeoffset]::UtcNow).ToUnixTimeMilliseconds()) }
function PD-IST([int64]$ms) { ([datetimeoffset]::FromUnixTimeMilliseconds($ms)).ToOffset([timespan]::FromHours(5.5)).ToString('dd MMM yyyy, h:mm tt') + ' IST' }
function PD-ISTDate([int64]$ms = 0) { if (!$ms) { $ms = PD-NowMs }; ([datetimeoffset]::FromUnixTimeMilliseconds($ms)).ToOffset([timespan]::FromHours(5.5)).ToString('yyyy-MM-dd') }
function PD-Json($o, [int]$d = 12) { $o | ConvertTo-Json -Depth $d -Compress }
function PD-ReadJson([string]$f) { try { if (Test-Path $f) { return (Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json) } } catch {}; $null }
function PD-WriteJson([string]$f, $o) { try { [IO.File]::WriteAllText($f, (PD-Json $o), (New-Object Text.UTF8Encoding($false))) } catch {} }
function PD-Sha256File([string]$f) { (Get-FileHash -Algorithm SHA256 -Path $f).Hash.ToLower() }
function PD-Sha256Text([string]$s) { $b = [Text.Encoding]::UTF8.GetBytes($s); (-join ([Security.Cryptography.SHA256]::Create().ComputeHash($b) | ForEach-Object { $_.ToString('x2') })) }

# ---- ThawSpace / place that survives a Deep Freeze restart (6: queue) ----
function PD-ThawPath {
  foreach ($v in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue)) {
    if ($v.VolumeName -match 'thaw' -or (Test-Path ($v.DeviceID + '\ThawSpace'))) { $p = $v.DeviceID + '\DavanPCDoctor'; New-Item -ItemType Directory -Force $p | Out-Null; return $p }
  }
  $null
}
function PD-DeepFreeze {
  # Deep Freeze Standard: state from its driver / registry (no DFC.exe command line). frozen | thawed | none
  $r = @{ state = 'none'; ver = ''; thaw = (PD-ThawPath) }
  $svc = Get-Service -Name 'DFServ' -ErrorAction SilentlyContinue
  if ($svc) {
    $r.state = 'frozen'
    try { $k = Get-ItemProperty 'HKLM:\SOFTWARE\Faronics\Deep Freeze 6' -ErrorAction Stop; if ($k.'DF Status' -eq 0 -or $k.'DF Status' -eq 'Thawed') { $r.state = 'thawed' } } catch {}
    try { $f = Get-Item "$env:SystemRoot\System32\DFC.exe","$env:ProgramFiles\Faronics\Deep Freeze\Install C-0\DF5Serv.exe" -ErrorAction SilentlyContinue | Select-Object -First 1; if ($f) { $r.ver = $f.VersionInfo.ProductVersion } } catch {}
    # a write to a frozen disk vanishes at restart: compare a marker written last boot
    $m = "$env:ProgramData\DavanPCDoctor\state\df_marker.txt"
    try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString('s')
      if (Test-Path $m) { $old = Get-Content $m -Raw; if ($old -and $old.Trim() -ne $boot) { $r.state = 'thawed' } }
      Set-Content $m $boot } catch {}
  }
  $r
}

# ---- identity + login ----
function PD-LoadId { $PD.Id = PD-ReadJson (Join-Path $PD.Root 'id.json'); $PD.Id }
function PD-SaveId { PD-WriteJson (Join-Path $PD.Root 'id.json') $PD.Id }
function PD-Fingerprint {
  $cs = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
  $bb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
  $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
  $nic = Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=True' -ErrorAction SilentlyContinue | Where-Object { $_.MACAddress -and $_.PNPDeviceID -match '^PCI' } | Select-Object -First 1
  $disks = @(Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceType -ne 'USB' } | ForEach-Object { ($_.SerialNumber + '').Trim() } | Where-Object { $_ })
  $ram = @(Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | ForEach-Object { ($_.SerialNumber + '').Trim() } | Where-Object { $_ })
  $inst = ''; try { $inst = [string](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallDate } catch {}
  @{ bu = [string]$cs.UUID; bb = [string]$bb.SerialNumber; mac = [string]$nic.MACAddress; cpu = [string]$cpu.ProcessorId; disks = $disks; ram = $ram; inst = $inst;
     model = ([string]$cs.Vendor + ' ' + [string]$cs.Name).Trim() }
}
function PD-Register([switch]$New) {
  if ($PD.Test) { throw 'test mode never registers' }   # 1.6: the GitHub test machine registered itself as a PC
  $fp = PD-Fingerprint
  $body = @{ fp = $fp; name = $env:COMPUTERNAME; inst = $fp.inst; ver = (PD-AgentVer) }
  if (!$New -and $PD.Id) { $body.hwid = $PD.Id.hwid; $body.key = $PD.Id.key }
  $r = Invoke-RestMethod -Method Post -Uri ($PD.Worker + '/lab/pc') -Body (PD-Json $body) -ContentType 'text/plain' -TimeoutSec 40
  if (!$r.ok) { throw ('register: ' + $r.msg) }
  if ($r.key) { $PD.Id = [pscustomobject]@{ hwid = $r.hwid; key = $r.key; refresh = ''; known = [bool]$r.known; name = $r.name; merge = $r.merge } }
  $t = Invoke-RestMethod -Method Post -Uri ('https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=' + $PD.Key) -Body (PD-Json @{ token = $r.token; returnSecureToken = $true }) -ContentType 'application/json' -TimeoutSec 30
  $PD.Tok = $t.idToken; $PD.TokExp = (Get-Date).AddSeconds([int]$t.expiresIn - 300)
  $PD.Id | Add-Member -NotePropertyName refresh -NotePropertyValue $t.refreshToken -Force
  PD-SaveId; $r
}
function PD-Token {
  if ($PD.Test) { return $null }
  if ($PD.Tok -and (Get-Date) -lt $PD.TokExp) { return $PD.Tok }
  if (!$PD.Id) { PD-LoadId | Out-Null }
  if ($PD.Id -and $PD.Id.refresh) {
    try {
      $t = Invoke-RestMethod -Method Post -Uri ('https://securetoken.googleapis.com/v1/token?key=' + $PD.Key) -Body ('grant_type=refresh_token&refresh_token=' + $PD.Id.refresh) -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 30
      $PD.Tok = $t.id_token; $PD.TokExp = (Get-Date).AddSeconds([int]$t.expires_in - 300); return $PD.Tok
    } catch { PD-Log ('refresh failed: ' + $_.Exception.Message) }
  }
  PD-Register | Out-Null; $PD.Tok
}
function PD-Hwid { if (!$PD.Id) { PD-LoadId | Out-Null }; if ($PD.Id) { $PD.Id.hwid } else { '' } }

# ---- DB5 REST; a failed write goes to the queue (ThawSpace file if present, else memory) and is sent later ----
function PD-Db([string]$Method, [string]$Path, $Body = $null, [string]$Query = '', [switch]$NoQueue) {
  if ($PD.Test) { return $null }   # test mode (Windows runner) never touches DB5
  try {
    $u = $PD.Db + '/' + $Path + '.json?auth=' + (PD-Token) + $(if ($Query) { '&' + $Query } else { '' })
    $p = @{ Method = $Method; Uri = $u; TimeoutSec = 30; ContentType = 'application/json; charset=utf-8' }
    if ($null -ne $Body) { $p.Body = [Text.Encoding]::UTF8.GetBytes((PD-Json $Body)) }
    $r = Invoke-RestMethod @p
    $PD.Online = $true; if ($Method -ne 'GET') { $PD.LastSent = Get-Date }
    return $r
  } catch {
    $PD.Online = $false; $PD.LastErr = $_.Exception.Message
    if ($Method -ne 'GET' -and !$NoQueue) { PD-Enqueue $Method $Path $Body }
    return $null
  }
}
function PD-QueueFile { $t = PD-ThawPath; if ($t) { Join-Path $t 'queue.jsonl' } else { $null } }
function PD-Enqueue($Method, $Path, $Body) {
  $row = PD-Json @{ m = $Method; p = $Path; b = $Body; t = (PD-NowMs) }
  $f = PD-QueueFile
  if ($f) { try { Add-Content -Path $f -Value $row -Encoding UTF8; return } catch {} }
  if ($PD.Queue.Count -gt 5000) { $PD.Queue.RemoveAt(0) }
  [void]$PD.Queue.Add($row)
}
function PD-FlushQueue {
  $rows = New-Object System.Collections.ArrayList
  $f = PD-QueueFile
  if ($f -and (Test-Path $f)) { Get-Content $f -Encoding UTF8 | ForEach-Object { [void]$rows.Add($_) }; Remove-Item $f -Force }
  $rows.AddRange($PD.Queue); $PD.Queue.Clear()
  $sent = 0
  foreach ($r in $rows) {
    try { $o = $r | ConvertFrom-Json } catch { continue }
    $res = PD-Db $o.m $o.p $o.b -NoQueue
    if ($PD.Online) { $sent++ } else { PD-Enqueue $o.m $o.p $o.b }
  }
  if ($sent) { PD-Log "queue: sent $sent saved rows" }
  $sent
}
function PD-QueueCount { $n = $PD.Queue.Count; $f = PD-QueueFile; if ($f -and (Test-Path $f)) { $n += @(Get-Content $f).Count }; $n }

# ---- settings (lab/cfg, every hour; fallback pcdoctor/cfg-default.json, then the last copy on disk) ----
function PD-Cfg([switch]$Force) {
  if (!$Force -and $PD.Cfg -and ((Get-Date) - $PD.CfgAt).TotalMinutes -lt 60) { return $PD.Cfg }
  $c = PD-Db GET 'lab/cfg'
  if (!$c) { try { $c = Invoke-RestMethod -Uri ($PD.Raw + 'cfg-default.json?t=' + (PD-NowMs)) -TimeoutSec 30 } catch {} }
  $f = Join-Path $PD.Root 'state\cfg.json'
  if ($c) { PD-WriteJson $f $c } else { $c = PD-ReadJson $f }
  $PD.Cfg = $c; $PD.CfgAt = Get-Date; $c
}
function PD-Thr([string]$k, $def) { $c = PD-Cfg; if ($c -and $c.thr -and $null -ne $c.thr.$k) { $c.thr.$k } else { $def } }
function PD-Group([string]$name) {
  # 4: the longest prefix in lab/cfg/groups wins (A5 -> A = Lab 1, PUC2 -> PUC); a laptop -> SA
  $c = PD-Cfg; $best = ''
  if ($c -and $c.groups) { foreach ($p in $c.groups.PSObject.Properties.Name) { if ($name -like ($p + '*') -and $name.Substring($p.Length) -match '^\d+$' -and $p.Length -gt $best.Length) { $best = $p } } }
  if (!$best -and (Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes -match '^(8|9|10|14|30|31|32)$') { $best = 'SA' }
  $best
}
function PD-AgentVer { $v = PD-ReadJson (Join-Path $PD.Root 'state\running.json'); if ($v) { [string]$v.ver } else { '0' } }
function PD-Alert([string]$kind, [string]$title, [string]$body, [string]$color = 'red') {
  if ($PD.Test) { return }
  try { Invoke-RestMethod -Method Post -Uri ($PD.Worker + '/lab/alert') -Body (PD-Json @{ idToken = (PD-Token); kind = $kind; title = $title; body = $body; color = $color }) -ContentType 'text/plain' -TimeoutSec 30 | Out-Null } catch { PD-Log ('alert not sent: ' + $_.Exception.Message) }
}
function PD-Event([string]$k, [string]$icon, [string]$txt, $extra = $null) {
  $t = PD-NowMs; $e = @{ t = $t; k = $k; icon = $icon; txt = $txt }
  if ($extra) { foreach ($p in $extra.Keys) { $e[$p] = $extra[$p] } }
  PD-Db PUT ('lab/events/' + (PD-Hwid) + '/e' + $t) $e | Out-Null
  $e
}

# 05-Nov-2026 (user: "a PowerShell window opens at start with red Get-Content errors"): Windows 11 opens "powershell -WindowStyle Hidden" in
# Windows Terminal, which ignores Hidden - so the tray showed a console. The tray now starts through wscript (window style 0 = never shown).
# Run as SYSTEM by the agent at every start (old installs fix themselves) and by install.ps1.
function PD-TrayLauncher {
  $v = Join-Path $PD.Root 'tray-start.vbs'
  $body = 'CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File ""' + (Join-Path $PD.Root 'bin\tray.ps1') + '""", 0, False'
  try { if (!(Test-Path $v) -or (Get-Content $v -Raw -ErrorAction Stop).Trim() -ne $body) { [IO.File]::WriteAllText($v, $body, [Text.Encoding]::ASCII) } } catch {}
  $run = 'wscript.exe "' + $v + '"'; $k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
  try { if ((Get-ItemProperty $k -Name DavanPCDoctor -ErrorAction SilentlyContinue).DavanPCDoctor -ne $run) { Set-ItemProperty $k 'DavanPCDoctor' $run } } catch {}
  $v
}
