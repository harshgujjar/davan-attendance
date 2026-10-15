# Session handoff - read this first (short, current state only)

Last updated: 15-Oct-2026. Old detail (history, done items, numbers): `HANDOFF-old.md` - grep it only when a task needs it.
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
| Staff app (src/index.src.html -> index.html) | v1852 | details: CHANGELOG-admin.md |
| Student portal (student_portal.html) | v11.65 | CHANGELOG-portal.md |
| PUC app (puc.html) / parent_ptm | v5.239 / v4.7.0 | |
| Student widget | public build 212 = w186; next 231 | source davan-scraper widgets/student |
| Staff widget | public build 262 = w233; next 292 | source davan-scraper widgets/staff |
| Scraper app.py (davan-scraper) | v104+ | runs in the cloud, Cloudflare worker davan-release v8 starts it |

## Where things are
- Widget sources + keystores: private **harshgujjar/davan-scraper** `widgets/` (README there). Toolchain: `bash tools/widget-toolchain.sh`,
  build `ANDROID_JAR=$HOME/tc/android.jar bash build.sh`; edit `layout-master/`, never res/layout/; no Java lambdas.
- Cloud jobs (davan-scraper Actions): Scrape (run once), PUC scrape, PUC marks, Sync allocations, Sync seating, DB2 usage, DB2 peek,
  Widget versions, Scrape status, Class feedback status. Cloudflare worker code: tools/cloudflare-release-worker.js (auto-deployed).
- Firebase DB2 = FREE Spark plan, 10 GB downloads / month: stay under ~330 MB / day (ask the user for the console screenshot to check).
- Student widget floor: build 133 (STU_WIDGET_BLOCK_V = STU_MIN_WIDGET_FLOOR = DB2 minApkVersion - keep all three equal).

## Side projects (user's own)
- **Usage Meter for Claude** (browser extension): source davan-scraper `extensions/usage-meter/` (build.sh -> -firefox / -chrome zips).
  v1.6.1 SUBMITTED to addons.mozilla.org 15-Oct (slug usage-meter-for-claude) - waiting for approval. Heartbeat -> DB4
  claude_meter/users, shown on the staff app 🧮 Claude Meter page (v1852). Updates: raise version, user uploads "Upload New Version".
- **Claude Pulse** (Android usage widget, upstream G-biggy/claude-pulse-android): source davan-scraper `claude-pulse/` (DAVAN-NOTES.md,
  build.sh). v2.6 sent 15-Oct: pace advice + notifications, floating bar over the Claude app, bigger text, usage details. Key
  claude-pulse.keystore (alias claudepulse) - user to upload it to davan-scraper/claude-pulse/ (ask for it + its password). Not phone-tested.
- Status Date app: PARKED (davan-scraper apps/statusdate/PLAN.md) - only when the user asks.

## Open items
- V Sem BCA Software Engineering: user to confirm if Vijayalakshmi teaches the MORNING batch (then section B - undo the swap in Edit Allocation).
- PUC: rovelabs login is typed into puc.html (public) - user to change the password; offered to remove the prefill.
- PUC Mid-Term: re-scrape when 2PUC COM-B / C marks are entered.
- Fees / SD books (v1848+): DB2 rules may need fee_cfg / fee_paid / sd_sub / sd_done if a save says 401.
- Not phone-tested yet: student 214-231 / staff 264-292 features (Your day, voice, Exams page, Xiaomi battery Fix, What's new by version).
- Offered, not answered: Kannada "Your day", staff widget calendar events, 3:15 pm present/absent note, photo ring style, in-app "Run now" scraper.
- In-app voice calls: enquiry only - do NOT build unless asked again.
