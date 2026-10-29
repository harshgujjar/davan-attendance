# Davan Dialer - the laptop half that DIALS the parent calls (29-Oct-2026, user: "go build it").  ASCII only (PowerShell 5.1).
# Proven 29-Oct: only calls that Phone Link itself starts carry the laptop's voice. So this helper takes the next queued call
# (DB4 hostel/parent_calls/queue, st 'wait'), opens tel:<number> (Phone Link) and clicks Phone Link's "Call" button with Windows
# UI Automation. The Davan Caller phone (c6) follows that call: answer -> st 'talk' (caller-voice.html speaks) -> 'spoken' -> hang up -> log.
# Started by davan-dialer.cmd (which downloads the newest copy of this file first). Heartbeat: hostel/parent_calls/dialer, log: logs/dialer.
$VER = 'd11'
$KEY = 'AIzaSyDBfwaUiCP_5tLPgCV2yZSeeWRnwnvnkDQ'
$DB = 'https://davan-lessonplan-archive-default-rtdb.asia-southeast1.firebasedatabase.app'
$ROOT = 'hostel/parent_calls'
$DIR = Join-Path $env:LOCALAPPDATA 'DavanDialer'
New-Item -ItemType Directory -Force -Path $DIR | Out-Null
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Windows.Forms
# d3: real mouse click + bring the window to the front (Phone Link ignored the UI Automation "Invoke" - log 29-Oct 08:34, no call started)
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class DvWin {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
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
      # d6 (log 29-Oct 09:00: a hidden plain "Call" button was taken and nothing else tried): candidates = visible, enabled buttons named
      # "Call ..." (never the "Calls" tab), the "Call Dialed number ..." one first; each one is tried until a call starts
      $cands = @($btns | Where-Object { $nm = [string]$_.Current.Name; ($nm -match '^\s*(Call|Dial|Call now)\s*$' -or $nm -match '^Call\s') -and -not $_.Current.IsOffscreen -and $_.Current.IsEnabled -and -not [double]::IsNaN($_.Current.BoundingRectangle.X) } |
        Sort-Object { if ([string]$_.Current.Name -match 'Dialed number') { 0 } else { 1 } })
      foreach ($b in $cands) {
        $n = [string]$b.Current.Name
        if ($true) {
          $how = @()
          try { $h = [IntPtr]$w.Current.NativeWindowHandle; if ($h -ne [IntPtr]::Zero) { [void][DvWin]::ShowWindow($h, 9); [void][DvWin]::SetForegroundWindow($h) } } catch { }
          Start-Sleep -Milliseconds 500
          try { $b.SetFocus(); Start-Sleep -Milliseconds 300; [System.Windows.Forms.SendKeys]::SendWait('{ENTER}'); $how += 'focus+Enter' } catch { $how += "Enter failed: $($_.Exception.Message)" }
          if (InCall $w 4) { return "call started after '$n' ($($how -join ', '))" }
          try { $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke(); $how += 'invoke' } catch { $how += 'invoke failed' }
          if (InCall $w 4) { return "call started after '$n' ($($how -join ', '))" }
          try {
            $r = $b.Current.BoundingRectangle
            [DvWin]::Click([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2)); $how += "mouse click at $([int]($r.X + $r.Width / 2)),$([int]($r.Y + $r.Height / 2))"
          } catch { $how += "mouse click failed: $($_.Exception.Message)" }
          if (InCall $w 6) { return "call started after '$n' ($($how -join ', '))" }
          Log "! pressed '$n' ($($how -join ', ')) but no call started - trying the next button"
        }
      }
      if ($cands.Count -gt 0) { $script:lastButtons = ((AllButtons $w) -join ' | '); return $null }   # one round only - never press Call again and again
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
# d7 (logs 29-Oct 09:04-09:13: when the phone app follows the call the audio jumps to the earpiece; when the phone is passive it stays on
# the laptop): the dialer itself sees the answer (Phone Link shows a call timer 0:05 / 00:05) and ends the call with Phone Link's End button
function PlWindows {
  $pids = @(Get-Process -Name 'PhoneExperienceHost', 'PhoneLink', 'YourPhone' -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
  $wins = [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
  return @($wins | Where-Object { ($pids -contains $_.Current.ProcessId) -or ($_.Current.Name -like '*Phone Link*') })
}
function PlTexts {
  $tc = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Text)
  $out = @(); foreach ($w in PlWindows) { try { $out += @($w.FindAll([System.Windows.Automation.TreeScope]::Descendants, $tc) | ForEach-Object { [string]$_.Current.Name } | Where-Object { $_ }) } catch { } }
  return $out
}
# d9 (log 29-Oct 10:52: an old "00:55" from the previous call was taken as the answer): answered = a FRESH timer 0:01 - 0:10
function Timers { return @(PlTexts | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d{1,2}:\d{2}(:\d{2})?$' }) }
function Secs($t) { $p = $t.Split(':'); $n = 0; foreach ($x in $p) { $n = $n * 60 + [int]$x }; return $n }
function Answered { foreach ($t in Timers) { $n = Secs $t; if ($n -ge 1 -and $n -le 10) { return $t } }; return $null }
# a call is running while Phone Link shows a timer or an End button
function Running { if ((Timers).Count -gt 0) { return $true }; return (CallOpen) }
function CallOpen { foreach ($w in PlWindows) { foreach ($n in (AllButtons $w)) { if ($n -match '^(End|End call|Hang up|Hang Up)\b') { return $true } } }; return $false }
function EndCall {
  $bc = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
  foreach ($w in PlWindows) { foreach ($b in @($w.FindAll([System.Windows.Automation.TreeScope]::Descendants, $bc))) {
    if ([string]$b.Current.Name -match '^(End|End call|Hang up|Hang Up)\b' -and -not $b.Current.IsOffscreen) {
      try { $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke() } catch { }
      Start-Sleep -Milliseconds 800
      if (CallOpen) { try { $r = $b.Current.BoundingRectangle; [DvWin]::Click([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2)) } catch { } }
      return $true } } }
  return $false
}
# result of a call this laptop placed: queue row done / retry + month log (same shape as the phone app wrote)
function Finish($id, $row, $res, $dur) {
  $now = Now; $att = [int]$row.attempts + 1; $tries = if ($cfg.tries) { [int]$cfg.tries } else { 2 }
  $again = ($res -ne 'ans' -and $res -ne 'stop' -and $att -lt $tries)
  if ($again) { Db 'PATCH' "$ROOT/queue/$id" @{ st = 'wait'; attempts = $att; res = $res; notBefore = $now + 1800000 } }
  else {
    Db 'PATCH' "$ROOT/queue/$id" @{ st = 'done'; attempts = $att; res = $res; doneAt = $now; dur = $dur }
    $e = @{ urn = $row.urn; name = $row.name; phone = $row.phone; pct = $row.pct; by = 'Auto call'; at = $now; how = 'auto'; res = $res; dur = $dur }
    foreach ($k in 'said', 'of', 'cable') { if ($null -ne $row.$k) { $e[$k] = $row.$k } }   # d10: how much of the message the parent heard (voice page v3.9)
    Db 'PUT' ("$ROOT/log/" + (Get-Date -Format 'yyyy-MM') + "/$id") $e
  }
  Log ("OK " + $row.name + ": " + $res + $(if ($dur) { " ($dur s)" } else { '' }) + $(if ($again) { ' - will try again in 30 min' } else { '' }))
}
function Beat {
  try {
    Db 'PUT' "$ROOT/dialer" @{ seen = (Now); ver = $VER; status = $script:status; pc = $env:COMPUTERNAME }
    $t = ("Davan Dialer $VER - $env:COMPUTERNAME`nStatus: " + $script:status + "`n" + ($script:log -join "`n"))
    if ($t -ne $script:logUp) { Db 'PUT' "$ROOT/logs/dialer" @{ at = (Now); ver = $VER; text = $t }; $script:logUp = $t }
  } catch { Write-Host "heartbeat: $($_.Exception.Message)" }
}

try { [void][DvWin]::SetProcessDPIAware() } catch { }   # d5: mouse coordinates = UI Automation's real pixels on scaled screens
Log "> Davan Dialer $VER started"
$cfg = $null; $cfgAt = 0; $lastBeat = 0; $mine = $null; $mineAt = 0; $verAt = 0; $stopAt = $null; $gone = 0
while ($true) {
  try {
    $now = Now
    if ($now - $lastBeat -gt 30000) { $lastBeat = $now; Beat }
    if ($now - $verAt -gt 3600000) {   # newer copy published -> exit; davan-dialer.cmd downloads it and starts again
      $verAt = $now
      try { $v = Invoke-RestMethod -Uri ('https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/caller-version.json?t=' + $now); if ($v.dialer -and $v.dialer -ne $VER) { Log "^ new dialer $($v.dialer) - restarting"; Beat; exit 0 } } catch { }
    }
    if ($now - $cfgAt -gt 120000 -or -not $cfg) { $cfg = Db 'GET' "$ROOT/cfg"; if (-not $cfg) { $cfg = [pscustomobject]@{} }; $cfgAt = $now }
    if ($mine) {   # d7: a call this laptop placed - the dialer watches it (answer, message done, stop, ring timeout) and ends it
      $row = Db 'GET' "$ROOT/queue/$mine"; $st = if ($row) { $row.st } else { $null }
      $open = Running
      if ($open) { $gone = 0 } else { $gone++ }
      if (-not $row) { if ($open) { [void](EndCall) }; Log "OK call removed from the queue"; $mine = $null; continue }
      if ($st -eq 'stop') { [void](EndCall); Finish $mine $row 'stop' 0; $mine = $null; Start-Sleep -Seconds 4; continue }
      if ($st -eq 'dial') {
        $ans = Answered
        if ($ans) { $ansAt = $now; Db 'PATCH' "$ROOT/queue/$mine" @{ st = 'talk'; ansAt = $now; via = 'phonelink' }; Log "CALL answered (Phone Link shows $ans) - laptop speaks"; Start-Sleep -Milliseconds 500; continue }
        # d8 (log 29-Oct 09:53: "ended before answered" 2 s after dialling - while it RINGS Phone Link has no End button yet): only the answer
        # or the ring timeout decide
        $ring = if ($cfg.ringSec) { [int]$cfg.ringSec } else { 45 }
        if ($now - $mineAt -gt ($ring + 8) * 1000) { [void](EndCall); Finish $mine $row 'nr' 0; Log "! no answer in $ring s"; $mine = $null; Start-Sleep -Seconds 6; continue }
        Start-Sleep -Milliseconds 700; continue
      }
      if ($st -eq 'talk' -or $st -eq 'spoken') {
        $dur = [int](($now - [int64]$row.ansAt) / 1000)
        if ($st -eq 'spoken') { [void](EndCall); Finish $mine $row 'ans' $dur; $mine = $null; Start-Sleep -Seconds 8; continue }
        if ($gone -ge 4) { Finish $mine $row 'ans' $dur; Log "OK the parent hung up"; $mine = $null; Start-Sleep -Seconds 6; continue }   # d9: 4 checks in a row without timer / End
        if ($dur -gt 180) { [void](EndCall); Finish $mine $row 'ans' $dur; $mine = $null; continue }
        Start-Sleep -Milliseconds 800; continue
      }
      Log "OK call finished ($st)"; $mine = $null; Start-Sleep -Seconds 4; continue
    }
    # d11: a call pressed by hand (staff app Call, row.now) dials at once - also when paused or outside the hours
    $q = Db 'GET' "$ROOT/queue"; $hasNow = $false
    if ($q) { foreach ($p in $q.PSObject.Properties) { if ($p.Value.st -eq 'wait' -and $p.Value.now) { $hasNow = $true } } }
    if ($cfg.paused -and -not $hasNow) { $script:status = '|| Paused'; Start-Sleep -Seconds 5; continue }
    if (-not $hasNow -and -not (InHours $cfg)) { $script:status = "night: outside calling hours ($($cfg.hours))"; Start-Sleep -Seconds 30; continue }
    $relay = Db 'GET' "$ROOT/relay"; $phone = Db 'GET' "$ROOT/caller"
    if (-not $relay -or $now - [int64]$relay.seen -gt 90000) { $script:status = 'laptop: voice page offline - open caller-voice.html in Edge'; Start-Sleep -Seconds 10; continue }
    if ($q) { foreach ($p in $q.PSObject.Properties) { if ($p.Value.st -eq 'stop' -and $now - [int64]$p.Value.dialAt -gt 120000) { Db 'PATCH' "$ROOT/queue/$($p.Name)" @{ st = 'done'; res = 'stop'; doneAt = $now }; Log "OK old stop finished: $($p.Value.name)" } } }   # d4: stuck 'stop' rows
    $pick = $null; $best = [int64]::MaxValue
    if ($q) { foreach ($p in $q.PSObject.Properties) { $r = $p.Value
      if ($r.st -ne 'wait' -or [int64]$r.notBefore -gt $now -or ([string]$r.phone).Length -lt 10 -or ($hasNow -and -not $r.now)) { continue }
      if ([int64]$r.at -lt $best) { $best = [int64]$r.at; $pick = $p.Name } } }
    if (-not $pick) { $script:status = 'OK Ready - no calls waiting'; Start-Sleep -Seconds 5; continue }
    $row = $q.$pick; $num = ([string]$row.phone) -replace '\D', ''
    Db 'PATCH' "$ROOT/queue/$pick" @{ st = 'dial'; dialAt = $now; dev = 'laptop' }
    $mine = $pick; $mineAt = $now; $gone = 0; $script:status = "CALL Phone Link dialling $($row.name)"
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
