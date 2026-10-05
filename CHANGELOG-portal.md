# Student portal (student_portal.html) changelog and handoff notes

Moved out of the page <head> on 29-Sep-2026 (portal v9.99): it was about 300 KB that every student downloaded before the app could show. Newest entries at the top of the VERSION list; new entries go at the top of that list.

```text
════════════════════════════════════════════════════════════════
  HANDOFF — Student Portal (Davan College)
  File   : student_portal_v6_79.html
  Updated: 2026-05-16 (v6.76)
  Author : Harsha Gujjar, Director — Davan College
════════════════════════════════════════════════════════════════

PROJECT : Davan Student Portal — single-file PWA
ARCH    : Firebase RTDB REST + Firebase Auth SDK (anonymous sign-in)
SCREENS : #screen-login → #screen-student → #screen-student-dash → #screen-admin
RTDB    : davan_pub/portal_students/{URN} | controls/ | davan_pub/students | notices/
          timetable/ | lessonPlan/ | controls/lpExceptions | controls/bannedStudents
RULES   : grep before editing | no guesswork — confirm from actual source | no \' in template literals
DIAGNOSTIC RULE : Whenever Claude is unsure about ANYTHING it can't verify by
  reading code alone — not just this file, not just bugs — it must not guess.
  This covers any work with Harsha: browser/runtime state, other apps
  (index.html, puc.html, results.html, library.html, meter.html, widgets,
  sync scripts), general questions, or any point where Claude would otherwise
  assume/guess an answer. Ask the user to open DevTools (F12) → Console and
  give them a copy-pasteable JS snippet (or other verification step if F12
  doesn't apply). That snippet's LAST line MUST be copy(...) wrapping the full
  result as a string (e.g. copy(JSON.stringify(r,null,2))) — never end on
  console.log alone — so the user can paste the result straight back with no
  manual selecting. Applies proactively any time Claude has a diagnostic
  question, not only after a bug report, and not limited to this page.
ADMIN   : hardcoded — admin/admin123 | manager/manager123 | vp/vp123
STUDENTS: URN = login id | SHA-256(phone) = default password stored in RTDB
VERSION BUMP CHECKLIST : APP_VERSION/BUILD_DATE (~line 6447) are the source of
  truth and get JS-applied to #topbar-version + footer-meta spans on load —
  BUT the raw HTML fallback text in those same spans (topbar-version span
  ~line 4149, login-footer-meta-1/2 + stu-footer-meta ~lines 4321/4406/4882)
  is a SEPARATE hardcoded string that JS only overwrites AFTER load. If that
  update runs late or the page is viewed before it fires, the stale hardcoded
  text shows through. At each version bump, update APP_VERSION/BUILD_DATE AND
  grep for the old version string in these HTML fallback spans so they never
  silently drift out of sync (this drifted for months before being caught).
VERSION : v11.17 (2026-10-05) -- Student widget w171 released (LATEST_STUDENT_WIDGET_APK 171, apkUrl now raw.githubusercontent.com/...?v=171): an update right after a release could download GitHub's cached old APK and reinstall the same version; the link carries the version and the widget checks the file before installing. Pairs with admin v1751, staff widget w215.
VERSION : v11.16 (2026-10-05) -- Student widget w170 released (LATEST_STUDENT_WIDGET_APK 170): test-list students always see the 🔊 box and live test (davan_pub/tts_cfg/showStu only applies in Everyone mode). Pairs with admin v1750, staff widget w214.
VERSION : v11.15 (2026-10-05) -- Student widget w169 released (LATEST_STUDENT_WIDGET_APK 169): the spoken-alert switches (davan_pub/tts_cfg) are read when the widget settings open (at most every 2 min) and on refresh. Pairs with admin v1748, staff widget w212.
VERSION : v11.14 (2026-10-05) -- Student widget w168 released (LATEST_STUDENT_WIDGET_APK 168): spoken reminders could never start on Android 11+ (the text-to-speech engine was not declared in the manifest) - fixed; live test plays on vibrate too and says when the voice fails. Pairs with admin v1747, staff widget w211.
VERSION : v11.13 (2026-10-05) -- Student widget w167 released (LATEST_STUDENT_WIDGET_APK 167): 🧪 live test only for test-list students; others get ON/OFF (davan_pub/tts_cfg/allowOff), language, Test my voice, Change voice. No new reads. Pairs with admin v1745, staff widget w209.
VERSION : v11.12 (2026-10-05) -- Student widget w166 released (LATEST_STUDENT_WIDGET_APK 166): the 🔊 box shows only when the admin's switch (davan_pub/tts_cfg/showStu, default on) allows it; live test buttons speak the real next class / morning / tomorrow now. No new reads. Pairs with admin v1743, staff widget w207.
VERSION : v11.11 (2026-10-05) -- Student widget w165 released (LATEST_STUDENT_WIDGET_APK 165): ⟳ refresh downloads and installs a new version at once, GitHub version check every 15 min (GitHub only, no Firebase cost), settings show why an update is stuck. Pairs with admin v1742, staff widget w206.
VERSION : v11.10 (2026-10-05) -- Student widget w164 released (LATEST_STUDENT_WIDGET_APK 164): notifications 20 min apart (the horoscope came with the weekly rates), new default times, times the admin moves on the 🔔 page. No new reads. Pairs with admin v1741, staff widget w205.
VERSION : v11.09 (2026-10-05) -- Student widget w163 released (LATEST_STUDENT_WIDGET_APK 163): 🔊 spoken alerts (next class, tomorrow's first class, meal ready) for the test list on the staff app's 🎛 Global Switches page (DB2 davan_pub/tts_cfg, one tiny read per phone per hour). Pairs with admin v1740, staff widget w204.
VERSION : v11.08 (2026-10-05) -- Saving the News sources (News & Rates tab) now merges into widgetConfig/newsSourceConfig instead of replacing it, so the currency list picked on the staff app's 💱 page (widgetConfig/newsSourceConfig/fxList, fxCatalog) is kept. No new reads. Pairs with admin v1739, fetch_news v1.6.2. Function: wcSaveNewsSourceConfig.
VERSION : v11.07 (2026-10-04) -- User: teacher photo wherever a subject shows. The internal exam timetable now shows the student's own teacher with photo under each subject (timetable, attendance, internal marks, lesson plan, notifications and class feedback already did; past results keep no teacher). No new reads. LATEST_STUDENT_WIDGET_APK 162. Pairs with admin v1737, student widget w162. Functions: stuFacForSubjName (new), intRenderTable.
VERSION : v11.06 (2026-10-04) -- User: ABHISHEK's preview notifications were in V NEESHA's list, and teacher photos were still missing. Notifications whose title starts with 👤 (a widget opened "as" another student - admin preview) are removed from the list (deleted like last week's); teacher photos now also show for the older 8 pm format (lines starting with "|", teachers indented with tabs). Data: davan_pub/student_notif_log/{urn} (deletes the 👤 entries). LATEST_STUDENT_WIDGET_APK 161. Pairs with admin v1736, student widget w161. Functions: stuLoadWidgetNotifs, stuNotifBodyHtml.
VERSION : v11.05 (2026-10-04) -- LATEST_STUDENT_WIDGET_APK 160: the widget sends tomorrow's classes every evening at 8 pm (Sunday too, no more 6 pm). No change in the app. Pairs with admin v1735, student widget w160.
VERSION : v11.04 (2026-10-04) -- User: the notification list should show the faculty photo for every subject. Each teacher in a notification (in brackets after a numbered class, or on the line under it) shows with their photo (davan_pub/faculty_photos, already loaded). LATEST_STUDENT_WIDGET_APK 159 (8 pm catch-up). No new reads. Pairs with admin v1734, student widget w159. Functions: stuNotifBodyHtml (new), renderNotifLogPanel.
VERSION : v11.03 (2026-10-04) -- User: show the currencies picked by the admin (Thai baht and any others, with flags). The News & Rates tab lists the news job's fx list (fetch_news v1.6.0) instead of only USD / AED. No new reads. LATEST_STUDENT_WIDGET_APK 158. Pairs with admin v1733, student widget w158, staff widget w202. Function: wcLoadRates.
VERSION : v11.02 (2026-10-04) -- User: weekly class feedback, compulsory, to help faculty improve before the semester ends. From Sat 10 Oct, every Saturday 11 am a round opens (open till Friday); after login the app shows only the form until it is sent: per subject the teacher's photo and name, the topics handled that week (lesson plan), understood 👍/🤔/👎 and ⭐ 1-5 (required), a few words (optional). An unanswered last week comes first (max 2 weeks). Today's classes stay visible. Data: davan_pub/class_fb/{week}/{URN} (one write per student per week), davan_pub/class_fb_done/{week}/{URN}, reads davan_pub/class_fb_cfg (tiny). Pairs with admin v1732, student widget w157, staff widget w201. Functions: cfbMaybeShow, cfbPending, cfbSubjects, cfbFaculty, cfbTopics, cfbRender, cfbSend.
VERSION : v11.01 (2026-10-04) -- User: the widget's gold rate was far below the Indian rates seen elsewhere (it was the world spot price in rupees). The news job now writes India's IBJA rates (before 3% GST and making) plus 18K gold and the Dubai dirham, and says which day the rates are from (IBJA publishes nothing on Sat/Sun and Govt holidays). The News & Rates tab shows them as a table with the "as of" day, the market-closed note and the currency day; LATEST_STUDENT_WIDGET_APK 156. Data: widgetConfig/news gains gold18Rate, aedInrRate, ratesSource, goldSilverSession, ratesAsOfText, ratesNote, fxAsOfText (no extra reads). Pairs with fetch_news.js v1.5.0, student widget w156, staff widget w200, admin v1731. Function: wcLoadRates.
VERSION : v11.00 (2026-10-04) -- Student widget w155 released (LATEST_STUDENT_WIDGET_APK 155): the weekend card's Monday list shows each class with the teacher's photo. Pairs with staff app v1730.
VERSION : v10.99 (2026-10-04) -- Student widget w154 released (LATEST_STUDENT_WIDGET_APK 154): weekend card Monday list without "<br><small>", footer "© Built by Davan". Pairs with staff app v1728.
VERSION : v10.98 (2026-10-03) -- Student widget w153 released (LATEST_STUDENT_WIDGET_APK 153): every widget notification shows the student's own photo (or initials) instead of the college logo. Pairs with staff app v1727.
VERSION : v10.97 (2026-10-03) -- User: the DB2 usage copy was cut off when pasted, and cut the big reads. (1) The usage Copy merges per-item paths (lessonPlan/<KEY>, student_widget_active/<CODE>, rooms ...), lists the top 40 and one line for the rest, sizes in whole bytes. (2) davan_pub/student_widget_pair_log (~290 KB, read whole 18 times a day) is read as the newest 500 rows through stuPairLogLast with a 10-minute copy shared by the Maintenance logs and the Widget tab. Student widget w152 released (LATEST_STUDENT_WIDGET_APK 152). Pairs with staff app v1725. Functions: stuUsageReportText, stuPairLogLast (new), renderMaintLogs, the Widget tab loaders.
VERSION : v10.96 (2026-10-03) -- User: still the gold ring. stuLoaderSync shared its stamp ('dv_boot_synced_at') with the staff app on the same website, and ran only after a student login. Own stamp ('dv_boot_synced_at_portal'), runs on every open (anonymous sign-in) and on return to the screen, and switches a still-showing opening screen at once. Pairs with staff app v1722. Function: stuLoaderSync.
VERSION : v10.95 (2026-10-03) -- Device report: the phone model no longer takes the language token some older Android browsers send ("en-gb"). Pairs with staff app v1720. Function: dvDeviceInfo.
VERSION : v10.94 (2026-10-03) -- User: device report (no lock). The usage write students already make (davan_pub/usage/<date>/<URN>) carries .dev: os, the real Android version (Chrome client hints), model, RAM, cores, browser, home-screen app - no extra write; the staff app's Admin Settings shows the report. Student widget w151 released (LATEST_STUDENT_WIDGET_APK 151): Follow Davan strip on top of page 1, "did you follow?" right after the tap. Pairs with staff app v1718. Functions: dvDeviceInfo (new), usageFlush.
VERSION : v10.93 (2026-10-03) -- User: Saturday and Sunday are holidays for degree classes. Working-day counts (semester note, teaching days done / left, timetable note) leave out Saturdays unless the degree calendar has a working day, exam, internal or VACC on that Saturday. Student widget w150 released (LATEST_STUDENT_WIDGET_APK 150): weekend card, Friday / Sunday 6 PM notices. No data change. Pairs with staff app v1715. Functions: stuWorkingSatSet, stuSatOff (new), stuCountHolidays, stuCountNonTeaching, stuTeachingDaysLine, the semester note, stuInjectTimetableStartNote.
VERSION : v10.92 (2026-10-03) -- User: the new opening animation did not reach phones. stuLoaderSync read davan_pub/app_loader once per session (never again while the installed app stayed in the background); now when 10 min have passed and each time the app comes back to the screen (tiny DB2 read, at most every 10 min). Pairs with staff app v1707.
VERSION : v10.91 (2026-10-03) -- Student widget w149 released (LATEST_STUDENT_WIDGET_APK 149): it checks for a new version every hour (GitHub file, no Firebase cost), retries a failed update download every hour and shows a waiting Install again every 3 hours. Pairs with staff app v1706.
VERSION : v10.90 (2026-10-03) -- User: show when an old widget last reported. The Widget tab's "⛔ old w101 · blocked, must update" adds "· last report 2 h 15 min ago"; every "ago" in the tab now shows hours and days in full ("3 days 4 h ago", not "3 d ago"). No data change. Functions: wcAgoLabel, the Widget tab list.
VERSION : v10.89 (2026-10-03) -- Student widget w148 released (LATEST_STUDENT_WIDGET_APK 148): the widget's update line shows both versions (w148 → w149). Pairs with staff app v1705.
VERSION : v10.88 (2026-10-03) -- Student widget w147 released (LATEST_STUDENT_WIDGET_APK 147): the admin's page 2 shows installed widgets split into new and old; the update line shows the version on the phone. Pairs with staff app v1704.
VERSION : v10.87 (2026-10-03) -- Student widget w146 released (LATEST_STUDENT_WIDGET_APK 146): the admin's page 2 shows the tapped student's photo and details again above the Widget check. Pairs with staff app v1702.
VERSION : v10.86 (2026-10-03) -- Student widget w145 released (LATEST_STUDENT_WIDGET_APK 145): on the admin's page 2 a tap only shows the student's Widget check; a button opens their widget; permissions are numbered, one per line. Pairs with staff app v1700.
VERSION : v10.85 (2026-10-03) -- Student widget w144 released (LATEST_STUDENT_WIDGET_APK 144): picking a student on the admin's page 2 also sends a preview of their class reminder and subject attendance, labelled with their name. Pairs with staff app v1697.
VERSION : v10.84 (2026-10-03) -- Student widget w143 released (LATEST_STUDENT_WIDGET_APK 143): the admin's page 2 sends a test notification on pick and then that student's notifications (labelled with the name), and shows when the list was sent. Pairs with staff app v1696.
VERSION : v10.83 (2026-10-03) -- Student widget w142 released (LATEST_STUDENT_WIDGET_APK 142): the permissions show on the widget itself (✅ / ❌ TAP HERE per line); a red line opens that phone setting; the widget stays locked until all are given. Pairs with staff app v1695.
VERSION : v10.82 (2026-10-03) -- Student widget w141 released (LATEST_STUDENT_WIDGET_APK 141): page 2 (admin) marks each student's widget (📲 version ✓ / ⬆, 🔐 setup, ⛔ old), adds a 'Widget installed' view and a Widget check for the picked student. Pairs with staff app v1693.
VERSION : v10.81 (2026-10-03) -- Student widget w140 released (LATEST_STUDENT_WIDGET_APK 140): all permissions in one block with Fix buttons; the widget stays locked with a red Finish setup card until the Must ones are given (chosen by the Super Admin in the staff app). The Widget tab shows '🔐 setup not finished · n missing'. Pairs with staff app v1691.
VERSION : v10.80 (2026-10-03) -- Old student widgets (below w108) are blocked: LATEST_STUDENT_WIDGET_APK.minApkVersion 106 -> 108 (they show 'update required', no data); the Widget tab marks them '⛔ old · blocked, must update'. Pairs with staff app v1689 (which also enforces minApkVersion 108).
VERSION : v10.79 (2026-10-03) -- Student widget w139 released (LATEST_STUDENT_WIDGET_APK 139): birthday wishes follow one global switch set by the Super Admin in the staff app (davan_pub/widget_flags); the per-phone switch is gone. Pairs with staff app v1683.
VERSION : v10.78 (2026-10-02) -- Student widget w138 released (LATEST_STUDENT_WIDGET_APK 138): birthday wishes (7-day countdown, the wish, a late wish) at a different time each day between 8 am and 12 noon, with student wording; replaces the fixed 8 am wish. Pairs with staff app v1675.
VERSION : v10.77 (2026-10-02) -- Student widget w137 released (LATEST_STUDENT_WIDGET_APK 137): the Page 1 button on page 2 brings the widget back to the student you logged in as, and page 1 shows a Back to ... button while viewing someone else. Pairs with staff app v1672.
VERSION : v10.76 (2026-10-02) -- Student widget w136 released (LATEST_STUDENT_WIDGET_APK 136): a teacher photo changed in the staff app is downloaded again (Dr. Shilpa R Y), and the Kannada / Hindi card shows only real photos (no half-cut initials over Kotrappa K). Pairs with staff app v1671.
VERSION : v10.75 (2026-10-02) -- User: page 2 "Open as" still fell back to V NEESHA - the link was refreshed without the admin mark. stuPairPayload: adm:true from the admin view, adm:false only on a real student-password sign-in (_freshLogin), nothing on a refresh (the widget keeps its last state). Student widget w135 released (LATEST_STUDENT_WIDGET_APK 135). Pairs with staff app v1670. Functions: stuPairPayload.
VERSION : v10.74 (2026-10-02) -- Student widget w134 released (LATEST_STUDENT_WIDGET_APK 134): page 2's Now showing box has the student's photo, URN, phone, Call and Copy. Pairs with staff app v1669 / staff widget w172.
VERSION : v10.73 (2026-10-02) -- Student widget w133 released (LATEST_STUDENT_WIDGET_APK 133): it also reads student-widget-version.json on GitHub, so it updates itself (auto download + install) even when no admin opens the staff app. Pairs with staff app v1668.
VERSION : v10.72 (2026-10-02) -- Student widget w132 released (LATEST_STUDENT_WIDGET_APK 132): page 2 has a "Page 1 - widget settings" button back to page 1. Pairs with staff app v1667 / staff widget w171.
VERSION : v10.71 (2026-10-02) -- Student widget w131 released (LATEST_STUDENT_WIDGET_APK 131): page 2 "Open as" shows student photos once 2+ letters are typed and 20 or fewer match (davan_student_photos/<URN> link + Cloudinary thumbnail, ~0.1 MB per search). Pairs with staff app v1666.
VERSION : v10.70 (2026-10-02) -- Student widget w130 released (LATEST_STUDENT_WIDGET_APK 130): page 2 "Open as" shows each student's URN + phone with Call / Copy, saves the choice at once (the widget stayed on the linked student) and has a check line with Copy. Pairs with staff app v1665 / staff widget w170.
VERSION : v10.69 (2026-10-02) -- User: on the admin's phone the student widget follows the login - a student's own password links it to that student (no adm flag, so no page 2 in the widget settings app); the master password (admin view) links with adm:true = page 2 "Open as" + Back to me. The v10.67 refusal of EMTH7Q is removed. Pairs with staff app v1664. Functions: pairing write, manual code entry.
VERSION : v10.68 (2026-10-02) -- A widget linked from the admin view (master password) is marked adm:true in davan_pub/student_widget_active/<code>, so the admin's student widget w129 (released, LATEST_STUDENT_WIDGET_APK 129) shows page 2 "Open as" in its settings app on any phone: search any student and see their widget (kept on that phone, nothing re-linked). Pairs with staff app v1662 / staff widget w169. Functions: stuPairPayload.
VERSION : v10.67 (2026-10-02) -- User: the admin's own widget code must never be taken by any student, now or later. The auto-link on login and the typed-code link both refuse ADMIN_PHONE codes (EMTH7Q) unless it is the admin view, and log the refusal in davan_pub/student_widget_pair_log. Pairs with staff app v1660 (S-7UP47U). Functions: isAdminWidgetCode guard in the pairing write and the manual code entry.
VERSION : v10.66 (2026-10-02) -- Labs are 2 hours (user): back-to-back periods of the same lab code are one row running straight on, e.g. 10.30 to 12.30, no 15-min break - in the Timetable page and the Now / Next card. Pairs with staff app v1659. Functions: stuMergeLabRows, _stuNowNextRowsForDate, timetable panel.
VERSION : v10.65 (2026-10-02) -- Student widget w128 released (LATEST_STUDENT_WIDGET_APK 128): a 2-hour lab (two back-to-back lab periods of the same subject) is one card running straight on, e.g. 10:30-12:30, no 15-min break (user). Pairs with staff app v1658 / staff widget w168.
VERSION : v10.64 (2026-10-02) -- Student widget w127 released (LATEST_STUDENT_WIDGET_APK 127): the Attendance page shows every teacher's photo (only today's / tomorrow's teachers had one, so e.g. Priyanka V stayed as initials). Pairs with staff app v1649.
VERSION : v10.63 (2026-10-02) -- Kannada / Hindi: a language period shows both - "Kannada / Hindi" and both teachers - in Today's timetable and the Now / Next card, whether combined, split by students or only one in the timetable (user). Lesson plan and attendance still use the allocation's own subject. Pairs with staff app v1646 and student widget w126. Functions: stuLangPair, _stuNowNextResolveRow, timetable panel render.
VERSION : v10.62 (2026-10-02) -- User: the Paired box said 76 but the sentence said 47, earlier it was 83. Two bugs: (1) the student list had an old 50-row cap, so the sentence counted at most 50 (minus the admin phone) - the cap is removed, the list now holds everyone the box counts; (2) v10.59 left out every URN the admin phone was EVER linked to (test logins), which removed real students who now have their own widget - now only the URN it is linked to right now is left out; download taps still leave out test-login URNs whose student has no widget of their own. Functions: wcAdminUrnSet, wcAdminDlUrn (new), renderWcTable, renderWcSummary.
VERSION : v10.61 (2026-10-02) -- Admin → Widget tab: the summary box above the student list is removed (the boxes on top stay as they are). Tapping a box shows one sentence for it above the list - e.g. "Paired: 76 out of 413 students have the widget linked (18%) - listed below" - and the list shows exactly those students with Sl No. The count boxes moved down to sit right above the list (under the search). Your phone is not counted and not listed (it has its own box). Functions: renderWcTable, Widget tab layout.
VERSION : v10.60 (2026-10-02) -- Admin → Widget tab: the boxes on top and the summary above the list now use ONE counter (wcCounts), so the same rule gives the same number (the list summary's "Reminders OK" used a different rule from "Reminders dead"). The list summary adds sentences "Banned: 0 out of 421 students (0%)" for every count and says whether filters are applied - the boxes count all live students, the list summary only the students shown. Functions: wcCounts (new), renderWcSummary, renderWcTable.
VERSION : v10.59 (2026-10-02) -- Admin → Widget tab: the admin's own phone (ADMIN_PHONE, Moto Edge 50 Pro, widget EMTH7Q) is left out of every count box, the download taps and the list summary, and gets its own 👑 MY PHONE box: widget code, version (latest or not), which URN it is linked to, last report, reminders state, and its own download taps. Admin URNs = the URN its widget code is linked to now + every URN the pair log shows it linked to. No extra reads. Functions: wcAdminUrnSet, wcIsAdminUrn (new), renderWcSummary, renderWcTable, widget data loader (_wcAdminPairUrns).
VERSION : v10.58 (2026-10-02) -- Admin → Widget tab: the student widget list now has a title (how many shown, class, filter) and a summary row (paired, up to date, outdated, reminders OK, notifications off, battery restricted, stale, never reported, banned) on top, and a Sl No on every student. Uses the data already loaded - no extra reads. Functions: renderWcTable.
VERSION : v10.57 (2026-10-02) -- User: on refresh the app logged out and then logged in again. A remembered session re-opens in the background (portal_students read, then goToDashboard), and the login screen showed meanwhile. Now the login screen is hidden behind "Opening your dashboard…" until the next screen shows (15 s safety). The "logs in as soon as URN and password are filled" is the phone's saved-password autofill submitting the form (Chrome on Android), not the app. Functions: stuRestoringUI (new), restoreSession, showScreen.
VERSION : v10.56 (2026-10-02) -- Storage guard (same as admin v1621): the college pages share one ~5 MB browser storage; when full, sign-in could not be saved ("exceeded the quota", logged out after refresh). setItem now drops the largest saved copies (never sign-in / remember / widget keys) and retries; trims at start-up over 4 M characters. Functions: storage guard (new inline script in <head>).
VERSION : v10.55 (2026-10-02) -- Lab and theory lesson plans no longer mixed: "Analysis and Design of Algorithm" (theory) could take the "...using Python Lab" plan because its name contains the theory name, and the Today / Tomorrow summary removed "Lab" so labs always took the theory plan. stuGetLPForSubject now tries plans of the same kind first (any kind only when none matches); resolveDayLP keeps "Lab". Student widget w125 released live with the same fix (LATEST_STUDENT_WIDGET_APK = w125). Pairs with admin v1617. Functions: stuGetLPForSubject, resolveDayLP.
VERSION : v10.54 (2026-10-02) -- Student widget w124 released live: page 2 shows IA-1 marks (as the mockup table) even with no internal exam scheduled; marks stored as text, half marks or AB are read like this app reads them (w123 skipped them and showed "No internal exam"). The countdown and exam timetable appear when the next internal is scheduled. LATEST_STUDENT_WIDGET_APK = w124. Pairs with admin v1608. Functions: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.53 (2026-10-02) -- Student widget w123 released live: page 3 results, IA marks, internal timetable and calendar as numbered, aligned tables (Sl No | name | value | badge), as in the pages 2-3 mockup; class and attendance cards numbered. LATEST_STUDENT_WIDGET_APK = w123. Pairs with admin v1607. Functions: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.52 (2026-10-02) -- The college logo address carries ?v=1601 so phones show the restored original GIF at once instead of a saved copy of the lighter one (admin v1601/v1602). No data change.
VERSION : v10.51 (2026-10-01) -- The 🏨 hostel-name marker walked the whole page in one go (in the staff app it caused 15-49 s freezes, found by a local CPU profile, admin v1600). Here it now checks the text length before any work and runs in small idle slices, so it can never block the phone. Display only, no data change. Pairs with admin v1600. Functions: the 🏨 marker (tag, pump, check, set).
VERSION : v10.50 (2026-10-01) -- DB2 quota (283 of 300 MB on 01-Oct). (1) Widgets older than w106 read the full results (1.6 MB) and lesson plan (650 KB) files, ~130 MB/day: the published minimum widget version is now never below 106, so they stop all reads and show Update needed (STU_MIN_WIDGET_FLOOR). (2) allocation_each, internals_current, timetable_portal, ia_live_status, allocations and calendar (~90 MB/day) are kept on the phone (localStorage pv_*) and read again only when davan_pub/pub_ver/<key> (staff app v1590 / this app's timetable sync), davan_pub/data_versions/<node> (sync script) or davan_meta moves, with a 12-24 h maximum age; 5 tiny reads per open instead. Pairs with admin v1590. Functions: stuPubVers, stuPvGet (new), stuIaLive, the dashboard loader, the internals loaders, stuResolveLatestWidgetApk, wcBulkPublishLatestSoft.
VERSION : v10.49 (2026-10-01) -- Student widget w122 released live: widget page 3 shows the student's university results as in the pages 2-3 mockup (SGPA, passed/class, total, rank, subject marks with grades, centums, backlogs, SGPA so far + CGPA) and notifies when a new semester result is out; every card opens the Report Card tab. The widget reads controls/global/resultsSliceVer each refresh and its own davan_pub/results_by_urn/<URN> only when it changed (never the full results file). Pairs with widget w122 and admin v1589. Functions: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.48 (2026-10-01) -- Student widget w121 released live: fixed text sizes (no longer grow with the phone's font setting), slimmer edges, one-line weather/screen-time and quote, class time and ✓ kept together, and a corrected screen time (w120 could count an app as open since morning). LATEST_STUDENT_WIDGET_APK = w121 (Davan.Student.apk on main); davan_pub/student_widget_latest is raised on the next open (1 write). Pairs with widget w121 and admin v1584. Functions: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.47 (2026-10-01) -- User: the downloaded APK should carry its version. The login-page and Get App download buttons now save it as Davan_Student_w<version>.apk (the same name the widget's own updates use). Note: the widget deletes only old update files it downloaded itself; Android does not let it delete files the browser saved. No database change. Functions: renderGetAppPanel.
VERSION : v10.46 (2026-10-01) -- Bug: Download buttons still opened a blank github.com page instead of downloading. The login-page Download APK, the Get App tab button and the hostel-staff widget button now link the APK on the app's own site (GitHub Pages, same file on main) with a download link, so the phone saves it straight away. Widgets keep their own update link. No database change. Functions: stuLoginApkTap, renderGetAppPanel.
VERSION : v10.45 (2026-10-01) -- Bug: the login page's "Download APK" button (Install Widget App box) did nothing in the installed app because it opened in the same window. It now opens the direct file link (raw.githubusercontent.com, no redirect) in a new tab, falls back to the same window if blocked, copies the link and shows it under the button. No database change. Functions: stuLoginApkTap.
VERSION : v10.44 (2026-10-01) -- Bug: w120 was released but the Widget Control tab still said w119 was latest, because davan_pub/student_widget_latest is only written when a student opens the new portal. Opening Widget Control now publishes the version in this file when the node is lower, and the publish is raise-only (it never puts an older version over a newer one). Data: davan_pub/student_widget_latest (1 extra small read per publish, 1 write only when behind). Pairs with widget w120. Functions: stuPublishLatestWidgetApk, loadWidgetCtrlData.
VERSION : v10.43 (2026-10-01) -- User: release w120 to all students. LATEST_STUDENT_WIDGET_APK = w120 (Davan.Student.apk on main), published to davan_pub/student_widget_latest (1 write, as before); widgets update themselves. w120 fixes a page showing another page's cards after switching pages (page name and content different). Pairs with widget w120. Functions: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.42 (2026-10-01) -- User: one Davan Staff widget for all staff. The hostel staff card now says "Davan Staff widget" and downloads DavanWidget.apk (w140) instead of the retired Davan Hostel Staff app. No database change. Pairs with admin v1571 and widget w140. Functions: hoWidgetNow (card text), stuPairByCode / hoPairWidget messages.
VERSION : v10.41 (2026-10-01) -- User: resident staff should get the staff widget. Hostel logins as staff or resident staff now see a "Davan Hostel Staff widget" card with the download link and the three steps (the student-widget card stays hidden for them). No database change. Pairs with admin v1570 and staff widget s09. Functions: hoWidgetNow.
VERSION : v10.40 (2026-10-01) -- User: release w119 to all students. LATEST_STUDENT_WIDGET_APK = w119 (Davan.Student.apk on main), published to davan_pub/student_widget_latest (1 write, as before); widgets update themselves. w119: page 3 opens the Report Card, horoscope split into parts, "installing" and "updated" shown on the widget. Pairs with widget w119. Functions: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.39 (2026-10-01) -- User: page 3 of the widget should open the Report Card. A link with ?wtab=reportcard (also attendance / internals / timetable) opens that tab once the dashboard loads, then the parameter is removed. No database change. Pairs with widget w119. Functions: goToDashboardInner.
VERSION : v10.38 (2026-10-01) -- User: release the new widget to all students. LATEST_STUDENT_WIDGET_APK = w118 (Davan.Student.apk on main); it is published to davan_pub/student_widget_latest (1 write, as before) and students' widgets download it themselves. w118 adds the "new widget" strip on top of every page (available / downloading % / ready to install) on top of w116-w117 (live refresh steps, download progress into Downloads keeping only the newest file, tappable page numbers, news emojis). Pairs with widget w118. Functions: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.37 (2026-10-01) -- User: staff must never link the student widget again (the w107-era connection). Hostel logins as staff or resident staff cannot link it (automatic link, typed code and the "My widget" card are all blocked or hidden), and a widget still linked to them is freed once on their next login (1 read, 1 delete only when it is theirs, logged as staff-unlink in student_widget_pair_log). Guests are unchanged. Pairs with admin v1569. Functions: stuStaffNoWidget (new), stuCompleteWidgetPairing, stuPairByCode, hoWidgetNow, hoPairWidget.
VERSION : v10.36 (2026-10-01) -- User: go live with the new widget for all students without GitHub Releases. LATEST_STUDENT_WIDGET_APK = w115 from raw/main/Davan.Student.apk (students' widgets update themselves); the Install Widget download link points there too; the published version is no longer raised from phone self-reports (test phones report test builds). Widget tab: Follow Davan switches (controls/global followNudge / followNotify / followRecheck) and "Show who follows" (reads davan_pub/follow once per tap). Pairs with widget w115, admin v1567. Functions: wcLoadFollowFlags, wcSaveFollowFlag, wcLoadFollowStats (new), stuResolveLatestWidgetApk, wcLoadNewsControl.
VERSION : v10.35 (2026-10-01) -- User: wants the admin's own phone (Motorola Edge 50 Pro) highlighted wherever it appears in the logs. The phone is recognised by its widget code (EMTH7Q, ADMIN_PHONE); browsers that logged in with that widget are saved once as "Admin phone" (gold) in davan_pub/pair_devices, so the login log, pair log and the widget health list show a gold "👑 ADMIN PHONE" highlight. A few bytes written once per browser. Pairs with admin v1566. Functions: isAdminWidgetCode (new), renderMaintLogs, wcDeviceLine and the widget list card.
VERSION : v10.34 (2026-10-01) -- User: wants to see at a glance that the widget is linked. A "📱 Widget linked" badge sits in the top bar whenever this phone's widget is linked to the logged-in student (green = the widget reported in the last 24 h, amber = linked but quiet); tap shows the code and last-seen time. One small read of davan_pub/student_widget_report/<code>/ts per sidebar refresh. Functions: stuPaintWidgetBadge, stuWidgetBadgeTap (new), stuApplySidebarWidgetStatus.
VERSION : v10.33 (2026-10-01) -- User: no way to check gold/silver rates and why the widgets showed none. The News & Rates tab now shows gold 24K/22K, silver 10 g/kg and USD/INR exactly as the widgets get them, the last news run time, the day the rates were fetched, and the reason when they are missing (the news job could not reach goldprice.dev; fixed in fetch_news.js v1.4.1, which retries and keeps the last good rates). One db3 read of widgetConfig/news per tab open. Pairs with fetch_news.js v1.4.1, student widget w113, staff widget s07. Function: wcLoadRates (new), wcLoadNewsControl.
VERSION : v10.32 (2026-09-30) -- User: PWAs cross-connected ("already installed", one app opening another). The portal now registers its own page-only worker (app-sw.js, scope student_portal.html) instead of the staff app's sw.js, and the missing icon-student_portal-maskable-512.png its manifest points to now exists (a missing icon can make Chrome create a plain shortcut instead of an installed app). No data change. Pairs with admin v1562 and the other apps' PWA fix. Function: registerSW.
VERSION : v10.31 (2026-09-30) -- The new staff widget app (Davan Hostel Staff) uses codes like S-7K2QMA. The student app never links such a code, so a student login can never take a staff widget, and the other way round (the staff app only links S- codes). Pairs with admin v1558 and staff widget s01. Function: stuCompleteWidgetPairing.
VERSION : v10.30 (2026-09-30) -- Hostel logins (staff, resident staff, guests) now send their phone number and login name with the widget link, so widget w108 can show "📞 phone" and "Login: <name>" in its header (user request). Data: davan_pub/student_widget_active/{code} gains phone / login (a few bytes). Pairs with admin v1557. Functions: hoLogin, hoStart, stuPairPayload.
VERSION : v10.29 (2026-09-30) -- DB2 usage report: the "did this phone hold this widget before?" check (used when a login moves a widget) read the latest 400 pair-log rows (about 216 KB, 5.9 MB on one day); 100 rows are plenty, so it now reads 100 (about a quarter). Data: davan_pub/student_widget_pair_log, fewer bytes per read, no new writes. Pairs with admin v1555. Function: stuBrowserHeldCode.
VERSION : v10.28 (2026-09-30) -- Hostel students now show 🏨 before their name on every screen (user request, so hostel students stand out). A small script at the end of the page reads DB4 hostel/residents (names of active residents) once, caches it 6 h in localStorage (1 read per device per 6 h), and tags any text that is exactly a resident's name; no data is changed. Pairs with admin v1550, portal v10.28, PUC v5.223, faculty v2.4.
VERSION : v10.27 (2026-09-30) -- User: first-year widgets showed no "F/o <father> · <phone>" (no university results yet, many logins without a phone); fix the data, not the widget. Student Logins has a "📋 Copy phone & parents to logins" button: fills ONLY missing fields on davan_pub/portal_students/<URN> - phone from the student record (davan_pub/students), fatherName / motherName from the admin's manual parent names (davan_pub/parent_overrides) - after a confirm showing the counts; existing values and passwords are never changed. The widget (w106) already reads phone / fatherName from the login record, so no widget update is needed. Data: one multi-path write (a few bytes per student). Tested in Chromium with a faked database. Function: stuCopyHeaderData (new).
VERSION : v10.26 (2026-09-30) -- Diagnosis aid (user report: the widget still would not move from HARSHITA): the 08:09 SAI M login on the widget's Chrome app wrote NO pair-log row, while v10.25 logs every attempt - so that phone was still running an older cached copy (the admin was checking v10.25 in Firefox). Student-login rows now show which app version the login ran (orange "(old)" when not the newest), the phone label / id and how it signed in, so an old copy is visible at once. Data: student_login_log rows gain v / login (a few bytes). Functions: stuLogLoginEvent, renderMaintLogs.
VERSION : v10.25 (2026-09-30) -- Widget pair log, user request: (1) name a phone: "👑 Mark this phone as mine" labels the admin's own phone "Admin phone" in gold (badge + gold bar on its rows); tap any phone id in the log to name it (other colour) or clear the name. (2) every pairing event now records WHY in plain words (linked because the widget was empty / moved because this phone held it before, and how that was known / refused because this phone never held it / admin OK or Cancel / freed by logout / admin Unlink), how the session signed in (student password / Hostel login / admin view / reopened app) and the app version; shown under each row. A takeover the admin cancels is no longer logged as a move. Data: davan_pub/pair_devices/{browserId} {label, color} (one small read when the log opens, a write only when naming); pair_log rows gain why / login / v (a few bytes each). Functions: stuNamePairDevice, stuLoginKind (new), stuLogPairEvent, stuBrowserHeldCode, stuCompleteWidgetPairing, stuPairByCode, stuClearWidgetPairing, stuAdminUnlinkWidget, renderMaintLogs.
VERSION : v10.24 (2026-09-30) -- Fix (user report: switching students on the admin's own phone no longer moved the widget; pair log showed "refused" for browser b3hbdoowd1f6h on EMTH7Q although that browser had linked it many times). The v8.38 same-phone rule looked up this browser's history with a pair-log query by code (orderBy="code"), which fails without a database index and finds nothing after the log's Clear button, so the app refused. Now the phone keeps its own list of widget codes it has linked or freed (localStorage davan_my_widget_codes, last 5) and, if that is empty, tries the indexed query and then the latest 400 pair-log rows. Rule unchanged: only a phone that held this widget before may move it between logins; a stranger's phone or link is still refused. Data: one extra read of up to 400 small log rows only when a move is checked and the phone has no local record. Tested on the real page with faked databases (6/6, incl. cleared log and a stranger's phone). Functions: stuBrowserHeldCode, stuMyWidgetCodes, stuRememberWidgetCode (new), stuCompleteWidgetPairing, stuPairByCode, stuClearWidgetPairing.
VERSION : v10.23 (2026-09-30) -- User: the master password is for testing any account freely; v10.22's block got in the way. Admin view (admin / master password on a student) works as before again - it may link, move and (on logout) free a widget - but it never changes the widget silently: before linking or moving it the app asks "Link this phone's widget to <student> for testing? OK / Cancel" (Cancel keeps it as it is; a real student login asks nothing). The takeover rules for a widget owned by someone else are unchanged. Logged as 'admin-test' in the pair log. Tested on the real page with faked databases: Cancel keeps / OK links / logout frees / the Director's widget kept on Cancel / student login unchanged (6/6), plus the 8/8 switching checks. Functions: stuCompleteWidgetPairing, stuPairByCode, stuClearWidgetPairing.
VERSION : v10.22 (2026-09-30) -- SAFETY FIX (user report: the Director's widget switched to a student overnight). Pair log: 29-Sep 11:25 pm a logout freed EMTH7Q, 11:29 pm a "fresh" login of HARSHITA R JAIN on the same phone linked it - an ADMIN VIEW (admin / master password on the student login) counted as the student's own sign-in (STATE._freshLogin) and linked the admin's own phone widget to that student. Old bug, not from the hostel work; takeover protection itself held (10:47 pm refused on another student's widget). An admin view now never links, moves or clears a widget (stuCompleteWidgetPairing, stuPairByCode, stuClearWidgetPairing all stop), also when the admin view was remembered (session keeps am). Tested on the real page with faked databases: admin view on an empty widget leaves it empty, admin view + logout keeps the student's widget, real student / Hostel logins still link (5/5), plus the earlier 8/8 switching checks. Functions: stuIsAdminView (new), stuCompleteWidgetPairing, stuPairByCode, stuClearWidgetPairing, loginStudent, doLogout, hoStart, session restore.
VERSION : v10.21 (2026-09-29) -- User: "Current students" said 421 while the cards say 404. It counted every login not passed out; now it counts only logins whose student is in this semester's class list (the same list the class cards use), so the two agree. Logins in no current class (not promoted, wrong URN, old record) get their own "⚠ Not in a current class (N)" group to check. Student photos in the Student Logins table open full size on tap (same zoom as elsewhere). Functions: stuLoginGroup, stuCurrentUrnSet (new), renderStudentTable, stuAvatarHtml.
VERSION : v10.20 (2026-09-29) -- Admin > Student Logins (user request): passed-out students are no longer mixed with current ones. New group dropdown: "Current students (N)" (default) and one "Passout <year> (N)" per year, newest first. Passout year = the end year of passoutAY for students marked passout by Promote & Archive ('2025-26' -> 2026), or, for a student still in Sem 6 while the current semester is odd, the current AY's start year (2026-27 -> 2026) - so next July (2027-28) that year's Sem 6 move to "Passout 2027" automatically, no manual step. New login filter: Everyone / Never logged in / Logged in, usable with any sort, in the list and in a class card's "with a login" group. No data change, no new reads. Functions: stuPassoutYear, stuLoginFilterOk (new), renderStudentTable.
VERSION : v10.19 (2026-09-29) -- Admin > Student Logins (user request): clicking a class card now shows the students WITHOUT a login on top and then everyone in that class WITH a login (was only the missing ones, an empty list once all were created). New sort dropdown next to All Classes: Last login newest (default) / oldest / never logged in first / Name A-Z / Z-A, shared with the Name and Last Login header clicks and used in both views. Phone column falls back to the student record (davan_pub/students phone / mobile, marked "(record)") when the login has no phone saved. No new reads. Functions: stuSetSort, stuSortRows, stuPhoneMap, stuLoginRowHtml (new), renderStudentTable.
VERSION : v10.18 (2026-09-29) -- Widget w106 released (GitHub release 106, Davan.Student.apk): LATEST_STUDENT_WIDGET_APK.apkVersion 101 -> 106 (minApkVersion unchanged at 55, soft nag only), so older widgets show UPDATE AVAILABLE. w106 = hostel logins on the widget (pages 6-8, staff Hostel today picture, own photo / initials), one-tap refresh after Log out, and own results / own lesson plan only (DB2 fix). Function: LATEST_STUDENT_WIDGET_APK.
VERSION : v10.17 (2026-09-29) -- User: the Director's password has letters (admin123) and the v10.16 number keyboard blocks them. The Hostel login password keeps the number keyboard by default and gets an "ABC letters keyboard" button (tap again for 123) that switches the keyboard and reopens it. No data change. Functions: hoKb (new); login screen HTML.
VERSION : v10.16 (2026-09-29) -- User requests: (1) the widget showed the last student's photo on a Hostel login: the pairing now carries the person's photo (Director = college logo, staff / resident staff = staff photo store as in the login preview, guest = their bed photo, read once at login), used by widget w103. (2) Hostel login on the login screen is a small text link ("Hostel staff / guest? Hostel login") instead of a big button. (3) Hostel password field opens the number keyboard (inputmode numeric). Data: pairing davan_pub/student_widget_active/{code}.photo; one small DB4 read of the guest's bed photo at a guest login. Pairs with widget w103. Functions: hoPhotoUrl (new), hoStart, stuPairPayload; login screen HTML.
VERSION : v10.15 (2026-09-29) -- User: "use the same principle for staff as for students". The Hostel login now follows exactly the student rule: the widget links only on a typed-password login (through the same stuCompleteWidgetPairing: an empty widget or your own), and only Log out frees it. Removed the v10.11 switch-release (a Hostel login freeing the student's widget and a student login freeing the staff one) and the reopen-with-widget-tap re-link. Tested on the real page with faked databases, 8/8: student login -> Log out -> Hostel login -> reopen (no change) -> Hostel Log out -> student login all move the widget as expected; a Hostel login or another student while SAI M is not logged out are refused. Data: none new. Functions: hoLogin, hoStart, loginStudent; stuReleaseWidgetFor removed.
VERSION : v10.14 (2026-09-29) -- User asked why the widget kept showing SAI M after a Hostel login as Sumithra. By design (v8.08 / v10.11): SAI M never logged out (closing the app is not a logout), so the widget stays his and the hostel login is refused. The hostel "My widget" card now names who still holds the widget and says to Log out that person on this phone or have the admin Unlink it. No rule change. Function: hoWidgetNow.
VERSION : v10.13 (2026-09-29) -- User could not find the v10.12 Unlink button (it sits in the Widget Pairing Health diagnostics). Admin > Activity log > Widget pairing changes now has "🔓 Unlink a widget" in its header and a "🔓 Unlink <code>" button on every refused row (e.g. EMTH7Q still held by ST_SUMITHRA_K_T, refusing SAI M). Same confirm + one delete + 'admin-unlink' log as v10.12. Functions: stuAdminUnlinkWidget (optional code), activity-log pairing rows.
VERSION : v10.12 (2026-09-29) -- User report "not working" after v10.11. Tested the real page in Chromium with both databases faked: student -> Hostel login -> reopen -> student login moves the widget each time; a widget still held by a hostel login (freed by no logout before v10.10) is refused for a student by design, and Hostel login + Log out frees it. Added so a stuck widget can always be fixed safely: Admin > Widget Pairing Health "Unlink ONE widget (by its code)" (shows who holds it, confirm, deletes that one pairing, logged 'admin-unlink'); the student's "widget belongs to" banner now names the person and says how to free it. No takeover rule changed. Data: davan_pub/student_widget_active/{code} (admin delete), student_widget_pair_log. Functions: stuAdminUnlinkWidget (new), stuCompleteWidgetPairing, stuRenderWidgetPairBanner.
VERSION : v10.11 (2026-09-29) -- SAFETY FIX, replaces the v10.08-v10.10 takeover exceptions (user: "keep it safe so they can't log in to some other student"). Those let a login take a widget owned by someone else (phone login list, hostel-owned widgets, staff typing a code) - the same kind of hole v8.08 / v8.38 closed. All removed: a login may again only create an empty pairing or refresh its own; typing a code still needs this browser's own pair history. Switching login on a phone now RELEASES the old login's own widget, exactly as its Log out would (only if that key still owns it), then the new login pairs the empty widget: Hostel login releases the remembered student, a student login releases the hostel session, Hostel Log out releases (v10.10). Hostel login pairs only on a real login or widget tap, not a bare reopen (v8.32 rule). Tested with the real functions on a fake database: student -> hostel -> student moves the widget; another student or staff without a logout is refused (auto and typed code); release by a non-owner does nothing. Data: davan_pub/student_widget_active/{code} (one delete on a switch), student_widget_pair_log 'switch-release'. Functions: stuReleaseWidgetFor (new), stuCompleteWidgetPairing, stuPairByCode, hoLogin, hoStart, hoWidgetNow, loginStudent.
VERSION : v10.10 (2026-09-29) -- Fix (user report: after switching back to the student login the widget stayed on Sumithra): the widget could move from a student to a hostel login but not back. The phone now keeps a short list of its own logins (localStorage davan_phone_users, last 6 student URNs / hostel keys) and the widget may move between any of them, both ways, even after a logout. A widget held by a hostel login also comes back to a student automatically when its code was remembered on that phone (not from a link), or by typing the code after a confirm. Hostel logout now unlinks the widget (as student logout already did). Data: davan_pub/student_widget_active/{code} (same read + write). Functions: stuPhoneUsers, stuPhoneUsed, stuPhoneAdd, stuCompleteWidgetPairing, stuPairByCode, hoLogin, hoStart, hoLogout, loginStudent.
VERSION : v10.09 (2026-09-29) -- Fix (user report: "Link widget" said the code belongs to another student): a staff or resident Hostel login may now move a widget linked to someone else after a confirm ("This widget is linked to SAI M - move it to you?"); guests still cannot take a linked widget. The My widget card now says when the widget is still linked to someone else. Data: davan_pub/student_widget_active/{code} (same one read + write). Functions: stuPairByCode, hoPairWidget, hoWidgetNow.
VERSION : v10.08 (2026-09-29) -- Fix (user report: widget stayed on the student after a hostel staff / guest login): the phone still remembered the student, so every reopen signed the student back in and re-paired the widget to them. A Hostel login now ends the remembered student session on that phone (and a student login ends a hostel session), and may take over the widget that student had on the same phone. The hostel screen gets a "My widget" card to link the widget by its code; manual linking now also sends the hostel fields. Data: davan_pub/student_widget_active/{code} (one write on link, no new reads). Pairs with widget w102. Functions: hoLogin, hoStart, hoWidgetNow, hoPairWidget, stuPairPayload, stuCompleteWidgetPairing, stuPairByCode, loginStudent.
VERSION : v10.07 (2026-09-29) -- Fix (user report: Hostel login opened an empty page): the hostel-only screen had no '.active' display rule, so it stayed hidden - added #screen-hostel-only.active. Staff (warden / hostel head / manager / principal / admin) now see a "Hostel today" card on top: next meal + expected, today's meals (had / didn't / no answer / stars), in hostel per hostel, on leave (names), waiting requests, guests, resident staff, cleaning, complaints, unread chats, and a link to the staff app. Staff who don't answer meal questions no longer see rating stars on the menu. Reads (only when staff open / refresh): residents, rooms, leave_out, leave_pending, cleaning/{today}, complaints_open, meal_log/{today}, skips/{today}, own chat inbox. Pairs with index.html v1546. Functions: hsStaffDashLoad, hsStaffDashHtml, hsStaffDashRefresh, hoStart, renderHostelPanel, hsMenuHtml (canRate).
VERSION : v10.06 (2026-09-29) -- Fix: Hostel login (Staff) said "Wrong password" for everyone - v10.05 read the staff database's login list, which this app's GOLDEN RULE guard blocks. Now the password is checked against a one-way hash in hostel/logins (DB4, written by index.html v1543), no staff database and no Firebase Auth call; the staff config was removed. If no hashes exist yet it says to ask the admin to open User Management once. Functions: hoHash, hoMatch, hoPreview, hoLogin.
VERSION : v10.05 (2026-09-29) -- Hostel login (Staff tab) is password only, like the staff app's faculty login: the password is matched in the staff app's login list (app_data/login_index, staff project), the person's photo and name show, and Open hostel signs in with Firebase Auth. Guests and wardens now also get "Did you have lunch?" (HS.hoFb). Widget pairing adds hoRole + staffUid; chat messages stamp every other member (staff too) for widget alerts. Pairs with index.html v1542 and widget w102. Functions: hoMatch, hoPreview, hoStaffApp, hoLogin, hoStart, hsFbApp, stuCompleteWidgetPairing, hsChatSend.
VERSION : v10.04 (2026-09-29) -- Chat contacts: only the staff the admin allows (hostel/config/chat_contacts; managers other than Lalitha hidden by default), with their photos from the staff photo store (davan_pub/faculty_photos, already used for teacher photos) and the college round logo for the Director. Phone More menu (bottom bar) now wraps onto more lines so Get Widget / Notif Log are no longer cut off. Pairs with index.html v1541. Functions: hsChatLoad; CSS .sbn-more-row / .sbn-more-btn / .sbn-more-drawer.
VERSION : v10.03 (2026-09-29) -- Meal stars no longer send on the first tap (a student who tapped 1 star could not give 4 or 5): tap to choose, the left half of a star gives half (e.g. 2.5), change freely, then Send; once sent it is locked. A 'Had it' answered on the widget (no stars yet) can still be rated here. Ratings may now be x.5 in canteen/ratings and meal_log.s (no extra reads or writes). Pairs with widget w102. Functions: hsStarsHtml, hsPick, hsGateHtml, hsMenuHtml, hsRate, hsAnswer.
VERSION : v10.02 (2026-09-29) -- Widget w102 chat alerts open the app on Hostel > Chat (?hs=chat deep link). No data change. Pairs with widget w102. Function: hsInit.
VERSION : v10.01 (2026-09-29) -- Hostel Chat tab (chat with each warden of your hostel, Hostel Head, Principal, Manager, Director and admin conferences; blue ticks; unread count). Hostel login on the login screen for resident staff, wardens / hostel head (staff app username + password, checked with Firebase Auth of the staff project) and guests (guest code): resident staff get the full Hostel page, others Menu + Notices (+ My Room for guests); session remembered; widget pairing marks hostelOnly for widget w102. Data: hostel/chat/*, hostel/logins, hostel/guest_pass (DB4); davan_pub/student_widget_active gains hostelOnly/hoKind/hostelId/dob. Pairs with index.html v1540. Functions: hoLogin, hoStart, hoLogout, hoBoot, hsChatLoad, hsChatHtml, hsChatOpen, hsChatSend, renderHostelPanel (tab list), hsFbApp, stuCompleteWidgetPairing.
VERSION : v10.00 (2026-09-29) -- Admin Hostel Students table (user request): serial number column, student photo (tap to zoom, same lightbox as the report card), and tapping the name opens the student card (ascOpen). Photo comes from the hostel record or bed, else davan_student_photos/{urn} via rcLoadPhoto (one small cached read per student shown, admin only). Functions: hsaRender, hsaLoad, hsaAvatar, hsaFillPhotos, hsaCard.
VERSION : v9.99 (2026-09-29) -- Faster first screen: the ~300 KB handoff + changelog comment in <head> moved to CHANGELOG-portal.md (every student downloaded it before anything showed; the file is now 1.88 MB, was 2.18 MB). meta charset is first in <head> again. Opening animation step text showed '&amp;' - fixed. No data or Firebase change.
VERSION : v9.98 (2026-09-29) -- OPENING ANIMATION + LEAVE: CHANGE OR CANCEL AFTER SENDING. (1) Opening animation (same as index.html v1537): the app's own animated screen replaces Android's still logo as soon as the first bytes arrive. To make that early, the manifest / meta / title tags were moved to the top of <head> and the animation sits right after them, above the long handoff / changelog comments (about 300 KB that used to be downloaded before anything could show). Style A / B / C comes from the admin (stuLoaderSync caches davan_pub/app_loader.portal for the next open). (2) Leave (user request: cancel, postpone, change dates or reason even after approval): Pending: Edit everything (stays pending) or Cancel. Approved, before leaving: Cancel leave (the warden is told by the WhatsApp preview), Edit reason only (stays approved, reasonEditedAt), Change dates / place / type -> Change requested: the old dates stay approved until the warden answers (index.html v1537), Undo possible. Out: Ask to extend return (new time + why) -> Extension asked, Undo possible. Rejected: Apply again fills the form with the old request. Every card has a History list. Each save re-reads that one leave first ("The warden already acted on it" if its state changed) and afterwards re-reads only that leave, not the whole hostel data. WhatsApp text for cancel / change / extension / edit. DATA: hostel/leave/{urn}/{id}: change {from,to,destination,type,at} | {to,ext:true,why,at}, reasonEditedAt, log/{k}: {at,by:'student',what}, status cancelled for an approved leave; hostel/leave_pending/{urn}_{id}: {hostelId, change:true} while a change waits (removed on undo / cancel). davan_pub/app_loader read once per session (a few bytes). Each change is one small multi-path write plus one small read of that leave. PAIRS WITH index.html v1537. Widget w101 unchanged. VERIFIED: Playwright: animation A/B/C paints and hides, manifest and viewport still in <head>, page errors identical to before. Leave cards rendered in node for pending / approved / change requested / out / extension asked / rejected and for each edit form (no undefined, correct buttons). Saving against the live database not run here. FILES (student_portal.html): dvBoot (opening animation block, moved above the head comments) 74; stuLoaderSync 7967; hsNowLocalIST 31980; hsLvReload 31982; hsLeaveHtml 32315; hsLeaveCard 32340; hsLvEdit 32381; hsLvAgain 32382; hsLvSave 32389; hsLvUndoChange 32433; hsCancelLeave 32462; hsLeaveWaText 32550; hsLeaveWa 32562; APP_VERSION 7679.
VERSION : v9.97 (2026-09-29) -- Menu: past days before the first menu plan started show no menu (the first plan was being shown for earlier days, e.g. in the previous-week view). Same fix as index.html v1535. FILES (student_portal.html): hsTplFor 31990.
VERSION : v9.96 (2026-09-29) -- DB2 METER, 4 leaks from the 28-Sep full copy. (1) results: a reopened portal draws the profile (parents' names -> rcLoadPrevResults) BEFORE the controls load, so rcSliceGv()/rcResultsVer() read '' and the FULL 1.5 MB davan_pub/results was downloaded (~30x/day). rcCtlVers() reads controls/global/resultsSliceVer + resultsVer directly (13 B each, once per page load) until the controls arrive; used by rcGetSlice and the rcCachedGet version path. (2) stuResolveLatestWidgetApk step 1 read EVERY student's davan_pub/student_widget_report (~170 KB) on every student open (292x = 48 MB/day); a signed-in student now skips it (built-in version + admin manual version + kill floor still apply); admin screens still scan. (3) stuLoadOwnLP: no lesson-plan entry for the class (Sem 2 / Sem 4 - none exist) threw -> full 637 KB on every open; now returns an empty plan (same as the full download after filtering). (4) davan_pub/ia_live_status/IA1+IA2 (~23 KB) read ~3x per open (banner + checks, 1,158/day); stuIaLive() shares one read per key per page load (10 min). Verified with mocks: results before controls -> own slice via the 13 B stamps (no full file); Sem2 lesson plan -> {} after one names read; 4 IA asks -> 2 downloads. FILES (student_portal.html): rcCtlVers 24598; rcGetSlice 24692; rcCachedGet version path 24597; stuResolveLatestWidgetApk student skip 7830; stuLoadOwnLP empty-class 18421; stuIaLive 22326; renderIAEligibilityBanner 22333; stuIsIneligibleForCurrentInternal read 23022.
VERSION : v9.95 (2026-09-29) -- APP VERSION GATE (same idea as index.html v1503): davan_pub/portal_build {min, v} = newest student app version anyone has opened (raised by that device, never lowered; a jump of more than 100 versions is ignored). A student on an older cached copy sees a red banner 'A newer version (v9.95) is available - updating now...' and the page reloads itself with a cache-busting ?b= (other link parameters kept), at most 2 tries per session; after that the banner asks to close the app completely and reopen. Checked after login and when the app comes back to the screen (at most every 10 min, one tiny read). An old copy also no longer overwrites the portal version the widgets show. FILES (student_portal.html): stuVerNum / stuBuildCheck 7939; stuBuildCheck 7941; stuPublishLatestWidgetApk (no older overwrite) 7982; dashboard call 10741.
VERSION : v9.94 (2026-09-29) -- Widget w101 released: LATEST_STUDENT_WIDGET_APK.apkVersion 93 -> 101 (minApkVersion unchanged at 55, soft nag only). w101 now reports its real version (was frozen at 93), so w101 phones read as up to date and older ones see UPDATE AVAILABLE. FILES (student_portal.html): LATEST_STUDENT_WIDGET_APK 7704.
VERSION : v9.93 (2026-09-29) -- STUDENT SWITCHES (index.html v1534 Hostel Settings > Student access & feedback, hostel/config/students): master Hostel & Canteen switch (OFF = no Hostel page / dashboard card, exceptions list flips it per student), Meal feedback switch (+exceptions), Ask in app tick, Lock until answered (OFF = question shown on top of the Hostel page, leave not blocked), 'What was wrong?' threshold. ANSWER ONCE: before saving an answer / rating / reason the row is re-read, so an answer given on the widget is never overwritten ('Already answered'); when the app comes back to the screen it re-reads today's meal_log (at most once a minute) so a widget answer clears the question here too. FILES (student_portal.html): hsSw / hsFbApp / hsLockOn / hsWhyBelow 32026; hsInit (master switch) 32019; hsLoad (HS.sw) 32029; hsPending 32076; hsAnswer (re-read first) 32197; hsWhySend (re-read first) 32274; renderHostelPanel (lock off) 32072; hsGateHtml 32292; hsSubmitLeave 32327; visibilitychange meal_log re-read 32526; hsRenderDashCard 32748.
VERSION : v9.92 (2026-09-29) -- LOW RATING -> 'WHAT WAS WRONG?': a meal rated 1-2 stars (below 2.5, incl. 'Had it: not good') shows a card on top of the Hostel page (and the dashboard card) with reason chips (salty, spicy, no taste, cold, not cooked, not fresh, oily, too little, not clean, other) + a note box; saved on canteen/meal_log/{date}/{urn}/{meal} as why:'cold,salty', note, whyAt. Snacks rated 1-2 also get a meal_log row. Same codes as widget w101 (?hs=why deep link). Admin v1533 shows the reasons. FILES (student_portal.html): HS_WHY / hsWhyPending / hsWhyToggle / hsWhyHtml 32254; hsWhySend 32274; hsRate (snacks low) 32145; hsAnswer 32197; renderHostelPanel (card on top) 32072; hsRenderDashCard 32748.
VERSION : v9.91 (2026-09-29) -- For widget w100: a new complaint, a reply and 'send to principal' also write hostel/complaints_stamp/{urn} (the widget re-reads the student's complaints only when it changes). Widget notification links ?hs=complaints|leave|notices open that Hostel tab. FILES (student_portal.html): hsSubmitComplaint (stamp) 32576; hsCmpReply (stamp) 32660; hsCmpEscalate (stamp) 32590; hsInit (?hs= deep links) 32019.
VERSION : v9.90 (2026-09-29) -- Hostel complaints chat: questions from the hostel office (index.html v1531 Chat with student, updates with ask:true) are highlighted, each open complaint has a reply box (hsCmpReply writes an update {role:'student', chat:true} and stamps complaints_open/{urn}_{id}/reply so the admin app alerts), and the Complaints tab shows how many need a reply. FILES (student_portal.html): hsCmpNeedsReply 32650; hsCmpReplyBox 32587; hsCmpReply 32660; hsCmpHtml 32569.
VERSION : v9.89 (2026-09-28) -- Timetable breaks: stuNormBreaks() accepts the mother app's list form [{class, items}] (v1497+, needed because 'I YEAR B.Com' cannot be an RTDB key) as well as the old {class: items}, so named breaks (Leisure 15m, Lunch 45m) show again between periods. Pairs with index.html v1517 (Push Timetable to Portal 400 fix).
VERSION : v9.88 (2026-09-28) -- CANTEEN MENU PLANS (pairs with index.html v1516): hostel menu now uses the dated menu (canteen/periods, From-To) or the regular menu version (canteen/defaults) for each date via hsTplFor(), falling back to canteen/template if those nodes cannot be read. Menu tab has a new Full week view (Mon-Sun) with Previous / Next week; specials and closures shown per day.
VERSION : v9.87 (2026-09-28) -- FIX: Sem 1 (and Sem 2) students were shown Sem III subjects in Lesson Plan. Confirmed on a real BCA Sem 1 login (K N AMRUTHA, U13DI26S0010): 20 cards incl. Computer Architecture, Internet Programming (+Lab), Java Programming (+Lab), PDTM and English/Hindi/Kannada twice. Cause: the sem check used ku.includes('SEM'+semRom) and 'SEMI' / 'SEMII' are inside 'SEMIII'. New _lpSemOk() compares the WHOLE sem token (regex SEM([IVX]+|digits) not followed by another roman/digit) with the student's sem (roman or number); used by filterLPForStudent (screen) and _lpKeyForClass (per-class download). Verified with the real 72 entry names: BCA Sem1 20 -> 11 (all SemI), BCom Sem1 16 -> 9, BBA Sem1 9 -> 9, all Sem III / Sem V classes unchanged, and the download list still matches the screen for every class. FILES (student_portal.html): _lpSemOk 18402; _lpKeyForClass sem check 18394; filterLPForStudent 18351 (sem check 18371).
VERSION : v9.86 (2026-09-28) -- PER-CLASS LESSON PLAN (biggest remaining DB2 cost: davan_pub/lessonPlan 631 KB, 72 entries named COURSE-SUBJECT-SEM-SECTION, downloaded whole by every student on every app open ~ 250 MB/day). stuLoadOwnLP(cls): reads only the entry names (shallow ~3 KB), keeps the ones matching the student's class with the SAME name rules as filterLPForStudent (_lpKeyForClass), reads each one's updated_at (bytes) and downloads an entry only if it is new or its updated_at changed; entries kept in localStorage davan_lp_own_v1. filterLPForStudent() still runs on the result, so students see exactly the same subjects. Any error / no matching name -> the old full download (never an empty lesson plan). Verified with the real 72 entry names (from the Copy lesson-plan names button) for Davan-BCA-Sem3-SecA, BCA-Sem5-SecB, BCom-Sem1-SecA, BBA-Sem5-SecA, BCA-Sem1-SecA: same subjects as the full download in every case; first open 49-160 KB (was 570-631 KB), reopen unchanged ~2 KB, one subject updated ~10 KB. PRE-EXISTING bug found by this test (kept unchanged here, FIXED in v9.87): the name rule also matched Sem III entries for Sem I / Sem II students. FILES (student_portal.html): _lpKeyForClass 18394; stuLoadOwnLP 18421; student loader call 18528.
VERSION : v9.85 (2026-09-28) -- Diagnostics: '📋 Copy lesson-plan names' button (admin asked, works from a phone - no F12). Copies ONLY the entry names of davan_pub/lessonPlan (shallow read), a count grouped by the first 4 name parts (e.g. Davan-BCA-Sem3-SecA), and the field names of 3 sample entries - no topics, no student data, a few KB. Purpose: check whether each class's entries share a name prefix, so students can later download only their own class (lesson plan = ~631 KB per student open, the biggest remaining DB2 cost). Nothing else changed. FILES (student_portal.html): button 27868; diagCopyLpNames 27917.
VERSION : v9.84 (2026-09-28) -- Data Usage page: '📋 Copy all' button on the DB2 Meter card copies EVERYTHING as text in one tap (to paste to Claude instead of copying from the screen): today / month / projection + settings, ALL paths for the selected day (not only the top 12) with reads, avg, total, %, ALL big reads, the last 30 days split per app, the switches that change usage (results published time, refresh stamp, Past Semesters on/off), then the existing per-student report (duBuildReport). Clipboard blocked -> the same select-and-copy box as the old report. FILES (student_portal.html): dbmRenderCard 32728 (DBM.last kept 32778, button 32787); stuUsageReportText 33027; stuCopyAllUsage 33004.
VERSION : v9.83 (2026-09-28) -- Publish report now names the portal version that ran it ('Published (portal v9.83)'): a press on a not-yet-refreshed v9.81 page showed '0 changed, 608 unchanged' and looked like v9.82 had run. The 'Last published' label now updates right after a press (it only changed on reload). FILES (student_portal.html): stuPublishResults 24671 (report + label 24716).
VERSION : v9.82 (2026-09-28) -- DB2 METER, from the live meter (results 47 reads x 1.5 MB, results_by_urn 20 x 36 KB, student_login_log 4 x 5.8 MB; archive stayed at 14 = the v9.79 fix works and phones run the new code). (1) ROOT CAUSE of the remaining results reads: rcGetSlice() fell back to the FULL 1.5 MB file for every student with no entry in results_ver - i.e. every first-year / anyone with no results yet - on EVERY open. Now Publish writes results_ver/_pub = the publish stamp; no entry + matching _pub = 'no results' (a few bytes once, then cached; zero reads after). _pub missing/different (node wiped) still falls back to the full file. (2) Smaller slices: a batch the student is not in keeps only its subject-name lists (rcSubjectsOnly) instead of the whole batch minus rows (avg 36 KB per slice). (3) Publish always stamps resultsSliceVer; resultsVer (allocation_each, 44 KB per phone) only when marks changed. (4) student_login_log: Maintenance reads the newest 300 (shows 40) via $key limitToLast; Data Usage no longer reads it on open - only on the first row expand, last 7 days. Verified with the real rcGetSlice in a mock: v9.81 first-year -> full file on first open AND every reopen; v9.82 -> results_ver/F1 + _pub once, then zero reads; student with results unchanged; missing marker -> full file (safe). ADMIN: press Publish once after this update so _pub is written. FILES (student_portal.html): rcGetSlice 24595 (no-results rule 24608); rcSubjectsOnly 24739; stuPublishResults 24671 (slice trim 24687, _pub stamp 24710); stuLoginLogLast 27203; renderMaintLogs 27085; Data Usage lazy login log 27249; duToggleDetail 27453.
VERSION : v9.81 (2026-09-28) -- STEP B PER-STUDENT RESULTS: Controls > Global > 'Publish results to students' (stuPublishResults) reads davan_pub/results once (admin), writes davan_pub/results_by_urn/<URN> = {docs: this student's rows only, ranks: precomputed by computeStudentRanks(pubOverride) per COURSE_SEM} and davan_pub/results_ver/<URN> fingerprint ('0' = no results) - ONLY for students whose fingerprint changed - then bumps controls/global/resultsSliceVer. Phones (rcGetSlice): same resultsSliceVer -> saved copy, zero reads; changed -> read own fingerprint (bytes), download own slice only if it changed. No fingerprint -> old full-file path. Rank pool memoised per results copy (WeakMap). Replaces v9.80's 'Tell phones to refresh' button (resultsVer still bumped by Publish for allocation_each). ADMIN WORKFLOW (new results OR revaluation, every time): 1) upload in results.html -> 2) sync as usual (index.html mirrors to davan_pub/results, sync reaches the portal DB) -> 3) portal Controls > Global > Publish results to students. Only students whose marks changed download again (a few KB each); everyone else downloads nothing. Publish before the sync has landed = '0 changed' -> just press again after the sync. Results do NOT reach students without step 3. FILES (student_portal.html): Publish results row 5664 (with workflow help text); admin label g-resultsVer-lbl 14918; _spRankPoolMemo + computeStudentRanks 18893-19231 (slice ranks first, pubOverride, memoised pool 19043, return-early 19231); STEP B block 24558-24724: rcSliceGv 24590, rcGetSlice 24595, rcRankKey, rcSliceRanks 24628, rcFilterForUrn 24634, rcHash, rcIndexResults 24650, ADMIN WORKFLOW note 24664, stuPublishResults 24655; rcLoadPrevResults 24675; rcLoadPrevResultsReal 24869 (own slice read 24886).
VERSION : v9.80 (2026-09-28) -- DB2: (1) RESULTS VERSION - davan_pub/results (1.5 MB) + allocation_each are kept on the phone until admin presses Controls > Global > 'New results published' (controls/global/resultsVer, read with the controls so the check costs nothing); safety re-download after 14 days; before the first press the old 24 h TTL applies. (2) student_login_log (5.8 MB, admin Maintenance + Data Usage) now reads only the last 31 days via a push-key $key range (no index needed). FILES (student_portal.html): stuBumpResultsVer 14943 (later replaced in the UI by Publish, function kept); rcCacheSet 24480 (ver); RC_VER_KEYS / RC_VER_MAX_DAYS / rcResultsVer / rcCachedGet 24494-24500; rcForceRefresh 24648; stuPushKeyAt 27100 + stuLoginLogRecent 27197; renderMaintLogs 27113 and Data Usage login log read 27249 (last 31 days).
VERSION : v9.79 (2026-09-28) -- ARCHIVE COST TO ~ZERO: new Controls > Global toggle 'Past Semesters (archive)' (controls/global/pastSems, DEFAULT OFF). Off: no year dropdown, stuPopulateAYSwitcher() makes no archive read at all. On: the which-past-semesters check runs once per SEMESTER per student (localStorage davan_ay_archive_keys_<URN> tagged with STU_AY_LIVE.key, re-checked only when a new semester starts), and an opened archived semester is kept in localStorage (davan_arch_<key>_<URN>; falls back to own-class list if too big) so it is downloaded once ever; the sync button (force) re-reads. FILES (student_portal.html): Past Semesters toggle row 5663; admin loader g-pastSems 14916; stuPopulateAYSwitcher 19318 (pastSems gate + once-per-semester cache); stuArchCacheGet / stuArchCachePut 19373-19385; stuSwitchAY 19386 (force param, archive kept on phone); AY sync button 4952 (force=true).
VERSION : v9.78 (2026-09-28) -- DB2 METER FIX: (1) stuPopulateAYSwitcher() no longer downloads the whole davan_pub/archive (~2.4 MB, 43% of a day's DB2 downloads) on every dashboard load just to find which past semesters hold this student -- shallow-lists archive keys + shallow-checks archive/<key>/portal_students/<urn> (bytes), cached per student 24 h in localStorage (davan_ay_archive_keys_<URN>). (2) RC_CACHE_DEFAULTS.bgRefreshMinutes 30 -> 360: results (1.5 MB) + allocation_each were silently re-downloaded every 30 min per active student; only applies when davan_config/rc_cache_settings is not set (Controls -> cache settings overrides). (3) Timetable class cards no longer repeat the faculty name on a second line under 'Faculty · Subject'. (4) Faculty label without a photo shows a teacher icon instead of the first initial (the 'S' circle before 'Smitha' read as 'SSmitha'). FILES (student_portal.html): spFacAvatar 7519 (icon instead of initial, alt empty) + spFacAvatarInject 7604; stuPopulateAYSwitcher 19318 (shallow archive scan); timetable slot card faculty line 23973-23989 (second name line only when no faculty); RC_CACHE_DEFAULTS 24423 (bgRefreshMinutes 360).
VERSION : v9.77 (2026-09-28) -- WhatsApp sheet as agreed: Send to warden (+ enabled contacts), Share... (WhatsApp chat/group picker) and Copy everywhere; agreed one-line messages for leave / complaint (#C-0042 running number via RTDB transaction, SDK loaded on first complaint) / meal feedback (Share + Copy only, cursor where the student types).
VERSION : v9.76 (2026-09-28) -- HOSTEL PART 1: Complaints tab (category, text, photo -> Cloudinary, status + office notes, send to principal after 48 h); WhatsApp preview/edit/send to warden + contacts enabled in index Hostel Settings after leave request and complaint; meal feedback Copy only; roommates show Warden/Staff/Guest.
VERSION : v9.75 (2026-09-27) -- COMPULSORY MEAL FEEDBACK: 45 min after B/L/D until next meal, Hostel page shows only 'Did you have X?' (1-5 stars / had it good / not good / didn't have it) -> canteen/meal_log (+ratings when ate); leave requests blocked while pending; dashboard card prompts. Same rules as widget w97.
VERSION : v9.74 (2026-09-27) -- Widget w97 deep links: ?hs=menu|rate|scan&meal=x opens Hostel page (menu tab, meal highlighted) or new Scan QR tab (placeholder until QR attendance).
VERSION : v9.73 (2026-09-27) -- HOSTEL -> DB4 (davan-lessonplan-archive): HS block reads/writes via hsGet/hsSet/hsPatch on its own anon app 'hs-db4' (golden rule: DB2 + DB4-hostel, never DB1). Closures (canteen/closed/{date}) shown in menu + next-meal card; leave type (Home/Medical/Personal/College).
VERSION : v9.72 (2026-09-27) -- DB2 METER: every portal read (rtdbGet/rtdbGetQuery via diagNoteRead) counted per grouped path and flushed every 3 min (silent PATCH, server increments) to davan_pub/meter, meter_t, meter_big; Data Usage tab gets the meter card (today vs budget, month vs 10 GB, projection, 30-day chart by app, top paths, big reads, settings). Data Usage tab now reads only this month of davan_pub/usage.
VERSION : v9.71 (2026-09-26) -- DB2 QUOTA: login diary moved controls/loginActivity -> login_activity (keeps /controls tiny); hostel leave writes also maintain hostel/leave_pending index (admin badge reads bytes, not full history).
VERSION : v9.70 (2026-09-26) -- FEAT Hostel (HS, DB2 only): Hostel nav for active residents (hostel/residents/{urn}); My Room with roommate photos + warden/office contact; Today/Tomorrow menu with Not-eating toggle (cutoff) and 1-5 star rating; hostel notices; leave/outpass request + cancel; next-meal card on dashboard. Admin side in index.html v1488.
VERSION : v9.69 (2026-09-22) -- FEAT, per explicit request: (1) the Home "Right now / Up next" widget's "sl.no N" line (right under subject/faculty, both the "Right now" card and the "Up next" card) relabelled to "Period N" -- previously read "sl.no 1" using the same label the Lesson Plan section right below it ALSO uses for topic numbers ("sl.no 24", "sl.no 25"), so two genuinely different meanings (timetable period position vs. lesson-plan topic number) shared one label stacked in the same card -- confirmed via screenshot this read as confusing. Only the two _stuNowNextResolveRow()-derived lines changed (both literal `'sl.no ' + resolved.period` occurrences, verified exactly 2 in the file, both in this widget); the Lesson Plan panel's OWN "sl.no" (topic number, a completely different field) was untouched -- that meaning is correct as-is and wasn't part of this request. (2) The "Get the Davan Student widget" promo card (#dash-getapp-card) — an install prompt for an ANDROID HOME-SCREEN widget — now hidden outright on desktop browsers, since a desktop user has no way to act on it at all. New stuIsMobileDevice() [~19678], a standard UA sniff (Android/iPhone/iPad/iPod/Mobi), gates the card in stuApplySidebarWidgetStatus() [~19688] at all THREE places that function sets the card's display: the desktop early-set-to-none guard at the top, the "no pair code on this device" reveal, and the final linkedToMe-&& recentlyActive reveal/hide -- all three now require stuIsMobileDevice() before ever setting display:'' on desktop, so no later branch in that function can re-show it there either. Did NOT touch the pre-existing "already installed and actively checking in -> hide" logic (linkedToMe && recentlyActive, unchanged) -- that was already correct and is exactly the other half of what was asked: hide when installed, in addition to now also hiding on desktop. Left the admin-preview fallback (no logged-in student -> show unconditionally, ~30021) and the sidebar's own widget-code meta line (informational once paired, not an install prompt) untouched -- neither is the install-promo path this request was about. APP_VERSION/BUILD_DATE bumped 9.68->9.69, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; grepped for every remaining literal 'sl.no' in the file to confirm only the Lesson Plan panel's own (correct, untouched) usage remains; grepped every promoCard/card.style.display assignment inside stuApplySidebarWidgetStatus to confirm all three are now gated. NOT YET LIVE-TESTED: please confirm on-device (a) the Now/Next card reads "Period 1" not "sl.no 1", (b) the widget-install card no longer appears at all on a desktop browser login, (c) on mobile it still correctly hides once the widget is actually paired and checking in, and still correctly shows when it isn't.
VERSION : v9.68 (2026-09-22) -- FIX, per explicit request with screenshot: v9.67 put the greeting BELOW the zodiac/DOB line and At a Glance (it had moved to the very top by mistake) -- reordered the dashboard header so "👋 Good evening, NAME!" is now the first line under the header, THEN the zodiac/DOB line (#dash-dob), THEN At a Glance below that -- restores the original relative order of greeting-then-zodiac that existed before v9.67, with At a Glance now sitting after both instead of its pre-v9.67 position much further down the page. Pure reorder of existing blocks (#df-banner+#dash-greeting, #dash-parents, #dash-dob, birthday/step2 banners, then the At-a-Glance stat-row) -- no ids, fill logic, or onclick handlers touched. APP_VERSION/BUILD_DATE bumped 9.67->9.68, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; grepped every touched id (dash-greeting, dash-dob, dash-parents, dash-birthday-banner, dash-step2-nudge, stu-dash-stat-row, sd-ia1-box, sd-ia2-box, df-banner) to confirm exactly one of each remains after the reorder, no duplicates left behind. NOT YET LIVE-TESTED: please confirm on-device the dashboard now reads Greeting → zodiac/DOB line → At a Glance, top to bottom.
VERSION : v9.67 (2026-09-22) -- FEAT, per explicit request: (1) the dashboard's "At a Glance" stat-widget block (renderHomeDashboard's #stu-dash-stat-row) moved to the VERY TOP of the dashboard panel, now sitting immediately below the header/photo and above "👋 Good evening, NAME!" -- previously it rendered much further down, after the seat card, Now/Next widget, and Attendance & Classes summary card. Straight relocation of the existing HTML block plus its section comment; no id, onclick, or fill logic touched, so all 6 original tiles (Overall Att./Subjects OK/Shortage/Today's Classes/Notices/Semester) behave identically, just positioned earlier. (2) Two NEW tiles added to the same stat-row: "1st Internal" and "2nd Internal", each showing total/max + % (e.g. "42/60 · 70.0%") plus a pass/fail-count sub-line, tapping through to the same Internal Marks panel (switchStudentPanel('internals')) the existing "Internals" summary card already links to. Each tile (#sd-ia1-box / #sd-ia2-box) starts display:none in the static HTML and is independently unhidden by new renderDashIATiles() [~19835], called from the end of renderHomeDashboard() using the same `subs` array already in scope -- fires only once that internal actually has at least one numeric or AB mark for this student, so the 2nd-Internal tile stays hidden through the whole 1st-Internal-only window instead of showing a stale "—", same "don't show empty state" convention renderIAEligibilityBanner() already follows for its own IA1/IA2 rows. Total/max/pass-fail math deliberately mirrors the EXISTING renderReportCard() IA summary cards (~24820) exactly -- int1/int2 counted only when typeof === 'number' (AB excluded from the numeric total, counted separately as its own "X AB" chip), max = count * 30, pass threshold 11/30 matching renderInternals()'s own INT_PASS_MIN -- so these new dashboard tiles can never show a number that disagrees with the Report Card's or Internal Marks panel's own totals for the same student. APP_VERSION/BUILD_DATE bumped 9.66->9.67, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; confirmed no duplicate #stu-dash-stat-row/#sd-overall-pct/etc ids exist after the move (old lower copy fully removed, not just visually superseded); confirmed int1/int2/INT_PASS_MIN=11 read back correctly against renderInternals() and renderReportCard()'s own use of the same fields. NOT YET LIVE-TESTED: please confirm on-device (a) At a Glance now appears above the greeting for a real student login, (b) the 1st Internal tile shows correct total/%/pass-fail once IA1 marks are entered, (c) the 2nd Internal tile stays hidden until IA2 marks exist, then shows correctly too, (d) tapping either new tile opens Internal Marks.
VERSION : v9.66 (2026-09-21) -- FEAT, per explicit request: the "Internals" and "Semester Result" cards in the dashboard's "Your Summary" stack (renderDashStudentSummary() [~21150]) are now clickable, jumping to their real panels same as the At-a-Glance stat boxes above them already do -- Internals -> switchStudentPanel('internals') (Internal Marks panel), Semester Result -> switchStudentPanel('reportcard') (Report Card panel, the same STATE._lastPrevResults source stuSummaryPart3()'s own text already reads from, so tapping through lands on the full detail behind exactly what the card already summarizes). cardWrap() [~21159] now takes an optional `panel` argument -- when supplied, the whole card gets onclick/role="button"/tabindex/cursor:pointer plus a small "tap to view →" hint in the header, same micro-affordance text the At-a-Glance boxes use; when omitted, the card renders exactly as before, non-clickable. Attendance & Classes (the top summary card) deliberately left non-clickable -- only Internals and Semester Result were asked for, and Attendance & Classes already has its own dedicated At-a-Glance stat boxes linking to the Attendance panel just above it, so a second click target there wasn't requested and would only duplicate that. APP_VERSION/BUILD_DATE bumped 9.65->9.66, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; confirmed 'internals' and 'reportcard' are the actual panel names switchStudentPanel() expects by grepping the sidebar/bottom-nav buttons that already navigate to them. NOT YET LIVE-TESTED: please confirm on-device that tapping the Internals card opens Internal Marks and tapping Semester Result opens Report Card, and that the "tap to view →" hint reads clearly without crowding the card title.
VERSION : v9.65 (2026-09-21) -- FEAT, per explicit admin request: a Controls toggle for the "resume last page on refresh" behavior, student side only. This behavior already existed unconditionally, shipped in an earlier v8.8x release: switchStudentPanel() saves the open panel to sessionStorage('stu_last_panel') on every switch, and goToDashboardInner() [~10566] read it back on every dashboard load, landing the student back on whatever page they were on instead of always resetting to Dashboard. Admin explicitly asked for this to become optional -- "default off now", and explicitly confirmed the SAME behavior on the admin side should be left alone ("on admin login this should not work... land which page I had open") -- admin's own restore is a completely separate, pre-existing mechanism (admin_last_tab, ~10942/10975/12866, its own sessionStorage key, its own read/write, never shared code with the student path) and needed zero changes; confirmed by grepping every admin_last_tab call site before touching anything, so there was no risk of the new flag accidentally gating the wrong side. Added 'resumeLastPage' to CONTROL_FLAGS (auto-gains byClass/byUrn override support + checkbox load/save via the existing CONTROL_FLAGS.forEach() loops, same proven zero-extra-wiring pattern the v8.44/v9.48 entries above already used for Internal Timetable/Report Card) and to CONTROL_FLAGS_DEFAULT_OFF (so it reads OFF for every student until an admin explicitly turns it on, matching "default off now" exactly, same default-off mechanics already proven for dobHoroscope/birthdayToast). New "Resume Last Page (student)" checkbox row in the Controls tab's Global group [~5571], grouped with the other DEFAULT OFF toggles, sub-label spells out that it's student-portal-only and admin's own tab memory is unaffected either way so there's no ambiguity reading the Controls screen later. The actual restore call in goToDashboardInner() is now wrapped in `if (canShow('resumeLastPage'))` -- when off (the default), that block is skipped entirely and the function's normal flow leaves Dashboard as the active panel, exactly the pre-v8.8x behavior; when an admin turns it on (globally, or per-class/per-URN via the same override rows every other flag already gets), a refresh resumes whichever student page was open, same as it always did before this toggle existed -- "can add that service back" if wanted. APP_VERSION/BUILD_DATE bumped 9.64->9.65, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; traced admin_last_tab's 3 call sites end to end to confirm none of them reference resumeLastPage or canShow() at all. NOT YET LIVE-TESTED: please confirm on-device (a) with the toggle OFF, a student refresh on any page lands on Dashboard, (b) with it ON, a refresh correctly resumes the page they were on, (c) admin's own refresh-resume behavior is unchanged either way.
VERSION : v9.64 (2026-09-21) -- FEAT, per explicit user request ("also add how much left... 6 topic to complete or 6 is balance"): the syllabus-covered graph (_stuNowNextSyllabusHtml() [~20079], new in v9.63) now shows a third line under the done/total/% row -- "⏳ N topics left to cover" (warn-colored) when topics remain, or "✅ All topics covered" (ok-colored) when the subject's syllabus is fully done. remaining = total - done, a simple derived value from the same syllabus.done/syllabus.total already computed in the model -- no new data source, no re-derivation, just the subtraction the user asked for spelled out as its own line rather than left for the student to do in their head from the two separate numbers already shown. APP_VERSION/BUILD_DATE bumped 9.63->9.64, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean. NOT YET LIVE-TESTED: please confirm on-device the remaining-topics line shows the correct count and flips to "All topics covered" correctly once a subject's syllabus reaches 100%.
VERSION : v9.63 (2026-09-21) -- FEAT, per explicit user question: "u tell what will do u show here graph or only %? If graph proper colour code and proper title and % also." Answer given and built: a GRAPH, matching the same visual language already used for attendance on this card and for the Lesson Plan panel's own syllabus bars elsewhere in this file -- not a bare number. Two changes to the Home "Right now / Up next" card: (1) the existing attendance bar (_stuNowNextAttHtml() [~20062]) had no title at all, reading ambiguously right under the Lesson Plan block above it -- added a "📊 Attendance" header line, same pattern as the Lesson Plan block's own "📖 Lesson plan" title. (2) NEW _stuNowNextSyllabusHtml() [~20078] -- a second, separate graph for per-subject syllabus coverage %, titled "📚 Syllabus covered", using the exact same real calculation the Lesson Plan panel itself uses for its own progress bars (done = topics with a handled_date, total = topics.length or total_topics -- computed once in _stuNowNextCardModel() [~19959] alongside the existing lesson-plan/attendance data, added as a new `syllabus` field on the model, not re-derived elsewhere). Same red/amber/green color thresholds as the rest of this file (<40% danger, <75% warn, >=75% ok) -- NOT the same thresholds as the attendance bar (<75%/<85%/>=85%), since syllabus-behind and attendance-shortage are different concepts with different real cutoffs elsewhere in this codebase (stuSummaryPart1's avgColor for syllabus vs the dashboard's own attendance color logic), matched here rather than inventing a third palette. Card order top to bottom is now: subject header -> Lesson plan (what's covered/next) -> Syllabus covered (how much, as %) -> Attendance (how much attended, as %) -- lesson-plan detail first, then the two progress summaries beneath it, added to BOTH card-rendering call sites (the normal now/next cards and the rollover-to-a-future-day cards) so the graph appears consistently everywhere this card renders. APP_VERSION/BUILD_DATE bumped 9.62->9.63, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; grepped both _stuNowNextAttHtml/_stuNowNextSyllabusHtml call sites to confirm the new graph was added to each, not just one. NOT YET LIVE-TESTED: please confirm on-device that the syllabus graph's done/total/% numbers match what the Lesson Plan panel itself shows for the same subject, and that both graphs read clearly as two distinct, titled metrics rather than one ambiguous bar.
VERSION : v9.62 (2026-09-21) -- REAL BUG, SAME ROOT CAUSE AS v9.61 BUT A DIFFERENT SCREEN: user sent another live screenshot showing the FULL TIMETABLE PANEL (not the Home widget fixed in v9.61) still displaying "Internet Programming" with only a small "A1·Lab 1" tag underneath for a genuinely-lab period -- confirmed on inspection this panel's OWN header-stripping line (~23424-23431, in the SECOND/active definition of renderStudentTimetable() -- this file has two, JS uses the later one) is exactly the pattern v9.61's comment already described and correctly left alone at the time, because the user hadn't reported it there yet. Now they have: the small purple tag alone doesn't read as clearly distinct from the real theory subject at a skim, same complaint as before. FIX, applied here the same principled way: (1) stopped stripping "Lab" from subjName in this panel's row-rendering loop -- the header now shows "Internet Programming Lab" for a lab slot, matching the admin's own real timetable. (2) This panel has its OWN local getLPForSubject() closure [~23310] (a near-duplicate of the global stuGetLPForSubject(), scoped to this function, NOT the same function already fixed in v9.58) with the identical substring-matching bug (lpName.includes(normSubj) matches "internet programming" inside "internet programming lab"'s plan) -- confirmed this is why the LP progress bar shown under a lab slot could silently be pulling the wrong subject's numbers even before the header text was fixed. getLPForSubject() now takes an optional isLab parameter: when passed (the row-rendering call site now passes parsed.isLab), it uses a strict path -- strip "lab" from both the row's subjName and each candidate LP name down to a bare base, require exact base-name match AND matching labbedness. When isLab is omitted, the function falls back to its original loose substring/word-overlap behavior unchanged, so nothing else that might call this closure without the new argument breaks. Checked for other call sites and other subject-attendance matching in this panel -- found none; this panel only shows LP progress (done/not-started/%), no per-subject attendance numbers, so unlike v9.61 there was no second matcher to fix here. Simulated the fixed matcher standalone (Node) against the exact real names and numbers from the screenshot (Internet Programming theory vs Internet Programming Lab, 20/6/26/77%) to confirm the lab slot now resolves to the lab's own real progress, not by coincidence (both happened to read 77% in this student's case) but by correct matching. APP_VERSION/BUILD_DATE bumped 9.61->9.62, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; grepped every getLPForSubject( call site in the file to confirm only the one local closure and its one call site exist, nothing else needed updating. NOT YET LIVE-TESTED: please confirm on-device that the Timetable panel now shows "Internet Programming Lab" (not the bare theory name) for lab slots, with the LP progress bar underneath matching the Lab subject's real done/not-started/total figures.
VERSION : v9.61 (2026-09-21) -- REAL BUG FOUND from a side-by-side comparison the user sent: the ADMIN'S OWN real timetable (index.html, screenshot 1) showed Tuesday 10:30's slot as "INPRO - Lab" with an A1·Lab 1 batch tag -- a genuinely different subject offering from theory "Internet Programming" -- but the Home "Right now / Up next" widget (screenshot 2) displayed the bare theory name "Internet Programming" with sl.no 1/Program 5, no lab indication anywhere, for that exact slot. Root cause, confirmed by reading the code, not guessed: _stuNowNextResolveRow() [~19890] was copying the real Timetable panel's own subjName-stripping line verbatim ("if (parsed.isLab) subjName = subjName.replace(/\s*lab\s*\$/i,'')" -- see the Timetable panel's own comment at ~23405-23411 explaining WHY it strips: that panel shows a SEPARATE 🧪 batch/lab tag line right underneath the header, so "Lab" is still visually present via that tag even after stripping the header text). This Home widget copied the strip but was never given that second tag line, so for a lab period the word "Lab" simply vanished with nothing replacing it -- the student had no way to tell a lab period from its own theory counterpart on Home, exactly what was reported. FIX: stopped stripping "Lab" from the DISPLAYED subject name in this widget -- subjName now shows exactly what the allocation/timetable actually says ("Internet Programming Lab" for a lab period, "Internet Programming" for theory), isLab is still computed and carried on the resolved row for internal matching. This required re-fixing BOTH v9.58's exact-match helpers, which had assumed subjName arrived already-stripped: _stuNowNextExactLPMatch() [~19929] and the per-subject attendance matcher inside _stuNowNextCardModel() [~19984] now both strip "lab" from EITHER side (the row's subjName AND each candidate LP/attendance-subject name) down to a bare base name before comparing, then separately require the isLab flags to agree -- correct regardless of whether subjName happens to carry "Lab" in it or not, rather than assuming one specific shape. Simulated the fixed matcher standalone (Node, outside the app) against theory+lab LP entries with the exact real names from the screenshots ("Internet Programming" / "Internet Programming Lab") to confirm both directions resolve to the correct entry before shipping. APP_VERSION/BUILD_DATE bumped 9.60->9.61, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean; grepped every remaining resolved.subjName/resolved.isLab call site in the file to confirm nothing else still assumes the old stripped shape. NOT YET LIVE-TESTED: please confirm on-device that a lab period on Home now correctly reads "<Subject> Lab" (not the bare theory name) and that its lesson-plan/attendance numbers match the LAB subject's real figures, not the theory subject's.
VERSION : v9.60 (2026-09-21) -- FEAT, per explicit user question + spec ("what'll u show Saturday last period... Sunday no class... or Monday 1st period"). Two changes to v9.59's rollover: (1) Sunday is no longer silently skipped in the walk-forward -- _stuNowNextRollover() [~20056] now stops explicitly on the first Sunday it crosses (kind stays whatever the day AFTER it resolves to, but a `sunday` field on the result carries that date), and renderHomeNowNext() [~20185] separately detects the case where TODAY ITSELF is Sunday and shows the notice immediately rather than only ever seeing it as a lookahead. Per explicit request, the Sunday card doesn't sit empty -- it shows the SAME REAL "X teaching days completed / Y remaining" and "Syllabus is Z% complete" data the dashboard's own Attendance & Classes card already shows (stuTeachingDaysLine() reused as-is, the identical inline syllabus-average calc from stuSummaryPart1() duplicated into the new shared _stuNowNextTeachSyllabusHtml() [~20048] -- same numbers, not a re-derived estimate), so the card reads "SUNDAY · No classes" followed by the real progress data, with the next real teaching day's periods shown underneath it. (2) The day the rollover lands on now shows its first TWO periods stacked (1st hour, then 2nd hour beneath it) instead of just the 1st -- _stuNowNextRolloverHtml() [~20090]'s `roll.kind === 'rows'` branch takes `roll.rows.slice(0, 2)` and renders both as separate cards under one "Up next — <Day>" header, per explicit request ("on Monday show Monday 1st hour below 2nd hour"). Net effect for the three cases asked about: Saturday's last period ending shows a Sunday notice (with real teaching-days/syllabus data) followed by Monday's 1st AND 2nd hour stacked beneath it; opening the app ON Sunday shows that same notice immediately, with Monday's 1st+2nd hour below it; Monday itself (once its own timetable is live) behaves exactly as any normal weekday already did before this change. APP_VERSION/BUILD_DATE bumped 9.59->9.60, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block -- clean. Simulated the rollover date-walk standalone (Node, outside the app) for both the "starting from Saturday" and "starting from Sunday itself" cases against a fake timetable/calendar to confirm the Sunday flag and the Monday-with-2-periods result land correctly before writing this into the file -- not a substitute for on-device testing, but caught the logic shape before shipping. NOT YET LIVE-TESTED: please confirm on-device (a) a Saturday's last period correctly shows Sunday-then-Monday-1st+2nd, (b) opening the app on an actual Sunday shows the same notice with real numbers matching the dashboard's own Attendance & Classes card, (c) Monday's card genuinely shows both its 1st and 2nd hour, not one card duplicated.
VERSION : v9.59 (2026-09-21) -- FEAT, per explicit user spec on-device: the "Up next" card now rolls over to TOMORROW once today's timetable is finished, instead of just saying "no more classes today" and stopping. renderHomeNowNext() [~20120]: when today has no more periods left (upNextIdx === -1), calls the new _stuNowNextRollover() [~20055], which walks forward day by day (Sundays already skip themselves via _stuNowNextRowsForDate() [~19836], the new date-parameterized version of the previous today-only _stuNowNextTodayRows()) and, for EACH candidate day, checks the synced academic calendar FIRST via the new _stuNowNextCalEventFor() [~19862] -- explicit user instruction: "if tomorrow holiday or vacc or internal as per calendar of events show that instead of next day, keep proper sync with calendar of events". Recognizes the same Holiday/Event/Exam/VACC/Working Day type vocabulary already used elsewhere in this file (TYPE_ICON/TYPE_CLR at ~10434, tcap at ~16744), matched tolerantly by regex against type/event/title text since STATE.calendarData as read here isn't always run through fetchAdminCalendar()'s own tcap normalizer first. A "Working Day" entry is deliberately excluded from blocking a day (it's informational, e.g. a Saturday made a teaching day -- never the reason to hide real classes). Only when a day has NEITHER a blocking calendar event NOR any timetable rows does the walk continue to the next day; capped at 14 days out as a backstop against an empty timetable looping forever. Two new render paths: _stuNowNextEventCardHtml() [~20071] for a blocked day (Holiday/VACC/Exam label, icon and color matching the existing calendar convention, "No regular classes scheduled -- synced with the academic calendar"), and _stuNowNextRolloverHtml() [~20089] for a real future teaching day, showing that day's FIRST period with its own date/day/time line (e.g. "Tuesday, 22 Sep · 10:30 AM - 11:30 AM") so it reads unambiguously as a different day, not today's card relabeled -- same lesson-plan and attendance sections as any other card. Also fixed: today's OWN date is now calendar-checked before falling through to "no classes today" at all (previously a Holiday/VACC/Exam entry for TODAY specifically was never surfaced on Home, only handled elsewhere in the Timetable panel). Auto-advance keeps working through the overnight gap with NO new code needed: the existing 60s ticker (stuStartNowNextTicker(), unchanged) keeps re-rendering, and the moment the real clock crosses midnight, new Date() naturally becomes "tomorrow" for every already-existing helper in this widget -- _stuNowNextTodayRows() then finds that day's own rows as TODAY's rows, and the normal current/upcoming split (unchanged from v9.57) takes over and flips the rolled-over card from "Up next" into a live "Right now" the instant that period's start time arrives, exactly the "once it's live change to live" behavior asked for. APP_VERSION/BUILD_DATE bumped 9.58->9.59, all 5 static-HTML fallback strings updated to match. VERIFIED: extracted and node --check'd the real script block containing this code -- clean. NOT YET LIVE-TESTED: please confirm on-device (a) tomorrow's 1st period shows correctly with its own date/day once today's timetable finishes, (b) a real Holiday/VACC/Exam calendar entry on tomorrow (or a further day, if several are non-teaching in a row) correctly shows that event instead of hunting past it for a class, (c) the rolled-over card correctly flips into "Right now" once its start time actually arrives the next morning.
VERSION : v9.58 (2026-09-21) -- TWO REAL BUGS FOUND ON-DEVICE, from a live screenshot the user sent right after v9.57 shipped. (1) The Home "Right now / Up next" widget's IA-eligibility card was correctly following v9.57's design (show it, don't touch it) but the DESIGN ITSELF was wrong: "1st Internal: ✅ Eligible" was still showing on-device days after the 1st Internal's own exam date had passed, because renderIAEligibilityBanner() [~21540] only ever gated on whether davan_pub/ia_live_status/IA1 had a status published for this student -- once published it stays published indefinitely (there is no "unpublish after the window closes" step anywhere in this system), so the card never hid itself on its own. FIX: cross-reference each internal against the synced academic calendar (STATE.calendarData), same source and title-matching convention (/1st|first/i, /2nd|second/i against event.event||event.title) stuSummaryPart2() already uses for its own nextInternal/pastInternal lines -- if that internal's calendar date is before today, drop the row entirely. Deliberately did NOT use ia_live_status's own `locked` flag for this: locked means marks are FINAL, a different, later concept than "the exam date has passed" -- eligibility is a PRE-exam question, so once the exam date is behind us showing "Eligible" (or "Not eligible") is stale noise regardless of whether marks are locked yet. If no matching calendar entry is found for an internal, its row is left showing rather than guessed-hidden -- only a confirmed past date suppresses it. (2) User reported the "Up next" card was showing LAB lesson-plan/attendance data for a THEORY period with the same base subject name (e.g. timetable said theory "Internet Programming", card showed the Lab's lesson plan) -- confirmed root cause: the shared, deliberately-loose stuGetLPForSubject() [~20927] does substring matching (lpName.includes(normSubj) / normSubj.includes(lpName)), so "internet programming" matches inside "internet programming lab" and returns the wrong entry. Did NOT touch stuGetLPForSubject() itself -- it's shared by the Timetable panel, Lesson Plan panel and dashboard summary, and its looseness is presumably intentional there for messier real-world name variants. Instead added a new, widget-local _stuNowNextExactLPMatch() [~19880] that requires an EXACT normalized-name match respecting whether the row is a Lab or Theory period (using the isLab flag _stuNowNextResolveRow() already computes from stuLmParseCode_), tried FIRST, falling back to the existing fuzzy stuGetLPForSubject() only if no exact match exists at all -- so an odd/inconsistently-scraped subject name still resolves to something instead of showing nothing. Applied the identical exact-then-fallback fix to the card's per-subject ATTENDANCE lookup too [~19931], which had the exact same substring bug matching against subs[].subject -- not something the user explicitly flagged in the screenshot, but the same root cause and worth fixing in the same pass rather than leaving a second copy of the bug live. APP_VERSION/BUILD_DATE bumped 9.57->9.58, all 5 static-HTML fallback strings updated to match, per the standing v9.55 rule. VERIFIED: extracted and node --check'd the real script block containing both fixes -- clean (the file's separate, always-failing "block 0" remains the same pre-existing false-positive documentation-comment artifact reproduced against the untouched original upload, unrelated to this change). NOT YET LIVE-TESTED: please confirm on-device that (a) the 1st Internal card is now gone/correctly hidden, (b) the 2nd Internal card still shows correctly (its exam date is still upcoming per the pinned "29 Oct 2026" banner in the same screenshot), (c) the "Up next" card for a subject with both a Lab and Theory offering now shows the correct one's lesson plan and attendance numbers.
VERSION : v9.57 (2026-09-21) -- FEAT: Home dashboard "Right now / Up next" widget (approved mockup: https://claude.ai/artifact/9y4dXTYAA9rmvTgyXBCjfS), per explicit user spec across several rounds. New #stu-home-nownext container, sits right after the seat card / before the existing Attendance-&-Classes summary card. renderHomeNowNext() [~19966] shows ONLY the class currently in session (if any) plus the next one -- never the full day's timetable on Home -- resolved via the SAME class/allocation-matching path the real Timetable panel and resolveDayLP() already use (stuLmBaseCode_/stuLmParseCode_/stuLmClassMatch_/stuLmAllocMatchesCode_, the existing global underscore-suffixed helpers -- deliberately NOT re-derived, to avoid a second, divergent copy of that matching logic). Each card carries: (1) subject/faculty/sl.no; (2) a lesson-plan block showing the highest-sl.no topic whose handled_date is <= now as "Handled", and the very next sl.no as "Today's topic" -- per explicit correction from the user, handled_date's REAL scraped shape is confirmed day-first WITH a time suffix ("22/07 05:04 PM", see sameDay() ~20776 and the v7.11 entry below), so "Handled" now shows date + time + a relative day count ("19 Sep @ 3:30 PM · 2 days back"), not just a bare date as an earlier draft of this widget had; (3) a collapsed "Show/hide upcoming topics" row (stuToggleNowNextLesson) so a student who wants the rest of the lesson plan can open it, collapsed by default to keep the card short; (4) a per-subject attendance progress bar in the same visual language as the existing LP/Timetable progress strips. Internals-hidden-between-windows behavior was NOT re-implemented here -- confirmed it already exists via renderIAEligibilityBanner() [~21268], which silently stays hidden whenever davan_pub/ia_live_status/IA1|IA2 has no published status for this student, i.e. between internal windows, without any change needed. Auto-advance: stuStartNowNextTicker() [~20029] re-renders the widget every 60s (visibility-gated, pure client-side re-render of STATE data already in memory, no extra network call) so "Right now" swaps to the next period, or clears once the day's last class ends, without the student needing to pull-to-refresh -- called once from renderHomeDashboard() alongside the initial render. APP_VERSION/BUILD_DATE bumped 9.56->9.57 and all 5 static-HTML version fallback strings (topbar + 3 login footers + stu-footer-meta) updated to match, per the standing v9.55 rule. VERIFIED: extracted and node --check'd the real script block containing this code (the file's other, always-failing "block 0" is the same pre-existing false-positive documentation-comment artifact already confirmed in the v9.48/etc. entries below -- reproduced identically against the untouched original upload, so not something this change introduced). NOT YET LIVE-TESTED: please confirm on a real device that (a) the current period highlights correctly and swaps automatically when a class ends, (b) the Handled/Today's-topic sl.no split looks right against a real lesson plan with several handled_date entries, (c) the attendance bar's numbers match the Attendance panel's own figures for the same subject.
VERSION : v9.56 (2026-09-21) -- REAL BUG FOUND AND FIXED, confirmed directly against a live device by the admin: admin's Day View timetable was showing periods out of chronological order (10:30 AM appearing AFTER 4:40 PM, all afternoon slots sorted before it). Root cause: buildAdminTTView()'s Day View branch relies on STATE.adminDayMap, sorted by an inline time-parsing helper -- present in 5 places in this file, all byte-identical -- that had NO AM/PM correction: "01.30"/"02.30" etc. (this system's convention for 1PM-7PM, hours 1-7 meaning PM, the SAME convention the mother app's own equivalent parser already handles correctly) parsed as literal 1:30/2:30, sorting as if they were 1 AM/2 AM -- ahead of genuine morning slots like "10.30". FIX: all 5 occurrences of this helper now add 12 to hours 1-7 before computing minutes, matching this file's own formatSlotTime() display logic (which already did this correctly, which is exactly why the SUBJECT NAMES and TIMES displayed correctly per-row -- only the ORDER of rows was wrong, since sorting used a different, unfixed helper than display did). Verified with a standalone simulation using the admin's own real slot times (10.30, 11.45, 01.30, 02.30, 03.40, 04.40) that the fix produces genuine chronological order. Confirmed this was NOT the "Push Timetable to Portal" / sync mechanism -- that was independently traced and confirmed working correctly first (226 rows, 9 classes, synced successfully, subjects/faculty/times all correct on both sides) before finding this separate, narrower ordering-only bug.
VERSION : v9.55 (2026-09-16) -- FIX: admin noticed the app was still displaying v9.47 everywhere despite the changelog being at v9.54 -- APP_VERSION/BUILD_DATE constants were never actually bumped during any of this session's earlier fixes, only the changelog entries were. Bumped APP_VERSION 9.47->9.54, BUILD_DATE to 16 Sep 2026. Also found and fixed a real bug while in this code: login-footer-meta-3 was missing from the runtime update forEach list (2 of 3 login-screen footers were wired, one was silently permanently frozen at whatever version was last hand-typed) -- added it. Updated the 5 stale static-HTML fallback strings (topbar + 4 footers, all still literally read "v9.47 / 13 Sep 2026" in source) to match, even though JS overwrites them at runtime -- source shouldn't lie even when self-healing.
VERSION : v9.54 (2026-09-16) -- REAL FIX for "No DOB" card still showing 0 after v9.53 (F12 data confirmed the actual cause): portal_students has 687 rows against a 403-student roster (old/passout/re-imported accounts, plus at least one non-roster URN in the live sample). noDobRows was checking whether a roster URN existed ANYWHERE in portal_students -- true for nearly every current student regardless of whether THEIR OWN record has dob, since so many extra rows exist. Fixed: exclusion set is now URNs that specifically HAVE dob (urnsWithDob), not just URNs present at all -- verified with the admin's own real numbers (403 roster, 369 with dob) produces exactly 34. Also fixed the sanity-check comparison, which would have misfired constantly comparing raw portal_students count to withDob count (differ by hundreds by design) -- now compares roster-scoped counts, the only comparison that means anything.
VERSION : v9.53 (2026-09-16) -- TWO FIXES on v9.52. (1) "No DOB" card showed 0 instead of an expected ~34 (403 roster - 369 with DOB): STATE.allStudents can be empty when this tab opens (bulk load not yet finished, or a nav path that skipped it), silently zeroing the card with no sign anything failed. Now falls back to fetching davan_pub/students directly if the roster is empty; also logs a sanity check if any portal_students row is ever found without a dob (would mean the mandatory-DOB assumption this card relies on doesn't hold everywhere). (2) Admin reversed the tab-width decision -- wants ALL tabs at 1400px, not just wide-content ones. Moved max-width:1400px onto the base .tab-content rule itself (was 900px) and removed the now-redundant .tab-content-wide class -- one line now controls every tab including any added later, true "one helper" as originally asked.
VERSION : v9.52 (2026-09-16) -- THREE FIXES. (1) Student Logins table: clickable Name header for A-Z/Z-A sort (stuCycleNameSort), independent of the existing Last Login sort cycle. (2) DOB & Horoscope admin tab: new "No DOB - never logged in" card. Admin confirmed DOB is mandatory at login, so the only way to lack one is never having logged in -- card is STATE.allStudents roster minus portal_students URNs, with its own drill-down list (baRenderOptInList's 'noDob' branch, separate render path since these rows have no dob/dobTime/dobPlace fields at all). (3) New .tab-content-wide CSS helper (max-width:1400px) replacing yesterday's one-off inline style on #tab-students; applied to it and #tab-engagement (the two tabs with a real <table>) -- NOT applied to all 19 tabs globally, per admin's own explicit call after I asked: short-form tabs should stay narrower rather than look stretched.
VERSION : v9.51 (2026-09-16) -- REAL FIX for parent names not showing (admin confirmed suspicion: "might be it hs not scraped from db1 to db2" -- correct). ROOT CAUSE #1: index.html's manual Father/Mother overrides live in Firestore DB1 app_data/student_parents; this portal is DB2-only by hard rule (installDb1Guard() blocks any DB1 fetch outright) and had no bridge for that path at all. Added sync_parent_overrides_firestore_to_rtdb() to sync_db1_to_db2.py (mirrors the existing students sync) -> RTDB DB2 davan_pub/parent_overrides, wired in unconditionally next to the students sync. New stuLoadParentOverrides() reads it via rtdbGet() (this file's own real DB2 reader -- an earlier draft of this fix wrongly used lpDb2Get, a function that does not exist in this file at all; caught before shipping by grepping for its definition here and finding none). ROOT CAUSE #2, found while fixing #1: rcLoadPrevResultsReal() only ever extracted the exact keys st.fatherName/st.motherName when building each semester record -- a differently-cased real key (AFIFA's actual data: FatherName/MotherName) was discarded before any pattern-matching could even see it. Now spreads every string field from the raw record onto the pushed result (explicit fatherName/motherName assignment kept after the spread for backward compat), so stuParentNamesFromResults() has the real data to search. Fixed all THREE display sites to use stuParentNamesFromResults() + the override fallback consistently: dashboard (dash-parents), Report Card header, and the admin name-card popup (ascOpenNameCard) -- the last one previously used manual &lt; escaping instead of escapeHtml(), now consistent too. VERIFIED: Python syntax clean; JS syntax clean across all script blocks; a Node harness reproducing AFIFA's exact real key shape (FatherName/MotherName + fatherPhone noise) resolves correctly end-to-end through the full pipeline. NOT YET LIVE-TESTED: needs a real sync_db1_to_db2.py run before davan_pub/parent_overrides exists in DB2 at all -- please run the sync, then confirm AFIFA (or any student with a manual override) shows Father/Mother on her own dashboard, Report Card, and the admin Student Logins table Info column.
VERSION : v9.50 (2026-09-16) -- FIX: Students tab wasted a lot of horizontal space on wide screens (.tab-content's shared max-width:900px, used by 19 tabs). Overrode max-width to 1400px on just #tab-students (not globally --other tabs are short forms/cards that would look stretched at full width). Table now width:100% to actually use the room; Info column's parent-name line no longer forced nowrap, so it wraps cleanly instead of cramping.
VERSION : v9.49 (2026-09-16) -- FEAT: admin Student Logins table (Controls -> Students) now shows a compact "Info" column per student -- DOB, zodiac sign, and Father/Mother name -- so admin can see at a glance who has and hasn't filled in their birth details, without opening each student individually. Direct admin request, with a real example: AFIFA ANJUM M (U13DI24S0001) shows Father/Mother correctly on index.html's own Report Card (MUKTHAR AHAMED SHARIFF / BI BI AYEESHA) but her OWN student_portal.html dashboard shows neither -- confirmed via a real screenshot, no Father/Mother line rendered at all between the header and the DOB line. Traced the cause: this file's dashboard code (updateSidebarProfile()'s dash-parents block, and the identical logic in renderReportCard()/the WhatsApp message builder) all check ONLY the exact keys fatherName/motherName, while index.html's own rcParentNames() matches by PATTERN (any key containing father/mother, case-insensitive, skipping phone/occupation/etc false-positives) -- the two apps read differently-shaped copies of the same underlying data (index.html: Firestore rcResultsCache; this file: davan_pub/results RTDB mirror), and AFIFA's real record apparently carries the name under a key the exact-match check here does not catch. NOT fixed in the dashboard itself this pass (flagged as a separate, not-yet-diagnosed gaprather than silently changed under an unrelated request) -- instead, new stuParentNamesFromResults() ports index.html's own proven pattern-matching logic into THIS file for the new admin table column, verified with a standalone harness against AFIFA's real key shape (FatherName/MotherName, mixed case) plus the plain exact-key case, a guardian-only fallback case, and empty/missing data -- all four resolve correctly. IMPLEMENTATION: new stuLoginInfoCellHtml(s) renders DOB+zodiac INSTANTLY (already on the row's own `s` object -- same davan_pub/portal_students data this file's astro system already loads, zero extra fetch) plus a placeholder for parents; new stuFillLoginParentCells(urns), called once per rendered page of 25 rows (not all ~400 students at once), fetches each visible row's results via the existing rcLoadPrevResults(urn) (already session-cached, confirmed by reading it) and fills that row's own cell independently as its fetch resolves, keyed by data-urn + CSS.escape so a slow/failed fetch on one row can never block or corrupt another's cell -- also correctly does nothing if the admin has already paged away by the time a fetch resolves (the document.querySelector lookup simply finds no matching cell left in the DOM). Table header/rows/colspan updated for the new 8th column; two other colspan values in this same render path (the initial loading-state row and the empty loading placeholder in the base HTML) were ALSO still at their pre-this-session stale values (6 and 7) from before even my own earlier edits today -- corrected to 8 as well while in this code, not left stale a third time. MOBILE-FRIENDLY: table given an explicit min-width so it never cramps illegibly on a narrow screen, sitting inside the existing .table-wrap (already overflow-x:auto) -- added a small "scroll sideways" hint line underneath so the horizontal-scroll affordance is not silently discovered by accident. VERIFIED: real script blocks node --check clean; confirmed every new function and every function it calls (rcLoadPrevResults, astroFormatDob, astroSignFromDob, escapeHtml, stuAvatarHtml, renderStudentTable) all live in the same script block, so no cross-block reference risk at all for this change. NOT YET LIVE-TESTED: please confirm the Info column appears, DOB/zodiac shows immediately, Father/Mother fills in shortly after for students who have it (AFIFA should now show correctly), and paging through the table doesn't visibly stall or error.
VERSION : v9.48 (2026-09-16) -- FIX: Report Card showed "not available at this time" for every student whenever admin turned OFF the Attendance visibility toggle, even though there was no way to intentionally block Report Card specifically -- direct admin report confirmed via screenshot (Visibility Controls panel has no Report Card row at all) plus explicit confirmation "i have not blocked ... i dont have option to do that also here". ROOT CAUSE: renderReportCard() [line ~23747] gated its entire panel on canShow('attendance') -- Report Card was silently piggybacking on the Attendance flag with no dedicated control of its own, same class of bug this file's own v8.44 entry above already fixed once for Internal Timetable (which used to piggyback on the weekly Timetable flag the same way). Checked all 4 other canShow('attendance') call sites in this file (renderDashAttSummary, the plain-language attendance-standing block, renderAttendance) before concluding this was the only one actually gating Report Card -- the other 4 are legitimately about attendance itself and were left untouched. FIX, same proven pattern as v8.44: added 'reportCard' to CONTROL_FLAGS (auto-gains byClass/byUrn override support + checkbox load/save, same as every other flag, confirmed by reading the CONTROL_FLAGS.forEach() loops at ~14683/14879 and the save path -- no flag-specific wiring needed beyond the array entry itself); new "Report Card" checkbox row [~5532] in the Controls tab, right after Internal Timetable; renderReportCard() now checks canShow('reportCard') instead of canShow('attendance'). Default ON (not added to CONTROL_FLAGS_DEFAULT_OFF), confirmed both canShow()'s own g[section]!==false fallback and renderControls()'s el.checked = ... !==false logic already treat an unset flag as checked/visible, so a fresh deploy with no saved value yet shows Report Card exactly as it always used to, without needing every admin to explicitly turn a new toggle on. VERIFIED: real script blocks node --check clean (one pre-existing script-tagged documentation-comment block, unrelated to this change, same known false-positive class already documented elsewhere in this project). NOT YET LIVE-TESTED: please confirm the new Report Card toggle appears in Visibility Controls, defaults to ON, and that turning Attendance off no longer hides Report Card while the Report Card toggle itself still works independently.
VERSION : v9.47 (2026-09-13) -- WIDGET FIX + VERSION-DRIFT FIX, per admin report on-device (widget correctly self-reported its real build, but tapping it to pair opened the ADMIN index.html PWA instead of this student portal PWA). ROOT CAUSE found by reading the actual widget Kotlin source directly (DavanStudentWidget_w90.zip), not guessed: [StudentWidgetProvider.kt: resolveWebApkPackage() ~588] already had PackageManager-based WebAPK targeting (shipped at w30, see that changelog entry above) specifically to handle two WebAPKs sharing one origin -- admin app scoped to /davan-attendance/, this portal scoped to /davan-attendance/student_portal.html -- but its tie-breaker for which candidate to pick, when Android's PackageManager returns both, compared the RAW PATTERN-STRING LENGTH of each WebAPK's declared intent-filter path. That measures how long Chrome's encoded scope string happens to be, not how specific the match actually is for the real target URL -- the admin app's broader /davan-attendance/ scope can (and did, on the reporting device) encode as a LONGER string than this portal's narrower, literal /davan-attendance/student_portal.html filter, so the tie-break picked the wrong app, exactly backwards from its own stated intent. FIX (widget-side only, this file unaffected by the fix itself): resolveWebApkPackage() now asks each candidate's real PatternMatcher whether it actually matches the target path via PatternMatcher.match() -- the same check Android itself performs during intent resolution -- and among real matches ranks an exact PATTERN_LITERAL match (this portal's own filter) above a PATTERN_PREFIX/PATTERN_SIMPLE_GLOB whole-folder match (the admin app's), instead of ranking by string length. SEPARATE BUG FOUND WHILE INVESTIGATING (same report, different cause): StudentFetchWorker.kt's THIS_APK_VERSION -- the one number the running APK actually self-reports to RTDB -- was still 90, even though this project's own build.gradle (versionCode/versionName 92) and W91_CHANGES.md/W92_CHANGES.md were already ahead of it. Every real w92 install was truthfully self-reporting "w90" over RTDB, two releases behind reality -- the exact same self-report-lags-the-build bug class already fixed once on the faculty widget side (see index.html's own v1120 changelog for the identical mechanism). Bumped THIS_APK_VERSION 90->92 to match the real versionCode, and correspondingly bumped LATEST_STUDENT_WIDGET_APK.apkVersion 83->92 here (minApkVersion left unchanged at 55 -- ordinary fixes, not a safety/security release, per the standing soft-nag-only rule) so students on 83-91 now correctly see an update is available, and w92 installs correctly read as up to date instead of appearing 9 builds behind. [STUDENT_WIDGET_README.md:17] CURRENT_VERSION 90->92 for consistency, per this project's own stated auto-increment rule that all three markers move together. NOT VERIFIED BY A REAL BUILD: this sandbox has no network access to the Gradle distribution or Android SDK components required to compile the APK, so the Kotlin change was verified by careful manual reading only -- correct PatternMatcher/PackageManager API usage confirmed against the stable, unchanged-since-API-1 public Android API surface, project's own check_and_zip_student.py scan_file() string-escape checker run successfully against every .kt file with zero NEW issues introduced (pre-existing false positives on Javadoc-style block comments and a triple-quoted raw-string regex were found and left alone -- confirmed as scanner limitations, not real bugs, neither in the file this fix touched). ACTION REQUIRED: rebuild the widget APK from the corrected source and publish a new release before this fix reaches any real device -- editing the source alone changes nothing already installed.
VERSION : v9.08 (2026-09-06) [NEWS_SOURCES india ~113 in fetch_news.js,
india checkbox list ~6255]: added 2 new India sources — Indian Express
and Hindustan Times — both confirmed live this session (Harsha uploaded
the raw XML responses directly). Also confirmed toi/ndtv are genuinely
working (Harsha tested both in a browser), removed their "(unverified)"
labels. bbcindia remains the one still-untested source.
PRIOR VERSION : v9.07 (2026-09-06) [FETCH_TRIGGER_WORKER_URL ~8100,
triggerFetchNewsWorkflow() ~8131]: moved the GitHub token OUT of
student_portal.html/repo entirely, onto a Cloudflare Worker
(davan-fetch-trigger.harshgujjar.workers.dev) that holds it as an
encrypted secret. The v9.06 "separate gh-token-config.js file, never
uploaded" plan turned out unworkable: student_portal.html is served via
GitHub Pages, meaning the repo IS the public web server — any file the
browser needs to load, wherever placed within that repo, is
necessarily public, so there was never actually a "private" location
inside it. This portal now calls the Worker's public URL with a plain,
tokenless POST; the Worker does the authenticated GitHub call
server-side. The token is genuinely not present anywhere in this file,
this repo, or any chat from this point forward.
PRIOR VERSION : v9.06 (2026-09-06) [gh-token-config.js reference ~6604,
GITHUB_WORKFLOW_OWNER ~8092]: moved the GitHub token OUT of this file
entirely, into a separate gh-token-config.js that Harsha's server hosts
alongside this page but never shares for code edits — fixes the token
being accidentally re-exposed twice in a row by living inside the same
file that gets uploaded/downloaded for every routine change request.
See the full one-time setup steps in the doc comment above
GITHUB_WORKFLOW_OWNER.
PRIOR VERSION : v9.05 (2026-09-06) [GITHUB_WORKFLOW_TOKEN ~8068]: reverted the
v9.04 localStorage-based token UI back to a file-embedded constant —
Harsha wants the instant-trigger to work from any browser/device, which
localStorage (scoped to one browser) can't do. Token is now set by
editing GITHUB_WORKFLOW_TOKEN directly in this file; the News & Rates
tab shows a read-only status line instead of an input+save UI.
PRIOR VERSION : v9.04 (2026-09-06) [wcSaveGithubToken() ~8079, wc-gh-token
input ~6165]: GitHub token moved from a hardcoded source-file constant
to a UI input (News & Rates tab) saved in the browser's localStorage —
Harsha no longer needs to edit this file's code to set/update/clear the
token, just paste it into the portal once per browser. Same accepted
exposure trade-off as before, just relocated to localStorage instead of
plaintext in the file; see the doc comment above triggerFetchNewsWorkflow().
PRIOR VERSION : v9.03 (2026-09-06) [triggerFetchNewsWorkflow() ~8025,
wcSaveNewsSourceConfig() ~25841]: added GITHUB_WORKFLOW_TOKEN-based
instant workflow trigger — "Save source selection" now calls GitHub's
workflow_dispatch API right after its db3 write, so fetch_news.js runs
immediately instead of waiting for its 45-min cron. Harsha's explicit,
informed choice to embed the token in this shared admin/student file
rather than add paid Firebase infrastructure to hide it — see the doc
comment on GITHUB_WORKFLOW_TOKEN itself for the full reasoning.
Deliberately NOT wired into wcSaveNewsOverride() — that function's
whole purpose is pinning manual values, and auto-triggering a fresh
RSS fetch right after saving one would risk immediately overwriting
what the admin just typed in.
PRIOR VERSION : v9.02 (2026-09-06) [tab-newscontrol ~6128, wcLoadNewsControl()
~25728, wcSaveNewsSourceConfig() ~25832]: moved Page 6 "News & Rates"
admin control out of the Widget tab into its own top-level tab; added
Bollywood/Sandalwood sections, per-section multi-source RSS checkboxes
(widgetConfig/newsSourceConfig), MAX SHOWN chip range widened 1-7 (was
4-7), per-button save-confirmation toasts (wc-news-src-save-ok,
wc-news-override-save-ok) fixing a bug where the shared top-of-tab
toast was invisible on this long tab. Also fixed wcSaveNewsOverride()
silently wiping gold/silver/Bollywood/Sandalwood on every override
save (was a bare 5-field db3Set overwriting the whole node instead of
merging).
PRIOR VERSION : v9.01 (2026-08-30) [wcLoadNewsControl() ~25498, HTML block
~6061]: added Page 6 "News & Rates" admin control to Student Widget
Control tab — on/off toggle, rate/weather/headlines/quote override
fields with Save/Clear/Refresh, reads+writes db3 (davan-student-news,
separate Firebase project from DB2 — see db3Get/db3Set/db3Patch
~7807). Built because Page 6's Cloud Function (index.js) originally
had no admin control layer at all — everything was hardcoded/deploy-only.
KNOWN GAP: index.js does not yet honor newsOverride.locked before its
next scheduled write — a "locked" override will still get overwritten
by the next auto-fetch until that check is added on the Cloud Function
side.
VERSION : v9.00 (2026-08-30) [renderWcSummary() ~24429]: added two summary
cards to Widget Control — "UP TO DATE (w<latest>)" and "NEVER REPORTED",
matching the row-badge/filter fix from v8.99. paired now splits cleanly
into 4 mutually exclusive buckets (never-reported checked first, same
order as the row badge) — neverReported + stale + outdated + upToDate
should always sum to paired; both new cards tap-to-filter like every
other card in the row.
VERSION : v8.99 (2026-08-30) [renderWcTable() statusBadge ~24637, filter
branches ~24558, wc-status-neverreported ~5912]: BUGFIX — a paired
student who has NEVER sent a single student_widget_report write
(st.report === null, not just old/stale) was showing "✓ up to date" with
none of the device/last-seen/reminders detail underneath, because both
st.stale and st.outdated require st.report to be truthy to evaluate at
all — with no report, both silently came back false, and "not outdated"
was wrongly read as "confirmed current". Root cause of BHAVANA/MANASA/
MUSKHAN/TEESHA showing the badge with no detail. Fixed at the source
(new explicit no-report branch, checked first, in both the row badge and
the outdated/uptodate filter matchers) rather than patched per call site.
Added a new "❔ Paired, never reported" chip so this bucket has its own
visibility instead of being folded into a wrong verdict.
VERSION : v8.98 (2026-08-30) [renderWcTable() ~24476, wc-status-uptodate
~5911, wc-version-bar ~5922]: 3 additions to the Widget Control chip row.
(1) "✓ Up to date (w<N>)" chip — exact inverse of Outdated (paired, not
stale, apkVersion === latest). (2) Version dropdown — independent axis
from the status chips, built from the actual set of apkVersions present
in current reports (not hardcoded), lets the admin isolate "who's still
on w57" regardless of whether that version happens to be current;
combines with an active status chip rather than replacing it. (3) BUGFIX:
the student list had no sort at all, falling back to roster/insertion
order — looked random and buried anyone reporting live among long-stale
entries. Now sorted by last-seen recency, most recent first; never-
reported students sort to the end.
VERSION : v8.97 (2026-08-30) [wnRefreshActiveList() ~14135,
wnRemoveGroupedEntry() ~14206, wnDeleteNotice_silent() ~14244]: 2
Widget-Notice bugs fixed. (1) "Active notices" stuck on "Loading…" —
was doing one sequential rtdbGet() per student (300-450+ round-trips) to
build the list; now one single read of the whole
davan_pub/student_widget_notices node, grouped client-side. (2) Removed
notices "coming back" — wnDeleteNotice_silent() used to swallow every
per-student delete failure with a console.warn only, so a partial delete
(a handful of the hundreds of per-student writes failing) looked
identical to success; the survivors then reappeared on the next refresh.
Now returns true/false, wnRemoveGroupedEntry() does one retry pass on
whatever failed, and reports any still-failed URNs to the admin instead
of silently leaving them.
VERSION : v8.96 (2026-08-30) [_wnResolveTargetUrns() ~14028, wn-target
~5546]: added a 4th "Show to" option to Widget Notice — "Only
Widget-Installed Students". davan_pub/student_widget_active is keyed by
pairCode (a URN can own more than one record over time via re-pairing),
so resolving this target reads that whole node and collects the distinct
urn values across all its records, not the node's own keys.
_wnResolveTargetUrns() is now async (single RTDB read for this target
only); its one call site in saveWidgetNotice() now awaits it.
VERSION : v8.95 (2026-08-30) [clearLiveBroadcast() ~14262, admin panel
~5590]: added a "🛑 Clear/Recall Broadcast" button next to Broadcast Now —
there was no way to stop a sent broadcast before. Wipes
davan_pub/live_broadcast to null, which both the dashboard-load recency
check and the _liveFeedTick() poll loop gate on — stops it for anyone who
hasn't seen it yet (new/refreshed loads, next poll tick on open tabs).
Cannot un-show a toast already displayed on some device (no server-side
dismiss channel) — confirm dialog states this explicitly.
VERSION : v8.94 (2026-08-30) [renderInternalsTimetable() ~19532]: added
"⏱️ This timetable was last updated on <meta.last_updated>" line to the
Internal Timetable panel, mirroring the mother app's own display 1:1 —
reads davan_pub/internals_current/meta.last_updated (pre-formatted string
written by index.html's intSave(), synced DB1→DB2 automatically), shown
verbatim with no reformatting. Hidden when no timetable data is loaded.
VERSION : v9.43 (2026-09-08) [baRenderOptInList() ~27927]: Opt-in Rate
drill-down rows now show dobTime/dobPlace, matched to the active tab —
Full chart shows both, Time only shows time, Place only shows place.
VERSION : v9.42 (2026-09-08) [tab-birthdayadmin ~6647, baLoadHoroscopePreview()
~27789]: Admin DOB tab, horoscope panel — removed the "Show fetch date"
toggle, date line always visible now. Each sign header also shows its
date/month range (from ASTRO_SIGNS + astroSignMonthDay(), same source as
the student card's badge) e.g. "Aries (Mar 21 – Apr 19)".
VERSION : v9.41 (2026-09-08) [renderDashboardSeatCard() ~21744]: Dashboard
seat card now auto-hides once today is past the last exam day (max
seat.perDay date, e.g. 12 Sep for 1st Internal). Internal Timetable
page's own panel unaffected — stays visible there regardless.
VERSION : v9.40 (2026-09-08) [renderIAEligibilityBanner() ~21133]: FIX —
v9.39 wrongly suppressed the click on the Dashboard eligibility row too.
Reverted: Dashboard row is clickable again → navigates to Internal
Timetable page, per explicit instruction. Only onTimetablePage instance
stays non-clickable (already there).
VERSION : v9.39 (2026-09-08) [new: renderDashboardSeatCard() ~21692,
#stu-seat-card-dash ~5016; reverted stuRenderSeatBanner() accordion
~21903; renderIAEligibilityBanner() ~21118]: Moved "Your Seat" to the
DASHBOARD, directly below the eligibility banner — new dedicated fetch +
render, default SHOWN with its own collapse toggle (Dashboard instance
only). Internal Timetable page's own seat panel reverted to
always-visible (v9.36/v9.38 accordion/auto-expand there was the wrong
place, per feedback). Dashboard + Timetable eligibility-banner instances
no longer click through to Timetable (redundant now / already there).
VERSION : v9.38 (2026-09-08) [renderIAEligibilityBanner() ~21118,
stuJumpToSeating() new, stuRenderSeatBanner() ~21903]: FIX — clicking
"1st Internal: Eligible" did nothing once the exam was LOCKED ("Final"),
since locked rows were deliberately non-clickable. Now locked rows are
clickable too, and the click (stuJumpToSeating()) navigates to Internal
Timetable AND pre-expands the seating accordion (v9.36) in one tap instead
of landing collapsed.
VERSION : v9.37 (2026-09-08) [horoscope card ~5126, astroToggleAllSigns()
~9022]: Removed the "Show all 12 zodiac signs" toggle button/panel from
the STUDENT horoscope card entirely — was already default-hidden behind a
toggle per earlier instruction, now removed outright (student login must
never show the 12-sign reference list). astroSignMonthDay() kept — still
used by the sign badge on the same card.
VERSION : v9.36 (2026-09-08) [stuRenderSeatBanner() ~21903]: "Your Seat"
table now collapsed behind a click-to-show/hide toggle (default hidden),
and today's row (date match, local device date) highlights with a
"📍 Today" tag. No change to which internal's days are shown — perDay
already only ever carries the current internal (gated by meta.n), so a
2nd Internal's seating appears automatically once published, nothing else
needed there.
VERSION : v8.93 (2026-08-30) [renderInternalsTimetable() ~19567,
decodeSlotSubject() ~19608, renderIAEligibilityBanner() ~18893]: 3 fixes.
(1) "My Class" seat/room/bench banner now hidden while flagged NOT ELIGIBLE
for the current internal (fails open on fetch error/no data published).
(2) Raw "__ignored__:regular_class" slot markers (mother app's new unified
per-slot model) now decode to "📘 Regular Class (as per timetable)" instead
of printing the raw key, in both intRenderTable() and the seat-banner's
per-day subject expansion. (3) "Live — tap to check timetable →" link
suppressed on the Internal Timetable page's own banner instance
(#stu-ia-elig-banner-tt) — redundant/self-referential there.
VERSION : v8.92 (2026-08-28) — REAL ROOT CAUSE of "broadcast shows on
every refresh" found — v8.91's fix only covered the dashboard-LOAD call
site (~line 16091). A SEPARATE, second call site — the live-poll tick
loop (_liveFeedTick() ~line 17030) that runs continuously "for the life
of the tab" — was guarded only by `let _lastBroadcastTs = 0`, a plain JS
variable that resets to 0 on every page refresh (JS memory does not
survive a reload). So after any refresh, this second listener's very
next tick saw the same already-shown broadcast as "new" again and
re-fired it, completely bypassing the v8.91 fix. Both call sites now
read/write the SAME sessionStorage key (davan_broadcast_seen_ts) —
_lastBroadcastTs is seeded from it on load instead of starting at 0, and
the live-poll path writes to it too when it fires. A broadcast now
displays once per session across BOTH code paths, not once per path.
VERSION : v8.91 (2026-08-28) — 2 broadcast-toast bugs fixed. (1)
[#broadcast-toast CSS ~3523] z-index raised above #welcome-toast (9000→
10100, backdrop 8999→10099) — the post-login welcome popup could render
on top of and completely bury a broadcast toast if both fired around the
same time, per report "after login a toast comes that makes this
broadcast not viewable". (2) [~line 16068] Re-trigger bug — the "show
broadcast if sent within last 30s" check ran on every dashboard load
(login/refresh/tab-return), so refreshing within that 30s window kept
re-showing the SAME broadcast every time. Now tracks the shown
broadcast's own timestamp in sessionStorage (survives refresh, resets on
a genuinely new session) so each broadcast displays once per session,
not once per page load.
VERSION : v8.90 (2026-08-28) — [wcPreviewDigestTemplate() ~25068] Added
{name} to the Nightly Digest preview's sample values, matching the
matching Kotlin-side fix in DavanStudentWidget w63 (StudentNotifications.kt
showTomorrowDigest() rewritten to use fillTemplate()/DEFAULT_DIGEST_TITLE/
DEFAULT_DIGEST_BODY + a new {name} placeholder — the w60 handoff spec had
never actually been applied to the Kotlin codebase, confirmed by direct
code read; this was a full first build, not a small addition). Also
documented {name} in the on-page placeholder help text.
VERSION : v8.89 (2026-08-28) — BUGFIX [loadWidgetCtrlData() ~23890,
STATE._wcUrnToPairCode]: found via real device evidence — admin's own
test URN showed a stale w45/7-day-old widget diagnostics row despite the
actual phone being live and current (w62) under a different, real
pairCode. Root cause: a URN can end up with more than one
student_widget_active/<pairCode> record (repeated pairing across widget
builds/reinstalls without the old record ever being cleaned up) —
Object.entries().forEach() previously let whichever pairCode Firebase
returned LAST in iteration order silently win, which is not
insertion-order or recency for RTDB's non-numeric keys. Now explicitly
keeps the record with the newest updatedAt per URN, so the diagnostics
panel always reflects the actually-current paired device.
VERSION : v8.88 (2026-08-28) — Portal-side build of 3 queued items. (1)
[renderWidgetNotices() ~18717] Dashboard notices now get a pulsing "NEW"
highlight + dismiss (✕) button per notice, tracked per-URN in
localStorage — was rendering correctly before but was easy to miss as a
flat static banner. (2) [stuSetKillFloorVersion() ~6624, HTML ~5719]
Admin UI field to set the widget hard-block floor (minApkVersion) by
typing a build number, writing to its own davan_pub/student_widget_kill_floor
node — previously required a code edit to LATEST_STUDENT_WIDGET_APK.
[#broadcast-toast CSS ~3479, HTML ~4141] Broadcast toast changed from a
small bottom chip to a large centered popup with backdrop, matching the
welcome-toast pattern. (3) [DIGEST_TEMPLATE_HANDOFF.md] Nightly Digest
wording editor — new "NIGHTLY SUMMARY NOTIFICATION" block mirroring the
class-reminder editor exactly (wc-digest-title/body, Save/Reset/Preview,
wcSaveDigestTemplate() PATCHes digestTitle/digestBody onto the same
davan_pub/student_widget_notif_template node used by class-reminder
fields). Defaults verified byte-identical to Kotlin's
DEFAULT_DIGEST_TITLE/BODY. Kotlin/widget side for this was already done
in w60 per the handoff doc — this was the missing portal half.
VERSION : v8.87 (2026-08-28) — [renderLfResponseList() ~10045-10150] Added
Login Feedback per-question summary (N answered/total/%, IST "as of" date,
per-day breakdown, "Showing N responses" + date-grouped headers in the
response list). [switchTab()/switchStudentPanel() ~10520/~15170] Admin
tab + student panel now persist across refresh via sessionStorage. FIX:
STATE.students is an object not array — Object.values() before .filter().
FIX: 4 hardcoded version fallback spans (topbar + 3 footers) were frozen
at v8.37 while APP_VERSION had moved on — now synced and bumped alongside
APP_VERSION going forward (see VERSION BUMP CHECKLIST above).
VERSION : v8.80 (2026-08-24) — FIX: saveWidgetNotice() button ("Save
Notice") gave zero feedback during an "All Students" save — with ~450
students, the sequential get+set fan-out loop genuinely takes real time
and the button just sat spinning with no indication anything was
happening, which read as stuck even though it was working correctly.
Button label now shows live "Saving… X / Y" progress through the loop.
SEPARATE, NOT FIXABLE HERE: notices still won't appear on the physical
Android widget — DavanStudentWidget's Kotlin side has never been built
to read davan_pub/student_widget_notices/{URN} at all (documented at
build time as a "one-time Kotlin build" still pending). This portal file
can only ever write the data and show it in the portal's own web view;
making it appear on the actual home-screen widget needs a
DavanStudentWidget Kotlin change, a separate app build.
VERSION : v8.79 (2026-08-24) — CLEANUP: removed v8.78's temporary
[SEAT-DEBUG] console dump from stuRenderSeatBanner() now that it did
its job. The dump proved the "English shown too early" report was NOT
a portal bug — seat.perDay dates/room-rotation and the per-date subject
sort were already correct; English is genuinely the saved 2:45pm slot
on the actual 3rd exam date (12 Sep). Real fix belongs in the Internal
Timetable Create/Edit data itself (index.html), not this file.
VERSION : v8.78 (2026-08-24) — TEMP DIAGNOSTIC: added console.log dump
inside stuRenderSeatBanner() (F12-visible) printing the exact raw
seat.perDay array and, per date, the exact raw slots matched for it —
i.e. real data instead of another guess at the ordering bug. Open the
Internal Timetable ▸ My Class tab, F12 ▸ Console, and paste every
[SEAT-DEBUG] line back for the actual fix. Remove this block once found.
VERSION : v8.77 (2026-08-24) — REAL FIX, found by reading sync_db1_to_
db2.py and index.html directly, not by guessing. v8.76's fix (sorting
perDay by date) was based on an unverified assumption and changed
nothing, because it was never the bug — confirmed by reading
sync_sitting_to_urn_fanout()/_sitting_live_dates_for_session() directly:
perDay's date/room order was already correct (sorted chronologically,
proven in code). The ACTUAL bug was in [stuRenderSeatBanner() ~18842
slotsForDate], one level down from where v8.76 looked — sorting each
date's list of subjects by time_label as a STRING
('01:15pm...'.localeCompare('09:00am...')), which breaks the moment
sorted hours cross a digit boundary. That's why English (a later paper)
could render before an earlier one on the same date. FIX: exact port of
index.html's sitFindStudentSchedule() time sort (index.html ~52637-
52640, already proven correct there for the identical multi-subject-
per-session case) — parses time_label's leading H:MM into a plain
numeric key instead of comparing the label as text.
VERSION : v8.76 (2026-08-24) — FIX: "Your Seat" Day 1/2/3 labels
[stuRenderSeatBanner() ~18804] were assigned by raw seat.perDay array
index, trusting the sync script to write dates pre-sorted — it wasn't
guaranteed to, and Firebase array-node reads can reorder anyway. Result:
a later exam date (English, actually Day 3) could render as "Day 1".
perDay is now sorted by date before Day N labels are assigned, so the
label always matches real chronological order no matter the write/read
order underneath.
VERSION : v8.75 (2026-08-24) — FIX+FEAT, IA Eligibility banner + widget promo
card. [renderIAEligibilityBanner() ~line 18108]: unlocked rows are now
clickable, jumping to the live Internal Timetable panel (switchStudentPanel
('inttt')) so a student can verify actual exam dates for themselves instead
of assuming the banner also states scheduling — it never did, only the
binary eligible/not-eligible verdict, but with no way to cross-check that
read as wrong info. [stuApplyAppPageVisibility() ~24107, stuApplySidebar
WidgetStatus() ~16429]: dash-getapp-card no longer flashes "Set it up" for
an already-paired, actively-checking-in student before the async pairing
check resolves — card now stays hidden until the check explicitly confirms
not-linked, rather than showing first and narrowing after.
VERSION : v8.74 (2026-08-24) — FEAT: soft-nag vs hard-block choice for
publishing the student widget release, per explicit admin request to
soft-nag for the first few days of a new APK build before forcing it.
Previously "Publish Current Version to All" (#tab-widgetctrl, Widget
Control tab) was the only publish path and always wrote whatever
LATEST_STUDENT_WIDGET_APK.minApkVersion was hardcoded to [~line 6354] —
for w55 that had deliberately been set equal to apkVersion (55), meaning
this one button would hard-block every widget below w55 the moment it
was pressed, with no gentler option. New CONST
SOFT_NAG_FLOOR_APK_VERSION = 54 [~line 6370] and new function
wcBulkPublishLatestSoft() [~line 23804] write the SAME
davan_pub/student_widget_latest node as the existing
wcBulkPublishLatest(), same apkVersion, but hardcode minApkVersion to
this new constant instead of reading LATEST_STUDENT_WIDGET_APK's own
field — so widgets below w54 see the "update available" nag, not the
full-screen block, regardless of what minApkVersion is set to above.
Existing button relabeled "📣 Publish (Hard Block)" (unchanged function,
unchanged behavior) and new "🕊️ Publish (Soft Nag)" button added beside
it [~line 5561-5562, #tab-widgetctrl toolbar row]. Explain box beneath
the buttons (wcRenderPublishExplain() [~line 23830]) rewritten to show
both the soft floor and hard floor at once instead of describing only
one path, so it's clear which is currently live. To go mandatory later:
either raise SOFT_NAG_FLOOR_APK_VERSION to match, or just press Hard
Block, which already reads minApkVersion: 55 from the top-of-file
constant. No widget/Kotlin changes — portal-only.
VERSION : v8.73 (2026-08-23) — FEAT: Widget Notice, a generic reusable
status-line system, per explicit admin request for a way to push future
notices (fees due, reminders, anything) without ever needing a new widget
APK build again after the one-time Kotlin work eligibility-style features
already require. Built here in student_portal.html's own admin screen
(#screen-admin), NOT index.html — admin correctly pushed back on an
initial instinct to build it in the mother app, and a look at what already
exists here confirmed the portal's own Live Announcement Banner (all/class/
URN targeting, color picker, chip-based class selector) was already almost
exactly the right shape, so this reuses that same chip-building loop
(~line 11922, wn-class-chips added alongside notice-class-chips/
banner-class-chips) and getSelectedChips() rather than a second parallel
targeting system. New card "📲 Widget Notice" placed directly below the
Live Announcement Banner card. STORAGE: davan_pub/student_widget_notices/
{URN}, a per-URN ARRAY (not one global list) — a class or all-student
notice is FAN-OUT written into every matching student's own array at save
time (same architectural pattern as davan_pub/sitting_by_urn), so a future
widget build only ever needs to read its own URN's array, drop anything
past its expiresOn date, and render the rest as colored lines — it never
needs to know or care WHY a notice exists, all targeting logic lives here.
Sequential (not parallel) writes for an all-student save, deliberately, to
avoid bursting RTDB with hundreds of simultaneous writes. Expiry date
field per explicit admin confirmation (auto-hides, no manual cleanup
required, though manual removal is also supported via the active-notices
list at the bottom of the card, which groups identical notices shared
across many students into one line with a Remove button rather than
showing the same text hundreds of times). Web-side display already fully
working with zero widget/Kotlin dependency: new renderWidgetNotices()
[~line 18049], shown on the Dashboard right below the IA Eligibility
banner, reading the exact same RTDB path a future widget build will read
— proves the fan-out/storage shape end-to-end before any Android work is
scheduled. The widget (APK) side itself is NOT part of this session's
scope (separate Kotlin codebase, not editable from here) — see the
StudentWidgetProvider/StudentFetchWorker.kt spec discussed but not yet
written up as a formal handoff document.
VERSION : v8.72 (2026-08-23) — FEAT: IA Eligibility banner (built v8.69,
originally Internal Marks only) now also shown on Internal Timetable and
the Dashboard, per explicit admin request after confirming on a real
screenshot that the Internal Timetable panel — where a student actually
checks their exam seat, arguably more useful than the marks panel for a
"you are not eligible" warning — had no banner at all. renderIAEligibilityBanner()
[~line 17724] generalized to accept a target element id parameter instead
of a single hardcoded one, so all three placements share the exact same
render logic and RTDB read (davan_pub/ia_live_status/{IA1,IA2}) rather than
three separate copies that could drift apart. Internal Marks call site
updated to pass its id explicitly (#stu-ia-elig-banner, unchanged
behavior). Internal Timetable: new #stu-ia-elig-banner-tt, wired into
renderInternalsTimetable() as a fire-and-forget call that never blocks the
actual schedule render. Dashboard: new #stu-ia-elig-banner-dash, placed in
the HTML immediately after #dash-greeting and BEFORE #social-nudge-banner/
#sd-summary-top-card per explicit admin instruction — a normal stacked
block above the existing summary card in document flow, not an overlay on
top of it — wired into renderHomeDashboard() as the first line, same
fire-and-forget pattern. All three share the identical privacy boundary
already established at v8.69 — binary eligible/not-eligible only, never
the rule engine, TA numbers, or exemption status.
VERSION : v8.71 (2026-08-23) — FEAT: student widget release now auto-resolves,
per explicit admin request ("i cnt do this every time... i want a comon
link", then "give provision to enter manually... I will enter there by
my self" for the fallback). Mirrors index.html's wcpResolveLatestApk()
(built v1117 for the faculty widget) applied to the student widget, which
already self-reports its own version to davan_pub/student_widget_report
the same way the faculty one does. [stuResolveLatestWidgetApk() ~line
6180]: (1) apkUrl changed to GitHub's "latest release" URL pattern
(releases/latest/download/Davan.Student.apk) instead of a tag-pinned
one — GitHub itself keeps this pointing at whatever was most recently
published, so unlike the faculty widget's SHA-pinned raw-content URL
(which needs re-resolving via the commits API every time), this never
needs re-resolving at all once set, AS LONG AS every future release
keeps the same filename and is published as the repo's latest release
(the default). (2) apkVersion auto-raised to the MAX apkVersion any real
student widget has self-reported — install a new build on your own
phone once, exactly as already works for the faculty widget, and the
whole estate's nag number updates itself with zero manual entry.
LATEST_STUDENT_WIDGET_APK.apkVersion is now a FLOOR only, never lowered
by auto-resolve. MANUAL FALLBACK (explicit admin request, used only when
auto-resolve can't yet know about a release — e.g. published on GitHub
but not yet installed on the admin's own phone to generate a real self-
report): new input field in the Widget Control Panel [markup ~line
5416, stuSetManualApkVersion() ~line 6265] writes to
davan_pub/student_widget_manual_version; stuResolveLatestWidgetApk()
reads it as a second, independent floor-raiser — the manual number is
ONLY ever applied if it is higher than the auto-resolved ceiling, so a
stale or mistaken manual entry can never drag the real, self-reported
version backward. stuPublishLatestWidgetApk() now calls
stuResolveLatestWidgetApk() before publishing (previously would have
published whatever was hardcoded at page-load, defeating the point);
loadWidgetCtrlData() does the same before rendering the admin panel, so
"Set in this portal file" always shows the true resolved number, not a
stale constant.
VERSION : v8.70 (2026-08-23) — FEAT: student widget APK w51 published as a
proper GitHub Release asset instead of the old harshgujjar.github.io
raw-file host, mirroring the same fix just done for the faculty widget in
index.html (CODE_BUILD 1220) — raw.githubusercontent.com/github.io-hosted
raw files are not backed by a real download CDN and were reported slow;
GitHub Release assets are. [LATEST_STUDENT_WIDGET_APK ~line 6154]:
apkUrl changed to https://github.com/harshgujjar/davan-attendance/
releases/download/w51/Davan.Student.apk; apkVersion bumped 48->51 to
match the w51 release tag (explicit admin confirmation — w51 is the real
new build number, not just a label). minApkVersion left at 29 per this
file's own standing rule (soft nag only on routine releases; only moves
for a genuine safety/security fix like w28's pairing-hijack patch).
Actual release asset filename confirmed as "Davan.Student.apk" (dots) —
corrected the nearby comment that previously assumed
"DavanStudentWidget.apk", so future releases reference the real naming
instead of a stale guess.
VERSION : v8.69 (2026-08-23) — FEAT: IA Eligibility banner [spanel-internals,
new #stu-ia-elig-banner, renderIAEligibilityBanner() ~line 17505]. Per the
mother app (index.html)'s own IA Rules Engine build across CODE_BUILD
1198-1218, this portal previously showed nothing about internal-exam
eligibility at all — the whole feature (attendance-based shortage, the
+1/+2 auto-clearance rule, temporary-attendance adjustments, college
exemptions) lived entirely on the admin side. Per explicit admin decision,
students should now see a binary eligible / not-eligible status per
internal, sourced from a NEW RTDB path davan_pub/ia_live_status/{IA1,IA2}
that the mother app now publishes (iaePublishLiveStatus(), throttled to
roughly every 2 minutes while an admin session is open) — this portal ONLY
ever reads that already-computed { flagged, X, Y, locked } map, never any
raw attendance, TA number, or which mechanism (rule/exemption/permission)
produced the result — matches the mother app's own privacy rule verbatim:
a student who became eligible via the rule engine or a college exemption
must look identical, from their own side, to one who simply had good
attendance. Shows "Live — may still change" before an exam's cutoff date
has locked, "Final" after. Gated behind the SAME canShow('internals')
check the marks table already uses, plus a new per-student/class/global
'iaEligibility' control key using the existing controls.byUrn/byClass/
global mechanism, so admin can hide this specific banner independent of
the marks table itself if needed. Fire-and-forget from renderInternals() —
never blocks or delays the actual marks table render if the RTDB path is
slow or doesn't exist yet (e.g. no admin session has published anything
for the current exam window).
VERSION : v8.68 (2026-08-22) — BUG FIX [intRenderTable() ~line 18175]:
Internal Timetable panel (spanel-inttt) showed a hardcoded "Harsharaj A
Gujjar" whenever meta.director was blank, and a STATIC "DIRECTOR" label
that never read meta.director_designation at all (so a real "Principal"
saved in the admin app had no way to ever display here) — same hardcode
bug already fixed in the admin app's index.html at v1160/v1169
(intRenderTable there, shared-origin function, this copy never got that
fix since it's a separate file). meta.director/director_designation
sync correctly from DB1→DB2 via sync_db1_to_db2.py's plain internals_
current mirror (confirmed: that path has no field filtering, copies the
whole meta blob as-is) — the actual display bug was entirely in this
file's own render function, not the sync. Fix: no longer defaults to a
wrong name; shows "(Director not set)" placeholder if genuinely blank
instead of substituting incorrect real data on a page students see, and
the label now reads the real saved designation (uppercased) instead of
the static word "DIRECTOR".
VERSION : v8.65 (2026-08-21) — FEAT: student widget w48 — the "Upcoming
Internal" card only ever showed the single soonest exam
(nextInternalName/Date/Room/Bench/SeatNo, fixed w47). Real request: a
student's internal period can span multiple days with different
subjects (confirmed live: 3 real exam days, different subject/date/
time/room each day per this college's current internal), and all of
them should be listed, not just the next one. [StudentWidgetStats.kt:
new UpcomingInternalSlot ~37, upcomingInternalSlots field ~250]
[StudentFetchWorker.kt: new fetchAllUpcomingInternalSlots() ~2260,
companion to the existing fetchUpcomingInternalFromTimetable() which
deliberately keeps only the soonest match — unchanged, still used for
the compact header] collects EVERY upcoming batch-matched slot from
davan_pub/internals_current.slots, each resolved against
sitting_by_urn.perDay for its OWN room (rotates per day) with shared
bench/seatNo. [StudentWidgetRenderer.kt: renderPageInternals() "upcoming"
~747] reuses the existing 3-row mechanism already used by the "marked"
state for a different purpose — no new layout views added, per this
file's own documented view-count caution. [StudentWidgetPrefs.kt: new
encodeUpcomingSlots()/decodeUpcomingSlots() ~276, wired into encode()/
decode() at index 70] — wired in from the SAME build the field was
added, deliberately avoiding a repeat of the exact w28-to-w46 gap that
caused the seat/room bug this session. [student_portal.html:6049]
apkVersion 47->48. [StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 47->48.
VERSION : v8.64 (2026-08-21) — FIX (real root cause found): student
widget w47 — the seat/room mystery (w28 through w46, many rounds) is
resolved. w46's portal-visible seatDebug field proved conclusively via
live logcat that fetchNextInternalSeat() was working perfectly all
along: `SUCCESS room='S7' bench='B' seatNo='6'`, matching the real data
exactly. Yet the widget screen still never showed it, even after a
manual refresh. Root cause: [StudentWidgetPrefs.kt: encode()/decode()]
nextInternalRoom/nextInternalBench/nextInternalSeatNo were NEVER wired
into this file's SharedPrefs save/load pair at all — added in w28,
same version as mustUpdateApkUrl (which WAS wired in correctly), simply
missed for these three fields specifically. Since the widget always
renders from THIS cache (StudentWidgetProvider.renderFromCache), not
directly from a fresh fetch result, a correctly-fetched seat was being
silently discarded on every single save/load round-trip — exactly
matching the reported symptom for 19 build versions. Same bug class,
same fix shape as an existing documented Aug-2026 fix in the same file
for attendanceRows/currentClassHeld/currentClassAttended, which had the
identical problem. Fixed: both fields appended at indices 67-69,
following the file's own established append-only-at-the-end convention
for backward-compatible pre-upgrade blobs. Per explicit instruction,
minApkVersion left unchanged (soft nag) despite this being a
long-standing broken feature — standing rule takes precedence.
[student_portal.html:6024] apkVersion 46->47. [StudentFetchWorker.kt:44,
app/build.gradle:33-34, STUDENT_WIDGET_README.md:17] version markers
46->47.
VERSION : v8.63 (2026-08-21) — FEAT: student widget w46 — every prior
round of the seat/room investigation (w42-w45) required pulling adb
logcat with a physical device attached, which is slow. Per request,
routed the same diagnostic trail through an already-existing, already
portal-visible channel instead: [StudentFetchWorker.kt: new
seatDebugTrail ~1728, fetchNextInternalSeat() mark() helper ~2305]
fetchNextInternalSeat()'s full checkpoint trail (ENTERED, checkpoints
A-H, SUCCESS, or an EXCEPTION line — new, the outer catch previously
only ever logged to Log.w, invisible anywhere else) now writes to BOTH
Log.d (still useful with a device attached) and a new seatDebugTrail
list. [StudentFetchWorker.kt: debugInfo assembly ~958] appends it as
`seatDebug=[...]`, matching the existing `lpKeys=[...]` convention
exactly. debugInfo already auto-publishes to
davan_pub/student_widget_report/<code>/scheduleDebug on every fetch
cycle (pre-existing, w15+) and that field is ALREADY displayed in the
admin portal's per-student device line (wcDeviceLine(), "two clicks"
per its own comment) — this was simply never wired up for this specific
function's checkpoints before. [student_portal.html: wcHighlightDebug()
~22464] added a `seatDebug=[...]` highlighter matching the existing
`lpKeys=[...]` one, colored red when the trail shows a real failure
signal (EXCEPTION, no usable room, no sitting_by_urn node) so a healthy
trail doesn't read as an error. No adb/logcat required going forward —
open the student's row in the admin portal, expand the device line, and
the full trail is right there. [student_portal.html:5998] apkVersion
45->46. [StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 45->46.
VERSION : v8.62 (2026-08-21) — DIAG: student widget w45 — w44's entry-log
fired for the first time (`fetchNextInternalSeat: ENTERED
urn='U13NU25S0031'`), a genuine result, but nothing from inside the
function followed it — no early-return diagnostic, no success return, no
outer catch's failure log either. Hand-traced the exact real Firebase
data for this student (meta.n=1, internalNum="1", bench="B", seatNo=6,
perDay=[{2026-09-09,S7},{2026-09-10,S3},{2026-09-11,S4}]) against every
line of this function's logic — everything resolves correctly on paper,
no bug found by inspection. Also ruled out Firebase security rules as a
cause: the SAME davan_pub/internals_current tree (via a sibling read in
fetchUpcomingInternalFromTimetable()) already succeeds in the SAME fetch
cycle to produce the "Upcoming: Internal — English" card, so a
permissions block on this node is inconsistent with that. Since neither
code-tracing nor rules explain a function that enters but produces zero
further output — not even a thrown exception — added a checkpoint
Log.d() after EVERY step in the function (both await() calls, every
intermediate value, the perDay resolution, and the final
success/failure returns), so the exact step it stops at is identified
directly on the next capture instead of inferred. No logic changed.
[student_portal.html:5976] apkVersion 44->45. [StudentFetchWorker.kt:44,
app/build.gradle:33-34, STUDENT_WIDGET_README.md:17] version markers
44->45.
VERSION : v8.61 (2026-08-21) — DIAG+FIX: student widget w44 — w42's gate
logging (canShow(internalTimetable)=true, internalsState=upcoming, both
confirmed passing) proved the call to fetchNextInternalSeat() SHOULD be
happening, yet a real capture still showed zero log output from inside
that function — not even its own w33/w34 early-return diagnostics.
Two things done: (1) [StudentFetchWorker.kt: fetchNextInternalSeat()
~2278] added an unconditional entry-point log as the literal first
line, before even the urn.isBlank() check, so "never entered" is now
distinguishable from every other silent-return case with certainty on
the next capture. (2) Found and fixed one genuinely remaining unguarded
`getValue(String::class.java)` inside this same function's
normalizeDate() helper (~2332) — missed during the w33/w34 hardening
pass despite being the exact same confirmed throws-on-mismatch risk
already fixed at every other call site in this function; if it threw,
the function's own outer catch would still log, but a real capture
showed no such line either, so this was a plausible but unconfirmed
contributor, fixed regardless since it's a genuine, demonstrated bug
class in this exact function. [student_portal.html:5956] apkVersion
43->44. [StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 43->44.
VERSION : v8.60 (2026-08-21) — FEAT: student widget w43 — footer text
("[w42 · v8.59] · just now · GC8U7J") was squeezed onto one horizontal
row alongside the page label, dots, refresh icon, and next-page arrow —
as the version/sync/pair-code string grew longer over this session's
many builds, it no longer fit and was getting clipped.
[widget_layout_student.xml: stu_footer] restructured from a single
horizontal LinearLayout into a vertical one containing two rows: the
top row keeps every existing element (page label, dots, refresh,
next-page arrow) exactly as before, unchanged and unreordered; a new
second row gives stu_tv_synced the full widget width on its own line
(maxLines=2, ellipsize=end as a safety net if it's ever still too long).
No Kotlin/renderer changes needed — every view ID referenced by
StudentWidgetRenderer.kt is unchanged, only the XML structure around
them. [student_portal.html:5940] apkVersion 42->43.
[StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 42->43.
VERSION : v8.67 (2026-08-21) — FEAT: "Your Seat" banner — replaced the
per-subject flex-card lines with an actual table (Day / Date / Room /
Bench·Seat / Subject), matching the requested layout exactly: Room and
Bench/Seat shown once per date, every subject scheduled that date
stacked as its own line inside the Subject cell with its time
(⏰ hh:mmam to hh:mmpm), date shown as "dd/mm/yyyy (Ddd)". Supersedes
v8.66's per-line room+subject approach, which repeated the room text
once per subject instead of grouping under one row per date.
[student_portal.html: stuRenderSeatBanner() ~18046 perDay branch,
outer wrapper switched from align-items:center to flex-start so the
table isn't vertically centered against the seat emoji]
VERSION : v8.66 (2026-08-21) — FEAT: "Your Seat" banner — on days with 2
internals (e.g. one morning, one afternoon), each perDay line now shows
its own subject + time next to the room instead of one bare date line,
so a student can tell which exam a given room/date is for. Cross-
references seat.perDay dates against internalsData.slots (already
fetched for the timetable table), filtered to the student's own batch
via myBatch, expanding into one line per subject+time actually
scheduled that date. Falls back to the old date-only line when no
matching slot is found. [student_portal.html: stuRenderSeatBanner()
~18035, stuUpdateInternalTable() call site ~18021 now passes myBatch
through]
VERSION : v8.59 (2026-08-21) — DIAG: student widget w42 — separate from
the lesson-plan fix (confirmed fully working: w41's own logcat shows
`fetchLessonPlanIndexed: resolved 9/9 keys` with correct English/
Kannada/Java results), the seat/room/bench line under "Upcoming:
Internal — English" is still not appearing for V NEESHA (URN
U13NU25S0031). Admin confirmed the "Internal Timetable" Controls toggle
was OFF, turned it ON, refreshed — a real capture STILL shows no
`fetchNextInternalSeat:` log line at all, meaning
[StudentFetchWorker.kt ~801] `if (internalsState == "upcoming" &&
canShow("internalTimetable"))` never became true even after the
Controls change. This is the SAME shape of mystery that took w37/w38 to
resolve for canShow("lessonPlan") — rather than guess a second time,
applying the same fix: log canShow("internalTimetable")'s actual return
value directly, alongside internalsState, right at the gate. No other
change. [student_portal.html:5923] apkVersion 41->42.
[StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 41->42.
VERSION : v8.58 (2026-08-21) — FIX: student widget w41 — w40 confirmed
working end to end on a real device (footer [w40 · v8.57], V NEESHA,
Kannada correctly resolved and showing "20 of 49 topics covered" instead
of "haven't been scheduled"/crash) — but the topic TEXT itself showed
bare numbers ("▶ 19", "◀ Last class: 18") instead of real words.
Confirmed NOT a widget-vs-data mismatch by direct comparison: the SAME
student's SAME Kannada lesson plan in this file's own admin view showed
real text for topic 19 ("ಆನಂದ ಕಂದರ ಶೀಗೆ ಹುಣ್ಣಿಮೆ ಕಥಿತ"), proving the
underlying data is fine. Root cause: [student_portal.html, e.g. ~13785,
~16829, ~17471] this file has always built topic display text from TWO
separate fields — `[t.topic, t.sub_topic].filter(Boolean).join(' — ')`
— where `topic` is often just the bare serial number and `sub_topic`
holds the real descriptive text. [StudentFetchWorker.kt:
fetchLessonPlanIndexed() topicAt() ~2008] only ever read `topic` alone —
a missing-field bug, not a wrong-field-name bug, confirmed by this
direct portal-vs-widget comparison on identical data. Fixed to join both
fields the same way, and hardened the `topic` field read against the
now-3x-confirmed risk that a field assumed String can actually be
numeric. [student_portal.html:5902] apkVersion 40->41.
[StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 40->41.
VERSION : v8.57 (2026-08-21) — FIX: student widget w40 — w39's
lesson-plan fix crashed on a real device before it could show anything:
`fetchLessonPlanIndexed: failed: Failed to convert a value of type
java.lang.String to long`, caught by the outer try/catch, hence
`lpKeys=[]` right after (a different empty-map cause than w37/w38's —
those were canShow()-related, this was a mid-function crash). Root
cause: [StudentFetchWorker.kt: fetchLessonPlanIndexed() fallback path,
~1926 pre-fix] `entry.child("updated_at").getValue(Long::class.java) ?:
...getValue(String::class.java)...` — a THIRD instance of a bug class
already fixed twice before in this file (w33's internalNum/bench/room,
w34's perDay date): a Kotlin/Firebase getValue(SpecificType::class.java)
call can THROW on a real type mismatch rather than return null, so the
intended "?: try the other type" fallback never runs — the exception
skips past it entirely and crashes the whole function. Fixed by reading
via getValue() (Any?) and coercing explicitly, same pattern as the prior
two fixes. Also, per the same instruction to fix from the core: found
two MORE bare getValue(Long::class.java) calls elsewhere in this file
with the identical unguarded risk (urgentSentAt/urgentAckedAt, notices'
createdAt) and hardened both preemptively via a new shared
readLongFlexible() helper, rather than waiting for a fourth crash on a
different field to justify it. [student_portal.html:5879] apkVersion
39->40. [StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 39->40.
VERSION : v8.56 (2026-08-21) — FIX (root cause): student widget w39 —
w38's detailed logging gave the conclusive answer: `lessonPlan has 198
total keys, 9 matched this class` (correct), but ALL 7 real subjects
(English, Kannada, Java Programming Lab, etc.) scored 0 against every
one of those 9 correctly-matched keys. Root cause confirmed and fixed
per explicit instruction — "fix from the core and never fix using fuzzy
fix": [StudentFetchWorker.kt: subjectMatchScore() ~1676] its
`shorter<5` length guard rejected every comparison outright, because
this college's real lessonPlan keys/codes ARE short abbreviations ("Eng",
"Kan", "Jpro") — exactly the legitimate case that guard was never
designed to allow. [student_portal.html: resolveLPSubjectName()
~20411-20436] already solves this correctly and was never fuzzy —
it resolves the short CODE to a proper full name via a lookup table
FIRST, then compares like-for-like. [StudentFetchWorker.kt: new
LP_CODE_NAMES ~1690, lpResolveCodeName() ~1783] ports that table (~90
entries) and resolution chain exactly. [StudentFetchWorker.kt:
fetchLessonPlanIndexed() ~1839-1920] matching rewritten: extract each
key's code via extractCode() (NOT a naive split("-")[1] — confirmed via
simulation against this college's real keys that codes like "INPRO -
Lab" contain their own embedded "-" which breaks positional splitting),
resolve it, then match against the schedule subject by containment with
a closest-length tiebreak (confirmed via simulation this correctly
separates Theory from Lab pairs sharing a base name, e.g. "Internet
Programming" vs "Internet Programming Lab", which longest-match
wrongly conflated). Old subjectMatchScore() kept only as an explicit
last-resort fallback for a code that doesn't resolve via the table at
all. [student_portal.html:5850] apkVersion 38->39.
[StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 38->39.
VERSION : v8.55 (2026-08-21) — DIAG: student widget w38 — w37's own
diagnostic logging inside fetchLessonPlanIndexed() NEVER FIRED at all in
a real capture (neither its "subjects empty" nor its main line), which
only happens if canShow("lessonPlan") returned false before the function
was ever called. But BOTH traceable causes for that were ruled out with
real evidence, not assumption: [admin Controls panel, screenshot] Global
"Lesson Plan" toggle confirmed ON, no byClass/byUrn override exists for
Davan-BCA-Sem3-SecA or U13NU25S0031; and [StudentFetchWorker.kt ~490] the
"page locks for ..." log line (only prints when lockedIdx is non-empty)
never appeared in the same capture either, ruling out davan_pub/
page_locks. Every branch of canShow("lessonPlan") traced from source
appears to allow it, yet the real device disagrees — rather than trace a
fourth branch blind, [StudentFetchWorker.kt: buildFullStats() ~612] now
logs canShow("lessonPlan")'s actual boolean return value directly,
alongside the URN and class it was evaluated for. This is the most
direct possible check and should be conclusive on the next capture.
[student_portal.html:5831] apkVersion 37->38. [StudentFetchWorker.kt:44,
app/build.gradle:33-34, STUDENT_WIDGET_README.md:17] version markers
37->38.
VERSION : v8.54 (2026-08-21) — DIAG: student widget w37 — w36's
diagnostic logging worked and RULED OUT the wrong-document theory: real
logcat capture (U13NU25S0031, same student who showed "Phrases" stuck
for English) showed `buildFullStats: lpKeys=[]` — completely empty, not
a mismatch. That means no subject matched ANY lesson-plan document on
this capture, a different (and more basic) failure than "matched the
wrong one". [StudentFetchWorker.kt: fetchLessonPlanIndexed() ~1687-1727]
had zero internal logging, so an empty result couldn't be told apart
from three different real causes: empty subjects list in, empty/
unreadable davan_pub/lessonPlan node, or every key rejected by
keyMatchesClass() (which has separate Davan/Nutana course-string
handling — this student's URN prefix suggests Nutana campus, worth
checking directly rather than assumed). Added logging that prints
studentClass, the parsed course/semNum/semRom/section, total
lessonPlan key count, and how many survived the class filter — plus a
per-subject line when a subject scores 0 against every matched key. No
functional fix yet — this build exists to get the ONE more logcat
capture needed to pinpoint the exact cause instead of guessing a fourth
time. [student_portal.html:5810] apkVersion 36->37.
[StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 36->37.
VERSION : v8.53 (2026-08-21) — FIX: student widget w36 — w35's row-limit
fix was correct but incomplete: user confirmed both Theory and Lab now
appear, but the Theory-TIME slot was showing the WRONG LABEL
("Java Programming Lab") instead of "Java Programming". Root cause
confirmed against this file's own logic:
[student_portal.html: stuLmAllocMatchesCode() ~18085-18089] checks
`isLabSlot !== allocIsLab` and rejects a mismatch BEFORE falling through
to base-code comparison — [StudentFetchWorker.kt: lmAllocMatchesCode()
~1162, old comment] this check was explicitly never ported, on the
documented (and wrong) assumption it was "display-only". Without it,
when Theory and Lab share the same base code after normalization (e.g.
both -> "Java Programming"), `classAllocs.firstOrNull{}` could grab
whichever allocation sorted first in the list regardless of which slot
it actually was. Fixed: new [StudentFetchWorker.kt: lmIsLabCode() ~1169]
ports stuLmParseCode()'s isLab detection exactly (the "SUBJ A1·Lab 1" and
"SUBJ A1(A)" patterns); lmAllocMatchesCode() now rejects a Theory/Lab
mismatch first, matching the portal exactly. Also, separately reported:
English's lesson-plan topic always shows "Phrases" regardless of day —
[StudentFetchWorker.kt: buildFullStats() ~817] the diagnostic data
needed to answer this (lpKeyUsed — which lessonPlan document each
subject matched) was already being computed and stored in
debugInfo/SharedPrefs every cycle but NEVER printed to logcat or shown
anywhere, genuinely invisible without a SharedPrefs dump. Added a
Log.d() so the next logcat capture answers directly whether English is
matching the right lesson-plan document (if so, "Phrases" is genuinely
the last topic marked done by faculty, not a code bug) or a wrong one.
[student_portal.html:5781] apkVersion 35->36. [StudentFetchWorker.kt:44,
app/build.gradle:33-34, STUDENT_WIDGET_README.md:17] version markers
35->36.
VERSION : v8.52 (2026-08-21) — FEAT: student widget w35 — a real 4th/5th
class for the day (e.g. Java Programming Theory AND Lab as separate
periods, both still upcoming) was silently cut off the widget's "Today's
Classes" list with no error anywhere, even though the SAME data rendered
correctly in student_portal.html's own timetable view. Root cause was
NOT the timetable data or the matching logic (both traced and confirmed
correct) — [StudentWidgetRenderer.kt ~570] the render loop only ever
filled a FIXED 3 rows (`rowIds = listOf(stu_tv_schedule_1, _2, _3)`), so
any upcoming period beyond the 3rd had nowhere to draw at all.
[widget_layout_student.xml ~445-475] added two more identical rows
(stu_tv_schedule_4, _5); [StudentWidgetRenderer.kt ~570] rowIds extended
to include them — the existing render loop already handles any list
length generically, no other logic change needed.
[student_portal.html:5765] apkVersion 34->35 (soft nag, minApkVersion
unchanged). [StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 34->35.
VERSION : v8.51 (2026-08-21) — FIX: student widget w34 — w33's own new
diagnostic logging caught this live, exactly as designed:
`fetchNextInternalSeat: failed: Failed to convert value of type
java.lang.Long to String` (ASHOKA T S / U13DI25S0027, adb logcat). w33
fixed internalNum/bench/room's type-mismatch risk but explicitly left
`perDay[].date` as a fixed String read, reasoning dates are consistently
ISO strings throughout the system — the live crash proved that
assumption wrong for this specific field. [StudentFetchWorker.kt:
fetchNextInternalSeat() ~1974] Fix is NOT a bare .toString() coercion
like the others — a raw epoch Long's .toString() would produce
millisecond garbage ("1757347200000") incomparable against the ISO
todayStr ("2026-09-09"), silently corrupting the "today or later" pick
instead of crashing. New local `normalizeDate()` handles both real
possibilities explicitly: an ISO string passes through unchanged; a Long
is formatted through the same "yyyy-MM-dd" formatter used for todayStr,
so the date comparison stays meaningful either way. Confirmed in the
SAME logcat capture that the w30 PWA-first-tap fix (routing to installed
WebAPK org.chromium.webapk.a62122dc747401434_v2) is firing correctly on
every tap — that part was never broken; the "already installed" prompt
blocking a fresh reinstall earlier was a Chrome-side stale registration,
unrelated to this codebase, resolved by clearing site data and
reinstalling via Chrome's "Install app" (not "Create shortcut", which
only makes a plain bookmark). [student_portal.html:5740] apkVersion
33->34. [StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 33->34.
VERSION : v8.50 (2026-08-21) — FIX: student widget w33 — seat/room line
still missing under the "Upcoming: Internal — English, 09 Sep 2026" card
on w32, confirmed live (ASHOKA T S / U13DI25S0027 — Room S3/S4/S5 · Bench
J · Seat 29 correct in the portal, absent on the widget). Root cause:
[StudentFetchWorker.kt: fetchNextInternalSeat() ~1955]
`seatSnap.child("internalNum").getValue(String::class.java)` assumed a
fixed String type for internalNum without verifying it — but
this file's OWN currentN read three lines above already handles the
identical field ambiguously (Int-then-String fallback), and this app's
own stuRenderSeatBanner() (~17673) defensively wraps the same field in
String(seat.internalNum) rather than assuming a type. A genuine Kotlin/
Firebase type mismatch on getValue(SpecificType::class.java) can THROW
rather than return null (confirmed via a real-world Firebase Android
forum report of this exact failure), which the function's own outer
try/catch was silently swallowing — the whole seat fetch failed and
returned blank with nothing visible anywhere, which is why the Upcoming
card rendered (that logic is unrelated, fixed in w32) but the seat line
never appeared. Fixed by reading internalNum (and bench/room/perDay's
room, same risk) via getValue() + toString() instead of a fixed type,
matching the portal's own defensive coercion. Also added Log.d() at
every remaining silent-blank point in this function (missing
sitting_by_urn node, stale-internal mismatch, no usable room) and made
the outer catch log the full exception object, not just its message, so
a genuine future failure shows a real stack trace in logcat instead of
one line. [student_portal.html:5712] apkVersion 32->33 (soft nag,
minApkVersion unchanged). [StudentFetchWorker.kt:44,
app/build.gradle:33-34, STUDENT_WIDGET_README.md:17] version markers
32->33.
VERSION : v8.49 (2026-08-21) — FIX: student widget w32 — internals card
still said "haven't been scheduled yet" on w31 despite the real fix,
confirmed live against ASHOKA T S / U13DI25S0027 (portal correctly showed
Room S3/S4/S5 · Bench J · Seat 29, widget still blank). Root cause:
[StudentFetchWorker.kt: fetchUpcomingInternalFromTimetable() ~1830] w31
parsed internals_current.slots[].date with "dd MMM yyyy", copied from the
unrelated fetchInternalCalendarEvents()'s calendar-entry format — but the
real field is stored as ISO "yyyy-MM-dd" (confirmed from this file's own
intRenderTable()/fmtDateApp() at ~17739, which does
`new Date(str+'T00:00:00')` — that function only FORMATS the value for
display, the stored value itself is ISO). The mismatched parse silently
failed for every slot, so no date ever passed the "today or later" check
regardless of whether the batch_name matched. Fixed the format string;
also added diagnostic Log.d() calls at each early-return point (blank
batch, missing node, no slots, no date match) so a future no-match logs
WHY instead of silently returning null — see W31_CHANGES.md's own
"share one real batch_name" ask, now unnecessary since the real bug
wasn't the batch-matching logic at all. [student_portal.html:5691]
apkVersion 31->32 (soft nag, minApkVersion unchanged at 29).
[StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 31->32.
VERSION : v8.48 (2026-08-21) — FEAT: student widget w31 — real internal
timetable as the source for the widget's "Upcoming" internals card.
[student_portal.html:5671] LATEST_STUDENT_WIDGET_APK.apkVersion 30->31
(soft nag, minApkVersion left at 29 per standing rule). Actual fix lives
in the APK: [StudentFetchWorker.kt: fetchUpcomingInternalFromTimetable()
~1816, motherClassToInttBatch() ~1804] internalsState was driven entirely
by a davan_pub/calendar entry whose TITLE happened to contain the word
"internal" (see w29's own changelog, which already flagged this as a
known gap) — never by davan_pub/internals_current, the real node
index.html's Internals module writes and this portal's own Internal
Timetable panel already reads (loadInternalsTimetable() above). An admin
could build a complete internal exam timetable with real seat
allocations and the widget would still say "haven't been scheduled yet".
Fix reads internals_current.slots directly, matches the student's batch
(ported stuClassToInttBatch()'s "II YEAR BCA (A)" -> "II BCA" logic),
and tries this FIRST; [buildFullStats() ~752] falls back to the old
calendar-title guess only if internals_current has nothing for that
batch — additive, not a replacement, for colleges that only ever used
the calendar entry. [StudentFetchWorker.kt:44, app/build.gradle:33-34,
STUDENT_WIDGET_README.md:17] version markers 30->31.
VERSION : v8.47 (2026-08-21) — FIX: v8.45's tap-to-pair auto-repair
silently did nothing for students on legacy auth. [student_portal.html:
stuTryFirebaseAutoRepair() ~5942] that function required a live
firebase.auth().currentUser to re-verify identity, but stuAuthenticate()'s
'legacy'/'legacy-master' modes (~6644-6683, still an active login path —
see the Phase-6 note above it) never call signInWithEmailAndPassword(),
so currentUser is genuinely null for those students — auto-repair always
fell through with nothing on screen, same failure class v8.29's banner
work was meant to end. FIX: split the two failure cases. A live session
that MISMATCHES the restored URN still refuses silently (real
stranger-takeover protection, unchanged). A MISSING session now sets
STATE._widgetNeedsConfirm and [stuRenderGreeting() ~15430, factored into
new stuRenderWidgetPairBanner() ~15398] renders a one-tap "Pair this
widget?" banner; tapping it (new stuConfirmWidgetPair() ~5904) is treated
as the same category of proof _freshLogin is — an explicit decision, just
lighter than retyping a password — and hands off to the existing
stuCompleteWidgetPairing() unchanged. Also fixed an ordering bug in the
same patch: [goToDashboard() ~7497] stuTryFirebaseAutoRepair() was
fire-and-forget, so the banner flag it sets was written AFTER
stuRenderGreeting() had already painted for that page load and never
appeared until some unrelated re-render. Now awaited, with an explicit
second stuRenderWidgetPairBanner() call right after.
VERSION : v8.46 (2026-08-21) — FEAT: student widget w30 — PWA-first tap.
[student_portal.html:5636] LATEST_STUDENT_WIDGET_APK.apkVersion 29->30 (soft
nag only — minApkVersion deliberately left at 29, see standing rule in the
comment above that line). Actual fix lives in the APK, not this file:
[StudentWidgetProvider.kt: resolveWebApkPackage() ~350, buildOpenPortalPendingIntent() ~394]
tapping the widget now queries PackageManager for an installed WebAPK
handling this exact URL and targets it via setPackage(), instead of a bare
ACTION_VIEW that was defaulting to a plain Chrome tab even with the PWA
installed. [AndroidManifest.xml: <queries> block] added so that query can
see the WebAPK at all under Android 11+ package-visibility rules — without
it the new code silently no-ops and always falls back to Chrome.
[StudentFetchWorker.kt:44, app/build.gradle:33-34, STUDENT_WIDGET_README.md:17]
THIS_APK_VERSION/versionCode/versionName/CURRENT_VERSION 29->30, kept in
sync per the existing auto-increment rule.
VERSION : v8.45 (2026-08-21) — FEAT: "auto connect" for the widget-tap
pairing flow. [ADDENDUM, added retroactively: the literal first edit of
this session, before this v8.45 entry existed, was
[student_portal.html:6073] LATEST_STUDENT_WIDGET_APK.minApkVersion
28->29 (hard-block raised on request — w28's pairing-hijack fix, see the
inline comment directly above that line for the full reasoning). This
never received its own VERSION header entry at the time, only the
inline code comment — a real gap against the hard rule that every edit
needs a chain log entry. No free version number exists to insert it
correctly in chronological order (v8.40-v8.44 are all already taken by
real entries), so it's recorded here instead of renumbering everything
below.]
[student_portal.html: goToDashboard() ~7406, stuTryFirebaseAutoRepair()
~5867] A student already signed in (restored session, no password just
typed) who taps their own unpaired widget now pairs it with zero extra
taps — previously this silently did nothing (v8.32's fix, correctly, only
allows pairing on _freshLogin). Bridges the gap WITHOUT reopening that
hole: gated on STATE._pairCodeFrom==='url' (proves a real tap just
happened, not a bare page open) AND a live firebase.auth().currentUser
email match against the restored URN (proves real Firebase identity, not
a trusted localStorage blob). On match, delegates to the existing
stuCompleteWidgetPairing() unchanged — same ownership guard, same
takeover refusal, same audit log.
VERSION : v8.44 (2026-08-21) — FEAT: Internal Timetable now has its own
VISIBILITY CONTROLS toggle ("Internal Timetable") instead of piggybacking
on the weekly class Timetable flag. Added 'internalTimetable' to
CONTROL_FLAGS (so it auto-gets byClass/byUrn override support + checkbox
load, same as every other flag), new checkbox row in Controls tab right
after Timetable, and renderInternalsTimetable() now checks
canShow('internalTimetable') instead of canShow('timetable').
VERSION : v8.43 (2026-08-21) — FEAT: "Your Seat" banner now shows one room
line PER EXAM DAY instead of a single fixed room. Admin confirmed rooms now
rotate per day (anti-cheating rotation) while bench/seat stay fixed — old
banner kept showing only the Day-1 room for every date. Reads the new
seat.perDay array ({date, room} per real exam day, written by
sync_db1_to_db2.py v2.9.0's sync_sitting_to_urn_fanout()); falls back to the
old single-room line if perDay is missing (older sitting_by_urn record).
VERSION : v8.42 (2026-08-20) — FEAT: "Your Seat" banner now shows Bench letter (e.g. "Room
          S3 · Bench C · Seat 7"), sourced from a new seat.bench field on davan_pub/
          sitting_by_urn/{URN} — computed SERVER-SIDE by sync_db1_to_db2.py v2.8.0's exact
          Python port of index.html's own sitBenchLetter() formula, not recomputed client-side,
          so there is exactly one bench-letter formula across both apps and this can never
          silently disagree with what the admin app itself shows for the same seat.
VERSION : v8.41 (2026-08-20) — FIX: "Your Seat" banner's session label (Morning/Afternoon
          chip) compared seat.session against lowercase 'morning'/'afternoon', but the real
          data at davan_pub/sitting_by_urn stores it as 'MORNING'/'AFTERNOON' (confirmed via
          F12 dump of the underlying DB1 path) — session label silently never showed even
          though Room/Seat still rendered fine. Comparison is now case-insensitive.
VERSION : v8.40 (2026-08-20) — FEAT: "Your Seat" banner on the Internal Timetable panel's
          My Class view — shows the student's own exam room + seat number (e.g. "Room S2 ·
          Seat 14"), sourced from davan_pub/sitting_by_urn/{URN}, a new per-student fanout
          (sync_db1_to_db2.py v2.5.0) built specifically so this stays a single-key, single-
          student lookup — the raw DB1 seating blob (every student's seat in every room) is
          never mirrored to DB2 in any form a client could enumerate. Banner only shows when
          the seat's internalNum matches the currently-displayed internal's meta.n, so a seat
          saved for an older internal doesn't linger looking current once a new one exists
          without its own seating pass yet. Full Timetable view never shows this — it's a
          personal answer, not something every student should see about themselves at once.
VERSION : v8.39 (2026-08-20) — FEAT: new Internal Timetable panel (spanel-inttt, distinct from the
          existing Internals panel which is IA1/IA2 marks). Two sub-tabs: My Class (filtered to the
          student's own internals batch, e.g. "II BCA") and Full Timetable (every batch, date-grouped).
          Reads davan_pub/internals_current — written by the mother app's Internals module (index.html
          §31 intSave, already mirrors to RTDB) — via the existing DB2-only rtdbGet, so it picks up
          real-time data the instant sync_db1_to_db2.py carries that path across; shows an explicit
          "not synced yet" message (not a silent blank) if the path isn't in DB2 yet. Class→batch
          matching reuses portalClassToMotherClass then strips YEAR/section per intBuildBatchesForActiveSem's
          convention on the admin side. Lazy-loaded on first tab open (same pattern as Calendar/Library),
          cached in STATE.internalsTT for the session, with its own ↻ Refresh button.
VERSION : v8.38 (2026-08-19) — FEAT: one-time fleet-wide widget pair-code reset, paired with the
          DavanStudentWidget w28 build. Every w28 widget clears and regenerates its own stored
          code on its first run (device side, automatic, once per version). Diagnostics → Widget
          Pairing Health now has a "Clear ALL widget pairings" button that deletes
          davan_pub/student_widget_active in one shot (admin side, manual, use once students have
          had time to update) so old orphaned codes don't linger after devices move to new ones.
          FEAT: the widget's pair code is now visible on the student's own login screen ("Widget:
          XXXXXX", from this browser's localStorage) — companion to the widget's own w28 change
          that keeps the code visible on the widget face after pairing, not only before. Neither
          the portal's pair log nor the widget's own code generation can explain WHY a specific
          code reaches a specific device; both only record what already happened. Showing the code
          live, everywhere, means the next occurrence is caught directly instead of reconstructed
          afterward.
          FIX: widgets were being silently taken over by students with no
          connection to that device. There is no manual pairing screen, so a ?wdev= code arriving
          via URL was treated as proof of possession (LAST LOGIN WINS, v8.29) — but GGV8VV's pair
          log showed every 17-18 Aug takeover (Afifa → Nikhil → Ashoka → Nikhil → Ashoka → Deepika)
          landing on ONE browser profile, all 'fresh' + 'code from link', none of them the device's
          real owner. Takeover is now only allowed automatically when THIS browser has prior
          (non-refused) history with THIS pair code — i.e. the same physical device changing
          hands, which is legitimate. A browser with no history against a code is refused and
          logged, unconditionally, same as widgetFirstOwnerWins used to require opting into.
          v8.37 (2026-08-18) — UX: Widget Control tab now defaults to the PAIRED filter on load
          (was showing all live students including unpaired, which is the noisier view) — chip
          highlighting synced to match. Activity log's WIDGET PAGE LOCKS and Student logins
          sections are now collapsed by default with an explicit Show/Hide button (was an
          unlabeled arrow, unclear it was clickable). Student logins and Widget pairing changes
          rows now show each student's class next to their name. Fixed the Show/Hide buttons
          stretching full-width and wrapping onto their own line on narrow screens.
          v8.36 (2026-08-18) — FIX: the browser filled admin/admin123 into the STUDENT login,
          producing "URN not found". Both logins share one page, and password managers key saved
          credentials to the origin plus the FIELD NAMES they were captured from — the admin
          inputs had no name attribute at all, so the saved entry matched the first
          name="username"/name="password" pair on the page, which v8.25 had just created on the
          student form. Admin fields are now named admin-username / admin-password inside their
          own <form>, so the two entries cannot be confused. Switching tabs also clears the other
          form's password. Existing saved entries were captured against the old anonymous fields,
          so delete admin/admin123 from the browser's password manager once and let it re-save.
          v8.35 (2026-08-18) — NOTE: manifest-student_portal.json now points at icon-192.png /
          icon-512.png (the real sized icons index.html already uses) rather than
          davan_degree.png, which Chrome would likely have rejected as not installable.
          PERF: computeStudentRanks() read davan_pub/results (1.54 MB)
          fresh on every call — 7 reads and 10.8 MB in one measured 19-minute session, 60% of
          everything downloaded. The report card already caches that exact node in localStorage
          via rcCachedGet with a TTL and background refresh; this path ignored it. Now shares
          that cache. Ranking does need whole-cohort data, so the real fix is for the sync to
          precompute ranks into results_by_urn/<URN> — noted, not done.
          FIX: Widget Pairing Health threw "esc is not defined" and rendered
          nothing. esc() is scoped inside the login-activity renderer, not global; this panel
          lives elsewhere. Uses its own escaper now.
          v8.34 (2026-08-18) — FEAT: Widget Pairing Health in Diagnostics. "It works on my phone
          now" is not "it is fixed" — this counts both 17-18 Aug faults across EVERY student:
          takeovers caused by a restored session (fixed in v8.32, so any dated after that deploy
          means the fix is not holding) and pair codes appearing in more than one browser (a
          six-character random code cannot reach two browsers by chance; it can only travel by a
          shared link carrying ?wdev=). Says plainly when a count reads zero because the v8.33
          fields are missing rather than because the fault is gone.
          v8.33 (2026-08-18) — DEBUG: pair and login rows now carry browserId (random id per
          browser profile — settles "same browser or not", which user-agent strings cannot),
          codeFrom ('url' = arrived via ?wdev= on this load, 'stored' = already in localStorage)
          and session ('fresh' vs 'restored'). Two diagnoses were reconstructed from timestamps
          and UA strings and both were wrong; these three facts cannot be inferred after the
          event, so the next occurrence explains itself.
          v8.32 (2026-08-18) — FIX: the widget kept reverting to a student the phone's owner
          had never signed in as. Root cause: stuCompleteWidgetPairing() ran on every
          goToDashboard(), and goToDashboard() is reached BOTH by a real sign-in AND by the
          silent 'stu_remember' session restore at page load. So merely opening the page
          re-claimed the widget for whoever last ticked Remember me in that browser — no typing,
          nothing on screen, indistinguishable from the app acting on its own. Pairing is now
          gated on STATE._freshLogin, set only by the login handler. Restored sessions still
          open the dashboard; they no longer change widget ownership. Also renamed the
          'auto-takeover' log label to 'login-takeover' — 'auto' meant "via the automatic
          pairing path, not manual code entry", but it read as "happened by itself", which
          actively misled the diagnosis.
          v8.31 (2026-08-17) — FEAT: real PWA install. There was NO manifest before this, so
          "Add to home screen" made a shortcut that still reported Mode: browser, and installing
          this app in Chrome displaced another Davan app — with no manifest Chrome identifies an
          app by ORIGIN, and every Davan app shares harshgujjar.github.io. Added
          manifest-student_portal.json with a unique "id" (the field that separates apps on one
          origin) and a "scope" pointed at this file, so no repo reorganisation is needed. Plus
          sw.js, a deliberately non-caching worker that exists only to satisfy Chrome's install
          criteria — caching would serve stale builds of a file that ships several times a day.
          NOTE for the widget: an Android intent opens the DEFAULT browser, and only Chrome can
          hand it to an installed PWA. A PWA installed in Opera cannot capture intents at all.
          v8.30 (2026-08-17) — UX: the widget pairing log showed two bare URNs per row, which
          is the hardest possible way to read a log whose entire subject is WHO holds a widget.
          Both sides now resolve to name + photo against the roster already in admin memory —
          which also fixes entries logged before this change, since the resolution happens at
          render rather than at write. (The v8.23 avatar line here referenced r.urn, a field
          this log never had, so it had been rendering nothing.)
          v8.29 (2026-08-17) — CHANGE: the widget now follows the LAST student to log in on
          that device, not the first. Previously whoever paired first kept it permanently and
          every later login was refused SILENTLY — six students logging in on one phone produced
          five invisible refusals, a widget stuck on the first, and refresh doing nothing because
          refresh re-reads the same unchanged node. Nothing on screen explained any of it.
          The old guard assumed a remembered pair code is not proof of holding the phone, but it
          nearly is: the code only reaches localStorage when the portal is opened FROM that
          widget via ?wdev=. Trade-off accepted and stated: borrow a friend's phone to check
          attendance and you take their widget with you — so every takeover is logged with the
          previous owner, and controls/global/widgetFirstOwnerWins = true restores the old
          behaviour from DB2 without a rebuild. Either outcome is now shown on the dashboard.
          v8.28 (2026-08-17) — FEAT: quota heartbeat on the LOGIN screen. The dashboard was
          already covered (davan_meta is read fresh every load), but nobody covered login: with
          the quota exhausted, loginStudent() failed on its first read and told the student
          "Something went wrong. Check your connection." — blaming their phone for our problem,
          at the moment they are most likely to keep retrying and burn what quota remains. Now
          one 67-byte uncached read runs when the login screen appears, and a failed login names
          the real cause and the date it clears.
          v8.27 (2026-08-17) — FIX: the freshness banner said "1 September", hardcoded. The
          monthly download quota resets on the BILLING date, which rolls forward every month;
          it is not a fixed calendar day. Now computed as the next occurrence, with
          controls/global/quotaResetDay to override if the real billing day is not the 1st.
          v8.26 (2026-08-17) — FEAT: freshness banner. Two different things make the screen
          lie and they look identical to a student: (1) the database is over its monthly
          download quota, RTDB answers 402/429, every read fails and the portal silently shows
          whatever sessionStorage still holds; (2) reads work but the scraper has not run. The
          top bar already reported (2) via "Last scraped"; nothing reported (1) — the dangerous
          one, because a student checking an attendance shortage cannot tell a working portal
          from a frozen one. rtdbGet now flags 402/429 at the single read choke point (so a new
          call site cannot forget to participate) and a red banner appears ABOVE the greeting
          naming the age of the data and when normal service resumes.
          v8.25 (2026-08-17) — FIX: saved-login dropdown now appears reliably and selecting a
          URN fills the saved password. The panel had TWO off-screen honeypot inputs whose
          stated job was to absorb autofill, plus autocomplete="off" on the URN and
          autocomplete="new-password" on the password — three separate instructions telling the
          browser not to remember these credentials. The dropdown appearing "sometimes" was
          Firefox guessing against those instructions. Removed the honeypots and wrapped the
          fields in a real <form> with name="username"/autocomplete="username" and
          name="password"/autocomplete="current-password". The form element is required:
          browsers will not reliably offer a username dropdown for loose inputs. display:contents
          keeps the card layout identical. Sign In is now type=submit, so Enter works from
          either field and password managers see a proper submit.
          v8.24 (2026-08-17) — PERF: stop downloading the login history on every page load.
          Both the student and admin loads fetched rtdbGet('controls') — the WHOLE node. That
          was fine when controls held a handful of toggles, but controls/loginActivity is
          pushed to on every login and has grown to ~845 KB. Every one of 402 students was
          downloading the college's entire login history to read six small flags: 38% of a
          measured admin session, and on the student path larger than everything Phase 4 saved.
          Now both fetch only the named children they use. Caching was NOT the fix — v7.68 is
          right that toggles must apply on the next load — asking for less was.
          Also: admin login-activity read is now orderBy=\"$key\"&limitToLast=500 via the new
          rtdbGetQuery(), so its cost stops growing with the age of the installation.
          v8.23 (2026-08-17) — Avatars extended to the Widget Control student list and the
          pairing-change feed, per the v8.21 helper. The pairing feed especially: it is a log
          about WHO holds a widget, and two URNs side by side are far harder to read than two
          faces.
          v8.22 (2026-08-17) — FIX: admin tab bar was unreachable with a mouse. It scrolls
          fine on touch, but the scrollbar is hidden by design, a vertical wheel does nothing
          to a horizontally scrolling element, and the only hint was a decorative right-hand
          arrow — so tabs past ACCOUNTS could only be reached by zooming the page out. Now:
          wheel over the bar scrolls it, nudge buttons on BOTH sides appear only when there is
          more that way, a slim scrollbar shows on pointer:fine devices, and switchTab scrolls
          the active tab into view. Touch behaviour unchanged.
          v8.21 (2026-08-17) — FEAT: davanAvatarHTML() / davanAvatarEl() — one helper for
          showing a student's photo beside their name, anywhere. Renders initials on a stable
          per-URN colour immediately, swaps in the Cloudinary photo when the shared index
          arrives (davanAvatarRepaint), and taps through to the existing rcZoomPhoto lightbox
          so pinch/wheel/double-tap zoom come for free. A dead photo URL degrades to initials
          rather than a broken-image icon. Wired into the Login Activity list; use it in every
          new list that shows a student name.
          v8.20 (2026-08-17) — Accounts tab now trusts davan_pub/auth_audit, written by
          sync_db1_to_db2.py v2.2.0. The sync holds a DB2 service-account key, so it can call
          auth.list_users() — the only way to know which accounts really exist. That is
          authoritative, costs no sign-up quota, and self-heals when an account is deleted in
          the console. The tab's own record is now just a fallback for the window before the
          first v2.2.0 run, and "Mark all as having accounts" hides itself once the sync has
          spoken. Also surfaces ORPHANS: accounts whose URN is no longer on the roster.
          v8.19 (2026-08-17) — PHASE 5: login now calls signInWithEmailAndPassword().
          Students type the same URN + phone as before; Firebase now issues an ID token,
          which is what Phase 6 rules will test. Typing any URN with the admin password
          opens that student's dashboard — replacing MASTER_PASSWORD, a plaintext string
          in this file that anyone could read from view-source. The old hash check is
          kept as a fallback and every login records authMode in controls/loginActivity.
          DO NOT ship Phase 6 until 'legacy' stops appearing there for a full week:
          while the fallback stands a student can reach the portal with no token, and
          tightened rules would give them a blank dashboard rather than a clear error.
          v8.18 (2026-08-17) — FEAT: Accounts tab (admin). Creates student Firebase Auth
          accounts singly or in bulk, and audits which students are missing one. Keeps a
          register at davan_pub/auth_registry/<URN> because a browser cannot list Auth
          users — only the Admin SDK can — and probing Firebase per student would spend
          the ~100/hour sign-up quota to learn nothing. Handles next AY intakes: new
          students simply show as missing. "Mark all as having accounts" seeds the
          register for the 402 created before this tab existed.
          v8.17 (2026-08-17) — PHASE 4: student path reads davan_pub/students_by_urn/<URN>
          instead of downloading the whole davan_pub/students blob and picking one row
          out of it in JS. Blob fallback retained until Phase 8 (see stuFetchOwnRow).
          STATE._phase4Src records which path served each load: 'by_urn' or 'blob:*'.
          This must ship BEFORE Phase 5/6 — a rule can only protect a per-URN node,
          so tightening rules while the portal still reads the blob locks out everyone.
          v8.16 (2026-08-17) — FEAT: Diagnostics tab. Answers "the portal is burning
  GB — WHICH READS?", which the Data Usage tab cannot: that one says WHO, this says
  WHAT. rtdbGet() now reads the body as text before parsing, so per-path byte
  totals are MEASURED, not estimated — for the portal every read is a REST fetch
  and body length is the payload Firebase billed for. (The widget still counts
  fetches, because the Firebase SDK never exposes transfer size.) Cost is one
  JSON.parse of a string already in memory: no second request, no clone().
  Path segments that look like identifiers (URN / date / push key / numeric id)
  collapse to <URN>, <DATE>, <PUSHKEY>, <ID>, so one fat node cannot hide behind
  450 small ones. Rows at >=25% of session traffic are flagged red.
  Also: window.onerror + unhandledrejection into a 50-entry localStorage ring
  buffer. Every failure in this app has so far vanished into a console that cannot
  be copied on a phone — which is how the v8.11 auth bug survived two releases
  while the page confidently reported zeros. Ring buffer, so a crash loop cannot
  fill storage and take the portal down. Stored in localStorage NOT Firebase on
  purpose: diagnostics about a database problem must not need that database.
  📋 Copy report emits versions, UA, PWA-vs-browser mode, session totals and rate,
  top 30 paths, last 25 errors, plus a free-text "what I see" box — the one line
  that tells a fresh reader where to look.
VERSION : v8.15 (2026-08-16) — FEAT: per-student usage detail. Photo avatar on each
  row (from davan_student_photos, loaded ONCE per render — 450 separate reads
  would be its own quota problem), and tapping a row expands: photo, last seen,
  reads/fetches/sessions, READS PER SESSION and SESSIONS PER DAY, PWA-vs-browser
  split, browser and device, a 14-day per-day bar chart, and the last 12 logins
  with time, surface and device.
  WHY THOSE TWO DERIVED FIGURES: the table says who is heavy, this says WHY, and
  the fix differs. 100 reads over 3 sessions means the app is expensive per load
  (fix loadAllData); 100 reads over 40 sessions means someone is reloading (fix
  caching or the UI). Sessions/day is the reload detector — normal is 1-3.
  Mode is captured via display-mode:standalone, NOT the user-agent: an installed
  PWA and a browser tab are the same browser and identical in UA, but a PWA keeps
  running in the background where a tab gets killed — exactly the shape of the
  v8.05 broadcast-poll leak. Recorded at flush time as pwaSessions/browserSessions
  plus lastMode/lastBrowser/lastDevice; login log rows gain mode too.
VERSION : v8.14 (2026-08-16) — FEAT: export on the Data Usage tab. 📋 Copy builds a
  readable text report (totals, top 40 users with vs-median multiples, daily
  totals); ⬇ CSV downloads the full table. Both read STATE._duRows — the exact
  array the table rendered from — rather than recomputing, because an export that
  disagrees with the screen is worse than no export. navigator.clipboard can be
  blocked on mobile browsers, so a failed copy falls back to a selectable textarea
  instead of failing silently.
VERSION : v8.13 (2026-08-16) — FIX: usage writes were unauthenticated, so the Data
  Usage tab showed zeros on both v8.11 and v8.12. usageFlush() used a bare fetch()
  with no ?auth= token while every other write in this file goes through
  rtdbPatch() -> getAuthToken() + authSep(); the writes were rejected and a
  catch-all swallowed the error, so nothing surfaced anywhere. The bare call
  existed only to set keepalive:true on pagehide, which rtdbPatch does not expose
  — that path now builds the authenticated URL by hand instead of dropping the
  token to get the flag. Failures now log to console AND return the counts to the
  in-memory tally so the next flush retries them: silent swallowing is what let an
  auth bug survive two releases while the page confidently reported zero.
VERSION : v8.12 (2026-08-16) — FIX: the usage counter could not see ADMIN sessions.
  v8.11 flushed only on the student heartbeat, so a day of admin work — which is
  the heaviest traffic in the building, since loadAllData() pulls ~15 whole nodes
  and development means a hundred reloads — recorded exactly zero. A usage tracker
  blind to its own operator reports "0 ops" while the quota drains, which is worse
  than no tracker because it actively misleads. Now usageIdentity() resolves either
  a student or the logged-in admin (keyed __ADMIN__<username>, so admin rows sort
  into the same table and stay obvious), and usageStartAutoFlush() flushes every
  2 min, on tab hide, and on pagehide with keepalive:true so a closing tab's
  counts are not cancelled mid-flight. No-op at zero, so an idle tab writes
  nothing.
VERSION : v8.11 (2026-08-16) — FEAT: Data Usage tab. Answers the two questions the
  Firebase console cannot: are we on track to blow the 10 GB free tier, and WHO is
  responsible. Console reports bytes with NO per-user attribution, so both figures
  are self-reported: the portal counts rtdbGet calls (single choke point, so a new
  call site cannot be forgotten), the widget counts completed cycles.
  COUNTS OPS, NOT BYTES, on purpose: neither client can see transfer size or
  TLS/header overhead, so a byte figure would be a 60-80% estimate, and a limit
  warning you cannot trust is worse than none. Counts are real, and post-w27 every
  op costs roughly the same, so ranking is sound — which is the actual question.
  GB projection is calibrated against Google's own figure, typed in by the admin,
  rather than derived from counts; uncalibrated it shows "—" instead of a
  confident wrong number. Table flags anyone at >=5x the median, the shape of a
  device stuck in a retry loop — the thing to catch on day 3 of a 400-student
  rollout, not day 20.
  MEASUREMENT COSTS NOTHING ON THE PORTAL SIDE: counts accumulate in memory and
  ride along on the heartbeat write that already happens. Instrumenting a system
  that just broke from too much traffic must not itself add traffic. Widget side
  is one ServerValue.increment per cycle (8/day at the 3h default), server-side so
  two devices on one URN add up instead of clobbering each other.
VERSION : v8.10 (2026-08-16) — FEAT: per-page widget locks. Lock ONE page (Today /
  Internals / Last sem / Attendance / Notices) instead of halting the whole widget:
  davan_pub/page_locks/<pageIdx> = {locked, msg, allowUrns[]}. Keys are page
  INDEXES matching StudentWidgetPageState, not names — the renderer switches on the
  index, and a name would need a mapping table in two codebases that could drift.
  w27 resolves locks per student at FETCH time and feeds them into the existing
  canShow() gates, so a locked page's data is never fetched or cached on the phone
  at all — this is a data gate, not a UI hide. Student sees a card addressed by
  name ("Dear Ashoka, ...") so a blank page reads as a deliberate admin action
  rather than a broken app, and the footer arrows stay visible so they can page off
  it. allowUrns exempts named students, for the "hold results back from the college
  but verify the page with one student first" workflow. DEFAULT OPEN: a missing
  node, missing field or failed read all mean unlocked — an admin control that
  failed closed would take pages from 400 students on one bad network moment.
VERSION : v8.09 (2026-08-16) — FEAT: widget fetch interval is now admin-controlled.
  Hard-coding 30 minutes into the APK is what let a wrong value run for months
  across every installed device with no way to correct it without a rebuild and a
  reinstall on every phone. The right number depends on how often
  sync_db1_to_db2.py runs — an operational decision that changes without anyone
  touching Kotlin. Dropdown (1/2/3/6/12h, default 3) writes fetchHours onto the
  SAME davan_pub/widget_halt node w27 already reads every cycle for the halt flag,
  so fleet-wide retuning costs ZERO extra reads. Saved by MERGE, not .set() — that
  node also carries the halt flag, and overwriting it would silently resume every
  halted widget. Requires w27+; older APKs ignore the field.
VERSION : v8.08 (2026-08-15) — SECURITY FIX + audit trail.
  THE HOLE: stuCompleteWidgetPairing() fired on EVERY login and blindly overwrote
  student_widget_active/<code> with whoever just logged in, where <code> comes from
  localStorage — which belongs to the BROWSER, not the student. So any login on a
  browser that had ever carried a ?wdev= code silently reassigned that physical
  widget, and the phone's owner then saw a stranger's attendance, father's name and
  mobile number on their home screen. Observed 15-Aug: widget GGV8VV displayed
  NIKHIL R HAMSI to a device that had never signed in as him. Logout had the same
  bug wearing a different hat — it deleted whatever node localStorage pointed at,
  which is what stranded GGV8VV on "Widget not paired" at 21:56.
  THE RULE NOW: an automatic pairing write may only CREATE a node or REFRESH one
  already owned by the same URN. Taking over someone else's widget requires
  stuPairByCode() — physically reading 6 characters off that phone's screen, which
  is proof of possession; stale localStorage is not. Logout likewise only clears a
  pairing that is actually ours. Manual takeover stays allowed but is logged with
  the previous owner: allowed is not the same as invisible.
  AUDIT TRAIL: davan_pub/student_login_log (every login attempt, allowed or blocked,
  WITH the browser's remembered pair code — the field that identifies which browser
  owns which widget) and davan_pub/student_widget_pair_log (every pairing create,
  refresh, takeover, refusal and clear). Both readable in the admin Widget tab under
  ACTIVITY LOG, because the Firebase console is not usable on the admin's phone.
  KNOWN LIMIT, not fixable retroactively: the maintenance gate is client-side, so a
  student still running a CACHED v8.05 has no gate to run and logs in normally
  (observed: U13NU25S0031 on v8.05 during an active halt). Clients pick the switch
  up when they load v8.06+.
VERSION : v8.07 (2026-08-15) — FEAT: widget halt now drives davan_pub/widget_halt
  {on,msg} as well as the ban list. w27+ reads that flag and renders a proper
  "Under maintenance" screen (student's name and pairing KEPT, amber not danger red,
  admin's own message shown); w26 knows nothing about it and still needs the ban-list
  half, which shows "Access suspended" — wrong wording for a pause but it does stop
  the fetch. Both written so a mixed fleet is covered; delete the ban-list half once
  every device is on w27+, because telling a student their access is suspended when
  it is not has a real cost. Resume clears both. LATEST_STUDENT_WIDGET_APK -> 27.
VERSION : v8.06 (2026-08-15) — FEAT: two kill switches, built because the 14-Aug
  quota incident had no OFF button. Both work on the w26 APK already installed.
  (1) WIDGET HALT. The only stop signal w26 honours is controls/bannedStudents —
  StudentPairing.isBanned() reads it every cycle and returns BEFORE buildFullStats(),
  so a listed student skips all nine whole-node reads. maintHaltWidgets() adds every
  paired URN there; maintResumeWidgets() removes exactly what it added, tracked in
  davan_pub/maint_widget_halt, so a genuinely banned student is never un-banned by
  Resume. loginStudent() SUBTRACTS the halt mirror from its ban check, so halting
  widgets does not lock anyone out of the portal.
  NOTE FOR LATER: controls/widgetBannedStudents — what the per-student "Ban widget"
  button writes — appears NOWHERE in the w26 source. That button has never stopped a
  widget, only changed this portal's display. Left as-is; the halt deliberately does
  not use it. Next APK should read it (and a proper davan_pub/widget_halt flag, so a
  halt can show "under maintenance" on the face instead of the ban screen).
  (2) PORTAL MAINTENANCE MODE. davan_pub/portal_maintenance {on,msg,allowUrns[]}.
  Blocks student logins with a custom message; admins always get in; allow-listed
  URNs pass so a fix can be verified against one real account before readmitting 400.
  Gate sits after the ban check (a banned student gets the ban message, not this one)
  and before the password check, so no credential work runs while the portal is shut.
  FAIL-OPEN by design: if the flag read throws, students are let in — a dead database
  must not also become a locked portal. Read at login only, never polled.
VERSION : v8.05 (2026-08-14) — CRITICAL FIX: the RTDB download quota blowout, and
  its real cause. DB2 hit 51.9 GB against Spark's 10 GB/month cap (41.9 GB over,
  graph flatlines 12-Aug), Firebase throttled the database, and writes started
  being rejected — which is why student widget reports froze and v8.04 had to be
  written to stop the admin panel presenting a 2-day-old snapshot as fact. A read
  loop broke the write path; the whole widget investigation was downstream of this.
  ROOT CAUSE: startBroadcastPoll() ran setInterval(..., 10000) doing TWO rtdbGets
  per tick (live_broadcast + live_banner) for the life of the tab, foreground or
  background = 17,280 requests/day PER OPEN SESSION. Whole DB is 8.85 MB; 51.9 GB
  is ~5,900 full-database downloads, ~195/day — a loop, not user traffic.
  FIXED THREE WAYS, each sufficient alone: (1) visibility gate — hidden tab clears
  the timer entirely, not just skips it, so a backgrounded PWA costs nothing (this
  is most of the saving; the cost was never students actively reading); (2) interval
  10s -> 60s via LIVE_POLL_MS, with an immediate tick on start and on tab-return so
  perceived latency does not regress; (3) new LIVE_FEED_URL points at a Cloudflare
  Worker (live-worker.js, shipped alongside) that reads the two nodes once per 30s
  and serves all students from edge cache — Firebase now takes a FIXED ~2,880
  reads/day for this feature regardless of whether 5 or 500 students are online,
  and Cloudflare bills no egress. Client count is decoupled from RTDB cost.
  NOT an SDK onValue listener, deliberately: Spark caps SIMULTANEOUS CONNECTIONS at
  100, so persistent listeners would swap a bandwidth ceiling for a connection
  ceiling and silently lock out student 101. Polling a cache is the right shape.
  LIVE_FEED_URL = '' falls back to reading Firebase directly (still gated, still
  60s), so this file is safe to ship BEFORE the Worker is deployed and a Worker
  outage degrades instead of killing broadcasts. Also fixed in passing: the banner
  was fetched INSIDE the early-returning broadcast block, so if no broadcast had
  ever been sent the banner was never evaluated at all — now checked every tick.
  stopBroadcastPoll() added and called on sign-out (a signed-out tab kept polling).
VERSION : v8.04 (2026-08-14) — FIX + FEAT, both from one real incident: a paired
  student (U13DI25S0027, motorola edge 50 pro) whose widget face read [w26 · v8.03]
  while this portal insisted "⬆ v21 outdated · last seen 2 d ago". Evidence chain:
  the face's "v8.03" can ONLY come from student_widget_latest.portalVersion, which
  is written by stuPublishLatestWidgetApk() — and v8.03 shipped 13 Aug, so the
  widget READ that node within a day, while report.ts stayed 2 days cold. Reads
  work; writes to davan_pub/student_widget_report do not. (Widget-side conclusion,
  not fixed here: the face is printing latest.apkVersion rather than its own
  THIS_APK_VERSION, which is also why a w21 build never showed the update nag —
  fix belongs in StudentFetchWorker.kt. Prime suspect for the dead write is an
  RTDB rules tightening on davan_pub.)
  (1) FIX — the portal was stating a frozen snapshot as current fact. New
  WC_STALE_MS (24h) + st.stale in wcGetStudentStatus(): a report older than a day
  no longer produces an "outdated" verdict (the version we hold is not evidence of
  what is installed now), and no longer feeds NOTIF OFF / REMINDERS DEAD either —
  those read the same frozen node, so a silent phone was padding live-fault counts.
  Row badge renders "🕑 w21 · stale (2 d)" in danger red instead of the confident
  outdated chip, with a banner saying every line under it (including the reassuring
  green "✓ Class reminders working") is LAST KNOWN state, plus the three usual
  causes. New STALE summary card + "🕑 Stale (not reporting)" filter chip; table
  filters carry the same !st.stale guard so chip and card can never disagree.
  (2) FEAT — download funnel. The APK is a static file on GitHub Pages, which
  publishes no per-file download stats, so "has anyone downloaded it" was
  unanswerable anywhere (GitHub only counts downloads on RELEASE assets — moving
  the APK to a Release would give a real count via the API). New
  stuLogApkDownload() on the Get The App button writes
  davan_pub/student_widget_dl_clicks/<URN> {name,class,taps,firstAt,lastAt,ver} —
  read-then-patch so repeat taps stay one row per student and a key count answers
  "how many students". Fire-and-forget, all failures swallowed to console: a
  logging write must never block a student getting the app. New DOWNLOAD TAPS card
  shows unique students · total taps → paired, i.e. top and bottom of the funnel
  side by side, since a tap is NOT an install and must never be quoted alone.
VERSION : v7.58 (2026-08-03) — FEAT: made the emoji summary tiles clickable filters
  across all Engagement-tab feedback lists — Login Feedback responses
  (renderLfResponseList/lfFilterByEmoji) and Calculator/Report-Card feedback
  (renderEgFeedbackList/egFeedbackFilterByEmoji). Clicking a tile (e.g. 😍 or 😞)
  filters the list below to only that emoji's responses, with a "Showing only X
  (n) ✕ Clear filter" line and a highlighted border on the active tile; clicking
  the same tile again clears the filter. Filter state is kept per question/kind so
  filtering one list doesn't affect another, and entries are cached in STATE
  (lfRawEntries / egFeedbackEntries) so filtering re-renders instantly from memory
  instead of re-fetching from Firebase on every click.
VERSION : v7.57 (2026-08-03) — FEAT: Engagement tab, two additions. (1) Added a
  "🗑️ Reset Usage Stats" button next to the SGPA/CGPA CALCULATOR — USAGE heading
  (egResetCalcOpens()) — deletes davan_pub/calcOpens entirely so testing-only opens
  (e.g. the 33 logged while testing) can be cleared before real students start using
  it; confirms via a Firebase re-read that the path actually came back empty before
  reporting success, rather than assuming the delete request succeeding meant the
  data was gone. (2) Added a floating bottom-right confirm-toast (egToast(),
  #eg-toast-wrap) shown for EVERY Engagement-tab save/toggle/add/remove action —
  calc/report-card feedback strip toggles (saveGlobal), and all Login Feedback
  question admin actions (lfAddQuestion/lfEditQuestion/lfSetQuestionType/
  lfToggleQuestion/lfRemoveQuestion/lfResetAll). Each of these now re-reads its own
  just-written RTDB path back from Firebase before toasting "confirmed in Firebase";
  if the read-back doesn't match what was sent, it toasts a failure instead — so a
  silent write failure (dropped network call, rules rejection) is never mistaken for
  a successful save.
VERSION : v7.55 (2026-08-01) — CRITICAL FIX: College Rank, Class Rank, and
  Davan/Nutana Campus Rank were all computed as pool.findIndex(s => ...) + 1
  -- raw array position after sorting by pct, with zero tie detection. Same
  bug class results.html was fixed for at its own r455 (dense competition
  ranking, ties share a rank). Confirmed live via screenshot: results.html
  student modal shows Aliya Firdose as College Rank #48 of 213 out of 306
  (Davan campus rank #31) for BCom Sem II -- but this file showed #79 of
  351 out of 567 for the same student/semester, because tied students ahead
  of her in the sorted pool were each counted as a separate rank instead of
  sharing one. FIX: added spAssignDenseRanks (mirrors results.html
  resAssignRanks exactly), applied to college, cls, and campusPos (feeds
  the di/nu Davan/Nutana Rank tiles) inside computeStudentRanks.
VERSION : v7.54 (2026-07-27) — FIX (real root cause, not the v7.53 theory):
  the "0 holidays" bug was neither a timing issue (v7.53's fix, while a
  real separate improvement, didn't resolve this) nor an index.html
  deploy-lag issue — added on-screen debug output that proved it directly:
  STATE.calendarData genuinely still contained dates as "15 Aug 2026"
  (pretty/display format), not ISO, in the live database at the moment
  this was checked. stuCountHolidays/stuCountNonTeaching do
  `new Date(dStr + 'T00:00:00')`, which is invalid syntax for that format
  and silently fails isNaN() — every holiday dropped, count stuck at 0 —
  while the Calendar tab looked completely fine on the exact same data,
  because DISPLAYING a pretty string never needed it to be parseable, only
  a numeric comparison (>=, sort, isPast) does. Added stuParseCalDate(), a
  shared parser that tries ISO first (unchanged behaviour for already-
  correct data) and falls back to manually parsing "DD Mon YYYY" /
  "DD Month YYYY" when ISO parsing fails — so this works correctly
  regardless of which format happens to be in the database, instead of
  depending on index.html always being redeployed with fresh data first.
  Swept the whole file for every other place silently vulnerable to the
  identical bug (all were doing ad-hoc new Date(e.date...) with no
  fallback) and fixed all of them to use the same shared parser:
  _filterCalToSessionWindow, the topbar ticker, the upcoming-events strip,
  both the student and admin calendar tables (display AND isPast/isToday
  logic), the admin calendar sort, stuDayInfo's per-day holiday lookup,
  and the internal-assessment date parser. Removed the temporary on-screen
  debug output added to diagnose this.
VERSION : v7.53 (2026-07-27) — FIX: Dashboard's working-days sentence
  ("This semester has N days... excluding N Sundays and N holidays") stuck
  showing "0 holidays" specifically on session RESTORE (remember-me / page
  reload while still signed in) even when the Calendar tab, opened
  separately, correctly showed real holidays from the same STATE.
  calendarData. Root cause: restoreStudentSession() calls
  updateSidebarProfile() (which triggers stuRenderSemStartNote(), the
  sentence) immediately as a "fast paint" BEFORE awaiting
  loadStudentDashboard() — at that point STATE.calendarData is still
  whatever it was left as from before this page load (typically empty on
  a fresh restore), so the holiday count computed from nothing and nothing
  ever recomputed it afterward. The Calendar tab looked fine only because
  it renders on-demand when actually opened, by which point the real fetch
  has long since finished. goToDashboard() (fresh login path) never had
  this bug — it already called updateSidebarProfile() only once, after the
  await. Fix: restoreStudentSession() now also calls updateSidebarProfile()
  again after awaiting loadStudentDashboard(), so the sentence gets a
  second, correct computation once real data has actually arrived. The
  earlier fast-paint call is left in place — it exists for a different,
  legitimate reason (see its own comment) and this is additive, not a
  replacement.
VERSION : v7.52 (2026-07-27) — FEAT: Social Media follow nudges now have
  independent show/hide toggles, one per placement — Controls ▸ VISIBILITY
  CONTROLS ▸ Global gained 4 new rows (Dashboard Banner, Sidebar Card,
  Once-a-day Toast, Login Page Footer), same Global-only pattern as Faculty
  Photos (default-on, no byClass/byUrn override — a per-student "should
  this student see the follow banner" doesn't make sense the way "should
  this student see their marks" does). New canShowSocial(flag) gates all 4
  render functions. The Login Page Footer toggle needed special handling
  since it renders before any login happens: loadPreLoginSocialLinks() now
  also fetches controls/global/socialLoginPage directly (not the full
  controls tree) so the flag is known pre-auth, same reasoning as the
  existing pre-login socialLinks fetch.
VERSION : v7.51 (2026-07-27) — FEAT: Social Media tab, two usability fixes.
  (1) BY PLACEMENT table cells are now clickable — tapping any non-zero
  number (e.g. "1" under Banner for Instagram) expands renderSocialPlacement
  Detail() below the table: exact list of who clicked that specific
  platform+placement combo, with photo (async-loaded via rcLoadPhoto, tap
  to zoom via rcZoomPhoto — same pattern as every other photo in the admin),
  name, URN, and timestamp. Anonymous login-page clicks show as such rather
  than blank. (2) Class roster drilldown no longer dumps all 40-65 students
  by default — split into clickers (shown immediately, with photos, sorted
  most-recent-activity-first) and non-clickers (collapsed behind a "👁 Show
  N who haven't clicked" toggle, built lazily on first expand rather than
  always rendering). Toggle re-labels to "🙈 Hide" and stays expanded until
  clicked again; re-opening a different class rebuilds fresh.
VERSION : v7.50 (2026-07-27) — FIX: v7.49's fixed Sign Out button ate into
  the tab row's available width, so Social Media (last tab) got visually
  truncated to "SO..." — looked broken rather than scrollable. Reduced
  tab-btn padding 20px→16px to fit more tabs before overflow, and added a
  right-edge fade gradient over the tab row (pointer-events:none, so it
  never blocks the tab underneath) that signals "more tabs, scroll →"
  instead of a tab looking cut off. Tab row still scrolls via the
  pre-existing .tab-bar overflow-x:auto — this only fixes the visual
  read, same underlying scroll mechanism as before.
VERSION : v7.49 (2026-07-27) — FIX: admin's Sign Out button got pushed off
  the visible screen edge once the new Social Media tab (v7.46) tipped the
  tab row over its horizontal-scroll threshold. Root cause: Sign Out lived
  INSIDE the same overflow-x:auto row as the tabs, positioned via
  margin-left:auto — that only pins it to the far edge of the scrollable
  content, not the visible viewport, so once the row overflowed, reaching
  Sign Out required scrolling the tab bar itself all the way right (not
  obvious/discoverable). Moved it OUTSIDE the scrolling .tab-bar entirely,
  into a fixed sibling button that's always on-screen regardless of how
  many tabs exist now or get added later — adding more tabs can now only
  make the tab row scroll, never hide Sign Out.
VERSION : v7.48 (2026-07-27) — FEAT: Social & Contact Links now fully
  admin-editable (Controls ▸ 📣 Social & Contact Links, writes
  controls/socialLinks) — Facebook/YouTube/Instagram URLs, WhatsApp number,
  and Call number can all be changed without a code deploy. Every nudge
  placement (login page footer, dashboard banner, sidebar card, once-a-day
  toast) now reads live from STATE.socialLinks via a getter (SN_LINKS →
  snGetLinks()) instead of hardcoded URLs, so an admin edit takes effect
  everywhere immediately. Added WhatsApp + Call the office links to the
  student login page (matching parent_ptm.html's own login footer) — these
  didn't exist here before, only the three social icons did. New
  loadPreLoginSocialLinks() fetches controls/socialLinks on page load, no
  login required, since the footer renders before any auth happens; falls
  back to sane hardcoded defaults (matching parent_ptm.html) until that
  resolves so the footer is never blank. snTrackClick() extended to two
  new platform keys (whatsapp, call) alongside fb/yt/ig. Admin Social Media
  tab gained a dedicated "LOGIN PAGE CLICKS" log (renderSocialOverview) —
  a flat, most-recent-first list of every individual pre-login click with
  which action (Facebook/YouTube/Instagram/WhatsApp/Call) and exact
  date/time, since these clicks are anonymous most of the time and can't
  go through the class-roster drilldown the way logged-in clicks can.
VERSION : v7.47 (2026-07-27) — FEAT: added the same "Follow us: [FB][YT][IG]"
  icon-row footer parent_ptm.html shows on its login page, to the student
  login page here too (below "Forgot password?"), same icons/links/sizing.
  snTrackClick() now records these too — previously it silently no-op'd
  without STATE.studentUser.urn (nobody's logged in yet on this screen),
  which would have dropped every login-page click. Anonymous clicks now
  write urn:null instead of being skipped, tagged source='loginpage'. Admin
  Social Media tab updated to handle them correctly rather than folding
  them into one fake "student": overview splits Unique students (signed
  in) from a separate Anon (login page) count, and the BY PLACEMENT table
  gained a 4th "Login pg" column so these clicks are visible there too.
VERSION : v7.46 (2026-07-27) — FEAT: Social Media follow nudges + admin
  analytics. Three student-facing placements, links/icons matched exactly
  to parent_ptm.html's official Facebook/YouTube/Instagram pages: (1) a
  dismissible banner at the top of the dashboard (dismiss lasts the
  session, reappears next login), (2) a permanent compact card in the
  sidebar, (3) a once-per-calendar-day welcome toast. Every click writes
  {urn,name,class,platform,source,ts} to davan_pub/socialClicks via
  snTrackClick() — source records which of the three placements was
  clicked. New admin "📣 Social Media" tab (loadSocialClicks/
  renderSocialOverview/renderSocialClassList/renderSocialDrilldown):
  overview cards (total clicks, unique students, per-platform totals) +
  a by-placement breakdown table (banner vs sidebar vs toast, per
  platform) + a per-class strength grid (unique clickers / roster size,
  same X/Y pattern as Login Activity) that opens a full roster drilldown
  on click — each student's click history with platform, placement,
  date/time, and repeat-click detection (same link clicked more than
  once). CODE_BUILD unrelated — this is student_portal.html only.
VERSION : v7.45 (2026-07-27) — FIX: dashboard showed "0 holidays" in the
  working-days sentence no matter how many holidays existed in the synced
  calendar. Root cause was on the index.html (mother app) side: the
  auto-push to davan_pub/calendar sent date/endDate as a display string
  ("15 Aug 2026") instead of something parseable, and stuCountHolidays /
  stuCountNonTeaching do `new Date(dStr + 'T00:00:00')` on that field —
  invalid syntax for a display string, so every holiday silently failed
  isNaN() and got dropped. index.html now sends date/endDate as ISO
  (YYYY-MM-DD) with the pretty text moved to new dateLabel/endDateLabel
  fields. Updated every place here that displays these dates (admin +
  student calendar tables, upcoming strip, topbar ticker) to prefer
  dateLabel/endDateLabel for display while date/endDate stays parseable —
  falls back to date/endDate for any calendar data pushed before this fix.
  Also fixed on the index.html side (v1048): the auto-push that runs after
  every calendar save was separately overwriting davan_pub/session_config
  (a PUT, not a merge) with a hardcoded placeholder date range whenever its
  own Session Config screen hadn't been used — silently reverting whatever
  the Semester Dates admin control here had saved. See index.html v1048.
VERSION : v7.44 (2026-07-27) — FIX: the Kannada/Hindi "student sits only one
  language, hide the other's permanent 0/0 row" fix (spActiveLangs /
  spLangVisible / spFilterLangSubs, 26-Jul-2026) only ever worked on the
  student's own login. It read STATE.studentData, which is the LOGGED-IN
  student — on the admin side, viewing someone else's card left that
  either empty or holding a different student's data, so the language
  filter silently did nothing and both rows showed for everyone. Gave all
  three language functions an optional subjects-array parameter so a
  caller with a specific student's data in hand (not necessarily the
  logged-in one) can pass it directly, and wired it into all four
  admin-card subject lists: Report Card's attendance + internals sections,
  and the standalone Attendance and Internals tabs. Student-side call
  sites are unaffected — passing their own subs array through explicitly
  is equivalent to the STATE.studentData default it replaces.
VERSION : v7.43 (2026-07-27) — FEAT/FIX: Admin Student Card overhaul (5
  issues from one report):
  1. Report Card tab showed ONLY current-semester attendance/internals —
     previous semesters lived only on the separate Prev Results tab, which
     looked like the Report Card was "stuck". Now shows a compact CGPI +
     per-semester SGPA summary (via the same rcLoadPrevResults() the other
     tabs use) that links straight to the full Prev Results tab.
  2. Added a Library tab: applied/queued holds, currently borrowed books
     with due dates, and closed lost/damaged records — same DB2
     library/requests + library/issues source as the student's own "My
     Library" panel, read-only (library.html remains the sole writer).
  3. Report Card / Attendance / Internals tabs never showed faculty name or
     photo at all — they read attData.subjects raw, with no enrichment
     step. Added ascResolveFaculty() (mirrors the student dashboard's
     sub.facultyDI/facultyNU/faculty + allocation name-match fallback) and
     ascEnsureAllocs() (fetches davan_pub/allocations directly rather than
     assuming STATE.motherAllocs is already populated on the admin side).
     Faculty now renders via the existing spFacLabel() on every subject row
     across all three tabs.
  4. Pinch/tap-to-zoom on faculty photos: no separate work needed — the
     existing rcZoomPhoto lightbox (pinch, wheel-zoom, double-tap, pan) was
     already wired to every spFacAvatar() photo; it just had nothing to
     zoom into until fix #3 made faculty photos actually render admin-side.
VERSION : v7.42 (2026-07-27) — FIX: topbar calendar ticker (v7.41's speed
  fix) vanished entirely on the older stu_urn/stu_name session-restore path
  (restoreStudentSession) — that path built topbar-row2 but never called
  the ticker builder, so anyone whose session restored through it (most
  desktop reloads) saw no ticker at all, even with upcoming calendar events.
  Root cause: buildStudentTicker() was a private IIFE inside goToDashboard(),
  so the other restore path had no way to call it. Promoted it to a
  top-level function and call it from both entry paths, after
  loadStudentDashboard() so STATE.calendarData is populated first.
VERSION : v7.93 (2026-08-06) — FIX: v7.92 stopped NEW negative photo results
  from being cached, but did nothing about negative entries already sitting
  in localStorage from before that fix — so a student could still show no
  photo on one screen (reading an old poisoned entry) while showing correctly
  on another (freshly re-checked), inconsistent within the same session.
  Reported live: M D Huzaif ur Rahaman's photo displayed on the Report Card
  page but not in the admin student-card popup opened from Login Activity —
  same rcLoadPhoto()/cache, same URN, different screens, because one had
  already been freshly re-checked post-v7.92 and the other was still reading
  a stale leftover. Fixed: _rcPhotoCacheGet() now treats any stored negative
  value as a leftover from the old caching behavior rather than a trustworthy
  "confirmed no photo" — it's discarded and re-checked fresh the moment it's
  encountered, self-healing every affected URN on its next lookup instead of
  waiting out the original 7-day TTL.
VERSION : v7.92 (2026-08-06) — FIX: Student photos that displayed correctly
  earlier could silently go blank later in the same session with no code
  change in between (reported: Alisha Khanum's photo showed in the raw log
  list, then disappeared in the class drilldown card minutes later).
  Root cause: _rcPhotoCacheSet() cached BOTH positive hits and negative "no
  photo found anywhere" results in localStorage for the same 7-day TTL. Any
  transient failure — RTDB briefly returning null, a Storage/Cloudinary HEAD
  request timing out on a slow connection — got permanently remembered as
  "this student has no photo" for a full week, even though the photo
  genuinely exists and would load fine on a retry. This is pre-existing
  behavior, not something introduced by v7.90/v7.91's chip-filter fixes.
  Fixed: only a confirmed positive hit (real photo URL) is now persisted to
  localStorage with the 7-day TTL. A miss is kept in-memory only for the
  current page load (so one screen with 50 students doesn't re-fire the
  same lookups repeatedly) and is never written to localStorage — so every
  fresh page load re-checks RTDB/Storage/Cloudinary from scratch instead of
  trusting a possibly-stale "no photo" verdict from earlier.
VERSION : v7.91 (2026-08-06) — FIX: Login Activity — Sem 1 (and other chip)
  filters stopped showing student photos in the raw log list, though the
  same photos loaded fine with no filter applied. Root cause: rcLoadPhoto()
  is async (RTDB read, then up to 6 parallel Storage HEAD requests as
  fallback); when a chip tap re-ran renderLoginActivity() before an
  in-flight photo fetch from the PREVIOUS render had resolved, that older
  fetch would land after la-list's HTML had already been rebuilt — writing
  into a stale/now-missing avatar element or the wrong slot, so the photo
  silently never appeared. Added a render-generation counter
  (STATE._laRenderGen): each render stamps its own generation, and the
  photo-load callback now checks it's still the current generation before
  touching the DOM, discarding results from any render that's since been
  superseded. Applies to every call path (chip clicks, search typing,
  class-summary card clicks, refresh), not just the Sem/Section chips.
VERSION : v7.90 (2026-08-06) — FIX: Semester and Section chips never
  highlighted when clicked, and the filter silently matched nothing. Root
  cause: laSetFilter() stored the clicked chip's LABEL text (e.g. "Sem 1")
  as the filter value, but laRenderChipBar() then re-added the "Sem "/"Sec "
  prefix on top of that stored value when deciding which chip to highlight
  (building "Sem Sem 1"), which never equals "Sem 1" — so the chip never lit
  up. Filtering used the same double-prefixed value against class names,
  which also never matched. Fixed by storing RAW values only ('1'..'6',
  'A'..'C', course code, AY string) in STATE._laFilt, with the "Sem "/"Sec "
  prefix now added purely for display via a display-formatter passed into
  laChipGroup(). Highlighting and filtering both now work correctly.
VERSION : v7.89 (2026-08-06) — FIX: Login Activity chip panel redesigned per
  admin feedback (v7.88's layout wasn't good) — Course + Semester now pack
  onto one row and Section + Academic Year onto a second row (matching the
  admin's reference layout), instead of one full-width row per category.
  Added a ● Live / ↻ Reset button directly inside the chip panel (top-right
  of the Course+Semester row) — previously there was no reset control
  visible in the panel at all; the old standalone Live button up near the
  search box was removed since it's now redundant.
VERSION : v7.88 (2026-08-06) — FIX: v7.87's Course/Semester/Section/AY chips
  were placed above the whole Login Activity tab and were filtering the class
  -summary cards / analytics / drilldown too — admin only wanted them on the
  RAW LOGIN LOG list at the bottom. Moved the chip bar to sit directly above
  that raw log table (under a new "📋 RAW LOGIN LOG" label) and scoped the
  filtering so it only ever touches that list's rows/count; class-summary
  cards, analytics and drilldowns now always show full unfiltered data,
  matching how they worked before this feature. Live button still resets
  the four chips to All and re-shows the full log, most recent first.
VERSION : v7.87 (2026-08-06) — FEAT: Login Activity — re-added Course /
  Semester / Section / Academic Year filter chips (previously removed in
  v7.84), styled as rounded pill chips matching the admin's reference design.
  Academic Year chips order fixed to current AY first (2026-27) then previous
  (2025-26), not alphabetical. All four chip rows default to "All". The
  existing Live pill now doubles as "reset all filters + drilldown to All and
  show current data" — clicking it while any chip is non-"All" or a drilldown
  is open snaps straight back to the default live view (most recent logins).
  Scoped entirely to the Login Activity tab; no other tab/filter touched.
VERSION : v7.41 (2026-07-27) — FIX: topbar calendar ticker used a fixed 30s
  scroll animation regardless of content length. With only 1-2 upcoming
  events (the common case) the short strip whipped across the screen in
  ~2 seconds instead of scrolling readably. Now measures the rendered
  content width after paint and sets duration to hold a steady ~40px/sec
  pace (8s floor for very short tickers), so speed no longer depends on
  how many events happen to be upcoming.
VERSION : v7.40 (2026-07-27) — FIX: Restored sessions (remember-me, or a
  page reload/reopen while still signed in) never wrote to
  controls/loginActivity — only a fresh password login did. Result: a
  student could be actively on the dashboard while admin's Login Activity
  tab / "Live on App" showed zero trace of them. Added stuStartHeartbeat():
  pushes an activity row on session restore and re-pings every 5 min while
  the tab stays open (throttled via sessionStorage so refreshes don't spam
  new rows); stuStopHeartbeat() clears it on sign-out.
VERSION : v7.39 (2026-07-27) — FIX: Login Activity tab (list + "Live on App"
  modal) showed a static 🟢/👤 emoji instead of the student's real photo.
  Both now render an initials placeholder immediately, then async-swap in
  the actual photo via rcLoadPhoto(urn) (same davan_student_photos/{urn}
  source used everywhere else), falling back to initials on load error.
VERSION : v7.38 (2026-07-25) — FIX: BCA_MERGED_SECTIONS was WRONG — it treated
  every BCA batch's Sem II-VI as merged, but per Harsha the section merge is
  PER-COHORT: only the 2025-admission cohort (URN year '25', e.g.
  U13NU25S0031) was merged into 1 section starting Sem II; other BCA batches
  (2023/2024 admits — current 2nd/3rd year students) have separate admission
  histories and are NOT merged. Replaced the semester-only BCA_MERGED_SECTIONS
  list with isMergedSectionCohort(urn, sem) — checks the URN's 2-digit
  admission year against MERGED_SECTION_COHORTS (currently just ['25']) AND
  requires sem !== 'I' (Sem I never merges for any cohort). Mirrors
  results.html's resIsMergedSection() added the same day — keep both files'
  cohort lists in sync if another batch merges later. Also: DI Rank / NU Rank
  are now suppressed (0, tile hidden) for merged-cohort students, matching
  results.html — a DI/NU split rank is meaningless once the two sections are
  administratively combined; Class Rank (still merged for these students)
  represents "my section" instead.
VERSION : v7.37 (2026-07-25) — CHANGE: College Rank now ALSO scopes by
  campus (Davan/DI vs Nutana/NU), on top of the semester-parity scoping added
  in v7.35, per Harsha's explicit follow-up request. A DI student's College
  Rank now pools only against other DI students in the same parity group
  (Odd or Even); an NU student's pools only against other NU students in the
  same parity group. Campus detection reuses the same logic as the existing
  myIsDI/myIsNU checks — URN contains 'DI' vs 'NU' — matching admin's
  facIsDI_global/facIsNU_global fallback (results.html) for records with no
  explicit campus field. Still not scoped by course: a Sem I NU student's
  College Rank pools against every Sem I/III/V NU student across
  BCA+BBA+BCom combined, same as before, just now also restricted to her own
  campus. Verified with an isolated trace: a synthetic 6-student pool mixing
  DI/NU and Odd/Even correctly excluded a same-parity DI student and a
  same-campus wrong-parity student, leaving only the 2 genuinely-comparable
  NU+Odd students plus self (pool size 3, rank 3).
VERSION : v7.36 (2026-07-25) — FIX: a student's HISTORICAL semester cards (in
  "Previous Results") were computing College/Class/DI/NU rank using the WRONG
  semester's data entirely. Confirmed live: V Neesha's Sem I card (CGPI block
  above it correctly showed "Sem I: 7.76 · Sem II: 8.12", proving she has
  multiple semesters on file) showed College Rank #3 — identical to her Class
  Rank — even after v7.35's parity scoping, which should have made the two
  numbers differ. Root cause, two compounding bugs in computeStudentRanks():
  (1) extractPool's allStudents dedup keyed on URN ALONE, so a student with
  results in several semesters had all but ONE semester's record silently
  discarded (whichever had the highest pct survived); (2) myEntry — used to
  determine which course/sem/section to scope every rank pool by — was then
  looked up by URN alone too, with the semStr parameter the caller passed in
  (e.g. 'I' for a Sem I card) never actually checked against it. So a Sem I
  card calling computeStudentRanks(urn, course, 'I') would silently pull
  myEntry from whatever semester survived the dedup (e.g. Sem III) and
  compute every rank — College, Class, DI, NU — using that wrong semester's
  course/section/pct, completely decoupled from which semester's card was
  actually asking. Fix: (1) dedup key is now `urn + '|' + sem` so each
  semester's record survives independently — a student now has one
  allStudents entry PER semester with results; (2) myEntry lookup now matches
  on `urn === myUrn && sem === targetSem` first, falling back to urn-only
  only if no exact-semester record exists (so it never silently returns
  zeros). Verified with an isolated trace: a synthetic student with pct 77.9
  (Sem I), 81.2 (Sem II), 88.0 (Sem III) — requesting the Sem I card now
  correctly resolves myEntry to the 77.9/Sem I record; requesting the Sem III
  card resolves to the 88.0/Sem III record; previously both silently
  resolved to whichever had survived the old urn-only dedup regardless of
  which was actually asked for.
VERSION : v7.35 (2026-07-25) — CHANGE (not a bug fix — deliberate scoping
  change requested by Harsha): College Rank is now scoped to the student's
  own semester PARITY, not the full six-semester institution. Odd-sem (I,
  III, V) students rank against other Odd-sem students only; Even-sem (II,
  IV, VI) students rank against other Even-sem students only — NOT scoped by
  course, so e.g. a Sem I BCA student's College Rank pools against every
  Sem I/III/V student across BCA+BBA+BCom combined. This mirrors admin's
  Rankings tab ODD_SEMS/EVEN_SEMS split (results.html resGetFilteredData,
  RES_DASH_PARITY). Background: v7.34 (same day, earlier) made College Rank
  fully unscoped across all 6 semesters after confirming v7.25's course+sem
  scoping was wrong — v7.34's number (#126 for a BCA Sem II/III-range
  student, verified against admin's "All Batches" view showing the same
  #126) was in fact numerically CORRECT for "unscoped across everything,"
  but Harsha then asked for parity-only scoping specifically, which is a
  narrower, different pool than either v7.34 or v7.25 used. Class Rank,
  DI Rank, NU Rank are unaffected — still scoped to the student's own
  course+sem as fixed in v7.24/v7.26/v7.27.
VERSION : v7.34 (2026-07-25) — REVERT of v7.25's College Rank fix: v7.25
  scoped College Rank to the student's own course+sem, on the theory that
  admin's "College Rank (All Merged)" view was itself scoped to Course +
  Semester filters. Confirmed by Harsha that theory is wrong — that admin
  view is always run with Course=All, Semester=All, Section=Both; "All
  Merged" means every course and every semester in the institution pooled
  into one 413-student ranking, not just DI+NU merged within one course+sem.
  Proof case: a BCA Sem I student correctly shown as #171 of 413 in that
  admin view was instead shown as #3 on her own report card — #3 was
  actually her Class Rank (BCA Sem I only, 27 students), mislabeled as
  College Rank by v7.25's narrower pool. Fix: College Rank is once again the
  student's position in the FULL unscoped pool (every course, every
  semester, DI+NU merged, regular students only) — same as it was before
  v7.25, and exactly what extractPool already builds into allStudents. Class
  Rank, DI Rank, and NU Rank (v7.24, v7.26/27) are untouched — those were a
  separate, correct fix and stay scoped to the student's own course+sem.
VERSION : v7.33 (2026-07-25) — FIX: v7.30's "move below PREVIOUS RESULTS
  title" placement (Internal Marks + Current Semester Attendance sitting
  between the title and the per-sem tables) turned out to be the wrong
  layout entirely, confirmed via side-by-side screenshot comparison against
  a reference: PREVIOUS RESULTS/CGPI should flow DIRECTLY into the
  per-semester result tables with nothing in between, and Internal Marks +
  Current Semester Attendance should sit ABOVE the whole Previous Results
  section instead. Moved #rc-cards (Internal Marks + Attendance, both
  collapsible) back above #rc-prev-cgpi in the static markup — final order
  is now: Summary → Internal Marks/Attendance → PREVIOUS RESULTS/CGPI →
  per-semester tables → Notifications. This supersedes the positioning from
  v7.29/v7.30 (the reorder-below-title idea); v7.31/v7.32's title-before-
  CGPI ordering WITHIN the CGPI block itself is unaffected and stays as-is.
VERSION : v7.32 (2026-07-25) — FIX: found a SECOND, separate CGPI/Previous
  Results block that v7.31 missed — ascRenderPrevResults() (admin-side
  per-student card view, renders to #asc-body) builds its own independent
  CGPI banner + "PREVIOUS RESULTS" title HTML, completely separate from the
  student-facing renderReportCard()/#rc-prev-cgpi path fixed in v7.31. It
  still had the old CGPI-then-title order. Applied the same title-first,
  CGPI-underneath swap here too, so both the student's own Report Card and
  the admin panel's per-student card view now show the same order.
VERSION : v7.31 (2026-07-25) — FIX, follow-up to v7.30: within the #rc-prev-cgpi
  block, swapped the order so "PREVIOUS RESULTS" title renders FIRST, with
  the CGPI banner underneath it (was CGPI-then-title). Only this one
  container's internal order changed — everything else (attendance block
  position, per-sem tables) stays exactly as v7.30 left it.
VERSION : v7.30 (2026-07-25) — CORRECTION to v7.29: "move below PREVIOUS
  RESULTS" meant below the TITLE LINE specifically (CGPI card → "PREVIOUS
  RESULTS" title → attendance block → the actual per-semester result
  tables), not below the entire results block including the tables — v7.29
  had moved it below everything. Split the single #rc-prev-results container
  into two: #rc-prev-cgpi (CGPI banner + "PREVIOUS RESULTS" title only) and
  #rc-prev-tables (the actual per-semester result tables), with #rc-cards
  (Current Semester Attendance) placed between them in the static markup.
  renderReportCard()'s previous-results code now renders two separate HTML
  strings to these two targets instead of one combined string to one
  target — split right after the "PREVIOUS RESULTS" title is appended. The
  async rank-injection code that runs after (queries per-semester
  rc-rank-inject-* slots by ID) is unaffected since it already worked by ID
  lookup rather than a direct reference to the old container.
VERSION : v7.29 (2026-07-25) — FIX/FEAT, follow-up to v7.28 per feedback:
  (1) Moved the "CURRENT SEMESTER ATTENDANCE" block to render AFTER the CGPI
  + "PREVIOUS RESULTS" block instead of before it — swapped the static
  #rc-cards / #rc-prev-results container order in the Report Card markup.
  Attendance isn't part of results/marks, so it now sits below that section
  instead of appearing to be part of it. (2) The toggle heading was a bare
  "▶ Show" with no context, which read as an unrelated stray label rather
  than an actual button. Now shows a one-line summary (subject count +
  overall attendance %) under the heading, and the arrow text explicitly
  says "▶ Click to view" / "▼ Click to hide" so it's unambiguous that
  clicking the heading opens/closes the attendance cards.
VERSION : v7.28 (2026-07-25) — FEAT: Report Card's "CURRENT SEMESTER"
  section (the per-subject attendance cards below Internal Marks) relabeled
  to "CURRENT SEMESTER ATTENDANCE" for clarity, and made collapsible —
  clicking the heading toggles the cards open/closed via the new
  stuToggleCurSemAttendance(). Default state on page load is COLLAPSED
  (rc-cursem-cards starts with display:none, arrow shows "▶ Show") so the
  Report Card opens shorter by default; clicking expands it in place.
VERSION : v7.27 (2026-07-25) — CORRECTION to v7.26: BCA_MERGED_SECTIONS was
  initially set to just ['III'] based on the first report of the section
  merge, but Harsha clarified the same day that the merge is actually much
  broader: BCA Sem II, III, IV, V, and VI ALL have Sec A + Sec B merged into
  one section starting 2026-27 Odd — ONLY Sem I keeps its separate DI/NU
  sections. Updated BCA_MERGED_SECTIONS to ['II','III','IV','V','VI']. FOR
  FUTURE REFERENCE: this is the current, corrected merge scope — see the
  "SECTION MERGE LOG" comment right above BCA_MERGED_SECTIONS in
  computeStudentRanks() for the full history if this changes again. Verified
  with an isolated logic test across all six semesters: Sem I correctly
  still splits DI/NU (rank #1 as the only NU student in the test pool),
  Sems II–VI all correctly use the merged pool (rank #3, matching position
  by percentage in the combined pool).
VERSION : v7.26 (2026-07-25) — FEAT/ADMIN CHANGE LOGGED: BCA Sem III Sec A
  and Sec B have been administratively MERGED into a single section, effective
  the 2026-27 Odd semester onward (confirmed by Harsha, Director, 25-Jul-2026).
  This is NOT a code bug fix — it's recording a real institutional change so
  Class Rank keeps matching admin's Rankings panel. Class Rank for BCA
  normally splits DI and NU students into separate ranking pools (mirrors
  results.html's section-based ranking) — but for a merged section that
  split is wrong, since admin's own Rankings panel for BCA Sem III now shows
  one combined DI+NU ranking, not two separate ones. Added a
  BCA_MERGED_SECTIONS list (currently: ['III']) inside computeStudentRanks()
  — any BCA semester listed there uses the same DI+NU-merged pool as College
  Rank instead of splitting by section. FOR FUTURE REFERENCE: if any other
  BCA semester's sections get merged (or un-merged) later, update
  BCA_MERGED_SECTIONS in computeStudentRanks() (search for "SECTION MERGE
  LOG" comment right above it) — that's the one place controlling this
  behavior. Verified with an isolated logic test: Sem III (merged) now ranks
  a student within the full combined pool; Sem II (still split, unaffected)
  continues ranking within DI-only or NU-only as before.
VERSION : v7.25 (2026-07-25) — FIX: College Rank on the student report card
  was a totally different, much bigger number than the admin panel's own
  "College Rank (All Merged)" view for the same student — #126 on the
  report card vs #3 in admin. Root cause: the report card's College Rank
  pooled the student against literally every course and every semester in
  the institution combined (310 students) — but admin's "College Rank (All
  Merged)" checkbox does NOT do that; it stays scoped to whatever Course +
  Semester filters are selected there, and "All Merged" only means DI and
  NU sections are combined into one ranking instead of split by section.
  Fix: College Rank is now computed the same way — same course, same
  semester, DI/NU merged — matching what admin actually shows. (NU/DI rank
  were fixed the same way one version earlier, in v7.24; this applies the
  identical scoping fix to College Rank, which had the same bug.) Verified
  with an isolated logic test: old logic gave rank #5 out of a mixed
  7-student pool spanning multiple courses/sems; fixed logic correctly
  gives #3 within the actual 5-student course+sem pool, matching the admin
  "All Merged" view exactly.
VERSION : v7.24 (2026-07-25) — FIX: DI Rank and NU Rank on the student report
  card / dashboard rank tiles were wrong — a student confirmed as "#1 NU" for
  BCA Sem II in the admin Rankings panel (filtered to that exact course+sem)
  saw "#55 NU Rank" on their own report card. Root cause: computeStudentRanks()'s
  DI/NU rank pools filtered ONLY by `s.urn.includes('DI')` / `s.isNU`, with NO
  course or semester filter — despite the DI rank code comment already saying
  "same course+sem" (it never actually did that). So DI/NU rank silently
  pooled students from EVERY course and semester together, meaning a student
  could rank #1 in their own actual class but show a much worse number
  because higher-scoring NU/DI students in unrelated courses/semesters were
  being counted against them. Class Rank (computed just above in the same
  function) already correctly filtered by course+sem — DI/NU rank simply
  never matched that pattern. Fix: both now filter by `course === myCourse
  && sem === mySem` exactly like Class Rank does. College Rank is left
  unchanged — it's intentionally unscoped across all courses/semesters (see
  extractPool's own comment), which is a different, deliberately broader
  number and is expected to differ from any one class's admin table.
  Verified with an isolated logic test using synthetic same-class + other-
  class NU students: old logic gave rank #4 (should be #1) once other-class
  students with higher % were mixed in; fixed logic correctly gives #1.
VERSION : v7.23 (2026-07-25) — FIX: on load, a promoted/moved student's page
  briefly showed the PREVIOUS semester's class, theme, timetable, subjects,
  and attendance before flipping to the current semester's — the "loads
  previous sem with that theme, then loads this sem" flash. Root cause:
  restoreStudentSession() set STATE.studentUser.class/semester from
  sessionStorage (written once at login time, never refreshed) and
  immediately called loadStudentDashboard() with that stale value, WHILE
  separately kicking off an un-awaited fetch to davan_pub/portal_students/
  {urn} to get the student's actual current class — so the first full
  dashboard load (and everything downstream: theme via applyTheme(),
  timetable, subjects, attendance) used the OLD class, and only corrected
  itself a moment later when that second fetch resolved and triggered a
  re-render. Fix: restoreStudentSession() is now async and AWAITS the
  portal_students/{urn} fetch first, so STATE.studentUser.class/semester is
  already correct before loadStudentDashboard() ever runs — one single,
  correct load instead of a wrong one followed by a corrective re-render.
  The sessionStorage values are still used as the initial in-memory shape
  (so other code never sees a null studentUser) but are no longer rendered
  to screen before being corrected.
VERSION : v7.22 (2026-07-25) — FEAT: the Yesterday/Today/Tomorrow lesson-plan
  summary lines (in "📊 Attendance & Classes") now explain WHY there's
  nothing scheduled instead of silently showing nothing. Added stuDayInfo(),
  which classifies a given date as Sunday, a synced calendar-of-events
  holiday (reusing the same STATE.calendarData shape/matching as
  stuCountHolidays), or a normal day. When Yesterday had no lesson-plan
  topics marked handled, Today has nothing pending/complete, or Tomorrow has
  nothing pending/complete, the relevant line now says e.g. "Tomorrow (27
  Jul) is Sunday — happy weekend!" or "Today is a holiday — Independence
  Day, as per the calendar of events" instead of just omitting the line
  entirely. Falls through to no line at all only if the day is a genuine
  ordinary day with no timetable/lesson-plan data (unchanged prior
  behaviour) — this only adds an explanation for the Sunday/holiday case,
  it doesn't change what happens on a normal day.
VERSION : v7.21 (2026-07-25) — FIX: student attendance summary stuck showing
  the empty "New semester — attendance will show once classes are recorded"
  box even after a fresh, fully-correct scrape had already landed in
  davan_pub/students. Confirmed via live console inspection that the
  underlying data was 100% correct (stuAYState() returned 'current',
  davan_pub/students.data held the right subjects/ct/ca/pct for the student)
  yet the DOM stayed on the fresh-box view. Root cause: renderStudentDashboard_orig()
  captures _ayState ONCE at the top of the function and, if it was 'fresh' at
  that moment, schedules stuApplyFreshAttendance() again via
  setTimeout(..., 400) using that same stale captured value — it never
  re-checks stuAYState() at fire-time. Two independent code paths call this
  function: the real data-fetch flow (after Promise.all resolves and
  STATE.metaData is populated) and restoreStudentSession()'s "fast paint"
  path, which can call it BEFORE STATE.metaData has ever loaded — at which
  point stuAYState()'s `if (!scraped) return 'fresh'` fallback fires purely
  because metaData is still null, not because attendance is actually stale.
  If that fast-paint call's 400ms timer happens to fire AFTER the real,
  authoritative render has already shown correct current-semester cards, it
  silently overwrites them back to the empty fresh box, and nothing
  afterward ever calls renderAttendance() again to undo it — the page is
  stuck on stale UI state even though every underlying data source is
  correct. Fix: the setTimeout callback now re-checks stuAYState() itself
  when it fires; if state has since resolved to 'current' it calls
  renderAttendance()/renderInternals() to show the real view instead of
  blindly re-applying the fresh override.
VERSION : v7.10 (2026-07-22) — FIX: v7.08 fixed subject-name resolution for
  the PREVIOUS-results tables, but a full sweep found 10+ MORE places across
  the file with their own raw, unnormalized STU_KNOWN_NAMES[code] lookups —
  each with the identical dot/underscore vulnerability, still broken: the
  current-semester Attendance cards (Dashboard 'CURRENT SEMESTER' + dedicated
  Attendance page, both card layouts), the Internals/IA table, old timetable
  slot rendering (2x), the LP subject-name resolver fallback chain, and the
  100/100 perfect-score celebration banners in both the student Report Card
  and the admin card view. Every one of these now delegates to the shared
  STU_KLU() helper introduced in v7.08, so a code appearing in ANY of these
  contexts resolves correctly regardless of dot/underscore formatting.
  Zero raw STU_KNOWN_NAMES[...] lookups remain outside STU_KLU's own
  implementation.
VERSION : v7.09 (2026-07-22) — FIX (same underlying issue as v7.08, opposite
  side): faculty still showed '—' for B.COM-3.1 through B.COM-3.4.M even after
  v7.08 fixed the subject names. Root cause confirmed via live RTDB dump of
  davan_pub/allocation_each: code there is a plain STRING VALUE inside an
  array, so it never went through RTDB's dot-stripping (that only affects
  OBJECT KEYS, which is what happened to davan_pub/results' subjects map).
  So allocation_each kept the dotted format ("B.COM-3.1") while results has
  the underscored form (B_COM-3_1) as its subjects object key — facMap[code]
  looked up the underscored form against dotted keys and silently missed.
  FIX: facMap now also indexes every entry by its dot/underscore-normalized
  form (via the shared _stuNormCode from v7.08), and the lookup tries the
  normalized form as a fallback. Verified against live data from both RTDB
  dumps — all four subjects now resolve to their correct faculty.
VERSION : v7.08 (2026-07-22) — FIX (root cause confirmed via live RTDB dump):
  B.COM-3.1 through B.COM-3.4.M still showed raw codes despite STU_KNOWN_NAMES
  having correct entries. Ground truth from a live davan_pub/results dump: the
  actual object keys stored are B_COM-3_1, B_COM-3_2 etc (underscores, not
  dots — RTDB/Firestore object keys can't contain dots, so the sync writes
  them this way). STU_KNOWN_NAMES was keyed with the original dotted format
  (B.COM-3.1), so every lookup for these subjects silently missed and fell
  through to sub.name — which itself just held the dotted code as literal
  text ("B.COM-3.1"), not a resolved name, so the raw code displayed either
  way. FIX: added a shared STU_KLU() helper (module-level, right after
  STU_KNOWN_NAMES) that normalizes dots+underscores before comparing, so
  B_COM-3_1 correctly matches the B.COM-3.1 map entry. All three previously-
  separate _klu/_knownLookup copies now delegate to this one implementation.
  Also added the missing COMP-DP-3 (Personality Development) entry.
  Removed the temporary v7.07 diagnostic console.warn.
VERSION : v7.07 (2026-07-22) — DIAGNOSTIC: B.COM-3.1 through B.COM-3.4.M still
  show raw codes despite STU_KNOWN_NAMES having verified-correct entries for
  all four (confirmed working in isolated test). Since ENGL-C-3/KAN-C-3 on the
  SAME row resolve correctly, the map/lookup logic itself works — something
  about the actual stored code/name for B.COM-3.x specifically differs from
  what's expected (whitespace/case already ruled out via direct testing).
  Added a temporary console.warn in the report-card table row renderer that
  fires whenever a lookup fails, dumping the exact code string, its character
  codes (to catch lookalike Unicode chars), and sub.name/short — needed to see
  the real bytes Firestore holds, which can't be determined from static file
  inspection. Remove once root cause is confirmed and fixed.
VERSION : v7.06 (2026-07-22) — FIX: BCom students showed raw subject codes
  (ENGL-C-1, KAN-C-1, and similar) instead of resolved names for their
  language/English/constitution subjects. ROOT CAUSE: STU_KNOWN_NAMES only had
  BCA-style codes (ENGL-S-1, KAN-B-1) -- BCom uses a different code family
  (ENGL-C-1, KAN-C-1, HINL-C-1, SAN-L-C-1, URL-C-1) for the same subjects,
  which was never added. Added all BCom Sem I/III/V language+English code
  variants, sourced directly from results.html's own KNOWN_NAMES map
  (authoritative, verified against the real portal data) rather than guessed.
  NOTE: faculty still shows '-' for several BCom subjects in the same table --
  that's a separate gap (missing/incomplete allocation_each doc for that
  semester's BCom section), not a code-naming issue; flagged for follow-up.
VERSION : v7.20 (2026-07-23) — FIX: Lesson Plan panel showed stale prior-semester subjects
  (e.g. "AFM", 98% done, updated_at ~02-Jun) alongside this term's real subject for the same
  faculty/course (e.g. "Financial Management", 7% done, updated_at today) — confirmed via
  user-provided evidence chain: app.py's scraper writes key and subject field from the same
  source variable (no mismatch possible there); index.html's admin Lesson Plan view showed
  BOTH "AFM" and "Financial Management" as separate cards for the same faculty, proving two
  genuinely distinct records coexist in davan_pub/lessonPlan, not a display-layer name bug.
  Root cause (already diagnosed and fixed for the ADMIN view in index.html v1009, but never
  ported to the student portal): davan_pub/lessonPlan is a flat blob with NO academic-year
  stamp — it accumulates lesson-plan entries across every semester ever scraped, so an old
  semester's subject and the current semester's subject for the same class can both legally
  match filterLPForStudent's course/sem/section filter (both say "Sem5", "BCom", etc.) even
  though one is months-stale. index.html solved this with _lpFilterByAY(): drop any entry
  whose updated_at predates the live semester's start date, applied at the single fetch
  choke point. Ported the same logic to student_portal.html as _stuLpFilterByAY() /
  _stuLpSemStartMs(), applied inside filterLPForStudent() (the shared choke point all 3
  STATE.lessonPlan assignment call sites already funnel through) — after the existing
  course/sem/section/exception filtering, additionally drops entries whose updated_at is
  older than the semester start (STATE.semConfig.startDate, with the same 13-Jul-of-AY-year
  fallback stuRenderSemStartNote() already uses when session_config isn't loaded yet).
  Entries with no updated_at at all are kept rather than dropped (can't judge recency, so
  err toward showing). Archive/legacy AY view (STATE._viewIsArchive) is exempt — shows the
  full historical blob unchanged, matching admin's _legacyDataInScope() behavior exactly.
VERSION : v7.19 (2026-07-23) — FIX: Today/Tomorrow lines (and any other feature routed
  through portalClassToMotherClass) never worked for BCom/BBA students — confirmed via
  console debug (user pasted real data): motherCls computed as "II YEAR B.Com (A)" but
  real motherTT class strings for BCom/BBA carry NO section suffix at all — actual values
  are "I YEAR B.Com", "II YEAR B.Com", "I YEAR BBA", "III YEAR BBA" etc. (only BCA runs
  multiple sections, e.g. "II YEAR BCA (A)"/"(B)", so only BCA rows have "(section)").
  portalClassToMotherClass() was unconditionally appending "(A)"/the parsed section to
  every course, producing a class string that matched zero timetable rows for BCom/BBA —
  hence rowsForMyClass: 0 in the debug dump despite allocs correctly resolving (22 course
  matches, 8 full matches). Fixed both parsing branches (roman-numeral format and
  Sem-keyword format) to only append "(section)" when the course is BCA; B.Com/BBA now
  return the bare "<year> YEAR <course>" string matching real data. stuLmClassMatch_'s
  section-comparison already degraded correctly for a sectionless ttClass (no regex
  match → falls through to unconditional true), so no change needed there. This was a
  single shared function used by 5 call sites (Today/Tomorrow, timetable rendering,
  attendance-summary-related lookups), so the fix applies uniformly, not just to the
  Your Summary card.
VERSION : v7.18 (2026-07-23) — CHANGE: dashboard top-of-page reorder, per user request
  (screenshot showed the "assigned N subjects / semester dates / working days" note at
  the very top, wanted it moved below Perfect Attendance/celebrations; wanted "Your
  Summary → 📊 Attendance & Classes" moved to the top instead, with a greeting line in
  its old spot). Moved #dash-sem-note (stuRenderSemStartNote output) from directly under
  the page subtitle down to right after #sd-celeb-section (celebration banners / Perfect
  Attendance). Added new #dash-greeting element in its old top spot, rendered by new
  stuRenderGreeting(u) — time-of-day-aware ("Good morning/afternoon/evening, <Name>!"),
  called from updateSidebarProfile() alongside the existing stuRenderSemStartNote() call.
  Split renderDashStudentSummary() so Part 1 (Attendance & Classes) now renders into a
  new #sd-summary-top-card placed right under the greeting, while Parts 2/3 (Internals,
  Semester Result) remain in the original #sd-summary-cards lower on the page — the
  "Your Summary" section heading above them is unchanged, now just holding 2 cards
  instead of 3. #sd-summary-part1-body id is preserved (just relocated in the DOM), so
  the async prev-results refresh logic for Part 3 is unaffected.
VERSION : v7.17 (2026-07-23) — FEAT: "Your Summary" card, Part 1 — added a "Today" line,
  matching the same timetable-driven logic already used for "Tomorrow" (per user request:
  card showed Yesterday + Tomorrow but not Today). Refactored the day→subjects→lesson-plan
  resolution (class/day timetable match, allocation-based subject-name resolution, lowest
  still-pending sl.no per subject) out of the Tomorrow block into a shared resolveDayLP(date)
  helper, called once for today and once for tomorrow — avoids duplicating that logic a
  third time. Today's line uses var(--warn) (amber) to sit visually between Yesterday's
  blue (past) and Tomorrow's accent color (future); shows "Syllabus already complete for
  <subject>" the same way if every topic for a today-subject is already handled. The
  "Coming up next" fallback now only fires when BOTH today's and tomorrow's timetable
  resolution come up empty (previously only checked tomorrow).
VERSION : v7.16 (2026-07-23) — FIX: eliminated the multi-second "flash old theme → flash
  empty panels → then real data" sequence on fresh student login. Root cause: goToDashboard()
  called showScreen('screen-student-dash') immediately, then awaited loadStudentDashboard()
  afterward — so the dashboard was visible with the default theme and empty panels for
  however long the 14 parallel Firebase reads inside loadStudentDashboard() took, only
  flipping theme + populating real semester data once those calls resolved. Reordered:
  dashboard screen is now shown only AFTER loadStudentDashboard() (which applies the
  correct theme and loads real data) completes, with a simple full-screen loader
  (showStuDashLoader/hideStuDashLoader) covering the wait in between. Net effect: student
  goes straight from login to a fully-themed dashboard with correct current-semester data
  in one paint — no intermediate stale/default frame.
VERSION : v7.15 (2026-07-23) — FEAT: Dashboard "Attendance Summary" card (renderDashAttSummary)
  — added a Held / Attended / Missed stat block before the % column for each subject, per
  user request (screenshot showed only % + progress bar + SHORTAGE/100% badge; requested
  the raw class counts too). Held = sub.ct, Attended = sub.ca, Missed = ct-ca (same fields
  already used for the % calc, no new data source). Rendered as a compact 3-line stack
  (📚 Held / ✅ Attended / ❌ Missed) with color-coded values (text/ok/danger), tagged
  .sd-att-stats for a mobile @media(max-width:480px) font-size reduction to keep the row
  from crowding on phones — the file's existing mobile breakpoint.
VERSION : v7.14 (2026-07-23) — CONFIRMED FIX: v7.13's Tomorrow-line fix verified working
  against real data (screenshot showed correct sl.no + subjects for Internet Programming
  Lab and Kannada). Removed the temporary [Summary Tomorrow debug] console.info added to
  diagnose it. FEAT: full color-coding pass across all three "Your Summary" cards for
  clearer at-a-glance scanning — consistent palette: var(--danger)/var(--warn)/var(--ok)
  for severity-graded numbers (attendance %, syllabus %, IA averages, SGPA), var(--blue)
  for neutral informational lines (Yesterday, teaching-days-completed, next internal
  exam date), var(--accent) for forward-looking lines (Tomorrow, Coming up next) with
  the sl.no now rendered as a small accent-colored pill instead of plain text. Replaced
  a hardcoded #f59e0b in Part 3 (Backlog/Repeater tag) with var(--warn) for consistency.
  Added SGPA and IA1/IA2 average color-grading (ok/warn/danger by threshold), matching
  the existing attColor() pattern used for attendance elsewhere on the dashboard.
VERSION : v7.13 (2026-07-23) — FIX: v7.12's "Tomorrow" line never rendered (confirmed via
  screenshot — Yesterday line showed, Tomorrow line was silently absent, no fallback
  either). Root cause: the tomorrow-timetable filter compared raw STATE.motherTT row
  class (mother-app format, e.g. "II YEAR BCA (A)") directly against the student's
  PORTAL class string, which uses different naming — exactly the mismatch
  portalClassToMotherClass() exists to bridge, and exactly the class of bug the timetable
  panel itself (renderStudentTimetable) already guards against. The filter matched zero
  rows every time, so tmrwPending/tmrwComplete were always empty, and apparently so was
  the given_date fallback for that day — nothing rendered. Also fixed: subject-name
  resolution per slot now goes through the matched allocation (alloc.splitSubject/
  alloc.subject via stuLmClassMatch_+stuLmAllocMatchesCode_), mirroring exactly what
  renderStudentTimetable does for the real Timetable panel, instead of feeding the raw
  slot code (e.g. "DBMS A1") straight into the LP matcher, which the lesson plan is not
  keyed/labelled by. Added standalone _-suffixed copies of stuLmBaseCode/stuLmParseCode/
  stuLmClassMatch/stuLmAllocMatchesCode (previously local-only to renderStudentTimetable)
  so the summary card can call them. Day matching now uses motherCls/MOTHER_DAYS
  ('Monday'..'Saturday') consistently — tomorrow being Sunday correctly yields no rows
  (falls through to the given_date fallback) rather than a wrong day-name lookup.
  Also: gave the Tomorrow-pending and syllabus-complete lines their own color treatment
  (var(--accent) / var(--ok)) matching the rest of the card, since even once fixed the
  line was easy to miss sitting uncolored next to the colored attendance/yesterday lines.
VERSION : v7.12 (2026-07-23) — CHANGE: "Your Summary" card, Part 1 — "Tomorrow" is no
  longer driven by given_date at all. Per spec: (1) look at tomorrow's TIMETABLE
  (STATE.motherTT, filtered by class + tomorrow's day name) to find which subjects
  actually have a class tomorrow; (2) for each such subject, resolve it to its lesson
  plan via new stuGetLPForSubject() (standalone version of the matcher previously local
  to renderStudentTimetable); (3) within that subject's topics[] — array order = sl.no
  order, matching the Lesson Plan panel's numbering — find the LOWEST serial number
  still not handled_date, via topics.findIndex(t => !t.handled_date). This is
  intentionally order-agnostic about what's been completed: if faculty marks sl.no 10
  done while sl.no 2 is still open, tomorrow still reports sl.no 2, since that's the
  earliest genuinely-pending topic — out-of-order completions elsewhere don't change
  it. If every topic for a tomorrow-subject is handled, reports "syllabus already
  complete for <subject>" instead of a topic (confirmed with the user). Reports
  "Tomorrow, as per your timetable: <Subject> — sl.no N: <topic>" per matched subject.
  The old given_date-based "Coming up next" line is kept ONLY as a fallback for when
  tomorrow's timetable yields nothing (no classes tomorrow, or no LP match found) —
  otherwise dropped to avoid disagreeing with the new timetable-based line.
VERSION : v7.11 (2026-07-23) — FIX: v7.10's "Yesterday/Tomorrow" lines never showed —
  sameDay() assumed handled_date/given_date are YYYY-MM-DD, but the real scraped format
  is day-first with no year and a time suffix (e.g. "22/07 05:04 PM", confirmed from
  the actual Computer Architecture lesson-plan card). The YYYY-first regex never
  matched that, so taughtYesterday/scheduledTomorrow were always empty and both lines
  silently didn't render — same silent-empty failure mode as the earlier attendance
  bug. sameDay() now tries DD/MM[/YYYY] first (defaulting year to the reference date's
  year when omitted, matching the real data), then falls back to YYYY-MM-DD in case
  that format is used elsewhere. Verified against the exact "22/07 05:04 PM" value.
VERSION : v7.10 (2026-07-23) — FEAT: "Your Summary" card, Part 1 — added explicit
  "Yesterday you covered..." and "Tomorrow you're scheduled to cover..." lines, listing
  actual topics (subject + topic name) whose handled_date matches yesterday or
  given_date matches tomorrow, instead of only the single earliest pending topic. The
  old "Coming up next" line is kept as a fallback for when nothing is dated exactly
  tomorrow (e.g. next class is a few days out), so it no longer duplicates the new
  tomorrow line when both would apply. Date matching parses YYYY-MM-DD/YYYY/MM/DD
  directly (not via new Date()) to avoid ambiguous-format misparses.
VERSION : v7.09 (2026-07-23) — FIX: "Your Summary" card (v7.08) had a duplicate-id bug —
  cardWrap() put id="sd-summary-part3-body" on all three cards' body divs, so
  document.getElementById grabbed the FIRST match (Part 1's attendance body) for the
  async prev-results refresh, silently overwriting the attendance text with Part 3's
  content while the real Part 3 card sat stuck on its placeholder. Fixed: each card's
  body now gets its own id (sd-summary-part1/2/3-body) passed into cardWrap explicitly.
  Also: Part 1's attendance section previously had no output at all when canShow
  ('attendance') was true but the subject list came through empty — the whole if-block
  was skipped with nothing pushed to lines[]. Now always pushes an explicit line
  ("Attendance is hidden…" / "No attendance data available yet…" / the real numbers).
  FEAT: Part 1 now also includes the completed/remaining teaching-days line ("✅ N
  teaching days have been completed so far, with M teaching days remaining"). Extracted
  the computation out of stuRenderSemStartNote into a new shared stuTeachingDaysLine()
  helper so the dashboard note and the summary card always show the same numbers.
VERSION : v7.08 (2026-07-23) — FEAT: new "Your Summary" card on the student dashboard,
  below Recent Notices — 3 plain-language parts, all pure summarizers over data already
  loaded elsewhere (no schema changes):
  Part 1 (Attendance & Classes): overall attendance % in plain language, subjects short
  of the 75% minimum, average syllabus completion %, subjects most behind, and the next
  un-taught topic (earliest given_date with no handled_date) as "coming up next".
  Part 2 (Internals): calendar-aware — reads STATE.calendarData for Exam-type entries
  whose title mentions "internal"; shows "coming soon" if none scheduled yet, the
  upcoming date if scheduled, "conducted, awaiting marks" if the date has passed with
  no marks in STATE.studentData.subjects (int1/int2), or IA1/IA2 averages + subjects
  below the 11/30 pass mark once marks are in.
  Part 3 (Semester Result): reads STATE._lastPrevResults (same source as the Report
  Card panel) — backlog/repeater flag, latest SGPA/%, failed subjects to focus on, and
  SGPA trend vs the prior semester. Since _lastPrevResults is normally only populated
  when the Report Card panel is opened, renderDashStudentSummary now also fetches it
  itself in the background via rcLoadPrevResults on first dashboard load if not yet
  cached, then re-renders just Part 3's body once it resolves.
  New functions: renderDashStudentSummary, stuSummaryPart1/2/3. Hooked into the existing
  dashboard render cycle right after renderDashAttSummary/renderDashNoticesPreview.
VERSION : v7.07 (2026-07-23) — FIX: completed/remaining teaching-days clause (added in
  v7.06) now excludes TODAY from the completed count — today is still in progress, not
  yet a finished teaching day, so the span is start..yesterday (capped at semester end)
  instead of start..today. Also split out of the working-days sentence into its own
  separate line (l4) with a ✅ prefix, rather than trailing onto the same sentence.
VERSION : v7.06 (2026-07-23) — FEAT: dashboard semester-note (stuRenderSemStartNote)
  now appends a dynamic "X days completed / Y teaching days remain" clause after the
  existing working-days sentence. Counts Mon-Sat days from semester start through
  today (capped at semester end), minus Sundays and non-teaching days (Holidays +
  Exam/Internal calendar entries, via new stuCountNonTeaching helper) in that elapsed
  span. Fully dynamic — advances by itself day to day, and immediately reflects any
  holiday or internal/exam added to the synced calendar or session_config, no manual
  update needed.
VERSION : v7.05 (2026-07-22) — FEAT: previous-semester result records now tag
  _isBacklog when the matched student came from a Firestore results doc's
  backlog[] array instead of regular[] (a failed student retaking that
  semester) — mirrors the same fix made in the mother app (index.html)
  rcFetchResults. A "BACKLOG / REPEATER" badge now shows on the semester
  header in all three render locations: the dashboard's per-sem mini-cards
  (rc-summary), the full student Report Card panel, and the admin-facing
  ascRenderPrevResults card. Previously a backlog-only semester rendered with
  no indication it was a repeat attempt, identical-looking to a normal pass/
  fail semester.
VERSION : v7.04 (2026-07-20) — FIX: attendance % showed last term's figures even
  after a real current-sem scrape. The scraper's stored sub.pct is unreliable at a
  term boundary (already documented v6.34), but the dashboard summary + Attendance
  cards trusted it first (ca/ct only as fallback). Added shared stuSubPct(s) that
  recomputes from ca/ct (classes attended / conducted) as the source of truth,
  wired into the dashboard summary rows, the Attendance-page cards, and the "at a
  glance" overall + shortage/OK counts. Overall now weights by Σca/Σct (true
  overall) instead of flat-averaging per-subject %. Subjects with no conducted
  classes render '—' with no bar/badge instead of a fake 0%/shortage. NOTE: if
  ca/ct themselves are stale, the fix is scraper-side (app.py) — verify via the
  "X / Y classes attended" line.
VERSION : v7.03 (2026-07-18) — FIX: fresh-semester detection used the wrong
  boundary, so a continuing student saw last term's attendance (60.3% overall,
  progress bars, SHORTAGE badges) on a brand-new semester. Two bugs: (1)
  stuAYState() only granted the "fresh" treatment to promoted students, so
  continuing students fell through to 'current'; (2) even after that gate was
  removed, the boundary was hardcoded to 1 Jul while the semester actually starts
  17 Jul — the 14 Jul scrape landed in that gap and was read as current-term data.
  stuAYState() now uses the REAL configured start (stuSemStartMs() →
  semConfig.startDate, the same 17 Jul the dashboard banner reads), falling back
  to the 1st-of-month heuristic only if config is missing. stuSemStartMs()
  hardened to parse dates the same robust way as _adminLPIsStale ('/'→'-', append
  midnight) so an odd stored format can't silently null it and drop to the broken
  fallback. Attendance-page fresh box now also lists subjects + faculty (via
  stuFreshSubjectsHtml), matching the dashboard summary — progress bars and % only
  appear once real classes are scraped. stuDebugState() updated to report the
  config-based boundary.
VERSION : v6.88 (2026-07-10) — Added admin-controlled global app theme (Odd/Even palette swap).
  New Theme tab in admin panel (sidebar + tab bar) lets admin pick between the original dark/amber
  look ("odd") and a new dark/teal look ("even") — colors only, same layout/fonts/radius throughout,
  so no existing component needed duplicating. Mechanism: new html[data-theme="even"] CSS block
  overrides the same --bg/--surface/--accent/--text variable names as :root; every existing rule
  already reads from these vars so the whole app re-skins with zero other CSS changes. Setting is
  stored at controls/theme ('odd'|'even', defaults to 'odd' if unset) and read back inside the
  existing loadAllData() controls fetch on every session boot (student + admin alike) — no extra
  network round trip. saveTheme()/applyTheme() added near saveGlobal(), same rtdbPatch pattern.
VERSION : v7.02 (2026-07-18) — Library panel: no way to pull fresh data short of
  reloading the WHOLE portal. libGet() never caches, so a targeted refresh was
  always possible — there was just no button for it. Added ↻ Refresh in the
  panel header, calling renderLibraryPanel() directly (same function the panel
  already runs on open), so a librarian-side fix (e.g. the admin pickup-date
  sweep) shows up without losing scroll position or re-fetching every other
  dashboard panel.
VERSION : v7.01 (2026-07-18) — The collection slot the librarian sets never
  reached the student. setAppt() in library.html writes it to
  library/requests/{id}/appt and library.html renders it — but this panel's
  READY block only ever rendered the title and the token, so appt, exp and the
  librarian's note were all in the record and simply never read. The slot dialog
  literally promises "This appears on the student's own login beside their
  token", which was only true INSIDE the library app, not in the portal where
  students actually look. READY now shows the slot (date, from–to, note) via
  libApptLine() mirroring library.html's apptLine(), plus the pickup deadline
  from r.exp with days left, turning red once it has passed, and a line saying
  the copy passes on if uncollected. IN QUEUE was worse — it showed only the
  title, never the position, which is the one thing a waiting student wants:
  now #N of M (ranked by dt among 'waiting' rows for that title, same ordering
  as library.html's queueFor()), the request date, and the pickup window from
  cfg.pickupDays.
VERSION : v7.00 (2026-07-18) — Library panel: the student was never told when a
  book was written off. library.html v1.37 added a lost/damaged close-out, which
  stamps ret to stop the fine clock and unblock the student — but myIss filters
  !x.ret, so the loan silently VANISHED from this panel with no trace they ever
  had it or that a replacement charge exists. Added a lost/damaged card (title,
  outcome, date, librarian's note, charge) and, on the borrow CTA, the loan terms
  now state the replacement charge BEFORE they apply — previously they agreed to
  terms that omitted the single largest charge they can incur. Charge is read
  from library/config replaceCost, so it tracks the Settings value.
VERSION : v6.99 (2026-07-17) — Library panel: per-book fine lines. Before the
  due date each loan shows "late fine ₹X/day after due date"; once overdue it
  shows THAT book's fine building live ("fine so far ₹N · growing ₹X/day"), so
  the student reaches the desk already knowing the exact amount. Rate comes
  from library/config finePerDay, not hardcoded.
VERSION : v6.98 (2026-07-17) — (1) Library opens INSIDE the portal: §LIBX
  full-screen iframe overlay + postMessage SSO (DAVAN_LIB_SSO / _READY /
  _CLOSE handshake, same-origin gated) so students never sign in twice.
  (2) Desktop sidebar finally got its Library item — only the mobile More
  drawer ever had one (stb-library); snav-library added after Calendar, with
  its own badge id (library-snav-badge) to avoid duplicate-ID breakage.
  (3) Overdue signals: red banner in the Library panel (count, live fine at the
  configured rate, borrowing-blocked note) and the nav badge now shows the
  overdue count in red, taking priority over the green ready-for-pickup count.
VERSION : v6.97 (2026-07-10) — Same bug shape as v6.96, this time for the Theme (odd/even)
  setting: applyTheme() was ONLY ever called from admin's loadAllData() and from clicking the
  admin Theme tab — the student's own load path (loadStudentDashboard) fetched 'controls' (which
  includes the theme field) but rebuilt STATE.controls with only global/byClass/byUrn, silently
  dropping theme, and never called applyTheme() at all. So a student's browser always rendered
  the default 'odd' palette regardless of what admin set, unless that tab had loaded admin
  first (same root cause as v6.96, different field). Fixed by calling applyTheme() on the
  student path too, reading controls.theme from the same fetch that already happens. Confirmed
  applyTheme() is safe to call here — every DOM lookup inside it (admin-only elements like
  theme-btn-odd) is already null-checked.
VERSION : v6.96 (2026-07-10) — Fixed the student dashboard's semester-dates note only showing
  real dates after visiting admin first in the same browser session. Root cause: STATE.semConfig
  was ONLY ever populated by loadAllData(), which is admin-only (called from
  enterAdminDashboard()) — the student's own load path (loadStudentDashboard) never fetched
  davan_pub/session_config at all. So a student logging in fresh always got STATE.semConfig ===
  null/undefined and stuRenderSemStartNote() fell back to the guessed 13-Jul date; the only
  reason it ever showed correctly was if the SAME browser tab had triggered an admin load
  earlier, leaving STATE.semConfig populated from that unrelated session. Added session_config
  to loadStudentDashboard()'s own Promise.all (cached with the same 30-min TTL as other
  slow-changing values), so every student session fetches it independently — no admin detour
  needed. Confirmed via user's own screenshots: admin-set values (20 Jul 2026, 116 days, 16
  Sundays, 100 working days) were correct in DB2, they just weren't reaching a fresh student
  session before this fix.
VERSION : v6.95 (2026-07-10) — Found the actual reason the Semester Dates control (v6.92)
  wasn't visible under Controls: it was never broken, it was in the WRONG TAB. The v6.92
  str_replace insertion matched STEP 3 text that exists inside tab-archives, not tab-controls,
  so the whole Semester Dates block got nested at the end of Archives instead — which is also
  why v6.94's div-balance investigation came back clean (structurally it was fine, just
  misplaced). Cut the block out of tab-archives and moved it to its intended location: end of
  tab-controls, right after the "By URN Override" section. Verified: tab-controls now 47/47
  balanced (was missing this block before), tab-archives still 45/45 balanced after removal,
  whole-document div count still 1099/1099, syntax clean.
VERSION : v6.94 (2026-07-10) — Found and fixed a REAL structural bug from my own earlier edit,
  though I can't yet confirm it's the full explanation for blank Students/Notices/Timetable
  tabs (browser console showed zero errors, which is consistent with either this bug or
  something else). The v6.92 Semester Dates insertion used a str_replace that matched text
  starting mid-way through the pre-existing STEP 3 card — this silently deleted that card's
  body paragraph ("In the MOTHER APP: load the NEW/current semester's timetable...") and its
  own closing </div> tags. Restored the missing content and tags exactly as they were before
  v6.92. Verified: whole-document div count is balanced (1099 open / 1099 close), tab-controls
  region is balanced (79/79), tab-students region is self-contained and balanced (13/13), JS
  syntax is clean. If tabs are STILL blank after this, the cause is something else — worth
  checking Network tab (not just Console) for failed requests, since a 403/permission error on
  a specific path wouldn't always throw a JS exception depending on how it's caught.
VERSION : v6.93 (2026-07-10) — Fixed admin Students/Notices/Timetable/etc tabs going completely
  blank with no on-screen explanation. Root cause: 4 of loadAllData()'s Promise.all calls
  (portal_students, controls, notices, davan_pub/students) had NO .catch() — confirmed
  pre-existing in the original file, not introduced by recent changes. Because they shared one
  Promise.all with no per-call catch, ANY single failure among them rejected the whole batch and
  skipped straight to the outer catch, so STATE.students/notices/allStudents/controls never got
  set — blanking every tab that depends on initial load, while tabs with their own separate
  fetch (like Controls' new Semester Dates loader) kept working, exactly matching the reported
  symptom. Added .catch(()=>null) to all 4 so one bad call degrades only that section. Also: the
  outer catch previously only console.error'd — invisible unless devtools was open — now shows
  a dismissible on-screen banner naming the actual error plus a Retry button, so "why is
  everything empty" has a real answer next time instead of silent blank tabs.
VERSION : v6.92 (2026-07-10) — (1) Removed the last DB1 read in the student app. Academic
  calendar (fetchAdminCalendar) previously fetched PRIMARILY and DIRECTLY from DB1's Firestore
  (davan-attendance-2026/app_data/academic_calendar), on every load, for both student and admin
  sessions — only falling back to DB2 (davan_pub/calendar) on error. Confirmed via grep this was
  the only DB1 read anywhere in the file; everything else (session_config, portal_students,
  timetable, allocations, lessonPlan, notices, controls) was already DB2-only. Removed the DB1
  fetch entirely — fetchAdminCalendar() now reads davan_pub/calendar exclusively. IMPORTANT:
  this makes the portal fully dependent on DB2's calendar being kept current by whatever pushes
  it from the mother app (_normCalForPortal(), confirmed already writes the correct normalized
  shape — {date,day,type,event,endDate,for} — so no shape-conversion logic was needed here). If
  that push doesn't run, the calendar and the working-days/holiday count on the student
  dashboard will legitimately show empty — that's a sync-freshness issue to fix on the push
  side, not something this fetch masks anymore.
  (2) Added a Semester Dates admin control (Controls tab) — session_config.startDate/endDate
  had NO admin UI at all before this; the dashboard's "Classes start ... in N days" note and
  working-days count silently fell back to a hardcoded 13-Jul guess whenever it was unset in
  DB2. New date inputs write directly to davan_pub/session_config (DB2) via saveSemesterDates();
  loadSemesterDatesUI() pre-fills them from current data and shows a "not set — using fallback"
  hint when empty, so it's now visible from the admin panel whether that date is real or guessed.
VERSION : v6.91 (2026-07-10) — CORRECTION: v6.90 accidentally shipped without the v6.88 Theme
  tab. Root cause was a version-chain mistake on my end — when fixing the archive-view bug
  report, I rebuilt from a freshly re-uploaded v6.87 (pre-Theme-tab) instead of v6.88
  (post-Theme-tab), so v6.89 and v6.90 both silently lost the Theme tab while keeping the
  archive fixes. This version re-merges everything correctly from v6.88 as the true base:
  Theme tab (v6.88) + archive-view STATE._viewIsArchive fixes across all 3 guards + sync
  button (v6.89) + single-source APP_VERSION/BUILD_DATE display fix (v6.90), verified all
  three are present before shipping.
VERSION : v6.90 (2026-07-10) — Fixed the on-screen version number being permanently stuck at
  "v6.84" no matter how many releases shipped after it, which made it impossible to tell from
  the live site whether a new build had actually deployed. Root cause: the displayed version
  existed as 8 separate hardcoded 'v6.84' string literals (page <title>, topbar chip, topbar
  row2 meta, and 3 footer "Version: ..." lines — 2 of which weren't even wired to JS at all,
  just static dead HTML) — every version bump since v6.84 updated the changelog comment at the
  top of the file but never touched any of these display strings, so the UI silently froze
  while the file kept moving. Fixed by adding APP_VERSION + BUILD_DATE as the single source of
  truth (defined once, near STATE); all 8 spots now read from these two constants. Going
  forward, bump ONLY these two lines at each release — nothing else needs touching.
VERSION : v6.89 (2026-07-10) — Fixed student Attendance/Internals/Lesson Plan showing empty
  "new semester" screens when viewing a PAST (archived) AY, even though real archived data was
  correctly fetched. Root cause: stuFreshGuard(), renderStudentDashboard_router(), AND
  switchStudentPanel() (a third copy of the same bug, found via follow-up report "auto data
  not loading, only sync icon loads it" — this one runs on every panel-nav click, silently
  reverting the correct archive render back to the fresh-semester placeholder the moment the
  student tapped a panel) all detected archive view by comparing STATE._viewAY to a hardcoded
  key ('2025-26_even') that doesn't match legacy archive keys like bare '2025-26'. Fixed by
  having stuSwitchAY() set an explicit STATE._viewIsArchive flag (it already knows this for
  certain via isLive) and pointing all guards at that instead. Also added: one automatic
  silent retry if studentData comes back null after an archive fetch, and a 🔄 sync button
  beside the AY dropdown that manually re-runs stuSwitchAY() — turns red if data still looks
  empty after the auto-retry.
VERSION : v6.88 (2026-07-10) — Added admin-controlled global app theme (Odd/Even palette swap).
  New Theme tab in admin panel (sidebar + tab bar) lets admin pick between the original dark/amber
  look ("odd") and a new dark/teal look ("even") — colors only, same layout/fonts/radius throughout,
  so no existing component needed duplicating. Mechanism: new html[data-theme="even"] CSS block
  overrides the same --bg/--surface/--accent/--text variable names as :root; every existing rule
  already reads from these vars so the whole app re-skins with zero other CSS changes. Setting is
  stored at controls/theme ('odd'|'even', defaults to 'odd' if unset) and read back inside the
  existing loadAllData() controls fetch on every session boot (student + admin alike) — no extra
  network round trip. saveTheme()/applyTheme() added near saveGlobal(), same rtdbPatch pattern.
VERSION : v6.87 (2026-07-09) — Root-caused the lab label bug properly (v6.86 was patching the wrong
  regex branch). Checked the mother app's real lmParseCode(): current lab slot codes use the "friendly"
  format "JAVA A2·Lab 2" (base + section-letter+batchNum + · + "Lab" + physical room number), NOT the
  old "SUBJ A1(A)" format stuLmParseCode only handled — so it never matched at all and silently fell
  through to the plain-code branch, hence bare "Java". Added the same labFriendly regex to
  stuLmParseCode() (now returns batch AND lab room separately) and the matching strip-rule to
  stuLmBaseCode() so allocation/faculty matching also picks up lab slots in this format correctly.
  Card now renders a separate "🧪 A2·Lab 2" line under the subject, mirroring the admin timetable
  grid's own codeCell style exactly (index.html lines ~26480-26483) instead of jamming batch text
  into the subject name.
VERSION : v6.86 (2026-07-09) — Fixed student Timetable showing plain "Java" for lab slots instead of the
  actual batch (e.g. "Java A2 Lab"): stuLmParseCode()'s regex already captured the batch code (A1/A2/B1/B2
  from raw slot codes like "JAVA A2 (B)") into its 3rd/4th match groups but silently discarded them —
  only the subject prefix (group 1) was kept as `base`. First attempt only appended the batch when an
  alloc was matched, so unmatched slots stayed bare; also risked double-"Lab" if alloc.subject already
  ended in "Lab". Fixed: subject name is now always normalised to "<Subject> <Batch> Lab" for any slot
  that parses as a lab, batch always shown, regardless of alloc match.
VERSION : v6.85 (2026-07-09) — Fixed admin Academic Calendar STILL showing "not synced yet" after v6.84:
  that fix only patched adminSwitchAY(), but switchTab('admincal') — which runs every time the Calendar
  tab is clicked — had the exact same bug (force-nulling STATE.calendarData for current AY) and was
  running AFTER adminSwitchAY's correct fetch, wiping it out again. Now switchTab('admincal') calls
  fetchAdminCalendar() itself (same source loadAllData() uses on initial load) instead of nulling.
VERSION : v6.84 (2026-07-09) — Fixed admin Academic Calendar showing "not synced yet" while student
  portal showed real synced events: adminSwitchAY() was force-nulling STATE.calendarData for the
  "current" AY view right after fetching it correctly, on the theory it might be stale mother-app
  data — no longer needed, so the fetch result is kept as-is. Temporary Class Change (Timetable tab):
  Slot/Subject is now a dropdown built from that class's actual timetable rows for the selected day
  (STATE.adminDayMap + _ttAllocFor, via populateOverrideSlotOptions/onOverrideSlotChange), instead of
  free text. Adds two whole-class quick actions ("Go Home — class suspended" / "Class Suspended, no
  substitute") and an "Other / add new subject…" option that reveals the old free-text field for
  anything not already on the timetable. Dropdown rebuilds on day-change and after class switch
  (now correctly ordered after renderAdminTT so it reflects the newly selected class, not the
  previous one).
VERSION : v6.83 (2026-07-09) — Timetable now auto-syncs DB1→DB2 (portal copy) silently whenever the admin
  opens the Timetable tab, with cheap fingerprint change-detection so it only writes when the mother-app
  data actually changed; manual button relabeled "Force Re-sync" as a backup. Banned Students chips
  rebuilt: row 1 = current-AY classes only (STATE.liveClasses); row 2 = dedicated passout section grouped
  by batch(AY) with expandable per-batch class chips (renderBanPassoutChips/toggleBanPassoutExpand),
  matching the archive-style grouping used in Notice/Banner/Broadcast passout pickers — direct chips, no
  dropdown. Academic Calendar: fixed STATE.calendarData shape-check bug (was dropping {data:[...]}-shaped
  payloads, only accepted raw arrays) on both admin and student load; empty-state message now explains
  the likely real cause when session.portal config exists but events don't — mother app's Session
  Configuration is probably still the OLD AY's dates, so _normCalForPortal() filters all events to empty
  before pushing. Fix: update Session Configuration in the mother app to the current AY, then re-save any
  calendar event to re-trigger the auto-push.
VERSION : v6.82 (2026-07-09) — Passout targeting extended to Live Banner + Broadcast Message (same
  Batch-AY/Class multi-select chips as Notice, via shared buildPassoutChipsInto/getPassoutFilters
  helpers); student-side banner/broadcast checks now honor passoutAYs/passoutClasses narrowing.
  Removed duplicate Promote&Archive/Archive Attendance buttons from Students tab (Archives tab is the
  single home for both). Banned Students tab: added "🎓 Passed-out (all)" quick filter chip + per-row
  alumni badge showing passoutAY — passout students were already included via STATE.students, now
  they're visibly labeled and filterable as a group. Academic Calendar "not synced yet" confirmed
  correct behavior, not a bug — davan_pub/calendar has no 2026-27 data until pushed from mother app.
VERSION : v6.81 (2026-07-09) — Passout notice targeting: Compose Notice → target "Passed-out Students" now shows
  multi-select chips for Batch (archive AY, e.g. 2025-26) and Class (e.g. 3rd BCA A), built live from
  STATE.students (status:'passout' records keep their class + passoutAY). Leave both blank to notify all
  alumni, or combine batch+class to reach e.g. only 3rd BCA A of the 2025-26 passout batch. Student-side
  renderStudentNotices() filters by n.passoutAYs/n.passoutClasses against studentUser.passoutAY/class.
VERSION : v6.80 (2026-07-09) — archive-view fix: fresh box no longer destroys stu-att-cards/int/rc structure; real data re-shows on AY switch (2026-07-08)

KEY DATA SHAPES (confirmed from live Firebase):
  davan_pub/students        → {data:[{urn, cls, class, subjects:[{subject, ct, ca, pct, enrolled, fine, int1, mc}]}]}
  davan_pub/portal_students → {URN:{urn,name,class,semester,phone,password,...}} — NO subjects field
  controls/lpExceptions     → {SubjectName:true, ...} — keyed by sub.subject (scraper name, may be truncated)
  davan_pub/allocations     → {data:[{code, subject, course, faculty, sem, section, codes:[]}]}
  davan_pub/timetable       → {data:[{class, day, slot, code, ...}]} — class="Davan-BCA-Sem2-SecA"

KEY FUNCTIONS:
  fixSubjectName(raw)    → resolves truncated scraper names via SUBJECT_DISPLAY_FIX table
  _excBuildMap()         → builds exceptions subject map from allStudents (ct>0), uses fixSubjectName
  saveExceptions()       → strips stale lpExceptions keys before writing to Firebase
  excClearStale()        → removes stale entries from STATE.lpExceptions, prompts save
  stuLmCourseInClass()   → alloc course→class matching (handles BCom/B.Com variants)

SUBJECT NAME TRUNCATION (UUCMS cuts long names in scraper):
  Fix table: SUBJECT_DISPLAY_FIX (line ~6663) — add entries here to fix everywhere
  "PHP and"                    → "PHP and MySQL"
  "Artificial Intelligence and" → "Artificial Intelligence and Applications"
  "Data Warehouse and Data"    → "Data Warehousing and Data Mining"

EXCEPTIONS TAB FLOW:
  Source: STATE.allStudents (ct>0) — ground truth
  Course chip filter: cls.split("-")[1] → BCA/BBA/BCOM
  lpExceptions stored as array of raw sub.subject keys
  Stale entries (in Firebase but not in current attendance) shown in amber for cleanup

LOG (newest first):
  v6.76 | 2026-05-16 | FIX: INT 2 score value color changed from green to purple (#c084fc) for passing marks — INT 1 stays green, INT 2 stays purple; warn/danger thresholds unchanged
  v6.75 | 2026-05-16 | FIX: INT 1 card given blue tint (bg + border + label), INT 2 given purple tint — visually distinct even when scores match
  v6.74 | 2026-05-16 | FIX: fetchAdminCalendar() now normalises Firestore fields (from/to/name/type→date/endDate/event/Type) to match what renderCalendarPanel expects — DATE and DAY columns now show correctly. Ticker also uses normalised data.
  v6.73 | 2026-05-16 | FEAT: Ticker built dynamically from STATE.calendarData (future dates only). Hides if nothing upcoming.
  v6.72 | 2026-05-16 | FEAT: Calendar reads directly from admin Firestore (davan-attendance-2026/app_data/academic_calendar) via REST. fetchAdminCalendar() helper; RTDB fallback built-in. Both load paths updated.
  v6.71 | 2026-05-16 | FEAT: IA1 PASS = green (#22c55e), IA2 PASS = cyan (#06b6d4); FAIL stays red. _portalIntCell takes iaIdx param.
  v6.70 | 2026-04-27 | FIX: _excBuildMap uses fixSubjectName(raw) via SUBJECT_DISPLAY_FIX — resolves truncated
           scraper names ("PHP and"→"PHP and MySQL", "Artificial Intelligence and"→"...Applications",
           "Data Warehouse and Data"→"Data Warehousing and Data Mining"). Removed redundant helpers.
  v6.69 | 2026-04-27 | FIX: _excBuildMap reverted to allStudents as ground truth (ct>0, class string split
           for course). alloc used only for display name prefix-lookup. Alloc course field unreliable.
  v6.68 | 2026-04-27 | FEAT: saveExceptions strips stale lpExceptions keys before Firebase write.
           Added "🧹 Clear Stale" amber button. Stale entries (academicYear, endDate, SPORTS etc) cleaned.
  v6.67 | 2026-04-27 | FIX: _excBuildMap source switched to STATE.adminMotherAlloc (davan_pub/allocations)
           same as timetable Faculty A-Z — full subject names. Fallback to allStudents if alloc empty.
  v6.66 | 2026-04-27 | FEAT: _excRender shows stale hidden entries (in lpExceptions but ct=0/not in map)
           at bottom in amber so admin can uncheck and clean up. makeCard helper added.
  v6.65 | 2026-04-27 | FIX: sub.code does not exist in davan_pub/students (confirmed JSON.stringify).
           sub.subject is the only field. _excBuildMap, dashboard filter, attendance filter all updated
           to use s.subject||s.code. lpExceptions now correctly filters student views.
  v6.64 | 2026-04-27 | DEBUG: _excBuildMap expanded console.log — full map codes + sample student
           subjects[0..2] to confirm data shape from live Firebase.
  v6.63 | 2026-04-26 | FIX: loadAllData Promise.all fetch order mismatch — excRaw was receiving
           davan_pub/session_config (keys: academicYear,endDate,holidays,...) instead of
           controls/lpExceptions. Reordered: calRaw=calendar, excRaw=lpExceptions,
           banRaw=bannedStudents, lpKeysRaw=lessonPlan, semCfgRaw=session_config.
  v6.62 | 2026-04-26 | FIX: _excBuildMap course extraction — regex on "Davan-BCA-Sem2-SecA" grabbed
           "DAVAN" not "BCA". Fixed to cls.split("-")[1] when parts[0] matches Davan/Nutana/DI/NU.
           Chip filter case mismatch (Set "BCOM" vs chip "BCom") fixed with .toUpperCase().
           sub.code fallback to sub.subject. Debug console.log added.
  v6.61 | 2026-04-26 | FIX: _excBuildMap read STATE.students (portal_students — no subjects field)
           instead of STATE.allStudents (davan_pub/students — subjects array with ct). Fixed data
           source and renderExceptionsTab guard. Emoji 🔍 fixed (was Python unicode escape).
  v6.60 | 2026-04-26 | FIX: Exceptions tab old section (line 434675) was never removed — new functions
           shadowed by duplicates. Removed old block; single copy of all exc* functions.
  v6.59 | 2026-04-26 | FEAT: Exceptions tab rebuilt from scratch — source: STATE.students attendance
           data only (ct>0). 3 chips: All/BBA/BCA/BCom. Search. Toggle saves to controls/lpExceptions.
  v6.55 | 2026-04-24 | PERF: sessionStorage cache (30-min TTL) — davan_pub/students, controls, notices,
           timetable, lessonPlan, motherTT, allocations, calendar, allocEach. Live data always fresh.
           Cuts Firebase downloads ~80%.
  v6.54 | 2026-04-19 | FEAT: Session config (davan_pub/session_config) loaded; STATE.semConfig +
           STATE.activeSemKey + STATE.isCurrentSem. Subject matching sem-aware. Sem label in sidebar.
  v6.52 | 2026-04-24 | FEAT: renderInternals — colour-coded IA1/IA2 cells; Status column (PASS/FAIL/AB). Pass threshold 11/30.
  v6.52 | 2026-04-17 | FEAT: Dashboard Attendance Summary shows "X / Y classes attended" per subject.
  v6.51 | 2026-04-17 | FEAT: Bell badge unread count; Notices sidebar badge; Admin student card RC tab loads shortage notifications + visit records (Firestore).
  v6.50 | 2026-04-16 | FIX: Admin student card photo — ascLoadPhoto delegates to rcLoadPhoto, correct path davan_student_photos/{urn}.
  v6.49 | 2026-04-16 | FEAT: Students tab class summary cards — logins CREATED vs strength; no-login rows with Create button. Admin Student Card "🎓 Prev Results" tab.
  v6.48 | 2026-04-16 | FEAT: Admin Students tab — class login summary cards; Login Activity tab — per-class unique logins, live 🟢 active count (last 15 min).
  v6.47 | 2026-04-15 | FIX: LP strip missing — added BCA-PY/Py-pro/QC/DWDM/FDS/WCMS/TS/OS&SP/ENG/AI-LAB to LP_CODE_NAMES and STU_KNOWN_NAMES.
  v6.46 | 2026-04-15 | FIX: LP strip missing — filterLPForStudent dropped no-Sec entries; STATE.currentScrapedLP never set; word-overlap fallback added.
  v6.45 | 2026-04-15 | FEAT: Report Card — rcLoadPhoto tries Firebase Storage paths as fallback; tap-to-zoom lightbox.
  v6.38 | 2026-04-14 | FIX: Student photo — handles string URL and object shapes; nameInitials() for "MEGHANA .H.M" style names.
  v6.37 | 2026-04-14 | FIX: QSpider LP card showing despite exception — filterLPForStudent now checks d.faculty against hidden-name regex.
  v6.36 | 2026-04-14 | FIX: "PHP and" truncated — SUBJECT_DISPLAY_FIX + aliases. Screenshot prevention. Celebration banner exception filter. Syllabus QSpider/sports filter. DWDM full name.
  v6.35 | 2026-04-14 | FIX: College/Class/DI rank wrong — computeStudentRanks ports resFixStudentMarks from results.html.
  v6.34 | 2026-04-14 | FIX: Previous Results % and ranks wrong — recompute pct from subject totals (mirrors results.html).
  v6.33 | 2026-04-14 | FEAT: SUBJECT_NAME_ALIASES lookup table — single place for subject name variants between Firebase attendance and motherAllocs.
  v6.30 | 2026-04-14 | FIX: College rank pool = all regular students across all courses+sems. Faculty GST permanent fix via STU_KNOWN_NAMES enrichment.
  v6.29 | 2026-04-14 | FIX: Class rank mirrors results.html — BBA/BCom = college rank pool; BCA splits DI/NU only.
  v6.28 | 2026-04-14 | FIX: Celebration banners in dedicated section; case-insensitive STU_KNOWN_NAMES lookup.
  v6.23 | 2026-04-13 | FIX: Student timetable class match — fall back to no-section when mother TT has section-less class.
  v6.22 | 2026-04-13 | FEAT: Master password, Remember Me, Login Activity tab, LP scraped+topics in admin, exceptions filter, calendar pre-render, import max 999.

────────────────────────────────────────────────────────────────
  FIREBASE CONFIG
────────────────────────────────────────────────────────────────
  apiKey            : AIzaSyBnWSfjilDwri7dBpONF2GwgXDJnc1W--w
  authDomain        : davan-student-portal.firebaseapp.com
  databaseURL       : https://davan-student-portal-default-rtdb.asia-southeast1.firebasedatabase.app
  projectId         : davan-student-portal
  storageBucket     : davan-student-portal.firebasestorage.app
  messagingSenderId : 576227315217
  appId             : 1:576227315217:web:21aa45946504afbeaeebb0

────────────────────────────────────────────────────────────────
  RTDB RULES (current)
────────────────────────────────────────────────────────────────
  davan_pub          : read=true,       write=auth!=null
  davan_users        : read=auth!=null, write=auth!=null
  davan_students     : read=auth!=null, write=auth!=null
  davan_student_photos: read=auth!=null, write=auth!=null
  davan_meta         : read=auth!=null, write=auth!=null
  bulk_mobile        : read=true,       write=auth!=null
  (root)             : read=auth!=null, write=auth!=null
  REQUIRED: Firebase Console → Authentication → Sign-in method → Anonymous → ENABLE

────────────────────────────────────────────────────────────────
  RTDB STRUCTURE
────────────────────────────────────────────────────────────────
  davan_pub/students/{URN}         ← import source (read-only)
    name, class, phone, semester
  davan_pub/portal_students/{URN}  ← portal logins (auth-gated write)
    urn, name, class, semester, password(SHA-256), passwordChanged, lastLogin, importedAt
  controls/global/                 ← feature flags: attendance|internals|semMarks|timetable|lessonPlan
  controls/byClass/ | controls/byUrn/
  notices/ | timetable/ | lessonPlan/

────────────────────────────────────────────────────────────────
  KEY FUNCTIONS
────────────────────────────────────────────────────────────────
  getAuthToken()    — anonymous Firebase sign-in, caches+refreshes ID token
  authSep()         — returns ?auth=<token> for RTDB REST URLs
  rtdbGet/Set/Patch/Delete/Push — all await getAuthToken() before fetch
  loginStudent()    — SHA-256 pwd check against RTDB
  runImport()       — bulk import davan_pub/students → portal_students
  enterAdminDashboard() — admin login success
  doLogout()        — clears session, resets UI

────────────────────────────────────────────────────────────────
  CDN SCRIPTS (added in v2.01, placed before main <script>)
────────────────────────────────────────────────────────────────
  https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js
  https://www.gstatic.com/firebasejs/10.12.0/firebase-auth-compat.js

────────────────────────────────────────────────────────────────
  CHANGELOG v6.22 – v6.52 (see main LOG block above for v6.53+)
────────────────────────────────────────────────────────────────
  v2.01 | 2026-04-11 | FIX: RTDB patch error 401 / Save failed
    Root cause: unauthenticated REST calls; rules require auth!=null
    Fix: added Firebase Auth SDK, getAuthToken() signs in anonymously,
         all rtdb* helpers await token, ?auth=<idToken> on every call

  v2.01 | 2026-04-11 | FIX: Import 0 logins created / 2 failed
    Root cause: rtdbSet inside runImport() hitting same 401
    Fix: resolved by auth fix above

  v2.01 | 2026-04-11 | FIX: Student login broken (URN not found)
    Root cause: students never imported due to above 401 chain
    Fix: resolved by auth + import fix chain

  v2.01 | 2026-04-11 | FEAT: Show phone number in Student Logins table
    Added Phone/Password column to student table (header + row)
    Phone now stored in portal_students payload during import
    Existing students without phone show — until re-imported

  v6.52 | 2026-04-24 | FEAT: renderInternals — colour-coded IA1/IA2 cells: 0-10 red/FAIL, 11-30 green/PASS, AB amber/ABSENT, null grey dash. Per-row left border + Status column (PASS/FAIL pill). Replaced Avg & Progress bar columns with Status. Pass threshold: 11/30.
  v6.52 | 2026-04-17 | FEAT: Dashboard Attendance Summary now shows "X / Y classes attended" below the progress bar for each subject.
  v6.51 | 2026-04-17 | FEAT: Bell badge now shows unread count (numbered pill, not dot); notices pushed to bell on render (deduped by notice key); sidebar 🔔 Notices button shows same unread count badge; badge clears when bell panel or Notices panel is opened; Admin student card RC tab now loads + shows SHORTAGE NOTIFICATIONS SENT and VISIT RECORDS / FOLLOW-UP LOG via rcLoadNotifications (Firestore)
  v6.50 | 2026-04-16 | FIX: Admin student card photo not showing — ascLoadPhoto was reading wrong RTDB path (portal_students/{urn}) instead of davan_student_photos/{urn}; now delegates to rcLoadPhoto, shares cache
  v6.49 | 2026-04-16 | FEAT: Students tab — class summary cards now show portal logins CREATED vs class strength from davan_pub/students (not login count); click any card to see exactly which students have no portal login yet (red "No Login" rows with pre-filled + Create button); click again or ✕ to go back to normal view. STATE.allStudents now persists davan_pub/students across renders.
  v6.48 | 2026-04-16 | FEAT: Admin Students tab — class login summary cards (X/strength logged in, Y still to login, % bar per class + all-classes total); Admin Login Activity tab — class login summary cards (unique logins per class vs class strength), live 🟢 indicator showing how many students are active on app in last 15 min (blinking dot).
  v6.49 | 2026-04-16 | FEAT: Admin Student Card — added "🎓 Prev Results" tab;
          ascRenderPrevResults() calls existing rcLoadPrevResults() and renders
          the same CGPI banner + per-semester subject tables (SGPA, %, result,
          ranks, 100/100 badges, faculty names) as the student-login report card.
  v6.47 | 2026-04-15 | FIX: LP strip missing for Python Programming (Priyanaka V) and Introduction to Quantum Computing (Pooja C) — scraped LP keys BCA-PY/Py-pro/QC/DWDM/FDS/WCMS/TS/OS&SP/ENG/AI-LAB were absent from LP_CODE_NAMES and STU_KNOWN_NAMES; added all newly discovered codes from Firebase lessonPlan key dump
  v6.46 | 2026-04-15 | FIX: LP strip missing for Vijayalakshmi/Karthik and other subjects in timetable — 3 bugs: (1) filterLPForStudent rejected LP keys with no -Sec suffix (applies-to-all-sections entries dropped); (2) STATE.currentScrapedLP never set during student load so getLPForSubject second source was always {}; (3) getLPForSubject had no word-overlap fallback for near-name variants (e.g. "Artificial Intelligence" vs "Artificial Intelligence and Applications"). All three fixed.
  v6.45 | 2026-04-15 | FEAT: Report Card — rcLoadPhoto now tries Firebase Storage paths (.jpg/.jpeg/.png under student_photos/ and photos/) as fallback when RTDB has no URL; topbar + dash photos now tap-to-zoom via rcZoomPhoto lightbox
  v6.38 | 2026-04-14 | FIX: Student photo not showing — rcLoadPhoto now handles both plain string URL and object shapes ({url|photo_url|photoURL|thumb|image}); nameInitials() helper added to fix "M." initials for names like "MEGHANA .H.M"
  v6.37 | 2026-04-14 | FIX: QSpider LP card still showing despite exception list — filterLPForStudent was only checking d.subject_name/full_name/subject against hidden-name regex; QSpider appears as d.faculty="QSpider" (subject code PT), so added d.faculty check to the same regex filter
  v6.36 | 2026-04-14 | FIX 1: "PHP and" subject shown truncated — added SUBJECT_DISPLAY_FIX map + SUBJECT_NAME_ALIASES entry; applied at attendance cards, internals, celebration banners; full name "PHP and MySQL" now shown everywhere
          FIX 2: Screenshot prevention — @media print blanks page; JS blocks PrintScreen/Ctrl+P/right-click contextmenu; full-screen overlay shows 3s on attempt; text-select disabled on att/int/report panels
          FIX 3: Celebration banners showed exception subjects — renderDashAttSummary now filters STATE.lpExceptions; _isCelebExcluded() added to suppress sports/QSpider/NSS/NCC/YRC by name for code-less subjects
          FIX 4: Syllabus tab showed QSpider/sports — filterLPForStudent now checks _LP_HIDDEN_CODES key fragments + _LP_HIDDEN_NAMES regex in addition to admin exceptions list
          FIX 5: Data Warehousing and Data Mining full name shown — added to STU_KNOWN_NAMES (21BCA6C17L, BCADSC-6-2, BCADSC-6-DW) and LP_CODE_NAMES (DW key); PHP and MySQL added under 21BCA6C16L, BCADSC-6-1, PHP key
  v6.35 | 2026-04-14 | FIX: College/Class/DI rank all wrong (#211 vs #26) — computeStudentRanks now ports resFixStudentMarks from results.html: recomputes total/pct/result from split strings before isFullPass filter+sort, so rank pool exactly matches results.html modal
  v6.34 | 2026-04-14 | FIX: Previous Results — percentage and college/DI ranks were wrong (e.g. 47.2% instead of 91.6%, #211 instead of #26) because stored s.pct in Firebase is unreliable (scraper bug). Both rcLoadPrevResults and computeStudentRanks now recompute pct from subject totals (mirrors results.html computeStudentPct), falling back to stored pct only when no subject totals exist
  v6.33 | 2026-04-14 | PERMANENT FIX: Add SUBJECT_NAME_ALIASES lookup table — single place to register subject name variants between Firebase attendance and motherAllocs; wired into both enrichment (aliasSubName) and _resolveFac (aliasN); eliminates need for 3-word prefix hacks going forward
  v6.32 | 2026-04-14 | FIX: GST faculty not shown — enrichment block now uses 3-word prefix match in addition to 4-word, catching "Goods and Service Tax" vs "Goods and Services Tax" singular/plural divergence at 4th word
  v6.31 | 2026-04-14 | FIX: Cultural Diversity faculty not shown — _resolveFac now checks found.facultyDI/found.facultyNU when found.faculty is empty (motherAlloc entries use campus-split fields); added BBADSE-6-HRM2 to STU_KNOWN_NAMES
  v6.30 | 2026-04-14 | FIX 1 (Rank): College rank pool = ALL regular students across ALL courses+sems, no backlog, no sem/course filter — matches results.html. Class rank filters by same course+sem. FIX 2 (Faculty GST — permanent): Enrichment now uses STU_KNOWN_NAMES[code] as resolved name for subject matching (Firebase sub.subject for BBADSC-6-6A may be empty/raw; STU_KNOWN_NAMES has the readable name). Also strips parentheticals (v706), normalizes & → and (v726), 4-word prefix match (v703). FIX 3: Version string updated in all locations.
  v6.29 | 2026-04-14 | FIX: Class rank now mirrors results.html exactly — BBA/BCom = college rank (one combined class, no section split); BCA only splits DI/NU; previous portal was incorrectly using DI-section pool for BBA class rank giving wrong #10 instead of #12
          FIX: Confirmed v6.28 fixes are all present — user was testing v6.27 (pre-fix) based on celebration banner still being inside att summary box
  v6.28 | 2026-04-14 | FIX: Celebration banners in dedicated section above Attendance Summary; case-insensitive STU_KNOWN_NAMES lookup everywhere
  v6.23 | 2026-04-13 | FIX: Student timetable class match — fall back to no-section when section-less class in mother TT (e.g. "III YEAR BBA" vs "III YEAR BBA (A)")
  v6.22 | 2026-04-13 | FEAT: Master password /*-, student Remember Me, Login Activity tab, LP scraped+topics in admin, LP classes fixed, exceptions filter for attendance/internals/reportcard, topbar font fix, calendar pre-render, import max 999
  v6.21 | 2026-04-13 | FIX: Timetable subject+faculty — ported lmBaseCode+lmClassMatch+lmAllocMatchesCode from mother app exactly; strips "ENG(S1)"→"ENG", "DS A1(A)"→"DS", "AM II"→"AM II"; matches by course+sem+section+code against LM_ALLOC_DEFAULT
  v6.21 | 2026-04-13 | FIX: Timetable 3 fixes — NOW badge colon/dot guard; subject name multi-fallback; faculty always shown
  v6.15 | 2026-04-13 | FIX: Timetable NOW badge wrong at midnight — slotStatus() used || 0 fallback so failed parses returned 0, making 0>=0 → current at midnight
  v6.14 | 2026-04-13 | FIX: Dashboard footer now fully visible — replaced <footer> tag with div.portal-footer (escapes hide rule); padding-bottom 80px clears fixed 60px bottom-nav so all 3 footer lines (copyright, version, built-by) are visible
  v6.13 | 2026-04-13 | FIX: Footer added inside .student-main (dashboard scroll area) — now visible on all screens
  v6.11 | 2026-04-13 | FIX: Footer moved inside #screen-login + #screen-student (guaranteed visible); phone stored in STATE at login; standalone footer removed
  v6.09 | 2026-04-13 | FIX: Footer visible on login/student screens (body min-height); topbar row2 shows name·URN·class·sem·phone; dash title name in sky-blue, rest white
  v6.08 | 2026-04-13 | UX: Remove logo box; password hint updated; URN live name preview; topbar row2 shows phone+mini-photo; welcome toast (30 greetings, time-aware, center-screen); dash name in accent colour; footer corrected; v6.07 hamburger fix

  v6.03 | 2026-04-12 | UX: Bottom nav (mobile PWA), two-row topbar (name·URN·version·last scraped), LP count fix (from topics array), stat pills, serial numbers, footer updated

  v6.02 | 2026-04-12 | FIX: LP path now reads davan_pub/lessonPlan (scraped data)

  v6.01 | 2026-04-12 | MERGE: Integrated v5.12 improvements
    NEW: Admin Calendar tab (🗓) with full table, type filters, upcoming banner
    UPD: renderCalendarPanel() — fetches davan_pub/calendar, filter chips, full table
    UPD: loadAllData() — pre-fetches timetable+allocations+calendar; populates tt-class-sel
    UPD: loadTimetable() — uses STATE cache, fallback fetch only if empty
    FIX: Admin TT dropdown now uses STATE.ttClasses (real mother-app class names)
    FIX: renderAdminTT() — exact class match (no fuzzy strip needed)
    UPD: Ticker — updated to May 2026 events
    FIX: Day chip click resets transpose view

  v6.00 | 2026-04-12 | MERGE: Combined other-session changes + restored DB2 fixes
    NEW: Bell notification panel (topbar 🔔 icon, localStorage history, badge dot)
    NEW: Academic Calendar as full student panel (replaces sidebar widget)
    NEW: Admin timetable rewritten — mother-app style, day chips, transpose, print, faculty A-Z
    NEW: Sunday handling in student timetable (shows Monday, no today-chip)
    FIX: DB_URL + FIREBASE_CONFIG restored to DB2 (davan-student-portal)
    FIX: rcLoadPhoto() restored to davan_student_photos/{urn} (correct DB2 path)
    FIX: topbar-scrape-date strip shown in topbar

  v5.08 | 2026-04-12 | FEAT: Previous results per-sem cards in summary stats grid
    Each past semester now gets its own mini-card below the IA row showing:
    SGPA badge (purple), % badge, PASS/FAIL badge (green/red), ✅ pass count, ❌ fail count.
    A thin divider separates current-sem stats from previous-sem cards.
    The old single "Prev Results: N" count card is replaced by this richer set.

  v5.07 | 2026-04-12 | FEAT: Visit Records / Notifications from Firestore
    Root cause: davan_followup_logs + davan_notification_logs are Firestore-only;
                RTDB paths davan_pub/followup_logs + notification_logs do not exist.
    Fix 1: Added firebase-firestore-compat.js CDN script.
    Fix 2: Initialised _db = firebase.firestore() after initializeApp().
    Fix 3: rcLoadNotifications() now reads davan_notification_logs/{urn} and
            davan_followup_logs/{urn} from Firestore (matches mother-app fuLoadAll +
            ntLoadLogs), sorted by meetingDate desc.
    Fix 4: Follow-up render upgraded to full rich card — type badge (parent_visit /
            staff_visit / phone_call / notification / counselling), status badge
            (completed / pending / no_response / follow_up_needed), outcome badge
            (positive / negative / neutral), meetingDate, notes, recordedBy.

────────────────────────────────────────────────────────────────
  HOW TO CONTINUE (for Claude)
────────────────────────────────────────────────────────────────
  1. Read this handoff block first
  2. grep before view, node --check after every JS edit
  3. Fix the described issue — minimal changes only
  4. Update the LOG block at top of handoff with new entry
  5. Deliver updated file
════════════════════════════════════════════════════════════════
```
