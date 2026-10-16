# Session handoff - read this first (short, current state only)

Last updated: 15-Oct-2026 (late). Old detail (history, done items, numbers): `HANDOFF-old.md` - grep it only when a task needs it.
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
| Staff app (src/index.src.html -> index.html) | v1857 | details: CHANGELOG-admin.md |
| Student portal (student_portal.html) | v11.72 | CHANGELOG-portal.md |
| PUC app (puc.html) / parent_ptm | v5.239 / v4.7.0 | |
| Student widget | public build 231 = w191 (15-Oct); next = 237 (What's new fold; 236: internal card from 60 days; 235: hostel fee on Today, page 2 filters All/Installed/New/Old/Hostel) (232: exam page no empty / "Regular Class" lines; 233: father name from results_by_urn / parent_overrides when portal_students has none; 234: ▶ day button on the name line, phone · F/o father plain below, main layout renamed widget_top) - public 16-Oct 9:15 pm. Test student V NEESHA (widget code KPGYNC) is in student-widget-next.json codes = gets every next build at once | source davan-scraper widgets/student |
| Staff widget | public build 292 = w237 (15-Oct); next 294 (293: ☁️ alerts; 294: What's new fold) | source davan-scraper widgets/staff |
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
- New job / feature that should tell the Super Admin: add the sa_notify step (or saPost in the staff app). Laptop: staff app ☁️ Cloud alerts -> "Get alerts on this laptop".
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
- V Sem BCA Software Engineering: user to confirm if Vijayalakshmi teaches the MORNING batch (then section B - undo the swap in Edit Allocation).
- PUC: rovelabs login is typed into puc.html (public) - user to change the password; offered to remove the prefill.
- PUC Mid-Term: re-scrape when 2PUC COM-B / C marks are entered.
- Fees / SD books (v1848+): DB2 rules may need fee_cfg / fee_paid / sd_sub / sd_done if a save says 401. v1854: hostel fee = fee_cfg/h + fee_paid/<URN>_H; bulk SD dates; staff widget does NOT yet show the fee window / who opened it (needs a staff widget build - offered).
- Not phone-tested yet: student 214-231 / staff 264-292 features (Your day, voice, Exams page, Xiaomi battery Fix, What's new by version).
- Offered, not answered: Kannada "Your day", staff widget calendar events, 3:15 pm present/absent note, photo ring style, in-app "Run now" scraper.
- In-app voice calls: enquiry only - do NOT build unless asked again.
