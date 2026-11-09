# Gujjar Home Class (user's family app, 01-Nov-2026)

Voice classes for Aryan (7th std) and Vihaan (2nd std): tables, oral test questions and spellings that Mom / Dad type.
English only (Kannada / Hindi later). No login. Nothing to do by hand after setup: it updates and cleans itself.

## Parts
| Part | File | Where it runs |
|---|---|---|
| Kids app (Android, phone + Google TV) | source davan-scraper `widgets/homeclass` (com.gujjar.homeclass, key homeclass.jks / homeclass / homeclass2026) -> `HomeClass.apk` + `homeclass-version.json` | spare phone next to the Google Home (Bluetooth speaker), Google TV |
| Kids screen | `homeclass-kid.html` | inside the app (downloaded fresh each start from GitHub Pages, kept for offline; copy in the APK) |
| Parent app | `homeclass.html` (+ manifest-homeclass.json, app-sw.js); also as APK `HomeClassParents.apk` (com.gujjar.homeclassparent, source davan-scraper widgets/homeclass-parent, homeclass-parent-version.json) | Mom's and Dad's phones |
| Shared code | `homeclass-core.js` | both pages |

The app = WebView at the fake address https://homeclass.app/ (served by MainActivity.serve, so localStorage stays the same online
or offline) + bridge `window.HCA`: speak (TextToSpeech en-IN), listen (SpeechRecognizer en-IN, 5 guesses), keepOn, setBusy,
setAlarms (AlarmManager, IST), checkUpdate. Self-update like Davan Caller (PackageInstaller, silent on Android 12+, never during a class).
A change to the kids screen = edit homeclass-kid.html only (no new APK). A new APK only for Java changes: bump versionCode/Name +
BuildInfo, write H<n>_CHANGES.md, build (`ANDROID_JAR=$HOME/tc/android.jar HOMECLASS_WEB=<this repo> bash build.sh`), copy to
HomeClass.apk, bump apkVersion + ?v= in homeclass-version.json. Keep the source + keystore in davan-scraper widgets/homeclass.

## Auto-update (01-Nov-2026)
`homeclass-ver.json` {kid, par, kidApk(+Name), parApk(+Name), news[{k,v,at,t}]} - pages check it every 60 s + on return (C.watchUpdate),
show "🆕 Updating" + news, reload with ?v=. APK: page calls bridge.checkUpdate() when kidApk / parApk is newer; Upd tells each step to
window.hcUpd. Parent APK: homeclass-parent-version.json; kids APK: homeclass-version.json (both still checked every 6 h too).

## Logs (01-Nov-2026) - read these FIRST for any problem
DB3 homeclass/<fam>/diag/<deviceId>/<YYYY-MM-DD>/<id> {t, m, l e|w} + diag/<dev>/info {kind, ver, app}. Find the family keys with the
davan-student-news "DB3 peek" job (paths `homeclass?shallow`), then read with curl `<DB3>/homeclass/<key>/diag.json` (the key opens it)
or peek `homeclass/<key>/diag/<dev>/<day>`. The user's main family (01-Nov) = the one with dev "Vihaan Gujjar" (key ends …SJZR? check dev).


## ▶▶ A problem is reported ("check the log", "no sound", "not recognising", "stuck") - DO THIS FIRST (user, 05-Nov-2026)
"When I start a new session it should read the log and the sound properly and fix it." Never say you cannot read the phone's log and never ask the user for a
screenshot first: the app UPLOADS its own log, the phone list and the child's recordings to DB3, and you read them with curl. You do NOT read the phone itself
(no Android log / settings / screen) - only what the app uploads (so a new thing to see = add a log line to the app).
1. **Get the family key** (a secret - it is in no repo; never ask the user for it): run the davan-student-news Action "DB3 peek" (paths `homeclass?shallow`, via the
   GitHub MCP actions_run_trigger + get_job_logs); the user's main family is the one whose `dev` list has "Vihaan Gujjar" / "Kids phone". Then `export FAM=<key>`.
