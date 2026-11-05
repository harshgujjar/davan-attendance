# 🖥️ Davan PC Doctor - changelog (newest first, never deleted)
Parts: PC Doctor Agent (background), PC Doctor (tray window), PC Doctor Console (lab.html), PC Doctor Rescue (pendrive).
Versions of every part: pcdoctor/lab-version.json. Plan: ROADMAP-pcdoctor.md.

- 05-Nov-2026 · tray 1.24 -- The user renamed a lab PC to B1 and the tray still showed DESKTOP-H25PRDD (the Windows name, changed only at a Thawed restart). Title + headline now show the Console name; facts list gets Name + Windows name rows. PcNames.
- 05-Nov-2026 · Agent 1.42 / worker v25 -- The user's laptop tray: "Last check 2.12 PM: No internet - could not reach the update server" - stuck on 1.29 for 3 h while online
  (agent reporting). Its running (old) loader tried only raw.githubusercontent.com. New loader: third road through the worker (GET /lab/raw, files still
  checked by SHA-256) after raw and api.github.com. A running old loader needs one service restart (net stop / start PCDoctorSvc) or the update pendrive.
- 05-Nov-2026 · Agent 1.40 / tray 1.23 -- The user: "Show me this PC is not working". DB5: the PC got the command and answered "done" within seconds - the pop-up
  is shown by the tray, and a tray whose window had been left open since before the update never replaced itself (it waited for the window to close). Now
  it tells the user in the message line, waits about 45 s and restarts itself with the window open again (the launcher takes /show). SelfUpdate, PD-TrayLauncher.
- 05-Nov-2026 · Console 1.14 -- The user: "keep the same notes in lab.html also" - side menu 📒 Notes (how it works) shows pcdoctor/src/notes.txt (the very same file as the tray's
  Notes tab; Copy button), so the two never differ. pageNotes.
- 05-Nov-2026 · Agent 1.37 / tray 1.22 / Console 1.13 -- The user: from the web app with 30 PCs, "which PC am I working on" - a pop-up on the PC. Console PC page
  "📍 Show me this PC" (and automatically when Remote screen is opened) sends the read-only command identify; the agent writes state/identify.json and
  the tray shows the PC's Console name (B6 ...) BIG on its own screen for 10 s with a sound (click closes). Picked up within ~14 s. identify, IdentifyShow, openMesh.
- 05-Nov-2026 · Agent 1.36 / tray 1.21 / worker v24 -- The user: the web app is slow to check and reply; give the Super Admin laptop's tray the options.
  Tray All PCs tab (laptop only): pick PCs, "How much it frees" (read-only), "Clean now" (deletes: list + password), "Delete old history" (count, then
  list + password) with the answer in a box within seconds (Copy). The laptop agent sends through the worker (POST /lab/cmd, /lab/cmdres, /lab/purge;
  the laptop key + salap are checked there) and re-checks the password for the deleting steps. All PCs now look for commands every 14 s (was every
  minute) - also faster for the web app. Data: lab/cmd, lab/res, lab/events (purge keeps the last 30 days). A-LabCmd, A-LabPoll, LabSend, LabPurge, LabUi.
- 05-Nov-2026 · Agent 1.35 -- The user: a lab PC set to Boot Thawed (Deep Freeze Standard 8.60 dialog) was shown "Frozen". PD-DeepFreeze guessed from a marker
  file and only counted the first minute after a boot. Now once per boot: the boot id written to a local file last session is compared with the one kept in DB5
  (lab/pcs/<h>/dfBoot): same = the write survived the restart = Thawed, different = Frozen; kept for the whole boot. The Boot Control tab in the Deep Freeze
  window shows "Status on NEXT boot", not the state now. PD-DeepFreeze.
- 05-Nov-2026 · Agent 1.34 / worker v23 -- The user installed 2 identical lab PCs and the Console showed ONE PC. DB5 lab/fp: both have the cheap H610M board's
  placeholder BIOS UUID 03000200-0400-... (+ "Default string" board serial, same CPU id = 45 points), so the second took the first one's hwid and a new key.
  Worker: those placeholder UUIDs never count, and different MAC + different disks = different PC (fpScore). Agent / Setup: a PC whose key does not match
  registers again as a NEW PC by itself (PD-Token, install Step 3). Both lab PCs: run PCDoctor-Setup.cmd again (or wait - the agent re-registers).
