# Davan attendance — working rules

## index.html is BUILT (from v1581) - edit src/index.src.html

Never edit `index.html` or `js/admin-*.js` by hand. Edit `src/index.src.html` (the whole staff app, as before), then run
`node tools/build_index.js` (first time in a session: `cd tools && npm install`). It writes `index.html` (HTML + small scripts) and
`js/admin-<n>-<hash>.js` (each big script, comments removed by terser, no renaming) and deletes the old ones. Commit all of them together.
Everything below that says `index.html` (CODE_BUILD, HTML_CHANGELOG, ...) means `src/index.src.html`. Syntax-check the source, not the output.

## Changelog: short entries, kept OUT of the app files

The full history lives in markdown files that the apps never download:

| App file | History file | Also in the app file |
|---|---|---|
| `src/index.src.html` (builds `index.html`) | `CHANGELOG-admin.md` | bump `CODE_BUILD`; add a one-line entry at the top of `HTML_CHANGELOG` (the "What's new" popup) and remove the oldest so it keeps **15** entries |
| `student_portal.html` | `CHANGELOG-portal.md` (new `VERSION : vX.YY (date) -- ...` line at the top of the VERSION list) | bump `APP_VERSION` + the topbar / footer version strings |
| other app files | their own changelog / version header | — |
| student widget source (kept out of git) | `W<nn>_CHANGES.md` in the widget folder | — |

Every change adds its entry **in the same commit**. An entry is **short** (2–5 sentences):
1. What changed for the user, and why (the request / bug).
2. Data touched (database paths) and the Firebase cost if it adds reads or writes.
3. Pairs with (versions of the other apps), if any.
4. The main function names changed. **No line numbers** in changelogs.

Line numbers and the detailed list of changed functions go in the **git commit message** only.

Never put long notes, handoff text or history back into `index.html` / `student_portal.html`: every byte there is downloaded by every user and read on every edit.

## Widget builds

