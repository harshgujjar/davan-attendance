# PC Doctor (tray window) - tray.ps1 (ROADMAP-pcdoctor.md 8). Runs for every user (HKLM Run). Closing the window never stops the
# PC Doctor Agent (that is the SYSTEM service). Reads the agent's state files, sends requests through req\ (the agent does the work).
# Password 2531 (hashed in lab/cfg/trayPw, changeable on the Console) to OPEN the window (and Copy report). Laptop = Super Admin mode: all-PCs grid + popups.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
# 1.6 (user, 05-Nov-2026: "on my laptop the tray text looks very low resolution"): without this Windows draws the window at 96 dpi and
# stretches it on a 125-200% screen (blurry). DPI-aware + every form scales its own layout (Sharp) = sharp text at any scaling.
try { Add-Type -Namespace PDT -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -ErrorAction Stop; [void][PDT.Dpi]::SetProcessDPIAware() } catch {}
[Windows.Forms.Application]::EnableVisualStyles()
# 1.8 (user, 05-Nov-2026: "the tray items are small and the window is big, not aligned"): Windows' AutoScale grew only the window, not
# its buttons / bars. Now every form is scaled by hand ONCE, after all its controls are in (Sharp), by the real screen DPI.
$DPIK = try { $g0 = [Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $d = $g0.DpiX / 96; $g0.Dispose(); [math]::Max(1, [math]::Min(3, $d)) } catch { 1 }
function Sharp($f) { $f.AutoScaleMode = [Windows.Forms.AutoScaleMode]::None; if ($DPIK -gt 1.01) { $f.Scale((New-Object Drawing.SizeF($DPIK, $DPIK))) } }
$Root = "$env:ProgramData\DavanPCDoctor"; $St = "$Root\state"; $Rq = "$Root\req"
$mtx = New-Object Threading.Mutex($false, 'Local\DavanPCDoctorTray'); if (!$mtx.WaitOne(0)) { exit 0 }
function J($f) { $p = "$St\$f"; if (!(Test-Path $p)) { return $null }; try { Get-Content $p -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json } catch { $null } }   # 1.12: a missing file = quiet null (no red errors)
function W($f, $o) { try { [IO.File]::WriteAllText("$Rq\$f", ($o | ConvertTo-Json -Depth 6 -Compress), (New-Object Text.UTF8Encoding($false))) } catch {} }
function IST($ms) { if (!$ms) { return '-' }; ([DateTimeOffset]::FromUnixTimeMilliseconds([int64]$ms)).ToOffset([TimeSpan]::FromHours(5.5)).ToString('dd MMM, h:mm tt') + ' IST' }
function Hash($s) { -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('davanlab:' + $s)) | ForEach-Object { $_.ToString('x2') }) }
$CL = @{ bg = [Drawing.Color]::FromArgb(11,13,17); card = [Drawing.Color]::FromArgb(20,23,30); bd = [Drawing.Color]::FromArgb(38,43,54); tx = [Drawing.Color]::FromArgb(230,232,238)
        mu = [Drawing.Color]::FromArgb(140,147,163); ac = [Drawing.Color]::FromArgb(240,165,0); ok = [Drawing.Color]::FromArgb(52,211,153); wa = [Drawing.Color]::FromArgb(251,146,60)
        er = [Drawing.Color]::FromArgb(248,113,113); ye = [Drawing.Color]::FromArgb(250,204,21); pu = [Drawing.Color]::FromArgb(167,139,250); off = [Drawing.Color]::FromArgb(75,85,99) }
