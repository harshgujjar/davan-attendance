# Roadmap: 🎯 Placement - English, Aptitude, Technical (plan agreed with the user 17-Oct-2026)

Name (user, 17-Oct): the page is "🎯 Placement" (not Learn) in the widget and the app; 'Learn' below = this page.

Mockup (17-Oct, 8 screens, clickable): https://claude.ai/artifact/E2rS4V5k1TsDywAVFBpv4t (private to the user).

PLAN ONLY - do not build until the user says. Read this before any Learn work; tick steps (☑ + versions) when done.

## Decisions (user, 17-Oct-2026)
- Degree students only (BCA / BBA / BCom). PUC left out. Optional (never locks anything). Kannada help in explanations: yes.
- Faculty get the same options (play for themselves; shown separately, never ranked against students).
- No content review: questions are written by Claude + the user only.
- Widget: a NEW page "📚 Learn" (student + staff widget), drawn with Cards.java (needs Cards v2 with tap-to-answer rows).
- App: the Learn page appears only for people who have started (answered at least once on the widget, or tapped "Start learning").
- Super Admin ONLY sees the reports (who uses it, how often, each person's tries / level / weak topics, today's word, per class /
  student / faculty). Nobody else sees other people's data.
- Data: fully interactive, stored in DB4 for now; must be movable to DB5 later with no app / widget build (see "Database").
- Aptitude (and every track) is LEVEL based: clear all levels -> "PRO". The data is used for campus drives.

## It TEACHES, not only asks (user, 17-Oct) - every level = Learn -> Practice -> Test
- Learn: 3-5 swipe lesson cards (rule / trick in simple English + Kannada, 2-3 solved examples step by step, spoken by the phone's voice).
- Practice: 10 questions with 💡 hint and full step-by-step solution after each; mistakes come back next day (revision).
- Test: 10 questions, no hints, pass 8/10 -> next level. Fail -> "watch the lesson again" for the topics missed.
- Aptitude extra: shortcut tricks (e.g. % as fractions, 10% / 1% method, unit digit), formula sheet per topic, timer practice.
- English teaching (beyond word of the day):
  - 🎧 Listen: the phone reads a sentence / short story / dialogue; questions on what was heard.
  - 🗣 Speak: listen & repeat - the phone's speech recognition (Android SpeechRecognizer in the widget, Web Speech API in the
    app) writes what the student said; words said wrong turn red, 'say it again'; score per sentence. Free, on the phone.
  - 🔁 Kannada -> English: a Kannada sentence, the student builds the English one from word tiles (then types it).
  - ✍ Write: email / leave letter / self-introduction - fill-the-blanks first, then a model answer to compare.
  - 💬 Role-play: interview, phone call, shop, office - the phone asks, the student picks or speaks the answer.
  - ❌ Mistake of the day ("I am having 2 brothers" -> "I have 2 brothers"), daily speaking topic (1 minute, self-recorded).
  - Later (costs money, ask first): AI check of spoken / written answers (Claude API).
