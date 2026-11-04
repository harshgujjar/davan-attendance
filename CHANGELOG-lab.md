# 🖥️ Davan PC Doctor - changelog (newest first, never deleted)
Parts: PC Doctor Agent (background), PC Doctor (tray window), PC Doctor Console (lab.html), PC Doctor Rescue (pendrive).
Versions of every part: pcdoctor/lab-version.json. Plan: ROADMAP-pcdoctor.md.

- 04-Nov-2026 · Agent 1.12 / tray 1.5 -- The user: "if I want to update manually within the hour, give an option in the tray, and show which version,
  when it came and what's new - latest 5, rest Show / Hide". Tray: new ⬆️ Updates tab (also in the right-click menu) - ⬆️ Update now (the
  updater checks within a minute and skips the 2-h test wait, since it was asked by hand), this PC's version + build + IST date-time it came,
  the newest published one, the result of the last check, 🆕 What's new (5 newest, Show all (N) / Hide). Loader saves state\labver.json +
  state\upd.json. No DB5 reads / writes. L-Fetch, L-Res, UpdNow, UpdRefresh.
- 04-Nov-2026 · Agent 1.11 / Console 1.2 -- STRICT RULE (user: "never delete anything from a PC, especially my laptop - tell me what you want to
  delete and delete only if I say yes"). Fixes that delete or remove anything (temp / Android clean, spooler jobs, startup item, roll back driver,
  uninstall update) never run by themselves: the PC posts "🧹 ... suggested - nothing is deleted until you tap it" (event + one amber alert a day)
  and runs it only when the Super Admin taps it. The Super Admin laptop runs no fix by itself at all. Two locks: PD-FixAllowed and PD-Fix.
  DB5 lab/cfg/fix auto = false + deleting switches off (Action "DB5 auto-fix OFF"). Console Switches show 🔒 "asks you first". A-AutoFix.
- 04-Nov-2026 · Agent 1.10 / tray 1.4 -- tray 1.2-1.3 would not start (the password box set TopMost twice - PowerShell refuses the whole
  script); caught by the Windows test before any PC took it. Fixed, and tools/pcdoctor_version.py now refuses a key written twice in one @{...}. Pw.
- 04-Nov-2026 · Agent 1.9 / tray 1.3 -- The user: "it's not auto update". Every PC checks GitHub at start + every hour, but only test PCs took a
  new build at once (others wait 2 h, and each new build restarted the wait), and a running tray kept its old copy until sign-in. Now the Super
  Admin laptop (state\laptop.flag, set by A-Laptop) always takes a new build at once, and the tray restarts itself with the new copy when the
  build changes and its window is closed. Lab PCs keep the safe 2-h wait after the test PCs. No new reads / writes. L-Fetch, A-Laptop, SelfUpdate.
- 04-Nov-2026 · tray 1.2 -- The user: "we planned a password to open it, but it opens without". The PC Doctor window now asks for the password
  (2531, hashed in lab/cfg/trayPw, changeable on the Console) every time it opens from the tray icon or menu, also for 📋 Copy report; while
  it is open ⚙️ / 🔧 don't ask again; closing it locks it. The password box stays on top. No new reads / writes. OpenWin, Pw.
- 04-Nov-2026 · Agent 1.7 -- The Windows test (GitHub runner) registered itself as a PC in DB5 once the worker had its DB5 key: test mode
  now never registers, never reads / writes DB5 and sends no alerts ($PD.Test in PD-Register / PD-Token / PD-Db / PD-Alert). The fake PC entry is removed.
- 04-Nov-2026 · Agent 1.5 / checks 1.3 -- First real PC (the user's laptop): (1) every minute failed with "$S.ring is null" - PowerShell
  names are case-blind, so the sample variable $s replaced the agent state $S (no minute rows, wrong verdict / Deep Freeze state in lab/now);
  renamed in A-Minute / A-Now / A-Live, and tools/pcdoctor_version.py now refuses to publish a function that uses both $s and $S.
  (2) Get-WinEvent "The parameter is incorrect" stopped the event reading - each source is read on its own (2 provider names one by one),
  a failing source is logged and skipped. (3) A plugged-in pendrive was listed as "the disk" (false "Disk replaced") - USB / SD / virtual disks
  left out, Windows disk first, SMART matched by device path. (4) "Update loop (Deep Freeze)" was shown on a laptop without Deep
  Freeze - only PCs with Deep Freeze are checked now. No new reads / writes. A-Minute, A-Now, A-Live, PD-ReadEvents, PD-Smart, PD-UpdateLoop.
- 04-Nov-2026 · worker v21 -- The hourly check said MeshCentral was down although it answered HTTPS 200 from outside (would have sent a false
  "Remote server offline" alert). It now tries https, then http (a 302 counts as alive) and keeps the error text in DB5 lab/wstate.mesh.err. No new reads. labHourly.
- 04-Nov-2026 · staff widget w365 -- Step 15: 🖥️ PC Doctor page on the Super Admin's staff widget (grid at a glance, problems, morning
  summary, tap = Console). Data: DB2 davan_pub/lab_grid written by the worker (hourly + after each alert; one small read per 15 min). -next channel.
- 04-Nov-2026 · Console 1.1 + Agent 1.2 + tray / checks / fixes / Rescue 1.1 -- Steps 4-14. PC Doctor Agent (PowerShell, no .exe): PCDoctor-Setup.cmd
  (Safe-Mode service built on the PC from C# source, boot task, tray autostart, MeshCentral agent, per-PC key), loader (SHA-256 checked updates,
  test-PC channel + relOk, rollback after 10 silent min), minute rows + hourly lab load, every deep Windows check, daily inventory, data-driven verdicts,
  light / heavy / restart / Thawed-queue fixes with limits, peers ping, pendrive .dlh + fix pendrive, Rescue (WinRE batch). PC Doctor Console lab.html:
  Lab overview, PC page, Disk, Auto-fix (approve, Thaw helper, undo, switches), ✨ Ask AI, Office, Printers, Versions, Remote screen + Terminal
  (MeshCentral login per tap), New / Old PCs, Groups, Import, Rescue tools, Settings (passwords encrypted / •••). Staff app v2000 menu item.
  DB5 lab/load (+ rules), worker /lab/secret + 🔔 switches. Windows test Action (pcdoctor-test.yml) runs every check on a real Windows PC.
- 04-Nov-2026 · cloud 1 -- Step 2 + 3: worker davan-release v18 (/lab/tok Super Admin DB5 login, /lab/pc PC login with a scored hardware
  fingerprint so a PC keeps its identity after an OS reinstall, /lab/alert, /lab/ai with the lab's own daily limit, /lab/mesh remote-screen
  login, hourly check: remote server offline, PC left Thawed, 🔴 PC, lab-wide, morning summary). davan-scraper Actions: DB5 rules, DB5 peek,
  DB5 cmd (changes wait for the Super Admin's OK), PC Doctor daily (settings, timetable lab periods, history export, Old PCs, cleanup),
  Mesh setup + Mesh backup. Settings in data: pcdoctor/cfg-default.json -> DB5 lab/cfg. Needs the worker secret DB5_SA.
