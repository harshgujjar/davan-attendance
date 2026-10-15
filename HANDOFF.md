# Session handoff - read this first (plug and play)

Last updated: 15-Oct-2026 (PUC Mid-Term marks: puc.html v5.239 Internals Mid-Term tab + scraper choice, parent_ptm v4.7.0, worker v8, davan-scraper puc_marks_scrape p2; earlier 12-Oct: 9:15 "Your day today" + 🔊 Tell me my day: staff app v1821, student build 214 / staff build 264 on next; earlier 11-Oct: PUC scrape in the cloud: puc_scrape.py + worker v5 + puc.html v5.231; scraper Cloudflare timer + app.py v104; news source tags: fetch_news v1.7.0, portal v11.59, student 213 / staff 263 on next). A new Claude session reads CLAUDE.md (rules) and
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

## Claude Usage Meter - browser extension (OPEN - continue here)
User's own side project (Chrome + Firefox). SOURCE: private harshgujjar/davan-scraper `extensions/usage-meter/` (src/ + build.sh -> Firefox / Chrome zips, README = update steps).
- v1.4: MV3, host claude.ai; background reads `claude.ai/api/organizations` -> org uuid -> `/api/organizations/<uuid>/usage`
  (five_hour / seven_day / seven_day_<model> or new `limits[]` {kind, percent, resets_at, scope.model.display_name}); badge = session %;
  popup bars + "Resets in" + "Allow on claude.ai" (Firefox "Only when clicked"); live bar on every claude.ai page (bar.js, popover="manual",
  generation id); gecko id `claude-usage-meter@davan`, data_collection_permissions required none.
- v1.5 (15-Oct, zip sent): bar starts TOP centre, drag to move (pointer events, >5 px = drag, else click = refresh), place saved as a
  share of the window in storage `barPos` (all tabs follow), double-click = back to the top. Tested in headless Chromium, not in Firefox.
- v1.6 (15-Oct, user OK'd the heartbeat, zip sent): anonymous Firebase sign-in (identitytoolkit accounts:signUp with the DB4 apiKey,
  refresh via securetoken, kept in storage `fb`) + heartbeat every 15 min (alarm "beat") PUT DB4 `claude_meter/users/<uid>`
  {v, br, os, name, first, last, ok, err, s, sr, w, wr}; popup: "Count me in Davan's meter" switch (storage share) + "Your name" box,
  last send / error shown under it; gecko data_collection_permissions required websiteContent. Live DB4 write NOT tested by Claude -
  the user checks that his own browser appears on the staff app page.
- v1.6.1 (15-Oct): name "Usage Meter for Claude – by Davan" (store trademark rule), gecko strict_min_version 140.0 + gecko_android 142.0
  (needed by data_collection_permissions). TWO zips from now on: -firefox (background.scripts only, no service_worker - AMO warned)
  and -chrome (service_worker only, no browser_specific_settings). addons-linter@latest: 0 errors, 0 warnings. SUBMITTED to AMO 15-Oct (Listed, slug usage-meter-for-claude, licence All Rights Reserved, privacy policy filled) - waiting for the approval e-mail.
- Staff app v1852: Super Admin page 🧮 Claude Meter (cmtrInit, reads DB4 claude_meter/users via lpDb4Get): active today / 7 days /
  all / new this week + table name, browser · OS, version, last seen, session %, weekly %, since; 📋 Copy.
