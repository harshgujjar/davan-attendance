# Davan PC Doctor - checks.ps1: minute sample, Windows event watch, daily inventory, deep checks, BSOD, startup, verdict (rules in lab/cfg).
# Everything reads Windows' own data; nothing here changes the PC.

# ---------- minute sample (6: CPU, RAM, disk busy, latency, queue, hard faults, top 5, temperature, network) ----------
$script:NetPrev = $null
function PD-Sample {
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
  $mem = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
  $dk = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'"
  $procs = @(Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | Where-Object { $_.Name -notin '_Total','Idle' })
  $ncpu = [Environment]::ProcessorCount
  $top = @()
  $top += $procs | Sort-Object PercentProcessorTime -Descending | Select-Object -First 5 | ForEach-Object { @{ n = ($_.Name -replace '#\d+$',''); c = [math]::Round($_.PercentProcessorTime / $ncpu, 1); m = [math]::Round($_.WorkingSetPrivate / 1MB); io = [math]::Round($_.IODataBytesPersec / 1KB) } }
  # 05-Nov-2026 (user: "why is 1DAVAN on 95% RAM"): RAM per PROGRAM (all its copies added: Firefox / Chrome run many) - not per copy
  $ramTop = $procs | Group-Object { $_.Name -replace '#\d+$','' } | ForEach-Object { @{ n = $_.Name; m = [math]::Round(($_.Group | Measure-Object WorkingSetPrivate -Sum).Sum / 1MB); k = $_.Count } } |
    Sort-Object { $_.m } -Descending | Select-Object -First 5
  $ioTop = $procs | Sort-Object IODataBytesPersec -Descending | Select-Object -First 5 | Where-Object { $_.IODataBytesPersec -gt 0 } | ForEach-Object { @{ n = ($_.Name -replace '#\d+$',''); io = [math]::Round($_.IODataBytesPersec / 1KB) } }
  $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  $net = Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface | Measure-Object -Property BytesTotalPersec -Sum
  $freq = $null; try { $freq = (Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "Name='_Total'").PercentofMaximumFrequency } catch {}
  @{
    t = (PD-NowMs); cpu = [int]$cpu
    ram = [int](100 - 100 * $os.FreePhysicalMemory / $os.TotalVisibleMemorySize)
    busy = [int][math]::Min(100, $dk.PercentDiskTime); lat = [int]($dk.AvgDisksecPerRead * 1000); q = [math]::Round($dk.CurrentDiskQueueLength, 1)
    hf = [int]$mem.PageReadsPersec; cfree = [math]::Round(100 * $c.FreeSpace / $c.Size, 1); cfreeGB = [math]::Round($c.FreeSpace / 1GB, 1)
    top = $top; ramTop = @($ramTop); ioTop = @($ioTop); net = [int]($net.Sum / 1KB); freq = $freq; temp = (PD-Temp)
    user = (PD-LoggedOnUser)
  }
}
function PD-LoggedOnUser { try { $u = (Get-CimInstance Win32_ComputerSystem).UserName; if ($u) { ($u -split '\\')[-1] } else { '' } } catch { '' } }

