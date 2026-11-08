# PC Doctor (tray window) - tray.ps1 (ROADMAP-pcdoctor.md 8). Runs for every user (HKLM Run). Closing the window never stops the
# PC Doctor Agent (that is the SYSTEM service). Reads the agent's state files, sends requests through req\ (the agent does the work).
# Password 2531 (hashed in lab/cfg/trayPw, changeable on the Console) to OPEN the window (and Copy report). Laptop = Super Admin mode: all-PCs grid + popups.
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
# 1.6 (user, 05-Nov-2026: "on my laptop the tray text looks very low resolution"): without this Windows draws the window at 96 dpi and
# stretches it on a 125-200% screen (blurry). DPI-aware + every form scales its own layout (Sharp) = sharp text at any scaling.
try { Add-Type -Namespace PDT -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -ErrorAction Stop; [void][PDT.Dpi]::SetProcessDPIAware() } catch {}
[Windows.Forms.Application]::EnableVisualStyles()
# 1.36 (user, 05-Nov-2026: "Windows PowerShell has stopped working" - the Sony's crash text: an error inside a button / timer, then Windows could not even draw its
# error box, which killed the tray): every such error is caught and written to %TEMP%\pcdoctor-tray-errors.log - the tray keeps running
try { [Windows.Forms.Application]::SetUnhandledExceptionMode([Windows.Forms.UnhandledExceptionMode]::CatchException) } catch {}
[Windows.Forms.Application]::add_ThreadException({ param($s0, $e0) try { Add-Content "$env:TEMP\pcdoctor-tray-errors.log" ((Get-Date).ToString('dd MMM HH:mm:ss') + '  ' + [string]$e0.Exception.Message) } catch {} })
# 1.8 (user, 05-Nov-2026: "the tray items are small and the window is big, not aligned"): Windows' AutoScale grew only the window, not
# its buttons / bars. Now every form is scaled by hand ONCE, after all its controls are in (Sharp), by the real screen DPI.
$DPIK = try { $g0 = [Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $d = $g0.DpiX / 96; $g0.Dispose(); [math]::Max(1, [math]::Min(3, $d)) } catch { 1 }
function Sharp($f) { $f.AutoScaleMode = [Windows.Forms.AutoScaleMode]::None; if ($DPIK -gt 1.01) { $f.Scale((New-Object Drawing.SizeF($DPIK, $DPIK))) } }
$Root = if ($env:PDT_ROOT) { $env:PDT_ROOT } else { "$env:ProgramData\DavanPCDoctor" }; $St = "$Root\state"; $Rq = "$Root\req"   # PDT_ROOT: only the Windows test (screenshots) sets it
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
# 1.44 (user, 05-Nov-2026: "show the version in the tooltip and on left click, without the password"): the running PC Doctor version (state\running.json)
function VerTxt { try { $x = [string](J 'running.json').ver; if ($x) { 'v' + $x } else { '' } } catch { '' } }
function PwText([string]$why) { $script:lastPw = $null; if (Pw $why) { return $script:lastPw }; return $null }
function Pw([string]$why) {
  $f = New-Object Windows.Forms.Form -Property @{ Text = ('PC Doctor ' + (VerTxt)); Width = 300; Height = 150; StartPosition = 'CenterScreen'; ShowInTaskbar = $true; BackColor = $CL.bg; ForeColor = $CL.tx; FormBorderStyle = 'FixedDialog'; MaximizeBox = $false; MinimizeBox = $false; TopMost = $true }
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
$form = New-Object Windows.Forms.Form -Property @{ Text = 'PC Doctor - ' + $env:COMPUTERNAME; Width = 460; Height = 748; BackColor = $CL.bg; ForeColor = $CL.tx; StartPosition = 'Manual'; FormBorderStyle = 'FixedSingle'; MaximizeBox = $false; ShowInTaskbar = $true }
function Corner { $wa = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea; $form.Left = $wa.Right - $form.Width - 12; $form.Top = [math]::Max($wa.Top, $wa.Bottom - $form.Height - 12) }
Corner; $form.Add_Shown({ Corner })   # after the DPI scaling the window is bigger - keep it in the corner, fully on screen
$tabs = New-Object Windows.Forms.TabControl -Property @{ Dock = 'Fill'; Font = $FT.n; Multiline = $true }
$tMe = New-Object Windows.Forms.TabPage -Property @{ Text = 'This PC'; BackColor = $CL.bg }
$tabs.TabPages.Add($tMe); $form.Controls.Add($tabs)
# 1.20 (user, 05-Nov-2026): a footer on every tab so everybody knows who built it (text can be changed in DB5 lab/cfg footer)
$foot = New-Object Windows.Forms.Label -Property @{ Dock = 'Bottom'; Height = 38; TextAlign = 'MiddleCenter'; Font = $FT.s; ForeColor = $CL.mu; BackColor = $CL.bg; Text = 'Davan PC Doctor' + [char]13 + [char]10 + 'Built by Harsh Gujjar for Davan College, Davangere  -  built with Claude' }
$form.Controls.Add($foot)
# ---------- Notes tab (user, 05-Nov-2026: "keep all these steps in new notes in the tray icon so I know how it works after some days") ----------
# the text is the file notes.txt (pcdoctor/src/notes.txt on GitHub), downloaded like every other PC Doctor file, so it reads offline and
# a change to the notes never needs a new tray
$tNote = New-Object Windows.Forms.TabPage -Property @{ Text = 'Notes'; BackColor = $CL.bg }
$nTxt = New-Object Windows.Forms.TextBox -Property @{ Left = 12; Top = 10; Width = 420; Height = 500; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None' }
$nCopy = New-Object Windows.Forms.Button -Property @{ Text = 'Copy notes'; Left = 12; Top = 516; Width = 140; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
$nCopy.FlatAppearance.BorderColor = $CL.bd; $nCopy.Add_Click({ try { [Windows.Forms.Clipboard]::SetText($nTxt.Text) } catch {} })
$tNote.Controls.AddRange(@($nTxt, $nCopy))
$script:notesAt = [datetime]::MinValue
function NotesLoad { $f = "$Root\bin\notes.txt"
  if (!(Test-Path $f)) { if (!$nTxt.Text) { $nTxt.Text = 'The notes arrive with the next PC Doctor update (Updates tab -> Update now).' }; return }
  $w = (Get-Item $f).LastWriteTime; if ($w -eq $script:notesAt) { return }; $script:notesAt = $w
  try { $nTxt.Text = ((Get-Content $f -Raw -Encoding UTF8) -replace "`r?`n", "`r`n"); $nTxt.SelectionStart = 0; $nTxt.SelectionLength = 0 } catch {} }
# ---------- ⬆️ Updates tab (user, 04-Nov-2026): Update now + this PC's version, when it came, what's new (5 newest, Show all / Hide) ----------
$tUp = New-Object Windows.Forms.TabPage -Property @{ Text = '⬆ Updates'; BackColor = $CL.bg }; $tabs.TabPages.Add($tUp); $tabs.TabPages.Add($tNote)
# ---------- 🩺 Fixes tab (1.71, user, 07-Nov-2026: "keep every fix of this PC on this PC and on the server - what we did, the command, the undo, did it work;
# one click for the manager; he can say it is still not working (choices + words + photo); every new problem too") ----------
# The list is state\book.json (written by the agent from DB5 lab/book/<hwid>), so it shows offline too. Every button sends a request file
# (req\book*.json) - the agent (SYSTEM) does the work and saves it on the server; a saved login runs here (it belongs to the person logged in).
# Photos go to Cloudinary (never into DB5): screenshot of this PC or a picture file. The same PC Doctor password opens the window.
$tFx = New-Object Windows.Forms.TabPage -Property @{ Text = '🩺 Fixes'; BackColor = $CL.bg }; $tabs.TabPages.Add($tFx)
$fxHead = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 8; Width = 420; Height = 22; Font = $FT.n; ForeColor = $CL.ac; Text = '🩺 Fixes for this PC' }
$fxList = New-Object Windows.Forms.ListView -Property @{ Left = 12; Top = 70; Width = 420; Height = 210; View = 'Details'; FullRowSelect = $true; HideSelection = $false; MultiSelect = $false; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None' }
foreach ($c0 in @(@('When', 92), @('What', 212), @('Status', 112))) { [void]$fxList.Columns.Add($c0[0], [int]($c0[1] * $DPIK)) }
$fxInfo = New-Object Windows.Forms.TextBox -Property @{ Left = 12; Top = 286; Width = 420; Height = 150; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None'; Text = 'Tap a line above to see what was done, the command, the undo and the result.' }
$fxMsg = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 582; Width = 420; Height = 34; Font = $FT.s; ForeColor = $CL.ac }
$tFx.Controls.AddRange(@($fxHead, $fxList, $fxInfo, $fxMsg))
function FxBtn($t0, $x, $yy, $w, $on) { $b = New-Object Windows.Forms.Button -Property @{ Text = $t0; Left = $x; Top = $yy; Width = $w; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $b.FlatAppearance.BorderColor = $CL.bd; $b.Add_Click($on); $tFx.Controls.Add($b); $b }
$fxRep = FxBtn '🆘 Report a problem' 12 34 206 { FxAsk 'report' $null }
$fxRep.BackColor = $CL.ac; $fxRep.ForeColor = [Drawing.Color]::Black
$null = FxBtn '⟳ Refresh' 226 34 206 { try { Set-Content "$Rq\refresh.flag" '1' } catch {}; $script:fxAt = 0; FxLoad; $fxMsg.Text = 'Asked PC Doctor for the newest list - it comes within about 15 s.' }
$fxRun = FxBtn '▶ Fix now' 12 442 136 { FxRun }
$fxOk = FxBtn '✅ Worked' 154 442 136 { FxFeedback $true }
$fxNot = FxBtn '❌ Still not working' 296 442 136 { FxAsk 'not' (FxSel) }
$fxUndo = FxBtn '↩ Undo' 12 476 136 { FxUndo }
$fxCp = FxBtn '📋 Copy command' 154 476 136 { $e = FxSel; if ($e -and $e.cmd) { try { [Windows.Forms.Clipboard]::SetText([string]$e.cmd); $fxMsg.Text = '📋 Command copied - paste it in PowerShell (as admin), or in Command Prompt for a saved login.' } catch {} } }
$fxCpU = FxBtn '📋 Copy undo' 296 476 136 { $e = FxSel; if ($e -and $e.undoCmd) { try { [Windows.Forms.Clipboard]::SetText([string]$e.undoCmd); $fxMsg.Text = '📋 Undo command copied.' } catch {} } }
$fxSolved = FxBtn '✅ Problem solved' 12 510 136 { FxSolved }
$fxCpAll = FxBtn '📋 Copy all details' 154 510 136 { try { [Windows.Forms.Clipboard]::SetText($fxInfo.Text); $fxMsg.Text = '📋 Details copied.' } catch {} }
$null = FxBtn '📋 Copy whole list' 296 510 136 { try { [Windows.Forms.Clipboard]::SetText((FxAllText)); $fxMsg.Text = '📋 Whole list copied.' } catch {} }
$script:fxAt = 0; $script:fxItems = @{}
function FxStatus($e) {
  if ($e.type -eq 'prob') { if ($e.st -eq 'fixed') { return '✅ solved' }; return '🆘 open' }
  if ($e.user -eq 'worked') { return '✅ worked' }
  if ($e.user -eq 'not') { return '❌ not working' }
  switch ([string]$e.st) { 'wait' { '⏳ waits for OK' } 'ready' { if ([string]$e.need -in '', 'auto') { '⏳ runs by itself' } else { '👉 press ▶ Fix now' } } 'running' { '⚙️ running' }
    'done' { if ($e.chk -and !$e.chk.ok) { '⚠️ check failed' } else { '✅ done' } } 'failed' { '❌ failed' } 'thaw' { '🧊 needs Thawed' } 'undo' { '↩ undo asked' } 'undone' { '↩ undone' } default { [string]$e.st } }
}
function FxTodo($e) { ($e.type -eq 'fix' -and (($e.st -eq 'ready' -and [string]$e.need -notin '', 'auto') -or ($e.st -eq 'undo' -and $e.need -eq 'user'))) -or ($e.type -eq 'prob' -and $e.st -eq 'open') }
function FxSel { if (!$fxList.SelectedItems.Count) { return $null }; $script:fxItems[[string]$fxList.SelectedItems[0].Tag] }
function FxDetail($e) {
  if (!$e) { return '' }
  $o = @(([string]$e.title), ('Status: ' + (FxStatus $e)), ('When: ' + (IST $e.t) + $(if ($e.by) { '  ·  by ' + $e.by } elseif ($e.who) { '  ·  by ' + $e.who } else { '' })))
  if ($e.type -eq 'prob') {
    if ($e.cat) { $o += 'Kind: ' + $e.cat }; if ($e.choice) { $o += 'Answer: ' + $e.choice }; if ($e.text) { $o += 'Words: ' + $e.text }; if ($e.photo) { $o += 'Photo: ' + $e.photo }
    if ($e.fix -and $script:fxItems[[string]$e.fix]) { $o += 'About the fix: ' + $script:fxItems[[string]$e.fix].title }
    $o += 'Logs saved for the Super Admin: ' + $(if ($e.ev) { 'yes' } else { 'being saved…' })
    if ($e.closedAt) { $o += 'Solved: ' + (IST $e.closedAt) + ' by ' + $e.closedBy }
  } else {
    if ($e.why) { $o += 'Why: ' + $e.why }
    $o += 'Who does it: ' + $(switch ([string]$e.need) { 'person' { 'a person presses ▶ Fix now here' } 'user' { 'the person logged in presses ▶ Fix now (it is their own login)' } default { 'PC Doctor, by itself, as soon as this PC is on' } })
    if ($e.res) { $o += 'Result: ' + $e.res.txt + '  (' + (IST $e.res.t) + $(if ($e.runBy) { ', ' + $e.runBy } else { '' }) + ')' }
    if ($e.chk) { $o += 'Check: ' + $(if ($e.chk.ok) { '✅ ' } else { '⚠️ ' }) + $e.chk.txt }
    if ($e.user) { $o += 'Person says: ' + $(if ($e.user -eq 'worked') { '✅ worked' } else { '❌ still not working' }) + ' (' + $e.userWho + ', ' + (IST $e.userAt) + ')' }
    if ($e.undoRes) { $o += 'Undo: ' + $e.undoRes + ' (' + (IST $e.undoAt) + ')' }
    if ($e.cmd) { $o += ''; $o += 'Command: ' + $e.cmd }
    if ($e.undoCmd) { $o += 'Undo command: ' + $e.undoCmd }
    $pr = @($script:fxItems.Values | Where-Object { $_.type -eq 'prob' -and [string]$_.fix -eq [string]$e.id })
    foreach ($x in $pr) { $o += ''; $o += '❌ ' + (IST $x.t) + ' ' + $x.who + ': ' + $x.choice + $(if ($x.text) { ' - ' + $x.text } else { '' }) }
  }
  $o -join "`r`n"
}
function FxAllText { $o = @('PC Doctor 🩺 Fixes - ' + $env:COMPUTERNAME + ' - ' + (IST ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()))); foreach ($e in @($script:fxItems.Values | Sort-Object { -[int64]$_.t })) { $o += ''; $o += (FxDetail $e) }; $o -join "`r`n" }
function FxButtons {
  $e = FxSel; $isF = $e -and $e.type -eq 'fix'
  $fxRun.Enabled = [bool]($isF -and $e.st -in 'ready', 'failed')
  $fxOk.Enabled = [bool]($isF -and $e.st -in 'done', 'thaw' -and $e.user -ne 'worked')
  $fxNot.Enabled = [bool]($isF -and $e.st -in 'done', 'failed', 'thaw')
  $fxUndo.Enabled = [bool]($isF -and (($e.st -in 'done', 'thaw' -and ($e.undo -or $e.need -eq 'user')) -or ($e.st -eq 'undo' -and $e.need -eq 'user')))
  $fxCp.Enabled = [bool]($isF -and $e.cmd); $fxCpU.Enabled = [bool]($isF -and $e.undoCmd)
  $fxSolved.Enabled = [bool]($e -and $e.type -eq 'prob' -and $e.st -eq 'open'); $fxCpAll.Enabled = [bool]$e
}
function FxLoad {
  $b = J 'book.json'; if (!$b) { $fxHead.Text = '🩺 Fixes for ' + $env:COMPUTERNAME + ' - nothing yet'; FxButtons; return }
  if ([int64]$b.t -eq [int64]$script:fxAt) { return }; $script:fxAt = [int64]$b.t
  $keep = if ($fxList.SelectedItems.Count) { [string]$fxList.SelectedItems[0].Tag } else { '' }
  $script:fxItems = @{}; foreach ($x in @($b.items)) { if ($x -and $x.id) { $script:fxItems[[string]$x.id] = $x } }
  $all = @($script:fxItems.Values | Sort-Object @{ e = { if (FxTodo $_) { 0 } else { 1 } } }, @{ e = { -[int64]$_.t } })
  $fxList.BeginUpdate(); $fxList.Items.Clear()
  foreach ($e in $all) { $it = New-Object Windows.Forms.ListViewItem((IST $e.t) -replace ' IST$', ''); $it.Tag = [string]$e.id
    [void]$it.SubItems.Add($(if ($e.type -eq 'prob') { '🆘 ' } else { '' }) + [string]$e.title); [void]$it.SubItems.Add((FxStatus $e)); $it.UseItemStyleForSubItems = $false
    $st0 = FxStatus $e; $it.SubItems[2].ForeColor = $(if ($st0 -match '^(✅)') { $CL.ok } elseif ($st0 -match '^(❌|🆘)') { $CL.er } elseif ($st0 -match '^(👉|⚠️)') { $CL.wa } else { $CL.mu })
    if (FxTodo $e) { $it.SubItems[1].ForeColor = $CL.ac }
    [void]$fxList.Items.Add($it); if ($it.Tag -eq $keep) { $it.Selected = $true } }
  $fxList.EndUpdate()
  $nTodo = @($all | Where-Object { FxTodo $_ }).Count; $nOpen = @($all | Where-Object { $_.type -eq 'prob' -and $_.st -eq 'open' }).Count
  $fxHead.Text = '🩺 ' + $env:COMPUTERNAME + ' - ' + $(if ($nTodo) { [string]$nTodo + ' to do' } else { 'nothing to do' }) + $(if ($nOpen) { ' · ' + $nOpen + ' open problem' + $(if ($nOpen -ne 1) { 's' } else { '' }) } else { '' }) + $(if (!$b.online) { ' · offline (saved, sent later)' } else { '' })
  $tFx.Text = $(if ($nTodo) { '🩺 Fixes (' + $nTodo + ')' } else { '🩺 Fixes' })
  $fxInfo.Text = $(if ($fxList.SelectedItems.Count) { FxDetail (FxSel) } elseif ($all.Count) { 'Tap a line above to see what was done, the command, the undo and the result.' } else { 'No fixes yet. When something is not working, press 🆘 Report a problem - the Super Admin gets it at once, with this PC''s logs.' })
  FxButtons
}
$fxList.Add_SelectedIndexChanged({ try { $fxInfo.Text = FxDetail (FxSel); FxButtons } catch {} })
function FxWho { try { $f = "$env:LOCALAPPDATA\DavanPCDoctor\who.txt"; if (Test-Path $f) { return ([string](Get-Content $f -Raw)).Trim() } } catch {}; [string]$env:USERNAME }
function FxWhoSave([string]$n) { try { New-Item -ItemType Directory -Force "$env:LOCALAPPDATA\DavanPCDoctor" | Out-Null; Set-Content "$env:LOCALAPPDATA\DavanPCDoctor\who.txt" $n } catch {} }
function FxSend($o) { W ('book' + [DateTime]::UtcNow.Ticks + '.json') $o }
try { Add-Type -ErrorAction Stop -TypeDefinition @'
using System; using System.Runtime.InteropServices;
namespace PDC { public static class Cred {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct CREDENTIAL { public int Flags; public int Type; public string TargetName; public string Comment; public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten; public int CredentialBlobSize; public IntPtr CredentialBlob; public int Persist; public int AttributeCount; public IntPtr Attributes; public string TargetAlias; public string UserName; }
  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool CredWriteW(ref CREDENTIAL c, int flags);
  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool CredDeleteW(string t, int type, int flags);
  [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool CredReadW(string t, int type, int flags, out IntPtr c);
  [DllImport("advapi32.dll")] static extern void CredFree(IntPtr p);
  public static int Add(string target, string user, string pass) { CREDENTIAL c = new CREDENTIAL(); c.Type = 2; c.TargetName = target; c.UserName = user; c.Persist = 2;
    byte[] b = System.Text.Encoding.Unicode.GetBytes(pass ?? ""); c.CredentialBlobSize = b.Length; c.CredentialBlob = IntPtr.Zero;
    if (b.Length > 0) { c.CredentialBlob = Marshal.AllocHGlobal(b.Length); Marshal.Copy(b, 0, c.CredentialBlob, b.Length); }
    bool ok = CredWriteW(ref c, 0); int e = ok ? 0 : Marshal.GetLastWin32Error(); if (c.CredentialBlob != IntPtr.Zero) Marshal.FreeHGlobal(c.CredentialBlob); return e; }
  public static bool Has(string target) { IntPtr p; if (!CredReadW(target, 2, 0, out p)) return false; CredFree(p); return true; }
  public static int Del(string target) { return CredDeleteW(target, 2, 0) ? 0 : Marshal.GetLastWin32Error(); } } }
'@ } catch {}
# need user (a saved login for a sharing PC): runs HERE, in the person's own Windows login. The password is typed on this PC and never leaves it.
function FxUserRun($e) {
  if ([string]$e.fix -ne 'save_login') { $fxMsg.Text = 'This fix has no one-click version for the user yet.'; return }
  $hst = [string]$e.args.host; $usr = [string]$e.args.user; if (!$hst -or !$usr) { $fxMsg.Text = 'The fix has no PC name / user - ask the Super Admin.'; return }
  # 1.78 option 1: the office printer login - PC Doctor fills the password in (state\printlogin.json, from the Console's encrypted copy); nobody types it
  if ($e.args.secret) { $pl = J 'printlogin.json'
    if (!$pl -or !$pl.pw) { try { Set-Content "$Rq\refresh.flag" '1' } catch {}; $fxMsg.Text = '⏳ PC Doctor is fetching the printer login password - press ▶ Fix now again in a minute. (Not set yet? Console -> Settings -> Printer login.)'; return }
    FxCredSave $e ([string]$pl.host) ([string]$pl.user) ([string]$pl.pw) ([int64]$pl.at) 'saved'; return }
  $f = New-Object Windows.Forms.Form -Property @{ Text = '🔑 Save the login for ' + $hst; Width = 360; Height = 220; StartPosition = 'CenterScreen'; BackColor = $CL.bg; ForeColor = $CL.tx; FormBorderStyle = 'FixedDialog'; MaximizeBox = $false; MinimizeBox = $false; TopMost = $true }
  $l = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 10; Width = 320; Height = 44; Font = $FT.s; Text = "This PC will log in to $hst as $usr (for its printers / folders). Type that password - it stays on this PC." }
  $nb = New-Object Windows.Forms.CheckBox -Property @{ Left = 12; Top = 58; Width = 320; Font = $FT.s; Text = 'That account has no password'; Checked = [bool]$e.args.blank }
  $tb = New-Object Windows.Forms.TextBox -Property @{ Left = 12; Top = 86; Width = 320; UseSystemPasswordChar = $true; Font = $FT.n; Enabled = ![bool]$e.args.blank }
  $nb.Add_CheckedChanged({ $tb.Enabled = !$nb.Checked; if ($nb.Checked) { $tb.Text = '' } })
  $ok = New-Object Windows.Forms.Button -Property @{ Text = 'Save login'; Left = 222; Top = 124; Width = 110; Height = 30; DialogResult = 'OK'; FlatStyle = 'Flat'; BackColor = $CL.ac; ForeColor = [Drawing.Color]::Black }
  $f.Controls.AddRange(@($l, $nb, $tb, $ok)); $f.AcceptButton = $ok; Sharp $f
  if ($f.ShowDialog() -ne 'OK') { return }
  $pw = if ($nb.Checked) { '' } else { $tb.Text }
  $err = try { [PDC.Cred]::Add($hst, $usr, $pw) } catch { -1 }
  $has = try { [PDC.Cred]::Has($hst) } catch { $false }
  $txt = if ($err -eq 0 -and $has) { "Login for $hst saved ($usr) for Windows user $env:USERNAME. Sign out and back in (or restart), then open \\$hst and double-click the printer." } else { "Could not save the login (error $err)." }
  FxSend @{ op = 'result'; id = [string]$e.id; ok = ($err -eq 0 -and $has); txt = $txt; who = (FxWho); chk = @{ ok = [bool]$has; txt = $(if ($has) { "Windows has a saved login for $hst" } else { "No saved login for $hst" }) } }
  $fxMsg.Text = $(if ($err -eq 0 -and $has) { '✅ ' } else { '❌ ' }) + $txt
}
function FxCredSave($e, [string]$hst, [string]$usr, [string]$pw, [int64]$at, [string]$how) {
  $err = try { [PDC.Cred]::Add($hst, $usr, $pw) } catch { -1 }; $has = try { [PDC.Cred]::Has($hst) } catch { $false }
  if ($err -eq 0 -and $has) { try { New-Item -ItemType Directory -Force "$env:LOCALAPPDATA\DavanPCDoctor" | Out-Null; Set-Content "$env:LOCALAPPDATA\DavanPCDoctor\printlogin_at.txt" ([string]$at) } catch {} }
  $txt = if ($err -eq 0 -and $has) { "Login for $hst $how ($usr) for Windows user $env:USERNAME. " + $(if ($how -eq 'saved') { "Sign out and back in (or restart), then open \\$hst and double-click a printer - it installs by itself, no password." } else { 'The new password from the Console is in - nothing to do.' }) } else { "Could not save the login (error $err)." }
  FxSend @{ op = 'result'; id = [string]$e.id; ok = ($err -eq 0 -and $has); txt = $txt; who = (FxWho); chk = @{ ok = [bool]$has; txt = $(if ($has) { "Windows has a saved login for $hst" } else { "No saved login for $hst" }) } }
  $fxMsg.Text = $(if ($err -eq 0 -and $has) { '✅ ' } else { '❌ ' }) + $txt
}
# a changed password (Console) is saved again by itself - only for a login this user already saved
function FxCredAuto {
  $pl = J 'printlogin.json'; if (!$pl -or !$pl.pw) { return }
  $f = "$env:LOCALAPPDATA\DavanPCDoctor\printlogin_at.txt"; if (!(Test-Path $f)) { return }
  if ([string](Get-Content $f -Raw).Trim() -eq [string]$pl.at) { return }
  $e = @($script:fxItems.Values | Where-Object { $_.type -eq 'fix' -and $_.fix -eq 'save_login' -and $_.args -and $_.args.secret -and $_.st -eq 'done' }) | Select-Object -First 1
  if ($e) { FxCredSave $e ([string]$pl.host) ([string]$pl.user) ([string]$pl.pw) ([int64]$pl.at) 'updated' }
}
function FxRun {
  $e = FxSel; if (!$e -or $e.type -ne 'fix') { return }
  if ($e.need -eq 'user') { FxUserRun $e; return }
  if ([Windows.Forms.MessageBox]::Show("Run now on this PC?`r`n`r`n" + [string]$e.title + $(if ($e.why) { "`r`n`r`nWhy: " + $e.why } else { '' }), 'PC Doctor - ▶ Fix now', 'YesNo', 'Question') -ne 'Yes') { return }
  FxSend @{ op = 'run'; id = [string]$e.id; who = (FxWho) }
  $fxMsg.Text = '▶ Sent - PC Doctor runs it within about 15 s; the result shows here and the Super Admin gets it.'
}
function FxFeedback([bool]$good) {
  $e = FxSel; if (!$e) { return }
  FxSend @{ op = 'fb'; id = [string]$e.id; ok = $good; who = (FxWho) }
  $fxMsg.Text = '✅ Thank you - saved. The Super Admin gets it now and the problem is closed.'
}
function FxSolved { $e = FxSel; if (!$e -or $e.type -ne 'prob') { return }
  if ([Windows.Forms.MessageBox]::Show('Is this problem solved now?', 'PC Doctor', 'YesNo', 'Question') -ne 'Yes') { return }
  FxSend @{ op = 'solved'; id = [string]$e.id; who = (FxWho) }; $fxMsg.Text = '✅ Marked solved - the Super Admin gets it now.' }
function FxUndo {
  $e = FxSel; if (!$e -or $e.type -ne 'fix') { return }
  if ([Windows.Forms.MessageBox]::Show("Undo this fix on this PC?`r`n`r`n" + [string]$e.title, 'PC Doctor - ↩ Undo', 'YesNo', 'Question') -ne 'Yes') { return }
  if ($e.need -eq 'user' -and [string]$e.fix -eq 'save_login') { $hst = [string]$e.args.host; $r0 = try { [PDC.Cred]::Del($hst) } catch { -1 }
    FxSend @{ op = 'undone'; id = [string]$e.id; who = (FxWho); txt = $(if ($r0 -eq 0) { "Saved login for $hst removed (Windows user $env:USERNAME)" } else { "No saved login for $hst to remove (code $r0)" }) }
    $fxMsg.Text = '↩ Done - the saved login for ' + $hst + ' is removed.'; return }
  FxSend @{ op = 'undo'; id = [string]$e.id; who = (FxWho) }; $fxMsg.Text = '↩ Sent - PC Doctor puts it back within about 15 s.'
}
function FxShot {
  $vs = [Windows.Forms.SystemInformation]::VirtualScreen; $bm = New-Object Drawing.Bitmap $vs.Width, $vs.Height; $gr = [Drawing.Graphics]::FromImage($bm); $gr.CopyFromScreen($vs.Left, $vs.Top, 0, 0, $bm.Size); $gr.Dispose()
  if ($bm.Width -gt 1920) { $k = 1920 / $bm.Width; $b2 = New-Object Drawing.Bitmap $bm, ([int]($bm.Width * $k)), ([int]($bm.Height * $k)); $bm.Dispose(); $bm = $b2 }
  $out = Join-Path $env:TEMP ('pcdoctor-shot-' + [DateTime]::Now.Ticks + '.jpg')
  $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
  $ep = New-Object Drawing.Imaging.EncoderParameters 1; $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), ([int64]70)
  $bm.Save($out, $enc, $ep); $bm.Dispose(); $out
}
# Cloudinary (the same account as the staff app's photos; names in DB5 lab/cfg cloudinary {cloud, preset} - a change needs no new tray)
function FxUpload([string]$file) {
  $cfg = J 'cfg.json'; $cl = if ($cfg -and $cfg.cloudinary -and $cfg.cloudinary.cloud) { [string]$cfg.cloudinary.cloud } else { 'dat0khbet' }; $pre = if ($cfg -and $cfg.cloudinary -and $cfg.cloudinary.preset) { [string]$cfg.cloudinary.preset } else { 'davan_students' }
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  Add-Type -AssemblyName System.Net.Http
  $hc = New-Object Net.Http.HttpClient; $hc.Timeout = [TimeSpan]::FromSeconds(90)
  $mp = New-Object Net.Http.MultipartFormDataContent
  $bc = New-Object Net.Http.ByteArrayContent (, [IO.File]::ReadAllBytes($file)); $bc.Headers.ContentType = [Net.Http.Headers.MediaTypeHeaderValue]::Parse($(if ($file -match '\.png$') { 'image/png' } else { 'image/jpeg' }))
  $mp.Add($bc, 'file', [IO.Path]::GetFileName($file)); $mp.Add((New-Object Net.Http.StringContent($pre)), 'upload_preset'); $mp.Add((New-Object Net.Http.StringContent('pcdoctor_' + $env:COMPUTERNAME)), 'tags')
  $rs = $hc.PostAsync("https://api.cloudinary.com/v1_1/$cl/image/upload", $mp).Result; $tx = $rs.Content.ReadAsStringAsync().Result; $hc.Dispose()
  $j = $tx | ConvertFrom-Json; if (!$j.secure_url) { throw ('Cloudinary: ' + $tx.Substring(0, [math]::Min(160, $tx.Length))) }; [string]$j.secure_url
}
# ❌ Still not working (about a fix) / 🆘 Report a problem: tap a choice, optional words, optional photo, your name -> the agent saves it on the server,
# saves this PC's logs (evidence pack) and the Super Admin gets a push at once. Offline: kept and sent when the internet is back.
function FxAsk([string]$mode, $e) {
  if ($mode -eq 'not' -and !$e) { return }
  $ch = if ($mode -eq 'not') { @('Same error as before', 'A different error now', 'Works sometimes, not always', 'Worked, but something else broke') } else { @('Printer', 'Internet / network', 'Slow', 'Will not start / restarts by itself', 'A program will not open', 'Sound / screen', 'Other') }
  $f = New-Object Windows.Forms.Form -Property @{ Text = $(if ($mode -eq 'not') { '❌ Still not working' } else { '🆘 Report a problem' }); Width = 400; Height = 300 + 26 * $ch.Count; StartPosition = 'CenterScreen'; BackColor = $CL.bg; ForeColor = $CL.tx; FormBorderStyle = 'FixedDialog'; MaximizeBox = $false; MinimizeBox = $false; TopMost = $true }
  $hd = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 8; Width = 360; Height = 34; Font = $FT.s; ForeColor = $CL.ac; Text = $(if ($mode -eq 'not') { 'After: ' + [string]$e.title } else { 'What is not working on ' + $env:COMPUTERNAME + '?' }) }
  $f.Controls.Add($hd); $yy = 44; $rb = @()
  foreach ($c1 in $ch) { $r = New-Object Windows.Forms.RadioButton -Property @{ Left = 16; Top = $yy; Width = 350; Height = 24; Text = $c1; Font = $FT.s; ForeColor = $CL.tx }; $f.Controls.Add($r); $rb += $r; $yy += 26 }
  $rb[0].Checked = $true
  $f.Controls.Add((New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $yy + 4; Width = 360; Font = $FT.s; ForeColor = $CL.mu; Text = 'Details / the error words (optional)' }))
  $tx = New-Object Windows.Forms.TextBox -Property @{ Left = 12; Top = $yy + 26; Width = 360; Height = 54; Multiline = $true; Font = $FT.s }; $f.Controls.Add($tx)
  $f.Controls.Add((New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $yy + 88; Width = 90; Font = $FT.s; ForeColor = $CL.mu; Text = 'Your name' }))
  $wn = New-Object Windows.Forms.TextBox -Property @{ Left = 104; Top = $yy + 85; Width = 268; Font = $FT.s; Text = (FxWho) }; $f.Controls.Add($wn)
  $script:fxPhoto = ''
  $pl = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $yy + 152; Width = 360; Font = $FT.s; ForeColor = $CL.mu; Text = 'No photo (optional)' }
  $bs = New-Object Windows.Forms.Button -Property @{ Text = '📷 Screenshot'; Left = 12; Top = $yy + 116; Width = 176; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $bp = New-Object Windows.Forms.Button -Property @{ Text = '📁 Picture file…'; Left = 196; Top = $yy + 116; Width = 176; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $bs.Add_Click({ try { $f.Opacity = 0; $form.Opacity = 0; [Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 700; $script:fxPhoto = FxShot } catch { $pl.Text = 'Screenshot failed: ' + $_.Exception.Message } finally { $f.Opacity = 1; $form.Opacity = 1 }
    if ($script:fxPhoto) { $pl.Text = '📷 Screenshot of this screen added'; $pl.ForeColor = $CL.ok } })
  $bp.Add_Click({ $od = New-Object Windows.Forms.OpenFileDialog -Property @{ Filter = 'Pictures|*.jpg;*.jpeg;*.png'; Title = 'Choose a picture of the problem' }; if ($od.ShowDialog() -eq 'OK') { $script:fxPhoto = $od.FileName; $pl.Text = '📁 ' + [IO.Path]::GetFileName($od.FileName); $pl.ForeColor = $CL.ok } })
  $ok = New-Object Windows.Forms.Button -Property @{ Text = 'Send'; Left = 262; Top = $yy + 180; Width = 110; Height = 32; DialogResult = 'OK'; FlatStyle = 'Flat'; BackColor = $CL.ac; ForeColor = [Drawing.Color]::Black }
  $cn = New-Object Windows.Forms.Button -Property @{ Text = 'Cancel'; Left = 146; Top = $yy + 180; Width = 110; Height = 32; DialogResult = 'Cancel'; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx }
  $f.Controls.AddRange(@($bs, $bp, $pl, $ok, $cn)); $f.CancelButton = $cn; Sharp $f
  if ($f.ShowDialog() -ne 'OK') { return }
  $pick = ($rb | Where-Object Checked | Select-Object -First 1).Text; $who = $wn.Text.Trim(); if (!$who) { $who = [string]$env:USERNAME }; FxWhoSave $who
  $url = ''; $note = ''
  if ($script:fxPhoto) { $fxMsg.Text = '📤 Sending the photo…'; [Windows.Forms.Application]::DoEvents()
    try { $url = FxUpload $script:fxPhoto } catch { $note = ' (the photo could not be sent: ' + $_.Exception.Message + ' - the report went without it)' } }
  if ($mode -eq 'not') { FxSend @{ op = 'fb'; id = [string]$e.id; ok = $false; choice = $pick; text = $tx.Text.Trim(); photo = $url; who = $who } }
  else { FxSend @{ op = 'report'; cat = $pick; choice = ''; text = $tx.Text.Trim(); photo = $url; who = $who } }
  $fxMsg.Text = '✅ Sent - the Super Admin gets it now, with this PC''s logs.' + $note
}
$uVer = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 10; Width = 420; Height = 26; Font = $FT.big; ForeColor = $CL.ac; Text = 'PC Doctor' }
$uWhen = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 40; Width = 420; Height = 40; Font = $FT.s; ForeColor = $CL.mu }
$uUsb = New-Object Windows.Forms.Button -Property @{ Text = 'Update from pendrive'; Left = 220; Top = 84; Width = 212; Height = 32; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.n }
$uUsb.FlatAppearance.BorderColor = $CL.bd
$uBar = New-Object Windows.Forms.ProgressBar -Property @{ Left = 12; Top = 122; Width = 420; Height = 14; Maximum = 100; Style = 'Continuous'; Visible = $false }
$uRes = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 140; Width = 420; Height = 38; Font = $FT.s; ForeColor = $CL.ac }
$uBtn = New-Object Windows.Forms.Button -Property @{ Text = '⬆ Update now'; Left = 12; Top = 84; Width = 200; Height = 32; FlatStyle = 'Flat'; BackColor = $CL.ac; ForeColor = [Drawing.Color]::Black; Font = $FT.n }
$uNewT = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 184; Width = 260; Height = 22; Font = $FT.n; Text = "What's new" }
$uAll = New-Object Windows.Forms.Button -Property @{ Text = 'Show all ▾'; Left = 312; Top = 180; Width = 120; Height = 26; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
$uNews = New-Object Windows.Forms.TextBox -Property @{ Left = 12; Top = 210; Width = 420; Height = 338; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None' }
$uBtn.FlatAppearance.BorderColor = $CL.ac; $uAll.FlatAppearance.BorderColor = $CL.bd
$tUp.Controls.AddRange(@($uVer, $uWhen, $uBtn, $uUsb, $uBar, $uRes, $uNewT, $uAll, $uNews))
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
    'usb'      { $pc = 10 + [int](70 * $pp.i / [math]::Max(1, $pp.n)); $tx = "Copying $to from the pendrive - file $($pp.i) of $($pp.n): $($pp.file)" }
    'usbdone'  { $pc = 100; $tx = "PC Doctor $to installed from the pendrive - it restarts in a few seconds." }
    default    { $pc = 5; $tx = 'Updating ...' }
  }
  $uBar.Visible = $true; $uBar.Value = [math]::Min(100, [math]::Max(0, $pc)); $uRes.Text = $(if ($pc -ge 100) { '✅ ' } else { '⏳ ' }) + $tx
  $msg.Text = 'Update: ' + $tx; $t2 = "PC Doctor - updating $pc%"; if ($pc -ge 100) { $t2 = "PC Doctor $to" }; $ni.Text = $t2.Substring(0, [math]::Min(63, $t2.Length))
  $k = [string]$pp.t; if ($pp.ph -eq 'download' -and $script:upKey -ne ('s' + $to) -and !$script:askedAt -and $pc -lt 100) { $script:upKey = 's' + $to; $ni.ShowBalloonTip(5000, 'PC Doctor', "Updating to $to - open the tray to see the progress.", 'Info') }
  if ($pc -ge 100) { $uBtn.Enabled = $true; $script:askedAt = 0; if ($script:upKey -ne ('d' + $to)) { $script:upKey = 'd' + $to; $ni.ShowBalloonTip(5000, 'PC Doctor', "Updated - PC Doctor $to is running.", 'Info') }; $tp.Stop() }
}
$tp = New-Object Windows.Forms.Timer -Property @{ Interval = 1000 }; $tp.Add_Tick({ try { UpdProgress } catch {} })
# 1.17 (user, 05-Nov-2026: "yes, build with pendrive also"): no internet / GitHub blocked -> a pendrive made on the Console (Rescue page ->
# "Make PC Doctor update pendrive", folder DavanUpdate). The password goes WITH the request: the agent (SYSTEM) checks it again and
# every file's fingerprint, so nobody can slip a changed file in from a stick.
$script:usbAt = 0
function UsbUpdate {
  if (!($script:unlocked -or (Pw 'updating from the pendrive'))) { return }
  $pw = $script:lastPw; if ($script:unlocked -and !$pw) { $pw = PwText 'updating from the pendrive'; if ($null -eq $pw) { return } }
  W 'usbupd.json' @{ pw = $pw; who = $env:USERNAME; t = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
  $script:usbAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $uRes.Text = 'Looking for the update pendrive (a DavanUpdate folder) ...'; $uBar.Visible = $true; $uBar.Value = 5; $tp.Start()
}
$uUsb.Add_Click({ UsbUpdate })
function UpdNow { try { Set-Content "$Rq\update.flag" '1' } catch { $uRes.Text = '❌ Could not ask the updater: ' + $_.Exception.Message; return }
  $script:askedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $uRes.Text = '⏳ Step 1/5 · Asked the updater - it starts within a few seconds ...'; $uBtn.Enabled = $false; $uBar.Visible = $true; $uBar.Value = 5; $tp.Start() }
$uBtn.Add_Click({ UpdNow })
$uAll.Add_Click({ $script:showAll = !$script:showAll; UpdRefresh })
function UpdRefresh {
  $r = J 'running.json'; $lv = J 'labver.json'; $u = J 'upd.json'
  $ux = J 'usbupd.json'; if ($ux -and $script:usbAt -and [int64]$ux.t -ge $script:usbAt) { $script:usbAt = 0; $uRes.Text = $(if ($ux.ok) { '✅ ' } else { '❌ ' }) + [string]$ux.msg; $msg.Text = [string]$ux.msg; if (!$ux.ok) { $uBar.Visible = $false; $tp.Stop() } }
  $fc = J 'cfg.json'; $ft2 = if ($fc -and $fc.footer) { [string]$fc.footer } else { 'Built by Harsh Gujjar for Davan College, Davangere  -  built with Claude' }
  $foot.Text = 'Davan PC Doctor' + $(if ($r -and $r.ver) { ' v' + $r.ver } else { '' }) + "`r`n" + $ft2
  $pn = PcNames; $form.Text = 'PC Doctor' + $(if ($r -and $r.ver) { ' v' + $r.ver } else { '' }) + ' - ' + $pn.con   # 1.15 (user, 05-Nov-2026): version always in the title
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
$verd = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = 40; Width = 420; Height = 46; Font = $FT.n }
$tMe.Controls.AddRange(@($head, $verd))
$bars = @{}; $y = 92
foreach ($k in @(@('cpu','CPU'), @('ram','RAM'), @('busy','Disk busy'), @('cfree','C: free'))) {
  $l = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $y; Width = 90; Text = $k[1]; Font = $FT.s; ForeColor = $CL.mu }
  $p = New-Object Windows.Forms.ProgressBar -Property @{ Left = 104; Top = $y; Width = 250; Height = 14; Maximum = 100; Style = 'Continuous' }
  $v = New-Object Windows.Forms.Label -Property @{ Left = 360; Top = $y - 2; Width = 70; Font = $FT.m }
  $tMe.Controls.AddRange(@($l, $p, $v)); $bars[$k[0]] = @($p, $v); $y += 22 }
