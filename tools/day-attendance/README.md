# Day-by-day attendance - findings and status (paused 07-Oct-2026)

User, 07-Oct-2026: "we'll stop this setup here - keep what is built, keep all findings in GitHub for later."

## What is LIVE and stays as it is
- **Scraper `app.py` v089** (on the admin's PC, not in git - it holds the portal password). Every scheduled run (1:00 pm / 5:30 pm)
  also saves that day's per-student attendance to DB2 `davan_pub/att_day/<YYYY-MM-DD>/<URN> = {s: {subject: [held, attended, mc]}, at}`.
  Days older than 35 are deleted by the same run. Test link: `http://localhost:5000/api/scrape_today?date=YYYY-MM-DD`.
- **Staff app v1796: 📅 Day Attendance** page (Analysis) reads one day (1 DB2 read, ~100-250 KB) and shows per class who was
  absent all day / missed some subjects / on MC.
- Days before 06-Oct-2026 are empty (only 06-Oct was saved by hand with the test link). From now on each college day fills in by itself
  while app.py v089 runs.

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
   Cost checked: DB2 ~3-7 MB for 30 days (1 GB free), ~30 writes, almost no downloads. Load is on the college site: ~90 requests per day,
   ~2,700 for 30 days -> add a 1 s pause, run once in the evening, not at 1:00 / 5:30 pm, PC on ~45-60 min.
2. **Cloud scraper** (no laptop, free): private repo `davan-scraper` + GitHub Actions running `python app.py --run-once` (v088 has it;
   portal login from secrets DAVAN_PORTAL_USER / DAVAN_PORTAL_PASS, Firebase keys as secrets), started by the Cloudflare worker at
   1:00 pm and 5:30 pm IST Mon-Sat. app.py must never go to this public repo.
3. **Student side**: lock-screen card, widget, portal "Your day". Rule: each phone reads ONLY its own `att_day/<day>/<URN>`, never a whole day.
