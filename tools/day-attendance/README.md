# Day-by-day attendance - findings and status (paused 07-Oct-2026)

User, 07-Oct-2026: "we'll stop this setup here - keep what is built, keep all findings in GitHub for later."

## What is LIVE and stays as it is
- **Scraper `app.py` v089** (on the admin's PC, not in git - it holds the portal password). Every scheduled run (1:00 pm / 5:30 pm)
  also saves that day's per-student attendance to DB2 `davan_pub/att_day/<YYYY-MM-DD>/<URN> = {s: {subject: [held, attended, mc]}, at}`.
  From v090 old days are NOT deleted automatically (user, 07-Oct-2026): the admin deletes them in the staff app (v1797) - 🗑 Delete saved
  days on the Day Attendance page, or the question asked when a new semester is set active (delete = new semester starts fresh, cancel = keep).
  A full semester is about 25 MB in DB2 (1 GB free). Test link: `http://localhost:5000/api/scrape_today?date=YYYY-MM-DD`.
- **Staff app v1796: 📅 Day Attendance** page (Analysis) reads one day (1 DB2 read, ~100-250 KB) and shows per class who was
  absent all day / missed some subjects / on MC.
- Days before 06-Oct-2026 are empty (only 06-Oct was saved by hand with the test link). From now on each college day fills in by itself
  while app.py v089 runs.

## app.py v093 - faculty summary (07-Oct-2026)
With every day collect: `davan_pub/att_fac/<date>/<class>/<subject> = {f: faculty, h: held, p: present count, a: [absent URNs],
m: [MC URNs]}` (~10-15 KB a day) + `pub_ver/att_fac`. The faculty name comes from the portal's own column heading
("Java Programming Pooja C ( 44 )"), matched against the allocation subject names first, so "C Programming MadhuMalathi B" gives
"MadhuMalathi B" (_faculty_from_heading). att_fac days follow att_day (deleted with it). Functions: scrape_day_attendance, push_day_attendance_to_db2, sync_att_stu.
Mockup of every screen (student portal / widget / lock screen / notification, faculty card / widget / notification, class in-charge,
principal) was made with the real 6-Oct-2026 data and sent to the user as a file (not kept in git: real student names).
Agreed so far: faculty notification 6:00 pm, student 3:15 pm break, lock screen counts only.

## app.py v092 - each student's own days (07-Oct-2026)
For the student app / widget / lock screen / notification (planned, not built yet): after every day collect the scraper also keeps
`davan_pub/att_stu/<URN>/<YYYY-MM-DD> = {subject: [held, attended, mc]}` - the last 30 college days still in att_day (~2 KB per
student). `davan_pub/att_stu_meta = {days, at}`; `davan_pub/pub_ver/att_stu` (ms) moves only when it changed, so a phone reads
ONLY its own `att_stu/<URN>` and only when that stamp moved (about 1 MB a day for 400 students). Days the admin deletes from
att_day drop out at the next run. `/api/sync_att_stu` rebuilds it now. Function: sync_att_stu.
Planned display (agreed outline): portal "📅 My days" card (yesterday's subjects ✅/❌/MC, 2-week dots, streak, "attend the next N
classes"), widget line + dots, lock screen counts only (no subject names), notification at the 3:15 pm break only when a class was
missed (registry entry on the 🔔 page, ON by default) + a Saturday "full week" note.

## app.py v091 + scraper_panel.html v091 (07-Oct-2026)
User: "collecting twice a day will slow davandvg.com - only once, at 1 pm, for yesterday".
- The per-day pass runs ONCE a day (first scheduled run, 1:00 pm) for YESTERDAY (Monday -> Saturday, Sundays skipped) and also fills
  up to 3 recent college days still missing in DB2. Days with no class marked (holidays) are remembered in `att_day_state.json`.
  The 5:30 pm run no longer asks for it (~90 fewer requests to davandvg.com a day). The first v091 run also fills 3 and 5 Oct.
- Run log: every scheduled run, manual scrape and manual day collect writes what each step did and every problem to `scrape_runs.json`
  (last 60); `/api/run_log`, scraper panel card 07 (📋 Copy). New: `/api/att_day_days`, panel card 06 (saved days, collect one day).
- Fixes from a full review of app.py: a scrape with 0 students never overwrites DB1; classes that failed to load (request errors)
  keep their previous data; manual scrape / Force Sync / day collect never overlap a running scrape (_session_lock); the manual
  scrape and the day collect log in again by themselves; a failed lesson-plan topic fetch no longer wipes the stored topics;
  scheduled and manual scrapes store the same student fields (_normalize_students); the scheduler thread survives a failing job and
  UTF-8 console (emoji printing on Windows); day saves merge (update) instead of replace; /api/status shows last run / last sync result
  / last push after restart; --run-once exits 1 on failure; /panel serves scraper_panel.html.
- Not fixed (noted): times use the PC clock (fine on the PC in IST; for a cloud runner use IST explicitly); the lesson-plan archive step
  re-reads the whole lessonPlan node every run.

## Findings (checked live on the admin's PC)
- Portal attendance request: `GET http://www.davandvg.com/dashboard/redicore.php` with
  `reqst=srch key=fata cig=1 sx=<section 1..5> csm=sm=<sem> crs=<1 BCA|2 BCom|3 BBA> crstxt=<B|C|BA> brch=-1 dtf dtt subId=undefined studId=undefined`,
  headers `X-Requested-With: XMLHttpRequest`, `Referer: .../dashboard/attendance.php`. Login: POST `/rediCore.php` `reqst=login ty=a u p`, success = `1`.
- **The date filter only works with year-first dates: `2026-10-06`** (or `2026/10/06`). `06-10-2026`, `06/10/2026`, `10/06/2026` give an
  EMPTY table - that is why the first try saved 0. Blank dtf/dtt = whole-term totals (what the normal scrape uses).
- dtf = dtt = one day gives that day only: each subject held 0-2 (max seen 1 per day; 2 for day..next day). A subject with no class that
  day shows `-1 -1` (same as "not enrolled") and is skipped.
- 06-Oct-2026 result: 8 classes, 373 students, 471 absent subject-entries.
- Status per subject: attended >= held -> present; attended + mc >= held (mc > 0) -> MC; else absent. "B" (blocked) counts as absent,
  exactly as the portal's own % does ((CA + MC) / CT).
- `tools/day-attendance/test_day_attendance.py <YYYY-MM-DD> [crs sem sec]`: standalone test (no DB writes) that tries the date formats.
  Login from env DAVAN_PORTAL_USER / DAVAN_PORTAL_PASS or app.py next to it.

## Paused / not built (pick up from here)
1. **Fill past days (backfill)** - code ready in `backfill_day_attendance_snippet.py` (app.py v090, never released):
   `/api/backfill_days?days=35` (background, progress `/api/backfill_days_status`) or `python app.py --backfill 35`.
   (Drop its 35-day cap now that days are kept.) Cost checked: DB2 ~3-7 MB for 30 days (1 GB free), ~30 writes, almost no downloads. Load is on the college site: ~90 requests per day,
   ~2,700 for 30 days -> add a 1 s pause, run once in the evening, not at 1:00 / 5:30 pm, PC on ~45-60 min.
2. **Cloud scraper** (no laptop, free): private repo `davan-scraper` + GitHub Actions running `python app.py --run-once` (v088 has it;
   portal login from secrets DAVAN_PORTAL_USER / DAVAN_PORTAL_PASS, Firebase keys as secrets), started by the Cloudflare worker at
   1:00 pm and 5:30 pm IST Mon-Sat. app.py must never go to this public repo.
3. **Student side**: lock-screen card, widget, portal "Your day". Rule: each phone reads ONLY its own `att_day/<day>/<URN>`, never a whole day.