Every new student-widget zip gets a NEW version (never re-zip the same number). From w108 the widget is Java with no Gradle
(built with its `build.sh`, signed with `davan-student-widget.keystore`, alias davanstudent, password davanstudent2026 — the SAME key
as w107, keep it): bump `versionCode` / `versionName` in AndroidManifest.xml and `BuildInfo.CODE` / `NAME`,
name the folder and zip `DavanStudentWidget_w<nn>`, and write `W<nn>_CHANGES.md`. The widget source stays out of git.
LIVE (from w115, no GitHub Release step): copy the APK to `Davan.Student.apk` on main, bump `apkVersion` in `student-widget-version.json` (from w133 the widgets update themselves from it, no staff-app dependency) and raise `LATEST_STUDENT_WIDGET_APK.apkVersion`
in student_portal.html AND `LATEST_STUDENT_WIDGET_APK_V` in src/index.src.html (the admin's staff app raises davan_pub/student_widget_latest,
which the students' widgets update from). From w121 (user, 01-Oct-2026): every new student widget build is RELEASED LIVE directly,
no test round, unless the user asks for testing; also copy it to `Davan.Student-test.apk` and bump `student-widget-test.json` so test phones stay level.
TEST builds: copy to `Davan.Student-test.apk` and bump `apkVersion` in `student-widget-test.json` (phones in its `testUrns` update to it).
Never put a test build in `Davan.Student.apk`. The published version is never raised from phone self-reports.

## Staff widget (Davan Staff = DavanWidget, Java, no Gradle)

From w140 the staff widget for faculty, admin and hostel staff is ONE app: app id `com.davan.widget`, signed with `davan-widget-release.keystore`
(alias davanwidget, password davan2026 - the old DavanWidget w132 key, keep it), so it installs over w132. Source stays out of git (folder `DavanWidget_w<nnn>`,
built with its `build.sh`, which renames the manifest package to com.davan.widget; keep the receiver name com.davan.widget.DavanWidgetProvider).
Every new APK gets a NEW version (> 140): bump `versionCode` / `versionName` in AndroidManifest.xml and `BuildInfo.CODE` / `NAME`, write `W<nnn>_CHANGES.md`,
copy the APK to `DavanWidget.apk` on main, and bump `apkVersion` AND the `?v=<n>` at the end of `apkUrl` in `davan-widget-version.json` (from w215 the link is versioned so GitHub's cache never serves the old APK; same for `student-widget-version.json` / `student-widget-test.json`) (the widgets update themselves from it) AND `LATEST_APK.apkVersion`
in index.html (old w132 phones). Its data comes from DB2 davan_pub/staff_pub, published by index.html's stwPublish. Its codes are always `S-XXXXXX`; the student
app must never link them. The old Davan Hostel Staff app (com.davan.hostelstaff, staff.jks, DavanHostelStaff.apk, staff-widget-version.json) is retired.

## Widget release channels (user, 05-Oct-2026) - read before releasing any widget

A new widget build NEVER goes straight to everyone. Copy it to the "next" files: `Davan.Student-next.apk` + `student-widget-next.json`
and `DavanWidget-next.apk` + `davan-widget-next.json` (apkVersion + apkUrl `raw.githubusercontent.com/.../<file>-next.apk?v=<n>`; `codes` =
widget codes that always get it at once, e.g. the Super Admin's S-7UP47U). From w175 / w221 the Super Admin, the spoken-alerts test list
(davan_pub/tts_cfg/test) and those codes update from "next" within minutes. Every night from 9 pm IST (user, 06-Oct; GitHub starts timed runs late, so a run until 6 am still releases - once a night, release-state.json "night") `.github/workflows/release-widgets.yml`
copies a newer "next" build to the public APK and json (`Davan.Student.apk` / `-test.apk` / `DavanWidget.apk`, version files) - one update a day
for everyone else, silent where Android allows. Do NOT edit the public version files or APKs, and keep `LATEST_APK` / `LATEST_STUDENT_WIDGET_APK_V`
(and the portal's `LATEST_STUDENT_WIDGET_APK`) at the PUBLIC version, or the staff app pushes the build to everyone early.
Download buttons (both apps, from v1774 / portal v11.33) give the "-next" APK, so a NEW install is always the newest build, held or not.
AUTOMATIC every night (user, 06-Oct: "fully independent, without Claude"): the job releases by itself, nobody asks. Holds are gone - never add
`"hold"`. The only stop is the Super Admin's switch in the staff app (Global Switches -> Widget updates: Stop tonight / Stop until resume /
Resume / Release now = DB2 `davan_pub/release_ctl` {stopDate, stopAll, nowReq}); if the user tells Claude to stop, set that switch the same way
(tell the user to press it - Claude cannot reach Firebase). The job runs every half hour for "Release now"; `release-state.json` remembers it.
Display numbers: each release raises `display` in the public json by ONE and records `names[build]`; the apps and widgets (w238 / w181+) show
w<display>, testers w<display>.<build - public build>. Never edit `display` / `names` by hand.
The release is STARTED by the Cloudflare Worker davan-release at 9:15 pm IST (+ 9:45 backup) in "auto" mode - GitHub's own timer is unreliable (code `tools/cloudflare-release-worker.js`, setup `RELEASE-WORKER.md`, secret GH_TOKEN); Release now calls it too.
Urgent fix for everyone: run the workflow by hand (Actions -> Release widgets -> Run workflow) or press Release now. The widget rules above about copying to
`Davan.Student.apk` / bumping the public jsons are replaced by this.

## PWA rule (every installable page)

Each page links its OWN `manifest-<app>.json` with a unique `id` and `scope` = that one page (never "./" or the folder), and registers its
service worker for its own page only (`register('app-sw.js', {scope: './<page>.html'})`). Only index.html's `sw.js` (push) sits at the folder.
No data: / blob: manifests or blob: workers. Every icon a manifest lists must exist.

## Debug panels (user, 01-Oct-2026)

Every debug / timing / diagnostic text shown to the user gets a one-tap **📋 Copy** button (`dvCopyText(text, btn)` in the staff app) so it can be pasted back fast.

## Always commit, push and merge to main (standing instruction)

After every change: bump versions, write the changelog entries, commit, push the session branch, then **merge it into `main` and push `main`** so the apps go live. Do this automatically, never ask. This holds in every session.

## Building the widgets in a NEW session (user, 03-Oct-2026)

Widget sources are not in git. The user uploads the newest zips (DavanWidget_w<nnn>.zip, DavanStudentWidget_w<nnn>.zip; each holds the
source, build.sh and the keystore). Unzip them, then run `bash tools/widget-toolchain.sh` once (installs aapt, dalvik-exchange,
zipalign, apksigner and a JDK from Ubuntu, and puts Android API 34 `android.jar` at `$HOME/tc/android.jar` from this repo's
`build-tools` branch - dl.google.com is blocked in cloud sessions; the jar is a slim 77 MB copy, checked 07-Oct-2026: w182 / w241
rebuilt with it are identical to the released APKs). Never put android.jar on main. Build: in the widget folder
`ANDROID_JAR=$HOME/tc/android.jar bash build.sh`. New version = copy the folder to the next number, bump AndroidManifest + BuildInfo,
write W<nn>_CHANGES.md, build, then release as above. Send the user the new APK. Send the source zip ONLY when the user asks for it
(user, 04-Oct-2026: it wastes tokens otherwise) - and always before a session is about to end so the next session can build.

## Faculty without classes (user, 03-Oct-2026)

A faculty member (full-time / visiting / VP) with **no subject allocated** this semester is left out of every list, count and report
(device report, widget lists, alerts, numbers) - they are not using the apps. They come in by themselves once a subject is allocated
(degree allocations of the current semester, the PUC app's Subject Map) or their login has a Title. Principal, admins, managers, office
and hostel staff always count. In the staff app use `facActiveSets()` + `facIsActive(u, sets)` for any new staff list.

## Notifications / feedback roadmap (user, 04-Oct-2026)

Before any work on notifications, weekly feedback, rates, fees or submissions read `ROADMAP-notifications.md` and follow its
standing decisions (new notifications ON by default, every notification in the one registry shown on the 🔔 page, 7 am - 9 pm
outside class periods, photos where possible, PUC left out). After a step is done tick it there with the versions.

## DB2 widget settings are guarded (user, 07-Oct-2026)

DB2 rules (project davan-student-portal) refuse any write to `davan_pub/student_widget_latest`, `student_widget_kill_floor` and
`student_widget_manual_version` unless it carries `_w` = a time newer than the stored `_w` (and not more than 10 min ahead). Every new
write to these nodes (any app, any script) must send `_w: Date.now()`, or Firebase answers 401. This keeps old cached app copies
(e.g. a student's portal v8.74) from putting old values back. Old student widgets up to w108 are blocked (minApkVersion 109).

## Every list of people: photo, tap to zoom, 🏨 (user, 07-Oct-2026 - default rule)

Any NEW list, card, chip or table that shows students or staff by name (both apps, every page) must show:
1. Their **photo** - student portal `davanAvatarHTML(urn, name, {size})`, staff app `_facAvatar(name, size, true)` for staff (call
   `_facAvatarInject()` after drawing so late photos fill in); students in the staff app use its existing student-photo helper.
2. **Tap the photo to zoom** (`rcZoomPhoto`) - pass zoom = true; never draw a photo without it.
3. The **🏨 hostel mark** - both apps add it automatically to text that is EXACTLY a hostel resident's name, so put the name in its
   OWN element (`<span>NAME</span>` / `<b>NAME</b>`): never glue an emoji, number or comma into the same text as the name.

## Every page loads by itself after a refresh (user, 07-Oct-2026)

A refresh reopens the last page and runs its side-menu onclick after `switchPanel(...)` (`_navRunExtra`, v1806). So a new page's
loader goes in its menu item (`switchPanel('x');xInit()`) and must work when called on its own - never only from a tap.