# 1.17 (user, 05-Nov-2026: "make it properly aligned so the points look neat, I do not want to miss any point"): a two-column list -
# what on the left (grey), the value on the right, one fact per row, RAM programs and the last-7-days findings one per row (coloured)
$facts = New-Object Windows.Forms.ListView -Property @{ Left = 12; Top = $y + 4; Width = 420; Height = 292; View = 'Details'; HeaderStyle = 'None'; FullRowSelect = $false; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None'; Scrollable = $true; MultiSelect = $false; HideSelection = $true }
[void]$facts.Columns.Add('', [int](30 * $DPIK)); [void]$facts.Columns.Add('', [int](98 * $DPIK)); [void]$facts.Columns.Add('', [int](270 * $DPIK))
$script:factNo = 0
$tMe.Controls.Add($facts)
# 1.18 (user, 05-Nov-2026: "give every point a serial number"): No. | what | value - every row numbered 1, 2, 3 ...
# 1.24 (user, 05-Nov-2026: "I renamed the PC to B1 but it still shows the other name"): the tray showed only the WINDOWS name (changes at a Thawed restart).
# Now the Console name (what you typed) comes first, the Windows name next to it, and a line says when Windows will change
function PcNames { $p = J 'pc.json'; $cn = if ($p -and $p.name) { [string]$p.name } else { $env:COMPUTERNAME }; @{ con = $cn; win = $env:COMPUTERNAME; same = ($cn -eq $env:COMPUTERNAME) } }
function FactSafe([scriptblock]$b) { try { . $b } catch { try { FactRow 'Error' ([string]$_.Exception.Message) $CL.er } catch {} } }   # 1.37: one row, its own error (NOT 'R' - that is PowerShell's alias for Invoke-History)
function FactRow([string]$lab, [string]$val, $col) { $script:factNo++; $it = New-Object Windows.Forms.ListViewItem([string]$script:factNo); $it.UseItemStyleForSubItems = $false; $it.ForeColor = $CL.ac
  [void]$it.SubItems.Add($lab); [void]$it.SubItems.Add($val); $it.SubItems[1].ForeColor = $CL.mu; $it.SubItems[2].ForeColor = $(if ($col) { $col } else { $CL.tx }); [void]$facts.Items.Add($it) }
function Btn($t, $x, $yy, $w, $on) { $b = New-Object Windows.Forms.Button -Property @{ Text = $t; Left = $x; Top = $yy; Width = $w; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $b.FlatAppearance.BorderColor = $CL.bd; $b.Add_Click($on); $tMe.Controls.Add($b); $b }
$by = $y + 304   # 1.17: buttons right under the facts list
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
# 1.39 (user, 05-Nov-2026: "give a Refresh option so any new change shows with that refresh"): fresh readings now (network, temperature, the whole list)
# within ~15 s + a check for a newer PC Doctor (installs by itself, progress on the Updates tab); the window re-reads every 3 s for 30 s
$script:rfUntil = [datetime]::MinValue
$trf = New-Object Windows.Forms.Timer -Property @{ Interval = 3000 }; $trf.Add_Tick({ try { Refresh } catch {}; try { UpdRefresh } catch {}; if ((Get-Date) -gt $script:rfUntil) { $trf.Stop(); $msg.Text = 'Refreshed ' + (Get-Date).ToString('h:mm:ss tt') + '.' } })
function RefreshNow { try { Set-Content "$Rq\refresh.flag" '1'; Set-Content "$Rq\update.flag" '1' } catch {}
  $script:rfUntil = (Get-Date).AddSeconds(30); $msg.Text = 'Refreshing - new readings within about 15 s; a newer PC Doctor (if any) installs by itself.'; $trf.Start() }
Btn 'Refresh' 12 ($by + 108) 206 { RefreshNow } | Out-Null
Btn 'Open Console' 222 ($by + 108) 210 { OpenConsole } | Out-Null
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
# 1.21 (user, 05-Nov-2026: "the web app takes time to check and reply - if I have this option in the tray it is super easy"): Super Admin laptop,
# All PCs tab: pick one or more PCs, then "How much it frees" (read-only), "Clean now" (deletes - list + password), "Delete old history"
# (count first, then list + password). The agent does the sending (worker /lab/cmd, /lab/purge); the answer comes back here within seconds.
$script:labAt = 0; $script:purgeAsk = $null
function LabSel { @($grid.SelectedItems | ForEach-Object { [string]$_.Tag } | Where-Object { $_ }) }
function LabNames { @($grid.SelectedItems | ForEach-Object { ([string]$_.Text -replace '^\S+\s+', '') }) }
function LabSend([string]$kind) {
  $sel = @(LabSel); if (!$sel.Count) { $script:labBox.Text = 'Tap a PC in the list first (Ctrl or Shift for several).'; return }
  $pw = ''
  if ($kind -eq 'clean') {
    $ok = [Windows.Forms.MessageBox]::Show("Run Clean now on: " + ((LabNames) -join ', ') + " ?`r`n`r`nIt deletes: caches, old Android Studio settings folders (the newest stays), project build folders, emulator images no virtual phone uses, extra virtual phones. It never touches your source code or the SDK.`r`n`r`nTip: tap 'How much it frees' first.", 'PC Doctor - Clean now', 'YesNo', 'Warning')
    if ($ok -ne 'Yes') { return }
    $pw = PwText 'cleaning the PCs'; if ($null -eq $pw) { return }
  }
  W 'labcmd.json' @{ op = 'send'; kind = $kind; pcs = $sel; pw = $pw; who = $env:USERNAME }
  $script:labAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $script:labBox.Text = 'Sent to ' + $sel.Count + ' PC(s) - waiting for the answer ...'; $tl.Start()
}
function LabPurge {
  $sel = @(LabSel); if (!$sel.Count) { $script:labBox.Text = 'Tap a PC in the list first (Ctrl or Shift for several).'; return }
  $script:purgeAsk = @{ pcs = $sel; days = 30 }
  W 'labcmd.json' @{ op = 'purge'; dry = $true; days = 30; pcs = $sel; who = $env:USERNAME }
  $script:labAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $script:labBox.Text = 'Counting old history (older than 30 days) ...'; $tl.Start()
}
function LabUi {
  $x = J 'labres.json'; $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  if (!$x -or !$script:labAt -or [int64]$x.t -lt $script:labAt) { if ($script:labAt -and ($now - $script:labAt) -gt 120000) { $script:labBox.Text = 'No answer in 2 minutes - the laptop agent may be busy. Tap again.'; $script:labAt = 0; $tl.Stop() }; return }
  if (!$x.ok) { $script:labBox.Text = [string]$x.msg; $script:labAt = 0; $tl.Stop(); return }
  if ([string]$x.op -eq 'purge') {
    $ev = 0; $rs = 0; $ln = @(); foreach ($w in @($x.rows)) { $ev += [int]$w.events; $rs += [int]$w.res; $ln += ([string]$w.pc + ':  ' + $w.events + ' old reports/events,  ' + $w.res + ' old answers') }
    $script:labBox.Text = $(if ($x.dry) { 'Older than ' + $x.days + ' days:' } else { 'Deleted (older than ' + $x.days + ' days):' }) + "`r`n" + ($ln -join "`r`n"); $script:labAt = 0; $tl.Stop()
    if ($x.dry -and $script:purgeAsk) { $pa = $script:purgeAsk; $script:purgeAsk = $null
      if (($ev + $rs) -eq 0) { $script:labBox.Text += "`r`n`r`nNothing old enough to delete."; return }
      $ok = [Windows.Forms.MessageBox]::Show("Delete $ev old reports/events and $rs old answers (older than $($x.days) days) of the chosen PC(s)?`r`n`r`nThe PCs' current data and the last $($x.days) days stay. This cannot be undone.", 'PC Doctor - delete old history', 'YesNo', 'Warning')
      if ($ok -eq 'Yes') { $pw = PwText 'deleting old history'; if ($null -ne $pw) { W 'labcmd.json' @{ op = 'purge'; dry = $false; days = $pa.days; pcs = $pa.pcs; pw = $pw; who = $env:USERNAME }
          $script:labAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $script:labBox.Text = 'Deleting ...'; $tl.Start() } } }
    return }
  $lines = @(@($x.rows) | ForEach-Object { [string]$_.pc + '  -  ' + $(switch ([string]$_.st) { 'done' { 'done' } 'failed' { 'FAILED' } 'running' { 'running on the PC ...' } default { 'waiting for the PC (it looks every 14 s) ...' } }) + $(if ($_.txt) { "`r`n      " + $_.txt } else { '' }) })
  $script:labBox.Text = ($lines -join "`r`n"); if ($x.done) { $script:labAt = 0; $tl.Stop() }
}
$tl = New-Object Windows.Forms.Timer -Property @{ Interval = 2000 }; $tl.Add_Tick({ try { LabUi } catch {} })
# 1.22 (user, 05-Nov-2026: "which of the 30 PCs am I working on from the web? a pop-up on the PC when I press it"): the Console's "Show me this PC"
# (and opening Remote screen) makes the agent write state\identify.json; this PC shows its name BIG on its own screen for 10 seconds, with a sound
# 1.25: the tray tells the agent which file it runs (sha) - the agent replaces a tray that runs an OLDER file (A-TrayFresh)
try { @{ t = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); sha = (Get-FileHash "$Root\bin\tray.ps1" -Algorithm SHA256).Hash; pid = $PID } | ConvertTo-Json -Compress | Set-Content "$Rq\tray_run.json" -Encoding UTF8 } catch {}
$script:idSeen = 0; try { $i0 = J 'identify.json'; if ($i0) { $script:idSeen = [int64]$i0.t } } catch {}
function IdentifyShow($nm, $by) {
  $f = New-Object Windows.Forms.Form -Property @{ FormBorderStyle = 'None'; StartPosition = 'CenterScreen'; Width = 620; Height = 270; TopMost = $true; ShowInTaskbar = $false; BackColor = $CL.ac }
  $in = New-Object Windows.Forms.Panel -Property @{ Left = 6; Top = 6; Width = 608; Height = 258; BackColor = $CL.bg }
  $l1 = New-Object Windows.Forms.Label -Property @{ Text = 'THIS PC IS'; Left = 0; Top = 16; Width = 608; Height = 30; TextAlign = 'MiddleCenter'; Font = (New-Object Drawing.Font('Segoe UI Semibold', 14)); ForeColor = $CL.mu }
  $l2 = New-Object Windows.Forms.Label -Property @{ Text = [string]$nm; Left = 0; Top = 50; Width = 608; Height = 110; TextAlign = 'MiddleCenter'; Font = (New-Object Drawing.Font('Segoe UI Semibold', 66)); ForeColor = $CL.ac }
  $l3 = New-Object Windows.Forms.Label -Property @{ Text = ('Windows name ' + $env:COMPUTERNAME + '  -  the Super Admin is working on this PC from the Console'); Left = 0; Top = 180; Width = 608; Height = 28; TextAlign = 'MiddleCenter'; Font = $FT.n; ForeColor = $CL.tx }
  $l4 = New-Object Windows.Forms.Label -Property @{ Text = 'stays here until you click it, or the Super Admin taps Hide on the Console'; Left = 0; Top = 218; Width = 608; Height = 24; TextAlign = 'MiddleCenter'; Font = $FT.s; ForeColor = $CL.mu }
  $in.Controls.AddRange(@($l1, $l2, $l3, $l4)); $f.Controls.Add($in)
  foreach ($c2 in $f, $in, $l1, $l2, $l3, $l4) { $c2.Add_Click({ try { $this.FindForm().Close() } catch {} }) }   # handlers run after this function has ended: no local variables in them
  if ($DPIK -gt 1.01) { $f.Scale((New-Object Drawing.SizeF($DPIK, $DPIK))) }
  try { if ($script:idForm) { $script:idForm.Close() } } catch {}; $script:idForm = $f; try { [Media.SystemSounds]::Exclamation.Play() } catch {}
  $f.Show(); $f.Activate(); if (!$script:idTimer) { $script:idTimer = New-Object Windows.Forms.Timer -Property @{ Interval = 21600000 }; $script:idTimer.Add_Tick({ $script:idTimer.Stop(); try { $script:idForm.Close() } catch {} }) }; $script:idTimer.Stop(); $script:idTimer.Start()
}
$ti = New-Object Windows.Forms.Timer -Property @{ Interval = 2000 }
$ti.Add_Tick({ try { $x1 = J 'identify.json'; if ($x1 -and [int64]$x1.t -gt $script:idSeen) { $script:idSeen = [int64]$x1.t
      if ($x1.off) { try { if ($script:idForm) { $script:idForm.Close() } } catch {} } elseif (([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - [int64]$x1.t) -lt 90000) { IdentifyShow ([string]$x1.name) ([string]$x1.by) } } } catch {} })
$ti.Start()
function LaptopTabs {
  if ($tGrid) { return }
  $script:tGrid = New-Object Windows.Forms.TabPage -Property @{ Text = 'All PCs'; BackColor = $CL.bg }
  $script:grid = New-Object Windows.Forms.ListView -Property @{ Left = 10; Top = 8; Width = 422; Height = 290; MultiSelect = $true; HideSelection = $false; View = 'Details'; FullRowSelect = $true; BackColor = $CL.bg; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None' }
  foreach ($c in @(@('PC', 70), @('Group', 90), @('State', 230))) { [void]$grid.Columns.Add($c[0], $c[1]) }
  $bHow = New-Object Windows.Forms.Button -Property @{ Text = 'How much it frees'; Left = 10; Top = 304; Width = 136; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $bCl = New-Object Windows.Forms.Button -Property @{ Text = 'Clean now'; Left = 150; Top = 304; Width = 120; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $bPu = New-Object Windows.Forms.Button -Property @{ Text = 'Delete old history'; Left = 274; Top = 304; Width = 158; Height = 30; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  $script:labBox = New-Object Windows.Forms.TextBox -Property @{ Left = 10; Top = 340; Width = 422; Height = 150; Multiline = $true; ReadOnly = $true; ScrollBars = 'Vertical'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s; BorderStyle = 'None'; Text = 'Tap a PC above (Ctrl / Shift for several), then a button. The answer shows here within seconds.' }
  $bCp = New-Object Windows.Forms.Button -Property @{ Text = 'Copy'; Left = 10; Top = 496; Width = 100; Height = 28; FlatStyle = 'Flat'; BackColor = $CL.card; ForeColor = $CL.tx; Font = $FT.s }
  foreach ($bb in $bHow, $bCl, $bPu, $bCp) { $bb.FlatAppearance.BorderColor = $CL.bd }
  $bHow.Add_Click({ LabSend 'clean_plan' }); $bCl.Add_Click({ LabSend 'clean' }); $bPu.Add_Click({ LabPurge }); $bCp.Add_Click({ try { [Windows.Forms.Clipboard]::SetText($script:labBox.Text) } catch {} })
  $tGrid.Controls.AddRange(@($grid, $bHow, $bCl, $bPu, $script:labBox, $bCp)); $tabs.TabPages.Add($tGrid)
  foreach ($x in $grid, $bHow, $bCl, $bPu, $script:labBox, $bCp) { $x.Scale((New-Object Drawing.SizeF($DPIK, $DPIK))) }
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
[void]$menu.Items.Add('Open Console', $null, { OpenConsole })
[void]$menu.Items.Add('Check now', $null, { Set-Content "$Rq\now.flag" '1' })
[void]$menu.Items.Add('⬆ Update now', $null, { UpdNow; OpenWin; $tabs.SelectedTab = $tUp })
[void]$menu.Items.Add('Copy report', $null, { if ($script:unlocked -or (Pw 'copying the report')) { [Windows.Forms.Clipboard]::SetText((Report)) } })
$ni.ContextMenuStrip = $menu
$ni.Add_MouseClick({ if ($_.Button -eq 'Left') { try { if (!$script:unlocked) { $ni.ShowBalloonTip(4000, ('PC Doctor ' + (VerTxt)), [string]$script:verdictTxt, 'Info') } } catch {}; OpenWin } })
$form.Add_FormClosing({ if ($_.CloseReason -eq 'UserClosing') { $_.Cancel = $true; $form.Hide(); $script:unlocked = $false } })   # closing never stops anything
$seen = @{}; $lastLv = ''
function Refresh {
  $n = J 'now.json'; $v = J 'verdict.json'
  if (!$n) { $head.Text = 'PC Doctor - starting'; $verd.Text = 'The PC Doctor Agent has not written its first check yet (about a minute after start).'; return }
  $lv = if ($v) { [string]$v.lv } else { 'green' }; $e = $LVL[$lv]; if (!$e) { $e = $LVL.green }
  $pn = PcNames; $head.Text = $e[0] + ' ' + $pn.con + ' - ' + $(if ($v) { $v.v } else { 'checking' }); $head.ForeColor = $e[1]
  $verd.Text = $(if ($v) { $v.why + "  (" + $v.conf + "% sure)" } else { '' })
  foreach ($k in 'cpu','ram','busy','cfree') { $x = [int]$n.$k; $bars[$k][0].Value = [math]::Max(0, [math]::Min(100, $x)); $bars[$k][1].Text = "$x%" }
  $run = J 'running.json'; $iv = J 'inv.json'
  # 1.36 (user, 05-Nov-2026: "no data is showing now" - one failing row left the WHOLE list blank: BeginUpdate without EndUpdate): the list is always finished,
  # and a row that fails shows its error text in red instead of hiding everything
  # 1.37 (user, 05-Nov-2026: the Sony showed 'Error: Cannot compare "" to "0"' after Temperature and nothing else): EVERY row runs on its own (R) - a bad
  # value breaks only its own row; numbers from now.json are taken only when they really are numbers (an empty list came back as an object)
  $facts.BeginUpdate(); try { $facts.Items.Clear(); $script:factNo = 0
  $tmpC = $(if ($n.temp -is [ValueType]) { [double]$n.temp } else { $null }); $v12n = $(if ($n.v12 -is [ValueType]) { [double]$n.v12 } else { $null }); $fl = @(@($n.fans) | Where-Object { $_ -is [ValueType] } | ForEach-Object { [int]$_ })
  FactSafe { FactRow 'Name' $(if ($pn.same) { $pn.con } else { $pn.con + '  (Console name)' }) $CL.ac }
  FactSafe { if (!$pn.same) { FactRow 'Windows name' ($pn.win + '  ->  ' + $pn.con + ' after a Thawed restart') $CL.wa } }
  # 1.35 (user, 05-Nov-2026): CPU temperature + fan speed + 12 V (the three that tell overheating from a weak power supply), or WHY they are missing
  FactSafe { FactRow 'Temperature' $(if ($tmpC) { 'CPU ' + [string]$tmpC + ' °C' } elseif ($n.tnote) { 'not yet - ' + [string]$n.tnote } else { 'not available (the board gives no reading)' }) $(if ($tmpC -ge 85) { $CL.er } elseif ($tmpC -ge 75) { $CL.wa } else { $null }) }
  FactSafe { if ($fl.Count -or $v12n) { FactRow 'Fan / power' ($(if ($fl.Count) { 'fans ' + ($fl -join ' / ') + ' rpm' } else { 'fans: not reported' }) + '   ·   12 V line ' + $(if ($v12n) { [string]$v12n + ' V' } else { 'not reported' })) $(if (($v12n -and $v12n -lt 11.4) -or ($fl.Count -and !($fl | Where-Object { $_ -gt 0 }))) { $CL.wa } else { $null }) } }
  $dfT = $(if ($n.df -eq 'thawed') { 'Thawed' } elseif ($n.df -eq 'frozen') { 'Frozen' } else { 'No Deep Freeze on this PC' }); $dfW = ($n.thawQ -and $n.df -ne 'none')
  FactSafe { FactRow 'Deep Freeze' ($dfT + $(if ($dfW) { "  -  Thaw needed: $($n.thawQ) fix" + $(if ($n.thawQ -ne 1) { 'es' }) } else { '' })) $(if ($dfW) { $CL.wa } else { $null }) }
  # 1.36 (user, 05-Nov-2026: "Internet OK - show Wi-Fi or LAN and the download speed"): connection type, Wi-Fi name + signal, link speed, measured download speed
  $nt = $n.nt
  FactSafe { FactRow 'Internet' ($(if ($n.online) { 'OK' } else { 'No internet - saved, sends later' }) + $(if ($nt -and $nt.type) { '   ·   ' + [string]$nt.type + $(if ($nt.ssid) { ' "' + [string]$nt.ssid + '"' } else { '' }) + $(if ($nt.sig) { ' ' + [string]$nt.sig + '%' } else { '' }) + $(if ($nt.link) { '   ·   link ' + [string]$nt.link } else { '' }) + $(if ($nt.also) { '   (' + [string]$nt.also + ' also on)' } else { '' }) } else { '' })) $(if ($n.online) { $CL.ok } else { $CL.wa }) }
  FactSafe { if ($nt -and ($nt.dl -or $nt.dlErr)) { FactRow 'Download' $(if ($nt.dl) { [string]$nt.dl + ' Mbps   (tested ' + (IST $nt.dlAt) + ')' } else { 'test failed: ' + [string]$nt.dlErr }) $(if ($nt.dl -and $nt.dl -lt 2) { $CL.wa } else { $null }) } }
  FactSafe { FactRow 'Last sent' ((IST $n.t) + $(if ($n.q) { "   ($($n.q) waiting)" } else { '' })) }
  FactSafe { FactRow 'C: drive' "$($n.cfreeGB) GB free   ·   answers in $($n.lat) ms" }
  FactSafe { $rt = @($n.rtop); for ($k = 0; $k -lt $rt.Count; $k++) { FactRow $(if ($k -eq 0) { 'RAM used by' } else { '' }) ([string]$rt[$k].n + '   ' + $(if ($rt[$k].m -ge 1024) { [string][math]::Round($rt[$k].m / 1024, 1) + ' GB' } else { [string]$rt[$k].m + ' MB' }) + $(if ($rt[$k].k -gt 1) { '   (' + $rt[$k].k + ' copies)' } else { '' })) } }
  FactSafe { FactRow 'PC Doctor' (($(if ($run -and $run.ver) { 'v' + $run.ver + ' (build ' + $run.build + ')' } else { 'v' + $n.ver })) + $(if ($n.user) { '   ·   user ' + $n.user } else { '' })) }
  FactSafe { if ($iv -and $iv.battery) { FactRow 'Battery' "health $($iv.battery.health)%   ($($iv.battery.cycles) cycles)" } }
  FactSafe { if ($iv -and $iv.disks) { $dk = @($iv.disks); for ($k = 0; $k -lt $dk.Count; $k++) { FactRow $(if ($k -eq 0) { 'Disk health' } else { '' }) ($dk[$k].model + '   ' + $dk[$k].health) } } }
  $wk = if ($v -and $v.all) { @($v.all) } else { @() }
  FactSafe { if (!$wk.Count) { FactRow 'Last 7 days' 'Nothing found' $CL.ok } else { for ($k = 0; $k -lt $wk.Count; $k++) { $wl = $LVL[[string]$wk[$k].lv]; if (!$wl) { $wl = $LVL.green }; FactRow $(if ($k -eq 0) { 'Last 7 days' } else { '' }) ($wl[0] + ' ' + $wk[$k].v) $wl[1] } } }
  } catch { try { FactRow 'Error' ([string]$_.Exception.Message) $CL.er } catch {} } finally { $facts.EndUpdate() }
  $tt = ('PC Doctor ' + (VerTxt) + ' - ' + $(if ($v) { $v.v } else { '' })); $ni.Text = $tt.Substring(0, [math]::Min(63, $tt.Length)); $script:verdictTxt = $(if ($v) { [string]$v.v } else { '' })
  if ($lv -ne $lastLv) { $ni.Icon = Ico $e[1]; $script:lastLv = $lv }
  $un = J 'uninst.json'; if ($un -and $script:unAsked -and [int64]$un.t -ge $script:unAsked) { $script:unAsked = 0; $msg.Text = [string]$un.msg }
  $u = J 'usb.json'; if ($u -and $u.t -gt $seen.usb) { $seen.usb = $u.t; $msg.Text = $(if ($u.ok) { 'Saved: ' + $u.file } else { 'No pendrive found - plug one in and try again.' }) }
  $x = J 'usbfix.json'; if ($x -and $x.t -gt $seen.fix) { $seen.fix = $x.t; $msg.Text = $(if ($x.ok) { 'Done: ' + ((@($x.done) | ForEach-Object { $_.file + $(if ($_.ok) { ' ✅' } else { ' ❌' }) }) -join ', ') + ' - result saved on the pendrive' } else { 'No fix pendrive (DavanFix\fix.json) found.' }) }
  # Super Admin laptop
  $g = J 'grid.json'
  if ($g -and $g.now) {
    LaptopTabs; $selH = @($grid.SelectedItems | ForEach-Object { [string]$_.Tag }); $grid.BeginUpdate(); $grid.Items.Clear(); $cfg = J 'cfg.json'; $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $rows = foreach ($p in $g.now.PSObject.Properties) { $pc = $g.pcs.($p.Name); if ($pc.old) { continue }; $r = $p.Value
      $l = if (($nowMs - [int64]$r.t) -gt 30 * 60000) { 'off' } else { [string]$r.lv }; [pscustomobject]@{ h = $p.Name; n = [string]$(if ($pc.name) { $pc.name } else { $r.name }); g = [string]$pc.grp; lv = $l; v = [string]$r.v } }
    foreach ($r in ($rows | Sort-Object g, @{ e = { [regex]::Replace($_.n, '\d+', { $args[0].Value.PadLeft(4, '0') }) } })) {
      $gn = if ($cfg -and $cfg.groups.($r.g)) { $cfg.groups.($r.g).name } else { $r.g }
      $it = New-Object Windows.Forms.ListViewItem(($LVL[$r.lv][0] + ' ' + $r.n)); [void]$it.SubItems.Add($gn); [void]$it.SubItems.Add($(if ($r.lv -eq 'off') { 'off / not reporting' } else { $r.v })); $it.ForeColor = $LVL[$r.lv][1]; $it.Tag = $r.h; if ($selH -contains [string]$r.h) { $it.Selected = $true }; [void]$grid.Items.Add($it)
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
# 1.43 (user, 05-Nov-2026: "every few minutes PC Doctor restarts and asks for the password"): the tray restarted on EVERY agent build (running.json build = agent build),
# and there were several that day. Now it restarts only when ITS OWN file (bin\tray.ps1) changed.
function TrayId { try { (Get-FileHash "$Root\bin\tray.ps1" -Algorithm SHA1 -ErrorAction Stop).Hash } catch { '' } }
$script:myBuild = TrayId
function SelfUpdate { $b = TrayId
  # 1.23 (user, 05-Nov-2026: "Show me this PC is not working" - this window had been open since before the update, so the OLD tray was still running):
  # a tray with its window open used to wait for the window to be closed, for ever. Now it says so, waits about 45 s and restarts itself, window open again
  $show = $false
  if ($b -and $script:myBuild -and $b -ne $script:myBuild -and $form.Visible) { $script:selfWait++; $msg.Text = 'A new PC Doctor tray is ready - this window restarts in about ' + [math]::Max(0, 45 - 15 * $script:selfWait) + ' s (the password is asked again).'; if ($script:selfWait -ge 3) { $show = $true } } else { $script:selfWait = 0 }
  if ($b -and $script:myBuild -and $b -ne $script:myBuild -and (!$form.Visible -or $show) -and (Test-Path "$Root\bin\tray.ps1")) {
    $ni.Visible = $false; try { $mtx.ReleaseMutex(); $mtx.Dispose() } catch {}
    if (Test-Path "$Root\tray-start.vbs") { Start-Process wscript.exe -ArgumentList ("`"$Root\tray-start.vbs`" " + $(if ($show) { '/show' } else { '/now' })) } else { Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Root\bin\tray.ps1`"" }
    [Environment]::Exit(0) } }
$tm = New-Object Windows.Forms.Timer -Property @{ Interval = 15000 }; $tm.Add_Tick({ try { Refresh } catch {}; try { UpdRefresh } catch {}; try { NotesLoad } catch {}; try { FxLoad; FxCredAuto } catch {}; try { if (!$tp.Enabled) { $pp = J 'updp.json'; if ($pp -and ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - [int64]$pp.t) -lt 300000) { $tp.Start() } } } catch {}; try { SelfUpdate } catch {} }); $tm.Start()
try { Refresh } catch {}; try { UpdRefresh } catch {}; try { NotesLoad } catch {}; try { FxLoad } catch {}
Sharp $form; Corner
if ($args -contains '-show') { OpenWin }
# Windows test (GitHub runner): draw every tab + the "Show me this PC" pop-up into PNG files (PDT_OUT) so the layout can be LOOKED AT before a release
if ($args -contains '-selftest') {
  $out = $env:PDT_OUT; New-Item -ItemType Directory -Force $out | Out-Null; $script:unlocked = $true
  $form.StartPosition = 'Manual'; $form.Left = 10; $form.Top = 10; $form.Show(); [Windows.Forms.Application]::DoEvents()
  try { FxLoad; if ($fxList.Items.Count) { $fxList.Items[0].Selected = $true } } catch { Set-Content "$out\error-fixes.txt" ($_ | Out-String) }
  try { Refresh } catch { Set-Content "$out\error-refresh.txt" ($_ | Out-String) }; try { UpdRefresh } catch { Set-Content "$out\error-upd.txt" ($_ | Out-String) }; [Windows.Forms.Application]::DoEvents()
  function Shot([Windows.Forms.Control]$c, [string]$name) { try { $b = New-Object Drawing.Bitmap $c.Width, $c.Height; $c.DrawToBitmap($b, (New-Object Drawing.Rectangle 0, 0, $c.Width, $c.Height)); $b.Save("$out\$name.png", [Drawing.Imaging.ImageFormat]::Png); $b.Dispose() } catch { Set-Content "$out\error-$name.txt" ($_ | Out-String) } }
  foreach ($tp0 in @($tabs.TabPages)) { $tabs.SelectedTab = $tp0; [Windows.Forms.Application]::DoEvents(); Shot $form ('tab-' + ($tp0.Text -replace '[^A-Za-z0-9]', '')) }
  # 1.45: a text layout check per tab (cheap to read from the log): each control, its box, text cut off (wider than its box), overlaps, off the tab
  foreach ($tp0 in @($tabs.TabPages)) { $tabs.SelectedTab = $tp0; [Windows.Forms.Application]::DoEvents(); $ly = @('tab ' + $tp0.Text + ' ' + $tp0.ClientSize.Width + 'x' + $tp0.ClientSize.Height); $cs = @($tp0.Controls)
    foreach ($c2 in $cs) { $tw = if ($c2 -is [Windows.Forms.Button] -or $c2 -is [Windows.Forms.Label]) { [Windows.Forms.TextRenderer]::MeasureText([string]$c2.Text, $c2.Font).Width } else { 0 }
      $fl = @(); if ($tw -gt $c2.Width -and ($c2 -is [Windows.Forms.Button] -or ($c2 -is [Windows.Forms.Label] -and $c2.Height -lt 2 * $c2.Font.Height))) { $fl += 'TEXT-CUT(' + $tw + '>' + $c2.Width + ')' }
      if ($c2.Right -gt $tp0.ClientSize.Width -or $c2.Bottom -gt $tp0.ClientSize.Height) { $fl += 'OFF-TAB' }
      foreach ($c3 in $cs) { if ($c3 -ne $c2 -and $c2.Visible -and $c3.Visible -and $c2.Bounds.IntersectsWith($c3.Bounds)) { $fl += 'OVERLAP:' + ([string]$c3.Text).Substring(0, [math]::Min(14, ([string]$c3.Text).Length)) } }
      $ly += ('  ' + $c2.GetType().Name + ' [' + ([string]$c2.Text -replace "`r?`n", ' ').Substring(0, [math]::Min(34, ([string]$c2.Text).Length)) + '] ' + $c2.Left + ',' + $c2.Top + ' ' + $c2.Width + 'x' + $c2.Height + ' ' + ($fl -join ' ')) }
    if ($tp0 -eq $tFx) { $ly += '  list rows: ' + $fxList.Items.Count + ' | head: ' + $fxHead.Text + ' | info: ' + ($fxInfo.Text -replace "`r?`n", ' / ').Substring(0, [math]::Min(300, $fxInfo.Text.Length)) + ' | buttons on: ' + ((@($fxRun, $fxOk, $fxNot, $fxUndo, $fxCp, $fxCpU, $fxSolved, $fxCpAll) | Where-Object Enabled | ForEach-Object { $_.Text }) -join ', ') }
    Set-Content ("$out\layout-" + ($tp0.Text -replace '[^A-Za-z0-9]', '') + '.txt') ($ly -join "`n") }
  try { IdentifyShow 'B1' 'Super Admin'; [Windows.Forms.Application]::DoEvents(); Shot $script:idForm 'identify-popup' } catch { Set-Content "$out\error-identify.txt" ($_ | Out-String) }
  [Environment]::Exit(0)
}
[Windows.Forms.Application]::Run()