# temperature: LibreHardwareMonitor (downloaded once, kept in ThawSpace or re-downloaded), else ACPI thermal zone
$script:Lhm = $null
# 1.57 (user, 05-Nov-2026: "build CPU temperature, fan and 12 V in" - option 1 approved): the old reader (LibreHardwareMonitor 0.9.4) used the WinRing0 driver, which
# Windows Defender blocks ("R0powershell ... contains a virus or potentially unwanted software") - so no PC showed a temperature. Now: PawnIO (signed by namazso.eu, the
# driver the newest LibreHardwareMonitor uses; tested on the Windows runner: silent install OK, Defender 0 detections) + LibreHardwareMonitor 0.9.6 (.NET Framework edition).
# Both addresses are data (lab/cfg pawnUrl / lhmUrl). A Frozen PC installs PawnIO only while Thawed (it would be lost at the restart). Tried again every 6 hours.
function PD-PawnIO {
  $k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PawnIO'
  if ((Get-ItemProperty $k -ErrorAction SilentlyContinue).DisplayVersion) { return $true }
  if ($PD.Test) { return $false }
  if ((PD-DeepFreeze).state -eq 'frozen') { $script:PawnNote = 'Frozen - the temperature driver installs while Thawed'; return $false }
  $c = PD-Cfg; $u = if ($c -and $c.pawnUrl) { [string]$c.pawnUrl } else { 'https://github.com/namazso/PawnIO.Setup/releases/download/2.2.0/PawnIO_setup.exe' }
  $f = Join-Path $PD.Root 'dl\PawnIO_setup.exe'
  try { New-Item -ItemType Directory -Force (Join-Path $PD.Root 'dl') | Out-Null
    if (!(Test-Path $f)) { Invoke-WebRequest -UseBasicParsing $u -OutFile $f -TimeoutSec 180 }
    $sg = Get-AuthenticodeSignature $f
    if ($sg.Status -ne 'Valid' -or [string]$sg.SignerCertificate.Subject -notmatch 'CN=namazso\.eu') { $script:PawnNote = 'driver refused: signature ' + $sg.Status; PD-Log ('PawnIO refused: ' + $sg.Status + ' ' + $sg.SignerCertificate.Subject); return $false }
    $p = Start-Process $f -ArgumentList '-install -silent' -PassThru -WindowStyle Hidden
    if (!$p.WaitForExit(120000)) { try { $p.Kill() } catch {}; $script:PawnNote = 'driver install timed out'; return $false }
    $ok = [bool](Get-ItemProperty $k -ErrorAction SilentlyContinue).DisplayVersion; PD-Log ('PawnIO install exit ' + $p.ExitCode + ', installed ' + $ok)
    if ($ok) { PD-Event 'install' 'T' 'Temperature driver PawnIO (signed) installed - CPU temperature, fans and 12 V are read from now on' | Out-Null } else { $script:PawnNote = 'driver install failed (exit ' + $p.ExitCode + ')' }
    return $ok } catch { $script:PawnNote = 'driver download failed: ' + $_.Exception.Message; PD-Log ('PawnIO: ' + $_.Exception.Message); return $false }
}
function PD-Temp {
  if ($script:Lhm -eq $false -and $script:LhmAt -and ((Get-Date) - $script:LhmAt).TotalHours -ge 6) { $script:Lhm = $null }
  try {
    if ($null -eq $script:Lhm) { $script:Lhm = $false; $script:LhmAt = Get-Date
      if (!(PD-PawnIO)) { throw 'no PawnIO' }
      $dir = Join-Path $PD.Root 'dl\lhm096'; $dll = Join-Path $dir 'LibreHardwareMonitorLib.dll'
      if (!(Test-Path $dll)) {
        $c = PD-Cfg; $u = if ($c -and $c.lhmUrl) { [string]$c.lhmUrl } else { 'https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/download/v0.9.6/LibreHardwareMonitor.zip' }
        $z = Join-Path $PD.Root 'dl\lhm096.zip'; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $z -TimeoutSec 180
        New-Item -ItemType Directory -Force $dir | Out-Null; Expand-Archive $z $dir -Force
        $in = Get-ChildItem $dir -Recurse -Filter LibreHardwareMonitorLib.dll | Select-Object -First 1; if ($in -and $in.DirectoryName -ne $dir) { Copy-Item "$($in.DirectoryName)\*" $dir -Recurse -Force } }
      Add-Type -Path $dll
      $comp = New-Object LibreHardwareMonitor.Hardware.Computer; $comp.IsCpuEnabled = $true; $comp.IsMotherboardEnabled = $true; $comp.IsStorageEnabled = $true; $comp.Open()
      $script:Lhm = $comp; $script:PawnNote = ''
    }
    if ($script:Lhm) {
      $r = @{ cpu = $null; disk = $null; fans = @(); volt = @(); v12 = $null }
      foreach ($h in $script:Lhm.Hardware) { $h.Update(); foreach ($sh in $h.SubHardware) { $sh.Update() }
        foreach ($s in @($h.Sensors) + @($h.SubHardware | ForEach-Object { $_.Sensors })) {
          if ($null -eq $s.Value) { continue }
          if ($s.SensorType -eq 'Temperature' -and $h.HardwareType -eq 'Cpu' -and ($s.Name -match 'Package|Tctl|Core Max|Average')) { $r.cpu = [math]::Max([double]$r.cpu, [math]::Round($s.Value)) }
          elseif ($s.SensorType -eq 'Temperature' -and $h.HardwareType -eq 'Storage') { $r.disk = [math]::Max([double]$r.disk, [math]::Round($s.Value)) }
          elseif ($s.SensorType -eq 'Fan') { $r.fans += [int]$s.Value }
          elseif ($s.SensorType -eq 'Voltage' -and $s.Name -match '12V|5V|3\.3V|Vcore|CPU') { $r.volt += ($s.Name + ' ' + [math]::Round($s.Value, 2)) }
          if ($s.SensorType -eq 'Voltage' -and $s.Name -match '12' -and $s.Value -gt 9 -and $s.Value -lt 15) { $r.v12 = [math]::Round($s.Value, 2) }
        } }
      return $r
    }
  } catch { $script:Lhm = $false }
  try { $z = Get-CimInstance -Namespace root/wmi MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Select-Object -First 1; return @{ cpu = [math]::Round($z.CurrentTemperature / 10 - 273.15) } } catch {}
  $null
}

