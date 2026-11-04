# 🖥️ Davan PC Doctor - FULL BUILD CHECKLIST (agreed with the user 04-Nov-2026, session 01BVkXcMKr6HK7qa23dAP4ee)

User (04-Nov): "build all as per plan without missing anything, all small small things, no skipping, no 'later build'".
EVERY line below is part of the build. Tick `[x]` with the version when done. Nothing here is optional.
Also follow every CLAUDE.md rule (self-working for years, settings in data, fallbacks, cleanup, ✨ on AI text, 📋 Copy on every debug text,
plain words, IST times, singular / plural, empty states, same look as the staff app, page reloads by itself after refresh, PWA rule,
changelog + version in the same commit, commit + merge main). Keep the user informed step by step (user, 04-Nov).

## 0. Names (FINAL)
- [x] Product **Davan PC Doctor**. Parts: **PC Doctor Agent** (background), **PC Doctor** (tray window), **PC Doctor Console** (`lab.html`),
      **PC Doctor Rescue** (pendrive). Same names on every screen, notification and file.

## 1. Infra (DONE by the user 04-Nov - keep these facts)
- DB5 = Firebase `davan-lab` (Spark free), RTDB Singapore, locked mode, Anonymous sign-in ON. Web config:
  apiKey AIzaSyAdebhgQpyjd3ZQgUl_UNhLXYUDRJK1C1s, authDomain davan-lab.firebaseapp.com,
  databaseURL https://davan-lab-default-rtdb.asia-southeast1.firebasedatabase.app, projectId davan-lab,
  storageBucket davan-lab.firebasestorage.app, messagingSenderId 587735256426, appId 1:587735256426:web:4964f6f1fdc08b5c03a913
- davan-scraper secrets: DB5_SA, ORACLE_IP, ORACLE_SSH_KEY. Action "PC Doctor - infra check" (pcdoctor-check.yml) passed 04-Nov
  (DB5 read 200; SSH ubuntu@VM OK).
- The Claude cloud proxy BLOCKS *.firebasedatabase.app for davan-lab -> Claude reads / writes DB5 only through davan-scraper Actions.
- Oracle Always Free, Mumbai: VM `davan-mesh` E2.1.Micro (Ampere was out of capacity; 1 OCPU, 951 MB RAM, 45 GB), Ubuntu 26.04.1, user
  `ubuntu`, TCP 22/80/443 open, reserved IP 144.24.111.207 -> `144-24-111-207.sslip.io` (DuckDNS is blocked by the user's ISP DNS;
  sslip.io tested OK on his network). Fallback nip.io.
- The user typed a password in chat (04-Nov) - NOT stored anywhere; passwords are only typed into the Settings page / MeshCentral.
- Deep Freeze **Standard** (no DFC.exe command line) -> no automatic Thaw / Freeze (see 7).
- Classroom Spy stays for in-lab screens (no change). MeshCentral = remote screen from anywhere (in the build).

## 2. Cloud jobs (davan-scraper, every one sends a ☁️ alert on failure) - DONE 04-Nov: worker v18 + tools/db5*.py, lab_daily.py, mesh/setup.sh
- [x] `DB5 rules` Action (writes the rules in 3; re-runnable).
- [x] `DB5 peek` Action (path + filter + maxc, like DB2 peek) - how Claude reads live data.
- [x] `DB5 cmd` Action - Claude QUEUES a read-only check freely, or a change as "waiting for OK" (never runs a change itself).
- [x] Daily history export DB5 -> davan-scraper `lab/` (small json per PC per day; kept for years).
- [x] Daily cleanup job (retention in 14).
- [x] `Mesh setup` Action over SSH: swap 2 GB, MeshCentral (Node LTS) as a service, HTTPS Let's Encrypt on the sslip.io name, allowFraming +
      login tokens for lab.html, 2-step login, auto-update ON, unattended-upgrades, weekly reboot, nightly config backup to davan-scraper
      (encrypted), keep-alive against Oracle idle reclaim, hourly health check -> ☁️ "Remote server offline". Rebuild = one Action run if the
      VM is ever lost. Agents keep the server cert hash so they connect even by bare IP.
- [x] Worker davan-release: route that mints a DB5 custom token for a logged-in Super Admin (verifies the staff ID token; DB5 service account as
      a worker secret) = Console / staff app login to DB5. Fallback: clear "can't reach DB5" box.

