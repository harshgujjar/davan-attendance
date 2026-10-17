# Session handoff - read this first (short, current state only)

Last updated: 17-Oct-2026. Old detail (history, done items, numbers): `HANDOFF-old.md` - grep it only when a task needs it.
Keep THIS file short: replace old lines, do not append history (history goes in the changelogs / commit messages).

## How the user works
- Plain language, short answers; the user types fast with typos - read for meaning.
- Widgets: always give **build number AND display number** (e.g. "build 201 = w183 for everyone").
- Mockups only when asked: private HTML via SendUserFile, NOW vs NEW side by side + "what changed".
- After every change: versions + changelogs, commit, push branch, merge to main, push main - never ask.
- Widget builds go to "-next" only; the 9:15 pm Cloudflare timer releases them. Never start a release unless asked.
- Say honestly what was not tested on a phone. Never ask for tokens / keys in chat (secrets = GitHub Secrets in davan-scraper).

## Current versions
| App | Now | Notes |
|---|---|---|
| Staff app (src/index.src.html -> index.html) | v1897 | details: CHANGELOG-admin.md |
| Student portal (student_portal.html) | v11.75 | CHANGELOG-portal.md |
| PUC app (puc.html) / parent_ptm | v5.246 / v4.7.4 | v4.7.4 + scraper puc_scrape p2 / puc_marks p3 (17-Oct): a student the portal blocks for fees (0 held, left out of marks) keeps the last good data - AISHWARYA R B 1D26004 blocked 2 days, card showed 0/0; republish her card; v4.7.3 Test scheme "🔁 Apply max / pass to published cards" (fix pass mark without republish); v5.246 Mid Term % out of 80; Mid Term round in PTM view logs; a student missing from an exam bucket is filled from All Exams (AISHWARYA R B 1D26004 missing from mid_term/1PUC-COM-A cloud scrape 16-Oct) |
| Student widget | public build 241 = w193 (16-Oct, hand release); next = 243 (243: page 2 "⬅ Settings" no longer drops the opened student - only ↩ Back to me does, like staff w210; user saw a newly opened student "come back to V NEESHA". Super Admin phone = EMTH7Q) (242: server cards - Cards.java draws davan_pub/cards_by_urn/<URN> rows; first card exam_seat from sync v2.9.2) (241: "For the 2nd internal" per-subject window card on Attendance + Internals) (240 (240: morning brief says holiday on a holiday) (239: hostel students on approved leave get no class reminders / next / tomorrow / morning "no class" until the last leave day; leave from StuHostel snapshot) (238: morning brief always spoken + "Dear name" on all voice) (237: What's new fold; 236: internal card from 60 days; 235: hostel fee on Today, page 2 filters All/Installed/New/Old/Hostel) (232: exam page no empty / "Regular Class" lines; 233: father name from results_by_urn / parent_overrides when portal_students has none; 234: ▶ day button on the name line, phone · F/o father plain below, main layout renamed widget_top) - public 16-Oct 9:15 pm. Test student V NEESHA (widget code KPGYNC) is in student-widget-next.json codes = gets every next build at once | source davan-scraper widgets/student |
| Staff widget | public build 295 = w239 (16-Oct, hand release); next 295 (295: morning brief always spoken) (293: ☁️ alerts; 294: What's new fold) | source davan-scraper widgets/staff |
| Scraper app.py (davan-scraper) | v108 | runs in the cloud, Cloudflare worker davan-release v9 starts it |

## Where things are
- Widget sources + keystores: private **harshgujjar/davan-scraper** `widgets/` (README there). Toolchain: `bash tools/widget-toolchain.sh`,
  build `ANDROID_JAR=$HOME/tc/android.jar bash build.sh`; edit `layout-master/`, never res/layout/; no Java lambdas.
- Cloud jobs (davan-scraper Actions): Scrape (run once), PUC scrape, PUC marks, Sync allocations, Sync seating, DB2 usage, DB2 peek,
  Widget versions, Scrape status, Class feedback status. Cloudflare worker code: tools/cloudflare-release-worker.js (auto-deployed).
- Firebase DB2 = FREE Spark plan, 10 GB downloads / month: stay under ~330 MB / day (ask the user for the console screenshot to check).
- Student widget floor: build 133 (STU_WIDGET_BLOCK_V = STU_MIN_WIDGET_FLOOR = DB2 minApkVersion - keep all three equal).

## ☁️ Super Admin cloud alerts (v1853, 15-Oct)
- Every alert = POST davan-release.harshgujjar.workers.dev/sa -> DB2 davan_pub/sa_ev (+ sa_ev_at) + push to laptops in davan_pub/sa_push
  (via fcm-push; sw.js tag sa-<colour>-<id>). Phone = staff widget SaEv (w293+, Super Admin only, polls ~5 min). Jobs: last step
  `tools/sa_notify.py "<name>" <kind>` (both repos), text from $RUNNER_TEMP/sa.json; a job alert must name its own running run (worker checks).
- 9:30 pm usage alert = worker cron "0,15 16" (16:00 UTC); Cloudflare account has 5 timers in total - do not add a timer.
- New job / feature that should tell the Super Admin: add the sa_notify step (or saPost in the staff app). Laptop: staff app ☁️ Cloud alerts -> "Get alerts on this laptop". From v1896 saAutoKeep re-adds the laptop on every open (address renewed -> worker dropped it).
- Not phone-tested: w293 channels / sounds; laptop photo + strip.

## Side projects (user's own)
- **Usage Meter for Claude** (browser extension): source davan-scraper `extensions/usage-meter/` (build.sh -> -firefox / -chrome zips).
  v1.6.1 SUBMITTED to addons.mozilla.org 15-Oct (slug usage-meter-for-claude) - waiting for approval. Heartbeat -> DB4
  claude_meter/users, shown on the staff app 🧮 Claude Meter page (v1852). Updates: raise version, user uploads "Upload New Version".
- **Claude Pulse** (Android usage widget, upstream G-biggy/claude-pulse-android): source davan-scraper `claude-pulse/` (DAVAN-NOTES.md,
  build.sh). v2.6 sent 15-Oct: pace advice + notifications, floating bar over the Claude app, bigger text, usage details. Key
  claude-pulse.keystore (alias claudepulse) - user to upload it to davan-scraper/claude-pulse/ (ask for it + its password). Not phone-tested.
  v2.7 (15-Oct, source pushed, compiled, signed v2.9 LIVE via ClaudePulse.apk + claude-pulse-version.json, self-updating): fixes repeated alerts (week-key jitter), alerts only while Claude is open, notification
  settings + weekly graph. Release: copy APK to ClaudePulse.apk + raise apkVersion in claude-pulse-version.json. Keystore password: ask the user.
- Status Date app: PARKED (davan-scraper apps/statusdate/PLAN.md) - only when the user asks.

## Open items
- Exam seating (v1866): Option A strict - 4 classes per room (sitPlanSlotSeatingA), 2 sides x 8 benches; regenerated when Sitting or Attendance tab opens. Not tested on real data yet.
- IA eligibility (v1860): 2nd internal = only classes after the IA1 cutoff (5-Sep) - students may look fine on the widget (whole semester) but be short in that window. +1/+2 rule now applied live. Window % now shown to students: portal v11.73 Attendance card, widget 241 (staff app v1861 publishes ia_live_status IA2 row .w). Not phone-tested.
- Load speed (user, 17-Oct): v1894 - opening screen closes on the cached draw + cached profile at restore (the real wait); v1892 - sw.js davan-v12 serves js/admin-*.js cache-first; photo lists cached in IndexedDB davan_kv (dvKvGet/Put/Stale); admin auto-mirror once per 6 h. Not phone-measured. Next if still slow: per-page tables (which panel/table is slow - ask user), app_data/students (biggest read) cached in IndexedDB instead of localStorage, defer scripts.
- Seating per exam time (v1877): davan-scraper sync v2.9.1 writes sitting_by_urn perDay rows {date,time,room,seatNo,bench} for the newest Internal with SLOT plans; portal v11.75 shows them. Student widget still reads perDay date->room only (2 exams on one day: shows the last room, top-level bench = first exam) - next widget build should show time + bench per row.
- V Sem BCA Software Engineering: user to confirm if Vijayalakshmi teaches the MORNING batch (then section B - undo the swap in Edit Allocation).
- PUC: rovelabs login is typed into puc.html (public) - user to change the password; offered to remove the prefill.
- PUC Mid-Term: re-scrape when 2PUC COM-B / C marks are entered. 16-Oct: 2PUC BS + EC have no Mid Term on the portal (all classes); AISHWARYA R B (1D26004) has no English / History Mid Term (English 53 typed as "IA - 3"). Missing-students check = compare puc_marks/<AY>/<exam>/<class> with /all (public REST read).
- Fees / SD books (v1848+): DB2 rules may need fee_cfg / fee_paid / sd_sub / sd_done if a save says 401. v1854: hostel fee = fee_cfg/h + fee_paid/<URN>_H; bulk SD dates; staff widget does NOT yet show the fee window / who opened it (needs a staff widget build - offered).
- Not phone-tested yet: student 214-231 / staff 264-292 features (Your day, voice, Exams page, Xiaomi battery Fix, What's new by version).
- Offered, not answered: Kannada "Your day", staff widget calendar events, 3:15 pm present/absent note, photo ring style, in-app "Run now" scraper.
- In-app voice calls: enquiry only - do NOT build unless asked again.

## Widget cards plan (user, 17-Oct-2026: "a data change must never need a new widget build - only a new look")
- Idea: the app / cloud sync sends READY cards, the widget only draws them. Student widget w242 has `Cards.java` (fields documented
  at its top): DB2 `davan_pub/cards_by_urn/<URN>/<cardId>` = {hide, internal, needs, eligOnly, rows:[{page, pos top|bottom|at:<place>,
  title, body (b/br/small HTML), bg, color, from, until, hl, tap}]}. Any page shows top / bottom rows with no build; "at:" places so far:
  internals `at:examDays`. Built-in parts a card can hide: `examDays`, `todaySeat`.
- DONE: exam seats (card `exam_seat`, one row per DAY with subjects + times, seat once - sync v2.9.3; written by davan-scraper sync `_write_exam_seat_cards`, Sync seating job 4x a day;
  subject comes from staff app v1879 `_who` URN -> batch).
- NEXT (user will say when): today's timetable / class changes, attendance, today's sheet, notices -> one card writer each (staff app
  or sync), no widget build. Then the same `Cards.java` for the STAFF widget (one build). A build only for a new look, new phone
  ability (alarm / notification type / button), or Android fixes.
