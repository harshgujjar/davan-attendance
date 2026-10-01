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
LIVE (from w115, no GitHub Release step): copy the APK to `Davan.Student.apk` on main and raise `LATEST_STUDENT_WIDGET_APK.apkVersion`
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
copy the APK to `DavanWidget.apk` on main, and bump `apkVersion` in `davan-widget-version.json` (the widgets update themselves from it) AND `LATEST_APK.apkVersion`
in index.html (old w132 phones). Its data comes from DB2 davan_pub/staff_pub, published by index.html's stwPublish. Its codes are always `S-XXXXXX`; the student
app must never link them. The old Davan Hostel Staff app (com.davan.hostelstaff, staff.jks, DavanHostelStaff.apk, staff-widget-version.json) is retired.

## PWA rule (every installable page)

Each page links its OWN `manifest-<app>.json` with a unique `id` and `scope` = that one page (never "./" or the folder), and registers its
service worker for its own page only (`register('app-sw.js', {scope: './<page>.html'})`). Only index.html's `sw.js` (push) sits at the folder.
No data: / blob: manifests or blob: workers. Every icon a manifest lists must exist.

## Always commit, push and merge to main (standing instruction)

After every change: bump versions, write the changelog entries, commit, push the session branch, then **merge it into `main` and push `main`** so the apps go live. Do this automatically, never ask. This holds in every session.