$LVL = @{ green = @('●', $CL.ok); yellow = @('●', $CL.ye); orange = @('●', $CL.wa); red = @('●', $CL.er); purple = @('●', $CL.pu); off = @('○', $CL.off) }
$FT = @{ big = New-Object Drawing.Font('Segoe UI Semibold', 13); n = New-Object Drawing.Font('Segoe UI', 9.5); s = New-Object Drawing.Font('Segoe UI', 8.5); m = New-Object Drawing.Font('Consolas', 9); e = New-Object Drawing.Font('Segoe UI Emoji', 10) }
function PwText([string]$why) { $script:lastPw = $null; if (Pw $why) { return $script:lastPw }; return $null }
function Pw([string]$why) {
  $f = New-Object Windows.Forms.Form -Property @{ Text = 'PC Doctor'; Width = 300; Height = 150; StartPosition = 'CenterScreen'; ShowInTaskbar = $true; BackColor = $CL.bg; ForeColor = $CL.tx; FormBorderStyle = 'FixedDialog'; MaximizeBox = $false; MinimizeBox = $false; TopMost = $true }
  $l = New-Object Windows.Forms.Label -Property @{ Text = "Password for $why"; Left = 14; Top = 12; Width = 260; Font = $FT.n }
  $t = New-Object Windows.Forms.TextBox -Property @{ Left = 14; Top = 40; Width = 255; UseSystemPasswordChar = $true; Font = $FT.n }
  $b = New-Object Windows.Forms.Button -Property @{ Text = 'OK'; Left = 194; Top = 72; Width = 75; DialogResult = 'OK'; FlatStyle = 'Flat'; BackColor = $CL.ac; ForeColor = [Drawing.Color]::Black }
  $sh = New-Object Windows.Forms.CheckBox -Property @{ Text = 'Show'; Left = 14; Top = 74; Width = 120; Font = $FT.s; ForeColor = $CL.tx }   # 1.7 (user, 05-Nov-2026)
  $sh.Add_CheckedChanged({ $t.UseSystemPasswordChar = !$sh.Checked })
  $f.Controls.AddRange(@($l, $t, $b, $sh)); $f.AcceptButton = $b; Sharp $f
  if ($f.ShowDialog() -ne 'OK') { return $false }
  $cfg = J 'cfg.json'; $want = if ($cfg -and $cfg.trayPw) { [string]$cfg.trayPw } else { Hash '2531' }
  if ((Hash $t.Text) -eq $want) { $script:lastPw = $t.Text; return $true }
  [Windows.Forms.MessageBox]::Show('Wrong password.', 'PC Doctor') | Out-Null; $false
}
# ---------- the window ----------
$form = New-Object Windows.Forms.Form -Property @{ Text = 'PC Doctor - ' + $env:COMPUTERNAME; Width = 460; Height = 608; BackColor = $CL.bg; ForeColor = $CL.tx; StartPosition = 'Manual'; FormBorderStyle = 'FixedSingle'; MaximizeBox = $false; ShowInTaskbar = $true }
function Corner { $wa = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea; $form.Left = $wa.Right - $form.Width - 12; $form.Top = [math]::Max($wa.Top, $wa.Bottom - $form.Height - 12) }
Corner; $form.Add_Shown({ Corner })   # after the DPI scaling the window is bigger - keep it in the corner, fully on screen
$tabs = New-Object Windows.Forms.TabControl -Property @{ Dock = 'Fill'; Font = $FT.n }
$tMe = New-Object Windows.Forms.TabPage -Property @{ Text = 'This PC'; BackColor = $CL.bg }
$tabs.TabPages.Add($tMe); $form.Controls.Add($tabs)
# ---------- ⬆️ Updates tab (user, 04-Nov-2026): Update now + this PC's version, when it came, what's new (5 newest, Show all / Hide) ----------
$tUp = New-Object Windows.Forms.TabPage -Property @{ Text = '⬆ Updates'; BackColor = $CL.bg }; $tabs.TabPages.Add($tUp)
$uVer = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 10; Width = 420; Height = 26; Font = $FT.big; ForeColor = $CL.ac; Text = 'PC Doctor' }
$uWhen = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 40; Width = 420; Height = 40; Font = $FT.s; ForeColor = $CL.mu }
$uBar = New-Object Windows.Forms.ProgressBar -Property @{ Left = 12; Top = 122; Width = 420; Height = 14; Maximum = 100; Style = 'Continuous'; Visible = $false }
$uRes = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 140; Width = 420; Height = 38; Font = $FT.s; ForeColor = $CL.ac }
$uBtn = New-Object Windows.Forms.Button -Property @{ Text = '⬆ Update now'; Left = 12; Top = 84; Width = 200; Height = 32; FlatStyle = 'Flat'; BackColor = $CL.ac; ForeColor = [Drawing.Color]::Black; Font = $FT.n }
$uNewT = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 184; Width = 260; Height = 22; Font = $FT.n; Text = "What's new" }
$uAll = New-Object Windows.Forms.Button -Property @{ Text = 'Show all ▾'; Left = 312; Top = 180; Width = 120; Height = 26; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
$uNews = New-Object Windows.Forms.TextBox -Property @{ Left = 12; Top = 210; Width = 420; Height = 338; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None' }
$uBtn.FlatAppearance.BorderColor = $CL.ac; $uAll.FlatAppearance.BorderColor = $CL.bd
$tUp.Controls.AddRange(@($uVer, $uWhen, $uBtn, $uBar, $uRes, $uNewT, $uAll, $uNews))
$script:showAll = $false; $script:askedAt = 0
# 1.14 (user, 05-Nov-2026: "when downloading a new update show the progress in the tray so I know what is happening"): the updater
# (loader) writes every step to state\updp.json; while an update runs the tray reads it every second: bar + step + file, the tray
# icon's text, This PC's message line, and a notification when it starts by itself and when the new version is running
$script:upKey = ''
function UpdProgress {
  $pp = J 'updp.json'; $u = J 'upd.json'; $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $fresh = $pp -and ($now - [int64]$pp.t) -lt 300000 -and (!$script:askedAt -or [int64]$pp.t -ge $script:askedAt - 2000)
  $ended = $fresh -and $pp.ph -ne 'restart' -and $u -and [int64]$u.at -ge [int64]$pp.t
  $to = if ($pp -and $pp.to) { [string]$pp.to } else { '' }
  if (!$fresh -or $ended) {
    if ($script:askedAt -and !$fresh) { $uBar.Visible = $true; $uBar.Value = 5; return }   # asked; the updater has not started yet
    $uBar.Visible = $false; $tp.Stop(); return }
  $hb = 0; try { $hb = [int64](J 'hb.txt') } catch {}
  switch ([string]$pp.ph) {
    'check'    { $pc = 10; $tx = 'Step 2/5 · Looking for a new version ...' }
    'download' { $pc = 10 + [int](70 * $pp.i / [math]::Max(1, $pp.n)); $tx = "Step 3/5 · Downloading $to - file $($pp.i) of $($pp.n): $($pp.file)" }
    'install'  { $pc = 85; $tx = "Step 4/5 · Installing $to (checked: every file matches its fingerprint) ..." }
    'restart'  { if ($hb -gt [int64]$pp.t) { $pc = 100; $tx = "Done - PC Doctor $to is running." } else { $pc = 95; $tx = "Step 5/5 · Starting PC Doctor $to - about a minute ..." } }
    default    { $pc = 5; $tx = 'Updating ...' }
  }
  $uBar.Visible = $true; $uBar.Value = [math]::Min(100, [math]::Max(0, $pc)); $uRes.Text = $(if ($pc -ge 100) { '✅ ' } else { '⏳ ' }) + $tx
  $msg.Text = 'Update: ' + $tx; $t2 = "PC Doctor - updating $pc%"; if ($pc -ge 100) { $t2 = "PC Doctor $to" }; $ni.Text = $t2.Substring(0, [math]::Min(63, $t2.Length))
  $k = [string]$pp.t; if ($pp.ph -eq 'download' -and $script:upKey -ne ('s' + $to) -and !$script:askedAt -and $pc -lt 100) { $script:upKey = 's' + $to; $ni.ShowBalloonTip(5000, 'PC Doctor', "Updating to $to - open the tray to see the progress.", 'Info') }
  if ($pc -ge 100) { $uBtn.Enabled = $true; $script:askedAt = 0; if ($script:upKey -ne ('d' + $to)) { $script:upKey = 'd' + $to; $ni.ShowBalloonTip(5000, 'PC Doctor', "Updated - PC Doctor $to is running.", 'Info') }; $tp.Stop() }
}
$tp = New-Object Windows.Forms.Timer -Property @{ Interval = 1000 }; $tp.Add_Tick({ try { UpdProgress } catch {} })
function UpdNow { try { Set-Content "$Rq\update.flag" '1' } catch { $uRes.Text = '❌ Could not ask the updater: ' + $_.Exception.Message; return }
  $script:askedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $uRes.Text = '⏳ Step 1/5 · Asked the updater - it starts within a few seconds ...'; $uBtn.Enabled = $false; $uBar.Visible = $true; $uBar.Value = 5; $tp.Start() }
$uBtn.Add_Click({ UpdNow })
$uAll.Add_Click({ $script:showAll = !$script:showAll; UpdRefresh })
function UpdRefresh {
  $r = J 'running.json'; $lv = J 'labver.json'; $u = J 'upd.json'
  $form.Text = 'PC Doctor' + $(if ($r -and $r.ver) { ' v' + $r.ver } else { '' }) + ' - ' + $env:COMPUTERNAME   # 1.15 (user, 05-Nov-2026): version always in the title
  $uVer.Text = if ($r) { 'PC Doctor ' + $r.ver + '  ·  build ' + $r.build } else { 'PC Doctor (first start)' }
  $newest = if ($lv -and $lv.agent) { [string]$lv.agent.ver + ' (build ' + $lv.agent.build + ', ' + $lv.agent.ist + ')' } else { '' }
  $uWhen.Text = $(if ($r -and $r.at) { 'This version came on ' + (IST $r.at) + ' IST' } else { '' }) + $(if ($newest) { "`r`nNewest published: " + $newest } else { '' })
  if ($u -and $u.res) {
    $fresh = $script:askedAt -and [int64]$u.at -ge $script:askedAt
    if (!$script:askedAt -or $fresh) { $uRes.Text = $(if ($fresh) { '✅ ' } else { 'Last check ' + (IST $u.at) + ': ' }) + $u.res; $uBtn.Enabled = $true; if ($fresh) { $script:askedAt = 0 } }
  } elseif (!$script:askedAt) { $uRes.Text = 'Checks by itself at every start and every hour.' }
  if ($script:askedAt -and ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $script:askedAt) -gt 180000) { $uRes.Text = '⌛ No answer yet - the updater runs again within the hour (or restart the PC).'; $uBtn.Enabled = $true; $script:askedAt = 0 }
  $news = @(); if ($lv -and $lv.news) { $news = @($lv.news) }
  if (!$news.Count) { $uNews.Text = "The list appears after the next update check (tap Update now)."; $uAll.Visible = $false; return }
  $show = if ($script:showAll) { $news } else { $news | Select-Object -First 5 }
  $uNews.Text = ($show | ForEach-Object { '1.' + $_.build + '  ·  ' + ([string]$_.ist -replace ' IST$', '') + "`r`n   " + $_.text + "`r`n" }) -join "`r`n"
  $uAll.Visible = $news.Count -gt 5; $uAll.Text = if ($script:showAll) { 'Hide ▴' } else { 'Show all (' + $news.Count + ') ▾' }
}
$head = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 10; Width = 420; Height = 26; Font = $FT.big; ForeColor = $CL.ac; Text = 'PC Doctor' }
$verd = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 40; Width = 420; Height = 62; Font = $FT.n }
$tMe.Controls.AddRange(@($head, $verd))
$bars = @{}; $y = 106
foreach ($k in @(@('cpu','CPU'), @('ram','RAM'), @('busy','Disk busy'), @('cfree','C: free'))) {
  $l = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $y; Width = 90; Text = $k[1]; Font = $FT.s; ForeColor = $CL.mu }
  $p = New-Object Windows.Forms.ProgressBar -Property @{ Left = 104; Top = $y; Width = 250; Height = 14; Maximum = 100; Style = 'Continuous' }
  $v = New-Object Windows.Forms.Label -Property @{ Left = 360; Top = $y - 2; Width = 70; Font = $FT.m }
  $tMe.Controls.AddRange(@($l, $p, $v)); $bars[$k[0]] = @($p, $v); $y += 24 }
