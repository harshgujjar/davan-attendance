/**
 * Davan widget release timer - Cloudflare Worker "davan-release" (user, 06-Oct-2026: "set up the Cloudflare worker for the 9:15 pm release").
 * GitHub's own timer started the nightly release hours late or not at all, so this worker starts it on time.
 *
 * What it does
 *  - Every night at 9:15 pm IST (cron 45 15 * * *) and again at 9:45 pm (15 16 * * *, a backup) it starts the GitHub job
 *    .github/workflows/release-widgets.yml in "auto" mode. The job itself decides: it obeys the Super Admin's stop switch
 *    (staff app -> Global Switches -> Widget updates) and releases only ONCE a night, so the backup does nothing extra.
 *  - The staff app's "Release now" button calls this worker's address; it starts the same job in "auto" mode, which releases
 *    only if Release now was really pressed (davan_pub/release_ctl nowReq). Nobody else can force a release through it.
 *
 *  - v4 (user, 11-Oct-2026: "scraper did not run on time - build both fixes, use the same key"): GitHub's timer also started the
 *    college scraper hours late (Sat 10-Oct: the 1 pm run never started). The worker now also starts the PRIVATE repo's job
 *    harshgujjar/davan-scraper .github/workflows/scrape.yml (input timed=yes) at 1:00 pm, 1:45 pm (backup), 5:30 pm and 6:15 pm
 *    (backup) IST, Monday-Saturday. app.py decides the rest (holiday / off Saturday = light run, a slot that already ran is skipped).
 *    The same GH_TOKEN is used: on GitHub its repository access must include davan-scraper too (Actions: read and write).
 *  - v7 (13-Oct-2026): GET /?marks=<exam>&cls=<classes> starts the PUC marks scrape in the cloud (puc-marks.yml) - the PUC app's button.
 *  - v6 (12-Oct-2026, the user's Cloudflare log showed only the two release timers ran): timers are recognised by their minute list,
 *    not by the text "MON-SAT" (the dashboard may store the days as 2-7). Paste this code AND add the two scraper timers (RELEASE-WORKER.md).
 *  - v5 (user, 11-Oct-2026: "puc html also runs a scraper - handle that in auto mode"): the PUC attendance scrape no longer needs
 *    an open puc.html tab. The worker starts davan-scraper .github/workflows/puc-scrape.yml (timed=yes) at the PUC slots
 *    10:34 am, 1:00, 3:18 and 5:34 pm IST and again 30 min later (backup), Monday-Saturday (own cron, PUC_CRON). puc_scrape.py
 *    decides the rest (PUC holiday / exam / Sunday = nothing, a slot that was already scraped is skipped).
 *
 * One-time setup (Cloudflare dashboard, works on the phone) - see RELEASE-WORKER.md in the repo for the steps with pictures-free detail:
 *  1. Workers & Pages -> Create -> Worker -> name it  davan-release  -> Deploy -> Edit code -> paste this file -> Deploy.
 *  2. Settings -> Variables and Secrets -> Add -> type Secret, name GH_TOKEN, value = the GitHub key (Actions: read and write,
 *     only the davan-attendance repository).
 *  3. Settings -> Trigger events -> Add -> Cron triggers:  45 15 * * *   and   15 16 * * *   (Cloudflare times are UTC).
 *  4. Open https://davan-release.<your-subdomain>.workers.dev/ - it must say "ok: key set".
 */
const REPO = 'harshgujjar/davan-attendance';
const WORKFLOW = 'release-widgets.yml';
const SCR_REPO = 'harshgujjar/davan-scraper';
const SCR_WORKFLOW = 'scrape.yml';
const SCR_TIMES = ['07:30', '08:15', '12:00', '12:45'];   // UTC = 1:00 pm, 1:45 pm, 5:30 pm, 6:15 pm IST (the cron fires every 15 min 07-12 UTC)
const SCR_CRON = '0,15,30,45 7,8,12 * * MON-SAT';
// v5: PUC slots 10:34 / 13:00 / 15:18 / 17:34 IST + 30 min backups, in UTC
const PUC_WORKFLOW = 'puc-scrape.yml';
const PUC_TIMES = ['05:04', '05:34', '07:30', '08:00', '09:48', '10:18', '12:04', '12:34'];
const PUC_CRON = '0,4,18,30,34,48 5,7,8,9,10,12 * * MON-SAT';
const GH_HDR = env => ({ 'Authorization': 'Bearer ' + env.GH_TOKEN, 'Accept': 'application/vnd.github+json', 'User-Agent': 'davan-release-worker',
  'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': 'application/json' });

