# Session handoff - read this first (short, current state only)

Last updated: 19-Oct-2026. Old detail (history, done items, numbers): `HANDOFF-old.md` - grep it only when a task needs it.
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
| Staff app (src/index.src.html -> index.html) | v1914 | details: CHANGELOG-admin.md (v1914: Widget check false alarm fixed (floor 133 = STU_WIDGET_BLOCK_V), alert tap -> ?go=widget-version; v1913: Placement steps 1-5 - photos, staff league, badges, paths, QR certificates, 4 new 🔔 registry rows; v1912: 🎯 Placement history page for all staff roles, SA keeps full page; v1911: seat lookup says Dias chair for seats 49+; v1910: Claude Meter DB1/DB2/DB4 usage boxes; v1909: Placement preview banner -> small 👀 ↩ + 🏠 home button, placement.js ?v=4; v1908: Placement word notification 7:40 am, spoken; v1905: Class feedback ⏸ Skip this week only - on:false + pausedWk; back on by itself next Sat with start = new week) |
| Student portal (student_portal.html) | v11.87 (Placement steps 1-5: photo, class league, badges, paths, QR certificate + learn/v.html verify; v11.86: history rows open "my answers" - needs widget w252+; v11.85: app 🎯 Placement = history & review only, locked until first widget answer; degree students; learn/placement.js hist mode; v11.84: Show/Hide on semester note, Horoscope, Attendance Summary; note shows the end date; v11.83: home Right now card shows a calendar holiday / VACC / exam day; v11.82: Placement off in the apps; dashboard banner promotes the widget) | CHANGELOG-portal.md |
| PUC app (puc.html) / parent_ptm | v5.246 / v4.7.4 | v4.7.4 + scraper puc_scrape p2 / puc_marks p3 (17-Oct): a student the portal blocks for fees (0 held, left out of marks) keeps the last good data - AISHWARYA R B 1D26004 blocked 2 days, card showed 0/0; republish her card; v4.7.3 Test scheme "🔁 Apply max / pass to published cards" (fix pass mark without republish); v5.246 Mid Term % out of 80; Mid Term round in PTM view logs; a student missing from an exam bucket is filled from All Exams (AISHWARYA R B 1D26004 missing from mid_term/1PUC-COM-A cloud scrape 16-Oct) |
| Student widget | public build 241 = w193 (16-Oct, hand release); next = 255 (255: no festival / holiday / closed-meal ("No snacks today") notices) (254: Placement animations - opening 🎯🏹 intro, cards float up, press, count-up, photo ring, bounce / shake, +XP, level pulse / pop, lesson deck + flip, mic ripple, words one by one, 3-2-1 Saturday) (253: Placement BUILD-ALL steps 1-5 - photos + PRO ring, weekly league card/page, A-D question notification, streak / Thu mock / Sun league / level-up notifications, badges, confetti, flame, revision of wrong answers, Saturday challenge, QR certificates, company paths; PlcFun.java + PlcQr.java) (252: Placement log rows keep the picked answers, pk = qid:pick) (251: 🎯 Placement promo card (portal orange card, no install button) on the student home page, 8-10 am, 1-3 pm, 5-7 pm, ✕ Not now; Pages.plcPromo) (250: Placement 🏠 button + 👀 in the circle instead of the preview banner) (249: Placement word notification 7:40 am + spoken, Placement.speakWord) (248: native 🎯 Placement page PlcActivity - tiles open it; settings 🎯 card; mic in-app, RECORD_AUDIO) (247: 🎯 Placement page = the Placement home of mockup 96dDUE8i4qvc6K3HeXpFkY v9, own card layouts plc_*.xml via Pages.Row.rv; tiles / mock say "widget app - next update") (246: 🎯 Placement page built in FULL per mockup v3 - Placement.java + PlcSay had never been saved to davan-scraper, rewritten: ready score, word 🔊/🎤/✓ + 7-day revision, question A-D + hint/later/ಕನ್ನಡ/again/endless practice, Japanese, tip + speaking, class league) (245: redraw fix - once per build draws lockcard first; 244: 🎯 Placement page 10 = 3rd dot, two-way question of the day, word, Japanese, tips) (243: page 2 "⬅ Settings" no longer drops the opened student - only ↩ Back to me does, like staff w210; user saw a newly opened student "come back to V NEESHA". Super Admin phone = EMTH7Q) (242: server cards - Cards.java draws davan_pub/cards_by_urn/<URN> rows; first card exam_seat from sync v2.9.2) (241: "For the 2nd internal" per-subject window card on Attendance + Internals) (240 (240: morning brief says holiday on a holiday) (239: hostel students on approved leave get no class reminders / next / tomorrow / morning "no class" until the last leave day; leave from StuHostel snapshot) (238: morning brief always spoken + "Dear name" on all voice) (237: What's new fold; 236: internal card from 60 days; 235: hostel fee on Today, page 2 filters All/Installed/New/Old/Hostel) (232: exam page no empty / "Regular Class" lines; 233: father name from results_by_urn / parent_overrides when portal_students has none; 234: ▶ day button on the name line, phone · F/o father plain below, main layout renamed widget_top) - public 16-Oct 9:15 pm. Test student V NEESHA (widget code KPGYNC) is in student-widget-next.json codes = gets every next build at once | source davan-scraper widgets/student |
| Staff widget | public build 295 = w239 (16-Oct, hand release); next 306 (306: same no-meal-notice rule + canteen notice not on Saturday) (305: same animations as w254) (304: same as w253, staff league) (303: same pk log as w252) (302: same as w250) (301: same morning spoken word) (300: same native PlcActivity as w248) (299: same Placement home as student w247, Technical tile = BCA) (298: same full Placement page + staff league; staff Row got real r_badge / r_inner views) (297: redraw fix; 296: 🎯 Placement = every login's 2nd page, Row.badge/inr, d13) (295: morning brief always spoken) (293: ☁️ alerts; 294: What's new fold) | source davan-scraper widgets/staff |
| Scraper app.py (davan-scraper) | v108 | runs in the cloud, Cloudflare worker davan-release v9 starts it |

## Where things are
- Widget sources + keystores: private **harshgujjar/davan-scraper** `widgets/` (README there). Toolchain: `bash tools/widget-toolchain.sh`,
  build `ANDROID_JAR=$HOME/tc/android.jar bash build.sh`; edit `layout-master/`, never res/layout/; no Java lambdas.
- Cloud jobs (davan-scraper Actions): Scrape (run once), PUC scrape, PUC marks, Sync allocations, Sync seating, DB2 usage, DB2 peek, Placement usage (read-only DB4 learn/prog counts, 18-Oct), DB usage to Claude Meter (every 3 h -> DB4 claude_meter/db_usage, shown on 🧮 Claude Meter v1910; Monitoring numbers need role Monitoring Viewer on each project key - 403 until the user adds it, 19-Oct),
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
- v1914: a job's sa.json may carry `link` = a staff-app page `index.html?go=<panel>` (worker keeps it only for harshgujjar.github.io/davan-attendance/, else the run URL); saBoot clicks #nav-<panel> after login. Widget check uses it. Not checked: that the staff widget's SaEv tap opens `link`.

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
- Load speed (user, 17-Oct): user still sees NO improvement after v1892/v1894. v1898 ⏱ load report (Super Admin, bottom-left, 📋 Copy). First report: Firestore SDK reads 6-7 s each -> v1899 one-time doc / collection gets go over REST (wrapper after the SDK; window.DV_FS_NO_REST=true switches it off) + removed the 6 s admin-seed check. 2nd report -> v1900: RTDB once('value') over REST too, facLoadRenames no longer blocks loadFirestoreData. Ask for a new report to confirm. Earlier: v1894 - opening screen closes on the cached draw + cached profile at restore (the real wait); v1892 - sw.js davan-v12 serves js/admin-*.js cache-first; photo lists cached in IndexedDB davan_kv (dvKvGet/Put/Stale); admin auto-mirror once per 6 h. Not phone-measured. Next if still slow: per-page tables (which panel/table is slow - ask user), app_data/students (biggest read) cached in IndexedDB instead of localStorage, defer scripts.
- Seating per exam time (v1877): davan-scraper sync v2.9.1 writes sitting_by_urn perDay rows {date,time,room,seatNo,bench} for the newest Internal with SLOT plans; portal v11.75 shows them. Student widget still reads perDay date->room only (2 exams on one day: shows the last room, top-level bench = first exam) - next widget build should show time + bench per row.
- V Sem BCA Software Engineering: user to confirm if Vijayalakshmi teaches the MORNING batch (then section B - undo the swap in Edit Allocation).
- PUC: rovelabs login is typed into puc.html (public) - user to change the password; offered to remove the prefill.
- PUC Mid-Term: re-scrape when 2PUC COM-B / C marks are entered. 16-Oct: 2PUC BS + EC have no Mid Term on the portal (all classes); AISHWARYA R B (1D26004) has no English / History Mid Term (English 53 typed as "IA - 3"). Missing-students check = compare puc_marks/<AY>/<exam>/<class> with /all (public REST read).
- Fees / SD books (v1848+): DB2 rules may need fee_cfg / fee_paid / sd_sub / sd_done if a save says 401. v1854: hostel fee = fee_cfg/h + fee_paid/<URN>_H; bulk SD dates; staff widget does NOT yet show the fee window / who opened it (needs a staff widget build - offered).
- Not phone-tested yet: student 214-231 / staff 264-292 features (Your day, voice, Exams page, Xiaomi battery Fix, What's new by version).
- Offered, not answered: Kannada "Your day", staff widget calendar events, 3:15 pm present/absent note, photo ring style, in-app "Run now" scraper.
- In-app voice calls: enquiry only - do NOT build unless asked again.

## 🎯 Placement - BUILT v1 (18-Oct): read ROADMAP-placement.md
- NEXT SESSION: 🇯🇵 Japanese letters-first + Type → 日本語 (A offline romaji, B word list, C Google Translate via worker) - read JAPANESE-PLAN.md
  (mockup row 3 of 96dDUE8i4qvc6K3HeXpFkY; Google key steps there - user adds it as Cloudflare secret GOOGLE_TRANSLATE_KEY). Still open: "Reply or hold" meaning (⏭ Later on widget question vs answer buttons on the 6:50 pm notification) - ask.
- Code: learn/placement.js (shared by portal stuPlacementOpen + staff app plcInit; Super Admin report + question bank inside), content learn/bank.json
  (v2: 8 tracks x 10 levels, 464 Qs, level 10 = PRO mixed, 5 company-pattern mocks; rebuild with python3 learn/build_levels.py; words, tips, jp, speak; "db" = where data lives). Widgets: Placement.java in both (student page 10, staff PLC 2nd page).
- Data DB4 learn/ (prog, log, qs, stats, hide, qx). DB4 rule "learn" (auth != null read/write) added 18-Oct by davan-scraper Action "DB4 rules - add Placement" (tested: write 200).
- Students: app page locked until the first widget answer (prog.xp > 0); dashboard promo stuPlcPromo. Widget update lesson (18-Oct): adding a view id shifts the others and launchers re-used old views -> Widgets.draw shows lockcard once per build.
- Widgets w246 / s298 (18-Oct): full page per mockup; class league reads learn/prog?orderBy="c" (staff: "r"="stf") every 6 h - needs
  the DB4 index from davan-scraper Action "DB4 rules - add Placement" (re-run 18-Oct for .indexOn). Staff widget id = STF_<pair name> - must match the staff app's login name.
- FINAL PLAN (18-Oct, ROADMAP-placement "FINAL PLAN"): widget = ONE 🎯 Placement home page (w247 / s299 built); a tile opens the widget app's
  NATIVE page 2 🎯 Placement (BUILT w248 / s300 as PlcActivity, not phone-tested yet; was: Speak / Map / Lesson / Practice / Tech (own course only) / Japan / MockResult / Cert of mockup
  96dDUE8i4qvc6K3HeXpFkY v9, bottom row); browser app = history + install banner. Build exactly the mockup, never a different design.
- BUILD-ALL steps 1-5 BUILT 19-Oct (w253 / s304 / portal v11.87 / v1913, not phone-tested): see ROADMAP-placement. Shared widget code PlcFun.java (same file both widgets) + PlcQr.java (QR, matches learn/placement.js qrMatrix and python qrcode). Next: step 6 (duel, Kannada for 464 questions),
  widget follows bank.db only for DB4 (Net.DB4) - a DB5 move needs a small widget change.

## Widget cards plan - ON HOLD (user, 17-Oct-2026: v2 = shared all/class cards, notify, link tap, dismiss, order; Learn needs it). (user, 17-Oct-2026: "a data change must never need a new widget build - only a new look")
- Idea: the app / cloud sync sends READY cards, the widget only draws them. Student widget w242 has `Cards.java` (fields documented
  at its top): DB2 `davan_pub/cards_by_urn/<URN>/<cardId>` = {hide, internal, needs, eligOnly, rows:[{page, pos top|bottom|at:<place>,
  title, body (b/br/small HTML), bg, color, from, until, hl, tap}]}. Any page shows top / bottom rows with no build; "at:" places so far:
  internals `at:examDays`. Built-in parts a card can hide: `examDays`, `todaySeat`.
- DONE: exam seats (card `exam_seat`, one row per DAY with subjects + times, seat once - sync v2.9.3; written by davan-scraper sync `_write_exam_seat_cards`, Sync seating job 4x a day;
  subject comes from staff app v1879 `_who` URN -> batch).
- NEXT (user will say when): today's timetable / class changes, attendance, today's sheet, notices -> one card writer each (staff app
  or sync), no widget build. Then the same `Cards.java` for the STAFF widget (one build). A build only for a new look, new phone
  ability (alarm / notification type / button), or Android fixes.