# ---------- Windows events (6: deepest checks) - watched every minute, uploaded as they happen ----------
$PD_EVENTS = @(
  @{ L = 'System'; P = 'Microsoft-Windows-Kernel-Power'; I = 41; k = 'kp41'; icon = '⚡'; txt = 'Switched off without shutting down (Kernel-Power 41)' },
  @{ L = 'System'; P = 'EventLog'; I = 6008; k = 'unexpected'; icon = '⚡'; txt = 'Previous shutdown was unexpected' },
  @{ L = 'System'; P = 'Microsoft-Windows-WER-SystemErrorReporting'; I = 1001; k = 'bsod'; icon = '💙'; txt = 'Blue screen (BugCheck)' },
  @{ L = 'System'; P = 'Microsoft-Windows-WHEA-Logger'; I = 17,18,19,47; k = 'whea'; icon = '🧠'; txt = 'Hardware error (WHEA)' },
  @{ L = 'System'; P = 'disk'; I = 7,51,153; k = 'disk'; icon = '💾'; txt = 'Disk error' },
  @{ L = 'System'; P = 'Ntfs','Microsoft-Windows-Ntfs'; I = 55; k = 'ntfs'; icon = '💾'; txt = 'NTFS file system damaged' },
  @{ L = 'System'; P = 'storport','stornvme','iaStorA','iaStorAC'; I = 129,153; k = 'storport'; icon = '💾'; txt = 'Storage driver reset' },
  @{ L = 'System'; P = 'Service Control Manager'; I = 7000,7001,7009,7011,7022,7023,7024,7026,7031,7034,7043; k = 'scm'; icon = '⚙️'; txt = 'Service failed' },
  @{ L = 'System'; P = 'Microsoft-Windows-GroupPolicy'; I = 1129; k = 'gp'; icon = '🌐'; txt = 'Group Policy: no network to the server' },
  @{ L = 'Application'; P = 'Microsoft-Windows-User Profiles Service','Microsoft-Windows-User Profile Service'; I = 1511,1515; k = 'profile'; icon = '👤'; txt = 'Temporary user profile' },
  @{ L = 'System'; P = 'Microsoft-Windows-Resource-Exhaustion-Detector'; I = 2004; k = 'lowmem'; icon = '🧠'; txt = 'Windows ran out of memory' },
  @{ L = 'Application'; P = 'Application Hang'; I = 1002; k = 'hang'; icon = '⏳'; txt = 'Program hung' },
  @{ L = 'Application'; P = 'Application Error'; I = 1000; k = 'apperr'; icon = '💥'; txt = 'Program crashed' },
  @{ L = 'Application'; P = '.NET Runtime'; I = 1026; k = 'dotnet'; icon = '💥'; txt = '.NET program crashed' },
  @{ L = 'System'; P = 'Display'; I = 4101; k = 'display'; icon = '🖥️'; txt = 'Display driver stopped and recovered' },
  @{ L = 'System'; P = 'Microsoft-Windows-Kernel-Processor-Power'; I = 37; k = 'throttle'; icon = '🌡️'; txt = 'CPU slowed down by the firmware (heat / power)' },
  @{ L = 'System'; P = 'Microsoft-Windows-WindowsUpdateClient'; I = 20; k = 'updfail'; icon = '🔄'; txt = 'Windows update failed' },
  @{ L = 'System'; P = 'Microsoft-Windows-WindowsUpdateClient'; I = 19,43,44; k = 'upd'; icon = '🔄'; txt = 'Windows update' },
  @{ L = 'Application'; P = 'MsiInstaller'; I = 11707,11724,1033,1034; k = 'install'; icon = '📦'; txt = 'Program installed / removed' },
  @{ L = 'System'; P = 'Tcpip'; I = 4199; k = 'ipconflict'; icon = '🌐'; txt = 'IP address conflict' },
  @{ L = 'System'; P = 'Microsoft-Windows-Kernel-General'; I = 1; k = 'clock'; icon = '🕐'; txt = 'Clock changed' },
  @{ L = 'Application'; P = 'Microsoft-Windows-Wininit','Wininit'; I = 1001; k = 'chkdsk'; icon = '💽'; txt = 'Check disk result' },
  @{ L = 'System'; P = 'Microsoft-Windows-MemoryDiagnostics-Results'; I = 1101,1201,1102,1202; k = 'mdiag'; icon = '🧠'; txt = 'Memory test result' },
  @{ L = 'Microsoft-Windows-PrintService/Admin'; P = $null; I = $null; k = 'print'; icon = '🖨️'; txt = 'Printer error' },
  @{ L = 'Microsoft-Windows-SmbClient/Connectivity'; P = $null; I = 30803,30804,30805,30806,30807,30808,30809,30810,30811,30812,30813,30814; k = 'smb'; icon = '📁'; txt = 'Shared folder / printer connection problem' },
  @{ L = 'Microsoft-Windows-Diagnostics-Performance/Operational'; P = $null; I = 100,101,102,103,104,105,106,107,108,109,110,200,201,202,203; k = 'perf'; icon = '🐢'; txt = 'Slow startup / shutdown' }
)
function PD-ReadEvents([datetime]$Since, [int]$Max = 60) {
  $out = @()
  foreach ($d in $PD_EVENTS) {
    $f = @{ LogName = $d.L; StartTime = $Since }
    if ($d.P) { $f.ProviderName = $d.P }; if ($d.I) { $f.Id = $d.I }
    # 1.4: "The parameter is incorrect" (an EventLogException) is not stopped by -ErrorAction - read each source on its own; with 2
    # provider names try them one by one; a source that still fails is logged and skipped, the others go on
    $evs = @(); try { $evs = @(Get-WinEvent -FilterHashtable $f -MaxEvents $Max -ErrorAction Stop) } catch {
      if ($_.Exception.Message -notmatch 'No events were found') {
        if (@($d.P).Count -gt 1) { foreach ($p1 in @($d.P)) { $f.ProviderName = $p1; try { $evs += @(Get-WinEvent -FilterHashtable $f -MaxEvents $Max -ErrorAction Stop) } catch {} } }
        else { try { PD-Log ('events ' + $d.L + ' ' + $d.k + ': ' + $_.Exception.Message) } catch {} } } }
    if ($d.L -like '*PrintService/Admin') { $evs = @($evs | Where-Object { $_.Level -le 3 }) }
    foreach ($e in $evs) {
      $msg = ''; try { $msg = ($e.Message -split "`n")[0..2] -join ' ' } catch {}
      $x = @{ t = [int64](([datetimeoffset]$e.TimeCreated).ToUnixTimeMilliseconds()); k = $d.k; icon = $d.icon; txt = $d.txt; id = $e.Id; src = $e.ProviderName; msg = $msg.Substring(0, [math]::Min(300, $msg.Length)) }
      if ($d.k -eq 'kp41') { try { $x.code = '0x{0:X}' -f [int64]$e.Properties[0].Value; $x.nobsod = ([int64]$e.Properties[0].Value -eq 0) } catch {} }
      if ($d.k -eq 'bsod') { if ($msg -match '0x([0-9a-fA-F]+)') { $x.code = '0x' + ([Convert]::ToInt64($Matches[1], 16)).ToString('X') } }
      if ($d.k -in 'hang','apperr') { try { $x.prog = [string]$e.Properties[0].Value } catch {} }
      if ($d.k -eq 'perf' -and $e.Id -eq 100) { try { $x.bootMs = [int64]$e.Properties[5].Value; $x.txt = 'Startup took ' + [math]::Round($x.bootMs / 1000) + ' s' } catch {} }
      if ($d.k -eq 'perf' -and $e.Id -in 101,102,103,106,109) { try { $x.prog = [string]$e.Properties[2].Value; $x.ms = [int64]$e.Properties[5].Value } catch {} }
      if ($d.k -eq 'throttle') { try { $x.pct = [int]$e.Properties[2].Value } catch {} }
      if ($d.k -eq 'clock') { try { $old = [datetime]$e.Properties[1].Value; $new = [datetime]$e.Properties[0].Value; $x.jump = [int]($new - $old).TotalMinutes } catch {} }
      $out += $x
    }
  }
  $out | Sort-Object { $_.t }
}

