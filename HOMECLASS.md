# Gujjar Home Class (user's family app, 01-Nov-2026)

Voice classes for Aryan (7th std) and Vihaan (2nd std): tables, oral test questions and spellings that Mom / Dad type.
English only (Kannada / Hindi later). No login. Nothing to do by hand after setup: it updates and cleans itself.

## Parts
| Part | File | Where it runs |
|---|---|---|
| Kids app (Android, phone + Google TV) | source davan-scraper `widgets/homeclass` (com.gujjar.homeclass, key homeclass.jks / homeclass / homeclass2026) -> `HomeClass.apk` + `homeclass-version.json` | spare phone next to the Google Home (Bluetooth speaker), Google TV |
| Kids screen | `homeclass-kid.html` | inside the app (downloaded fresh each start from GitHub Pages, kept for offline; copy in the APK) |
| Parent app | `homeclass.html` (+ manifest-homeclass.json, app-sw.js) | Mom's and Dad's phones |
| Shared code | `homeclass-core.js` | both pages |

The app = WebView at the fake address https://homeclass.app/ (served by MainActivity.serve, so localStorage stays the same online
or offline) + bridge `window.HCA`: speak (TextToSpeech en-IN), listen (SpeechRecognizer en-IN, 5 guesses), keepOn, setBusy,
setAlarms (AlarmManager, IST), checkUpdate. Self-update like Davan Caller (PackageInstaller, silent on Android 12+, never during a class).
A change to the kids screen = edit homeclass-kid.html only (no new APK). A new APK only for Java changes: bump versionCode/Name +
BuildInfo, write H<n>_CHANGES.md, build (`ANDROID_JAR=$HOME/tc/android.jar HOMECLASS_WEB=<this repo> bash build.sh`), copy to
HomeClass.apk, bump apkVersion + ?v= in homeclass-version.json. Keep the source + keystore in davan-scraper widgets/homeclass.

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
(waits 5 min). Lessons after the tables (60% of the time is tables when there are lessons; lessons always finish, max +10 min).
Oral: parent's key words after | must all be said, else 70% of the answer's main words. Spelling: letters one by one.
TV: no microphone (Google TV remotes send voice only to Google) -> answers with the on-screen number keys; also shows a class
running on the phone big and live. Phone: ⌨️ Type is a fallback; after 3 mic failures it switches to typing by itself.
