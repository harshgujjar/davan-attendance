# 🖥️ PC Doctor (Lab Health) - agreed plan (user, 04-Nov-2026) - NOTHING BUILT YET

Name FINAL (user, 04-Nov): "Davan PC Doctor" (Agent / PC Doctor tray app / PC Doctor Console = lab.html / PC Doctor Rescue USB) - ask the user.
Mockup (sample data, 8 screens) was sent as a file in session 01BVkXcMKr6HK7qa23dAP4ee - user had not approved / commented yet.

## Infra - DONE by the user 04-Nov-2026
- **DB5** = Firebase project `davan-lab` (Spark, free), RTDB Singapore, locked mode (rules still to write via a davan-scraper Action with DB5_SA),
  Anonymous sign-in ON (tested: signUp gives a token). Web config:
  apiKey AIzaSyAdebhgQpyjd3ZQgUl_UNhLXYUDRJK1C1s, authDomain davan-lab.firebaseapp.com,
  databaseURL https://davan-lab-default-rtdb.asia-southeast1.firebasedatabase.app, projectId davan-lab,
  storageBucket davan-lab.firebasestorage.app, messagingSenderId 587735256426, appId 1:587735256426:web:4964f6f1fdc08b5c03a913
- davan-scraper secret **DB5_SA** (service account json) - added.
- The cloud session's proxy BLOCKS *.firebasedatabase.app for this new project -> Claude reads DB5 through a davan-scraper Action ("DB5 peek").
- **Oracle Cloud** Always Free, India West (Mumbai): VM `davan-mesh`, VM.Standard.E2.1.Micro (1 OCPU, 1 GB - Ampere A1 was "out of capacity"),
  Ubuntu 26.04, ingress TCP 22, 80, 443 open. **Reserved public IP 144.24.111.207** -> address `144-24-111-207.sslip.io`
  (DuckDNS is blocked by the user's ISP DNS; sslip.io tested OK on his network). Secrets ORACLE_IP + ORACLE_SSH_KEY added; davan-scraper Action "PC Doctor - infra check" (pcdoctor-check.yml) passed 04-Nov: DB5 read 200, SSH ubuntu@VM OK (Ubuntu 26.04.1, 951 MB RAM, 45 GB disk, internet OK).
- Add swap on the VM (1 GB RAM). Keep-alive against Oracle idle reclaim. Nightly MeshCentral config backup to davan-scraper.

## PCs
30 lab PCs (Win 10/11, Deep Freeze STANDARD edition (user, 04-Nov) - no DFC.exe command line (Enterprise only), so automatic Thaw/Freeze is NOT possible: agent queues "needs Thawed" fixes, Super Admin sets Boot Thawed / Boot Frozen through MeshCentral remote screen, agent runs the queued fixes while Thawed and reminds to refreeze; ThawSpace only if made at DF install - agent detects) + Degree office 5 + PUC office 4 + the user's laptop.
Names = Windows computer name, group by prefix from DB5 lab/cfg/groups (A* Lab 1, B* Lab 2, PUC* PUC office, D* Degree office; longest prefix
wins; ➕ Add group on the page = new lab / office with no build). Unknown names -> 📥 New PCs (Assign / Rename). Silent 30 days -> 🗄️ Old PCs.
Identity = HARDWARE fingerprint (board serial, BIOS UUID, MAC, CPU id, disk + RAM serials, scored) - an OS reinstall keeps name + full history
("🔄 OS reinstalled"), part swaps recorded per part, new board -> "Looks like PUC2 -> Merge?". Name / group / notes editable both ways
(page <-> tray app), logged, local rename -> "Keep / Change back", duplicates flagged.

## Agent (PowerShell, SYSTEM scheduled task at boot + a Safe-Mode-allowed service)
- Install once while Thawed (tiny loader + task); every boot / hour it downloads the newest scripts from GitHub (hash list in lab-version.json),
  2 test PCs first, others 2 h later if healthy; new version silent 10 min -> automatic rollback + alert.
- Every minute: CPU / RAM / disk busy / disk latency / top programs -> DB5 (Deep Freeze wipes C:, so nothing important stays local;
  offline queue on ThawSpace). Events as they happen. Daily inventory scan (printers, hardware, software, drives, Deep Freeze state, Android
  Studio / SDK / project locations). Deepest checks: Kernel-Power 41 / 6008 / BugCheck, minidumps + LiveKernelReports (cdb !analyze),
  WER, Diagnostics-Performance 100-110, SCM 7000-7043, SMART full (CRC = cable), WHEA, memory diag, temps / fans / voltages
  (LibreHardwareMonitor), throttling, app hang / crash, Windows Update failures + Deep Freeze update loop, MsiInstaller, drivers, Defender,
  network (latency, link speed, IP conflict), CMOS battery (clock jump), Reliability index, printers (PrintService logs, spooler, 0x11b /
  0x709 / 0xbcb, Point-and-Print, SMB 24H2 guest / signing, network profile, firewall).
- Before / after snapshot (5 min) around every freeze / slow start -> rule engine verdict with confidence %, compared with same-model PCs.
  Rules, BSOD code words, thresholds = DB5 lab/cfg (editable). Unknown -> ❓ with data. Solved cases -> lab/kb.
- Peer ping: answers ping but agent silent = "on but stuck"; many PCs at once = lab-wide.

## Fixes (user, 04-Nov: checks + fixes work in the BACKGROUND, no 15-min idle rule)
- Checks: always. Light fixes (temp, hung program, spooler / printer, network / firewall / sharing, startup items): at once, during lab too.
- Heavy (sfc / DISM, Android / Gradle / AVD / build clean, winget updates, update downloads): background at low I/O priority, auto-pause when
  busy; Android clean only when Android Studio is closed; student source code never deleted.
- Restart-needing (Thaw -> fix -> Freeze, chkdsk, RAM test, installing updates): at shutdown, or free timetable period (staff app timetable)
  with nobody logged in, or ✅ now. Never restart a PC in use. Deep Freeze password STORED (user OK'd) in DB5, encrypted, for auto Thaw/Freeze.
- Max 5 PCs at once, same fix once a week, per-fix switches + master switch, always refreeze (alert if not), morning summary.
- Claude / ✨ AI may only QUEUE changes "waiting for OK"; the Super Admin taps ✅ Approve. Every change logged with ↩ Undo.
- winget keeps software updated (keep-version list in data, e.g. Android Studio). Feature upgrades + BIOS: report / hold.

## Screens
- **lab.html** (plain HTML+JS, own manifest-lab.json + own SW, auto-updates itself), opened inside the staff app from a Super Admin side-menu
  item (like Rates ?embed=1), same login. Tabs: Lab grid / PC detail / Disk / Printers / Auto-fix / Office / 📦 Versions & updates
  (each part's version + build + IST time, per-PC version + why behind, update log, What's new) / ⚙️ Groups / 📥 Import from pendrive.
- Tray app on every PC (PowerShell WinForms, 🖥️ tray icon, password 2531 stored hashed in DB5): live, verdict, 7 days, 📤 Send, 💾 Save to
  pendrive (.dlh; auto-copy when a DAVANLAB.key USB is plugged), 🔧 Fix from pendrive, ⚙️ name / notes. Laptop = Super Admin mode with popups.
- ✨ AI: "Ask about this PC / the lab" via worker davan-release /ai (aiAsk, free Workers AI -> Gemini), short context ~3 KB, daily limit in data.
- MeshCentral (user uses it - in the build): server on the Oracle VM, agent on every PC, remote screen + terminal EMBEDDED in lab.html
  (login key per tap, Super Admin only), works on laptop + phone. Classroom Spy stays for in-lab screens.
- PC Doctor Rescue: DavanRescue.cmd from WinRE command prompt (collect to USB, bootrec, offline sfc / DISM, chkdsk, undo update);
  later a bootable Ventoy USB (Hiren's + Memtest86+ + rescue).

## Data / cleanup
DB5 lab/pcs/<hwid>, lab/live (2 days), lab/events, lab/cmd, lab/res, lab/cfg, lab/fixlog, lab/kb; daily summaries 90 days - 1 year;
hardware history forever; daily history export to davan-scraper lab/. Changelog: CHANGELOG-lab.md, versions lab-version.json.

## Build order
1 DB5 rules + DB5 peek Action  2 agent v1 (install, minute upload, checks, boot, Deep Freeze)  3 tray app  4 lab.html + staff app link + alerts
5 fixes + approve  6 MeshCentral on Oracle via Action (ORACLE_SSH_KEY) + embed  7 self-update / rollback / cleanup  8 test 2 lab + 1 office PC, then all.
Open questions: name; Deep Freeze edition / ThawSpace; printer list comes from the scan.
