# Roadmap: notifications, weekly feedback, rates (agreed with the user 04-Oct-2026)

Read this before any notification / feedback / rates / fee work. After finishing a step, tick it (☑), add the versions, commit.
In a new session the user uploads the newest widget zips and says "do the next step from the roadmap".

## Standing decisions
- New notifications are **ON by default**; the admin switches them off on the 🔔 Notifications page.
- Every notification (existing and new) is listed in ONE registry (`NOTIF_REGISTRY` in src/index.src.html, published to
  davan_pub/notif_registry). Anything not in the registry must not be sent. Add new ones there in the same commit.
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
- ☐ 0. This roadmap + CLAUDE.md rule
- ☐ 1. Weekly class feedback (before Sat 10-Oct-2026)
- ☐ 2. Thai baht + currency picker (flags) · rates card in staff app admin · rate history · 🔔 Notifications page (all existing +
       new) · morning brief 7:30 · horoscope 7:45 · news 10:35 / 1:00 / 7:30 · gold ▲/▼ 12:50 · staff: currencies 3:20,
       Nifty 5:35, gold closing 5:40 · big gold move (>=1%) · weekly rates Mon 7:40 · weekend review Sat 6 pm · Instagram names
- ☐ 3. Shortage + study: under 50% -> meet Principal ("I'll meet" list), 50-75% shortage, good subjects, miss-2-more, backlog
- ☐ 4. Fee window + "I have paid" + Manager bulk page (class/section, Mark all, NEW in yellow, Save) + faculty submissions + Thu summary
- ☐ 5. Event feedback forms (stars / 1-5 marks / yes-no / few words) + anonymous box + 📖 "How Davan works" guide page
- ☐ 6. Faculty semester scorecard (feedback + syllabus + classes held + internal marks)
- ☐ 7. Exam paper feedback lock (when internals come near)
- Hold: university exam notifications, PUC
