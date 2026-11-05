# PC Doctor (tray window) - tray.ps1 (ROADMAP-pcdoctor.md 8). Runs for every user (HKLM Run). Closing the window never stops the
# PC Doctor Agent (that is the SYSTEM service). Reads the agent's state files, sends requests through req\ (the agent does the work).
# Password 2531 (hashed in lab/cfg/trayPw, changeable on the Console) to OPEN the window (and Copy report). Laptop = Super Admin mode: all-PCs grid + popups.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
# 1.6 (user, 05-Nov-2026: "on my laptop the tray text looks very low resolution"): without this Windows draws the window at 96 dpi and
# stretches it on a 125-200% screen (blurry). DPI-aware + every form scales its own layout (Sharp) = sharp text at any scaling.
try { Add-Type -Namespace PDT -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -ErrorAction Stop; [void][PDT.Dpi]::SetProcessDPIAware() } catch {}
[Windows.Forms.Application]::EnableVisualStyles()
function Sharp($f) { $f.AutoScaleDimensions = New-Object Drawing.SizeF(96, 96); $f.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Dpi }
$Root = "$env:ProgramData\DavanPCDoctor"; $St = "$Root\state"; $Rq = "$Root\req"
$mtx = New-Object Threading.Mutex($false, 'Local\DavanPCDoctorTray'); if (!$mtx.WaitOne(0)) { exit 0 }
function J($f) { try { Get-Content "$St\$f" -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $null } }
function W($f, $o) { try { [IO.File]::WriteAllText("$Rq\$f", ($o | ConvertTo-Json -Depth 6 -Compress), (New-Object Text.UTF8Encoding($false))) } catch {} }
function IST($ms) { if (!$ms) { return '-' }; ([DateTimeOffset]::FromUnixTimeMilliseconds([int64]$ms)).ToOffset([TimeSpan]::FromHours(5.5)).ToString('dd MMM, h:mm tt') + ' IST' }
function Hash($s) { -join ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('davanlab:' + $s)) | ForEach-Object { $_.ToString('x2') }) }
$C = @{ bg = [Drawing.Color]::FromArgb(11,13,17); card = [Drawing.Color]::FromArgb(20,23,30); bd = [Drawing.Color]::FromArgb(38,43,54); tx = [Drawing.Color]::FromArgb(230,232,238)
        mu = [Drawing.Color]::FromArgb(140,147,163); ac = [Drawing.Color]::FromArgb(240,165,0); ok = [Drawing.Color]::FromArgb(52,211,153); wa = [Drawing.Color]::FromArgb(251,146,60)
        er = [Drawing.Color]::FromArgb(248,113,113); ye = [Drawing.Color]::FromArgb(250,204,21); pu = [Drawing.Color]::FromArgb(167,139,250); off = [Drawing.Color]::FromArgb(75,85,99) }