- Claude Pulse (Android usage widget, upstream G-biggy/claude-pulse-android): v2.4.1 SOURCE saved 15-Oct in private davan-scraper
  `claude-pulse/` (upstream + the user's 5 changed files; DAVAN-NOTES.md = build without Gradle, build.sh).
  v2.5 (15-Oct, APK sent): weekly pace advice on the widget + notifications (Pace.kt; 7-day week, no day off; orange/red once a week,
  7 am budget). NEW key (alias claudepulse, cert 2e90756d...cfc9) sent to the user to upload as davan-scraper/claude-pulse/claude-pulse.keystore
  (password told to the user in chat; ask if needed). User uninstalls v2.4.1 once. Not phone-tested.
  Asked (answer only, not built): a floating bar over the Claude Android app = overlay ("display over other apps") + usage access to see
  when Claude is open - offered as v2.6.
- Later: publish LISTED on addons.mozilla.org / Chrome Web Store; name idea "Usage Meter for Claude - by Davan".

## Xiaomi battery Fix (15-Oct-2026)
Shankar B C (S-Y6EGC2, Redmi 13C HyperOS / Android 15): "Battery: unrestricted" red, Fix went to the wrong screen. Staff build 289 (-next):
on Xiaomi/Redmi/POCO Fix opens com.miui.powerkeeper Battery saver ("No restrictions"), fallback App info. S-Y6EGC2 added to
davan-widget-next.json codes so he gets it at once (remove later if wanted). 289 still landed in App info (powerkeeper screen refused) ->
build 290: each Fix tap tries the next of 6 ways (MI_WAY); report field battVia = last way tried. Check his report: bat true + battVia.
His photo was missing: link student_widget_active/S-Y6EGC2 saved with photo "" (staff app linked before photos loaded) -> build 291:
Photo.refresh falls back to staff_pub/ph by name / facKeys. Staff app hswPayload still writes "" in that case (widget covers it).
Student widget build 229 (-next) has the same Xiaomi battery Fix rotation (Perms.miuiBatt), report field battVia.
Shankar fixed (bat true, battVia "battery optimization list") -> staff 292 / student 230: Xiaomi Fix STARTS with that list (key batt_try2, default 3).

## Fees reverse + To do pop-up (17-Oct-2026)
Staff app v1851: ✗ Not received also on a ✅ Paid row (reverse any time, Save). Portal v11.64: 📌 To do above At a Glance; on open a To do
pop-up (welcome-toast reused, stuTodoToast) with "💰 I have paid" replaces the greeting when fee is unanswered / not received or an SD book is due in 0-3 days.
Student widget already shows fee "no" as a red FEE NOT RECEIVED row (+ 8:30 note) at its next refresh.

## V Sem BCA Software Engineering (15-Oct-2026, open)
Timetable (davan_pub/timetable_portal): III YEAR BCA (A) SOEN = afternoon (4:40 pm), (B) = morning (11:45 am); the allocation agrees
("Afternoon (A)" / "Morning (B)" for every V BCA row). After the user's swap: Afternoon (A) = Vijayalakshmi P S, Morning (B) = Karthik J S.
If she teaches the MORNING batch, she is section B and the swap must be undone in Edit Allocation (user to confirm which batch she teaches).

## Sales brochure (15-Oct-2026)
brochure/Smart-Campus-App-Brochure.pdf (6 pages, drawn phone screens with sample names, WhatsApp/Call buttons for 98445 42132 and 89702 25551),
brochure/cover.jpg, editable source brochure/source.html (print with headless Chromium --print-to-pdf). Link: https://harshgujjar.github.io/davan-attendance/brochure/Smart-Campus-App-Brochure.pdf

## Current versions (08-Oct-2026)
| App | Build | Notes |
|---|---|---|
| Staff app (index.html from src/index.src.html) | CODE_BUILD 1852 (v1852 🧮 Claude Meter page (Super Admin); v1849-1851 see CHANGELOG-admin.md; v1848 💰 Fees + 📒 SD books + 📊 Thursday summary (roadmap 4); v1847 Class feedback 🏫 Per class tab: answered with comments + not answered, per class; v1846 Internal Create/Edit grid fits a phone - subject selects shrink, full name below; v1845 v1845 Internal dates from the calendar no longer one day early - dvLocalISO; v1844 v1844 allocation saves also write DB2 davan_pub/allocations + pub_ver (students' app + widget), allocPortalHeal at admin login; v1843 v1843 View Allocation sem list from the session (I, III, V); user swapped SE Sem V: A = Vijayalakshmi, B = Karthik - portal still opposite; v1842 v1842 🧭 Teacher check on Edit Allocation - allocation vs college portal per class, Super Admin reminder; ONE source = live allocation everywhere (portal v11.62 subject teachers at load, app.py v107 att_fac f + fp); v1841 v1841 allocFacFor reads "MORNING (B)" sections - live allocation: SE Sem5 A = Karthik, B = Vijayalakshmi; v1840 v1840 feedback summaries with fx < 1840 rebuilt at next login, stale class_fb_fac rows emptied; v1839 v1839 allocFacFor: the allocation (course+sem+section+subject) decides the teacher in feedback summaries, yesterday card, day attendance - portal v11.61 cfbFaculty, app.py v105 att_fac; v1838 v1838 + puc.html v5.236 + staff widget w283: PUC Principal logs in THROUGH the PUC app - password-only box, view from her own users doc, widget link from puc.html #swdev; staff app shows her a card (Open PUC app / Log out) instead of redirecting; v1837 v1837 + puc.html v5.235: switch from the PUC Principal to admin - note carries uid, PUC Sign Out clears it, Staff app login link; v1836 + puc.html v5.234: note carries name / title / photo for the PUC app sidebar; v1835 PUC-only login: link widget then location.href = puc.html; v1834 PUC glance Commerce only; v1833 + puc.html v5.233: localStorage davan_staff_scope -> PUC app menu + Commerce-only data (pucSkipCls) for the PUC Principal; v1832 PUC-only login: staffPucOnly = PUC in Title OR STAFF_PUC_ONLY_NAMES (Almas Banu T) - app only the PUC page, widget scope puc + calScope pucc; v1831 PUC Science left OFF the staff widgets (user); v1830 PUC timetable from the PUC app's saved timetables (puc_timetables_com/sci, davan_tt_1puc_com) + 1st PUC; v1829 PUC Commerce 6 periods = puc.html; v1828 PUC SCI teacher not from the COM list; v1827 lesson plan by own language; v1826 Kannada / Hindi: each teacher only their own language - row.lg; v1825 🔔 page: no jump to top on a switch, jump buttons; v1824 Your day for admins text; v1823 Short / Full day / Stop text; 🔔 page 👑 Admin column with 🔔 + 🔊 switches; v1821 "📅 Your day today" 9:15 rows) | student widgets below build 133 blocked; 🔔 page "📌 Who keeps the lock-screen card"; 🕷 Scraper page (runs, settings, history) |
| Student portal (student_portal.html) | v11.63 (📌 To do card: fee "I have paid" + SD book last days; v11.62 current subjects' teachers from the live allocation of own course+sem+section at load; v11.61 feedback answer saves the section's allocated teacher; v11.60 class feedback: Send lists the unanswered subjects instead of doing nothing; v11.59 Widget Control -> News: numbered headlines with source tags + per-source counts) | widget floor 133; admin Widget tab: "Not on w<N> yet" list + "📌 Who keeps the lock-screen card" |
| Student widget | build 212 = **w186** public (10-Oct 9:16 pm) | next = 226 (226 = Exams page day by day (date+time, subjects, that day's room/bench), countdown without "N papers", empty/__ignored__ slots not counted; Today 🧪 internal card (eligible + first/today's paper + seat) taps to the Internals page (OpenActivity act "page"), first card on exam days; "Open as" student whose data fails shows a red ⚠ COULD NOT LOAD card with the error instead of looking like the admin - ask the user for that screenshot); was next = 225 (225 = Exams page: eligible / not for the coming internal first, then timetable + room / bench, IA-1 marks below; seat of an older internal never shown); was next = 224 (settings tag shows "· build N" to testers only; 223 = Fast voice default, update chime res/raw/update_chime.wav + Chime.java, switch "chime"; 222 = ▶ on the widget runs in a foreground service DaySvc - Android cut the receiver short; 221 = voice speed Slow / Normal / Fast / Super fast for every voice, Speak.rate / tts_rate; 220 = Kannada times in words with ಬೆಳಿಗ್ಗೆ / ಮಧ್ಯಾಹ್ನ / ಸಂಜೆ, Speak.knTimes; 219 = Your day: date + new thought, Full = everything left, box closes itself, ▶ Mon beside the phone + moving strip on top while speaking; 218 = Kannada Your day + ▶ Mon day button on the widget header; 217 = "server gave the old file": waits 6 min for GitHub's cache; 216 = Tell me my day: 🔊 Short / 🔊 Full day / ⏹ Stop, one at a time; 215 = update no longer stuck at "connecting…"; 214 = 9:15 "Your day today" + 🔊 Tell me my day; 213 = news source tags); BuildInfo.NEWS = changes since the last public build |
| Staff widget (Davan Staff) | build 262 = **w233** public (10-Oct 9:16 pm) | next = 286 (286 = feedback card columns short again, words under the subject; 285 = feedback card in words: "👍 100% understood", "30 of 62 answered"; 284 = markets card scrolls with the Stars page, no fixed box - same as student w210; 283 = 3rd "Linked as" option 🏛 PUC Principal -> puc.html#swdev, Widgets.pucAppIntent; 282 = voice says "first P U C Commerce A" for 1PUC COM A, no "pug" / "com" - Speak.puc in speakNow + HomeCast.say; settings tag "· build N" for Super Admin + test list only; 280 = PUC Principal gets Your day from the PUC board - Periods.todayPuc, Gen.collegeDay puc; 279 = PUC-only login: widget tap opens puc.html - its PWA if installed else the browser, Widgets.pwaOrBrowser; 277 = voice: "38 students, 41 classes taken out of 50" - lesson plan total, Speak.subSay / counts; 275 = Fast default, update chime; 274 = DaySvc for ▶; 273 = voice speed; 272 = Kannada times fix; 271 = same Your day changes as student 219; 270 = Your day on the Super Admin's settings + page 2 = the person's real settings, Roles.who; 269 = Kannada Your day + ▶ Mon button; 268 = Your day for admins / Principal = the college's day, Gen.collegeDay; 267 = old-file wait; 266 = Short / Full day / ⏹ Stop; 265 = update fix + Admin voice switches notif_off/stf/_v; 264 = 9:15 "Your day today"; 263 = news source tags) |
| College scraper app.py (PRIVATE repo harshgujjar/davan-scraper) | v104 (sync v2.11.0); PUC: puc_scrape.py p1 (worker v5) | tools/sync_allocations.py (Actions -> Sync allocations, 7:10 am / 1:10 pm / 7:10 pm IST + by hand) copies the live allocation to DB2 davan_pub/allocations + pub_ver when it differs; runs in the CLOUD by itself: Cloudflare worker davan-release v4 starts "Scrape (run once)" (timed=yes) 1:00 / 1:45 / 5:30 / 6:15 pm IST Mon-Sat; GitHub's own timer stays as a late backup - no laptop needed |
| Cloudflare worker davan-release | v6 (12-Oct 11:23 pm), DEPLOYED by GitHub (.github/workflows/deploy-worker.yml, secret CLOUDFLARE_API_TOKEN = an Account API token, 53 chars - the job finds the account id, wrangler 4) | 4 timers: release 9:15 / 9:45 pm, college scraper 1:00 / 1:45 / 5:30 / 6:15 pm, PUC 10:34 / 1:00 / 3:18 / 5:34 + backups (Mon-Sat). Claude changes it by pushing tools/cloudflare-release-worker.js. PUC secrets PUC_PORTAL_USER / PUC_PORTAL_PASS added 12-Oct; first cloud PUC scrape green (8 classes, 260 students, 236 s). puc.html v5.237: the PC / browser never scrapes by itself (manual Scrape button only) - automatic = cloud only (Mon-Sat, PUC calendar skips Sunday / holiday / event / exam per stream, before login). 13-Oct: PUC MARKS by hand in the cloud - puc.html v5.238 '☁ Scrape marks in the cloud' (Scraper -> 02b) -> worker v7 ?marks= -> davan-scraper puc-marks.yml / puc_marks_scrape.py (same puc_marks shape, blank = AB not 0, status puc_marks_cloud/<AY>/<exam>); no PC helper needed. Test 1PUC-COM-A IA-1: 30 students, 149 marks. OPEN: the rovelabs login is typed into puc.html (public repo) - user to change the password; offered to remove the prefill. Seating: davan-scraper Actions -> Sync seating (tools/sync_seating.py, 7:20 / 11:20 am, 3:20 / 7:20 pm IST + by hand) copies the staff app's seating plan (DB1 internals/sittingAllocation) to DB2 sitting_by_urn - before 13-Oct only the PC sync did it with 'sync sitting' ticked; first run published IA-2 seats for 402 students. Also: davan-scraper Actions -> Sync allocations (live allocation -> students' DB2 copy, 3x a day) |

## Widget sources (private repo, not this one)
Newest sources: harshgujjar/davan-scraper (PRIVATE) folder `widgets/student` (build 208) and `widgets/staff` (build 262) - add_repo +
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
- 17-Oct: widget "What's new" by version + date/time: student build 228, staff build 288 on "next" (Update.news, NEWS "build|text");
  release-widgets.yml now writes times[build] into the public json (+ backfills from release-log.json). Before tonight's release the
  headers show no time. CLAUDE.md rule updated (keep the history).
- 17-Oct: ROADMAP step 4 in the APPS (staff v1848 💰 Fees + 📒 SD books pages + 📊 Thursday summary; portal v11.63 "📌 To do" card). Widgets: student build 227
  (Today 💰 / 📒 rows, 8:30 am gen_todo), staff build 287 (Thu 7 pm gen_thu from DB2 thu_sum, saved by staff app v1849 at a Thursday
  admin login) - on "next". Not tested with real logins / phones; DB2 rules must allow the new davan_pub nodes
  fee_cfg / fee_paid / sd_sub / sd_done (assumed open like meet_req) - if a save says 401, add them.
- 12-Oct: "download failed - the server gave the old file" = raw.githubusercontent.com caches the APK up to 5 min (max-age=300)
  after a push, while github.io already shows the new version. Builds 217 / 267 wait 6 min (Update.staleWait) instead of 3 quick
  retries. RELEASE HABIT: push the "-next" APK first, bump the "-next" json in a later push (5+ min later) - done so for 217 / 267.
  Checked 12-Oct: the CDN IGNORES the ?v= query (a new ?v=267 link got the cached 266 file) - ?v= does not bust it. The nightly
  workflow now pushes the APKs, sleeps 330 s, then pushes the version files.
- 12-Oct: update "connecting…" fix (student 215 / staff 265): the background refresh started the APK download on a side thread and
  ended, Android froze / killed it -> 0 bytes until the next hourly try. Now the download runs on the refresh's own thread, a 0-byte try
  is dead after 45 s, one more direct try before DownloadManager, and the open settings screen starts it (Update.kick). Not phone-tested.
- 12-Oct: 🔔 page admin sections (v1822 -> v1823 user: "make it Super Admin + one section for admin, principal and others"):
  👑 Super Admin = his phone only (notif_off/stf/_sa/{key}, voice _sav/{key}); 🏛 Admin, Principal & others = {key}, voice _v/{key}.
  Rows adm: 1 (both sections), sa: 1 (Super Admin only: scraper), v: 1 (has a voice). Staff widget 266: Gen.off / voiceOff / SA_KEYS
  (cfb_adm, periods, daily, week, scraper) - add a new admin-only notification to SA_KEYS and the registry together.
- 12-Oct: 📅 "Your day today" BUILT (user mockup 12-Oct, then "9:15, keep the 20-min rule out only for this time, keep 7:30, new quote,
  every low subject"): Gen gen_day 9:15 Mon-Sat, both widgets (student 214, staff 264, "next"), Gen.dayBrief / Speak.tellDay.
  Speaks in English only (no Kannada version yet - offer it). Not phone-tested: check the 9:15 note + voice and the settings button.
  Also fixed: the widgets read notif_off "stu_gen_x" but the 🔔 page saves "gen_x" - switches turned OFF earlier now take effect.
- 11-Oct night: PUC scrape moved to the CLOUD (user: "puc html also runs a scraper - handle that in auto mode"). davan-scraper
  `puc_scrape.py` (p1, port of puc.html spDoScrape/spPushFB: same writes puc_daily / puc_students / puc_meta, calendar off-day rule)
  + `puc-scrape.yml`; worker v5 starts it (timed=yes) 10:34 / 13:00 / 15:18 / 17:34 IST + 30 min backups Mon-Sat (cron
  `0,4,18,30,34,48 5,7,8,9,10,12 * * MON-SAT` = PUC_CRON). Status: PUC RTDB puc_sp_config/cloud_last. puc.html v5.231: an open tab
  skips its auto / catch-up scrape while cloud_last is ok within 4 days. NOT done by Claude: pucSessAutoSetOnScrape (segment start
  date, only on a semester's first scrape - do one manual scrape in the tab at a new semester's start). USER STEPS (RELEASE-WORKER.md
  "v5"): add secrets PUC_PORTAL_USER / PUC_PORTAL_PASS to davan-scraper; paste worker v5 + add the new cron (auto deploy key not set);
  run "PUC scrape" by hand once. Verify Mon 12-Oct: puc-scrape.yml runs ~05:05 UTC (10:34 IST).
- 12-Oct: CHECKED - the Cloudflare worker davan-release still runs v4 code (no PUC v5) and has NEVER started a davan-scraper run: no scrape.yml / puc-scrape.yml workflow_dispatch at 07:30 / 08:15 UTC on Mon 12-Oct (only the user's manual run 08:23 UTC); GitHub's own schedule did not fire at all. Release dispatches DO work (11-Oct 15:46 / 16:16 UTC) -> the scraper cron `0,15,30,45 7,8,12 * * MON-SAT` is missing in Cloudflare Triggers or the key lacks davan-scraper. User to check (staff app 🕷 Scraper page shows the worker's scr status) and paste worker v5. Read-only tool added: davan-scraper Actions -> Class feedback status (tools/cfb_status.py).
- 15-Oct: PUC MID-TERM marks (user: "marks entered, no option to show them in internals and PTM"). They WERE in the database: the
  cloud "All Exams" scrape of 14-Oct 2:41 pm stores them at PUC RTDB puc_marks/2026-27/all/<class> under the portal task name
  "Mid Term Examination" (1PUC COM A/B/C full, 2PUC COM-A + both SCI only Kannada, 2PUC COM-B / C none yet). Teachers name tasks
  differently ("Internal Assessement 2" = IA - 2, so the IA - 2 scrape skipped those subjects). ONE rule now: pucExamName (puc.html) /
  ptmExamName (parent_ptm.html) / canon (puc_marks_scrape.py p2) -> "IA - 1".."IA - 5", "Mid Term". puc.html v5.239: Internals
  Mid-Term tab (default pass 28), every exam tab also fills from the all bucket (intMergeAllBucket, read only); scraper 02b has
  Mid-Term (bucket mid_term, worker v8 MARKS_EXAMS). parent_ptm v4.7.0: source "Mid Term", a class with mid-term marks gets a
  Mid Term test (80 / pass 28) once (puc_test_config/<AY>/<cls>/midAdded). Re-scrape Mid-Term when 2PUC COM-B / C marks are entered.
- 11-Oct: scraper timer. Sat 10-Oct GitHub never started the 1 pm run (late starts 7:23-10:58 pm all skipped -> Friday's day attendance
  missed). Built: worker v4 (also starts davan-scraper scrape.yml, cron `0,15,30,45 7,8,12 * * MON-SAT`, filters to 07:30/08:15/12:00/12:45 UTC)
  + app.py v104 (off day: any timed start does the light run until att_state.last_run = today; college day: a slot that already ran
  today is never re-scraped by a late start). USER STEPS: add davan-scraper to the davan-release fine-grained key; paste worker code +
  add the cron if the auto deploy (CLOUDFLARE_API_TOKEN) is not set. Check: worker URL "scr":true / 🕷 page "✅ Cloudflare timer on".
  11-Oct: user says both steps DONE (key has davan-scraper, worker code pasted + cron added). Verify Mon 12-Oct: scrape.yml run
  with event workflow_dispatch at ~07:30 UTC (1 pm IST).
  Friday 09-Oct day attendance: the Monday 1 pm run's catch-up (ATT_DAY_CATCHUP 3) fills it, or run "Collect missing days".
- 11-Oct: news source tags BUILT: fetch_news v1.7.0 (repo davan-student-news, public) takes turns between ticked sources and writes
  indiaSrc / worldSrc / bollywoodSrc / sandalwoodSrc (source key per headline, same order); portal v11.59 Widget Control -> News
  numbered list + tags + per-source counts; student build 213 / staff build 263 on "next" (number + coloured tag, title lists sources,
  notifications end "(TOI)"). Source key -> tag/colour tables: portal WC_NEWS_SRC, widgets Pages.NEWS_SRC - keep in step with NEWS_SOURCES.
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
   **OFFICIAL Firebase numbers (user's console screenshots, 11-Oct-2026) - the ones that count.** DB2 is on the FREE Spark plan:
   downloads 10 GB / month (over = database OFF until the 1st of next month), storage 1 GB, 100 connections. October so far
   (1-10 Oct): downloads **2.96 GB**, storage 41.5 MB, peak connections 18, load 3%, rules 487K allows / 255 denies (rule checks
   fell from ~70K to ~22K a day after the 09/10-Oct "fewer downloads" work). Downloads per day (approx., Firebase days run
   ~12:30 pm - 12:30 pm IST, Pacific time): 1 Oct ~770 MB (month start, everything fresh), 2-4 Oct 140-270, 5-6 Oct 360-430,
   7-8 Oct ~260-270, 9 Oct ~200, 10 Oct (Sat) ~130 MB. Safe line for the rest of October: **~330 MB / day** (7 GB left / 21 days);
   weekdays at 200-250 MB end the month near 7.5-8 GB. The apps' own meter (DB2 usage workflow) shows only ~1/6 of Firebase's
   number (no connection / listener overhead, no scraper syncs) - use it to compare days, trust the console for totals.
   Claude cannot read the console itself: no Firebase connector, and Cloud Monitoring needs billing (Blaze) - checked 10-Oct with
   the davan-scraper workflow "Firebase console usage" (403 / "requires billing"; the user added Monitoring Viewer in
   davan-attendance-2026 only). Do NOT suggest turning on billing just for this. Ask the user for the console screenshot
   (Realtime Database -> Usage -> tap "Downloads" for the per-day graph). TODO: check a full weekday (Mon 12-Oct onwards); if any
   day goes above ~330 MB, find the reader and cut it.
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
Its key `statusdate.keystore` was uploaded by the user to davan-scraper apps/statusdate on 11-Oct-2026 (checked: same certificate c44f8cfa… as StatusDate v8 on the phone).

## Who is on an old student widget
Portal v11.57 (10-Oct): the "Not on w<N> yet" box has a "📲 Send reminder" button per group (DB2 davan_pub/widget_reminder/<URN> -> a card on the student's dashboard; B / C also get the widget's "message from college").
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