## 3. DB5 data + rules - DONE 04-Nov: davan-scraper tools/db5_rules.json (+ lab/now, lab/inv, lab/fp, lab/pckey, lab/secret, lab/salap, lab/tt, lab/sum, lab/peers); lab/fixlog/<date>/<hwid>
- [x] Paths: `lab/pcs/<hwid>` (info, name, group, notes, parts, history marks), `lab/live/<hwid>` (minute rows), `lab/events/<hwid>`,
      `lab/daily/<hwid>/<date>`, `lab/cmd/<hwid>`, `lab/res/<hwid>`, `lab/fixlog`, `lab/cfg` (groups, rules, BSOD words, thresholds, switches,
      timetable link, keep-version list, AI limit, passwords hashed / encrypted), `lab/kb` (solved cases), `lab/ver` (per-PC versions), `lab/alerts`.
- [x] Rules: each PC writes only its own nodes with its per-PC key (made at install while Thawed, so it is part of the frozen image); reads only
      its own `cmd` + `cfg`; Super Admin (custom token claim) reads / writes all; everything else denied.

## 4-14 BUILT 04-Nov (Console 1.1, Agent 1.2, staff app v2000, worker v18) - details CHANGELOG-lab.md
## 4. Groups + names (user, 04-Nov)
- [x] PC number = Windows computer name. Prefixes in `lab/cfg/groups`: `A` Lab 1, `B` Lab 2, `PUC` PUC office, `D` Degree office; laptop =
      💼 Super Admin. Longest prefix wins. Each group: prefix, name, Lab / Office, Deep Freeze yes / no, timetable room.
- [x] ⚙️ Groups tab: ➕ Add group (new lab / block / office) with no new build; edit / remove.
- [x] 📥 New PCs box (unknown name, e.g. DESKTOP-7XK2): Assign / ✏️ Rename (agent renames Windows; on Frozen PCs at a Thawed restart).
- [x] Silent 30 days -> 🗄️ Old PCs (history kept). Duplicate names -> ⚠️ "A5 (duplicate)".
- [ ] Today: Lab 30, Degree office 5, PUC office 4, the user's laptop. (counts fill in as each PC runs PCDoctor-Setup.cmd - see 16)

## 5. Identity survives OS reinstall (user, 04-Nov)
- [x] Hardware fingerprint, scored (board serial, BIOS UUID, onboard NIC MAC, CPU id, disk serials, RAM serials; blank OEM serials ignored).
- [x] Reinstall detected (Windows InstallDate changed) -> "♻️ Known PC: PUC2" -> name, group, notes, settings put back, Windows renamed,
      timeline mark "🔄 OS reinstalled <date>", history continues; verdicts use pre-reinstall history ("same RAM errors before the reinstall").
- [x] Part swap -> event per part ("💾 Disk replaced 12 Dec: old disk had 148 bad sectors"); each part keeps its own history.
- [x] New board -> "Looks like PUC2 (disk + RAM match) -> Merge?" one tap.
- [x] Name / group / place / user / notes / Deep Freeze yes-no / keep-version list editable BOTH ways (Console <-> tray app); a Windows rename on the
      PC is detected; every change logged (who, where, when, old -> new); a change made on the PC -> "✏️ Keep / ↩ Change back".

## 6. PC Doctor Agent (PowerShell, no .exe)
- [x] One installer `PCDoctor-Setup.cmd` (run as admin, PC Thawed, ~2 min): loader, SYSTEM scheduled task at boot (before login), Safe-Mode-allowed
      service (SafeBoot\Minimal + Network), tray app autostart, MeshCentral agent, per-PC key; asks nothing (group from the name). Win 10 + Win 11.
- [x] Loader downloads the newest scripts from GitHub every boot + every hour; `lab-version.json` holds versions + SHA-256 of every file (fake files
      refused). Channel: 2 test PCs (in data) first, everyone 2 h later if they are healthy. New version silent 10 min -> automatic rollback to the
      last good + ☁️ alert.
- [x] Lowest priority, < 1% CPU. Minute row to DB5: CPU, RAM, disk busy %, disk read latency ms, queue, hard faults/s, top 5 programs (CPU / RAM /
      disk I/O), temperature, network. Events uploaded as they happen. Local 10-min ring buffer too.