$LV = @{ green = @('🟢', $C.ok); yellow = @('🟡', $C.ye); orange = @('🟠', $C.wa); red = @('🔴', $C.er); purple = @('🟣', $C.pu); off = @('⚫', $C.off) }
$F = @{ big = New-Object Drawing.Font('Segoe UI Semibold', 13); n = New-Object Drawing.Font('Segoe UI', 9.5); s = New-Object Drawing.Font('Segoe UI', 8.5); m = New-Object Drawing.Font('Consolas', 9); e = New-Object Drawing.Font('Segoe UI Emoji', 10) }
function Pw([string]$why) {
  $f = New-Object Windows.Forms.Form -Property @{ Text = 'PC Doctor'; Width = 300; Height = 150; StartPosition = 'CenterScreen'; ShowInTaskbar = $true; BackColor = $C.bg; ForeColor = $C.tx; FormBorderStyle = 'FixedDialog'; MaximizeBox = $false; MinimizeBox = $false; TopMost = $true }; Sharp $f
  $l = New-Object Windows.Forms.Label -Property @{ Text = "🔒 Password for $why"; Left = 14; Top = 12; Width = 260; Font = $F.n }
  $t = New-Object Windows.Forms.TextBox -Property @{ Left = 14; Top = 40; Width = 255; UseSystemPasswordChar = $true; Font = $F.n }
  $b = New-Object Windows.Forms.Button -Property @{ Text = 'OK'; Left = 194; Top = 72; Width = 75; DialogResult = 'OK'; FlatStyle = 'Flat'; BackColor = $C.ac; ForeColor = [Drawing.Color]::Black }
  $f.Controls.AddRange(@($l, $t, $b)); $f.AcceptButton = $b
  if ($f.ShowDialog() -ne 'OK') { return $false }
  $cfg = J 'cfg.json'; $want = if ($cfg -and $cfg.trayPw) { [string]$cfg.trayPw } else { Hash '2531' }
  if ((Hash $t.Text) -eq $want) { return $true }
  [Windows.Forms.MessageBox]::Show('Wrong password.', 'PC Doctor') | Out-Null; $false
}
# ---------- the window ----------
$form = New-Object Windows.Forms.Form -Property @{ Text = 'PC Doctor - ' + $env:COMPUTERNAME; Width = 460; Height = 640; BackColor = $C.bg; ForeColor = $C.tx; StartPosition = 'Manual'; FormBorderStyle = 'FixedSingle'; MaximizeBox = $false; ShowInTaskbar = $true }
Sharp $form
function Corner { $wa = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea; $form.Left = $wa.Right - $form.Width - 12; $form.Top = [math]::Max($wa.Top, $wa.Bottom - $form.Height - 12) }
Corner; $form.Add_Shown({ Corner })   # after the DPI scaling the window is bigger - keep it in the corner, fully on screen
$tabs = New-Object Windows.Forms.TabControl -Property @{ Dock = 'Fill'; Font = $F.n }
$tMe = New-Object Windows.Forms.TabPage -Property @{ Text = 'This PC'; BackColor = $C.bg }
$tabs.TabPages.Add($tMe); $form.Controls.Add($tabs)
# ---------- ⬆️ Updates tab (user, 04-Nov-2026): Update now + this PC's version, when it came, what's new (5 newest, Show all / Hide) ----------
$tUp = New-Object Windows.Forms.TabPage -Property @{ Text = '⬆️ Updates'; BackColor = $C.bg }; $tabs.TabPages.Add($tUp)
$uVer = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 10; Width = 420; Height = 26; Font = $F.big; ForeColor = $C.ac; Text = 'PC Doctor' }
$uWhen = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 40; Width = 420; Height = 40; Font = $F.s; ForeColor = $C.mu }
$uRes = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 122; Width = 420; Height = 36; Font = $F.s; ForeColor = $C.ac }
$uBtn = New-Object Windows.Forms.Button -Property @{ Text = '⬆️ Update now'; Left = 12; Top = 84; Width = 200; Height = 32; FlatStyle = 'Flat'; BackColor = $C.ac; ForeColor = [Drawing.Color]::Black; Font = $F.n }
$uNewT = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 162; Width = 260; Height = 22; Font = $F.n; Text = "🆕 What's new" }
$uAll = New-Object Windows.Forms.Button -Property @{ Text = 'Show all ▾'; Left = 312; Top = 158; Width = 120; Height = 26; FlatStyle = 'Flat'; BackColor = $C.card; ForeColor = $C.tx; Font = $F.s }
$uNews = New-Object Windows.Forms.TextBox -Property @{ Left = 12; Top = 188; Width = 420; Height = 360; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $C.card; ForeColor = $C.tx; Font = $F.s; BorderStyle = 'None' }
$uBtn.FlatAppearance.BorderColor = $C.ac; $uAll.FlatAppearance.BorderColor = $C.bd
$tUp.Controls.AddRange(@($uVer, $uWhen, $uBtn, $uRes, $uNewT, $uAll, $uNews))
$script:showAll = $false; $script:askedAt = 0
function UpdNow { try { Set-Content "$Rq\update.flag" '1' } catch { $uRes.Text = '❌ Could not ask the updater: ' + $_.Exception.Message; return }
  $script:askedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $uRes.Text = '⏳ Checking for an update - about a minute ...'; $uBtn.Enabled = $false }
