# 🖥️ Davan PC Doctor - changelog (newest first, never deleted)
Parts: PC Doctor Agent (background), PC Doctor (tray window), PC Doctor Console (lab.html), PC Doctor Rescue (pendrive).
Versions of every part: pcdoctor/lab-version.json. Plan: ROADMAP-pcdoctor.md.

- 04-Nov-2026 · Agent 1.5 / checks 1.3 -- First real PC (the user's laptop): (1) every minute failed with "$S.ring is null" - PowerShell
  names are case-blind, so the sample variable $s replaced the agent state $S (no minute rows, wrong verdict / Deep Freeze state in lab/now);
  renamed in A-Minute / A-Now / A-Live, and tools/pcdoctor_version.py now refuses to publish a function that uses both $s and $S.
  (2) Get-WinEvent "The parameter is incorrect" stopped the event reading - each source is read on its own (2 provider names one by one),
  a failing source is logged and skipped. (3) A plugged-in pendrive was listed as "the disk" (false "Disk replaced") - USB / SD / virtual disks
  left out, Windows disk first, SMART matched by device path. No new reads / writes. A-Minute, A-Now, A-Live, PD-ReadEvents, PD-Smart.
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