# ---------- SMART (full) - storage reliability counters + raw attributes where Windows gives them ----------
function PD-Smart {
  # 1.4 (04-Nov-2026, first real PC): a plugged-in pendrive came first as "the disk" - USB / SD / virtual disks are left out, and the
  # Windows (system) disk is always first, so a pendrive never looks like a "disk replaced"
  $out = @(); $sysN = ''
  try { $sysN = [string](Get-Partition -DriveLetter ($env:SystemDrive.TrimEnd(':')) -ErrorAction Stop).DiskNumber } catch {}
  $skip = @('USB', 'SD', 'MMC', 'Virtual', 'File Backed Virtual')
  foreach ($pd in @(Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $skip -notcontains [string]$_.BusType } |
                    Sort-Object { if ([string]$_.DeviceId -eq $sysN) { 0 } else { 1 } }, { [int]$_.DeviceId })) {
    $rc = $pd | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
    $o = @{ model = $pd.FriendlyName; serial = ([string]$pd.SerialNumber).Trim(); media = [string]$pd.MediaType; bus = [string]$pd.BusType; sizeGB = [math]::Round($pd.Size / 1GB);
            health = [string]$pd.HealthStatus; op = [string]($pd.OperationalStatus -join ',');
            hours = $rc.PowerOnHours; temp = $rc.Temperature; tempMax = $rc.TemperatureMax; wear = $rc.Wear; readErr = $rc.ReadErrorsTotal; writeErr = $rc.WriteErrorsTotal;
            readLatMax = $rc.ReadLatencyMax; starts = $rc.StartStopCycleCount; realloc = $null; pending = $null; uncorr = $null; crc = $null; predict = $false;
            n = [string]$pd.DeviceId; sys = ([string]$pd.DeviceId -eq $sysN) }
    $out += $o
  }
  # raw ATA attributes (5 reallocated, 197 pending, 198 uncorrectable, 199 CRC) + predicted failure
  try {
    $fail = @(Get-CimInstance -Namespace root/wmi MSStorageDriver_FailurePredictStatus -ErrorAction Stop)
    $data = @(Get-CimInstance -Namespace root/wmi MSStorageDriver_FailurePredictData -ErrorAction Stop)
    $ddAll = @(Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue)
    for ($i = 0; $i -lt $data.Count; $i++) {
      $b = $data[$i].VendorSpecific; $a = @{}
      for ($j = 2; $j -lt $b.Length - 11; $j += 12) { if ($b[$j]) { $a[[int]$b[$j]] = [int64]$b[$j + 5] + 256 * [int64]$b[$j + 6] + 65536 * [int64]$b[$j + 7] } }
      # match the raw SMART row to its disk by the device path (InstanceName = PNPDeviceID + _0), not by position
      $pn = ([string]$data[$i].InstanceName) -replace '_\d+$', ''; $dd = @($ddAll | Where-Object { [string]$_.PNPDeviceID -eq $pn }) | Select-Object -First 1
      $o = if ($dd) { $out | Where-Object { $_.n -eq [string]$dd.Index } | Select-Object -First 1 } elseif ($out.Count -eq 1 -and $data.Count -eq 1) { $out[0] } else { $null }
      if ($o) { $o.realloc = $a[5]; $o.pending = $a[197]; $o.uncorr = $a[198]; $o.crc = $a[199]; if (!$o.hours) { $o.hours = $a[9] }
        $f = @($fail | Where-Object { [string]$_.InstanceName -eq [string]$data[$i].InstanceName }) | Select-Object -First 1; if ($f) { $o.predict = [bool]$f.PredictFailure } }
    }
  } catch {}
  $out
}