- [x] No internet / DB5 down -> queue (ThawSpace if present, else memory + pendrive), sends later.
- [x] Daily inventory scan: CPU, RAM sticks (size / speed / mismatch / serial), disks (model, SMART, power-on hours), board, BIOS version / date,
      Secure Boot, TPM, Windows build, drivers + dates + unsigned, services, startup items, scheduled tasks, installed software + versions, recent
      installs / uninstalls, Defender state + scan times, printers (model, USB / network, shared, driver, port, who uses it), network (adapter, link
      speed, IP, gateway, DNS), Deep Freeze state + version + ThawSpace, drive map (where Windows, Android Studio, SDK, emulators, Gradle, student
      projects are; Frozen / ThawSpace), Classroom Spy agent present, battery report (laptops).
- [x] Deepest checks (Windows' own data): Kernel-Power 41 + codes, 6008, BugCheck 1001, minidumps + LiveKernelReports, WER reports,
      Diagnostics-Performance 100-110 + 200-203, Service Control Manager 7000-7043, Group Policy 1129, User Profile 1511/1515, Disk 7/51/153, Ntfs 55,
      storport, chkdsk results (Wininit), SMART full (reallocated / pending / uncorrectable / CRC = cable / temp / SSD wear), WHEA 17/18/19/47,
      Memory Diagnostic results, Resource-Exhaustion 2004, App Hang 1002 / App Error 1000 / .NET 1026, Display 4101, Kernel-Processor-Power 37 +
      % of max frequency (heat slow-down), temps / fans / voltages (LibreHardwareMonitor, downloaded once), WindowsUpdateClient 20 + pending-reboot
      flags, MsiInstaller 11707/11724, Tcpip 4199 IP conflict, ping gateway / internet / DNS time, CMOS battery (clock jump at boot), Reliability
      index, sfc / DISM state, PrintService Admin / Operational, spooler + stuck jobs, SMB client / server logs, SMB signing / guest (24H2),
      network profile, firewall rules, RPC / Point-and-Print (0x11b / 0x709 / 0xbcb), credentials / password-protected sharing.
- [x] Before / after snapshot 5 min around every freeze / slow start / BSOD (from minute rows already in DB5, so Deep Freeze can't wipe it).
- [x] Startup: power-on -> desktop time, slowest drivers / services / apps by name, "stuck at startup" diagnosis.
- [x] Deep Freeze update-loop check (update downloaded, wiped every restart).
- [x] Peer ping: each PC pings the others -> "🟠 on but stuck" vs "⚫ off / stuck before Windows (check by hand)"; many PCs at once ->
      "🟣 lab-wide (network / server / update)". Wake-on-LAN through MeshCentral where the BIOS allows.
- [x] BSOD: crash code + guilty driver via Microsoft cdb `!analyze` (downloaded once; ThawSpace or re-download), plain words from the `lab/cfg`
      table (0x1A/0x50 RAM, 0x7A/0xEF disk / Windows, 0x124 hardware, 0x133 disk driver, 0x116/0x119 display, 0xD1/0x3B/0x7E named driver ...),
      "started after KB / driver X", same BSOD on many PCs = lab-wide. Empty Minidump folder on a Frozen PC -> say so.
- [x] Rule engine in data -> verdict + confidence %, compared with same-model PCs; ❓ Unknown with full data when no rule fits; solved cases to `lab/kb`.
- [x] Verdicts in plain words: 🔴 disk failing, 🔴 RAM error, 🟠 too little RAM, 🟠 Windows damaged, 🟠 program X hangs N times, 🟠 overheating,
      🟠 disk almost full (Android files), 🟠 update loop, 🟠 printer error <code>, 🟡 slow startup, 🟡 power cuts / no UPS, 🟣 lab-wide, ⚫ off, 🟢 healthy.

## 7. Fixes (user, 04-Nov: everything in the background, NO idle wait)
- [x] Checks + scans: always, during lab too.
- [x] Light, at once (during lab too): temp / crash dump clean, stop hung program, spooler restart + stuck jobs, network Private + discovery +
      File & Printer Sharing firewall, RPC 0x11b / 0x709 / 0xbcb settings (both PCs), direct printer-driver install, printer by IP, SMB 24H2 sharing
      + saved login, startup item off. (On Frozen PCs a light fix lasts until restart; permanent ones go to the Thawed queue.)
- [x] Heavy, background at low I/O priority, auto-pause when busy (disk > 80% / a student program waiting): sfc / DISM, Android clean (only when
      Android Studio is closed), winget software updates (keep-version list in data, e.g. Android Studio), Windows update download.
- [x] Android clean list: %TEMP% + Windows temp + dumps; Gradle caches + old Gradle; Android Studio caches / logs; old Android Studio version folders;
      AVD data + snapshots (keep 1 emulator, wipe data); unused SDK system images; project build folders. NEVER student source code.
      Auto when C: free < 15% (data), 🧹 Clean now button, "will free ≈ X GB", alert only if still red after.
- [x] Restart-needing (chkdsk, RAM test, update install, rename): at shutdown, or a free timetable period with nobody logged in, or ✅ now.
      Never restart a PC in use.
- [x] Deep Freeze STANDARD: agent queues "needs Thawed" -> Console "Thaw needed: N fixes" -> Super Admin opens 🖥️ Remote screen and sets Boot Thawed
      (helper shows the steps) -> agent sees Thawed after the restart, runs ALL queued fixes, then "✅ done - now Boot Frozen" -> reminder + ☁️ alert if
      left Thawed. Deep Freeze password typed once on ⚙️ Settings, stored encrypted, never shown in plain text.
- [x] Timetable: lab / free periods per room read from the staff app's timetable (current semester, automatic); room = group setting.
- [x] Limits in data: max 5 PCs at once, same fix once a week, per-fix switches + master Auto-fix switch; ☁️ morning summary of fixes.
- [x] Fix buttons per PC: 🔍 Check now, 🧹 Clean now, ⛔ Stop a program, 🔄 Restart, 🛠️ Repair Windows, 💽 Check disk, 🧠 RAM test, 🖨️ printer fixes,
      ↩ roll back driver / uninstall update + block, 📤 Send report, 💾 SSD swap steps, 📋 Copy full report.
- [x] Claude / ✨ AI only QUEUE changes "waiting for OK"; Super Admin taps ✅ Approve; every change logged with result + ↩ Undo for settings.
- [x] Windows feature upgrades on hold (switch in data); BIOS / firmware = report only.

## 8. PC Doctor tray app (PowerShell WinForms, every PC)
- [x] 🖥️ tray icon; closing the window never stops the agent. Password 2531 (hashed in `lab/cfg`, changeable on the Console).
- [x] Shows: verdict, CPU / RAM / disk busy / C: free bars, temp, Frozen / Thawed, internet, last sent, last 7 days; buttons 📤 Send report now,
      🔍 Check now, 📋 Copy, 💾 Save report to pendrive, 🔧 Fix from pendrive, ⚙️ name / group / notes (syncs both ways).
- [x] Laptop = **Super Admin mode**: all PCs grid (Lab / Degree / PUC tabs) + Windows toast popups (🔴 PC, hang fixed, lab-wide, 9 am summary) +
      the laptop's own health (battery health, disk).

## 9. Offline + Safe Mode + Rescue (user, 04-Nov)
- [x] 💾 Save to pendrive -> `<NAME>_<yyyy-mm-dd_hhmm>.dlh` (zip: queued data, last minutes, evtx logs, dumps, SMART, inventory, fingerprint).
      Auto-copy, no click, when a pendrive with `DAVANLAB.key` is plugged in.
- [x] Console 📥 Import from pendrive (JSZip): shows the PC exactly like online + uploads to DB5 (history complete, AI + Claude see it).
- [x] Console 💾 Make fix pendrive (approved scripts + offline driver / update files) -> tray 🔧 Fix from pendrive (password) -> result back on the
      USB -> import.
- [x] Safe Mode: the service runs there; Safe Mode with Networking uploads + MeshCentral; without network -> pendrive.
- [x] PC Doctor Rescue: `DavanRescue.cmd` for the WinRE Command Prompt (menu: 1 collect everything to pendrive from the dead Windows, 2 repair
      startup bootrec, 3 offline sfc / DISM, 4 chkdsk, 5 undo last update / driver). Console 💾 Make Rescue pendrive button + steps.
- [x] Bootable Ventoy pendrive guide on the Console (Hiren's BootCD PE + Memtest86+ + PC Doctor Rescue), BlueScreenView / CrystalDiskInfo /
      HWiNFO steps, Secure Boot "Enroll key" note.

## 10. PC Doctor Console = `lab.html` (plain HTML + JS, this repo)
- [x] Own `manifest-lab.json` (unique id, scope = lab.html), own SW `register('app-sw.js', {scope:'./lab.html'})`, icons exist; auto-update
      (new version -> reload by itself); version + build + IST time in the footer.
- [x] Opens inside the staff app: Super Admin side-menu item 🖥️ PC Doctor (like Rates `?embed=1`), same login (custom DB5 token, 2); also full
      screen / installable on phone + laptop. Super Admin only. Reopens itself after refresh.
- [x] Look = the staff app (Bebas Neue / DM Sans / DM Mono, --bg #0b0d11, --accent #f0a500 ...), phone first, matching the 04-Nov mockup:
      lab score donut + counts, alert cards, tile grid (🟢🟡🟠🔴⚫🟣, 🔥 Thawed, pulse on red) + legend, top problems bars, lab load chart with lab
      periods, lab-wide card; PC detail (verdict + why, 4 gauges, drives & Deep Freeze, 7-day timeline, startup bars, just-before-freeze,
      What to do steps, actions); Disk (all PCs free bars + per-PC breakdown + Clean); Printers; Auto-fix (timetable bar, waiting / done,
      switches, limits, passwords •••); Office (Degree / PUC / Laptop); ✨ Ask AI; 📦 Versions & updates; ⚙️ Groups; 📥 New PCs; 🗄️ Old PCs;
      📥 Import; Rescue / pendrive tools; 🖥️ Remote screen + ⌨️ Terminal (MeshCentral embedded, login key per tap, Ctrl+Alt+Del, phone
      keyboard, fit / zoom, files, session log).
- [x] Empty / edge states: no PCs yet, PC never reported, offline, VM down ("Remote server offline"), DB5 down, AI limit used, old agent version.
- [x] 📋 Copy on every report / log / list.
- [x] Staff user names on office PCs: `_facAvatar(name, size, true)` + `_facAvatarInject()` (photo + tap to zoom), name in its own element.

## 11. ✨ AI (free)
- [x] ✨ Ask about this PC / ✨ Ask about the lab (Console + laptop tray), through `aiAsk()` / worker `/ai` (Workers AI -> Gemini, model in DB2
      `davan_pub/ai_cfg`), ~3 KB context (verdict, snapshots, events, 7 days, `lab/kb` matches), follow-ups, answers marked ✨ AI, suggests a fix
      button (never runs it). Lab daily limit in `lab/cfg` (e.g. 50) -> "AI limit used today, back tomorrow"; rule verdicts keep working.
- [x] ✨ 9 am daily lab summary paragraph (Console + laptop toast).

## 12. Alerts + notifications
- [x] ☁️ Cloud alerts to the Super Admin only when a PC turns 🔴, lab-wide problem, PC left Thawed, VM / MeshCentral down, update rolled back,
      a job failed; one morning summary.
- [x] Staff app push (sw.js) + NOTIF_REGISTRY rows on the 🔔 page (ON by default; read ROADMAP-notifications.md first).

## 13. Versions + changelog
- [x] `lab-version.json`: agent / tray / checks / fixes / rescue / console - version, build, IST date-time, notes, SHA-256 list, test PCs.
- [x] `CHANGELOG-lab.md` (short entries, newest first, never deleted). Staff app menu change: CODE_BUILD + HTML_CHANGELOG + CHANGELOG-admin.md,
      built with tools/build_index.js.
- [x] 📦 Versions tab: every part's version; each PC's version + ✅ / ⏳ behind + why (off / no internet / waiting / rolled back); per-PC update log
      (time, old -> new, result); 🆕 What's new; Windows + software updates per PC (installed / when / result / on hold); 📋 Copy.

## 14. Retention / cost (Spark free)
- [x] Live minute rows 2 days, daily summaries 1 year, hardware history forever, fix log 1 year, history export to davan-scraper.
      ~17 MB/day live for 40 PCs. Console reads summaries, not raw rows.

## 15. Staff widget
- [ ] 🖥️ Lab page in the staff widget (grid at a glance, tap opens the Console) - Super Admin only; BuildInfo.NEWS line; next channel.

## 16. Test + roll-out
- [ ] Test on 2 lab PCs + 1 office PC for one day (user installs, Thawed, admin login); check every screen as the user would; fix mismatches.
- [ ] Then all 30 lab + 9 office + laptop. The user sets the MeshCentral password and types the Deep Freeze password on ⚙️ Settings.
- [ ] Final check per CLAUDE.md: "Will this still work in 2 years with nobody touching it?"

## Still with the user
- Name the PCs in Windows (A1.., B1.., PUC1.., D1..) or rename later from the Console.
- Blue-screen PC: Ventoy pendrive (Hiren's + Memtest86+), photo of the stop code / Minidump files -> Claude reads them.
- Change the password that was typed in chat on 04-Nov.
