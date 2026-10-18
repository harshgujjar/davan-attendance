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
- ☐ 1. Content set 1: words.json + English L1-L3 + Aptitude L1-L3 (each sub-track) + Technical L1-L2 per course (Claude writes).
- ☐ 2. Student app 📚 Learn page (level map, play, progress, badges) + learn_cfg db switch + DB4 rules for learn/.
- ☐ 3. Staff app: Super Admin Learn report + campus-drive filter / export; faculty get the Learn page in the staff app.
- ☐ 4. Cards v2 (tap-to-answer rows) + widget 📚 Learn page: student build + staff build; 8 am / 4 pm notifications.
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