# ---------- daily inventory (6) ----------
function PD-Inventory {
  $cs = Get-CimInstance Win32_ComputerSystem; $os = Get-CimInstance Win32_OperatingSystem; $bios = Get-CimInstance Win32_BIOS; $bb = Get-CimInstance Win32_BaseBoard
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  $ram = @(Get-CimInstance Win32_PhysicalMemory | ForEach-Object { @{ gb = [math]::Round($_.Capacity / 1GB); mhz = $_.ConfiguredClockSpeed; maker = ([string]$_.Manufacturer).Trim(); part = ([string]$_.PartNumber).Trim(); serial = ([string]$_.SerialNumber).Trim(); slot = $_.DeviceLocator } })
  $mis = (@($ram | ForEach-Object { "$($_.gb)/$($_.mhz)" } | Select-Object -Unique)).Count -gt 1
  $sb = $null; try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop } catch {}
  $tpm = $null; try { $t = Get-Tpm -ErrorAction Stop; $tpm = @{ present = $t.TpmPresent; ready = $t.TpmReady } } catch {}
  $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
  $drv = @(Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -and $_.DriverProviderName -ne 'Microsoft' } | ForEach-Object { @{ dev = $_.DeviceName; ver = $_.DriverVersion; date = ([string]$_.DriverDate).Substring(0, [math]::Min(8, ([string]$_.DriverDate).Length)); by = $_.DriverProviderName; signed = $_.IsSigned; inf = $_.InfName } } | Select-Object -First 150)
  $sw = @()
  foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*') {
    $sw += @(Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and !$_.SystemComponent } | ForEach-Object { @{ n = $_.DisplayName; v = [string]$_.DisplayVersion; d = [string]$_.InstallDate; by = [string]$_.Publisher } })
  }
  $start = @(Get-CimInstance Win32_StartupCommand | ForEach-Object { @{ n = $_.Name; cmd = ([string]$_.Command).Substring(0, [math]::Min(160, ([string]$_.Command).Length)); where = $_.Location } })
  $svcBad = @(Get-CimInstance Win32_Service -Filter "StartMode='Auto' AND State<>'Running'" | Where-Object { $_.Name -notmatch 'gupdate|edgeupdate|sppsvc|RemoteRegistry|MapsBroker|wuauserv|TrustedInstaller|BITS|Wbio|GoogleUpdater|DoSvc|UsoSvc|WaaSMedic|sedsvc' } | ForEach-Object { $_.DisplayName })
  $tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskPath -notlike '\Microsoft\*' -and $_.State -ne 'Disabled' } | ForEach-Object { $_.TaskPath + $_.TaskName } | Select-Object -First 60)
  $def = $null; try { $m = Get-MpComputerStatus -ErrorAction Stop; $def = @{ on = $m.AntivirusEnabled; rt = $m.RealTimeProtectionEnabled; sig = $m.AntivirusSignatureLastUpdated.ToString('s'); quick = ([string]$m.QuickScanEndTime); full = ([string]$m.FullScanEndTime); threats = @(Get-MpThreatDetection -ErrorAction SilentlyContinue).Count } } catch {}
  $prn = @(Get-Printer -ErrorAction SilentlyContinue | ForEach-Object { $p = $_; $port = Get-PrinterPort -Name $p.PortName -ErrorAction SilentlyContinue
    @{ n = $p.Name; drv = $p.DriverName; port = $p.PortName; ip = [string]$port.PrinterHostAddress; type = $(if ($p.Type -eq 'Connection') { 'shared from ' + $p.ComputerName } elseif ($p.PortName -match '^USB') { 'USB' } elseif ($port.PrinterHostAddress) { 'network' } else { [string]$p.PortName }); shared = $p.Shared; share = $p.ShareName; st = [string]$p.PrinterStatus; def = $false; jobs = @(Get-PrintJob -PrinterName $p.Name -ErrorAction SilentlyContinue).Count } })
  try { $dp = (Get-CimInstance Win32_Printer -Filter 'Default=True' | Select-Object -First 1).Name; foreach ($p in $prn) { if ($p.n -eq $dp) { $p.def = $true } } } catch {}
  $net = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up' | ForEach-Object { $ip = Get-NetIPConfiguration -InterfaceIndex $_.ifIndex -ErrorAction SilentlyContinue
    @{ n = $_.Name; desc = $_.InterfaceDescription; speed = [string]$_.LinkSpeed; mac = $_.MacAddress; ip = [string]($ip.IPv4Address.IPAddress | Select-Object -First 1); gw = [string]($ip.IPv4DefaultGateway.NextHop | Select-Object -First 1); dns = @($ip.DNSServer.ServerAddresses | Where-Object { $_ -match '\.' }); prof = [string](Get-NetConnectionProfile -InterfaceIndex $_.ifIndex -ErrorAction SilentlyContinue).NetworkCategory } })
  $vols = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { @{ d = $_.DeviceID; label = $_.VolumeName; gb = [math]::Round($_.Size / 1GB); freeGB = [math]::Round($_.FreeSpace / 1GB, 1); fs = $_.FileSystem } })
  $df = PD-DeepFreeze
  $bat = $null
  if ((Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)) { try { $x = "$env:TEMP\pd_bat.xml"; powercfg /batteryreport /xml /output $x | Out-Null; [xml]$b = Get-Content $x; $bt = $b.BatteryReport.Batteries.Battery | Select-Object -First 1
      $bat = @{ design = [int]$bt.DesignCapacity; full = [int]$bt.FullChargeCapacity; health = [math]::Round(100 * [int]$bt.FullChargeCapacity / [math]::Max(1, [int]$bt.DesignCapacity)); cycles = [int]$bt.CycleCount }; Remove-Item $x -Force } catch {} }
  @{
    t = (PD-NowMs); name = $env:COMPUTERNAME; model = ($cs.Manufacturer + ' ' + $cs.Model).Trim(); user = (PD-LoggedOnUser); domain = $cs.Domain
    cpu = @{ n = ([string]$cpu.Name).Trim(); cores = $cpu.NumberOfCores; threads = $cpu.NumberOfLogicalProcessors; mhz = $cpu.MaxClockSpeed }
    ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB); ram = $ram; ramMismatch = $mis; ramSlots = (Get-CimInstance Win32_PhysicalMemoryArray | Measure-Object -Property MemoryDevices -Sum).Sum
    disks = @(PD-Smart); vols = $vols
    board = @{ maker = $bb.Manufacturer; model = $bb.Product }; bios = @{ ver = $bios.SMBIOSBIOSVersion; date = ([string]$bios.ReleaseDate); maker = $bios.Manufacturer }
    secureBoot = $sb; tpm = $tpm
    win = @{ name = $cv.ProductName -replace 'Windows 10','Windows 1x'; disp = $cv.DisplayVersion; build = ([string]$cv.CurrentBuild + '.' + [string]$cv.UBR); inst = [string]$cv.InstallDate; edition = $cv.EditionID; boot = $os.LastBootUpTime.ToString('s') }
    drivers = $drv; unsigned = @($drv | Where-Object { !$_.signed } | ForEach-Object { $_.dev }); software = @($sw | Sort-Object { $_.n } -Unique | Select-Object -First 400)
    startup = $start; svcStopped = $svcBad; tasks = $tasks; defender = $def; printers = $prn; net = $net
    df = $df; drives = (PD-DriveMap); spy = [bool](Get-Service -Name '*ClassroomSpy*','CSAgent*' -ErrorAction SilentlyContinue); battery = $bat
    mesh = (PD-MeshNode)
  }
}
# 1.47 (user, 05-Nov-2026: B1 "MeshCentral agent already installed" but no remote id): the agent's registry key is named after its service
# ("Mesh Agent", older "MeshAgent2", 32-bit WOW6432Node) - look in every key under Open Source for NodeId
function PD-MeshNode {
  foreach ($root in 'HKLM:\SOFTWARE\Open Source', 'HKLM:\SOFTWARE\WOW6432Node\Open Source') {
    foreach ($k in @(Get-ChildItem $root -ErrorAction SilentlyContinue)) {
      try { $v = (Get-ItemProperty $k.PSPath -ErrorAction Stop).NodeId; if ($v) { return ([string]$v).Trim() } } catch {} } }
  ''
}
# where Windows, Android Studio, SDK, emulators, Gradle and student projects are, and how big (6: drive map; 7: Android clean)
function PD-DirGB([string]$p) { try { if (Test-Path $p) { [math]::Round(((Get-ChildItem $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum) / 1GB, 2) } else { $null } } catch { $null } }
function PD-UserDirs { @(Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin 'Public','Default','Default User','All Users' }) }
function PD-DriveMap {
  $m = @{ windows = $env:SystemDrive; studio = @(); sdk = @(); avd = @(); gradle = @(); projects = @() }
  foreach ($s in @(Get-ChildItem 'C:\Program Files\Android','D:\Program Files\Android' -Directory -ErrorAction SilentlyContinue)) { $m.studio += @{ p = $s.FullName } }
  foreach ($u in PD-UserDirs) {
    $h = $u.FullName
    foreach ($x in @(@('sdk', "$h\AppData\Local\Android\Sdk"), @('avd', "$h\.android\avd"), @('gradle', "$h\.gradle"), @('projects', "$h\AndroidStudioProjects"))) {
      if (Test-Path $x[1]) { $m[$x[0]] += @{ p = $x[1]; gb = (PD-DirGB $x[1]) } } }
  }
  $m
}