$uBtn.Add_Click({ UpdNow })
$uAll.Add_Click({ $script:showAll = !$script:showAll; UpdRefresh })
function UpdRefresh {
  $r = J 'running.json'; $lv = J 'labver.json'; $u = J 'upd.json'
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
$head = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 10; Width = 420; Height = 26; Font = $F.big; ForeColor = $C.ac; Text = 'PC Doctor' }
$verd = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 40; Width = 420; Height = 62; Font = $F.n }
$tMe.Controls.AddRange(@($head, $verd))
$bars = @{}; $y = 106
foreach ($k in @(@('cpu','CPU'), @('ram','RAM'), @('busy','Disk busy'), @('cfree','C: free'))) {
  $l = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $y; Width = 90; Text = $k[1]; Font = $F.s; ForeColor = $C.mu }
  $p = New-Object Windows.Forms.ProgressBar -Property @{ Left = 104; Top = $y; Width = 250; Height = 14; Maximum = 100; Style = 'Continuous' }
  $v = New-Object Windows.Forms.Label -Property @{ Left = 360; Top = $y - 2; Width = 70; Font = $F.m }
  $tMe.Controls.AddRange(@($l, $p, $v)); $bars[$k[0]] = @($p, $v); $y += 24 }
$info = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $y + 4; Width = 420; Height = 92; Font = $F.s; ForeColor = $C.mu }
$week = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $y + 98; Width = 420; Height = 60; Font = $F.s }
$tMe.Controls.AddRange(@($info, $week))
function Btn($t, $x, $yy, $w, $on) { $b = New-Object Windows.Forms.Button -Property @{ Text = $t; Left = $x; Top = $yy; Width = $w; Height = 30; FlatStyle = 'Flat'; BackColor = $C.card; ForeColor = $C.tx; Font = $F.s }
  $b.FlatAppearance.BorderColor = $C.bd; $b.Add_Click($on); $tMe.Controls.Add($b); $b }
