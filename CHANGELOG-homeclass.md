# Gujjar Home Class - changelog (newest first)

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
