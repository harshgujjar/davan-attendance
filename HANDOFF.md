# Session handoff - read this first (plug and play)

Last updated: 08-Oct-2026 night (session ended after the w201 / w256 release). A new Claude session reads CLAUDE.md (rules) and
then this file (where things stand). The user should not have to repeat anything below. Update this file at the end of every
session (same commit as the work), keep it short, newest state only.

## How the user works (keep doing this)
- Plain language, short answers. The user writes quickly with typos; read for meaning.
- Always give the widget **build number AND display number** (e.g. "build 201 = w183 for everyone, w182.7 on test phones").
- Answer in chat. Mockups only when asked; when asked: a private HTML file sent with SendUserFile (real student data never published).
  Show NOW vs NEW side by side and list what changed. Keep the existing layout unless told otherwise.
- After every change: versions + changelogs, commit, push the session branch, merge to main, push main - never ask (CLAUDE.md).
- Widget builds go to the "-next" channel only; the nightly Cloudflare timer (9:15 pm IST) releases them. Don't start a release
  unless asked. Super Admin can stop it (Global Switches -> Widget updates).
- Say honestly what could not be tested on a phone.
- Never ask the user to paste tokens/keys into chat. Secrets live in GitHub Secrets (davan-scraper repo).
- Login / admin push alerts go only to the Super Admin.

## Current versions (08-Oct-2026)
| App | Build | Notes |
|---|---|---|
| Staff app (index.html from src/index.src.html) | CODE_BUILD 1813 | |
| Student portal (student_portal.html) | v11.50 | day wrap-up card on the dashboard |
| Student widget | build 201 = **w183** public (released 08-Oct 9:16 pm) | next = 201 |
| Staff widget (Davan Staff) | build 256 = **w231** public (released 08-Oct 9:16 pm) | next = 256 |
| College scraper app.py (PRIVATE repo harshgujjar/davan-scraper) | v100 | laptop runs v100 |

## Widget sources (NOT in git)
The newest sources are DavanStudentWidget_w201 and DavanWidget_w256 (zips sent to the user 08-Oct). At the start of a widget task
ask the user to upload those two zips (or newer), unzip, run `bash tools/widget-toolchain.sh`, build with
`ANDROID_JAR=$HOME/tc/android.jar bash build.sh`. New from w199 / w256: `layout-master/` holds the card + main layouts and
`gen_sizes.py` (run by build.sh) writes res/layout/*.xml, *_m.xml (92%), *_s.xml (85%) - **edit layout-master/, never res/layout/**.
dx needs `--min-sdk 24`: **no Java lambdas** (use anonymous classes).

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
1. **Check the new Today page on a real phone** (built without device testing): DAVAN colours, countdown badge, small photos per line,
   Results faculty names, lock-card header. Fix whatever the user reports.
2. **DB2 daily usage check**: Claude cannot read DB2 from the cloud (an anonymous-token sign-up was blocked by the permission
   classifier on 08-Oct). Ask the user for a screenshot of the staff app meter page (DB2 usage, pick the date), or for permission.
   Watch: w201 makes each student re-read their results once (+~15 KB allocation_each_c) - a one-day bump on 09-Oct is expected.
3. Cloud scraper: login / keys / reachability tests pass in GitHub Actions (davan-scraper). Offered, not approved yet: a full cloud
   test scrape, then move the 1 pm / 5:30 pm runs to the cloud and switch off the laptop scheduler.
4. Student 3:15 pm note: add present/absent counts + topics missed (offered, not built).
5. Swaroop (student) needed a one-time manual install of the widget (Files -> Downloads -> APK) because of the old "Open with" bug.
6. Optional idea offered: keep widget sources + keystores in the private davan-scraper repo so a new session can build without the
   user uploading zips - **only if the user agrees** (its CLAUDE.md forbids committing keys).

## Useful facts
- Release log: `release-log.json` ("by": "Cloudflare 9:15 pm" = the timer worked). Display numbers: `display` in the public jsons.
- Day attendance data: DB2 davan_pub/att_day, att_fac, att_stu/<URN>/<date>; scraper saves after 1 pm for the last college day.
- DB2 meter: davan_pub/meter (bytes; the page shows MiB - 1 MiB = 1.048 MB).
