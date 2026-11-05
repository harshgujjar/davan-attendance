# 🖥️ Davan PC Doctor - changelog (newest first, never deleted)
Parts: PC Doctor Agent (background), PC Doctor (tray window), PC Doctor Console (lab.html), PC Doctor Rescue (pendrive).
Versions of every part: pcdoctor/lab-version.json. Plan: ROADMAP-pcdoctor.md.

- 05-Nov-2026 · tray 1.15 -- The user: "show the version here always" - the tray window title reads "PC Doctor v1.24 - GUJJAR" and follows
  every update by itself (state/running.json). UpdRefresh.
- 05-Nov-2026 · Agent 1.23 / tray 1.14 -- The user: "when downloading a new update show the progress in the tray so I know what is happening".
  The updater (loader) writes each step to state/updp.json (looking, downloading file i of n, installing, starting); the tray's Updates tab
  shows a bar + the step every second while it runs, also on This PC's message line and the icon's text, with a notification when an update
  starts by itself and when the new version is running. Update now starts within 5 s (the loader looked once a minute). The new loader is
  used from the next PC start (it updates itself). L-P, L-Fetch, UpdProgress, UpdNow.
- 05-Nov-2026 · Agent 1.22 / Console 1.9 -- The user's Dashboard: "Thaw needed: GUJJAR, GUJJAR" and "2 PCs on an old version". Both laptops
  have no Deep Freeze; a thaw queue from an early wrong Frozen reading waited forever - the agent now clears it on a PC without Deep Freeze
  (logged 🧹, nothing run by itself) and the Console never says Thaw needed for such a PC. "Old version" counts only after the missing
  build has been out 3 hours (PCs update within the hour). A-ThawRun, thawNeeded, oldAgent.
- 05-Nov-2026 · Agent 1.21 / tray 1.13 -- The user: "PC Doctor got uninstalled on 1DAVAN, I pressed nothing". DB5: it was NOT uninstalled
  (agent reporting every minute, no uninstalled mark) - only the tray was gone, closed together with the PowerShell window it ran in.
  The launcher now starts the tray only when it is not running, and a task "Davan PC Doctor Tray" runs it for every user at sign-in and
  every 10 minutes - a closed or crashed tray comes back by itself. Uninstall removes that task too. PD-TrayLauncher, SelfUpdate, A-Uninstall.
- 05-Nov-2026 · Agent 1.20 / tray 1.12 -- The user: "at start a PowerShell window opens with red Get-Content errors". Windows 11 opens
  "powershell -WindowStyle Hidden" in Windows Terminal, which ignores Hidden. The tray now starts through wscript (tray-start.vbs, window
  style 0); the agent (SYSTEM) rewrites the launcher + HKLM Run key at every start, so installed PCs fix themselves; install.ps1 and the
  tray's self-restart use it too. J returns a quiet null for a missing state file. PD-TrayLauncher, J, SelfUpdate.
- 05-Nov-2026 · Agent 1.19 / tray 1.11 / Console 1.8 -- The user: "an option with a password to uninstall the tray software on a laptop or
  desktop". Tray This PC -> Uninstall: password, "also remove MeshCentral?", then the exact list of what goes (service + boot task, tray for
  every user, the ProgramData folder, MeshCentral if chosen); a Frozen PC is refused (Deep Freeze would bring it back). The agent (SYSTEM)
  checks the password again, marks DB5 lab/pcs/<hwid> old + uninstalled {t, who, mesh} (Old PCs, history kept), sends a Super Admin alert and
  hands over to a one-time SYSTEM task that removes everything. Setup again = back from Old PCs. Uninstall, PwText, A-Uninstall, A-SyncPc, pageOldPcs.
- 05-Nov-2026 · Agent 1.18 / tray 1.10 / Console 1.7 -- The user asked "why is 1DAVAN on 95% RAM" - the PC only reported the top programs by
  CPU. checks.ps1 now adds RAM per program (all copies summed, e.g. Firefox's many), lab/now gets rtop (3 items, ~100 bytes a minute, no new
  writes); tray This PC, Copy report, Ask AI and the Console PC page show "RAM used by". PD-Sample, A-Now, Refresh, Report, AskAi, pcPage.
