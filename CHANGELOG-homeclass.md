# Gujjar Home Class - changelog (newest first)

- 05-Nov-2026 · kids v58 · parent v47 · app h27 (user: "the child app still has many problems - it is not recognising properly - 7 7 zaa / how much - check the log and the sound and fix"): log 05-Nov:
  (1) THE MOTOROLA PHONE HAS NO SOUND: h26 logged "voice engine ready · default sia.netttsengine.ttslexx · installed: com.google.android.tts sia.netttsengine.ttslexx" - the phone's default speech
  engine is not Google's and speaks nothing; Google's was installed. h27 asks for com.google.android.tts BY NAME whenever it is installed (default only when not), checks every sentence
  (a voice that does not START within 4 s switches to the next installed engine, max 2, and says the sentence again), and shows the engine in ⚙️ (kids) and in the parent app's device list.
  (2) the h26 "did not start speaking" line fired on every short sentence (it compared with the LAST started id) -> now a per-utterance set. (3) cfg/joiner is "is" (left from the tests): the voice asks
  "seven, seven is?" - the parent chooses ja / za / zaa in Settings (🔊 Hear it on the parent phone). Recognition: the Redmi's table 4 / 7 recitations (85 s, 110 s, restarts and corrections) were heard
  as noise ("four four four [unk] four two eight forty za twelve ...") but the single-line follow-up questions counted both tables (right 2, wrong 0). Functions: initTts, speakNow, ttsEngine.

- 05-Nov-2026 · kids v57 (user: the voice says "7 7 how much" instead of "7 7 zaa"): the question line "a b ja?" ended with a question mark right after the joiner, which the speech engine turned into a question phrase. rawSay now replaces "<joiner>?" with "<joiner> ..." before speaking (screen text unchanged). No data/cost change. Phone logs could not be read in this session (Firebase blocked) - listening complaints need the log copy (⚙️ → 🩺 Log → 📋 Copy). Functions: rawSay.

- 04-Nov-2026 · kids v56 · parent v46 · app h26 (user photo 11:48: "sound is not coming - Hello ... on my phone where the child app is installed"): the log of that phone (Motorola edge 50 pro, Android 16, h25 freshly installed)
  shows "voice: no 'done' from the speaker engine" after EVERY sentence from 11:43 - the phone's text-to-speech never started or never spoke (it spoke fine on 3 Nov, no such lines). I cannot see the
  phone's voice settings, so h26 makes it self-diagnosing and self-repairing: the engine start is checked after 6 s and retried (1st with Google's speech services by name, then the default), the log
  names the default engine and every installed engine, a voice that never starts speaking is logged / reported (HCA.voiceState ok / loading / failed / silent), onError codes are logged. Page: after 2
  sentences in a row without "done" a help bar shows - ⚙️ Open voice settings (the phone's Text-to-speech screen) / 🔊 Try again; the heartbeat carries voice, the parent app's device list shows
  "🔇 no voice". Tested in a browser with a silent voice: bar shows, the settings button calls the app, a working voice hides it. Functions: initTts, speakNow, voiceHelp, rawSay.

- 04-Nov-2026 · kids v55 · parent v45 · app h25 (user: "when I say call it must call ONE specific phone - show the phone make; name each phone at the start and use it as the base"): the cause - a call (cmd dev
  "any") went to EVERY phone that starts classes. Now: (1) each phone asks "Name this phone" once (suggestion from the model; two phones with one name get the model added; after a
  re-install "↩︎ same as <old entry>" takes the old entry over and deletes it); the heartbeat carries dev/<id>/{name, model, named}; h25 gives the make + model (HCA.model()). (2) parent
  Home: when 2+ phones start classes each child shows "📱 On which phone?" (name · model · online / last seen); every Start / Call / Test / Lesson goes to that one phone (cmd dev = its id);
  Stop goes to the phone that runs the class; the last choice is remembered; a warning when the phone has been offline. (3) Settings -> child -> "Class phone": only that phone rings at
  class time (timer + alarm); if it has been offline 3 min after the class time another phone that starts classes takes over (its alarm wakes 4 min later). The TV starts on the class
  phone. (4) Settings -> Devices: name + model, "needs a name" tag, ✏️ rename (devcfg/<id>/ren), 🔔 test (the phone says "Hello! This is <name>"). Tested: parent call -> dev = chosen
  phone; class-phone rules at 18:31 (other phone online: no call, this phone: call, class phone offline at 18:35: takes over, none set: call); name screen + adopt + rename.
  Functions: openNameScreen, isClassPhone, devModel, parent targetDev / phonesList / sendCmd, data-ren / data-tst, saveKid dev.

- 04-Nov-2026 · kids v54 · parent v44 · core v36 (user photos 9:47 / 9:51 / 9:52 + "check the log, fix the problems"): (1) ANSWER COUNTDOWN: Settings -> "Time to answer a question" (Off / 10 / 15 / 20 / 30 s, default 20)
  and "Countdown in the last" (3 / 5 / 10 s, default 5; cfg/ansTime, cfg/ansCount). One clock per table question (warm-up, revision, in-order, mixed), quiet until the last
  seconds, then a big 5-4-3-2-1 near the mic; it waits while he is speaking (partials) and while paused; at zero: "Time's up" + the answer, counted "to practise", then
  the next question; with a clock, plain silence is handled by it (no "sorry" sheet). Tested: only 3-2-1 shown, "Time's up. twenty two, four ja eighty eight." (2)
  LETTERS POP UP: the app says the word letter by letter - each letter pops up big, the earlier ones go down in a row, then the whole word (on a Wi-Fi speaker the
  letters come on a timer); used for right / "let us look" / "not quite", app and Mom-Dad mode (spellOut). (3) TYPE / SPEAK STUCK (log 21:51 "mic off (keys)"): 3 listening
  errors switched to typing for good (typing never listens, so the count never reset; the button only flipped a flag the count overrode, and the question waiting
  for typing never woke). Now: count + typing reset at every class start, the button shows what it switches TO (🎤 Speak / ⌨️ Type), pressing it resets the count and wakes
  the waiting question. (4) LOG: a heard answer far smaller than the right one (nine for 88, sixty for 161) is asked once more (C.numTruncated); the spelling mic opens
  0.9 s (1.5 s on a Wi-Fi speaker) after the app's voice (extra "E S" before BONES in photo 3). Functions: hear (clock), askTable, spellOut, syncType, kType, C.numTruncated.

- 03-Nov-2026 · parent v43 (user: "why hear in the kids phone - I want to hear it on the parent's phone"): 🔊 Hear it (how to say the name, ja / za word) plays with the parent app's own voice
  (HCP.speak, the same TTS the lesson editor uses; a browser uses speechSynthesis); only a phone with neither voice falls back to the kids phone. The sample text goes through
  C.speakNums like the kids app (words, pause between table and line). No new APK needed. Tested with a mock HCP: the parent phone said "five one za five. five two za ten.
  twenty one, three za sixty three." and "Hello Aar yun! Ready to shine?", no command to the kids phone. Functions: hearHere, playJoin, data-hear.

- 03-Nov-2026 · kids v53 · parent v42 (user: "how about testing za then ja - give option in the parents app to set and check"): Settings -> "The word between the line and the answer":
  ja / za / jha / jaa / zaa / is, saved as cfg/joiner; tapping one saves it and the kids phone plays "five one <word> five. five two <word> ten. twenty one,
  three <word> sixty three." (cmd say, raw) so the parent hears the real voice; 🔊 repeats it. The kids app replaces "ja" in every spoken line with the chosen word
  from the next class on (rawSay); the screen and the listening (ja / za / jha all accepted) are unchanged. Tested: parent saves "za" + sends the sample, the
  kids page then says "one, two za two". Functions: parent sJoin / playJoin, kids rawSay (keep), onCmd say.

- 03-Nov-2026 · kids v52 · parent v41 · core v35 (user: "it says 2 one 3 za but it is 21 3 za - check the sounds and log"): Aryan's class (tables 11-30): the voice read "21 3 ja" digit
  by digit ("two one three ja") and the log shows the child answering what he heard ("one three za sixty three", "four six za one forty four", "one" for 21 x 3).
  Every number in a spoken line now goes to the voice as WORDS, two numbers side by side are split by a comma (a pause): "21 3 ja 63" -> "twenty one, three ja
  sixty three" (C.speakNums, applied in rawSay for the phone voice and Google Home; the screen keeps digits). Tested on the lines of the app (questions, corrections,
  "table of 5", scores, "tables 11 to 30"). Functions: C.speakNums, rawSay.