async function startScrape(env, why, wf) {
  if (!env.GH_TOKEN) return { ok: false, msg: 'GH_TOKEN secret is not set' };
  const r = await fetch('https://api.github.com/repos/' + SCR_REPO + '/actions/workflows/' + (wf || SCR_WORKFLOW) + '/dispatches', {
    method: 'POST', headers: GH_HDR(env), body: JSON.stringify({ ref: 'main', inputs: { timed: 'yes' } }),
  });
  return { ok: r.status === 204, msg: r.status === 204 ? (wf || SCR_WORKFLOW) + ' started (' + why + ')' : 'GitHub said ' + r.status + (r.status === 404 ? ' (the key cannot see davan-scraper)' : '') };
}

// v7 (user, 13-Oct-2026: "PUC marks: not daily - by hand when I want, from the app"): GET /?marks=IA%20-%201&cls=2PUC-COM-A,1PUC-COM-B
// starts davan-scraper puc-marks.yml (puc_marks_scrape.py). Only the 6 exam names and the 8 class labels are accepted; the job saves
// to the PUC database and writes its progress to puc_marks_cloud/<AY>/<exam>, which the PUC app shows.
const MARKS_EXAMS = ['IA - 1', 'IA - 2', 'IA - 3', 'IA - 4', 'IA - 5', 'ALL'];
const MARKS_CLASSES = ['2PUC-SCI-A', '2PUC-COM-A', '2PUC-COM-B', '2PUC-COM-C', '1PUC-SCI-A', '1PUC-COM-A', '1PUC-COM-B', '1PUC-COM-C'];
async function startMarks(env, exam, cls) {
  if (!env.GH_TOKEN) return { ok: false, msg: 'GH_TOKEN secret is not set' };
  if (MARKS_EXAMS.indexOf(exam) < 0) return { ok: false, msg: 'unknown exam' };
  const list = String(cls || '').split(',').map(x => x.trim()).filter(x => MARKS_CLASSES.indexOf(x) >= 0);
  const r = await fetch('https://api.github.com/repos/' + SCR_REPO + '/actions/workflows/puc-marks.yml/dispatches', {
    method: 'POST', headers: GH_HDR(env), body: JSON.stringify({ ref: 'main', inputs: { exam, classes: list.join(',') } }),
  });
  return { ok: r.status === 204, msg: r.status === 204 ? 'cloud marks scrape started: ' + exam + ' · ' + (list.length ? list.join(', ') : 'all classes') : 'GitHub said ' + r.status };
}

async function startRelease(env, why) {
  if (!env.GH_TOKEN) return { ok: false, msg: 'GH_TOKEN secret is not set' };
  const r = await fetch('https://api.github.com/repos/' + REPO + '/actions/workflows/' + WORKFLOW + '/dispatches', {
    method: 'POST',
    headers: { 'Authorization': 'Bearer ' + env.GH_TOKEN, 'Accept': 'application/vnd.github+json', 'User-Agent': 'davan-release-worker',
      'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': 'application/json' },
    body: JSON.stringify({ ref: 'main', inputs: { mode: 'auto', why: why } }),
  });
  return { ok: r.status === 204, msg: r.status === 204 ? 'release job started (' + why + ')' : 'GitHub said ' + r.status + ': ' + (await r.text()).slice(0, 200) };
}

// 07-Oct-2026 (user: "upload the widget log immediately when asked"): GET /?log=<code> starts log-request.yml, which puts the code in
// log-req.json; the student widget reads that file every 15 minutes (GitHub, no Firebase cost) and uploads its log.
async function logRequest(env, code) {
  if (!env.GH_TOKEN) return { ok: false, msg: 'GH_TOKEN secret is not set' };
  if (!/^[A-Z0-9-]{4,12}$/.test(code)) return { ok: false, msg: 'not a widget code' };
  const r = await fetch('https://api.github.com/repos/' + REPO + '/actions/workflows/log-request.yml/dispatches', {
    method: 'POST',
    headers: { 'Authorization': 'Bearer ' + env.GH_TOKEN, 'Accept': 'application/vnd.github+json', 'User-Agent': 'davan-release-worker',
      'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': 'application/json' },
    body: JSON.stringify({ ref: 'main', inputs: { code } }),
  });
  return { ok: r.status === 204, msg: r.status === 204 ? 'log request sent for ' + code : 'GitHub said ' + r.status + ': ' + (await r.text()).slice(0, 200) };
}

