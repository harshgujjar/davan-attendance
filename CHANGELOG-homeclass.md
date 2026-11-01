# Gujjar Home Class - changelog (newest first)

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
