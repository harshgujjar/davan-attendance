# Gujjar Home Class - changelog (newest first)

- 17-Nov-2026 · kids v119 (user: smart pace "not working", log 12:16): v118 trusted the spoken line numbers, but the phone heard "thirteen two" for 3 and "four" for 5 - the right answers (39, 52, 65) were lost. Now the answers are matched IN ORDER whatever line numbers were heard: 2+ answers in one clip (or this line's own answer) count, the app skips those lines; one wrong answer never credits the next line. Tested on the real 12:16 clip: lines 3 and 4 counted. Data: none. Function: `followLine`.

- 17-Nov-2026 · kids v118 (user: "if I say the table fast it is not taken, I have to go with the app's pace"): SMART PACE - reciting a table line by line (follow-along) now reads a clip that holds several lines ("13 2 ja 26, 13 3 ja 39") with the table parser: every line said right turns green (the current one too, even when the clip ends with the next line), lines already heard are skipped, and the mic listens for this line + the next two. One line per clip works as before; a wrong or unheard line is still asked again. Tested on the real functions: 10 lines in 3 clips, no re-asks. Data: none. Functions: `followLine`, `followTable`.

- 17-Nov-2026 · kids v117 · core v48 (user, Vihaan's 13 table, log 11:13-11:14): (1) practising with answers shown ended with "Perfect! Now try it without looking: the test." and the class stopped ("Well done Vihaan") - it now goes straight into the test (`practice0`). (2) 13 x 9: the phone heard "one one seven" (117 said as digits) and marked it wrong - an answer of 100+ said as single digits now counts (`tableJudge`). Data: none, no extra reads / writes.

- 17-Nov-2026 · kids v116 · parent v83 · HC Admin v16 (user: "build it like the staff app, below - above About & rules, not on the front"): the 🔐 Permissions card is always there in ⚙️ Settings (parent: just above ℹ️ About & rules; children's screen: above 🆘 Report a problem; HC Admin: Settings) - green "Permissions · all 5 done ✅" folded (tap to see / fold the list), orange and open with ❌ lines when one is missing; no longer on the Home screens (the old "turn on Display over other apps" hint on the children's Home stays). permCard, admPermCard.

- 17-Nov-2026 · kids v115 · parent v82 (user: "change Parent / Both / Child after the first choice"; "reopen where I was last"): ⚙️ Settings (parent screens and the children's screen in the one app) → "📱 This phone is for": 👨‍👩‍👧 Parent / 🏠 Both / 🧒 Child (chosen one green; Both / Child need the family PIN - set it first if missing). The app remembers the screen used last (hc_last): a parent phone reopens on the children's screen when that was last; a child / both phone reopens on the parent screens when they were last - with a PIN it asks the PIN first (Cancel = children's screen). TV always the children's screen. extract.js start(); parent data-r3, bKids; kids data-r4, drawRole4.

- 17-Nov-2026 · kids v114 (user screenshot: "Speak when the app opens" button empty - on or off?): the switch was drawn by a wrapper that the settings button replaced, so it stayed blank; now drawn when ⚙️ Settings opens - green "✅ ON" / yellow "OFF". drawKWel.

- 17-Nov-2026 · kids v113 · parent v81 (user: "3 separate buttons - tables, spelling, questions"): parent ⚙️ Settings → 👁 Hold to see has three green ON / yellow OFF switches (cfg/peekT, peekS, peekQ; the earlier single switch counts as all three); 💬 Questions now also have 👁 Hold to see (shows the answer). peekOn(k), askOral; parent data-pk switches.

- 17-Nov-2026 · kids v112 · parent v80 (Gujjar log 22:16: "bones" spelt right but the word was not seen; user: "hold-to-see icon for spellings and tables, parents can switch it off"): (1) a word spelt right now shows big and green (✅ BONES) until the next word. (2) 👁 Hold to see on the children's screen during a hidden spelling word or a table: while held it shows the word / the whole table with answers, let go = hidden; each peek is counted (days/<date>/<kid>/peeks) and said in the parent summary ("She peeked twice"). (3) Parent ⚙️ Settings → "👁 Hold to see button for children" (green ON default / yellow OFF = hidden; cfg/peekBtn). Not on the TV yet. peekSet, askSpell, askTable, followTable; parent sPeek, kidSay.

- 17-Nov-2026 · kids v111 (user screenshot: "Spell the word: BONES" still written under "Listen and spell"): the spoken sentence shown on screen wrote the word in capitals; in a 🙈 hidden lesson it now shows "🔊 _ _ _ _ _" until the word is spelt right / answered (👀 lessons still show it). say().

- 17-Nov-2026 · kids v110 · parent v79 (user: "spelling is missing in the welcome / refresh / per-child summary - use it when assigned, not when not"): every summary (welcome, 🔄, family banner, child photo on both screens, 📋 Today) adds each lesson ASSIGNED to the child today: "Spelling · Evs: 5 of 7 right" when done, "Spelling · Evs: not done yet" when not; a child with no lesson gets no lesson words. lesSay, kidSay, kidSum.

- 17-Nov-2026 · kids v109 · parent v78 (user: "show the spelling word or not - per lesson"): ✏️ Spelling lesson editor → "👀 Show the word on the child's screen" (off by default = a test: the children's screen says "✏️ Listen and spell" with empty letter boxes and shows the word only when it is spelt right or the answer is given; on = learning: "✏️ BONES" from the start). The Lessons list says "👀 word shown" / "🙈 word hidden"; the parent's live card always shows the word. Data: sets/<id>/show. askSpell, askSpellG, runSet; parent eShow, drawLessons. "Stop class did not stop": the Stop is a saved change and that phone's saving was stuck - fixed by core v47.

- 17-Nov-2026 · parent v77 (user: "we fixed Aaryan but the welcome says Aryan"): every voice on the parent screens (welcome summary, family / child taps, 🔊 Hear it) now uses each child's "How to say the name" like the children's screen does (C.sayName in hearHere).

- 17-Nov-2026 · core v47 · kids v108 · parent v76 (user: "sync still stuck, never Live"; "Stop button missing, sometimes on refresh - make it a rule"): (1) every save now gives up after 20 s and is tried again (AbortController), and the save queue can never stay "busy" for more than a minute - a save that never got an answer held every later save (and the phones' logs) for ever; a test write to DB3 worked, so the database was fine. (2) The ⏹ Stop button now stays until the voice really ends (parent: HCA hcSpoke callback for the summary id; child: rawSay done) - before it vanished after a fixed time. Rule added to CLAUDE.md: every spoken summary has ⏹ Stop. C.flush, send, saySummary, hcSpoke, speakKid.

- 16-Nov-2026 · kids v107: tapping a child's picture writes a log line at once ("🔊 picture tapped: name · voice · speaker phone / Google Home") - the child-screen tap at 21:01 left no trace, so the next tap shows where it stops. Checked in a browser: the tap speaks the child's summary.

- 16-Nov-2026 · kids v106 · parent v75 · core v46 (user: "⏳ still not Live", "no voice on the child's screen when I touch the picture", "child setting on/off like the parents"): (1) a saved change that keeps failing (5 tries) is dropped and logged, and waiting changes are sent every 30 s and 3 s after opening - the parent phone's queue (5 waiting since 20:41, which also held back its log) clears by itself. (2) Children's screen ⚙️ Settings → "🔊 Speak when the app opens" (green ON default / yellow OFF): speaks this phone's child(ren) once per open / 🔄, never during a call or class, ⏹ Stop. (3) When the phone's own voice did not start (the Samsung's log: "engine com.google.android.tts did not start speaking") both screens now say so: "check phone Settings → Text-to-speech and the media volume". C.flush, kidWelcomeOnce, speakKid, voiceOk, saySummary.

- 16-Nov-2026 · kids v105 (user screenshot: 🔒 Parents fell to a second line): the 4 top buttons stay in ONE line - they shrink their padding and text on phones (labels hidden only below 330 px). CSS .tbar.

- 16-Nov-2026 · app h33 (user: "why are all updates 5 MB"): the offline listening engine is in the APK twice (64-bit 8.5 MB + 32-bit 7.9 MB unpacked); now each release also has HomeClass-64.apk and HomeClass-32.apk (3.3 MB each) and the app's updater downloads the one for its own phone (homeclass-version.json apk64Url / apk32Url; HomeClass.apk stays the full file for new installs and h32 and older). The h32 -> h33 update itself is still the full 6 MB; from then on about 3 MB. Upd.abiUrl, build.sh.

- 16-Nov-2026 · kids v104 · parent v74 · core v45 (user's screenshot): (1) "⏳ Saving…" never ended and pushed the top bar off the screen - a write the database refused stayed first in the save queue and blocked everything; now a refused write (400 / 401 / 403) is dropped and logged (network / server errors still retry) (C.flush); the parent top chip is "🟢 Live" / "⏳" / "🔴 Offline" (details on tap-hold). (2) Children's screen top buttons (🔄 Refresh, 🆘 Help, ⚙️ Settings, 🔒 Parents) wrap / shrink on small screens instead of running off the edge. (3) Children's screen: tap a child's picture (🔊 badge) to hear that child's last practice (grade, time, right / to practise, stars, birthday wish on the day), ⏹ Stop while speaking, nothing during a call (kidSum, sayStopBtn). One-app engine rebuilt from core v45 (judge equivalent).

- 16-Nov-2026 · parent v73 (user's photo of the new Home): the summary says "8th grade" (not "8th std"), the time as one piece ("7 41 PM" - it was read as "7 . 41 and pm"), the stars ("She got 4 stars") and "Happy birthday, <name>!" only on the child's birthday; browser voice a little faster. Family banner shows each child's picture before the name. Top chip "⏳ 2 to sync" -> "⏳ Saving…". ⚙️ Settings: 🎨 picture and colour are always shown (no fold), the chosen picture / colour is marked (bigger, ✓). gradeSay, bday, whenTxt, kidSay, famSay, drawFamHi, net.

- 16-Nov-2026 · parent v72 · kids v103 · app h32 · HC Admin v15 + app a4 (user's list): (1) 🔐 Permissions card like the staff app on the children's screen, the parent screens and HC Admin - one line per permission (install updates, notifications, microphone, opens by itself, battery; HC Admin: updates + notifications), ❌ lines open the right Android screen, the card hides itself when all are ✅ (HCA.perms / openPerm, HCADM.perms / openPerm). (2) "Classes for all children" switch: it worked (log 19:44 OFF/ON/OFF) but nothing showed it - now a green ✅ ON / yellow ⏸ OFF button and the child cards say "Classes are OFF". (3) Family name banner "🏡 Vijaya family" on the parent Home (tap = hear the family summary), 📋 Today card (one line per child + 🔊), tap a child's photo (🔊 badge) = that child's details incl. a class a few minutes ago / running now. (4) Spoken welcome summary when the app opens or 🔄 is pressed, switch "🔊 Welcome summary" in ⚙️ Settings (on by default, per phone), never during a ringing / active call (HCA.inCall), ⏹ Stop button while it speaks. Data: days/<date> of the last 7 days (7 small reads per open). Guide updated. Functions: loadRecent, kidSay, famSay, saySummary, drawFamHi, permCard.

- 16-Nov-2026 · kids v102 (Vijaya family log 19:30: 📣 Call and 🙈 Test for Mangala did nothing - "for me false": her phone has "starts classes by itself" off, so commands sent to "any phone" went to the Samsung, which had briefly been a kids' phone): a command for a child is now taken by that child's own class phone (cfg/kids/<k>/dev); phones with "starts by itself" on take it only when the child has no class phone. onCmd. The Samsung's device row is now "Parent phone (Samsung)" with "starts by itself" off (it is the parent's phone - the server keeps a row for every family phone).

- 16-Nov-2026 · kids v101 · parent v71 (user screenshot: the new parent phone showed the kids' "Name this phone" screen): app h30+ opens the one app, which treated every phone as a kids phone - now a phone that chose 👨‍👩‍👧 Parent goes straight to the parent screens; 🧒 Kids still opens the children's screen for that session (sessionStorage hc_kidsview). extract.js start(), parent bKids.

- 16-Nov-2026 · app h31 · kids v100 · parent v70 · pass client v4 · pass server (Vijaya family's new phone, screenshots + log 18:40-18:46: "pass refused: unknown_device" again and again, stuck on "Getting today's class… a parent phone is already set up"; "Paid but it says Upgrade"; "take all permissions at the beginning"): (1) pass server: a phone that joined with the family code (it holds the family key) is added to the family by itself, up to 5 devices - before, phones that joined the old way were refused for ever. (2) No pass yet -> the family's saved plan decides the screen (no plan = Paid), so a Paid family never sees "Upgrade" (homeclass-pass.js P.ent). (3) h31 asks all permissions at the first start one after another - microphone + notifications, "Display over other apps", no battery limits, "Install unknown apps" (updates) - missing ones again the next day, at most once a day, never during a class (MainActivity nextPerm). HC Admin "last seen 6 h ago" for Mangala: her phone was on the old h28 screen, which wrote "last seen" only when the app opened; now on h30+ it is current.

- 16-Nov-2026 · kids v99 · core v44 (Vijaya family, Mangala's table 12 test 16-Nov 18:12-18:18, read from her log): 12 × 5 = 60 - she said "sixty" but the offline engine heard "sixteen" (3 times), "eighteen / eighty", "sixty six" and she was marked wrong. Now the -ty / -teen twin of the answer (60 / 16, 30 / 13 … 90 / 19) counts as the answer - the twin is never itself the right answer of that line; when only another heard version is the twin, the app asks "Did you say 60?". Fixed for ALL families (old screen + one app; engine rebuilt, 13,288 judge calls equivalent). C.tableOne. Not fixed: words the engine hears as something unrelated ("ten", "one").

- 16-Nov-2026 · kids v98 + app h30 (user: "this old page comes first - it should never show"): the app h30 opens the ONE app (homeclass-app.html) directly; on h29 phones the old kids screen now jumps to the one app before drawing anything (inline check at the top of the page; hc_onapp remembers if the one app was switched off for the family / phone, then the old screen stays). h30 installs itself. hcPageSwitch, MainActivity.onCreate.

- 16-Nov-2026 · parent v69 · HC Admin v14 (user: "make it 50"): tables go up to 50 - the child's Tables from / to already took 50; the Paid plan card now says "All (1-50)" and HC Admin → Children draws up to 50 table boxes. tabKids, upgrade rows.

- 16-Nov-2026 · HC Admin v13 + app a3 (user: "HC Admin takes a lot of time to start"): the last family list shows at once from the phone (hcadm_cache), then ONE pass-server answer (/admin/overview: every family's settings, devices, delete request and 🆘 reports without voice notes) refreshes it - before, about 20 downloads one after another incl. the voice notes; voice notes load only when the 🆘 Reports tab opens. App a3 opens its saved copy of the page at once and reloads it only when hcadmin-version.json "page" is newer (raise "page" with every admin page change). Functions: load, tabRep; a3 MainActivity fresh().

- 16-Nov-2026 · kids v97 (user: "don't build old device rows, future also"): once a day a phone takes over its own OLD device row (same model, same kind, last seen before this install and over an hour ago): the child linked to the old row moves to this phone, the old dev/<id> and devcfg/<id> are removed. Two different phones of the same model stay apart. Data: homeclass/<fam>/dev, devcfg, cfg/kids/<k>/dev (1 read a day). takeOverOld.

- 16-Nov-2026 · HC Admin: version chip next to "Home Class admin" on the family list (v12). Gujjar family: 2 old device rows removed on the user's yes (old Home Class entry + old Parents app) with their logs.

- 16-Nov-2026 · HC Admin v12 + homeclass-guide.json (user: "one app - what are these 2 downloads"; "the WhatsApp message must update by itself, always ready"): Releases shows ONE download "Home Class (parents, children, TV)" + HC Admin; the old Parents app is marked retired (its APK under 📜 Older APKs). The WhatsApp message is now built live: the server template only holds the intro and support text, {guide} = the how-to steps that ship with every release (homeclass-guide.json - CLAUDE.md rule: updated in the same commit as every build that changes what a family does), {news} = the newest 5 release notes, plus links / versions; an old full text without {guide} is ignored so it can never go stale. Functions: drawRel.

- 16-Nov-2026 · parent v68 + one app (kids v96) (user: the Redmi asked to choose a new PIN although it was set on the Motorola; "go build family PIN"): ONE parent PIN for the family, kept in the family settings (cfg/pin {h = SHA-256 of family key + PIN, p}); 🔒 Parents on every phone asks that PIN (never "choose a PIN" when the family has one); parent ⚙️ Settings → "🔒 Family parent PIN" set / change / remove / 👁 Show, changes reach every phone; a PIN made on one phone before is moved into the family the first time it is typed. Removed the kids ⚙️ Settings box "This is also the parent's phone" (🔒 Parents at the top does it). Data: homeclass/<fam>/cfg/pin. extract.js famPin, famPinHash, famPinSave, hasPin, pinAsk; parent drawPin, pinForm.

- 16-Nov-2026 · parent v67 (user: "show present PIN"): parent ⚙️ Settings → 🔒 Parent PIN shows the PIN behind 👁 Show (this phone keeps a readable copy, hc_pin_show, next to the hash; a PIN set before this update shows "change it once to see it here"). The one app's PIN screen also keeps that copy (extract.js). drawPin, pinForm.

- 16-Nov-2026 · parent v66 (user: "🔊 Hear the first one in spelling is not working"; "parents' settings show nothing, no option to change the PIN"): inside the ONE app the parent screens now use that app's own voice (HCA.speak) for 🔊 Hear the first one and every other "hear it" (an Android WebView has no speech voice of its own), and 🎤 Speak to type listens through the app (HCA.listen with Google speech). Parent ⚙️ Settings → "🔒 Parent PIN on this phone": shows on / no PIN, 🔒 Set a PIN, 🔁 Change PIN (asks the current PIN), Remove PIN - the same PIN the kids screen's 🔒 Parents asks for. Functions: hearHere, hcaVoice, eTry / eMic handlers, drawPin, pinForm, pinHash2.

- 16-Nov-2026 · kids v95 · parent v65 (user screenshot: "still it says Evs - we have two: Spellings and Questions"; "from parents how to go back to the child"): every lesson is shown by its KIND first - "✏️ Spelling · Evs" / "💬 Questions · Evs" (DECISIONS: the title is only the subject the parent typed) on the parent Lessons list and Home buttons, the start toast, the kids Home buttons, the class tag, the call screen, the spelling menu / book, live watch and the report results; the 💬 icon replaces the old 🗣️ for Questions; editor field renamed "Subject / title". Parent screens inside the ONE app: 🧒 Kids button at the top → back to the children's screen. Functions: setLabel (kids + parent), setIcon, drawLessons; extract.js UI patch.

- 16-Nov-2026 · kids v94 (user's Motorola log 16-Nov 07:49-07:52: his own phone already had Home Class, so the one app asked "Who will learn on this phone?" and he picked Aryan; screenshots): (1) 🔒 Parents is ALWAYS at the top on phones (not TV) - the first tap sets a parent PIN and opens the parent screens at once; later taps ask the PIN. (2) "Who will learn" form: 🔊 Hear it (or any live update of the family / device list) no longer wipes what was typed - only the chips redraw while the form is being filled. (3) Save with something missing: the field turns red and the message stays in the form ("Tap 👦 Boy or 👧 Girl", "🎂 Choose the date of birth"), not only a short toast; same in ⚙️ Settings → children. Functions: drawWho, kfBad, kidFormRead; extract.js (bPar always, parAfterPin).

- 16-Nov-2026 · kids v93 (one app; user: "installed it, it did not ask parent / join" - his Motorola is already the family's KIDS phone, so the app went straight to the kids screen): ⚙️ Settings → "👨‍👩‍👧 This is also the parent's phone" → choose a 4-digit PIN → a 🔒 Parents button at the top opens the parent screens of the same family (no join, no code); ⚙️ Settings is then behind the PIN too; on a TV the option is hidden. Pass server: a linked kids phone may become role "shared" (dev/<id>/role; never plain "parent"). Opening the parent part writes pmove/<model>, so the old Parents app on the same phone turns green (🗑 Remove this old app). extract.js (sShareBox, drawShare, pinSave goes home when linked).

- 16-Nov-2026 · parent v64 + Parents app p4 (the LAST old Parents APK; user: "build the remove old app button"): when the parent has opened the family in the NEW Home Class app on the same phone (it writes homeclass/<fam>/pmove/<phone model>), the old Parents app's card turns into "✅ You moved to the new Home Class app" with 🗑 Remove this old app → Android's own uninstall screen (HCP.uninstall, REQUEST_DELETE_PACKAGES; the parent taps OK - Android allows no silent removal). Before moving: a small "Already moved? Remove this old app" link. p2 / p3 phones update to p4 by themselves; older ones get a how-to instead of the button. Functions: drawMove, moveKey, boot.

- 16-Nov-2026 · ONE APP FOR EVERYONE (user: "switch on all families once for all, one install link, retire the old parents app, keep the data per family"): homeclass-ver.json app110.all = true - every phone on app h29+ opens the one app (homeclass-app.html); kids v92: a brand-new phone with no family also opens it (role screen: 👨‍👩‍👧 Parent / 🧒 Child / 🏠 Shared phone, TV found by itself). Parent v63: inside the OLD Parents app (p3) a "📲 Home Class is now ONE app" card on Home - install Home Class → Parent → Join → the family code; nothing moves, the family, children, progress and lessons stay with the family key; the old app keeps working until they move (no new Parents APK any more). WhatsApp message (HC Admin → Releases) = one install link. HC Admin v11: family → 🧾 Log day picker (today … 7 days back), family → 🔧 Fixes (this family + all families; pass server /admin/fixes, KV fix:*). Functions: hcPageSwitch, drawMove, tabLog, tabFix.

- 16-Nov-2026 · On the user's yes: the two old unnamed test families (…bWYL, …RgoM - Aryan / Vihaan copies from the first days) were removed from DB3 for ever by the new davan-student-news Action "DB3 remove Home Class family" (copy kept 90 days as the run's artifact), and their keys are blocked in the DB3 rules (no read / no write), so an old phone can never re-create them. The Gujjar family is untouched. No app change.

- 16-Nov-2026 · HC Admin v10: 🚀 Releases → 📥 install buttons for the newest Class app / Parents app / HC Admin APKs; 💬 WhatsApp message that is always live (links and versions fill in by themselves from the version files; ✏️ edit and save it in the app - kept on the pass server, never in a repo, so a phone number in it stays out of GitHub); 📤 Send on WhatsApp / 📋 Copy / ↗ Share; 📜 every older APK from GitHub's history (newest 5, rest behind Show older); 🔗 all links with 📋. Data: pass server /admin/texts (KV text:invite + last 5 versions). Functions: drawRel, oldApks.

- 16-Nov-2026 · kids v91 · parent v62 · core v43 (Vijaya family, Mangala's phone, table 8 test on 15-Nov - read from her phone's log): (1) 8 × 2: she said "sixteen" and noise followed ("sixteen … one", "sixteen twenty six ten") - marked wrong as 1 / 10 twice although the right answer came first; now the right answer said first is right (a changed answer with words like "no" is still judged by the last number). (2) Saying the table line by line: the app moved on to 8 × 4 while she was still saying "eight three ja twenty four" - marked wrong; now a line that names the previous line with its right answer is not wrong, the app asks again. C.tableOne. The one-app engine is rebuilt from core v43 (homeclass-core-app.js, homeclass-app.html, engine on the pass server); 13,288 judge calls equivalent.

- 16-Nov-2026 · HC Admin v8 (user: "duplicate families"): families with no family name and no phone seen for 14+ days (early test copies, e.g. Family …bWYL, …RgoM) are grouped under "💤 Old / unused families (n)", tap to show; counts at the top are the real families only. Nothing deleted. Function: drawList.

- 15-Nov-2026 · HC Admin v7: 🚀 Releases showed "[object Object]…" (the family news is a list of {k, v, at, t}); now a "📜 What the families were told" card lists the newest 8 with kids / parent / app version and date. Function: newsList, drawRel.

- 15-Nov-2026 · HC Admin v6 (user: the app asked for a login link he no longer has; "u don't collect log from admin"): the admin key alone opens everything - the family list now comes from the pass server (/admin/families) instead of the encrypted registry + #d= link (kept as a fallback); first screen says "paste your admin key" with ⚙️ Open Settings. The page sends its own log (steps, server answers, JS errors + the Android app's log) to the pass server /applog (KV applog:<phone>, 30 days, at most once a minute, errors at once) - Claude reads it with /admin/applogs. Functions: load, LG, sendLog, api.

- 15-Nov-2026 · HC Admin app a2 (fix: the user's phone showed an all-white screen): "⏳ Opening HC Admin…" at once; if the page does not open in 20 s, fails, or stays empty, a page says why with ⟳ Try again, Open in Chrome and the app's log (📋 Copy); redirects stay inside the app; a crashed page renderer reopens the app. a1 updates itself to a2 (first update: one tap).

- 15-Nov-2026 · HC Admin Android app a1 (HCAdmin.apk + hcadmin-version.json, app id com.gujjar.hcadmin, Home Class key) + admin page v5: the admin screens open in their own app with the HC Admin icon; paste the login link once in ⚙️ Settings; 📋 Copy and 📤 Send go through the app; the app updates itself (every 6 h, silent on Android 12+ after the first update); no internet -> "📡 Try again". Web version: ⚙️ Settings → ⬇️ Get HC Admin for Android. Functions: copy (HCADM bridge), hcAppUpd, drawSet.

- 15-Nov-2026 · HC Admin v4: all 7 pages of the approved Admin V6 bar - 👪 Families · 🩺 Doctor (auto-doctor: checks every family once an hour by itself - open reports, delete requests, old screens, silent voice, no microphone, quiet families, paused; rules on/off; ▶ Run now; runs at once when the last run is over an hour old) · 🚀 Releases (live versions, which families use the one app) · 💳 Billing (rate card, ₹ 0 while all Paid are tests, Paid / Free / gift counts, per family, 🎟 promo codes: make, on/off) · 🛡️ Security · 🔔 Alerts (one per NEW problem, red number on the bar, tap opens the family) · ⚙️ Settings (+ paste a login link once, for the HC Admin Android app). Data: pass server /admin/doctor*, /admin/alerts (KV doc:*, alerts - written only when something changes, so the free daily writes last); DB3 read by the server once an hour per family (cfg, dev, reports, delreq). Hourly run = davan-scraper Action "Home Class doctor" (Cloudflare free cron slots are all used).

- 15-Nov-2026 · one app switched ON for the Gujjar family only (homeclass-ver.json app110.fams = its hash, after its parent phone checked in with the pass server): its h29 phones / TV open homeclass-app.html by themselves; every other family stays on today's screen. Switch back = empty the list.

- 15-Nov-2026 · HC Admin v3 (homeclass-admin.html, the separate admin app): bottom bar 👪 Families · 🛡️ Security · ⚙️ Settings. Per family: 💳 Plan (Free / Paid switch, 🎁 gifts with days + why, end early), 🔐 Controls (⏸ pause - class stops at once, 🔒 no new phones, 🗑 parent's delete request: approve = stopped and kept 30 days, restore, remove for ever only after 30 days with the typed name), 📱 block / unblock a phone. 🛡️ Security = the pass server's 30-day log with family names and who did each admin action, plus the stop-all-new-phones switch. ⚙️ Settings: admin key kept on this phone; the owner adds a second admin (her own login link, removable). Data: pass server /admin/* (Cloudflare KV + DB3 homeclass/<fam>/cfg plan, grants, susp, del; delreq; dev/<id>/blocked); no new reads for families. Pairs with pass server 15-Nov (admin endpoints), parent v61.

- 15-Nov-2026 · kids app h29 (HomeClass.apk, installs itself, same key as h28): can open the coming one app (homeclass-app.html + homeclass-core-app.js + homeclass-pass.js) and the parent screens (homeclass.html) for the Parent role; offline copies inside the APK. The kids screen still opens first - a phone switches only when homeclass-ver.json app110 lists its family / device. Source + H29_CHANGES.md in davan-scraper widgets/homeclass (MainActivity FILES, build.sh assets, BuildInfo / manifest 29). Google backup comes in the next APK (needs the user's Google sign-in key).

- 15-Nov-2026 · kids v90 (no visible change): knows how to switch this phone to the coming one app (homeclass-app.html) and back, decided in DATA - homeclass-ver.json app110 {all, fams (SHA-256 of the family key, first 22 chars, the same value the pass server logs), devs}; only inside the Android app h29+ (which can open the new files), never during a class, checked 4 s after start and every 15 min. Today app110 is empty, so nothing switches. Function: hcPageSwitch. homeclass-app.html / homeclass-core-app.js rebuilt from v90 (same check, so turning a family off brings it back).

- 15-Nov-2026 · parent v61: ⚙️ Settings → ℹ️ About & rules (Home Class - the 2nd parent at home, version, Built by Gujjar & Company, support email, 🔒 Privacy Policy / 📜 Terms / ❓ Help on the website) and 🗑 Delete my family and data (lists exactly what goes, type the family name, request kept 30 days with Cancel; Gujjar & Company approves in the admin app). Lesson types renamed 💬 Questions / ✏️ Spelling. Data: DB3 homeclass/<fam>/delreq. Functions: drawAbout, delForm, delete click handler, page. homeclass-app.html: About line with Privacy / Terms / Help in the device settings.

- 15-Nov-2026 · parent v60: 📣 call status on Home ("📞 ringing…", then "✅ said ready" or "❌ missed - did not answer"); 🤝 Invite a family card in Settings (own code, WhatsApp share, families joined / months earned; both get 1 month after the invited family's first class). Free families only (none today - existing families are Paid): 🆓 plan card, 📚 choose any 5 free tables, ⭐ Upgrade page (₹99 / month or ₹799 / year, 7-day trial, 🎟 code), 🎁 free sample of 4 spellings + 4 questions locked after saving (no edit / switch / delete), lessons behind Paid; 🎁 gift card with "ends in N days". Data: cfg/kids/<id>/free5, sets/sample_spell + sample_oral, codes + invites on the pass server. Functions: drawPlan, callChip, upgrade, freeTables, sampleForm, drawInvite, ov click, drawLessons / lesson guards, sendCmd. homeclass-pass.js?v=3: useCode, invite, inviteUse, inviteDone. homeclass-app.html: the child's phone reloads by itself when the plan changes (hcPlanCheck) and shows "🎉 Paid unlocked" / "Back to Free"; engine reports the first finished class for invites.

- 15-Nov-2026 · homeclass-app.html (coming one app, NOT used by the live APK yet): Free plan on the child's screens - 🔒 on tables outside the parent's 5 (home card, Practise-a-table picker, class picker), the 2nd child's card locked ("More children need the Paid plan - ask a parent", no Start button), 🔒 on lessons that are not the free sample, "· Free" next to the version. The engine (from the pass server) enforces the same rules. Functions: uiEnt, uiOk, uiKidOk, uiSetOk, drawHome2 / table pickers (app page). No live change.

- 15-Nov-2026 · homeclass-app.html (coming one app, NOT used by the live APK yet): "Who uses this phone?" - 👨‍👩‍👧 Parent (opens the parent screens), 🧒 Child (links with the code), 🏠 Shared phone (4-digit parent PIN, saved as a hash; ⚙️ Settings and 🔒 Parents need the PIN); a TV is found by itself and links as a TV. Linking text now says the code is on the parent Home page, then ✓ Allow. Functions: roleScreen, pinSetScreen, pinAsk, pinHash, start (app page). No live change.

- 15-Nov-2026 · homeclass-app.html (coming one app, NOT used by the live APK yet): linking a new phone now goes through the pass server - code -> "⏳ Waiting for your parent… tap ✓ Allow" -> engine -> class home; wrong code shows "Wrong code (n of 5 tries)", Deny shows "Your parent did not allow this phone". Function: tryPair (app page only). No live change.

- 15-Nov-2026 · parent v59: 📱 "<phone> wants to join your family" card with ✓ Allow / ✕ Deny on the parent Home (shows only when a phone of the coming one app types the family code - today's kids app still links the old way), 5-device limit shown; the parent phone gets its own pass from the pass server (first parent phone of the family registers itself) and parent phones are kept out of the kids-device lists. Data: DB3 homeclass/<fam>/joinreq (read), dev/<parent phone> (written once by the server). Functions: drawJoin, hJoin click, dev listener, boot (HCPass.setRole / renew). Loads homeclass-pass.js?v=2.

- 15-Nov-2026 · NEW homeclass-app.html + homeclass-core-app.js (the coming one app, NGP 1.10 - NOT used by the live apps yet, the APK still opens homeclass-kid.html): the class teacher (40 class functions + 41 judge pieces, byte-identical to v89 / core v42) is no longer in these files - it comes from the pass server for a valid pass (homeclass-pass.js, kept as a saved copy for offline days); a modded copy gets "not genuine" and no class. Proven equal to today's app (same questions, log lines and data writes). homeclass-pass.js: fixed - it now finds the core (window.HCcore). No live change, no data change.

- 15-Nov-2026 · homeclass-pass.js (NEW, not loaded by the live app yet - wired in at stage 1e): the app side of the pass server homeclass-pass.harshgujjar.workers.dev - join a family with the code + the parent's Allow / Deny (HCPass.join / waitAllow / answer), signed pass 2 days + 3 offline days (ensure / renew), Free / Paid / gifts (ent / paid / tableOk), family code made by the server (code), class engine only for a valid pass with an offline copy (engine / runEngine). No live change, no data change. Plan + tests: davan-scraper homeclass-play (BUILD-PLAN.md, server/client-test.mjs).

- 09-Nov-2026 · kids v89 · parent v58 (Vijaya photos 14:57-14:59: "two phones of two different children both show the same child; a change on one changes the other"): log - Mangala was saved as a child on her phone at 14:52:41, then vanished: the parent app wrote the WHOLE family settings (C.put cfg) from its own older copy on every change (e.g. the Classes switch), wiping a child added on a kids phone; so both phones showed the only child left, Harsha. Parent now writes only what changed (cfg/kids/<id> fields, cfg/<field>, DELETE for a removed child). Kids phones show the children whose class phone they are (myKids; a phone with none, and the TV, show all); ⚙️ Settings lists the phone's own child first and "Other children (on other phones)" folded. Mangala restored from the log (8th std, girl, 25-12-2009, her phone). Functions: saveKid, kAdd, data-rm, sPause, sFam, sAns / sCnt / sJoin / sRounds / sUpto (parent); myKids, drawHome2, drawKidsMe (kids).

- 09-Nov-2026 · kids v88 · parent v57 (Vijaya photo 13:47: "I added a new child Mangala but it shows Harsha (already on another phone); show the details with the name, not a separate click; make it mandatory; add boy or girl; Settings should show all details directly - neat"): "Mangala" had been typed in the separate "Name this phone" step, so it became the PHONE's name, not a child. Now a kids phone shows ONE screen after linking: chips of the children (each with the phone it is on, "· on Harsha Gujjar") + ➕ New child, and the details form right below - name, class, 👦 boy / 👧 girl, 🎂 date of birth (all required) and how the app says the name with 🔊 Hear it; ✓ Save makes / updates the child, makes this phone their class phone and names the phone "<child>'s phone" (no separate naming step; the TV keeps "name this phone"). ⚙️ Settings shows every child's form directly with its own ✓ Save, and ➕ Add a child. Parent: gender per child; the add-child form needs class, boy / girl and date of birth (no preset class). The who screen redraws when the family settings change. Tested at 360 px (empty submit -> asks for the name; new child saved + phone named; Settings forms). Functions: kidFormHTML, kidFormRead, kidSave, drawWho, openWho, whoSave, drawKidsMe (kids); drawSettings, kAdd (parent).

- 09-Nov-2026 · parent v56 (user: "show the code on top until the first child is added, then a small line under Kids devices pointing to Settings"): Home shows the big "📲 Link a kids phone" code card only while the family has no child; with a child it shows a small line under Kids devices: "📲 Family code ... - to add more phones or a TV, see ⚙️ Settings → Devices" (the big card returns if every child is removed). The top bar keeps "Home Class v56 · p3" on one line (smaller tag, 19 px title on narrow phones - checked at 360 px, no sideways scroll). Functions: drawFamCode, drawHome, CSS.

- 09-Nov-2026 · kids v87 · parent v55 (user: "on top also add the h number and the p number"): the version tag shows the screen version + the Android app version ("v87 · h28" on the kids app, "v55 · p3" in the parent Android app; the parent web page shows only v55). Functions: drawHome2 (kids), tVer (parent).

- 09-Nov-2026 · parent v54 · kids v86 (Vijaya photo 13:26: "the Class phone drop-down does not show the Harsha Gujjar phone"): the child cards were drawn before the phone list (dev) arrived and were never drawn again; and since v53 (the code always in the Devices card) the device list stopped refreshing (it refreshed only while the code box was empty). Now a change in the phones (added / renamed) redraws the whole Settings page when nothing is being typed, otherwise the device list refreshes. 🎂 Date of birth: max one year ago (parent field + kids details sheet) - the Vijaya family had saved today's date. Tested with the phone list arriving late. Functions: dev listener (parent), saveKid, meOpen / meSave (kids).

- 09-Nov-2026 · parent v53 · kids v85 (user: "show the version on top - no p / h numbers; keep the code visible always - why press Add a device"): the version (v53 / v85) is a small tag next to "Home Class" in both top bars; ⚙️ Settings → Devices shows the family code all the time (the ➕ Add a device button is gone). Fix found while testing: the Devices page could MAKE a code before the family settings had loaded and replace the family code - a code is now only made / renewed after the settings arrive. Functions: drawDevices, makeCode, drawFamCode, drawHome2 (kids), CSS .vtag.

- 09-Nov-2026 · parent v52 · kids v84 · core v42 (user: "one permanent family code, always visible"): the family keeps ONE 6-digit code (cfg.code, DB3 hcpair/<code> {fam, exp, perm}); every time a parent app opens it is renewed for 5 more years (the existing rule lets the same family rewrite its own code), so it never runs out; Home shows "📲 Link a kids phone, TV or the other parent's phone" with the code and 🔁 New code (confirm; makes a fresh code, deletes the old hcpair entry - linked phones stay linked); ➕ Add a device shows the same code; the kids pairing screen says the code is on the parent Home page. Tested with the DB mocked (code shown, new code made, old one freed). Functions: C.famCode; parent showFamCode / drawFamCode / makeCode / hCodeNew.

- 09-Nov-2026 · kids v83 (user: "voice is the main rule of my app - build A and B"; Poorvika family log 12:12-12:16: the long recitation lost 5x3, 5x7, 5x10 as [unk] while 12 of 12 single questions were heard): A = FOLLOW-ALONG recitation (followTable / followLine): the board lights one line at a time, the app listens only for that line (qGrammar - the strong single-question grammar), heard = green + next line, no Start / Done button; B = a line not heard (or a different number) is asked by voice at once ("5 2 zaa?") and listened to again; if half or more are still missing, one more pass over those lines. All lines heard = proven: no quick check, table learnt (ro.proven); lines still missing go to the short check; too few heard -> "we will try again later". The old long recitation stays in the code (o.long) as a fallback. The TV keeps the question rounds. Log: "follow 5×3: ... → ✓", "follow 5: 9 of 10 heard · not heard 3". Tested with a mock app bridge (typed answers): all-right path (learnt, no check) and a missed line (asked again, then in the check); earlier walk-throughs re-run. Functions: followTable, followLine, reciteTable, practice0, tablesLearn.

- 09-Nov-2026 · kids v82 (user: "when the child app is linked with the parent's code it should ask the child's name, class and date of birth - once added, all set"): after linking + naming the phone, a "👋 Who will learn on this phone?" screen: tap a child (details sheet to confirm) or ➕ A new child (name, class - must be chosen, no preset -, birthday, name sound, Save) - saved to cfg/kids/<id> with prof:1 and dev = this phone (its class phone); "Later" skips; asked once (hc_who); phones linked before v82 are asked once if no child has details yet; not on the TV. ⚙️ Settings → Children's details also has ➕ New child. Back closes the sheet / skips. Checked: new family + existing child at 360 px; earlier walk-throughs (parent new family, kids report, settings details, admin) re-run. Functions: openWho, meOpen(id, who), meSave, drawKidsMe, hcBack, npSave, start2.

- 09-Nov-2026 · kids v81 (user: "My details does not belong on the home page - put it in Settings"): the ✏️ My details button and the hint chip left the child cards; ⚙️ Settings has "👦 Children's details" with one ✏️ button per child (the same sheet: name, class, birthday, name sound + 🔊 Hear it, Save). Functions: drawKidsMe, drawHome2, bSet.

- 09-Nov-2026 · kids v80 · parent v51 (user: option 2 + "a proper Save button, details shown on the child phone; hands-free by default; Hear it on the child phone with a change option; one click to turn all classes off (default on); the 3 top buttons in their own place; no text on the card's curve; the Gujjar family in the admin page"): kids home: ✏️ My details per child (name, class, 🎂 date of birth, how the app says the name + 🔊 Hear it, ✓ Save -> cfg/kids/<id> with prof:1; parent shows it), a hint chip until saved, 🎂 "Happy birthday" chip on the day; the top buttons are labelled pills on their own row (🔄 Refresh · 🆘 Help · ⚙️ Settings); the card circle is small and in the corner; default answer mode hands-free. Parent: 📅 "Classes for all children" ⏸ Turn all off / ▶ Turn classes on (cfg.pauseAll - kids phones start no class and ring no alarm), 🎂 Date of birth per child. Gujjar family registered in the admin list. Checked at 360 px. Functions: meOpen / meSave / bday, nextClassText, alarms, holdMode (kids); drawSettings, sPause (parent).

- 09-Nov-2026 · kids v79 · parent v50 (Vijaya family photos 10:17-10:25: "the child I added is not taken"; kids top bar "Vijaya / Home / Class" on 3 lines next to 3 big buttons; parent device row squeezed into a thin column): the child was still not saved at 10:21 (their cfg had no kids; the page saved fine when Claude added "Harsha" through the same page, so the phone's tap did not reach ➕ Add) - Enter in the name box now adds too, and every add is logged ("child added"). Kids top bar: one-line "Home Class", "<Family> family · Mon, 9 Nov" under it, smaller round buttons on phones, the spacer no longer halves the title space. Parent devices: the ✏️ 🔔 🔊 Remove buttons sit under the device text. Checked at 360 px. Functions: drawHome2 (kids), sKids keydown / kAdd (parent), CSS.

- 09-Nov-2026 · kids v78 · parent v49 · core v41 (first tester family "Vijaya", 10:05: "I added the child, it does not show; voice clips must be on for testing; zaa as default; a refresh button in both apps"): their cfg had no children - "➕ Add a child" asked the name with prompt(), which the phone's app did not show, so nothing was saved. Now an in-page form (name + class) adds the child. Testing phase: voice clips always on (new families rec: true, the switch is replaced by a note; Vijaya family set to rec true + joiner zaa); the default word is "zaa" (C.JOIN_DEF) wherever a family has not chosen. 🔄 Refresh in the kids top bar and the parent top bar: clears the page caches and loads the newest copy (C.hardRefresh). Note: the Vijaya kids phone reports mic: false (microphone permission not given). Functions: C.newFamCfg, C.hardRefresh, C.JOIN_DEF; parent drawSettings / kAdd; kids bRef, rawSay joiner.

- 09-Nov-2026 · admin page v2 (user: "the admin link clashes with the staff web app"): the admin page had no manifest of its own, so on a phone with the staff app installed the link was taken by that app. It is now its own installable app "HC Admin" (manifest-hcadmin.json, id /davan-attendance/homeclass-admin, scope = this page only; app-sw.js scoped to the page), per the PWA rule. Functions: none (manifest + worker registration).

- 09-Nov-2026 · kids v77 · parent v48 · core v40 · admin page v1 (user: "build v77" - other families test the app; admin page; 🆘 report with a voice note + WhatsApp 9844542132): a NEW family (parent app "🏠 Start a new family" + family name) starts with NO children (cfg.v2, C.newFamCfg; C.kidList no longer falls back to the Gujjar children) and voice clips off (cfg.rec false - the kids page removes ans / rec clips again, except 🆘 voice notes, since app h28 still uploads them; recClean); parent Settings: ➕ Add a child / 🗑 remove, family name, voice-clip switch; the app name is "<Family> Home Class" everywhere (C.appTitle; the Gujjar family cfg.famName = "Gujjar"); kids pairing screen explains the 3 steps for new families. 🆘 Report a problem in the kids app (top bar + ⚙️, voice note with the app's own recorder + what it heard) and the parent app (⚙️ Family, browser recorder up to 60 s): homeclass/<fam>/reports/<id> {note, heard, aud / recFrom-recTo, last 150 log lines, device, versions, st}; then "📲 Also tell on WhatsApp" (wa.me/919844542132, prefilled). Admin page homeclass-admin.html (open once with the admin link #d=<private key>, kept only on that phone): every device registers its family once a day at homeclass/hcreg-admin-family-list-encrypted-v1/<id> ENCRYPTED for the admin (ECDH P-256 + AES-GCM, C.register) - list of families (🔴 open reports, old screens, silent voice), tap -> Reports (note, ▶ voice note, log + 📋 Copy, ✅ Solved), Children (table map, weak facts), Devices, Live, Log (today, 📋 Copy). The DB3 rules were not changed (a new hcreg rule was refused as a production change; the list lives under homeclass/ with a 24+ character key). Functions: C.register, C.report, C.waLink, C.famName / appTitle / newFamCfg, kidList; kids repOpen / repSend / recClean / hcRecite; parent wNew, drawSettings, kAdd, sRec, repSend.

- 08-Nov-2026 · kids v76 · core v39 (user: "the TV does not update - check the log"): the TV's log had 1026 lines on 08-Nov (cap 800 a day): app h28's "mic: no sound for 1.5 s - reopened it" line every ~1.7 s filled it, so from 22:55 none of the screen's own lines (open, update, class) were saved - the TV did update to v75 after a restart (23:25, heartbeat v75). The app's "reopened it" lines are now counted and sent as one summary line per 15 s flush. Functions: diag flush (core). Next app build: drop the useless re-open (it never woke the remote).

- 08-Nov-2026 · kids v75 · core v38 (user's TV photo 22:53: "mic still not on when needed and the sign is wrong; Evs screen mixed up and no letter pop-up like the phone; the update message cannot be closed on the TV; the app does not force the mic on; text mixing - check all pages"): TV log 22:46-22:54 with app h28: the app re-opened the mic ~70 times while the sound stayed dead - re-opening does NOT wake the remote; every time a remote BUTTON was pressed (Start, 🎤 Mic on) the sound came back for ~30-50 s: the remote's Bluetooth mic sleeps when no button is pressed and only a button press wakes it. So: red sign "🔇 Mic asleep - press OK on the remote" + the TV says once per question "Press OK on the remote, then say it."; during a question the focus sits on 🎤 Mic on, so OK = wake + listen. The TV page is 960 x 540 CSS px (not 1920 x 1080 as tested before): class bar, keys, question, mic sign and board sized for it (no big mic circle on the TV board screen), Practise page choices compact - checked at 960 x 540 (table, spelling, practise). Spelling on the TV (askSpellG) now spells the word out letter by letter like the phone (spellOut) for right / wrong / time up. Update card: any remote key or Back closes it (core upCard keydown, hcBack). Functions: tvMicOff, hcLevel, hear, askSpellG, hcBack, upCard, CSS.

- 08-Nov-2026 · kids v74 · app h28 (user's TV photo 22:24: "build the APK and fix it properly; the texts are all mixed, one inside the other"): (1) h28 VoskMic measures the mic sound (RMS every 0.1 s) and sends the loudest of each 0.3 s to the page (window.hcLevel); the TV sign is green while sound comes in and red after 1 s of nothing (old apps keep the v73 5 s rule). On a TV, 1.5 s of dead sound (RMS < 14 - the remote's mic sends 6-9 when it has gone quiet, 20-80 when live) re-opens the microphone by itself (log "mic: no sound for 1.5 s - reopened it (TV remote)", page log "TV mic: no sound - the app reopened the mic"). (2) TV spelling screen: the grid rows could shrink below their text when the TV keyboard took half the screen (min-height 0) - rows now never shrink (checked at 1920x1080 and 1920x600); the text box no longer grabs focus on the TV, so the big keyboard opens only when he selects it. Functions: hcLevel, tvMicShow, showInput, CSS; Java VoskMic.level / reopen, MainActivity.vStart. HomeClass.apk + homeclass-version.json 28, homeclass-ver.json kidApk 28.

- 08-Nov-2026 · kids v73 (user, 22:18: "the mic is off but it says Mic ON - show it in another colour; the big table numbers push the Practise page out of view, keep them as before"): TV log 22:15-22:18 - answers were heard only 1.4-5.4 s after a listening window opened (or right after 🎤 Mic on), later windows timed out ("time up" x6) while the sign stayed green - the app cannot read the remote's sound level (Vosk path gives no level to the page), and the remote's Bluetooth mic stops sending after a few seconds. The sign is now green for the first 5 s of a window (and while words come in), then red "🔇 Mic OFF - press 🎤 Mic on". The v72 56 px table numbers are removed (old size; the gold focus ring stays). Functions: tvMicShow, tvMicOff, tvMicWords, onPartial, CSS. An exact sign needs the app to send the real mic level (new APK).

- 08-Nov-2026 · kids v72 (user: "Start class on the home page does not work, I can't select tables in Practise a table from the remote; show a sign when the remote mic is off - I talk looking at the TV"): TV log 21:55-22:01 - no "class start" after pressing Start (the press went elsewhere), then Practise ran table 1 (could not pick 9). On the TV only .btn / .kid / .key / .ic had a focus ring, so Start class (.go), the table numbers (.dot) and the practice choices (.mode) showed nothing when selected; the first focus went to the card div (not focusable). Now every button / input gets the gold ring on the TV, the first focus is Start class, the table numbers are 56 px and keep the focus after a pick (log "table picked: N"). New mic sign at the top (TV, during a class): green "🎤 Mic ON - speak now" while a listening window is open, red "🔇 Mic OFF - press 🎤 Mic on" when it is closed for more than 0.9 s; hidden off the class screen / when the app is hidden. The log also showed 🎤 Mic on works (heard within 2-4 s after each press). Functions: CSS, focusFirst, tPick, tvMicShow / tvMicHide, micListen, hear, show.

- 08-Nov-2026 · kids v71 (user: "I closed the app and the mic keeps going on and off"): TV log 21:51-21:53 - after "class end 21:52:00" the TV still opened a listening window every 3 s (and at 21:51:53 two loops ran at once: "TV mic: busy" x17). tvListen kept looping for up to 60 s per question whatever happened (only a typed answer cancelled it). Now one loop at a time (a new one stops the old), it stops when the question is answered / typed / timed out / skipped (hear() closes it), when the class is no longer running, and when the app is hidden or closed (visibilitychange -> stopListen, log "app hidden - mic closed"). Functions: tvListen, hear, visibilitychange.

- 08-Nov-2026 · kids v70 (user's TV photo 21:50: "the mic goes off in between; when I skip all it still says I completed the table and gives 5 stars; give a manual mic button everywhere; Evs spell word in capitals, another colour, highlighted; countdown like the tables"): TV log 21:44-21:51: table 9 test - 5 answered, then 20 lines skipped -> round() treated "skip" as nothing, so the round stayed clean -> learnt + 5 stars; Evs spelling on the TV uses Google's listening, which got no sound from the remote ("error 7 · loudest 6-8" every 2.5 s, one "bo NES" in 4 min). Now: a skipped line makes the round not clean and is not learnt (tables, checks, warm-up); 📺 "🎤 Mic on" button in the class bar on the TV (fresh listening window = wakes the remote mic); the spelling word in the caption is shown in CAPITALS, amber, boxed (.spw); the answer countdown now also runs on the TV and in lessons (askOral) and spelling (askSpellG, at least 20 s), with "Time's up" + the answer. Functions: round, hbShow, kMic, say, hear, askOral, askSpellG. The remote's mic itself still drops sound (hardware) - the number keys / typing always work.

- 08-Nov-2026 · kids v69 (user's TV photo 21:38: "I didn't finish the 9 table, the app says I finished; the screen does not look right - check every page, the log and the sound"): TV log + sound 21:37: the 45.8 s recitation WAV has his voice only for the first ~7 s ("nine one ... nine two eighteen"), then near-digital silence (RMS 6-9) - the remote's Bluetooth mic stops sending sound a few seconds after it is opened; v61 then counted the 8 lost lines as "not heard -> quick check" and said "Super! You said the whole table". Now (1) a recitation with fewer than half the lines heard is not "said" - "I could hear only N lines. Say the whole table again" (phone too); the quick check says "Good. Now a quick check" when lines were lost. (2) the TV never uses the long recitation (reciteOk false on TV again, without the wrong "needs app h16" toast): practise / test on the TV = the whole table as questions (mixed for the test), learnt when every line is finally right. (3) TV mic windows short again (6 s; v67's 45 s window went deaf after the remote stopped sending). (4) TV class screen: the number keys sit right of the board (they covered Skip / Pause / Stop and pushed the question off the top) - checked at 1920x1080. Functions: reciteOk, practice0, reciteTable, randomCheck, tvListen, CSS.

- 08-Nov-2026 · kids v68 (user's TV photo: "from the remote I can't reach Start; a toast says it needs the new listening app h16"): (1) reciteOk() was false on every TV, so the "needs app h16+" toast showed (the TV app is h27 with the model ready) - the TV may now say a whole table. (2) the big ▶ Start saying / ■ Done button (kHold) is position:fixed, so the TV's arrow-key focus list (offsetParent) never held it, it reacted only to touch (pointerdown), and it sat cut off at the screen edge: it is now in the focus list, takes OK (click), is focused by itself when the app waits for ▶ Start saying, and sits 70 px / 50 px inside the edge with a gold focus ring. Functions: reciteOk, focusables, waitStart, kHold click, CSS.

- 08-Nov-2026 · kids v67 (user: "the remote mic is on sometimes, off many times - make it perfect"): TV sound 08-Nov 21:15 - the saved WAVs show the TV mic delivers sound all the time (noise floor 20-80, speech 1200-1700), so it is NOT switched off by the remote; the on / off was the app: tvListen reopened a 9 s Vosk window again and again (log "TV mic: silence (try N)", 21 windows for 5 answers; each reopen = mic icon off + a gap where words are lost, answers also started 3-6 s after the question). Now one open window of 45 s per question (restarted only after it ends). Functions: tvListen. Not changed: the question flow.

- 08-Nov-2026 · kids v66 (user: "why can't I start Evs / practise a table on the TV - make the TV app a TV app, not dependent on the phone"): on the TV the ▶ button and the lesson buttons (Evs ...) only sent a command to a kids phone (and said nothing useful when the phone app was closed - TV log "no kids phone online"). Now ▶ Start class and every lesson run on the TV itself (runClass 'tv-remote', the same code as the phone; answers by the remote's mic or the number keys); the home text and the button say so; the extra "practise here with the remote" row is gone. A class that runs on a phone is still shown on the TV (watch screen). Functions: drawHome, the kids click handler. Weak part left: the TV remote's mic (listens only while the remote's mic is active).

- 08-Nov-2026 · kids v65 · core v37 (user, TV: "9 3 za I said 21, it took it correctly"): TV log 21:16 + saved sound: he said "twenty one" for 9x3; the app logged "twenty seven → ✓". Free decoding of the WAV (small and big model) says "twenty one"; the single-question grammar held only the right answer and its neighbours (p±a, p±b, ±1, ±2, ±10, a+b), so any number was forced onto 27. qGrammar now also allows every number 1-100 as a bare answer and after the line; tested on 11 real recordings: the 21 is now "✗ 21", all right answers still ✓. TV mic: the remote's mic listened 21 times for 5 answers ("TV mic: silence") and "TV: no kids phone online" - the class ran on the remote mic because the kids phone app was closed; the phone listens much better (see HOMECLASS.md). Functions: qGrammar.

- 08-Nov-2026 · kids v64 (user's TV photo: "I am missing so many buttons on the TV, how to skip"): the fit-to-screen class layout (v-bOn rules) was written for phones only (`:not(.tv)`), so on the TV the table board pushed the buttons (Skip, Skip warm-up, Test me now, Next table, Go to table, Pause, Stop) below the screen edge. The same layout now runs on the TV, with bigger buttons (20 px) for the remote. No data. Functions: CSS only.

- 08-Nov-2026 · kids v63 (user: "it says Brilliant but the card shows Excellent" / "the child finished the 9 table and the random test but it asks to do it again"): log 19:03-19:08 - the recitation was heard fully (3 unsure lines), the 5-line check asked 9 answers (wrong lines came back and were finally right: 9x3, 9x4, 9x9, 9x6) but round() returned "not clean" for any first-try mistake, so the table was not learnt and the voice said "once more". Now the check counts when every wrong line was finally right (S.roundFixed). The card and the voice used two separate random praise words; now one word for both (tables, oral facts, spelling). Functions: round, randomCheck, askTable.

- 08-Nov-2026 · kids v62 (user: option 2 - "check the log and then we plan"): the bigger Vosk model (en-us-0.22-lgraph, from a public GitHub copy) was tested on Vihaan's WAVs and hears the same as the small one ("seven two za" with no number), so NOT built. Now: when only the line is heard ("seven two za" / "[unk]") the app no longer says "Just say the answer" (v59) - it listens again quietly and the screen shows "Now say the answer"; every "heard" log line ends with how he spoke: started after N s · spoke N s · ended N s after the last word (or "no word at all in N s"). Next step: read these lines + the saved WAVs after one class and decide. No new data. Functions: micListen, onPartial, askTable.

- 08-Nov-2026 · kids v61 (user: "9 2 zaa was not heard properly, same problem, fix it a different way"): log + sound 08-Nov 18:34, table 9: he said 9 lines (9 speech bursts, 2 s apart) but the offline listening caught 3 ("nine one nine ... nine two eighteen"); a line-by-line test with the exact answer grammar on the same WAV also failed from line 3 - so it is the sound/model (Vosk small on this Redmi), not the judge. Change: after a whole-table recitation the lines it did not catch are no longer asked one by one (7 questions); they join the unsure lines in the short random check (max 5, v60), where listening is short and reliable. Bigger model / second listener needs a new APK (model download is blocked in cloud sessions). Functions: reciteTable.

- 08-Nov-2026 · kids v60 (user: "option B ... if all turns green ask random and make the child perfect, then give stars; 5 random + unsure lines, cap 5, not 1 and 10, only in this test"): saying a whole table from memory - a line the app is only UNSURE about now counts as right and is not asked again (only lines not said at all are asked, one by one). Then a short check, at most 5 questions: the unsure lines first (max 5), the rest random, lines 1 and 10 never asked; a wrong line is told and comes back (answer hidden, v59). All right = table learnt, +5 stars, confetti; otherwise the table comes again. No new data. Functions: randomCheck (new), reciteTable, tablesLearn, practice0.

- 08-Nov-2026 · kids v59 (user: "child keeps telling the word but the app could not hear" / "when it asks again after a wrong table, hide the answer - he reads it, not remembers"): log 08-Nov, Vihaan's Redmi, class 17:35: 7x5 and 7x2 heard as "[unk]" / "into" / "seven two za" / "seven two [unk]" - he says the line ("seven two ja") and the number after it is lost, then repeats the whole line (the Vosk run on the saved WAVs gives the same, so it is the sound, not the judge). Now: first time that happens the app says "Just say the answer." (log: "line heard, answer lost"). A question asked AGAIN after a wrong answer hides the answer on the board (the row kept its answer shown after "Not quite"). Functions: askTable.

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