2. **Read the log** (private repo davan-scraper, widgets/homeclass/tools - attach it with add_repo): `bash hc-log.sh [day] [deviceId|all] [grep-word]` prints the phones
   (name | make+model | app | screen version | voice engine | last seen) and each phone's log lines (IST). Today = default. `TAIL=200 bash hc-log.sh ...` for more.
3. **Read the sound**: `bash hc-rec.sh <dir> rec|ans [since-epoch-ms]` downloads the saved WAVs (rec = whole tables / spellings, ans = single answers) + what the app heard;
   `python3 -I hc-test.py <wav> spell <word> | table <t> | ans <a> <b>` runs the app's own listening (same grammar + judge from homeclass-core.js) on a recording
   (needs `pip install vosk`, VOSK_MODEL = unzipped homeclass-model-en-us-0.15.zip from this repo, node). Test every fix on the real recordings BEFORE publishing.
4. **What the log lines mean**:
   - `voice engine ready · default X · installed: ...` = the phone's speech engines; `voice: no "done" ...` / `did not start speaking` = NO SOUND (h27 asks for Google's engine by name, then switches engine);
     the phone list shows voice ok / silent / failed and the engine.
   - `listen (offline engine): "..." / alt` = what the offline engine heard; `heard AxB: "..." → ✓ / ✗ n / ?`; `recite N (try k): "..." -> wrong / unsure / missing`; `spell <word>: "..." -> ok|unsure|wrong cost`.
   - `Promise error` / `screen crashed` / `mic off (keys)` / `cmd ... ignored: N s old` = a bug / memory kill / typing mode / a command that arrived late.
   - `class start/end ... right N wrong N`, `warm-up skipped`, `table N skipped`, `question skipped`, `not heard (app)` / `confirmed` = what the family did.
5. Then fix, test (browser tests with a mock window.HCA, Vosk on the real WAVs), publish (see the rules above), and tell the user what the log showed in plain words.

## ✅ Before saying "done" - every Home Class build (user, 09-Nov-2026: "why so many problems, can't you be perfect")
Run ALL of these, not only the changed screen (scripts in the session scratchpad are throw-away; re-create them):
1. Syntax: node --check on core + every <script> of kids / parent / admin pages.
2. Browser walk-through with the DB mocked (Playwright route on firebasedatabase.app, never write test data to real families) at 360x740 phone AND 960x540 TV:
   NEW family (parent: family name -> Start -> add child with the form -> settings -> add device), kids home empty / 1 child / 3 children, start class,
   practise a table, lesson + spelling, 🆘 report (kids + parent), ⚙️ settings, 🔄 refresh, admin list + family tabs. Zero page errors, no text cut / overlapping.
3. Old families: the Gujjar family (no cfg.v2) must look and work exactly as before.
4. Things the Android apps do differently from a browser: no prompt()/alert reliance for anything important, taps near the keyboard, small screens, old app versions.
5. Only then publish, and list honestly what was NOT tested on a real phone.