# ---------- startup (6): power on -> desktop, slowest drivers / services / apps, "stuck at startup" ----------
function PD-Startup {
  $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100,101,102,103,106,109 } -MaxEvents 80 -ErrorAction SilentlyContinue)
  $last = $ev | Where-Object Id -eq 100 | Select-Object -First 1
  $r = @{ sec = $null; top = @(); at = $null; stuck = '' }
  if ($last) { try { $r.sec = [math]::Round([int64]$last.Properties[5].Value / 1000); $r.at = $last.TimeCreated.ToString('s'); $r.mainMs = [int64]$last.Properties[6].Value; $r.postMs = [int64]$last.Properties[48].Value } catch {} }
  $r.top = @($ev | Where-Object { $_.Id -ne 100 -and (!$last -or $_.TimeCreated -ge $last.TimeCreated.AddMinutes(-15)) } | ForEach-Object {
    $kind = @{ 101 = 'app'; 102 = 'driver'; 103 = 'service'; 106 = 'background'; 109 = 'device' }[$_.Id]
    @{ n = [string]$_.Properties[2].Value; what = $kind; ms = [int64]$_.Properties[5].Value } } | Sort-Object { -$_.ms } | Select-Object -First 8)
  # BIOS / POST time + the time since boot for the agent itself (before login) tells "stuck before Windows" vs "stuck at login"
  try { $fw = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction Stop).FwPOSTTime; if ($fw) { $r.biosSec = [math]::Round($fw / 1000, 1) } } catch {}
  if ($r.sec -and $r.top.Count) { $r.stuck = 'Slowest: ' + (($r.top | Select-Object -First 3 | ForEach-Object { $_.n + ' ' + [math]::Round($_.ms / 1000, 1) + ' s' }) -join ', ') }
  $r
}

