# Roadmap: notifications, weekly feedback, rates (agreed with the user 04-Oct-2026)

Read this before any notification / feedback / rates / fee work. After finishing a step, tick it (☑), add the versions, commit.
In a new session the user uploads the newest widget zips and says "do the next step from the roadmap".

## Standing decisions
- New notifications are **ON by default**; the admin switches them off on the 🔔 Notifications page.
- Every notification (existing and new) is listed in ONE registry: `NOTIF_REGISTRY` in src/index.src.html (the 🔔 Notifications page).
  Its switches are DB2 davan_pub/notif_off/{stu|stf}/{key} = true; the widgets map their notification ids to keys in
  Alerts.regKey (and Gen for the general ones). A new notification = a registry entry + a regKey mapping, in the same commit.
- Only 7:00 am - 9:00 pm, never inside a class period (breaks: 10:30-10:45, 12:45-1:15, 3:15-3:30, after 5:30).
- Faculty photos and student photos wherever possible.
- College notifications run only between the semester start / end dates already in the app (SESSION_CONFIG.startDate / endDate).
- PUC is left out until the user says. University exam notifications are on hold (no sample of the university PDF yet).
- Faculty with no subject this semester are left out (facActiveSets / facIsActive).

## Weekly class feedback (decisions)
- Opens Saturday 11:00 am, open until Friday night. Compulsory: widget + student app data locked until answered (today's
  timetable stays visible). Reminders every 2 h, 9 am - 9 pm. Admin "unlock all" switch.
- Missed weeks carry forward, max 2 (last week + this week); older = "missed", never asked again.
- Per subject: faculty photo + name, subject, topics covered that week (lesson plan). Q1 understood 👍/🤔/👎 (required),
  Q2 stars 1-5 (required), Q3 a few words (optional).
- One answer counts on widget and app (saved per URN). Only subjects that had classes that week.
- Faculty: own subjects, no names, hidden until >= 5 answers, ⚠ under 40% of the class, response rate shown. Monday 8 am.
- Admin + Principal: everything with names and photos; college / per faculty / per student / not answered (widget / app / neither).
- Kept per semester for the faculty semester scorecard.

## Steps
- ☑ 0. This roadmap + CLAUDE.md rule (04-Oct-2026)
- ☑ 1. Weekly class feedback (before Sat 10-Oct-2026) - done 04-Oct-2026: portal v11.02, admin v1732, student widget w157, staff widget w201.
       Subjects = the student's attendance subjects with classes (ct > 0), same filters as the Attendance tab. Data paths in CHANGELOG-admin v1732.
- ☑ 2. (done 04-Oct-2026: admin v1733, portal v11.03, student widget w158, staff widget w202, fetch_news v1.6.1) Thai baht + currency picker (flags) · rates card in staff app admin · rate history · 🔔 Notifications page (all existing +
       new) · morning brief 7:30 · horoscope 7:45 · news 10:35 / 1:00 / 7:30 · gold ▲/▼ 12:50 · staff: currencies 3:20,
       Nifty 5:35, gold closing 5:40 · big gold move (>=1%) · weekly rates Mon 7:40 · weekend review Sat 6 pm · Instagram names
- ☑ 2b. (done 05-Oct-2026: admin v1740, portal v11.09, student widget w163, staff widget w204) 🔊 Spoken alerts (English / Kannada, 7 am - 9 pm, max 5 a day; 07-Oct-2026 admin v1791, student widget w184, staff widget w243: NO daily limit, and the class-start / last-class wrapping-up alerts speak too)
       + 🎛 Global Switches page; test list (V NEESHA + admin) on davan_pub/tts_cfg, the admin adds more people / groups or sets 'all'.
- ☑ 2c. (done 05-Oct-2026: admin v1741, student widget w164, staff widget w205) Notifications at least 20 min apart (phones wait), new
       default times, ✎ times movable on the 🔔 page (notif_off/{aud}/_t), ✅ clash check there. Keep any new fixed time 20 min from the others.
- ☑ 2d. (done 05-Oct-2026: admin v1752, staff widget w216) 📋 Period class list for admins / Principal at every period start (List / Voice ON-OFF,
       default ON) and spoken alerts for the other roles (daily report, meeting, canteen, hostel, message from the college; never SOS).
- ☑ Day attendance Phase 1 (07-Oct-2026: student widget w188, portal v11.44, admin v1800, app.py v092+): lock-screen card (key lock) and the 3:15 pm "yesterday's missed classes" note (gen_dayatt). Plan: tools/day-attendance/README.md
- ☑ Day attendance Phase 2 - faculty (07-Oct-2026: staff widget w250, admin v1804): "Yesterday in your classes" card + widget row, class in-charge card, faculty lock-screen card (stf lock), 6 pm "absent in your classes" (stf gen_dayatt). Covering a class: not done (no substitution data).
- ☐ 3. Shortage + study: under 50% -> meet Principal ("I'll meet" list), 50-75% shortage, good subjects, miss-2-more, backlog
- ☐ 4. Fee window + "I have paid" + Manager bulk page (class/section, Mark all, NEW in yellow, Save) + faculty submissions + Thu summary
- ☐ 5. Event feedback forms (stars / 1-5 marks / yes-no / few words) + anonymous box + 📖 "How Davan works" guide page
- ☐ 6. Faculty semester scorecard (feedback + syllabus + classes held + internal marks)
- ☐ 7. Exam paper feedback lock (when internals come near)
- Hold: university exam notifications, PUC