- 03-Nov-2026 · kids v51 · parent v40 · core v34 (user screenshot 9:19: "This phone cannot play a test voice here" - "I can't hear"): the parent app has no voice, so 🔊 Hear it now sends
  cmd {do: "say", text: "Hello <how to say>! Ready to shine?"} (DB3 homeclass/<fam>/cmd, a few bytes) and the kids phone says it with its real voice (phone or
  Google Home); ignored while a class runs. The field showed "Aryan" - typing the name itself is the same as not setting it, so the built-in "Aar yun" is
  kept (C.sayName). Tested: parent sends the command, the kids page speaks "Hello Aar yun! Ready to shine?". Functions: parent data-hear, kids onCmd ('say'), C.sayName.

- 03-Nov-2026 · kids v50 · parent v39 · core v33 (user: "I want it to say Aryan properly - it sounds 'Arien'"): the voice reads the child's name from a respelling - built-in
  default "Aryan" -> "Aar yun" (C.NAME_SAY), changeable per child in the parent app (Settings -> child -> "How to say the name", saved as cfg/kids/<id>/say,
  + 🔊 Hear it plays "Hello <name>! Ready to shine?" with the phone's voice to test a spelling). Applied in rawSay for every spoken line (phone voice and
  Google Home); the screen keeps the normal spelling. Works for any name, no new build needed to change one. Tested: the voice receives "Hi Aar yun!",
  the caption shows "Aryan". Functions: C.sayName, rawSay, parent saveKid / data-hear.

- 03-Nov-2026 · kids v49 · parent v38 · core v32 (user: "check the log, it is not working properly still"): log 20:53-21:02. Tables of Vihaan worked (table 5 / 6 counted after
  the single lines, warm-up skipped, test me now, next table). Found: (1) Aryan 17 x 10: "one seventy" (= 170 the Indian way) was marked 70 -> a number
  with no "hundred" (one seventy, two forty, one twenty six) now counts as hundreds (tableOne); (2) a doubtful single answer (70 for 170, 43 for 63) was
  "Not quite" at once -> asked once more first (C.numAlike, askTable); (3) Evs "handkerchief" (12 letters): three tries all "unsure" - he pauses between
  letter groups, so while fewer than 75 % of the letters were heard the app now waits 3.8 s of quiet (was 2.2 s), and long words are more forgiving
  (limit grows 12 % per letter above 6, from the 2nd try). Functions: C.tableOne, C.numAlike, askTable, spellAccept, spellListen.