$by = 440
$msg = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $by + 108; Width = 420; Height = 36; Font = $F.s; ForeColor = $C.ac }; $tMe.Controls.Add($msg)
function Report {
  $n = J 'now.json'; $v = J 'verdict.json'; $p = J 'pc.json'
  "PC Doctor report - $env:COMPUTERNAME ($(IST ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())))`r`n" +
  "Verdict: $($v.v) ($($v.conf)% sure) - $($v.why)`r`n" + "Group: $($p.grp)  Place: $($p.place)  Notes: $($p.notes)`r`n" +
  "CPU $($n.cpu)%  RAM $($n.ram)%  Disk busy $($n.busy)%  latency $($n.lat) ms  C: free $($n.cfree)% ($($n.cfreeGB) GB)  Temp $($n.temp) °C`r`n" +
  "Deep Freeze: $($n.df)  Internet: $(if ($n.online) { 'yes' } else { 'no' })  Not sent yet: $($n.q)  Agent: $($n.ver)`r`n" +
  "Top programs: " + ((@($n.top) | ForEach-Object { "$($_.n) $($_.c)% $($_.m) MB" }) -join ', ') + "`r`n" +
  "Other findings: " + ((@($v.all) | Select-Object -Skip 1 | ForEach-Object { $_.v }) -join ', ')
}
Btn '📤 Send report now' 12 $by 136 { Set-Content "$Rq\now.flag" '1'; $msg.Text = '📤 Asked - the full report goes to the Console in about a minute.' } | Out-Null
Btn '🔍 Check now' 152 $by 136 { Set-Content "$Rq\now.flag" '1'; $msg.Text = '🔍 Checking - the verdict updates in about a minute.' } | Out-Null
Btn '📋 Copy' 292 $by 140 { [Windows.Forms.Clipboard]::SetText((Report)); $msg.Text = '📋 Report copied - paste it in WhatsApp / chat.' } | Out-Null
Btn '💾 Save report to pendrive' 12 ($by + 36) 200 { Set-Content "$Rq\usb.flag" '1'; $msg.Text = '💾 Saving to the pendrive ...' } | Out-Null
Btn '🔧 Fix from pendrive' 216 ($by + 36) 216 { if ($script:unlocked -or (Pw 'Fix from pendrive')) { Set-Content "$Rq\usbfix.flag" '1'; $msg.Text = '🔧 Running the approved fixes from the pendrive ...' } } | Out-Null
Btn '⚙️ Name / group / notes' 12 ($by + 72) 420 { if ($script:unlocked -or (Pw 'changing this PC')) { Edit } } | Out-Null
function Edit {
  $p = J 'pc.json'; $cfg = J 'cfg.json'
  $f = New-Object Windows.Forms.Form -Property @{ Text = '⚙️ This PC'; Width = 360; Height = 330; BackColor = $C.bg; ForeColor = $C.tx; StartPosition = 'CenterScreen'; FormBorderStyle = 'FixedDialog'; TopMost = $true }; Sharp $f
  $fields = @(@('name','Name (= Windows name)'), @('grp','Group'), @('place','Place'), @('user','Usual user'), @('notes','Notes')); $box = @{}; $yy = 12
  foreach ($x in $fields) { $f.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = $x[1]; Left = 12; Top = $yy + 3; Width = 130; Font = $F.s; ForeColor = $C.mu }))
    if ($x[0] -eq 'grp') { $c = New-Object Windows.Forms.ComboBox -Property @{ Left = 146; Top = $yy; Width = 185; DropDownStyle = 'DropDownList' }
      if ($cfg -and $cfg.groups) { foreach ($g in $cfg.groups.PSObject.Properties) { [void]$c.Items.Add($g.Name + ' - ' + $g.Value.name) } }
      $c.SelectedIndex = [math]::Max(0, [array]::IndexOf(@($c.Items | ForEach-Object { ($_ -split ' - ')[0] }), [string]$p.grp)) }
    else { $c = New-Object Windows.Forms.TextBox -Property @{ Left = 146; Top = $yy; Width = 185; Text = [string]$p.($x[0]) } }
    $f.Controls.Add($c); $box[$x[0]] = $c; $yy += 32 }
  $dfb = New-Object Windows.Forms.CheckBox -Property @{ Text = 'Has Deep Freeze'; Left = 146; Top = $yy; Width = 185; Checked = [bool]($p.df -ne $false) }; $f.Controls.Add($dfb); $yy += 30
  $who = New-Object Windows.Forms.TextBox -Property @{ Left = 146; Top = $yy; Width = 185 }; $f.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = 'Your name'; Left = 12; Top = $yy + 3; Width = 130; Font = $F.s; ForeColor = $C.mu })); $f.Controls.Add($who); $yy += 36
  $ok = New-Object Windows.Forms.Button -Property @{ Text = 'Save'; Left = 256; Top = $yy; Width = 75; DialogResult = 'OK'; FlatStyle = 'Flat'; BackColor = $C.ac; ForeColor = [Drawing.Color]::Black }; $f.Controls.Add($ok)
  if ($f.ShowDialog() -eq 'OK') {
    $e = @{ who = $(if ($who.Text) { $who.Text } else { $env:USERNAME }); name = $box.name.Text.Trim().ToUpper(); grp = ([string]$box.grp.SelectedItem -split ' - ')[0]; place = $box.place.Text; user = $box.user.Text; notes = $box.notes.Text; df = $dfb.Checked }
    W ('edit' + [DateTime]::UtcNow.Ticks + '.json') $e; $msg.Text = '✏️ Saved - the Console shows the change (and who made it) within a minute.' }
}
# ---------- Super Admin laptop: all PCs grid + ✨ Ask AI ----------
$tGrid = $null; $grid = $null; $tAi = $null
function LaptopTabs {
  if ($tGrid) { return }
  $script:tGrid = New-Object Windows.Forms.TabPage -Property @{ Text = 'All PCs'; BackColor = $C.bg }
  $script:grid = New-Object Windows.Forms.ListView -Property @{ Dock = 'Fill'; View = 'Details'; FullRowSelect = $true; BackColor = $C.bg; ForeColor = $C.tx; Font = $F.s; BorderStyle = 'None' }
  foreach ($c in @(@('PC', 70), @('Group', 90), @('State', 230))) { [void]$grid.Columns.Add($c[0], $c[1]) }
  $tGrid.Controls.Add($grid); $tabs.TabPages.Add($tGrid)
  $script:tAi = New-Object Windows.Forms.TabPage -Property @{ Text = '✨ Ask AI'; BackColor = $C.bg }
  $q = New-Object Windows.Forms.TextBox -Property @{ Left = 10; Top = 10; Width = 330; Font = $F.n }
  $ans = New-Object Windows.Forms.TextBox -Property @{ Left = 10; Top = 46; Width = 422; Height = 470; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $C.card; ForeColor = $C.tx; Font = $F.n }
  $go = New-Object Windows.Forms.Button -Property @{ Text = 'Ask'; Left = 346; Top = 8; Width = 86; FlatStyle = 'Flat'; BackColor = $C.ac; ForeColor = [Drawing.Color]::Black }
  $go.Add_Click({ $g = J 'grid.json'; $ctx = ''
    if ($g) { $ctx = (@($g.now.PSObject.Properties) | ForEach-Object { $n = $_.Value; ([string]$g.pcs.($_.Name).name) + ': ' + $n.lv + ' ' + $n.v + ' cpu ' + $n.cpu + ' ram ' + $n.ram + ' C free ' + $n.cfree + '%' }) -join "`n" }
    W 'ai.json' @{ prompt = ('Lab now:' + "`n" + $ctx.Substring(0, [math]::Min(2800, $ctx.Length)) + "`n`nQuestion: " + $q.Text); history = @() }
    $ans.Text = '✨ Asking ...'; $script:aiAsked = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() })
  $tAi.Controls.AddRange(@($q, $go, $ans)); $tabs.TabPages.Add($tAi); $script:aiBox = $ans
}
# ---------- tray icon + refresh ----------
$ni = New-Object Windows.Forms.NotifyIcon -Property @{ Visible = $true; Text = 'PC Doctor' }
function Ico($col) { $b = New-Object Drawing.Bitmap 16, 16; $g = [Drawing.Graphics]::FromImage($b); $g.SmoothingMode = 'AntiAlias'
  $g.FillRectangle((New-Object Drawing.SolidBrush $C.bg), 0, 0, 16, 16); $g.FillRectangle((New-Object Drawing.SolidBrush $C.tx), 2, 3, 12, 8); $g.FillRectangle((New-Object Drawing.SolidBrush $C.bg), 3, 4, 10, 6)
  $g.FillRectangle((New-Object Drawing.SolidBrush $C.tx), 6, 12, 4, 2); $g.FillEllipse((New-Object Drawing.SolidBrush $col), 9, 8, 7, 7); $g.Dispose(); [Drawing.Icon]::FromHandle($b.GetHicon()) }