const CORS = { 'Access-Control-Allow-Origin': '*', 'Content-Type': 'application/json' };

export default {
  // the timers: 9:15 pm IST + 9:45 pm backup (release); v4: SCR_CRON -> the college scraper at SCR_TIMES only; v5: PUC_CRON -> PUC at PUC_TIMES
  async scheduled(event, env, ctx) {
    // v6 (12-Oct-2026: the dashboard can store a timer as "... * * 2-7" instead of "MON-SAT"): the two release timers are recognised by
    // their exact time (minute + hour); every other timer is a scraper timer, and the minute decides which scraper (if any) runs
    const c = String(event.cron || '').trim().replace(/\s+/g, ' ');
    if (/^(45 15|15 16) \* \* \*$/.test(c)) { ctx.waitUntil(startRelease(env, 'Cloudflare timer ' + c)); return; }
    const d = new Date(event.scheduledTime), hm = String(d.getUTCHours()).padStart(2, '0') + ':' + String(d.getUTCMinutes()).padStart(2, '0');
    if (d.getUTCDay() === 0) return;
    const puc = c.split(' ')[0].split(',').indexOf('4') >= 0;   // the PUC timer's minutes are 0,4,18,30,34,48; the college one's 0,15,30,45
    if (puc) { if (PUC_TIMES.indexOf(hm) >= 0) ctx.waitUntil(startScrape(env, 'Cloudflare timer ' + hm + ' UTC', PUC_WORKFLOW)); return; }
    if (SCR_TIMES.indexOf(hm) >= 0) ctx.waitUntil(startScrape(env, 'Cloudflare timer ' + hm + ' UTC'));
  },
  // GET /            -> health check (no release)
  // GET /?now=1      -> "Release now" from the staff app: the job releases only if the Super Admin pressed it
  // GET /?log=CODE   -> a widget log request (log-request.yml -> log-req.json)
  async fetch(request, env) {
    const u = new URL(request.url);
    if (u.searchParams.get('marks')) return new Response(JSON.stringify(await startMarks(env, String(u.searchParams.get('marks')).trim(), u.searchParams.get('cls') || '')), { headers: CORS });
    if (u.searchParams.get('log')) return new Response(JSON.stringify(await logRequest(env, String(u.searchParams.get('log')).trim().toUpperCase())), { headers: CORS });
    if (u.searchParams.get('now') === '1') return new Response(JSON.stringify(await startRelease(env, 'Release now button')), { headers: CORS });
    // 07-Oct-2026 (user: "show whether my new Cloudflare worker is connected"): gh = the GitHub key really opens the release job
    // (one read-only GitHub call); the staff app's Faculty Class Alerts page and Widget updates card show it. crons = its timers.
    let gh = null, ghMsg = '', scr = null, scrMsg = '';
    if (env.GH_TOKEN) try {
      const r = await fetch('https://api.github.com/repos/' + REPO + '/actions/workflows/' + WORKFLOW, { headers: { 'Authorization': 'Bearer ' + env.GH_TOKEN,
        'Accept': 'application/vnd.github+json', 'User-Agent': 'davan-release-worker', 'X-GitHub-Api-Version': '2022-11-28' } });
      gh = r.status === 200; ghMsg = gh ? 'GitHub key works' : 'GitHub said ' + r.status + (r.status === 401 ? ' (key wrong or expired)' : '');
      // v4: can the same key see the scraper job? (scr false = add davan-scraper to the key's repositories on GitHub)
      const r2 = await fetch('https://api.github.com/repos/' + SCR_REPO + '/actions/workflows/' + SCR_WORKFLOW, { headers: GH_HDR(env) });
      scr = r2.status === 200; scrMsg = scr ? 'scraper timer works' : 'GitHub said ' + r2.status + (r2.status === 404 ? ' - add davan-scraper to the key (Actions: read and write)' : '');
    } catch (e) { ghMsg = 'GitHub not reachable: ' + e.message; }
    return new Response(JSON.stringify({ ok: true, msg: env.GH_TOKEN ? 'ok: key set' : 'GH_TOKEN secret is NOT set yet', gh, ghMsg, scr, scrMsg, ver: 7, now: Date.now() }), { headers: CORS });
  },
};