# ---------- BSOD (6): code + guilty driver (cdb !analyze, downloaded once), plain words from lab/cfg/bsod ----------
function PD-Bsod([int]$Days = 30) {
  $c = PD-Cfg; $list = @()
  $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001; StartTime = (Get-Date).AddDays(-$Days) } -ErrorAction SilentlyContinue)
  foreach ($e in $ev) {
    $code = ''; if ($e.Message -match '0x([0-9a-fA-F]{8,16})') { $code = '0x' + ([Convert]::ToInt64($Matches[1], 16)).ToString('X') }
    $w = $null; if ($c -and $c.bsod -and $code) { $w = $c.bsod.$code }
    $list += @{ t = [int64](([datetimeoffset]$e.TimeCreated).ToUnixTimeMilliseconds()); code = $code; words = $(if ($w) { $w.w } else { 'Blue screen ' + $code }); vk = $(if ($w) { $w.vk } else { 'unknown' }); lv = $(if ($w) { $w.lv } else { 'orange' }) }
  }
  $dumps = @(Get-ChildItem "$env:SystemRoot\Minidump\*.dmp","$env:SystemRoot\LiveKernelReports\*\*.dmp" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5)
  $df = PD-DeepFreeze
  $r = @{ list = $list; n7 = @($list | Where-Object { $_.t -gt (PD-NowMs) - 7 * 86400000 }).Count; dumps = @($dumps | ForEach-Object { @{ f = $_.Name; t = $_.LastWriteTime.ToString('s'); kb = [math]::Round($_.Length / 1KB) } }); note = '' }
  if (!$dumps.Count -and $list.Count -and $df.state -eq 'frozen') { $r.note = 'Minidump folder is empty - Deep Freeze wiped the crash files at restart. The code above comes from the event saved in DB5.' }
  if ($dumps.Count) { $an = PD-Analyze $dumps[0].FullName; if ($an) { $r.driver = $an.driver; $r.analyze = $an.text } }
  $r
}
function PD-Analyze([string]$dmp) {
  try {
    $cdb = Get-ChildItem "$env:ProgramFiles*\Windows Kits\10\Debuggers\x64\cdb.exe","$(PD-ThawPath)\cdb\cdb.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (!$cdb) { return $null }   # Debugging Tools: installed by the "Install crash reader" fix (winsdksetup /features OptionId.WindowsDesktopDebuggers)
    $o = & $cdb.FullName -z $dmp -c '!analyze -v; q' -y 'srv*C:\ProgramData\DavanPCDoctor\dl\sym*https://msdl.microsoft.com/download/symbols' 2>$null | Out-String
    $drv = ''; if ($o -match 'IMAGE_NAME:\s+(\S+)') { $drv = $Matches[1] } elseif ($o -match 'MODULE_NAME:\s+(\S+)') { $drv = $Matches[1] }
    @{ driver = $drv; text = ($o -split "`n" | Where-Object { $_ -match 'BUGCHECK_CODE|BUGCHECK_STR|IMAGE_NAME|MODULE_NAME|PROCESS_NAME|FAILURE_BUCKET_ID|DEFAULT_BUCKET_ID' }) -join "`n" }
  } catch { $null }
}

