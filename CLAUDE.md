# Davan attendance — working rules

## Changelog: short entries, kept OUT of the app files

The full history lives in markdown files that the apps never download:

| App file | History file | Also in the app file |
|---|---|---|
| `index.html` | `CHANGELOG-admin.md` | bump `CODE_BUILD`; add a one-line entry at the top of `HTML_CHANGELOG` (the "What's new" popup) and remove the oldest so it keeps **15** entries |
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

Every new student-widget zip gets a NEW version (never re-zip the same number): bump `versionCode` / `versionName`
in app/build.gradle, `THIS_APK_VERSION` in StudentFetchWorker.kt and `CURRENT_VERSION` in STUDENT_WIDGET_README.md,
name the folder and zip `DavanStudentWidget_w<nn>`, and write `W<nn>_CHANGES.md`. The widget source stays out of git.

## Staff widget (Davan Hostel Staff, Java, no Gradle)

Source stays out of git (folder `DavanHostelStaff_s<nn>`, built with its `build.sh`; keep `staff.jks`, password davanstaff). Every new APK gets a NEW version: bump
`versionCode` / `versionName` in AndroidManifest.xml and `BuildInfo.CODE` / `NAME`, write `S<nn>_CHANGES.md`, copy the APK to `DavanHostelStaff.apk` on main and
bump `STAFF_WIDGET_APK.apkVersion` in index.html (the widgets auto-update from it). Its codes are always `S-XXXXXX`; the student app must never link them.

## Always commit, push and merge to main (standing instruction)

After every change: bump versions, write the changelog entries, commit, push the session branch, then **merge it into `main` and push `main`** so the apps go live. Do this automatically, never ask. This holds in every session.