- 05-Nov-2026 · tray 1.9 -- The user: ✨ Ask AI on the laptop did nothing (no answer, no "Asking"). The Ask click ran after LaptopTabs had
  ended, when its own question / answer boxes were gone (PowerShell event blocks do not keep a function's variables). Boxes now at script
  level, AskAi does the work, Enter asks, "Asking ..." shows, a 2-minute "no answer" message, and the question carries this PC's top
  programs + RAM size (so "why is RAM 95%" gets a real answer). AskAi, LaptopTabs, Refresh.
- 05-Nov-2026 · Console 1.6 -- The user: "show the version number always" - the side bar title now reads "Console · Davan College · v1.6"
  on every page (brandVer, set from LAB_VER, so it follows every build by itself).
- 05-Nov-2026 · Agent 1.16 / Console 1.5 -- The user: "duplicate PCs are still showing". DB5 lab/pcs: both laptops (ASUS, Windows 1DAVAN;
  Sony, Windows GUJJARSONY) were Assigned with an empty name box, which kept "GUJJAR" on both and asked Windows to rename both to GUJJAR.
  Console: 📥 New PCs shows the Windows name, the box starts with it (when free), Assign refuses a name another PC already has (nameFree,
  assignPc). Agent: compares with the name Windows gets after the restart and cancels a waiting rename when the Console name is the current
  name again (registry ComputerName + NV Hostname, event ↩). A-SyncPc.
- 05-Nov-2026 · Agent 1.15 / tray 1.8 -- The user: tray bars were plain white lines, nothing worked, buttons showed boxes, small items in a big
  window. Cause: PowerShell names are case-blind - Refresh's $lv overwrote the colour table $LV (and $c / $f overwrote $C / $F in Edit / Pw /
  All PCs), so every refresh crashed silently. Globals renamed ($LVL, $CL, $FT); WinForms buttons / labels without colour emoji (drawn as boxes),
  level dots = coloured ●; every form scaled by hand by the real DPI after its controls are in (Sharp), buttons right under the 7-day line.
  pcdoctor_version.py now refuses any name used in two spellings in one function. Agent: the Console name follows a Windows rename when it
  was never set by hand (two laptops were both "GUJJAR (duplicate)"). Refresh, Sharp, LaptopTabs, A-SyncPc.
- 05-Nov-2026 · Agent 1.14 / tray 1.7 / Console 1.4 -- The user: the new Console password did not work, wants it fixed as given + 👁 show password.
  Password set by the private Action "DB5 set Console password" (lab/secret/consolePw, same salted hash as the worker; lock cleared).
  Console login box + Settings (now an inline New / Again form instead of pop-ups) and the tray password box get 👁 Show. saveConsolePw, Pw.
- 05-Nov-2026 · Agent 1.13 / tray 1.6 / Console 1.3 / worker v22 / DB5 rules -- The user's list: (1) the daily job failed "Index not defined" -
  DB5 rules: lab/events/$h .indexOn t. (2) + (5) setup was slow and silent - PCDoctor-Setup.cmd says it is starting, install.ps1 shows 7 numbered
  steps with the time so far, each downloaded file, the total; the deep first check and the MeshCentral agent run in the background afterwards;
  a re-run stops the old loader / agent / tray first so the new ones really start. (3) tray bars were empty - the agent's minute step crashed
  before writing now.json (fixed in 1.5; reaches the PC with this setup). (4) blurry tray text on the laptop - DPI-aware + every form scales its
  layout (Sharp). Console: its OWN PC Doctor password (worker /lab/tok {pw} + /lab/setpw, salted hash in DB5 lab/secret/consolePw, 10 wrong = 1 h
  lock) - opening lab.html never logs in to the staff app any more (that login made the staff app's sound); inside the staff app it still uses
  the Super Admin who is logged in. 🚪 Log out. New 📊 Dashboard (first page: 8 tiles, health per group, Needs you now, Today, lab load,
  Add a PC), ⬇️ Add a PC always in the header + menu. DB5: reads already loaded by the Console, no new ones. pageDash, setupCard, customLogin,
  labTok, labSetPw, Step, Sharp.
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