$ni.Icon = Ico $C.ok
$menu = New-Object Windows.Forms.ContextMenuStrip
# 1.2 (user, 04-Nov-2026: "we planned a password to open it, but it opens without"): the window opens only with the password (2531,
# changeable on the Console); while it stays open ⚙️ / 🔧 don't ask again; hiding it locks it again
$script:unlocked = $false
function OpenWin { if ($form.Visible -and $script:unlocked) { $form.WindowState = 'Normal'; $form.Activate(); return }
  if (!$script:unlocked -and !(Pw 'opening PC Doctor')) { return }
  $script:unlocked = $true; $form.Show(); $form.WindowState = 'Normal'; $form.Activate() }
[void]$menu.Items.Add('Open PC Doctor', $null, { OpenWin })
[void]$menu.Items.Add('🔍 Check now', $null, { Set-Content "$Rq\now.flag" '1' })
[void]$menu.Items.Add('⬆️ Update now', $null, { UpdNow; OpenWin; $tabs.SelectedTab = $tUp })
[void]$menu.Items.Add('📋 Copy report', $null, { if ($script:unlocked -or (Pw 'copying the report')) { [Windows.Forms.Clipboard]::SetText((Report)) } })
$ni.ContextMenuStrip = $menu
$ni.Add_MouseClick({ if ($_.Button -eq 'Left') { OpenWin } })
$form.Add_FormClosing({ if ($_.CloseReason -eq 'UserClosing') { $_.Cancel = $true; $form.Hide(); $script:unlocked = $false } })   # closing never stops anything
$seen = @{}; $lastLv = ''
function Refresh {
  $n = J 'now.json'; $v = J 'verdict.json'
  if (!$n) { $head.Text = 'PC Doctor - starting'; $verd.Text = 'The PC Doctor Agent has not written its first check yet (about a minute after start).'; return }
  $lv = if ($v) { [string]$v.lv } else { 'green' }; $e = $LV[$lv]; if (!$e) { $e = $LV.green }
  $head.Text = $e[0] + ' ' + $env:COMPUTERNAME + ' - ' + $(if ($v) { $v.v } else { 'checking' }); $head.ForeColor = $e[1]
  $verd.Text = $(if ($v) { $v.why + "  (" + $v.conf + "% sure)" } else { '' })
  foreach ($k in 'cpu','ram','busy','cfree') { $x = [int]$n.$k; $bars[$k][0].Value = [math]::Max(0, [math]::Min(100, $x)); $bars[$k][1].Text = "$x%" }
  $tq = if ($n.thawQ) { "  ·  Thaw needed: $($n.thawQ) fix" + $(if ($n.thawQ -ne 1) { 'es' }) } else { '' }
  $info.Text = "🌡️ CPU $(if ($n.temp) { [string]$n.temp + ' °C' } else { '-' })   ·   " + $(if ($n.df -eq 'thawed') { '🔥 Thawed' } elseif ($n.df -eq 'frozen') { '🧊 Frozen' } else { 'No Deep Freeze' }) + $tq + "`r`n" +
    $(if ($n.online) { '🌐 Internet OK' } else { '📴 No internet - saved, sends later' }) + "   ·   Last sent $(IST $n.t)" + $(if ($n.q) { "   ·   $($n.q) waiting" } else { '' }) + "`r`n" +
    "C: $($n.cfreeGB) GB free   ·   disk answers in $($n.lat) ms   ·   Agent $($n.ver)" + $(if ($n.user) { "`r`n👤 $($n.user)" } else { '' })
  $iv = J 'inv.json'; if ($iv -and $iv.battery) { $info.Text += "`r`n🔋 Battery health $($iv.battery.health)% ($($iv.battery.cycles) cycles)   ·   💾 " + ((@($iv.disks) | ForEach-Object { $_.model + ' ' + $_.health }) -join ', ') }
  $week.Text = 'Last 7 days: ' + $(if ($v -and $v.all) { (@($v.all) | ForEach-Object { $LV[[string]$_.lv][0] + ' ' + $_.v }) -join '   ' } else { '🟢 nothing found' })
  $ni.Text = ('PC Doctor - ' + $(if ($v) { $v.v } else { '' })).Substring(0, [math]::Min(63, ('PC Doctor - ' + $(if ($v) { $v.v } else { '' })).Length))
  if ($lv -ne $lastLv) { $ni.Icon = Ico $e[1]; $script:lastLv = $lv }
  $u = J 'usb.json'; if ($u -and $u.t -gt $seen.usb) { $seen.usb = $u.t; $msg.Text = $(if ($u.ok) { '💾 Saved: ' + $u.file } else { '💾 No pendrive found - plug one in and try again.' }) }
  $x = J 'usbfix.json'; if ($x -and $x.t -gt $seen.fix) { $seen.fix = $x.t; $msg.Text = $(if ($x.ok) { '🔧 Done: ' + ((@($x.done) | ForEach-Object { $_.file + $(if ($_.ok) { ' ✅' } else { ' ❌' }) }) -join ', ') + ' - result saved on the pendrive' } else { '🔧 No fix pendrive (DavanFix\fix.json) found.' }) }
  # Super Admin laptop
  $g = J 'grid.json'
  if ($g -and $g.now) {
    LaptopTabs; $grid.BeginUpdate(); $grid.Items.Clear(); $cfg = J 'cfg.json'; $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $rows = foreach ($p in $g.now.PSObject.Properties) { $pc = $g.pcs.($p.Name); if ($pc.old) { continue }; $r = $p.Value
      $l = if (($nowMs - [int64]$r.t) -gt 30 * 60000) { 'off' } else { [string]$r.lv }; [pscustomobject]@{ h = $p.Name; n = [string]$(if ($pc.name) { $pc.name } else { $r.name }); g = [string]$pc.grp; lv = $l; v = [string]$r.v } }
    foreach ($r in ($rows | Sort-Object g, @{ e = { [regex]::Replace($_.n, '\d+', { $args[0].Value.PadLeft(4, '0') }) } })) {
      $gn = if ($cfg -and $cfg.groups.($r.g)) { $cfg.groups.($r.g).name } else { $r.g }
      $it = New-Object Windows.Forms.ListViewItem(($LV[$r.lv][0] + ' ' + $r.n)); [void]$it.SubItems.Add($gn); [void]$it.SubItems.Add($(if ($r.lv -eq 'off') { 'off / not reporting' } else { $r.v })); $it.ForeColor = $LV[$r.lv][1]; [void]$grid.Items.Add($it)
      # popups: a PC turned 🔴 / lab-wide
      $key = $r.h + $r.lv + $r.v; if ($r.lv -in 'red','purple' -and !$seen[$key]) { $seen[$key] = 1; if ($seen.init) { $ni.ShowBalloonTip(8000, ($LV[$r.lv][0] + ' ' + $r.n), $r.v, 'Warning') } } }
    $grid.EndUpdate(); $seen.init = 1
    if ($g.sum -and $g.sum.at -and !$seen['sum' + $g.sum.at]) { $seen['sum' + $g.sum.at] = 1; $ni.ShowBalloonTip(15000, '🖥️ PC Doctor morning summary', ([string]$g.sum.base + $(if ($g.sum.ai) { "`n✨ " + $g.sum.ai } else { '' })), 'Info') }
    foreach ($fx in @($g.fix.PSObject.Properties | ForEach-Object { $hh = $_.Name; $_.Value.PSObject.Properties | ForEach-Object { [pscustomobject]@{ h = $hh; k = $_.Name; f = $_.Value } } })) {
      if ($seen['fx' + $fx.k] -or $fx.f.fix -ne 'stop_program' -or !$fx.f.ok) { $seen['fx' + $fx.k] = 1; continue }
      $seen['fx' + $fx.k] = 1; if ($seen.init2) { $ni.ShowBalloonTip(6000, ('🛠️ Hang fixed on ' + [string]$g.pcs.($fx.h).name), [string]$fx.f.txt, 'Info') } }
    $seen.init2 = 1
    $a = J 'ai.json'; if ($a -and $a.t -gt $seen.ai -and $script:aiBox) { $seen.ai = $a.t; $script:aiBox.Text = $(if ($a.ok) { "✨ AI`r`n`r`n" + $a.text + "`r`n`r`n($($a.left) answers left today)" } else { [string]$a.msg }) }
  }
}
# 1.3 (user, 04-Nov-2026: "it's not auto update"): the loader updates the files, but a running tray kept its old copy until the next sign-in -
# when state\running.json shows a new build and the window is closed, the tray starts its new copy and quits (no click, no sign-out)
$script:myBuild = try { [int](J 'running.json').build } catch { 0 }
function SelfUpdate { $b = try { [int](J 'running.json').build } catch { 0 }
  if ($b -and $script:myBuild -and $b -ne $script:myBuild -and !$form.Visible -and (Test-Path "$Root\bin\tray.ps1")) {
    $ni.Visible = $false; try { $mtx.ReleaseMutex(); $mtx.Dispose() } catch {}
    Start-Process powershell.exe -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Root\bin\tray.ps1`""
    [Environment]::Exit(0) } }
$tm = New-Object Windows.Forms.Timer -Property @{ Interval = 15000 }; $tm.Add_Tick({ try { Refresh } catch {}; try { UpdRefresh } catch {}; try { SelfUpdate } catch {} }); $tm.Start()
try { Refresh } catch {}; try { UpdRefresh } catch {}
if ($args -contains '-show') { OpenWin }
[Windows.Forms.Application]::Run()