$info = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $y + 4; Width = 420; Height = 110; Font = $FT.s; ForeColor = $CL.mu }
$week = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $y + 116; Width = 420; Height = 60; Font = $FT.s }
$tMe.Controls.AddRange(@($info, $week))
function Btn($t, $x, $yy, $w, $on) { $b = New-Object Windows.Forms.Button -Property @{ Text = $t; Left = $x; Top = $yy; Width = $w; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $b.FlatAppearance.BorderColor = $CL.bd; $b.Add_Click($on); $tMe.Controls.Add($b); $b }
$by = $y + 184   # 1.8: buttons right under the 7-day line (no big empty gap)
$msg = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $by + 144; Width = 420; Height = 36; Font = $FT.s; ForeColor = $CL.ac }; $tMe.Controls.Add($msg)
function Report {
  $n = J 'now.json'; $v = J 'verdict.json'; $p = J 'pc.json'
  "PC Doctor report - $env:COMPUTERNAME ($(IST ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())))`r`n" +
  "Verdict: $($v.v) ($($v.conf)% sure) - $($v.why)`r`n" + "Group: $($p.grp)  Place: $($p.place)  Notes: $($p.notes)`r`n" +
  "CPU $($n.cpu)%  RAM $($n.ram)%  Disk busy $($n.busy)%  latency $($n.lat) ms  C: free $($n.cfree)% ($($n.cfreeGB) GB)  Temp $($n.temp) °C`r`n" +
  "Deep Freeze: $($n.df)  Internet: $(if ($n.online) { 'yes' } else { 'no' })  Not sent yet: $($n.q)  Agent: $($n.ver)`r`n" +
  "Using RAM: " + ((@($n.rtop) | ForEach-Object { "$($_.n) $($_.m) MB" }) -join ', ') + "`r`n" +
  "Top programs: " + ((@($n.top) | ForEach-Object { "$($_.n) $($_.c)% $($_.m) MB" }) -join ', ') + "`r`n" +
  "Other findings: " + ((@($v.all) | Select-Object -Skip 1 | ForEach-Object { $_.v }) -join ', ')
}
Btn 'Send report now' 12 $by 136 { Set-Content "$Rq\now.flag" '1'; $msg.Text = 'Asked - the full report goes to the Console in about a minute.' } | Out-Null
Btn 'Check now' 152 $by 136 { Set-Content "$Rq\now.flag" '1'; $msg.Text = 'Checking - the verdict updates in about a minute.' } | Out-Null
Btn 'Copy' 292 $by 140 { [Windows.Forms.Clipboard]::SetText((Report)); $msg.Text = 'Report copied - paste it in WhatsApp / chat.' } | Out-Null
Btn 'Save report to pendrive' 12 ($by + 36) 200 { Set-Content "$Rq\usb.flag" '1'; $msg.Text = 'Saving to the pendrive ...' } | Out-Null
Btn 'Fix from pendrive' 216 ($by + 36) 216 { if ($script:unlocked -or (Pw 'Fix from pendrive')) { Set-Content "$Rq\usbfix.flag" '1'; $msg.Text = 'Running the approved fixes from the pendrive ...' } } | Out-Null
Btn '🖥 Open Console' 12 ($by + 108) 420 { OpenConsole } | Out-Null
Btn '⚙ Name / group / notes' 12 ($by + 72) 316 { if ($script:unlocked -or (Pw 'changing this PC')) { Edit } } | Out-Null
# 1.11 (user, 05-Nov-2026): Uninstall with the password - shows exactly what is removed, the agent (SYSTEM) does it and checks the password again
Btn 'Uninstall' 332 ($by + 72) 100 { Uninstall } | Out-Null
# 1.16 (user, 05-Nov-2026: "Open Console button on every tray"): opens the Console (lab.html) in the browser - on every PC. The tray password
# is asked first (unless the window is already unlocked) and the Console has its OWN login + lock-out, so a student gets nowhere.
# The address is data: DB5 lab/cfg consoleUrl (fallback below), so a moved site needs no new build.
function OpenConsole {
  if (!($script:unlocked -or (Pw 'opening the Console'))) { return }
  $cfg = J 'cfg.json'; $u = if ($cfg -and $cfg.consoleUrl) { [string]$cfg.consoleUrl } else { 'https://harshgujjar.github.io/davan-attendance/lab.html' }
  try { Start-Process $u; $msg.Text = 'Console opened in your browser - it asks for the Console password.' } catch { $msg.Text = 'Could not open the browser: ' + $_.Exception.Message + ' - address: ' + $u }
}
function Uninstall {
  $n = J 'now.json'
  if ($n -and $n.df -eq 'frozen') { [Windows.Forms.MessageBox]::Show("This PC is Frozen (Deep Freeze).`r`nBoot Thawed first, then uninstall - otherwise PC Doctor comes back at the restart.", 'PC Doctor') | Out-Null; return }
  $pw = PwText 'uninstalling PC Doctor'; if ($null -eq $pw) { return }
  $mesh = [Windows.Forms.MessageBox]::Show("Also remove the remote-screen agent (MeshCentral)?`r`n`r`nYes = remove it too    No = keep it", 'PC Doctor - uninstall', 'YesNoCancel', 'Question')
  if ($mesh -eq 'Cancel') { return }
  $ok = [Windows.Forms.MessageBox]::Show("Uninstall PC Doctor from " + $env:COMPUTERNAME + "?`r`n`r`nThis removes:`r`n - the PC Doctor Agent service and its boot task`r`n - this tray app (for every user)`r`n - the folder " + $Root + " (settings, reports not yet sent)" + $(if ($mesh -eq 'Yes') { "`r`n - the remote-screen agent (MeshCentral)" } else { '' }) + "`r`n`r`nThe PC moves to Old PCs on the Console - its history is kept there. Running PCDoctor-Setup.cmd again brings it back.", 'PC Doctor - uninstall', 'YesNo', 'Warning')
  if ($ok -ne 'Yes') { return }
  W 'uninstall.json' @{ pw = $pw; mesh = ($mesh -eq 'Yes'); who = $env:USERNAME; t = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
  $script:unAsked = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $msg.Text = 'Uninstall asked - checking the password (about a minute) ...'
}
function Edit {
  $p = J 'pc.json'; $cfg = J 'cfg.json'
  $f = New-Object Windows.Forms.Form -Property @{ Text = '⚙ This PC'; Width = 360; Height = 330; BackColor = $CL.bg; ForeColor = $CL.tx; StartPosition = 'CenterScreen'; FormBorderStyle = 'FixedDialog'; TopMost = $true }
  $fields = @(@('name','Name (= Windows name)'), @('grp','Group'), @('place','Place'), @('user','Usual user'), @('notes','Notes')); $box = @{}; $yy = 12
  foreach ($x in $fields) { $f.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = $x[1]; Left = 12; Top = $yy + 3; Width = 130; Font = $FT.s; ForeColor = $CL.mu }))
    if ($x[0] -eq 'grp') { $c = New-Object Windows.Forms.ComboBox -Property @{ Left = 146; Top = $yy; Width = 185; DropDownStyle = 'DropDownList' }
      if ($cfg -and $cfg.groups) { foreach ($g in $cfg.groups.PSObject.Properties) { [void]$c.Items.Add($g.Name + ' - ' + $g.Value.name) } }
      $c.SelectedIndex = [math]::Max(0, [array]::IndexOf(@($c.Items | ForEach-Object { ($_ -split ' - ')[0] }), [string]$p.grp)) }
    else { $c = New-Object Windows.Forms.TextBox -Property @{ Left = 146; Top = $yy; Width = 185; Text = [string]$p.($x[0]) } }
    $f.Controls.Add($c); $box[$x[0]] = $c; $yy += 32 }
  $dfb = New-Object Windows.Forms.CheckBox -Property @{ Text = 'Has Deep Freeze'; Left = 146; Top = $yy; Width = 185; Checked = [bool]($p.df -ne $false) }; $f.Controls.Add($dfb); $yy += 30
  $who = New-Object Windows.Forms.TextBox -Property @{ Left = 146; Top = $yy; Width = 185 }; $f.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = 'Your name'; Left = 12; Top = $yy + 3; Width = 130; Font = $FT.s; ForeColor = $CL.mu })); $f.Controls.Add($who); $yy += 36
  $ok = New-Object Windows.Forms.Button -Property @{ Text = 'Save'; Left = 256; Top = $yy; Width = 75; DialogResult = 'OK'; FlatStyle = 'Flat'; BackColor = $CL.ac; ForeColor = [Drawing.Color]::Black }; $f.Controls.Add($ok)
  Sharp $f
  if ($f.ShowDialog() -eq 'OK') {
    $e = @{ who = $(if ($who.Text) { $who.Text } else { $env:USERNAME }); name = $box.name.Text.Trim().ToUpper(); grp = ([string]$box.grp.SelectedItem -split ' - ')[0]; place = $box.place.Text; user = $box.user.Text; notes = $box.notes.Text; df = $dfb.Checked }
    W ('edit' + [DateTime]::UtcNow.Ticks + '.json') $e; $msg.Text = '✏ Saved - the Console shows the change (and who made it) within a minute.' }
}
# ---------- Super Admin laptop: all PCs grid + ✨ Ask AI ----------
$tGrid = $null; $grid = $null; $tAi = $null
function LaptopTabs {
  if ($tGrid) { return }
  $script:tGrid = New-Object Windows.Forms.TabPage -Property @{ Text = 'All PCs'; BackColor = $CL.bg }
  $script:grid = New-Object Windows.Forms.ListView -Property @{ Dock = 'Fill'; View = 'Details'; FullRowSelect = $true; BackColor = $CL.bg; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None' }
  foreach ($c in @(@('PC', 70), @('Group', 90), @('State', 230))) { [void]$grid.Columns.Add($c[0], $c[1]) }
  $tGrid.Controls.Add($grid); $tabs.TabPages.Add($tGrid)
  $script:tAi = New-Object Windows.Forms.TabPage -Property @{ Text = '✨ Ask AI'; BackColor = $CL.bg }
  $q = New-Object Windows.Forms.TextBox -Property @{ Left = 10; Top = 10; Width = 330; Font = $FT.n }
  $ans = New-Object Windows.Forms.TextBox -Property @{ Left = 10; Top = 46; Width = 422; Height = 470; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.n }
  $go = New-Object Windows.Forms.Button -Property @{ Text = 'Ask'; Left = 346; Top = 8; Width = 86; FlatStyle = 'Flat'; BackColor = $CL.ac; ForeColor = [Drawing.Color]::Black }
  # 1.9 (user, 05-Nov-2026: "I asked, it did not answer nor show anything"): the click ran after LaptopTabs ended, when its own
  # $q / $ans were gone - the boxes now live at script level (aiQ / aiBox) and AskAi does the work; Enter asks too
  $script:aiQ = $q; $script:aiBox = $ans; $go.Add_Click({ AskAi }); $q.Add_KeyDown({ if ($_.KeyCode -eq 'Enter') { $_.SuppressKeyPress = $true; AskAi } })
  $tAi.Controls.AddRange(@($q, $go, $ans)); foreach ($x in $q, $go, $ans) { $x.Scale((New-Object Drawing.SizeF($DPIK, $DPIK))) }; foreach ($x in $grid.Columns) { $x.Width = [int]($x.Width * $DPIK) }; $tabs.TabPages.Add($tAi)
}
function AskAi {
  $qq = [string]$script:aiQ.Text; if (!$qq.Trim()) { $script:aiBox.Text = 'Type a question first, then tap Ask.'; return }
  $g = J 'grid.json'; $ctx = ''
  if ($g -and $g.now) { $ctx = (@($g.now.PSObject.Properties) | ForEach-Object { $n = $_.Value; $pn = [string]$g.pcs.($_.Name).name; if (!$pn) { $pn = [string]$n.name }
      $pn + ' (Windows ' + [string]$n.name + '): ' + $n.lv + ' ' + $n.v + ', cpu ' + $n.cpu + '%, ram ' + $n.ram + '%, C free ' + $n.cfree + '%' }) -join "`n" }
  # this PC's own details: top programs + RAM, so "why is RAM 95%" can be answered
  $me = J 'now.json'; $iv = J 'inv.json'
  if ($me) { $ctx += "`n`nThis PC " + $env:COMPUTERNAME + ': cpu ' + $me.cpu + '%, ram ' + $me.ram + '%' + $(if ($iv -and $iv.ramGB) { ' of ' + $iv.ramGB + ' GB' } else { '' }) +
      ', RAM used by: ' + ((@($me.rtop) | ForEach-Object { [string]$_.n + ' ' + $_.m + ' MB' + $(if ($_.k -gt 1) { ' (' + $_.k + ' copies)' }) }) -join ', ') +
      ', top programs: ' + ((@($me.top) | ForEach-Object { [string]$_.n + ' ' + $_.c + '% cpu ' + $_.m + ' MB' }) -join ', ') }
  W 'ai.json' @{ prompt = ('Lab now:' + "`n" + $ctx.Substring(0, [math]::Min(3500, $ctx.Length)) + "`n`nQuestion: " + $qq); history = @() }
  $script:aiBox.Text = '✨ Asking ... (about 10-30 seconds)'; $script:aiAsked = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
}
# ---------- tray icon + refresh ----------
$ni = New-Object Windows.Forms.NotifyIcon -Property @{ Visible = $true; Text = 'PC Doctor' }
function Ico($col) { $b = New-Object Drawing.Bitmap 16, 16; $g = [Drawing.Graphics]::FromImage($b); $g.SmoothingMode = 'AntiAlias'
  $g.FillRectangle((New-Object Drawing.SolidBrush $CL.bg), 0, 0, 16, 16); $g.FillRectangle((New-Object Drawing.SolidBrush $CL.tx), 2, 3, 12, 8); $g.FillRectangle((New-Object Drawing.SolidBrush $CL.bg), 3, 4, 10, 6)
  $g.FillRectangle((New-Object Drawing.SolidBrush $CL.tx), 6, 12, 4, 2); $g.FillEllipse((New-Object Drawing.SolidBrush $col), 9, 8, 7, 7); $g.Dispose(); [Drawing.Icon]::FromHandle($b.GetHicon()) }
$ni.Icon = Ico $CL.ok
$menu = New-Object Windows.Forms.ContextMenuStrip
# 1.2 (user, 04-Nov-2026: "we planned a password to open it, but it opens without"): the window opens only with the password (2531,
# changeable on the Console); while it stays open ⚙️ / 🔧 don't ask again; hiding it locks it again
$script:unlocked = $false
function OpenWin { if ($form.Visible -and $script:unlocked) { $form.WindowState = 'Normal'; $form.Activate(); return }
  if (!$script:unlocked -and !(Pw 'opening PC Doctor')) { return }
  $script:unlocked = $true; $form.Show(); $form.WindowState = 'Normal'; $form.Activate() }
[void]$menu.Items.Add('Open PC Doctor', $null, { OpenWin })
[void]$menu.Items.Add('Check now', $null, { Set-Content "$Rq\now.flag" '1' })
[void]$menu.Items.Add('⬆ Update now', $null, { UpdNow; OpenWin; $tabs.SelectedTab = $tUp })
[void]$menu.Items.Add('Copy report', $null, { if ($script:unlocked -or (Pw 'copying the report')) { [Windows.Forms.Clipboard]::SetText((Report)) } })
$ni.ContextMenuStrip = $menu
$ni.Add_MouseClick({ if ($_.Button -eq 'Left') { OpenWin } })
$form.Add_FormClosing({ if ($_.CloseReason -eq 'UserClosing') { $_.Cancel = $true; $form.Hide(); $script:unlocked = $false } })   # closing never stops anything
$seen = @{}; $lastLv = ''
function Refresh {
  $n = J 'now.json'; $v = J 'verdict.json'
  if (!$n) { $head.Text = 'PC Doctor - starting'; $verd.Text = 'The PC Doctor Agent has not written its first check yet (about a minute after start).'; return }
  $lv = if ($v) { [string]$v.lv } else { 'green' }; $e = $LVL[$lv]; if (!$e) { $e = $LVL.green }
  $head.Text = $e[0] + ' ' + $env:COMPUTERNAME + ' - ' + $(if ($v) { $v.v } else { 'checking' }); $head.ForeColor = $e[1]
  $verd.Text = $(if ($v) { $v.why + "  (" + $v.conf + "% sure)" } else { '' })
  foreach ($k in 'cpu','ram','busy','cfree') { $x = [int]$n.$k; $bars[$k][0].Value = [math]::Max(0, [math]::Min(100, $x)); $bars[$k][1].Text = "$x%" }
  $tq = if ($n.thawQ) { "  ·  Thaw needed: $($n.thawQ) fix" + $(if ($n.thawQ -ne 1) { 'es' }) } else { '' }
  $info.Text = "CPU $(if ($n.temp) { [string]$n.temp + ' °C' } else { '-' })   ·   " + $(if ($n.df -eq 'thawed') { 'Thawed' } elseif ($n.df -eq 'frozen') { 'Frozen' } else { 'No Deep Freeze' }) + $tq + "`r`n" +
    $(if ($n.online) { 'Internet OK' } else { 'No internet - saved, sends later' }) + "   ·   Last sent $(IST $n.t)" + $(if ($n.q) { "   ·   $($n.q) waiting" } else { '' }) + "`r`n" +
    $(if (@($n.rtop).Count) { 'RAM used by: ' + ((@($n.rtop) | ForEach-Object { [string]$_.n + ' ' + $(if ($_.m -ge 1024) { [string][math]::Round($_.m / 1024, 1) + ' GB' } else { [string]$_.m + ' MB' }) }) -join ', ') + "`r`n" } else { '' }) +
    "C: $($n.cfreeGB) GB free   ·   disk answers in $($n.lat) ms   ·   Agent $($n.ver)" + $(if ($n.user) { "`r`n$($n.user)" } else { '' })
  $iv = J 'inv.json'; if ($iv -and $iv.battery) { $info.Text += "`r`nBattery health $($iv.battery.health)% ($($iv.battery.cycles) cycles)   ·   " + ((@($iv.disks) | ForEach-Object { $_.model + ' ' + $_.health }) -join ', ') }
  $week.Text = 'Last 7 days: ' + $(if ($v -and $v.all) { (@($v.all) | ForEach-Object { $LVL[[string]$_.lv][0] + ' ' + $_.v }) -join '   ' } else { 'nothing found' })
  $ni.Text = ('PC Doctor - ' + $(if ($v) { $v.v } else { '' })).Substring(0, [math]::Min(63, ('PC Doctor - ' + $(if ($v) { $v.v } else { '' })).Length))
  if ($lv -ne $lastLv) { $ni.Icon = Ico $e[1]; $script:lastLv = $lv }
  $un = J 'uninst.json'; if ($un -and $script:unAsked -and [int64]$un.t -ge $script:unAsked) { $script:unAsked = 0; $msg.Text = [string]$un.msg }
  $u = J 'usb.json'; if ($u -and $u.t -gt $seen.usb) { $seen.usb = $u.t; $msg.Text = $(if ($u.ok) { 'Saved: ' + $u.file } else { 'No pendrive found - plug one in and try again.' }) }
  $x = J 'usbfix.json'; if ($x -and $x.t -gt $seen.fix) { $seen.fix = $x.t; $msg.Text = $(if ($x.ok) { 'Done: ' + ((@($x.done) | ForEach-Object { $_.file + $(if ($_.ok) { ' ✅' } else { ' ❌' }) }) -join ', ') + ' - result saved on the pendrive' } else { 'No fix pendrive (DavanFix\fix.json) found.' }) }
  # Super Admin laptop
  $g = J 'grid.json'
  if ($g -and $g.now) {
    LaptopTabs; $grid.BeginUpdate(); $grid.Items.Clear(); $cfg = J 'cfg.json'; $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $rows = foreach ($p in $g.now.PSObject.Properties) { $pc = $g.pcs.($p.Name); if ($pc.old) { continue }; $r = $p.Value
      $l = if (($nowMs - [int64]$r.t) -gt 30 * 60000) { 'off' } else { [string]$r.lv }; [pscustomobject]@{ h = $p.Name; n = [string]$(if ($pc.name) { $pc.name } else { $r.name }); g = [string]$pc.grp; lv = $l; v = [string]$r.v } }
    foreach ($r in ($rows | Sort-Object g, @{ e = { [regex]::Replace($_.n, '\d+', { $args[0].Value.PadLeft(4, '0') }) } })) {
      $gn = if ($cfg -and $cfg.groups.($r.g)) { $cfg.groups.($r.g).name } else { $r.g }
      $it = New-Object Windows.Forms.ListViewItem(($LVL[$r.lv][0] + ' ' + $r.n)); [void]$it.SubItems.Add($gn); [void]$it.SubItems.Add($(if ($r.lv -eq 'off') { 'off / not reporting' } else { $r.v })); $it.ForeColor = $LVL[$r.lv][1]; [void]$grid.Items.Add($it)
      # popups: a PC turned 🔴 / lab-wide
      $key = $r.h + $r.lv + $r.v; if ($r.lv -in 'red','purple' -and !$seen[$key]) { $seen[$key] = 1; if ($seen.init) { $ni.ShowBalloonTip(8000, ($LVL[$r.lv][0] + ' ' + $r.n), $r.v, 'Warning') } } }
    $grid.EndUpdate(); $seen.init = 1
    if ($g.sum -and $g.sum.at -and !$seen['sum' + $g.sum.at]) { $seen['sum' + $g.sum.at] = 1; $ni.ShowBalloonTip(15000, '🖥️ PC Doctor morning summary', ([string]$g.sum.base + $(if ($g.sum.ai) { "`n✨ " + $g.sum.ai } else { '' })), 'Info') }
    foreach ($fx in @($g.fix.PSObject.Properties | ForEach-Object { $hh = $_.Name; $_.Value.PSObject.Properties | ForEach-Object { [pscustomobject]@{ h = $hh; k = $_.Name; f = $_.Value } } })) {
      if ($seen['fx' + $fx.k] -or $fx.f.fix -ne 'stop_program' -or !$fx.f.ok) { $seen['fx' + $fx.k] = 1; continue }
      $seen['fx' + $fx.k] = 1; if ($seen.init2) { $ni.ShowBalloonTip(6000, ('🛠️ Hang fixed on ' + [string]$g.pcs.($fx.h).name), [string]$fx.f.txt, 'Info') } }
    $seen.init2 = 1
    if ($script:aiAsked -and $script:aiBox -and ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $script:aiAsked) -gt 120000) { $script:aiAsked = 0; $script:aiBox.Text = 'No answer in 2 minutes - the PC Doctor Agent may be busy or offline. Tap Ask again; if it keeps failing, tap Copy report on This PC and send it to Claude.' }
    $a = J 'ai.json'; if ($a -and $a.t -gt $seen.ai -and $script:aiBox) { $seen.ai = $a.t; $script:aiAsked = 0; $script:aiBox.Text = $(if ($a.ok) { "✨ AI`r`n`r`n" + $a.text + "`r`n`r`n($($a.left) answers left today)" } else { [string]$a.msg }) }
  }
}
# 1.3 (user, 04-Nov-2026: "it's not auto update"): the loader updates the files, but a running tray kept its old copy until the next sign-in -
# when state\running.json shows a new build and the window is closed, the tray starts its new copy and quits (no click, no sign-out)
$script:myBuild = try { [int](J 'running.json').build } catch { 0 }
function SelfUpdate { $b = try { [int](J 'running.json').build } catch { 0 }
  if ($b -and $script:myBuild -and $b -ne $script:myBuild -and !$form.Visible -and (Test-Path "$Root\bin\tray.ps1")) {
    $ni.Visible = $false; try { $mtx.ReleaseMutex(); $mtx.Dispose() } catch {}
    if (Test-Path "$Root\tray-start.vbs") { Start-Process wscript.exe -ArgumentList "`"$Root\tray-start.vbs`" /now" } else { Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Root\bin\tray.ps1`"" }
    [Environment]::Exit(0) } }
$tm = New-Object Windows.Forms.Timer -Property @{ Interval = 15000 }; $tm.Add_Tick({ try { Refresh } catch {}; try { UpdRefresh } catch {}; try { if (!$tp.Enabled) { $pp = J 'updp.json'; if ($pp -and ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - [int64]$pp.t) -lt 300000) { $tp.Start() } } } catch {}; try { SelfUpdate } catch {} }); $tm.Start()
try { Refresh } catch {}; try { UpdRefresh } catch {}
Sharp $form; Corner
if ($args -contains '-show') { OpenWin }
[Windows.Forms.Application]::Run()