- 03-Nov-2026 · kids v48 · parent v37 · core v31 (user: "it always says 5 one ja 5 - I did not hear that - it is not important, we skip it"): table x 1 (= the table
  itself) is only SAID in "say it after me" - no listening, no "Your turn", straight to x 2; in table questions an unheard x 1 is accepted (no "I could not
  hear"); in the whole-table recitation line 1 is never missing / unsure (C.checkRecite). Learning is not a test: a line that cannot be heard is listened
  to once more quietly, then the app goes on after 2 tries (was 3, with talking) and logs nothing as wrong when nothing was heard. Functions: learnFact,
  askTable, C.checkRecite.

- 03-Nov-2026 · kids v47 (user photo 9:45 + "why are practise a table / Evs separate - keep them inside the child's block"): (1) spelling finishes by itself: when the
  letters heard are EXACTLY the word (and in Mom / Dad mode exactly one of the words) and have not changed for 0.9 s, the listen ends - no ■ Done; a
  sound-alike / doubtful spelling still waits the normal 2.2 s; "quiet" now means the letters stopped changing (repeated partials are not activity).
  Tested: exact word answered 1.4 s after the letters, sound-alike 2.9 s. (2) Home: each child's card holds ▶ Start class, 📚 Practise a table and
  his lessons (✏️ Evs) - the old row of separate buttons under the cards is gone; the card is a div, ▶ Start class is its own button (TV remote focus
  keeps working). Functions: spellListen (RC.chg), drawHome2, kids click handler.

- 03-Nov-2026 · kids v46 (user photos 9:19 / 9:24: "skip the warm-up; test me while learning the table; the screen shows the old data"): (1) ⏭ Skip warm-up
  (this class only) ends the whole warm-up; (2) 🙈 Test me now while "say it after me" - the table goes to the test without seeing (also in "Say it
  with the app" practice); (3) buttons by section (S.sect): Skip + Skip warm-up in the warm-up; Skip, Test me now, Next table, Go to table while
  learning; Next table / Go to table in the test and table questions; "⏭ Skip word" + Clear in spelling; Pause / Stop / Type always. (4) stage(): at
  every change of part (warm-up, table, round end, lesson, next word / question) the old question, board, heard line and pop-up are cleared and a title
  card ("📚 Table of 3") shows while the app talks - tested: during "Let's learn the table of 3" the screen shows the card, not the last warm-up
  question. Skip lesson was NOT added (user: skip the word, not the lesson). Functions: setSect, stage, chk (WARMX / TESTN), tablesLearn, practice,
  runSet, askSpell, askOral, hbShow.

- 03-Nov-2026 · kids v45 · parent v36 · core v30 ("Build 1", user: "it is the software not hearing, not the child's mistake"): (1) answer finds its line: log 08:37
  "three ONE twenty four" / "three za into twenty four" - the line number is what the engine loses; an answer above the table's range (12, 15, 18 ...) is
  unique to one line, so it is read as that line when it fits between the neighbouring lines in the order spoken (3 x 8 = 24 now counts). (2) the long
  recitation never says "wrong": every doubtful line is asked again alone (short question, only fitting answers allowed), and that decides; the
  asked line shows "= ?" and does not give the answer away. (3) ⏭ Skip button for the whole class: cuts the app's voice, skips the current
  question (no right, no wrong); ⏭ Next table (⏭ Stop this table in table practice) and 🔢 Go to table (jump 4 -> 6: skipped tables come back at the
  end). (4) the app could not hear twice in a row: it says "Sorry, it is my fault" and shows ✅ Yes, I said it / 🔁 Say again / ⏭ Skip instead of asking
  again and again (counted in the log as "not heard (app)"). Tested on his 08:36 table-3 recitation (no wrong lines) + browser tests for skip / next /
  jump / sheet. Functions: inQ, chk (SKIPQ / NEXTT), releaseWaits, notHeard, confirmSheet, tablesLearn (skipT, jumpTo), practice, C.checkRecite.

- 02-Nov-2026 · kids v44: a doubtful line ("unsure") is now a real question - "I am not sure I heard 3 4. Say that line again." with "= ?" on the
  screen; the answer is said / shown only after he has tried (before the message gave the answer away). A real mistake one digit off (5 x 7 = 30)
  is therefore asked again instead of corrected at once. Function: reciteTable.

- 02-Nov-2026 · kids v43 · parent v35 · core v29: (1) STUCK on "Welcome Vihaan!" (photo 21:22, log 21:16 and 21:21 "Promise error: Cannot read properties of
  null (reading 'kid')"): finish() said "Class over!" for several seconds with S.running already false; a new class started in that time
  and then finish() ran `SES = null` - wiping the NEW class. Now it clears SES only when it is still its own, does not switch the busy /
  keep-awake flags off under a new class, a new class silences the old goodbye, and runClass survives a failing finish(). Reproduced and
  fixed in a browser test (before: that error; after: the class runs). (2) His real table-3 recitations (21:18, 21:20; rec/): the engine
  returned "thirty three" for 3, "one" for twelve, "ten" for fifteen, "ready" for eighteen - he said it right and got "wrong". An answer one
  digit away from the right one is now "unsure" (that line asked again alone), up to 6 lines (was 2); "wrong" only when clearly different.
  Both recitations: no wrong lines (4 and 1 lines asked again). Functions: finish, runClass, C.checkRecite (alike), reciteTable.

- 02-Nov-2026 · kids v42 · parent v34: user photo 10:05 (Mom / Dad mode showed only dots, no letters) + "the pop-up I want is when all is correct and
  the app repeats the word - at that time". (1) Mom / Dad mode: while he spells, the word the letters fit best (C.spellWhich) is used for the
  boxes and the marked chips, so the letters appear live. (2) Right answer: the app says its praise, THEN the word pops up and stays while the app
  says "bones is spelt B, O, N, E, S" (popWord now stays until hideFlash; before it vanished after 2.6 s, in the middle of the speech).
  Same for "Let us look at it" / "Not quite". Functions: hcRecite (RC.list), popWord, askSpell, parentSpell.

- 02-Nov-2026 · kids v41 · parent v33 · core v28: user: "pop up what it is reading, marked". While spelling, the line under the mic shows each heard
  letter as a chip that pops in (C.heardView: green = fits the word, amber = sound-alike, red = a different / extra letter, grey ? = not
  understood; the "e"+letter splits are hidden); when the word is finished a big pop-up shows the word with "I heard: ..." chips (right, doubtful
  and wrong). Log 09:50-09:56 (before this): 10 of 12 words accepted on the first try, the other 2 on the second. Functions: C.heardView,
  chipsHTML, popWord (askSpell, parentSpell).

- 02-Nov-2026 · kids v40 · parent v32 · core v27: "when I say S it takes something else" - his 09:15 recordings: S / M came back as "e s" / "e m" and the
  live letters showed them raw, so it looked wrong and he pressed Clear in the middle of the word (the next listen caught the rest of the
  word). The live boxes now show only letters that FIT the target (C.liveLetters: sound-alike counts, extra "e" before m n f l s x skipped),
  a dot for the rest; the line under the orb no longer prints raw letters. Real recordings of 9 words: 4 accepted at once, 3 more after
  one repeat. Functions: C.liveLetters, boardHTML (s).

- 02-Nov-2026 · kids v39 · parent v31 · core v26: from 10 real spelling recordings (bones / muscles, rec/): the engine splits "em" / "en" / "es"
  into "e" + letter (muscles: "e m you ess see l e ess"), loses letters, and the word list for "Mom / Dad says the word" never matched real
  speech ("we will any is"). Fixes: (1) an extra "e" before m n f l s x costs .2 and a heard "e" may stand for those letters; (2) Mom / Dad
  mode no longer listens for the spoken word - the child's LETTERS are matched against every word left in the list (C.spellWhich, grammar holds
  all words spelled out); (3) a doubtful hearing is never "wrong": ask again, each try accepts a little less perfect hearing (try 2: cost
  < 1.6, try 3: < 2.6), then the word is shown and it moves on; "Not quite" only for clearly different letters (cost > 3.4); (4) ⏭ Skip
  button + saying skip / next; skipped = no re-ask. Gain / loudness tests on the recordings changed nothing (engine limit, not volume).
  Functions: spellAccept, askSpell, skipWord, parentSpell, C.spellWhich, C.isSkip, C.spellGrammar(list).

- 02-Nov-2026 · kids v38 · parent v30 · core v25: "for N it says 'en', all wrong" - 5 real recordings of "bones" (rec/ 08:19-08:40): N is said "en"
  and the engine returned "e"+"en", [unk] or "i"; the letters list now also holds the target word spelled out (4 forms) - 3 of the 3
  clear recordings came out exactly (bee oh n e s). The heard tokens are ALIGNED to the target word (C.spellJudge, edit cost: sound-alike
  letter .5, [unk] = any letter .3, extra "e" before "en" .2, missing letter 1.2); said twice / talk before = the best stretch counts.
  Not sure = ask again slowly (max 2), then show the word and move on ("We will try it again soon"), never "Not quite". On the 5
  recordings: 4 accepted, 1 (b o e i r) asked again. Functions: C.spellGrammar(word), C.spellJudge, spellTokens, spellCost, askSpell.

- 02-Nov-2026 · kids v37 · parent v29 · core v24: tested on his 2 real spelling recordings (rec/ in DB3, 08:20): free engine heard "b o n e s"
  as "b o in a yes" (n -> in, e -> a, s -> yes) and his talk as words; with a letters-only list (C.spellGrammar: a-z + letter names,
  everything else [unk]) it is "bee owe n e s" (right) / "bee owe n e f" (s -> f). ONE sound-alike letter (s / f, b / d ...) is now accepted
  (the engine cannot tell them), two or more = "say it again". Both recordings now judged right. Functions: C.spellGrammar, C.spellJudge, spellListen.

- 02-Nov-2026 · kids v36 · parent v28 · core v23: spelling "takes so many wrong words, they stay in the block, no way to delete" (log 02-Nov
  08:20: "we were in yes b o n e s" counted as wrong - the free engine also hears room talk). Only LETTERS count now (C.letterSeq; the target
  word inside extra letters = right), the live letters / board show letters only, a short pause before listening (the speaker may still be
  talking), and a ⌫ Clear button during spelling: throws away what was heard and listens again ("OK. Spell again"). Functions: C.letterSeq,
  C.spellJudge, askSpell (kClear).

- 02-Nov-2026 · kids v35 · parent v27 · core v22 (no new APK): spelling in the Evs class "took 'you' / 'ka b' for letters" (log 02-Nov
  08:08: spelling used Google speech, which does not hear letters). Spelling now uses the offline engine (free recognition, letters shown
  live, ■ Done or 2.2 s quiet ends it). Letters that sound alike (b d p t v c e g z, m n, f s x, a j k, i y, u q) = "unsure" -> "say it
  again", never "wrong" (C.spellJudge). A spelling lesson opens 3 ways: 📖 show the words (nothing listens, then "test me"), 🙈 app says
  the word, 👨‍👩‍👦 Mom / Dad says any word of the list in any order (C.pickWord + word list grammar), the child spells it; the word shows when
  done. Every spelling is saved as a recording (rec/). Old phones / engine not ready keep the Google way. Functions: askSpell,
  askSpellG, parentSpell, spellListen, openSpellMenu, C.spellJudge, C.pickWord, C.wordGrammar.

- 01-Nov-2026 · kids v34 · parent v26 · core v21 · app h24 (user: "build all 5 in one go"):
  1. "12 not recognised" (2×6 heard as "one" ×3): each question listens only for the answers that make sense (C.qGrammar: right one,
     near misses, the question said back, commands) - synthetic test 53/54 right heard (was 45/54), wrong answers caught 54/54.
  2. "two into two" (fast "2 one za 2") read as line 1 (C.parseRecite).
  3. Spoken table lines are "1 eight ja 8" everywhere (askTable question, hints, corrections) - never "times".
  4. h24 saves single answers too: DB3 ans/<t> + ansdata/<t> (WAV ~0.1 MB, newest 60; whole tables stay in rec/recdata, newest 30).
  5. Lessons are separate classes (user: "don't mix anything, all are individual - if we want we can mix"): ▶ per lesson on both
     Homes (cmd "lesson"), own time + days (alarm + timer), 🔀 "Also after the tables" (sets/<id>.mix) to mix; default not mixed
     (the existing Evs lesson is now its own class). Functions: mixedSets, runClass(opt.set), callKid(opt), timer, alarms, kidSets,
     edit / eSave (time, days, mix).

- 01-Nov-2026 · kids v33 · parent v25 · core v20 · app h23: tested on Vihaan's 3 real recordings (h22): table 1 ×2 PERFECT; table 2
  "two six two twelve" (fast za heard as "two") now right, "two ten into ten" (fast twenty) = asked again, not wrong; an out-of-order
  line whose answer is the next line's counts as that line. Word-by-word listening was tested and was much WORSE on his voice - kept the
  phrase list. Lines the app missed / was unsure of are asked one by one; all right = table counts (a wrong answer still = whole table
  again). h23: speech model downloaded once on Wi-Fi (homeclass-model-en-us-0.15.zip; link / sha in homeclass-version.json), APK 47 ->
  6 MB, app updates on Wi-Fi only. Functions: C.parseRecite, C.checkRecite (fz), reciteTable, hcUpd (mprogress / model / wifi).

- 01-Nov-2026 · kids app h22: fast recitation lost lines as [unk] (log 21:58) - user: "first save the live recording on the phone, use it,
  then test it". Every recite's sound is saved on the phone (newest 10) and sent to DB3 homeclass/<fam>/rec/<t> (what was heard) +
  recdata/<t> (WAV, ~0.85 MB per 20 s; newest 30 kept, older deleted by the app). Used to test the engine on Vihaan's real voice
  before the next listening fix. Java: Rec.save / Rec.sendAll / Rec.clean, VoskMic.keep.

- 01-Nov-2026 · kids v32: "the table should fit my mobile screen, no scrolling" - the 📖 table page and the class screen with the table
  board (recite / test) now fill exactly one phone screen (100dvh; rows, fonts, mic and thumb button size from the screen height; >12
  lines go in two columns). TV unchanged. Checked at 393×740 and 360×640: no scroll. Functions: openShow, drawBoard (body.bOn).

- 01-Nov-2026 · kids v31 · parent v24 · core v19: "it does not go with my speed" - log 21:46: fast speech drops "ja/za" ("one six six, one
  seven seven"), and the checker needed the separator, so those lines counted as not said. C.parseRecite now follows the pattern table ·
  line · answer with or without ja / za / into (the answer ends where the next "table · next line" starts); the LATEST version of a line
  counts (he goes back); the engine word list also has the no-ja forms. Checked: the real 21:46 recording, fast synthetic tables with
  and without ja through the real engine (mistake 5×7=30 caught every time). cfg.upto set to 10 (user: "1×1 to 1×10"; was 12).
  Functions: C.parseRecite, readNums, C.checkRecite, C.grammar.

- 01-Nov-2026 · kids v30 · parent v23 · core v18: 📚 PRACTISE A TABLE 4 WAYS (user: "just show the table, he practises alone, then I test
  him without seeing"): kids home → "📚 <name> · practise a table" → pick the table → 📖 just show (nothing listens, "I'm ready - test me"),
  🗣️ say it with the app, 👀 with answers shown, 🙈 test without seeing; ▶ Start saying / ■ Done on the big button. Passing the test =
  learnt ⭐. Parent Home → 🙈 Test a table → pick it → the kids phone starts the test (cmd do:test, table). Hearing: only the tested
  table's words (+ usual wrong answers) are listened for; "starting again" is understood. Indian-English model downloaded (davan-scraper
  workflow "Vosk model") and compared: 33 % vs American 98 % on synthetic voices (unfair - it is trained on real Indian voices); American
  stays (proven 10/10 on Vihaan's real recitation, log 21:05) until a comparison on his real voice. Functions: practice, reciteTable (modes),
  waitStart, openTab, openShow, C.grammar (one table), C.checkRecite (restart), parent drawHome (testpick) / sendCmd (extra).

- 01-Nov-2026 · kids app h21: ROOT CAUSE of the crashes found by h19's crash report (log 20:54): "NoSuchMethodError LambdaMetafactory at
  org.vosk.android.SpeechService$RecognizerThread.run" - Vosk's ready-made microphone helper uses Java lambdas that our no-Gradle (dx)
  build leaves unconverted. VoskMic.java replaces it (AudioRecord loop, same callbacks, plain Java); build.sh refuses lambdas in our classes.
  The engine re-enables itself (it was switched off for h19 only). Same h21 (not yet on any device, log 21:00 "old file" loop): updates now
  download from GitHub Pages with a fresh ?t= (raw.githubusercontent kept the previous APK cached for 5 min after every upload), raw = backup.
  Functions: VoskMic, MainActivity.vStart / vEnd, Upd.check.

- 01-Nov-2026 · kids v29 · parent v22 · core v17 · kids app h20: UPDATE YOU CAN WATCH (user: "show what is happening - downloading,
  installing"). Card with every step: 🔎 checking, 📥 downloading app hNN · % · MB of MB (progress bar), ⏳ GitHub still has the old
  file (retry 3 min), 📦 installing, ✅ done / up to date. h20 also takes the newest version from the page (checkUpdateTo, from GitHub
  Pages homeclass-ver.json) - raw.githubusercontent's homeclass-version.json was still "17" minutes after h19 was published.
  Functions: hcUpd, C.watchUpdate, Upd.check (hintV), Net.toFile (progress), MainActivity.checkUpdateTo.

- 01-Nov-2026 · kids v28 · parent v21 · core v16: user "Check for update only says v27, it does not check h19" - the button checked only
  the screen; the app was asked once (20:48) when GitHub still served the old version file, then not again for 10 min. Now the button
  always asks the app as well and shows both ("Screen v27 · App h17 → h19 downloading"), and the app is asked again every 3 min until it
  has the newest one. Function: C.watchUpdate.

- 01-Nov-2026 · kids app h19: h17 updated itself (log 20:46) and found NO Android crash report for h16's restarts - so most likely the
  screen (WebView renderer) died, which takes the app down. onRenderProcessGone now rebuilds the screen and logs it; every unexpected
  exit reason is logged. Comes by auto-update after h18. Functions: onRenderProcessGone, reportLastExit.

- 01-Nov-2026 · kids app h18: user "auto update will not happen" - log: h16 started downloading h17 twice but crashed (engine) before
  the 47 MB download finished; the downloader also kept the whole APK in memory. h18 streams updates to a file (Net.toFile). One-time
  hand install of h18 needed (h16 cannot update itself). Same crash guard as h17.

- 01-Nov-2026 · kids app h17: h16 closed itself on Vihaan's phone ~15 s into a class (log: "app h16 open" again at the first listen,
  no Java error = native). Crash guard: a breadcrumb per offline-engine step (written at once), Android's exit reason + trace
  (ApplicationExitInfo) and Java crashes are logged on the next start; a crash inside the engine switches that phone to Google listening
  until the next app version (VoskEng.off); the engine's memory is freed 3 s after its thread stopped. Functions: reportLastExit, crumb, vEnd, VoskEng.off / disable.

- 01-Nov-2026 · kids v27 · parent v20 · core v15 · kids app h16: 🗣️ SAY THE WHOLE TABLE + OFFLINE ENGINE (user: "what parents do - he tells
  the 5 table fast, the app follows, notes every mistake, tells him where, say it again, then once more"; "Android does not get what is
  told"). h16 carries the Vosk offline engine + small English model (47 MB APK), limited to table words (setGrammar), Google only as
  backup and for oral / spelling. Learning now: listen & repeat ("5 one ja 5") -> say the whole table (board ticks each line live;
  afterwards wrong / unsure (fifteen-fifty) / missed lines practised; "one more time", up to 3 a class) -> learnt. Tests: real engine
  output of fast synthetic recitation (deliberate mistakes found), full flow 1-table with a mistake then perfect.
  Functions: C.parseRecite / checkRecite / grammar / numWord, reciteTable / reciteListen / hcRecite, VoskEng, MainActivity.vStart / vDeliver.

- 01-Nov-2026 · kids v26 · parent v19 · core v14: 🎤 THUMB BUTTON (user's photo: the hold button vanished after "I did not hear it" and
  came back seconds later; "put it down right for the thumb"; "not super active"). Log 19:50-19:52: " 7 * 4 =" marked ✗ 4; a 0.4 s TAP
  heard nothing. Now one big button fixed at the bottom right for the whole class: HOLD = listen while held, check on release; TAP = listen
  hands-free until he stops; pressing while the app talks stops the voice and listens (barge-in); an early answer is kept for that
  question (S.curQ). Hearing only the question's numbers = listen on, never wrong (C.tableOne). Tested: hold / tap / barge-in 3/3.
  Functions: hbDown / hbUp / hbListen / hbDeliver / holdListen, rawSay, C.tableOne.

- 01-Nov-2026 · kids v25 · kids app h15: ✋ HOLD TO ANSWER (user: "can't it hear only me?" - log 19:20: other voices "Rekha", "for
  example", and a few seconds' wait for silence). The child holds a big button while answering; only that is listened to, and letting go
  checks at once (h15 listenHold / endListen = stopListening). Live words show while holding; an early stop while still holding listens
  on. Kids ⚙️ → "🎤 How the child answers": ✋ Hold (default) / 🎙 Hands-free (hc_ans). Tested: 5/5, result ~0.1 s after release.
  Functions: holdListen, holdMode, hear, drawAns, MainActivity.listenHold / endListen.

- 01-Nov-2026 · kids v24 · parent v18 · core v13: user "I say 3, it does not take it" - log 19:09 (1×3): Google wrote "the", then 13 s
  later "three three". A single word that sounds like THE answer now counts ("the" / "tree" = 3, "to" = 2, "ate" = 8 ...); the same word
  for any other answer is not taken (asks again). Function: C.tableOne (SOUNDS).

- 01-Nov-2026 · kids v23 · parent v17 · core v12 · kids app h14: tuned from the real log 19:07-19:10 (h13 offline worked: 50, 60, 10, 72,
  30 ✓). Fixes: "Ja" / "the" (recitation pauses cut the answer) -> 2.2 s end silence; 3 × "speech no" after 1.5 s (offline gives up
  before the child starts) -> listens again quietly up to 8 s; "18 years pilot" / "computer" marked wrong -> mostly-other-words = not an
  answer (C.tableOne junk), first unclear = quiet re-listen; offline speech first and kept once it works. 25 phrase checks pass.
  Functions: C.tableOne, askTable, MainActivity.listenNow / onError.

- 01-Nov-2026 · kids v22 · kids app h13: (1) user's photo 7:01 pm "already correct but asks the same question": quick revision picked
  8×9 twice in one round (weak facts are picked more often) - each fact now only once per round (wrong ones still come back to practise).
  (2) "not hearing at all": log 19:00 - Google's online speech failed (error 2 network), then 8 listens "speech no". h13 switches to the
  phone's OFFLINE speech after a network error or 3 empty listens (and back when offline is not available); log lines say "(offline)".
  Functions: tablesRevise, MainActivity.listenNow.

- 01-Nov-2026 · kids v21 · parent v16 · core v11: "4-5 times I answer, it does not hear" - log 18:52 (h12): no speech in the first listen
  (answer given before the mic opened), "52" for 72 (Google's first guess), then "72" taken. Now: the mic opens 120 ms after the voice
  (Wi-Fi speaker 350 ms) with a soft ding + "🎤 Your turn!"; the first silence just listens again (no talking); when another of Google's
  guesses is right, "Did you say 72? Say it again." once (C.tableJudge altOk). Functions: say, hear, ding, askTable, C.tableJudge.

- 01-Nov-2026 · kids v20: FIX "it runs like a bullet, does not take what I say" - log 18:38 (app h12): "32" ✓, "18" ✓, then "mic: stop"
  3-8 s into the next questions. micListen's 13 s safety timer called stopListen() even after its own listen had finished, so it cut the
  NEXT question's listening; the class saw silence and hurried on. The timer now stops only its own still-open listen (19 s).
  Also seen: "error 2" = Google speech network error (offline English (India) pack advised). Function: micListen.

- 01-Nov-2026 · kids v19 · parent v15 · core v10: 🩺 LOG ON EVERY DEVICE (user: "keep the log on the phones and TV for 1 day, show only
  when I tap"). Kids ⚙️ → 🩺 Log (phone + TV) and parent Settings → 🩺 → 📱 This phone: this device's last 24 h (its DB lines incl. the
  Android "📱" lines + the local copy kept 24 h for offline), hidden until tapped, 📋 Copy / ✕ Hide. Functions: C.diagText, C.copyText, C.diag.

- 01-Nov-2026 · kids v18 · kids app h12: MIC HEARD NOTHING (user's photo 6:21 pm "it does not listen, keeps saying are you there";
  log: a 75 s class with not one word heard). h12 makes a fresh SpeechRecognizer for every answer (Xiaomi's speech service can hang
  when one is reused), restarts it once if it is not ready in 4 s, uses the live words when the result is empty, and logs every listen
  (ready time, speech yes/no, loudest level, partials, error). Function: MainActivity.listenNow / stats.

- 01-Nov-2026 · kids v17 · parent v14 · kids app h11: user "no option to cancel Google and use only the phone" - the button is now
  "📱 Phone only (Google Home off)" with a line saying what it does (kids 🔊 page + parent 🔊 panel). Log 18:17: the Home Mini connected
  (284 ms) but never played Google's web voice ("no answer from the speaker"); h11 sends the phone's own voice as a WAV file first
  (web voice as backup) and gives up after 6 s (phone speaks at once); the speaker's media replies go to the log. Functions: Cast.say / play, spkLine, spkText.

- 01-Nov-2026 · kids v16 · kids app h10: (1) SHORT ANSWERS (user's photo: "eight" shown live, then "Are you there, Vihaan?"): Google
  showed the words but sent no final result; the page (hear / onPartial) and h10 (onError no-match -> last partial) now use the live
  words; the 3 s minimum listening length is removed. (2) GOOGLE HOME (log 18:10, Home Mini: "the speaker did not open its player",
  ~15 s wait per sentence): Cast.say falls back to the staff widget's one-shot way (sayOnce) and keeps it if it works; if both fail the
  phone speaks at once for 2 min (downUntil); launch wait 10 s; the speaker's replies go to the 🩺 log. Functions: hear, onPartial, Cast.say / sayOnce / recvSync.

- 01-Nov-2026 · kids v15: TV live view gets ⏹ Stop class (cmd stop to the device that runs it) - user: "I cancelled but it is still
  running" (TV 🏠 only hid the view; the class ran on the phone). ▶ on the TV no longer starts twice (live check + 15 s guard).
  Log also showed the TV still on app h5: its self-update stops at Android's install window (Home Class not allowed to install apps). Functions: wStop, startOnPhone.

- 01-Nov-2026 · kids v14 · parent v13 · core v9: the app-update card ("downloaded - press HOME") stayed on screen over the settings
  (user's photo); it now closes after 15 s and says "Tap to close" (only "installing" stays). Function: hcUpd.

- 01-Nov-2026 · kids v13 · kids app h9: TV REMOTE MIC (user: "when I press the remote mic and answer it is not taken"). The remote's mic
  button goes to Google Assistant; the app now opens the remote's microphone itself during TV practice (tvListen: listens again after
  silence for 60 s, number keys shown at the same time, first answer wins) and h9 catches the search / voice / assistant key when the
  TV passes it on (hcMicKey). Every try is logged ("TV mic heard … N of M tries") to learn what this TV supports. Functions: tvListen, hcMicKey, useKeys.

- 01-Nov-2026 · kids v12 · parent v12 · core v8: update messages (log: old apps h5 / h6 said "installs after the class" with no class
  on, and downloaded again every few seconds; Android's first "Update?" tap was missed). "ready" now says press HOME once (old app) or
  "after this class" only when one runs; the one-tap message says what window to press; "downloading" shows once per 10 min and the
  APK check is remembered across reloads (hc_apkask). Functions: C.watchUpdate, hcUpd.

- 01-Nov-2026 · kids screen v11 · parent app v11 · core v7: (1) TABLES AS THE KIDS SAY THEM (user: "two one ja two", "2 too ja four" not
  understood): C.tableOne / tableJudge - ja / za / is / are / into / ones, sound-alikes, Google's joined digits ("212", "21 ja 2"), all 5
  guesses (another guess counts only when the best one had no number); every heard phrase goes to the 🩺 log. 18 test phrases pass.
  (2) TV: ▶ starts the class on the kids phone (startOnPhone -> cmd for that device) and the TV shows the live board; "✍️ practise here
  with the remote" kept. (3) A table is finished after 1 perfect mixed round (parent Settings: 1 or 2, cfg.rounds). (4) FIX 🏠 Home on
  the "Well done" screen did nothing (no action; only the 25 s timer) - user's TV photo. Functions: askTable, learnFact, startOnPhone, rounds, dHome.

- 01-Nov-2026 · kids screen v10 · parent app v10 · core v6 · kids app h8 · parent app p3: APP UPDATES INSTALL AT ONCE (user: "why
  after the class - update it immediately"). Only a running class waits; otherwise the new APK installs straight away. The kids app
  reopens by itself when "Display over other apps" is on (Vihaan's phone had it OFF - the home screen now shows a ⚠️ card with
  "Turn it on"), else and in the parent app a "✅ updated - tap to open" notification. Messages say exactly what happens.
  Functions: Upd.check / installReady / doneNote, BootRx, HCA.canOverlay / openOverlay, hcUpd texts.

- 01-Nov-2026 · kids screen v9 · parent app v9 · kids app h7: 🔊 SPEAKER PAGE = the staff widget's Google Home options (user: "Google
  Home is very slow; the staff app has slow / fast - it is one package"). Mode Auto / Always Google Home / Phone, speed Slower 0.85 /
  Normal / Faster 1.2 / Fastest 1.4, Google Home volume during class (put back after), words on TV, Test (shows how long the speaker
  took), Stop. Warm-up: the speaker is connected when a class starts / the call begins, so the first sentence no longer waits
  3-5 s (log: "speaker ready in N ms"); kept 5 min idle. Parent ⚙️ → Devices → 🔊 changes it from the phone (devcfg/<id>, polled 45 s).
  Data: devcfg/<dev>, dev/<id>.spkCfg / spks. Functions: Cast.warm / setVol / autoFind / rate, openSpk, setSpk, onDevCfg, spkPanel.

- 01-Nov-2026 · kids screen v8 · parent app v8 · kids app h6: 🔊 GOOGLE HOME OVER WI-FI (user: "connect the Google Home by Wi-Fi,
  not Bluetooth, like my staff app"). Kids ⚙️ → 🔊 Speaker: 📱 This phone / Bluetooth, or 🏠 Google Home (finds the speakers on the
  Wi-Fi, pick one, it says hello). h6 Cast.java = the staff widget's tested Cast code with one connection kept for the whole class;
  any failure -> the phone's own voice + 🩺 log line + one toast. The phone still listens. Device list (parent) shows the speaker.
  Data: dev/<id>.spk. Functions: Cast.say / open / play / discover, HCA.findSpeakers / setSpeaker / speaker, drawSpk, hcSpeakers, hcSpkErr.

- 01-Nov-2026 · kids screen v7 · parent app v7 · core v5: FIX kids home screen crash (user: Back does nothing on Vihaan's phone; its
  log showed it never checked in after 3:41 pm). Firebase stores prog/<kid>/t {"1":..} as a list [null, {..}]; drawHome read
  .st of the null and start() stopped before the heartbeat, live listeners and the log. C.normProg turns it back into an object
  everywhere (kids loadProg / loadProgAll, parent report); drawHome and start are guarded (error -> 🩺 log, never a dead screen);
  the log and the self-updater start first. Found with the real family data (read-only test). Functions: C.normProg, drawHome, start.

- 01-Nov-2026 · kids screen v6 · parent app v6 · core v4 · kids app h5: 🩺 LOG for every device (user: "read the log from TV,
  child and parent apps"). Pages write short lines (open, versions, live-stream drops, every Start / Call and why it was or was
  not run, class start / end, mic / voice problems, updates, JS errors) to DB3 homeclass/<fam>/diag/<dev>/<day> in batches
  (max 800 lines / device / day, kept 14 days, C.diagClean); h5 adds the Android side ("📱": permissions, listener, alarm,
  update). Parent: Settings → 🩺 Diagnostics (today / yesterday, 📋 Copy). Found with the first look: 3 families (TV in its own);
  `homeclass/<old>/moved` = main key makes a device join the main family by itself (C.checkMoved); "Start our Home Class" now
  asks first. Functions: C.diag / diagFlush / diagStart / diagClean / checkMoved, onCmd, diagShow, NLog.

- 01-Nov-2026 · kids screen v5 · parent app v5 · kids app h4: FIX ▶ Start now / 📣 Call did nothing on Vihaan's phone (user's
  screenshot: phone online, "No kids device answered"). With the app in the background or the screen off Android pauses the page.
  h4 adds a small foreground service (Listen) with one live stream on DB3 homeclass/<fam>/cmd that opens the app for a fresh
  start / call; the page runs it (page -> HCA.setFam). Parent waits 25 s and says exactly what to do (old app / no device set to
  start classes / no internet). Cost: one open stream per kids phone, bytes per command. Functions: Listen, famToApp, sendCmd.

- 01-Nov-2026 · kids screen v4 · parent app v4 · core v3 · kids app h3 · parent app p2: AUTO-UPDATE you can see (user: "as soon as
  you update it should update by itself, refresh takes it at once, show what is updating"). homeclass-ver.json (kid / par / kidApk /
  parApk + news) is checked every minute and when the app comes back; a newer page shows "🆕 Updating vX → vY" with the news and
  reloads (?v= so no cache serves the old copy; never during a class or while a lesson is typed; one try per version per 10 min);
  after it, "✅ Updated" with the news. A newer APK downloads at once and the steps show (📥 / 📦 / 👆 / ✅); kids phone installs
  at once and reopens, parent app installs when you leave it. Tap the 🟢 chip or ⟳ Check for updates to check now.
  Functions: C.watchUpdate, upCard, hcUpd, Upd.install / installReady, MainActivity.say.

- 01-Nov-2026 · kids screen v3 · parent app v3 · core v2: FIX "Add a device" stuck on "Making a code…" in the Android parent app
  (user's screenshot). The parent page kept 6 live streams open and Android's WebView allows only 6 connections to one server, so
  every other request waited for ever. Now at most 3 live streams (C.listen); cfg / dev / sets are checked every 15-60 s
  (C.poll, only while visible). A newly linked device shows at once ("✅ Google TV linked!"); a code that cannot be made says so
  after 15 s. Checked with the real DB3: code made, TV linked, parent saw it. Functions: C.listen, C.poll, makeCode, boot.

- 01-Nov-2026 · parent app v2 · Home Class Parents APK p1: the parent app as an Android app (user asked). HomeClassParents.apk +
  homeclass-parent-version.json (self-update); source davan-scraper widgets/homeclass-parent, same key as the kids app. In the app,
  🔊 Hear the first one and 🎤 Speak to type use the phone's own voice / Google speech dialog (window.HCP); Back goes editor ->
  lessons -> home. Settings → Family shows the APK link. Functions: addSpoken, hcDictated, hcBack, eTry.

- 01-Nov-2026 · kids screen v2 · kids app h2 (APK 2): 📋 table board (user: "TV should show the table and move as he says").
  The whole table is on the phone and big on the TV: the row being asked glows, turns green when right, orange with the answer
  when wrong, green with an orange edge once fixed; learning shows each row as it is taught. Oral questions show the key words
  lighting up as they are said; spellings show the letters one by one (green / orange). The child's words appear live while he
  speaks (h2: SpeechRecognizer partial results -> hcPartial). Data: live/<kid> gets `board` + `p` (partial words, at most 2
  writes a second while speaking). DB3 rules job run (homeclass/, hcPairs) - checked: root locked, family path open, news untouched.
  Functions: boardHTML, drawBoard, onPartial, bTable / bSet / bCur, drawWatch, setLive.

- 01-Nov-2026 · kids screen v1 · parent app v1 · kids app h1 (APK 1): first build. Kids app for the phone next to the Google Home
  and the Google TV (voice classes: tables learn step by step / quick revision, oral questions, spellings, correction + repeat,
  stars, class-time call, parent Start / Call / Stop, TV live view + remote keypad), parent app (live class, today, lessons
  editor with speak-to-type, 2-week report with every answer, settings per child, devices + 6-digit pairing, install steps).
  Data DB3 homeclass/<familyKey> + hcpair/ (needs the "DB3 rules - Home Class" workflow in davan-student-news). See HOMECLASS.md.