- 05-Nov-2026 · Agent 1.33 / Console 1.12 -- The user ran the DFC.exe test on new lab PC B1 (not found) and showed "Overheating" at 41-45 C + "Thaw needed" +
  B1 in Lab 1. Overheating: an idle CPU's low speed (power saving) and Windows' "speed limited" events counted as heat - now speed counts only while
  the CPU is busy (50%+) and the slow-down events only when the CPU reached 80 C. Thaw needed: the Windows rename to B1 (a Frozen PC waits for Thawed -
  as designed). Group: Assign kept the first group (Lab 1) - typing a name now picks its group (B1 -> Lab 2). A-Verdict inputs, pickGrp.
- 05-Nov-2026 · Agent 1.32 / tray 1.20 / Console 1.11 -- The user: (1) update reach the laptop + test PCs in 5 min not 1 h; (2) a footer so everybody
  knows who built it; (3) install on a lab PC with no internet. (1) loader: Super Admin laptop + lab/cfg test PCs look every 5 min (cfg fastMin);
  the agent restarts a loader that is older than loader.ps1 (service starts it again in ~30 s) so the new loader needs no PC restart. (2) tray footer
  "Built by Harsh Gujjar for Davan College, Davangere - built with Claude" (cfg footer overrides). (3) Console Rescue page "Make offline install
  pendrive" (PCDoctor-Setup.cmd + src with lab-version.json); install.ps1 offline branch checks every fingerprint, writes running.json, copies
  notes.txt; registration failing = installs anyway and the agent registers by itself when internet comes (Thawed!). Notes tab updated.
  Loader, agent start, install.ps1 Step 2/3, makeOfflineSetup.
- 05-Nov-2026 · tray 1.19 -- The user: "keep all these steps in new notes in the tray so I know how it works after some days". New Notes tab
  (copy button) showing src/notes.txt - install, passwords, Command Prompt steps, tray / agent not working, updates + update pendrive, Deep Freeze
  behaviour, the DFC.exe test for an automatic Thaw / Freeze in lab hours (planned, not built), buttons, who to ask. notes.txt is downloaded
  with the other files (pcdoctor_version.py lists it), so the notes are editable on GitHub and read offline. NotesLoad.
- 05-Nov-2026 · tray 1.18 -- The user: "give every point a serial number" - the This PC facts list has a No. column (1, 2, 3 ...), then what | value.
  FactRow.
- 05-Nov-2026 · Agent 1.29 / tray 1.17 / Console 1.10 -- The user: neat, aligned tray facts + "build the update pendrive". Tray This PC: the facts are
  now a two-column list (what | value), one fact per row, RAM programs and the last-7-days findings one per row, coloured, PC Doctor version
  from the running build. Offline update: Console Rescue page -> "Make PC Doctor update pendrive" (DavanUpdate folder: lab-version.json +
  src files, each checked against its fingerprint); tray Updates -> "Update from pendrive" (password goes with the request, the SYSTEM agent
  checks it again + every fingerprint + a newer build; old copy kept for the 10-min rollback; progress bar). Needs 1.29 already installed.
  FactRow, UsbUpdate, A-UsbUpdate, A-PwOk, makeUpdatePen.
- 05-Nov-2026 · Agent 1.28 -- The user: Windows Script Host "tray-start.vbs line 8 Unterminated string constant" (shown at each tray start / 10-min
  check). In PD-TrayLauncher the comma bound tighter than + so the tray path landed on a line of its own; the Run line is now one bracketed string.
  The agent rewrites the launcher by itself at its next start (new text differs).
- 05-Nov-2026 · tray 1.16 -- The user: "Open Console button on every tray". This PC tab + the tray icon's right-click menu get "Open Console" on
  every PC: asks the tray password (unless unlocked), then opens lab.html in the browser, which has its own login + lock-out. Address from DB5
  lab/cfg consoleUrl (fallback harshgujjar.github.io/davan-attendance/lab.html). OpenConsole.
- 05-Nov-2026 · Agent 1.25 -- The user: "Update now says no internet" - 1DAVAN online (agent reporting) but its updater could not reach
  raw.githubusercontent.com (stuck on 1.19). The loader now tries 3 times, then GitHub's API as a second road, says the real reason, and a failed
  check retries in 5 minutes (was 1 hour). New read-only command loader_log (last 30 updater log lines). L-Get, L-Fetch, A-Cmd.
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
