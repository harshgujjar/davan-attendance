# Davan PC Doctor - dlh.ps1 (ROADMAP-pcdoctor.md 9): offline report to a pendrive + fixes from a pendrive.
# <NAME>_<yyyy-mm-dd_hhmm>.dlh = a zip: info.json (fingerprint, inventory, verdict, now), queue.jsonl (rows not sent yet), ring.json
# (last minutes), events.json, smart.json, evtx\ (System, Application, PrintService, Diagnostics-Performance), dumps\ (minidumps).
# The Console's 📥 Import reads it (JSZip) and uploads it to DB5 like an online PC.
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
function PD-MakeDlh([string]$destDir, [switch]$Offline) {
  New-Item -ItemType Directory -Force $destDir | Out-Null
  $ist = [DateTime]::UtcNow.AddHours(5.5)
  $name = $env:COMPUTERNAME + '_' + $ist.ToString('yyyy-MM-dd_HHmm') + '.dlh'
  $tmp = Join-Path $env:TEMP ('dlh_' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force "$tmp\evtx","$tmp\dumps" | Out-Null
  $id = PD-ReadJson (Join-Path $PD.Root 'id.json')
  $info = @{ v = 1; made = (PD-NowMs); madeIST = (PD-IST (PD-NowMs)); name = $env:COMPUTERNAME; hwid = $(if ($id) { $id.hwid } else { '' }); fp = (PD-Fingerprint)
             now = (PD-ReadJson (Join-Path $PD.Root 'state\now.json')); verdict = (PD-ReadJson (Join-Path $PD.Root 'state\verdict.json')); pc = (PD-ReadJson (Join-Path $PD.Root 'state\pc.json'))
             inv = (PD-ReadJson (Join-Path $PD.Root 'state\inv.json')); offline = [bool]$Offline; ver = (PD-AgentVer) }
  if (!$info.inv) { try { $info.inv = PD-Inventory } catch {} }
  PD-WriteJson "$tmp\info.json" $info
  Copy-Item (Join-Path $PD.Root 'state\ring.json') "$tmp\ring.json" -ErrorAction SilentlyContinue
  $q = @(); $qf = PD-QueueFile; if ($qf -and (Test-Path $qf)) { $q += Get-Content $qf -Encoding UTF8 }; $q += @($PD.Queue)
  Set-Content "$tmp\queue.jsonl" $q -Encoding UTF8
  try { PD-WriteJson "$tmp\events.json" @(PD-ReadEvents (Get-Date).AddDays(-14) 200) } catch {}
  try { PD-WriteJson "$tmp\smart.json" @(PD-Smart) } catch {}
  try { PD-WriteJson "$tmp\checks.json" @{ startup = (PD-Startup); bsod = (PD-Bsod 60); prn = (PD-PrintCheck); sfc = (PD-SfcState) } } catch {}
  foreach ($l in 'System','Application','Microsoft-Windows-PrintService/Admin','Microsoft-Windows-Diagnostics-Performance/Operational') {
    $f = "$tmp\evtx\" + ($l -replace '[\\/]','_') + '.evtx'; wevtutil epl $l $f "/q:*[System[TimeCreated[timediff(@SystemTime) <= 1209600000]]]" 2>$null }
  Get-ChildItem "$env:SystemRoot\Minidump\*.dmp" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | Copy-Item -Destination "$tmp\dumps" -ErrorAction SilentlyContinue
  $out = Join-Path $destDir $name; if (Test-Path $out) { Remove-Item $out -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($tmp, $out)
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  # once saved, the queued rows are on the pendrive: the Console uploads them, so they are not sent twice
  if ($qf -and (Test-Path $qf)) { Remove-Item $qf -Force }; $PD.Queue.Clear()
  $out
}
# 🔧 Fix from pendrive: <USB>\DavanFix\fix.json {made, by, scripts: [{file, sha256, label}], hash} made by the Console's 💾 Make fix pendrive.
# Only scripts whose SHA-256 matches the list run; results go to <USB>\DavanFix\result_<NAME>_<time>.json for 📥 Import.
function PD-RunUsbFix([string]$drive, [switch]$Asked) {
  $dir = "$drive\DavanFix"; $m = PD-ReadJson "$dir\fix.json"; if (!$m) { return $null }
  if (!$Asked -and !$m.auto) { return $null }   # the tray's 🔧 Fix from pendrive asks for the password first; auto only when the Console said so
  if ($m.only -and @($m.only) -notcontains $env:COMPUTERNAME) { return $null }
  $done = @()
  foreach ($s in @($m.scripts)) {
    $f = Join-Path $dir $s.file
    if (!(Test-Path $f) -or (PD-Sha256File $f) -ne $s.sha256) { $done += @{ file = $s.file; ok = $false; txt = 'refused - file changed or missing' }; continue }
    try { $o = & powershell -NoProfile -ExecutionPolicy Bypass -File $f 2>&1 | Out-String; $done += @{ file = $s.file; label = $s.label; ok = ($LASTEXITCODE -eq 0); txt = $o.Substring(0, [math]::Min(2000, $o.Length)) } }
    catch { $done += @{ file = $s.file; ok = $false; txt = $_.Exception.Message } }
  }
  foreach ($x in @($m.drivers)) { $p = Join-Path $dir $x; Get-ChildItem $p -Recurse -Filter *.inf -ErrorAction SilentlyContinue | ForEach-Object { $o = pnputil /add-driver $_.FullName /install 2>&1 | Out-String; $done += @{ file = $_.Name; ok = $true; txt = 'driver: ' + ($o -split "`n" | Select-Object -Last 3) -join ' ' } } }
  foreach ($x in @($m.updates)) { $p = Join-Path $dir $x; if ($p -match '\.msu$') { $r = Start-Process wusa.exe "`"$p`" /quiet /norestart" -Wait -PassThru; $done += @{ file = $x; ok = ($r.ExitCode -in 0,3010); txt = 'update code ' + $r.ExitCode } } }
  $ist = [DateTime]::UtcNow.AddHours(5.5).ToString('yyyy-MM-dd_HHmm')
  PD-WriteJson "$dir\result_$($env:COMPUTERNAME)_$ist.json" @{ name = $env:COMPUTERNAME; t = (PD-NowMs); done = $done; made = $m.made }
  $done
}
