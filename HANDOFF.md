# Session handoff - read this first (plug and play)

Last updated: 09-Oct-2026 (student widget build 208 = settings screen, update progress, calendar events, on "next"). A new Claude session reads CLAUDE.md (rules) and
then this file (where things stand). The user should not have to repeat anything below. Update this file at the end of every
session (same commit as the work), keep it short, newest state only.

## How the user works (keep doing this)
- Plain language, short answers. The user writes quickly with typos; read for meaning.
- Always give the widget **build number AND display number** (e.g. "build 201 = w183 for everyone, w182.7 on test phones").
- Answer in chat. Mockups only when asked; when asked: a private HTML file sent with SendUserFile (real student data never published).
  Show NOW vs NEW side by side and list what changed. Keep the existing layout unless told otherwise.
- **Default for every mockup (user, 09-Oct):** NOW and NEW side by side + "what changed" under each pair. For a redesign, first list
  every item on the current screen (incl. Super Admin-only parts and sub-pages like the widget's page 2 "Open as") - nothing may go missing.
- After every change: versions + changelogs, commit, push the session branch, merge to main, push main - never ask (CLAUDE.md).
- Widget builds go to the "-next" channel only; the nightly Cloudflare timer (9:15 pm IST) releases them. Don't start a release
  unless asked. Super Admin can stop it (Global Switches -> Widget updates).
- Say honestly what could not be tested on a phone.
- Never ask the user to paste tokens/keys into chat. Secrets live in GitHub Secrets (davan-scraper repo).
- Login / admin push alerts go only to the Super Admin.

## Current versions (08-Oct-2026)
| App | Build | Notes |
|---|---|---|
| Staff app (index.html from src/index.src.html) | CODE_BUILD 1819 | student widgets below build 133 blocked; 🔔 page "📌 Who keeps the lock-screen card"; 🕷 Scraper page (runs, settings, history) |
| Student portal (student_portal.html) | v11.55 | widget floor 133; admin Widget tab (admin Moto test phone left out): live "Not on w<N> yet" list (A / B / C) + "📌 Who keeps the lock-screen card" |
| Student widget | build 201 = **w183** public (released 08-Oct 9:16 pm) | next = 209 (209 = fewer DB2 downloads: lesson plan / internals / timed copies follow pub_ver; 📌 lock card, 🔔 labels, update state, no repeated lesson plan; 205-206 = new settings screen (chips for My pages / Speak), 207 = update progress "connecting" + % bar, 208 = any calendar event (Davan Carnival) on Today / evening note / lock card, with 📌 / 🙈 switches, reports lock {off, hide, at}) |
| Staff widget (Davan Staff) | build 256 = **w231** public (released 08-Oct 9:16 pm) | next = 261 (261 = clearer Weekly class feedback switches ✅ ON | OFF; 260 = slot shows the full run; 259 = 🕷 scraper line + alert for the Super Admin; 📌 lock card, 🔔 alert labels; 258 = new settings screen like the student widget, 📌 / 🙈 switches, lock in staff_widget_report) |
| College scraper app.py (PRIVATE repo harshgujjar/davan-scraper) | v103 (sync v2.11.0) | runs in the CLOUD by itself (GitHub "Scrape (run once)" 1:00 pm + 5:30 pm IST Mon-Sat, backups 1:45 / 6:15) - no laptop needed |

## Widget sources (private repo, not this one)
Newest sources: harshgujjar/davan-scraper (PRIVATE) folder `widgets/student` (build 208) and `widgets/staff` (build 260) - add_repo +
clone it, read widgets/README.md. Keystores: the user uploads `widgets/student/davan-student-widget.keystore` and
`widgets/staff/davan-widget-release.keystore` there (Claude never copies key files - blocked as credential leakage on 08-Oct); if they
are missing, ask the user to upload them (or the zips). Then `bash tools/widget-toolchain.sh`, build with
`ANDROID_JAR=$HOME/tc/android.jar bash build.sh`. From w199 / w256: `layout-master/` holds the card + main layouts and `gen_sizes.py`
(run by build.sh) writes res/layout/*.xml, *_m.xml (92%), *_s.xml (85%) - **edit layout-master/, never res/layout/**.
dx needs `--min-sdk 24`: **no Java lambdas** (use anonymous classes). After a build: copy the source back to davan-scraper/widgets, push.

## What was built this session (all live)
- Student widget w199-w201: new Today page look (badges, live countdown on NOW, "TEACHING NOW" topic, "Prof." names, "Your last
  class: Present/Absent" per subject from day-wise attendance, Yesterday/Attendance lines with faculty name + small photo, "40/10"
  marks stripped by Pages.sn), header card with progress-ring photo, bottom bar (numbers on own line, Updated time + date, version tags,
  "© BUILT BY DAVAN" logo colours), text size by widget size on all pages, lighter animation, neat "Your semester".
  w201: Results names from codes (SubjNames = copy of portal STU_KNOWN_NAMES - keep both in step), faculty of that semester under each
  result subject (allocation_each_c), lock-card header "Name · date", settings Close only closes (Android cannot jump to a home page).
- Staff widget w256: same size rule (100/92/85%).
- Earlier the same day: day wrap-up notification (student, 30 min after last class), portal wrap-up card, update-install hotfix,
  duplicate-notification fix, "Professor" in spoken names, faculty Day Attendance by subject, DB2 pub_hash, app.py v095-v100.

## Open items / next steps
- 10-Oct: DB2 "fix all 6" done (portal v11.55, staff v1819, widget build 209 on next, app.py v103 / sync v2.11.0): every writer stamps
  davan_pub/pub_ver/<key> on a REAL change (scraper: lessonPlan; sync: students, allocations, allocation_each, internals_current,
  faculty_photos, + writes allocation_each_c / internals_stu); phones keep copies up to 72 h. CHECK on 11-Oct with the DB2 usage
  workflow (inputs day=2026-10-10, sizes=1): row diag~allocEachFull~... = current portals still reading the whole allocation_each
  (if it is 0 but davan_pub~allocation_each still has reads, those are old app copies). portal_students (admin, 278 KB) left as is
  (changes on every login). DB3 widgetConfig/news is DB3, not DB2.
- 09-Oct: user applied for Claude for Open Source (free Max); README.md rewritten to current state (keep it current - reviewers may look).
- **In-app voice calls (students <-> faculty)**: user asked 09-Oct ONLY as an enquiry (mockup shown) - NOT to be built unless the user asks again.
- Student widget build 208 adds college calendar events (any type) to Today / evening note / lock card; the staff widget does not have it yet (offered).
- Staff widget settings redesign: BUILT 09-Oct as staff build 258 (next) - check it on a phone.
0. Photo ring on the student widget header: user may pick a % badge or a full ring (offered, not answered).
1. **Check the new Today page on a real phone** (built without device testing): DAVAN colours, countdown badge, small photos per line,
   Results faculty names, lock-card header. Fix whatever the user reports.
2. **DB2 daily usage check**: run the private davan-scraper workflow **"DB2 usage"** (Actions -> DB2 usage -> Run workflow, or the
   GitHub MCP actions_run_trigger with workflow_id db2-usage.yml) and read the job log - same numbers as the staff app meter page,
   read only, uses the SA_DB2 secret. Do NOT sign up anonymous tokens (blocked). 09-Oct at 11:03 pm: 43.7 MiB (15% of 300 MB); 08-Oct full day 71.5 MiB;
   7-Oct 109.5, 6-Oct 96.2, 5-Oct 106.7 MiB. Biggest: portal allocation_each (old full node, 4.9 MiB / 113 reads - old cached
   portals), lessonPlan (staff app 4.6 MiB), timetable_portal 4.0 MiB. Expect a small bump on 09-Oct (w201 re-reads results once).
3. Scraper (app.py v102): every run / skipped slot -> DB2 davan_pub/scraper/{runs, status}; settings from the staff app's 🕷 Scraper page
   (scraper/cfg: s1, s2, marks, groups, sitting, holidaySkip); holiday / off Saturday = 1 pm light run (day attendance only), 5:30 skipped;
   day-attendance notes in scraper/att_state. NOT built yet: in-app "Run now" (needs the Cloudflare worker's GitHub key to reach the
   private davan-scraper repo - the page links to GitHub "Run workflow" until then).
   Scraper is fully automatic in the cloud since 09-Oct (user: "I built this so I don't need the laptop"). Check any time with the
   davan-scraper workflow "Scrape status" (read only: last DB1 scrape, att_day dates, lock). The laptop copy may still run; the slot guard
   (SLOT_GUARD_MIN 120) + DB2 scraper_lock stop double scrapes. If a run fails, run "Scrape (run once)" by hand.
4. Student 3:15 pm note: add present/absent counts + topics missed (offered, not built).
5. Swaroop (student) needed a one-time manual install of the widget (Files -> Downloads -> APK) because of the old "Open with" bug.
6. Widget keystores: uploaded by the user to davan-scraper/widgets on 08-Oct and checked - a test build from the repo signs with the
   same certificate as the released APKs (student 9ed273b8…, staff d5a018f5…). New sessions can build straight from there.

## Side project: Status Date (PARKED by the user, 09-Oct-2026)
Day / date / month on the status bar (user's own app). Do not work on it unless the user asks. When asked, show the private
davan-scraper `apps/statusdate/PLAN.md` (state v8, future plan: free Google Play version, fallbacks, market check) and README.md.
Its key `statusdate.keystore` is not uploaded yet - the user will add it to apps/statusdate later.

## Who is on an old student widget
Run the private davan-scraper workflow **"Widget versions"** (GitHub MCP actions_run_trigger, workflow_id widget-versions.yml); it saves
`reports/widget-versions.csv` + `widget-versions-summary.txt` in davan-scraper (git pull them). One row per student (latest widget code;
older codes = earlier installs). Reasons: A build < 133 cannot self-update (install once by hand), B update downloaded but not installed
(needs a tap / "Install unknown apps"), C not checked in for 3+ days. 09-Oct 07:45: 104 students, 21 on w183, A 31, B 25, C 27.
From w203 the report has `upd` (step, error, canInst, installer) - check it to see exactly why B is stuck.

## Student widget minimum (block)
Since 09-Oct-2026 widgets below build **133** are blocked (they cannot update themselves): staff app STU_WIDGET_BLOCK_V = portal
STU_MIN_WIDGET_FLOOR = 133, DB2 davan_pub/student_widget_latest.minApkVersion = 133 (set at once by the davan-scraper workflow
"Set widget minimum", input min). Keep all three equal or the apps rewrite each other.

## Useful facts
- Release log: `release-log.json` ("by": "Cloudflare 9:15 pm" = the timer worked). Display numbers: `display` in the public jsons.
- Day attendance data: DB2 davan_pub/att_day, att_fac, att_stu/<URN>/<date>; scraper saves after 1 pm for the last college day.
- DB2 meter: davan_pub/meter (bytes; the page shows MiB - 1 MiB = 1.048 MB).
