# 🇯🇵 Japanese: letters first + Type → 日本語 (user, 18-Oct-2026) - NEXT SESSION BUILD

Approved mockup: artifact 96dDUE8i4qvc6K3HeXpFkY, row 3 "Japanese - letters first" (JHome, JChart, JLesson, JType, WLetter).
User: "students know nothing about Japanese - learn the alphabet first, like a b c" + "type in English -> Japanese, and speak it".
Build A + B + C. A and B need nothing; C needs the Google key (steps below). Widget apps only (PlcActivity + widget 🎯 page), native, no browser.

## What to build
1. **Japanese home (PlcActivity jp view, mockup JHome)**: Step 1 Hiragana (46, 11 rows, 5 a day) -> Step 2 Katakana -> Step 3 numbers + greetings
   -> Step 4 words + sentences (N5). Words / later steps 🔒 until hiragana is done. Buttons: 🔤 Letter chart · ✍️ Today's row · ⌨️ Type → 日本語.
2. **Letter chart (JChart)**: 5-column grid, Hiragana / Katakana switch; each box = letter + romaji + Kannada sound (か = ka · ಕ);
   tap = big letter + phone Japanese voice; learned rows green, future rows faded (still tappable).
3. **Row lesson (JLesson)**: per row, 3 steps - (1) see + hear (big letter, ಕನ್ನಡ sound, "like ಕ in ಕಮಲ"), (2) write with the finger
   over a grey letter (native custom View drawing a Path), (3) quick check (see letter -> pick sound, 2 x 2, green / red, +5 XP).
   Passing a row = prog.lv.japanese + 1 (keep the existing japanese track levels 1-10 in learn/bank.json in this order).
4. **⌨️ Type → 日本語 (JType)**, 3 tabs, every result: Japanese letters + romaji + Kannada + 🔊 Speak + 🐢 Slow (phone Japanese voice):
   - **A · Sound → letters (offline)**: romaji -> hiragana live as you type (+ katakana line). Rules: longest match 3/2/1 letters,
     double consonant = っ, n before a consonant / at the end = ん, "-" = ー. The mockup's toKana() table is the reference.
   - **B · English word (offline)**: ~500 job + daily words / phrases in learn/bank.json (new "jdict": [en, kana, romaji, kn]); search as you type.
   - **C · Any sentence (online)**: Cloudflare worker davan-release gets a /translate route -> Google Cloud Translation v2 (key = worker
     secret GOOGLE_TRANSLATE_KEY, never in the APK); returns Japanese; romaji + Kannada made in the app from the kana when possible.
     Show "machine translation - check with B". Cache answers on the phone.
5. **Widget 🎯 page: 🇯🇵 letter of the day (WLetter)** until hiragana is done (then the Japanese word of the day): letter, 🔊, 2 x 2 sound quiz,
   "✍️ Learn today's row in the app →" (opens PlcActivity jp). New plc_* card layout like the others.
6. If the phone has no Japanese voice: show "Settings → Text-to-speech → install Japanese" once.
Staff widget: same. Bump both widgets (next numbers after w249 / s301), changelogs, "next" channel as usual.

## Google key for C - steps the user follows (Claude never sees the key)
Google needs a card even though our use stays free (5 lakh characters / month).
1. console.cloud.google.com, sign in with harshgujjar@gmail.com.
2. Project menu (top left) -> New Project -> name **davan-translate** -> Create; select it.
3. ☰ Billing -> link / create a billing account (India, card). Billing -> Budgets & alerts -> budget **₹100** (email if anything is charged).
4. ☰ APIs & Services -> Library -> **Cloud Translation API** -> Enable.
5. APIs & Services -> Credentials -> + Create credentials -> **API key** (starts AIza…). Edit API key -> API restrictions -> Restrict key ->
   tick only Cloud Translation API -> Save.
6. APIs & Services -> Cloud Translation API -> Quotas & System Limits -> "Characters per day" -> **15000** (stays under the free 5 lakh / month).
7. Do NOT paste the key in chat. dash.cloudflare.com -> Workers & Pages -> **davan-release** -> Settings -> Variables and Secrets -> + Add ->
   Type **Secret**, Name **GOOGLE_TRANSLATE_KEY**, Value = the key -> Deploy.
8. Tell Claude "key added" -> Claude adds the /translate route to tools/cloudflare-release-worker.js and gives the paste / deploy steps
   (see RELEASE-WORKER.md). Until then C shows "coming soon"; A + B work.
