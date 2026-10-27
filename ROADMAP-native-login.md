# Native widget login - plan (user, 24-Oct-2026) - NOT BUILT, waiting for the user's decision

Status: discussed only. Nothing below is built except portal v11.99 (item 0). The user wants time to think, then we discuss.

## 0. Done
- Portal v11.99: admin view (master password) popup "Link this phone's widget?" - OK = link as admin (page 2), Cancel = link as that student only (adm false).

## 1. Queued widget builds (approved in chat, not started)
1. Student widget: show the "Speak my reminders" box only when the Super Admin allows ON/OFF (`davan_pub/tts_cfg/allowOff` = true) or the person is on the test list; `showStu` = false still hides it. Voice keeps speaking in the default language.
2. Staff widget: same rule (`showStf`).
3. Both: app-icon number = unread notifications the widget posted. Clear them when the app / settings opens; "Today's messages" marks NEW items and shows "N new"; a notification tap opens that message.
4. Logout-only button (student widget, staff too if the user says): "Log out" in settings with "Are you sure?", clears this phone's link (`Sync.unlink`); only the person's own tap does it. Check first whether the portal's logout also removes `student_widget_active/<code>` and match it.
Until then (no build): Super Admin -> Global Switches -> Spoken alerts -> "Students see it" OFF hides the box.

## 2. Native login (the idea)
- Widget has its own login (URN + password); writes the same link record the portal writes (`davan_pub/student_widget_active/<code>`: urn, name, class, adm). Rest of the widget unchanged.
- Already-linked students never see it; only their own Logout brings it back. Keep the phone's choice (old link / native login) in the widget settings; add a test that an update keeps a linked phone linked.
- Screen: URN, password with show/hide eye, Remember me (default on), Android autofill, saved logins list (tap = login), "Use another login". Saved password only in Android encrypted storage, only with Remember me; Logout removes it.
- Master password also saved (user). After it: choose **Student** (pick a student, adm false, no page 2) or **Admin** (adm true, page 2).
- Wrong password = clear message, nothing linked; no internet = "try again", never logs out; banned = existing message.
- Portal/PWA/browser stay as they are, with their own login; nothing is auto-linked between them. Existing widget taps that open the portal stay as they are.
- Optional: "Open student portal" after native login, already signed in (installed PWA if Android opens it - not guaranteed).
  - A: login in the link's `#` part, once; portal reads it, removes it, then does the normal login. No server; password briefly in the link (students only).
  - B: a small cloud service makes a one-time sign-in ticket. Cleaner, needs a secret + one more service.
  - Recommended: A, students only; master login does not auto-open.

## 3. What the check found (24-Oct)
- Student password check = Firebase Auth email `<urn lowercase>@davan.local` + password; the widget already has the DB2 key and signs in anonymously, so it can do this by REST, no server.
- DB2 rules shown for several nodes: `.read/.write: auth != null`; the exact rule for `student_widget_active` not seen - confirm with a real write when building.
- SECURITY (open): the admin sign-in secret is stored in plain text in the public student_portal.html (its own comment says it is not). Plan: change that Firebase admin password and stop keeping it in the page (separate job, needs the user's go). Do not write the value in any file.

## 4. Decisions needed from the user
1. Portal auto-open: A or B (or skip).
2. Logout button in student only, or staff too.
3. Go for the admin-secret clean-up.
4. Go for the builds (order: 1 = box rule + notification fix + logout, student; 2 = same, staff; 3 = native login, student).

- 27-Oct-2026: decision 3 (cleaning the plain-text admin secret in the public portal page) is DEFERRED by the user - do not start until told. See ROADMAP-native-app.md.
