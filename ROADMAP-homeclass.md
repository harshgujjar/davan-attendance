# Home Class - build roadmap (agreed 09-Nov-2026)

Read this first in every Home Class session. Tick a step when done (with versions). Rules: CLAUDE.md "Gujjar Home Class".

## Editions (one codebase)
- 🏠 Family / Tester edition: com.gujjar.homeclass, self-updating APK + live screen, DB2 now (DB6 later), free, more data with tester consent.
- 🛒 Play edition (later): new app id, Play updates, DB6, Play Billing, Play Integrity, minimal data (voice only with consent).
- Same screens / core files for both; only an "edition" switch differs (self-update, payment, database, data collected).
- Version line after every build: screen vNN · core vNN · family app hNN · play app pNN · parent vNN.

## Phase -1 - quick test version for other families - DONE 09-Nov-2026 (kids v77 / parent v48 / core v40 / admin v1)
- [x] New family = family name + no children, ➕ add / 🗑 remove child, voice clips off by default, app name per family.
- [x] 🆘 Report a problem (note, voice note, log) + WhatsApp 9844542132; mini admin page (encrypted family list, reports, children, devices, live, log).

## MAIN RULE (user, 09-Nov-2026): Home Class is a VOICE app - hearing the child by voice is the core; every change must keep or improve voice recognition.
## Later (agreed, not built yet)
- [x] Permanent family link code always visible on the parent Home (🔁 New code) - parent v52.
- [ ] C: weekly hearing tuning from the testers' saved clips (hc-test.py on real WAVs; add the words children really say - "tree", "fourty", zaa/jaa/ja, Kannada-accented numbers).
- [ ] D: clearer sound on quiet phones (Android gain / noise suppression in a new APK) - only if the saved clips prove it helps.
- [ ] Backup: tap a grey line on the board to say just that line again (only for lines the voice still missed).
- [x] A + B follow-along recitation + missed lines asked by voice - kids v83.

## Phase 0 - approve the mockup  (mockups/mockup-homeclass-admin.html)
- [ ] User approves / corrects the single-app + admin + "small details" screens.

## Phase 1 - single app, Family edition, DB2  (2-3 sessions)
- [ ] One app, roles: Parent / Child / Shared phone (🔒 PIN) / TV (auto). Parent part moves into the app; parent APK retired, parent web page stays.
- [ ] First-time setup: family name, children (class, tables, lessons, name pronunciation), buddy animal, PIN, link devices with the 6-digit code.
- [ ] Per-family privacy in DB2 (anonymous sign-in + rules: a device reads only its own family); database address = one setting (for DB6 later).
- [ ] Settings in two layers: defaults for all families + per-family overrides; "make default" from the admin page.
- [ ] Feel-good details: buddy, streak, badges, sticker book, birthday, parent notes read out, instant "learnt the 9 table" message, Sunday summary.
- [ ] 1 phone / 3 children: own times, back-to-back classes ("your turn in 2 minutes"); family quiz (optional).
- [ ] Feedback: 👍 / 👎 after a class, 🆘 Report a problem (log + note) -> admin page + alert.
- [ ] Voice clips: off by default, parent switch with consent; logs 7 days, clips 30 days, auto clean-up; per-family size limits.
- [ ] Test every screen (phone + TV 960x540) before saying done.

## Phase 2 - admin page (your control room, on your phone)  (1-2 sessions)
- [ ] All families: problems first, devices online / versions, last class.
- [ ] Family: Children (progress, weak facts, spellings) · Classes (timeline: said / heard / ✓ ✗ / time up / skipped / ▶ sound) · Devices · Sound · Problems · Live (watch, Stop / Skip) · Log (📋 Copy).
- [ ] Auto-doctor every hour (like PC Doctor): mic asleep, voice silent, old version, crash, low hearing rate -> one-tap fixes; safe ones by itself; ☁️ alert only when needed.
- [ ] Nightly report: top problems, hearing rate, crashes, families gone quiet.
- [ ] Self-improving: misheard words across families -> new hearing rules; spaced practice per child; adaptive answer time.

## Phase 3 - tester families  (ongoing)
- [ ] Invite message (links + 3 steps). Your family + 2-5 friend families. Live fixes, weekly top-3 problems.

## Phase 4 - Play edition  (2-3 sessions, after testing is good)
- [ ] Open DB6, copy script, switch the Family edition to DB6 too.
- [ ] Edition switch: no self-update, Play Billing (trial + monthly / yearly, one plan per family), cloud function checks purchases with Google + Real-time Developer Notifications (renew / cancel / grace / refund -> "active until"), acknowledge within 3 days.
- [ ] Play Integrity check on the server; premium data only with the server-side premium flag (mods get nothing synced).
- [ ] Privacy policy, parent consent (India DPDP), Families policy, Data safety form, content rating, store listing (icon, screenshots, video), in-app ⭐ review at happy moments.
- [ ] Play Console account ($25), payments profile (bank, PAN/GST); closed test 12 testers x 14 days; production in steps 10% -> 50% -> 100%.

## Phase 5 - after launch (both editions keep running)
- [ ] Weekly: fix top 3 from the admin page, Family edition first, then Play. Reply to reviews. Watch costs (Firebase budget alerts) and backups.