- Technical teaching: short concept notes + diagram, code walk-through (BCA: run-in-head "guess the output"), flashcards,
  interview Q with a model answer (tap to reveal, self-mark 'I knew it' / 'didn't know'), BBA/BCom: worked examples
  (journal entries, GST calc, ratio analysis, Excel formulas step by step), mini case studies.

## What the student gets
Widget page 📚 Learn (1-2 min a day):
- 🔤 Word of the day (spoken English + Kannada meaning, example sentence), 🧮 question of the day (tap A/B/C/D -> ✅/❌ + 1-line
  explanation), 🔥 streak, ⭐ XP, current level of each track, "Continue level 4 ->" (opens the app).
- 8 am word, 4 pm question (outside class periods, 20 min from other notifications, registered in NOTIF_REGISTRY, default ON).

App page 📚 Learn (attractive + game-like):
- Tracks as a level MAP (like a game path): English, Aptitude (Quant / Reasoning / Verbal), Technical (per course).
- Each level = 10 questions, pass 8/10 to unlock the next; stars 1-3 by score + speed; a wrong answer shows the explanation
  (English + Kannada) and comes back later (revision).
- Clear the last level of a track -> "🏆 PRO" badge + Pro test (30 questions, timed). All tracks Pro -> "Davan Placement Pro".
- Fun: XP, streaks, badges, confetti / sound on level-up, class league (weekly, top 10 with photos - photo rules apply),
  Saturday 20-minute challenge, "beat your friend" duel later.
- My progress: accuracy per topic, weak topics, time per question, Ready Score.

## Tracks and levels (first content set)
- English (10 levels): basics (articles, tenses) -> grammar errors -> vocabulary / synonyms -> reading comprehension ->
  email + letter writing -> interview phrases / self-introduction -> group-discussion phrases -> PRO. Speaking practice later
  (phone mic: say the sentence, check it).
- Aptitude, 3 sub-tracks x 10 levels: Quant (number system, %, profit-loss, SI/CI, ratio, time-work, time-speed-distance, averages,
  data interpretation), Reasoning (series, coding-decoding, blood relations, directions, seating, syllogism, puzzles),
  Verbal (para-jumbles, fill-ups, error spotting, comprehension).
- Technical:
  - BCA: C, Java / Python, DBMS + SQL, OS, Networks, Data Structures, Web basics, "guess the output" code questions, HR-tech interview Qs.
  - BBA: management principles, marketing, HR, finance basics, business communication, case studies, MS Excel / PowerPoint.
  - BCom: accounting, GST + Tally, taxation basics, banking + finance, cost accounting, MS Excel, financial calculations.
  - All degree students: computer basics + MS Office (optional extra track).
- Content = JSON files in this repo (learn/<track>/L<n>.json), downloaded once and cached - costs no Firebase reads.
  Each question: {id, q, opts[4], ans, exp, expKn, topic, lvl}. Word list: learn/words.json (365 words).

## Campus drive use
- "Ready Score" 0-100 per student = aptitude 40 + English 30 + technical 30 (from levels cleared + Pro tests).
- Super Admin page: filter by course / class / min level / Pro badges / Ready Score -> list with photos -> 📋 Copy / CSV export
  for the company. Shows each student's levels, accuracy, weak topics, days active.

## Super Admin report (staff app, Super Admin login only)
- Today: word of the day, question of the day, how many answered (widget / app), % correct.
- Usage: daily / weekly active, how often each person opens it (days active, last active, average minutes), streak leaders.
- Per student / per faculty: every try (date, track, level, score, time), level map, weak topics, Ready Score.
- Per class: participation %, average level, top 10, never started.

## Database (DB4 now, DB5 later - keep it switchable)
- Everything under ONE root `learn/` so a move = export + import of one node.
- Which database: DB2 `davan_pub/learn_cfg/db` = the database URL (+ key name). App, widgets and reports read it at start;
  changing it moves everyone at once - no build. Writes go through one helper per app (learnDb() / Learn.db()).
- Paths: learn/ans/<URN or S-code>/<day>/<qid> = {a, ok, ms} (tries); learn/prog/<id> = {xp, streak, lvl:{track:n}, pro:[...],
  ready, last, days} (small summary, what the widget + reports read); learn/daily/<date> = {word, qid}; learn/stats/<date>
  = counts (written by the app on answer, so the report reads one small node, not every student).
- Cost (estimate): ~500 active x ~20 answers a day x ~80 bytes = ~1 MB / day written; reads = own prog node + daily node only.
  Report reads prog/ (~1,500 x ~300 bytes = ~0.5 MB) only when the Super Admin opens it. Content files from GitHub, not Firebase.

## Steps (build only when the user says)
- ☑ 1. (18-Oct: bank.json, 8 tracks x L1-L2) Content set 1: words.json + English L1-L3 + Aptitude L1-L3 (each sub-track) + Technical L1-L2 per course (Claude writes).
- ☑ 2. (portal v11.76/77) Student app 📚 Learn page (level map, play, progress, badges) + learn_cfg db switch + DB4 rules for learn/.
- ☑ 3. (v1902/03) Staff app: Super Admin Learn report + campus-drive filter / export; faculty get the Learn page in the staff app.
- ☑ 4. (native Placement.java rows, student w244 / staff w296; FULL mockup v3 page student w246 / staff w298, next channel; not Cards v2) Cards v2 (tap-to-answer rows) + widget 📚 Learn page: student build + staff build; 8 am / 4 pm notifications.
- ☐ 5. More content (levels 4-10, Pro tests), Saturday challenge, class league, speaking practice.

## Proposed 18-Oct (user asked, not yet decided)
- Super Admin "📚 Question bank" page: every lesson / question / word by track + level, coming-next calendar (next 7 days of word +
  question of the day), "play as student" preview, per-question stats (% right, avg time, most-picked wrong option), 🙈 hide / ✎ edit.
  Admin sees everything BEFORE students and faculty (content goes live next morning; the Super Admin can hide it the day before).
- Look: Gen Z style (dark mode default, bold big type, bright gradient cards, stickers / emoji, animated streak flame, confetti,
  story-style swipe lessons, avatars, sounds, haptics) in the Davan app's own colours. Mockup to be redone when the user says.
- Teaching methods: microlearning (5-min), retrieval practice + spaced repetition (wrong / old items come back 1-3-7-21 days),
  worked example -> faded example -> solo, 80% mastery gate, interleaved mixed practice, instant feedback, shadowing for speaking,
  previous campus-drive pattern papers (TCS NQT / Infosys / Wipro / Accenture / AMCAT style) for Pro tests, error notebook.
- Foreign language (bonus track, phase 2): ONE first - Japanese (JLPT N5) or German (A1); kana / alphabet, 300 words, phrases,
  phone voice + speech recognition support both. French / Chinese later only if students ask.

## Decided 18-Oct (user)
- The whole concept is "🎯 Placement"; Japanese (JLPT N5 path) is a track INSIDE it (English, Aptitude, Technical, Japanese).
- Every question shows its source tag. HONEST tags only (Claude writes the questions, they are not copied papers):
  "TCS NQT pattern", "Infosys pattern", "Wipro pattern", "Accenture pattern", "AMCAT pattern", "Interview Q (HR / technical)",
  "Workplace situation". Never "asked in TCS 2025" unless it really is a published previous-year question. No company logos.
- Questions framed as real work situations (salary hike %, client call, office email, bank / GST case).
- No competitions for now. Pull students in with: free Davan "Placement Ready" certificate per track (PDF, QR to verify, PRO =
  gold) for resume / LinkedIn; company-pattern mock tests ("TCS NQT pattern mock, 60 min"); "Prepare for <company>" paths;
  Ready Score used by the college for campus-drive shortlists (only if the college really does it - user to decide);
  PRO ring on the student's photo in both apps; monthly top-10 shout-out on the Davan widgets; social proof ("312 practising
  this week"); widget nudges ("your class is ahead of you").

## Mockup v3 (18-Oct) - widget drawn from the REAL student widget
- Widget Placement page = normal Pages.Row rows (c_chip / c_lilac / c_cream / c_ev / c_rose / c_water, title 12.5 bold, badge pill,
  body 16, inner box, 2 bars, table lines, up to 6 btn_pill buttons). Row already has badge / inner / bar / t / btns: Cards v2 only
  has to pass these fields from the card JSON + button actions (answer A-D, Hear, Say it, Know it, Got it, ಕನ್ನಡ, Next). New page
  (10th dot "🎯") = one widget build. Two-way: answer on the widget, the row turns green / rose with the explanation + follow-up buttons.
- Japanese shown with Kannada letters for the sound (しごと = ಶಿಗೊತೊ) + Kannada meaning (ಕೆಲಸ) + English (work).
- Notifications (registry, default ON, 20-min gap, outside class periods): word 8:05 am (spoken), question 6:15 pm with answer
  buttons IN the notification, streak 8:15 pm only if not opened, level-up / certificate when it happens, league Sun 6:30 pm,
  new mock Thu 6:45 pm. Times to be clash-checked on the 🔔 page when built.
- Added screens: first open (goal, English / ಕನ್ನಡ help, time a day, 5-min level check), mock result (sections, weak topics),
  certificate (QR verify, LinkedIn / WhatsApp / PDF), placement tips on home + widget.

## Open as (page 2) + staff learners (user, 18-Oct)
- Super Admin opens a student (or staff) on page 2 of the widget / in the app: the Placement page shows THAT person's real data
  (levels, streak, XP, Ready Score, tries, today's word / question, what they answered). READ-ONLY for their record.
- Anything the Super Admin does there (answer, practise, Say it, Know it, mock test) is a "preview session": shown at once on his
  screen, kept only on his phone (memory, cleared on ↩ Back to me), NEVER written to learn/ans or learn/prog of that person, never
  counts in streak / XP / league / reports / certificates. A small "👀 Preview · not saved" tag on the page. Same rule in the app.
  (Roles.who(c) for what is SHOWN; writes go only to the owner's own id - pair_raw - and are skipped while another person is open.)
- Staff learn too: Super Admin, Principal, admins, office and faculty get the full Placement page in the staff widget + staff app,
  with their OWN progress (id = S-code / login), own streak and certificates, a separate staff league, never ranked against
  students and left out of student reports / campus-drive lists. Japanese track for staff (the Super Admin wants to learn it).

## NEXT (user, 18-Oct): everything in the WIDGET, mockup look (app opens only after the first widget answer)
User: "voice etc is in widget only, not in app - I want all features in the widget, look / feel / colour as the mockup".
Plan: a NATIVE full-screen PlacementActivity inside both widget APKs (student + staff), opened by the widget row buttons
(▶ Practice, 📖 Learn, 🎤 Speak, 🇯🇵 Japanese, 📝 Mock, 🏅, 💡) - not the browser, not the Davan app. Screens = the approved
mockup (claude.ai/artifact/E2rS4V5k1TsDywAVFBpv4t; same as learn/placement.js v3): level map path, story lesson cards (EN / ಕನ್ನಡ,
TextToSpeech), practice / test 2x2 tiles (pass 80%), speaking (SpeechRecognizer, wrong words red, score), Japanese flip cards +
N5 levels, mock tests (timer, sections, weak topics), tips, certificates. Data: learn/bank.json (cached) + DB4 learn/prog, log, qs
(same fields as placement.js, so app and widget share progress); page-2 Open-as = preview, never writes. Java, no lambdas, Views
built in code (no new layout ids -> no stale-view problem). Check no other session is building widgets first (versions clash).
- (user, 18-Oct) The WIDGET is the main product; the Davan app is only a backup. Android only, never a browser page for this.
  Entry points: a new widget row "🚀 FULL PLACEMENT · IN THIS WIDGET APP" (▶ Practice · 📖 Learn · 🎤 Speak · 📝 Mock · 🇯🇵 · 🏅)
  + a big 🎯 Placement card (score, streak, Open Placement) and 4 quick buttons at the top of ⚙ Widget settings
  (StudentPermissionActivity; staff: its settings screen). Mockup row 4 "Android · inside the Davan widget app" (Settings + N* boards).
  Build only after the user approves the mockup.
- (user, 18-Oct, FINAL) ONLY 2 places: (1) the home-screen widget, built to look like the mockup's widget board; (2) the widget's own
  Android settings page with a 🎯 Placement page carrying ALL features (native). Apps / browser: switched off (portal v11.81 hides
  menu + banner, staff app v1907 = Super Admin only for report / question bank). Students must come to the widget, not the app.
  The widget rows built in w246 / s298 are to be redone to match the mockup in the same build. Build in a fresh session.
- THE mockup to build from (18-Oct, clean, 6 screens in one row): https://claude.ai/artifact/96dDUE8i4qvc6K3HeXpFkY (1 widget, 2 widget settings with 🎯 Placement, 3-6 widget-app screens). Student app dashboard banner stays ON and only sells the widget (portal v11.82).
- (user, 18-Oct, LATEST - overrides the lines above) Build EXACTLY the 5 screens of https://claude.ai/artifact/96dDUE8i4qvc6K3HeXpFkY inside the widget app (1 ⚙ settings with the 🎯 Placement card, 2 Placement home, 3 practice / test, 4 speaking, 5 Japanese) - nothing extra. NO new row on the home-screen widget (user: "why you added new").

## Confirmed plan - 3 layers (user, 18-Oct-2026: "It's now correct") - NOT built yet
- **Layer 1 = the home-screen widget (main product)**: 4 Placement pages - 1 English, 2 Aptitude, 3 Technical, 4 Japanese.
  Daily, one item at a time, two-way (answer A-D, hear / say, know it). Mockup: artifact 96dDUE8i4qvc6K3HeXpFkY row 1 (WEnglish / WAptitude / WTechnical / WJapanese).
- **Layer 2 = the widget app's own Android page 🎯 Placement** (native, never a browser): levels, lessons, practice / tests, speaking with the mic,
  Japanese levels, mock tests. Mockup row 2.
- **Layer 3 = browser Davan app**: history / results only (read-only "My Placement", later) + the dashboard banner selling the widget + Super Admin report / question bank.
- Staff get the same in the staff widget with their own progress. Build only when the user says, in a fresh session, with the other widget session paused.

## Change (user, 18-Oct-2026): WIDGET ONLY - no native app page (Layer 2 dropped)
Everything runs in the 4 widget pages: lesson cards (▶ Next card), "why" after a wrong answer, mic speaking (tap 🎤 -> Google's small
speech box over the home screen, score back in the widget - the only popup Android forces), mock tests one question at a time with a
timer (Chronometer), results, certificate drawn as a picture + Android share sheet. Answers stay A-D (widgets cannot take typing).
Mockup: artifact 96dDUE8i4qvc6K3HeXpFkY row 1 (daily) + row 2 (same pages, other moments). Browser app = history + banner only.
- Placement HOME page in the widget (user, 18-Oct-2026): page 🎯 first (ready score, streak, today's tasks, 4 tiles); a tile tap jumps to that page (same as a page-dot tap), ⌂ goes back. Widget has 5 Placement pages: 🎯 🗣 🧠 💻 🇯🇵.
- DESIGN (user, 18-Oct-2026: "our first plan was correct"): the widget pages use the FIRST Placement design (ready score + company chips + 4 gradient tiles home, zig-zag level map, lesson cards, big A-D practice, speaking with mic, Japanese card + N5 path) inside the widget frame with the page dots / ⌂ footer - not plain rows. Mockup 96dDUE8i4qvc6K3HeXpFkY v8.
- FINAL PLAN (user, 18-Oct-2026): widget = ONE 🎯 Placement page (home design; word + question of the day answered on the widget). A tile tap opens the widget app (native) at page 2 🎯 Placement on that track: English speaking (in-app mic), Aptitude map / lessons / practice, Technical, Japanese, mocks, certificates. Browser app = history + banner. The mockup 96dDUE8i4qvc6K3HeXpFkY v9 is exactly what gets built. Not built yet.
- BUILT 18-Oct-2026: widget part = student w247 / staff s299 (next channel, public at 9:15 pm). Technical tile = the student's own course only (staff: BCA). NEXT: the native widget-app page 2 🎯 Placement.
- BUILT 18-Oct-2026: native page = PlcActivity in student w248 / staff s300 (tiles + settings 🎯 card open it; Open as = that person's data, 👀 Preview, nothing saved).
- 18-Oct-2026: word of the day = 7:40 am notification + spoken (w249 / s301, staff app v1908 registry).
- NEXT: Japanese letters first + Type → 日本語 - JAPANESE-PLAN.md (mockup approved for building, 18-Oct-2026).

## Student web app page (user, 19-Oct-2026, overrides "apps switched off") - BUILT portal v11.85
The app's 🎯 Placement page is HISTORY & REVIEW only: progress, 📜 history, 📖 solutions + tricks of cleared levels, 💡 tips, 🏅 certificates (download). No practice / tests / speaking in the app - every screen sends the student back to the widget. Shown for degree students, locked (sections greyed + install steps) until the first widget answer (prog.xp > 0). Code: learn/placement.js `hist` mode. Not stored: the answer the student picked (the log keeps only kind / track / level / score), so solutions show the right answer + why, not "you chose B" - would need the widget to save picks.

## BUILD-ALL PLAN (user, 19-Oct-2026: "build all in one go") - steps 1-5 ☑ BUILT 19-Oct (student w253, staff s304, portal v11.87, staff app v1913; not phone-tested); decisions: league ON, photos everywhere, staff league separate
Checked in code 19-Oct: the "class league" is only a comment in Placement.java (nothing drawn); the widgets draw only the owner's initials, never a photo.
One request, built as ONE release train in a fresh session (student w253 + staff w304 + portal + staff app), in this order so each step can be tested:
☑ 1. PHOTOS (rule "every list of people"): real photo (tap = zoom, 🏨 mark) in the Placement header (widget, native page, portal, staff app); PRO ring.
   Needs: where other people's photos come from for a league row (check the existing student / staff photo store; the widget only holds its owner's photo).
☑ 2. WEEKLY LEAGUE: prog gets weekly XP `wk` = {w: weekKey, x: xp} (touch() in widget + app); league = top 10 of the class by this week's XP (+ you), photos,
   staff league separate (r = stf), Sunday 6:30 pm result; monthly top-10 shout-out; "your class is ahead" nudge; "N practising this week" counter.
☑ 3. NOTIFICATIONS (registry, default ON, 20 min gap, 7 am - 9 pm): question with A-D buttons in the notification, streak 8:15 pm only if not opened,
   level-up / certificate when it happens, new mock Thu 6:45 pm, league Sun 6:30 pm. (Word 7:40 am + question 6:50 pm are built.)
☑ 4. FUN: badges, confetti + sound on level-up, animated flame, wrong answers return for revision, Saturday 20-minute challenge.
☑ 5. CERTIFICATES: QR to verify + LinkedIn / WhatsApp share; "Prepare for <company>" paths.
6. LATER (own sessions, NOT built): "beat your friend" duel; Kannada explanation for all 464 questions (content writing).
Pairs: student widget + staff widget (same code, both repos' PlcActivity / Placement), learn/placement.js (portal + staff app), staff app registry (NOTIF_REGISTRY), DB4 index on learn/prog (wk).

Built 19-Oct (how): prog.wk {w: Monday IST, x}, mo / pm {m, x}, bs (best streak), sat {d, s}, h (hostel) - written by touch() (widget PlcFun.bump, app touch).
League = learn/prog?orderBy="c"&equalTo=<class> (staff "r"="stf"), widget every 6 h (plc_lg), app on open; photos: student DB2 davan_student_photos/<URN> (files/plcf), staff FacPhoto.
Notifications: gen_plc_qod custom big view A-D (Alerts.BIG, OpenActivity plc_nans), gen_plc_streak 20:15, gen_plc_mock Thu 18:45 (mock of the week), gen_plc_league Sun 18:30, plc_lvl event.
Revision = phone-only plc_wrong (wrong qid -> back the next day). Certificates: QR -> learn/v.html#<id>.<track>.<level> (anonymous DB4 read). Paths = bank.json "paths" (also in build_levels.py).

## FINAL BUILD PLAN (user, 23-Oct-2026) - mockup v4 https://claude.ai/artifact/2RDGezjZqDbhu6999iZJQe
Live data 23-Oct: 31 students + 2 staff; top Nanditha 76 / Akshatha 72 / Sindhu 70; 19 at level 0; L1 tests + company mocks hardest; 2 on Japanese.
Already done 23-Oct: SA report photos (staff w336), local weather (student 280 / staff w337), class-feedback skip ahead (v1940), tools/learn_report.py (davan-scraper, read only).
Decisions: Level 1 pass mark unchanged (8/10); anti-cheat for PRO only; Ollama code removed from the staff app; AI = Cloudflare Workers AI;
Live AI interview when 20 students pass PRO; PRO+ Rs 500 only after 10 PRO+ students (decide later); sharing optional, never forced.
- ☐ S1 small: 🏨 on SaActivity report rows (p.h); SA report counts 🆕 new today/week (prog.fd first day, old learners from their log),
  ⬆ moved up a level today/week, 😴 stopped 3+ days (native SA page + staff app); remove Ollama from the staff app;
  💻 Technical other courses: chips [BCA ✓][BBA][BCom], own course first; other courses = "Explore" with their OWN knowledge XP (kx),
  shown only there - NOT in XP, league, Ready score, rank or report (student widget native, portal, staff app). Mockup first.
- ☐ S2 🇯🇵 Japanese word of the day replaces the ✨ quote in the 7:30 voice note: daily-jp.json (365 words: word, romaji, Kannada letters,
  English + Kannada meaning, example) + one checked "Why Japan" line a day (JLPT, MEXT, jobs, comparison, live Davan numbers, tips);
  🔊 Hear / 🔁 Slowly / ✅ Got it; widget Today card, portal dashboard card, Today's messages; staff widget too; count taps.
  Plus: Why Japan card, 7-day starter challenge, 🇯🇵 badge in league/battle, teaser after English level 10.
- ☐ S3 📊 report card: graphics + code-written text (where you stand / going well / holding back / compare / next) + 🔊 Read;
  student widget native + portal (backup) + SA view of any student.
- ◐ S4 AI (23-Oct: worker /ai live v12; feedback moments lvl / mock / stuck BUILT widgets 282 / w339 + staff v1943 💬 Feedback with AI summary; still: Ready 70 / Saturday / monthly moments, portal card, coach note, student AI auth): Cloudflare Workers AI through the worker; feedback = one tap on result screens + one AI "why?" (chips + 🎤), max 1 a day,
  +10 XP, schedule table in the mockup; AI joins the pieces per student; SA 💬 Feedback page (Placement / App / Widget);
  🤖 coach note auto for Ready 70+ (Sunday, cap 50 a week).
- ☐ S5 growth: teasers as students come close (PRO, Saturday challenge, Live AI 0/20); ⚔️ course battle BCA/BBA/BCom
  (average XP per learner) + optional share card (+50 XP first time); comeback engine (stuck / away 2+ days / never started, 1 a day);
  class teacher 📣 Ask your class card + stuck list (staff widget + staff app).
- ☐ S6 👑 PRO ladder: endless levels after 10, each harder, 9/10 to pass, fresh questions on a retry; anti-cheat (shuffle, minimum time,
  tab switches, practice vs mock check, flags only, server-side answers).
- ☐ Later: 🤖 live AI mock interview (at 20 PRO); 💎 PRO+ plan (after 10, Rs 500 - decide then).
