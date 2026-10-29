# Davan Dialer - the laptop half that DIALS the parent calls (29-Oct-2026, user: "go build it").  ASCII only (PowerShell 5.1).
# Proven 29-Oct: only calls that Phone Link itself starts carry the laptop's voice. So this helper takes the next queued call
# (DB4 hostel/parent_calls/queue, st 'wait'), opens tel:<number> (Phone Link) and clicks Phone Link's "Call" button with Windows
# UI Automation. The Davan Caller phone (c6) follows that call: answer -> st 'talk' (caller-voice.html speaks) -> 'spoken' -> hang up -> log.
# Started by davan-dialer.cmd (which downloads the newest copy of this file first). Heartbeat: hostel/parent_calls/dialer, log: logs/dialer.
$VER = 'd4'
$KEY = 'AIzaSyDBfwaUiCP_5tLPgCV2yZSeeWRnwnvnkDQ'
$DB = 'https://davan-lessonplan-archive-default-rtdb.asia-southeast1.firebasedatabase.app'
$ROOT = 'hostel/parent_calls'
$DIR = Join-Path $env:LOCALAPPDATA 'DavanDialer'
New-Item -ItemType Directory -Force -Path $DIR | Out-Null
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
# d3: real mouse click + bring the window to the front (Phone Link ignored the UI Automation "Invoke" - log 29-Oct 08:34, no call started)
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class DvWin {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
  public static void Click(int x, int y) { SetCursorPos(x, y); mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero); mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero); }
}
"@
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:log = New-Object System.Collections.ArrayList
$script:status = 'Starting'
$script:tok = ''; $script:tokExp = 0; $script:logUp = ''; $script:lastButtons = ''
function Now { [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
function Log($s) {
  $line = (Get-Date -Format 'dd MMM HH:mm:ss') + '  ' + $s
  [void]$script:log.Insert(0, $line); while ($script:log.Count -gt 80) { $script:log.RemoveAt($script:log.Count - 1) }
  Write-Host $line
}

# --- anonymous Firebase sign-in (same as the apps), refreshed before it expires ---
function Token {
  if ($script:tok -and (Now) -lt $script:tokExp - 120000) { return $script:tok }
  $f = Join-Path $DIR 'refresh.txt'
  try {
    if (Test-Path $f) {
      $r = Invoke-RestMethod -Method Post -Uri "https://securetoken.googleapis.com/v1/token?key=$KEY" -ContentType 'application/x-www-form-urlencoded' -Body ('grant_type=refresh_token&refresh_token=' + [uri]::EscapeDataString((Get-Content $f -Raw).Trim()))
      $script:tok = $r.id_token; Set-Content $f $r.refresh_token; $script:tokExp = (Now) + [int]$r.expires_in * 1000; return $script:tok
    }
  } catch { Remove-Item $f -ErrorAction SilentlyContinue }
  $r = Invoke-RestMethod -Method Post -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$KEY" -ContentType 'application/json' -Body '{"returnSecureToken":true}'
  $script:tok = $r.idToken; Set-Content $f $r.refreshToken; $script:tokExp = (Now) + [int]$r.expiresIn * 1000; return $script:tok
}
function Db($method, $path, $body) {
  $u = "$DB/$path.json?auth=" + (Token)
  if ($method -eq 'GET') { return Invoke-RestMethod -Method Get -Uri $u }
  $json = if ($null -eq $body) { 'null' } else { $body | ConvertTo-Json -Depth 6 -Compress }
  Invoke-RestMethod -Method $method -Uri ($u + '&print=silent') -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null
}

# --- calling hours (cfg.hours "10:00-18:00", may pass midnight; cfg.days "123456", 1 = Monday) ---
function InHours($cfg) {
  try {
    $days = if ($cfg.days) { [string]$cfg.days } else { '123456' }
    $iso = [int](Get-Date).DayOfWeek; if ($iso -eq 0) { $iso = 7 }
    if (-not $days.Contains([string]$iso)) { return $false }
    $h = if ($cfg.hours) { [string]$cfg.hours } else { '10:00-18:00' }
    $p = $h.Split('-'); $a = [TimeSpan]::Parse($p[0].Trim()).TotalMinutes; $b = [TimeSpan]::Parse($p[1].Trim()).TotalMinutes
    $m = (Get-Date).TimeOfDay.TotalMinutes
    if ($a -le $b) { return ($m -ge $a -and $m -le $b) } else { return ($m -ge $a -or $m -le $b) }
  } catch { return $true }
}

# --- click Phone Link's Call button (any Phone Link window: main window or its call box) ---
function ClickCall {
  $deadline = (Get-Date).AddSeconds(15); $seen = ''
  $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
  while ((Get-Date) -lt $deadline) {
    $pids = @(Get-Process -Name 'PhoneExperienceHost', 'PhoneLink', 'YourPhone' -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
    $wins = [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($w in $wins) {
      if (-not ($pids -contains $w.Current.ProcessId) -and $w.Current.Name -notlike '*Phone Link*') { continue }
      $btns = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
      foreach ($b in $btns) {
        $n = [string]$b.Current.Name
        # d2: Phone Link names it "Call Dialed number 8 8 9 2 ..." (log 29-Oct 08:29) - any name that starts with "Call " / is "Call", never the "Calls" tab
        if ($n -match '^\s*(Call|Dial|Call now)\s*$' -or $n -match '^Call\s') {
          $how = @()
          try { $h = [IntPtr]$w.Current.NativeWindowHandle; if ($h -ne [IntPtr]::Zero) { [void][DvWin]::ShowWindow($h, 9); [void][DvWin]::SetForegroundWindow($h) } } catch { }
          Start-Sleep -Milliseconds 400
          try { $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke(); $how += 'invoke' } catch { $how += 'invoke failed' }
          if (InCall $w 4) { return "call started after '$n' ($($how -join ', '))" }
          try {   # Phone Link did not react: real mouse click in the middle of the button
            $r = $b.Current.BoundingRectangle
            [DvWin]::Click([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2)); $how += "mouse click at $([int]($r.X + $r.Width / 2)),$([int]($r.Y + $r.Height / 2))"
          } catch { $how += 'mouse click failed' }
          if (InCall $w 6) { return "call started after '$n' ($($how -join ', '))" }
          $script:lastButtons = ((AllButtons $w) -join ' | ')
          Log "! pressed '$n' ($($how -join ', ')) but no call started. Buttons now: $($script:lastButtons)"
          return $null
        }
      }
      $seen = (($btns | ForEach-Object { $_.Current.Name }) | Where-Object { $_ }) -join ' | '
    }
    Start-Sleep -Milliseconds 700
  }
  $script:lastButtons = $seen
  return $null
}

function AllButtons($w) {
  $bc = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
  try { return @($w.FindAll([System.Windows.Automation.TreeScope]::Descendants, $bc) | ForEach-Object { $_.Current.Name } | Where-Object { $_ }) } catch { return @() }
}
# a call is running when Phone Link shows an End / Hang up button (in any of its windows)
function InCall($w, $sec) {
  $until = (Get-Date).AddSeconds($sec)
  while ((Get-Date) -lt $until) {
    $pids = @(Get-Process -Name 'PhoneExperienceHost', 'PhoneLink', 'YourPhone' -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
    $wins = [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
    foreach ($x in $wins) {
      if (-not ($pids -contains $x.Current.ProcessId) -and $x.Current.Name -notlike '*Phone Link*') { continue }
      foreach ($n in (AllButtons $x)) { if ($n -match '^(End|End call|Hang up|Hang Up)\b') { return $true } }
    }
    Start-Sleep -Milliseconds 500
  }
  return $false
}
function Beat {
  try {
    Db 'PUT' "$ROOT/dialer" @{ seen = (Now); ver = $VER; status = $script:status; pc = $env:COMPUTERNAME }
    $t = ("Davan Dialer $VER - $env:COMPUTERNAME`nStatus: " + $script:status + "`n" + ($script:log -join "`n"))
    if ($t -ne $script:logUp) { Db 'PUT' "$ROOT/logs/dialer" @{ at = (Now); ver = $VER; text = $t }; $script:logUp = $t }
  } catch { Write-Host "heartbeat: $($_.Exception.Message)" }
}

Log "> Davan Dialer $VER started"
$cfg = $null; $cfgAt = 0; $lastBeat = 0; $mine = $null; $mineAt = 0; $verAt = 0; $stopAt = $null
while ($true) {
  try {
    $now = Now
    if ($now - $lastBeat -gt 30000) { $lastBeat = $now; Beat }
    if ($now - $verAt -gt 3600000) {   # newer copy published -> exit; davan-dialer.cmd downloads it and starts again
      $verAt = $now
      try { $v = Invoke-RestMethod -Uri ('https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/caller-version.json?t=' + $now); if ($v.dialer -and $v.dialer -ne $VER) { Log "^ new dialer $($v.dialer) - restarting"; Beat; exit 0 } } catch { }
    }
    if ($now - $cfgAt -gt 120000 -or -not $cfg) { $cfg = Db 'GET' "$ROOT/cfg"; if (-not $cfg) { $cfg = [pscustomobject]@{} }; $cfgAt = $now }
    if ($mine) {   # a call this laptop placed is in progress: wait for the phone to finish it
      $st = Db 'GET' "$ROOT/queue/$mine/st"
      if ($st -eq 'stop') { if (-not $stopAt) { $stopAt = $now } elseif ($now - $stopAt -gt 15000) { Log "OK stop finished (no phone call to hang up)"; Db 'PATCH' "$ROOT/queue/$mine" @{ st = 'done'; res = 'stop'; doneAt = $now }; $mine = $null; $stopAt = $null; continue } } else { $stopAt = $null }   # d4
      if ($st -ne 'dial' -and $st -ne 'talk' -and $st -ne 'stop') { Log "OK call finished ($st)"; $mine = $null; $script:status = 'Ready'; Start-Sleep -Seconds 6; continue }
      if ($st -eq 'dial' -and $now - $mineAt -gt 90000) {   # the phone never picked it up
        Log "! the phone did not follow the call in 90 s - back to the queue"
        Db 'PATCH' "$ROOT/queue/$mine" @{ st = 'wait'; notBefore = $now + 300000; res = 'fail' }; $mine = $null
      }
      if ($mine -and $now - $mineAt -gt 240000) { Log "! call still open after 4 min - letting go"; $mine = $null }
      Start-Sleep -Seconds 3; continue
    }
    if ($cfg.paused) { $script:status = '|| Paused'; Start-Sleep -Seconds 10; continue }
    if (-not (InHours $cfg)) { $script:status = "night: outside calling hours ($($cfg.hours))"; Start-Sleep -Seconds 30; continue }
    $relay = Db 'GET' "$ROOT/relay"; $phone = Db 'GET' "$ROOT/caller"
    if (-not $relay -or $now - [int64]$relay.seen -gt 90000) { $script:status = 'laptop: voice page offline - open caller-voice.html in Edge'; Start-Sleep -Seconds 10; continue }
    if (-not $phone -or $now - [int64]$phone.seen -gt 150000) { $script:status = 'phone: Davan Caller phone offline'; Start-Sleep -Seconds 10; continue }
    $q = Db 'GET' "$ROOT/queue"
    if ($q) { foreach ($p in $q.PSObject.Properties) { if ($p.Value.st -eq 'stop' -and $now - [int64]$p.Value.dialAt -gt 120000) { Db 'PATCH' "$ROOT/queue/$($p.Name)" @{ st = 'done'; res = 'stop'; doneAt = $now }; Log "OK old stop finished: $($p.Value.name)" } } }   # d4: stuck 'stop' rows
    $pick = $null; $best = [int64]::MaxValue
    if ($q) { foreach ($p in $q.PSObject.Properties) { $r = $p.Value
      if ($r.st -ne 'wait' -or [int64]$r.notBefore -gt $now -or ([string]$r.phone).Length -lt 10) { continue }
      if ([int64]$r.at -lt $best) { $best = [int64]$r.at; $pick = $p.Name } } }
    if (-not $pick) { $script:status = 'OK Ready - no calls waiting'; Start-Sleep -Seconds 5; continue }
    $row = $q.$pick; $num = ([string]$row.phone) -replace '\D', ''
    Db 'PATCH' "$ROOT/queue/$pick" @{ st = 'dial'; dialAt = $now; dev = 'laptop' }
    $mine = $pick; $mineAt = $now; $script:status = "CALL Phone Link dialling $($row.name)"
    Log "CALL $($row.name) ($num) - opening Phone Link"
    Start-Process "tel:$num"
    $c = ClickCall
    if ($c) { Log "CALL $c" } else {
      Log "! no call started (see the line above). Buttons seen: $($script:lastButtons)"
      Db 'PATCH' "$ROOT/queue/$pick" @{ st = 'wait'; notBefore = $now + 300000; res = 'fail' }; $mine = $null
    }
    Beat
  } catch { Log "! $($_.Exception.Message)"; Start-Sleep -Seconds 10 }
}