# ---------- network (deep): gateway / internet / DNS times, SMB 24H2, firewall, RPC printing ----------
function PD-NetCheck {
  $gw = (Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4DefaultGateway.NextHop
  $png = { param($h) try { $p = New-Object Net.NetworkInformation.Ping; $ok = 0; $ms = 0; 1..4 | ForEach-Object { $x = $p.Send($h, 1000); if ($x.Status -eq 'Success') { $ok++; $ms += $x.RoundtripTime } }; @{ ms = $(if ($ok) { [int]($ms / $ok) } else { -1 }); loss = (4 - $ok) * 25 } } catch { @{ ms = -1; loss = 100 } } }
  $g = & $png $gw; $i = & $png '8.8.8.8'
  $dns = -1; try { $sw = [Diagnostics.Stopwatch]::StartNew(); [Net.Dns]::GetHostAddresses('www.google.com') | Out-Null; $dns = [int]$sw.ElapsedMilliseconds } catch {}
  $smb = $null; try { $s = Get-SmbClientConfiguration -ErrorAction Stop; $smb = @{ signReq = $s.RequireSecuritySignature; guest = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' -ErrorAction SilentlyContinue).AllowInsecureGuestAuth } } catch {}
  $fw = @(Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq 'True' -and $_.Profile -match 'Private|Any' }).Count
  $rpc = $null; try { $p = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' -ErrorAction Stop; $rpc = @{ RpcAuthnLevelPrivacyEnabled = $p.RpcAuthnLevelPrivacyEnabled } } catch {}
  $pp = $null; try { $q = Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC' -ErrorAction Stop; $pp = @{ RpcUseNamedPipeProtocol = $q.RpcUseNamedPipeProtocol; RpcProtocols = $q.RpcProtocols } } catch {}
  $pwshare = $null; try { $pwshare = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -ErrorAction Stop).everyoneincludesanonymous } catch {}
  @{ gw = $gw; gwMs = $g.ms; loss = $g.loss; netMs = $i.ms; netLoss = $i.loss; dnsMs = $dns; smb = $smb; fpsRules = $fw; rpc = $rpc; rpcPrint = $pp; prof = @(Get-NetConnectionProfile -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.NetworkCategory }); anon = $pwshare
     creds = @((cmdkey /list 2>$null) | Where-Object { $_ -match 'Target:' } | ForEach-Object { ($_ -replace '.*Target:\s*','').Trim() } | Select-Object -First 15) }
}
function PD-PrintCheck {
  $sp = Get-Service Spooler -ErrorAction SilentlyContinue
  $jobs = @(Get-Printer -ErrorAction SilentlyContinue | ForEach-Object { $n = $_.Name; Get-PrintJob -PrinterName $n -ErrorAction SilentlyContinue | Where-Object { $_.SubmittedTime -lt (Get-Date).AddMinutes(-10) } | ForEach-Object { @{ prn = $n; doc = $_.DocumentName; st = [string]$_.JobStatus; at = $_.SubmittedTime.ToString('s') } } })
  $err = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-PrintService/Admin'; StartTime = (Get-Date).AddDays(-7) } -MaxEvents 30 -ErrorAction SilentlyContinue | Where-Object Level -le 3)
  $code = ''; foreach ($e in $err) { if ($e.Message -match '0x0*(11b|709|bcb|bc4|5|3e3|6ba)\b') { $code = '0x' + $Matches[1]; break } }
  @{ spooler = [string]$sp.Status; stuck = $jobs.Count; jobs = $jobs; err = $err.Count; code = $code; last = @($err | Select-Object -First 5 | ForEach-Object { $_.TimeCreated.ToString('s') + ' ' + (($_.Message -split "`n")[0]) }) }
}
function PD-SfcState {
  # read-only: the last sfc / DISM results from CBS.log + pending reboot flags
  $r = @{ bad = 0; fixed = 0; at = ''; pendingReboot = $false; reliability = $null }
  try { $l = Get-Content "$env:SystemRoot\Logs\CBS\CBS.log" -Tail 4000 -ErrorAction Stop
    $r.bad = @($l | Where-Object { $_ -match 'Cannot repair member file|corrupt' }).Count; $r.fixed = @($l | Where-Object { $_ -match 'Repaired file|Repairing corrupted file' }).Count } catch {}
  $r.pendingReboot = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or [bool](Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue)
  try { $r.reliability = [math]::Round((Get-CimInstance Win32_ReliabilityStabilityMetrics -ErrorAction Stop | Select-Object -First 1).SystemStabilityIndex, 1) } catch {}
  $r
}
# Deep Freeze update loop (6): the same update downloaded again after every restart
function PD-UpdateLoop([object[]]$ev7) {
  # 1.4: only a PC with Deep Freeze can loop (first real PC, a laptop without it, was called "Update loop (Deep Freeze)")
  if (([string]$PD.DfState) -eq 'none' -or (!$PD.DfState -and (PD-DeepFreeze).state -eq 'none')) { return @{ loop = 0; loopN = 0; what = '' } }
  $dl = @($ev7 | Where-Object { $_.k -eq 'upd' -and $_.id -eq 44 })
  $g = $dl | Group-Object { if ($_.msg -match '(KB\d+)') { $Matches[1] } else { $_.msg.Substring(0, [math]::Min(60, $_.msg.Length)) } } | Where-Object Count -ge 3 | Sort-Object Count -Descending | Select-Object -First 1
  if ($g) { @{ loop = 1; loopN = $g.Count; what = $g.Name } } else { @{ loop = 0; loopN = 0; what = '' } }
}

# ---------- verdict (6): the rules in lab/cfg -> verdict + confidence, compared with same-model PCs ----------
function PD-Get($o, [string]$path) { $v = $o; foreach ($p in $path.Split('.')) { if ($null -eq $v) { return $null }; if ($v -is [hashtable]) { $v = $v[$p] } else { $v = $v.$p } }; $v }
function PD-Verdict([hashtable]$m) {
  $c = PD-Cfg; $hits = @()
  foreach ($r in @($c.rules)) {
    if (!$r -or !$r.id) { continue }
    $conds = @(); $mode = 'all'; if ($r.any) { $conds = @($r.any); $mode = 'any' } elseif ($r.all) { $conds = @($r.all) }
    $ok = 0
    foreach ($cd in $conds) { $v = PD-Get $m $cd[0]; if ($null -eq $v) { continue }
      $x = [double]$cd[2]; $y = 0.0; if (![double]::TryParse([string]$v, [ref]$y)) { continue }
      $pass = switch ($cd[1]) { '>' { $y -gt $x } '>=' { $y -ge $x } '<' { $y -lt $x } '<=' { $y -le $x } '==' { $y -eq $x } default { $false } }
      if ($pass) { $ok++ } }
    $fire = if ($mode -eq 'any') { $ok -gt 0 } else { $conds.Count -gt 0 -and $ok -eq $conds.Count }
    if ($fire) {
      $why = [regex]::Replace([string]$r.why, '\{([a-zA-Z0-9_.]+)\}', { param($mm) $v = PD-Get $m $mm.Groups[1].Value; if ($null -eq $v -or $v -eq '') { '?' } else { [string]$v } })
      $conf = [int]$r.conf; if ($mode -eq 'any' -and $ok -gt 1) { $conf = [math]::Min(98, $conf + 5 * ($ok - 1)) }
      $hits += @{ id = $r.id; lv = $r.lv; vk = $r.vk; v = $r.v; why = $why; conf = $conf; fix = $r.fix }
    }
  }
  $rank = @{ red = 4; orange = 3; purple = 3; yellow = 2; green = 0 }
  $hits = @($hits | Sort-Object { -($rank[$_.lv] * 100 + $_.conf) })
  if (!$hits.Count) {
    $unk = ($m.ev.scm -gt 20) -or ($m.ev.apperr -gt 20)
    if ($unk) { return @{ lv = 'yellow'; vk = 'unknown'; v = '❓ Unknown problem'; why = 'Many errors but no rule fits - full data is on the PC page; ✨ Ask AI or Claude can look.'; conf = 30; all = @() } }
    return @{ lv = 'green'; vk = 'ok'; v = 'Healthy'; why = 'No problem found.'; conf = 90; all = @() }
  }
  $top = $hits[0]
  @{ lv = $top.lv; vk = $top.vk; v = $top.v; why = $top.why; conf = $top.conf; fix = $top.fix; all = @($hits | Select-Object -First 6) }
}