## 🛠️ Admin page + other families (v77, 09-Nov-2026)
`homeclass-admin.html` (admin link #d=<private key>, kept only on the admin phone). Families register themselves ENCRYPTED at DB3 `homeclass/hcreg-admin-family-list-encrypted-v1/<id>` (C.register, public key C.ADMIN_PUB in core). 🆘 reports: `homeclass/<fam>/reports/<id>`. New family cfg: {v2:1, famName, rec:false}. To read another family's log with the tools, get its key from the admin page (family → key …xxxx) or DB3 peek.

## 🔊 Speaker (h6)
Kids app prefs "spk" {mode phone|cast, name, host, port, model}. Cast = Google Cast v2 to the Default Media Receiver (from the staff
widget's HomeCast), one TLS connection per class (reader thread answers PING, closed after 90 s idle), Google translate_tts MP3 first,
phone TTS WAV served from the phone as backup. Fails -> phone voice (hcSpkErr). Latency ~0.5-1 s per sentence after the first.

## 🗣️ Recite + offline engine (h16 / v27)
Vosk (libs in davan-scraper widgets/homeclass/libs, README there) - model unzipped once to files/vosk; A.voskState(), A.setGrammar(json |
'google'), listen / listenHold / endListen go to Vosk when ready; A.reciteStart / reciteStop -> hcRecite(id, p|r|f, text). C.parseRecite
splits on ja / is / into, the line numbers in order decide where an answer ends. Learn style: st0 listen & repeat -> st1 recite (perfect =
learnt, st3); without the engine (old app / TV / browser) st1 = the old in-order quiz.

NEVER use org.vosk.android.SpeechService / StorageService (Java lambdas -> crash on Android with our dx build); VoskMic.java is the mic loop.

## 📚 Practice modes (v30)
practice(kid, {mode: show|app|answers|test, t}) via runClass(kid, why, opt); parent cmd {do:'test', kid, table}. The Indian-English model
zip is in davan-scraper widgets/homeclass/libs (not in the app yet - compare on Vihaan's REAL recordings first; synthetic voices: US 98 %, IN 33 %).

## Data: DB3 (davan-student-news) `homeclass/<familyKey 28 chars>/`
- `cfg` {kids:{k1,k2:{name,std,from,to,style learn|revise,min,time "HH:MM" IST,days [0-6],on,emoji,color}}, upto 10|12|20}
- `sets/<id>` lessons {title,type oral|spell,who all|k1|k2,until YYYY-MM-DD,items[{q,a,k?,s?}],off}
- `prog/<kid>` {t:{<table>:{st 0 learn,1 in order,2 mixed,3 mastered, ok}}, weak:{"7x8":n}}
- `live/<kid>` the class now (parent app + TV watch it live); `cmd` parent's Start / Call / Stop {do,kid,dev,at,id,took}
- `days/<YYYY-MM-DD>/<kid>` totals {right,wrong,stars,sec,n,mist,sets,missed}; `log/<day>/<kid>/<id>` every answer
- `dev/<id>` devices {name,kind phone|tv|web,ver,app,at,auto,mic}
- `hcpair/<6 digits>` {fam,exp} pairing code, 15 min (outside homeclass/)
Rules (no login): homeclass/$fam read/write when the key has 24+ characters (root not listable); hcpair codes. Added by
davan-student-news workflow "DB3 rules - Home Class" (scripts/db3_rules_homeclass.js, keeps all other rules, safe to re-run).
Clean-up (kids device, once a day): log/ older than 90 days, days/ older than 400 days. Cost: a few KB per class.

## How a class goes
Class time (per child, IST, days) -> the phone calls "<name>, class time! Say ready" for 10 min (missed = shown to parents).
Learn style (Vihaan): warm-up from learnt tables, then the current table: listen & repeat -> in order -> mixed; mastered after
2 perfect mixed rounds (+5 stars, confetti). Revise style (Aryan): mixed questions, wrong ones (weak) come back 40% of the time.
Wrong answer: "Not quite. 7 times 8 is 56. Say it with me" -> child repeats -> the question comes back later in the round.
Answer = LAST number said ("7 into 8 is 56" -> 56; number words too). Silence: "Take your time" -> after 3: "Are you there?"
(waits 5 min). Lessons are separate classes (v34): ▶ per lesson on both Homes, own time + days (alarm), 🔀 "mix" = also after the tables (60% tables then, max +10 min). Spoken table lines use "a b ja ans", never "times".
Oral: parent's key words after | must all be said, else 70% of the answer's main words. Spelling: letters one by one.
Table board (v2): live/<kid>.board = {k t|o|s, title, rows [[a,b,state 0-4,shown]], cur | keys, res, a | w, got} + live.p (words
while speaking, from h2 partial results); boardHTML draws it on the phone (kBoard) and the TV (wBoard, 2 columns).
TV: no microphone (Google TV remotes send voice only to Google) -> answers with the on-screen number keys; also shows a class
running on the phone big and live. Phone: ⌨️ Type is a fallback; after 3 mic failures it switches to typing by itself.
