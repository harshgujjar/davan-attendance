# Google Home relay - option 2 (plan for a later build)

User, 06-Oct-2026: "link the widget with Google Home, server side". Google gives no cloud API that makes a Google Home / Nest speaker
talk; a speaker only plays what a device on the SAME Wi-Fi sends it (Google Cast). So something at home must pass the message on.

## Option 1 - built in staff widget w227 (held, Super Admin + Vijayalakshmi P S only)
The person's own phone does it (`HomeCast` in the widget): every widget notification except SOS, a 7:30 am horoscope + markets brief
and the 3:45 pm market close are turned into speech on the phone and played on the chosen speaker - only while the phone is on the
home Wi-Fi. Settings: card "🏠 GOOGLE HOME" on widget page 4 (Super Admin) / page 2 (staff) -> HomeActivity.

## Option 2 - an always-on spare phone at home (next build)
Goal: the speaker announces even when the person is away from home, with no computer.

1. **Device**: any old Android phone (Android 7+) left on its charger at home on the Wi-Fi, or a Google TV / Chromecast with Google TV.
2. **Same app, "home relay" mode**: install the Davan Staff widget, log in once, and switch on "🏠 Be the home relay for <person>".
   It keeps the screen off and only needs the charger.
3. **Server side (no extra cost)**: the staff app / widget writes each announcement for that person to DB2
   `davan_pub/home_say/{login}/{pushId} = {t: text, at, kind}` (kept 1 day). The relay reads it every minute (one tiny read, the same
   NodeCache stamp pattern as the other nodes) or wakes on a high-priority FCM push from the Cloudflare worker already used for faculty
   push, says new items on the speaker in order, and writes `said: at` back.
4. **Who writes**: the person's own widget (every notification it shows, as in option 1, but posted to `home_say` instead of cast
   directly) and the staff app for server events (timetable change, new notice) - so announcements happen even when the person's
   phone is off.
5. **Rules kept from option 1**: SOS left out (until the user decides), hours 7 am - 9 pm by default, horoscope + markets brief at
   7:30 am, market close 3:45 pm Mon-Fri; per-person on/off and speaker choice on the relay.
6. **Firebase cost**: one write per announcement (a few a day per person) and one small read a minute per relay phone.
7. **Later**: several speakers (staff room / office / hostel) = one relay phone each, with `home_say/{room}` instead of `{login}`.

## Truly server-only alternative (not Google)
Amazon Alexa (Echo) can be made to announce straight from a server with the free "Voice Monkey" service - no device at home needed.
