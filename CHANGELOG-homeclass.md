# Gujjar Home Class - changelog (newest first)

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
