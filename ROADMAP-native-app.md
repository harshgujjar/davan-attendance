# Native student app redesign - ROADMAP (user, 27-Oct-2026) - DESIGN ONLY, NOTHING BUILT

Mockups (claude.ai artifacts, private to the user): student foldable cards 1DfkX2JzFxssAFCK4nbKYq (the chosen one), student always-open
cards 8votf8YiX4nmammsKTyjKT (old), admin / staff RW7xpb1FbCDifNHBxvvWyP. Real data in them: V NEESHA U13NU25S0031, BCA sem 3 A, read with
the davan-scraper "DB2 peek" Action (read only). Weather, phone time, hostel, Placement, results, fees, library, news = SAMPLE in the mockup.

## Decisions (history)
1. Goal: students build skills by themselves (30-day challenges, Skill Passport, Ask Davan). No parent notifications.
2. Design: tabs on top (Today, Study, Campus, Grow, Me) + foldable cards, college seal, header with photo, name + ▶ day, phone, F/o father,
   weather chip, yesterday's phone time chip. Every item of the running app has a place (see "Where each old page went" in the mockup).
3. Built INSIDE the existing native student app as a new main screen. The widget code and the web app are NOT touched.
4. Visible only to the user and testers. Released to NOBODY (not even the nightly 9:15 pm) until after this semester (ends 20 Nov 2026);
   students get it next semester. Test channel only: Davan.Student-test.apk + student-widget-test.json (testUrns / codes), an allow-list
   check inside the app, new code in its own package + build mode so a normal bug-fix build never carries it. Never use the "-next" files.
5. Layout from a JSON file Claude edits (no Designer page for now). App falls back to a built-in default layout.
6. Login: native login (URN + password, Firebase email <urn lowercase>@davan.local) writes the SAME link record the portal writes
   (davan_pub/student_widget_active/<code>), so the widget does not need the web app. Logout clears that record. Admin mode = staff login,
   never the master password inside the APK. No silent re-linking; the Super Admin phone stays protected; pair log kept.
7. Admin / staff app: separate mockup, built later (role tabs, role preview, Designer later).
8. DEFERRED by the user (27-Oct): cleaning up the plain-text admin password in the public student_portal.html. Do not start it until the
   user says. Because of this, the new app must NOT use or copy that secret in any way.

## Build plan (serial numbers)
Phase 0 - prepare: 1 approve mockup; 2 (DEFERRED) admin-secret clean-up; 3 test list (user phone + Neesha's test phone); 4 toolchain + build mode.
Phase 1 - foundation (test builds only): 5 own package + manifest piece + higher version; 6 allow-list gate; 7 layout JSON reader + cache + default; 8 shell (header, Ask bar, tabs, foldable cards, detail pages).
Phase 2 - Study (real data from Store.st): 9 Today's classes, Timetable, Attendance (all groups), Internals + seat + IA eligibility, Results, Lesson plan, Calendar, Report card.
Phase 3 - rest of the app: 10 Today tab hero + Heads-up banners; 11 Campus (Notices, Hostel incl. SOS + night check-in, Messages, News + rates, Stars, Weather, Instagram, Follow, Fees, Library); 12 Me (ID, Settings, App states); 13 Placement + Messages open the existing screens unchanged.
Phase 4 - login: 14 native login + saved logins; 15 logout clears the link; 16 admin mode via staff login (Open as); 17 keep the link protections.
Phase 5 - new for students: 18 Grow (30-day challenges from JSON, Skill Passport, QR); 19 Ask Davan (own-data answers, ✨ AI with daily limit); 20 campus map.
Phase 6 - test: 21 testers use it daily, fixes; 22 checks (DB reads, offline, old phones, every card vs the real app).
Phase 7 - release (after the semester, only when the user says): 23 public build with the screen + "What's new"; 24 Super Admin switch = everyone; 25 rollback = switch off.
Later: 26 admin / staff app redesign; Designer page.

## Every build follows the widget rules
New version each build, W<nn>_CHANGES.md, source copied to davan-scraper/widgets/student, BuildInfo.NEWS only when it is released, no public file touched
(Davan.Student*.apk, student-widget-version.json, -next files), test channel only.

## Suggested timeline (to 20 Nov)
Week 1 (27 Oct-2 Nov) steps 1-9; week 2 steps 10-13; week 3 steps 14-20; week 4 steps 21-22; release steps 23-25 after 20 Nov when the user says.

## Still open
Father's name for Neesha in the header (placeholder until given); test phones; real data for hostel / Placement / results (DB4 and results rows) when we reach those cards.
