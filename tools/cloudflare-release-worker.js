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
 *  - v8 (15-Oct-2026): the marks button also takes "Mid Term" (PUC app v5.239).
 *  - v9 (user, 15-Oct-2026: "push notifications to the Super Admin only, laptop from Cloudflare, mobile from the app"): POST /sa = one
 *    Super Admin event (staff login, release, scrape done, job FAILED, sync done, widget check). It is saved to DB2 davan_pub/sa_ev
 *    (+ davan_pub/sa_ev_at = its time; the Super Admin's staff widget reads them) and pushed (via fcm-push) to the laptops in
 *    davan_pub/sa_push (staff app -> ☁️ Cloud alerts -> "This laptop"). Cloud jobs must send {repo, run} = their own running GitHub run,
 *    which is checked with GH_TOKEN, so nobody else can post job alerts. 9:30 pm IST (cron 0,15 16 = 9:30 usage + 9:45 backup release):
 *    DB2 usage of the day as one alert; events older than 30 days are deleted. A timer that cannot start a job sends a red alert.
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

async function startPlacement(env) {
  if (!env.GH_TOKEN) return { ok: false, msg: 'GH_TOKEN secret is not set' };
  const r = await fetch('https://api.github.com/repos/' + SCR_REPO + '/actions/workflows/learn-usage.yml/dispatches', {
    method: 'POST', headers: GH_HDR(env), body: JSON.stringify({ ref: 'main' }),
  });
  return { ok: r.status === 204, msg: r.status === 204 ? 'learn-usage.yml started' : 'GitHub said ' + r.status };
}
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
const MARKS_EXAMS = ['IA - 1', 'IA - 2', 'IA - 3', 'IA - 4', 'IA - 5', 'Mid Term', 'ALL'];   // v8: + Mid Term
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

const CORS = { 'Access-Control-Allow-Origin': '*', 'Content-Type': 'application/json', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type' };

// ── v9: Super Admin alerts ───────────────────────────────────────────────────────────────────────────────────────────────
const DB2 = 'https://davan-student-portal-default-rtdb.asia-southeast1.firebasedatabase.app';
const DB2_KEY = 'AIzaSyBnWSfjilDwri7dBpONF2GwgXDJnc1W--w';   // the apps' public web key (anonymous sign-in, like the release job)
const PUSH_URL = 'https://fcm-push.harshgujjar.workers.dev';
const SA_COLORS = ['green', 'red', 'blue', 'purple', 'amber'];
const ROLE_LABEL = { fulltime: 'Full-Time Faculty', visiting: 'Visiting Faculty', vp: 'Vice Principal', principal: 'Principal', manager: 'Manager',
  admin: 'Admin', warden: 'Hostel Warden', hostel_head: 'Hostel Head', office: 'Office' };
let _tok = '', _tokExp = 0;
async function db2Tok() {
  if (_tok && Date.now() < _tokExp) return _tok;
  const r = await fetch('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + DB2_KEY, { method: 'POST',
    headers: { 'Content-Type': 'application/json' }, body: '{"returnSecureToken":true}' });
  const j = await r.json(); _tok = j.idToken || ''; _tokExp = Date.now() + 50 * 60000; return _tok;
}
async function db2(method, path, body, q) {
  const t = await db2Tok();
  const r = await fetch(DB2 + '/' + path + '.json?auth=' + t + (q ? '&' + q : ''), { method, headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body) });
  return r.ok ? r.json() : null;
}
const clip = (x, n) => String(x == null ? '' : x).slice(0, n);
const stampIST = ms => new Date(ms).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', day: 'numeric', month: 'short', year: 'numeric',
  hour: 'numeric', minute: '2-digit', hour12: true }).replace(',', ' ·').replace(/\s?(am|pm)$/i, m => ' ' + m.trim().toLowerCase());
const istDate = ms => new Date(ms + 5.5 * 3600000).toISOString().slice(0, 10);

/** Saves one event to DB2 (the phone app reads it) and pushes it to the Super Admin's laptops. */
async function saEvent(ev) {
  const at = Date.now(), color = SA_COLORS.indexOf(ev.color) >= 0 ? ev.color : 'green';
  const e = { at, kind: clip(ev.kind || 'job', 20), color, title: clip(ev.title, 120), body: clip(ev.body, 500), by: clip(ev.by, 60), link: clip(ev.link, 200), who: clip(ev.who, 60) };
  const key = 'e' + at + String(Math.floor(Math.random() * 90) + 10);
  await db2('PUT', 'davan_pub/sa_ev/' + key, e);
  await db2('PUT', 'davan_pub/sa_ev_at', at);
  const subs = (await db2('GET', 'davan_pub/sa_push')) || {};
  const list = Object.entries(subs).filter(([, s]) => s && s.endpoint && s.keys);
  const res = { ok: true, key, subs: list.length, sent: 0, failed: 0 };
  if (list.length) try {
    const r = await fetch(PUSH_URL, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({
      title: e.title, body: (e.body ? e.body + '\n' : '') + stampIST(at) + (e.by ? ' · ' + e.by : ''),
      subscriptions: list.map(([, s]) => ({ endpoint: s.endpoint, keys: s.keys })), tag: 'sa-' + color + '-' + key }) });
    const j = await r.json().catch(() => ({}));
    res.sent = j.sent || 0; res.failed = j.failed || 0;
    // a laptop whose browser dropped the subscription (404 / 410) is removed; other failures are kept for the next alert
    const fs = j.failedSids || [], er = j.errors || [];
    for (let i = 0; i < fs.length; i++) if (/Push failed (404|410)/.test(er[i] || '')) {
      const hit = list.find(([, s]) => s.endpoint === fs[i]); if (hit) await db2('DELETE', 'davan_pub/sa_push/' + hit[0]);
    }
  } catch (x) { res.pushErr = String(x.message || x); }
  return res;
}
/** POST /sa from the staff app (login, test) or a cloud job (must name its own running GitHub run). */
async function saIncoming(env, b) {
  b = b || {};
  if (b.kind === 'login') {
    const name = clip(b.name, 60).trim(); if (!name) return { ok: false, msg: 'no name' };
    return saEvent({ kind: 'login', color: 'blue', who: name, title: '🔑 ' + name + ' logged in', body: (ROLE_LABEL[b.role] || clip(b.role, 30)) + (b.how ? ' · ' + clip(b.how, 40) : ''), by: 'staff app' });
  }
  if (b.kind === 'test') return saEvent({ kind: 'test', color: b.color, title: '🧪 Test alert (' + (SA_COLORS.indexOf(b.color) >= 0 ? b.color : 'green') + ')',
    body: 'Super Admin alerts work on this device.', by: 'staff app' });
  const repo = [REPO, SCR_REPO].indexOf(b.repo) >= 0 ? b.repo : '', run = String(b.run || '').replace(/\D/g, '');
  if (!repo || !run || !env.GH_TOKEN) return { ok: false, msg: 'a job alert needs repo + run' };
  const r = await fetch('https://api.github.com/repos/' + repo + '/actions/runs/' + run, { headers: GH_HDR(env) });
  if (r.status !== 200) return { ok: false, msg: 'run not found (' + r.status + ')' };
  const g = await r.json(), age = Date.now() - Date.parse(g.created_at || 0), upd = Date.now() - Date.parse(g.updated_at || 0);
  if (!(age < 12 * 3600000 && (g.status !== 'completed' || upd < 15 * 60000))) return { ok: false, msg: 'run is not running' };
  return saEvent({ kind: b.kind || 'job', color: b.color || (b.ok === false ? 'red' : 'green'), title: b.title || (g.name + (b.ok === false ? ' FAILED' : ' done')),
    body: b.body, by: b.by || 'cloud',
    // v1914 (user, 19-Oct: "it should take us to the right place, not just a web page"): a job may name a staff-app page (?go=<panel>)
    link: /^https:\/\/harshgujjar\.github\.io\/davan-attendance\//.test(String(b.link || '')) ? b.link : g.html_url });
}
/** 9:30 pm IST: the day's DB2 download (staff app meter numbers) as one alert; old events deleted. */
async function saUsage() {
  const now = Date.now(), d = istDate(now);
  const t = (await db2('GET', 'davan_pub/meter_t/' + d)) || {}, cfg = (await db2('GET', 'davan_pub/meter_cfg')) || {};
  const budget = +cfg.budgetMB || 300, parts = Object.entries(t).filter(([, v]) => typeof v === 'number').sort((a, b) => b[1] - a[1]);
  const mb = parts.reduce((n, [, v]) => n + v, 0) / 1e6, pct = Math.round(mb / budget * 100);
  await saEvent({ kind: 'usage', color: pct > 100 ? 'red' : pct >= 80 ? 'amber' : 'green', title: '📊 DB2 today: ' + mb.toFixed(0) + ' MB of ' + budget + ' MB (' + pct + '%)',
    body: parts.slice(0, 4).map(([a, v]) => a + ' ' + (v / 1e6).toFixed(0) + ' MB').join(' · ') || 'no numbers yet', by: 'Cloudflare 9:30 pm' });
  const old = await db2('GET', 'davan_pub/sa_ev', undefined, 'orderBy=%22%24key%22&endAt=%22e' + (now - 30 * 86400000) + '%22');
  if (old && Object.keys(old).length) { const z = {}; for (const k of Object.keys(old)) z[k] = null; await db2('PATCH', 'davan_pub/sa_ev', z); }
}
/** A timer that could not start its job tells the Super Admin at once. */
async function startOrAlert(p, what) {
  const r = await p;
  if (!r.ok) await saEvent({ kind: 'fail', color: 'red', title: '❌ ' + what + ' did not start', body: r.msg, by: 'Cloudflare timer' });
  return r;
}

export default {
  // the timers: 9:15 pm IST + 9:45 pm backup (release); v4: SCR_CRON -> the college scraper at SCR_TIMES only; v5: PUC_CRON -> PUC at PUC_TIMES
  async scheduled(event, env, ctx) {
    // v6 (12-Oct-2026: the dashboard can store a timer as "... * * 2-7" instead of "MON-SAT"): the two release timers are recognised by
    // their exact time (minute + hour); every other timer is a scraper timer, and the minute decides which scraper (if any) runs
    const c = String(event.cron || '').trim().replace(/\s+/g, ' ');
    const d = new Date(event.scheduledTime), hm = String(d.getUTCHours()).padStart(2, '0') + ':' + String(d.getUTCMinutes()).padStart(2, '0');
    // v9: the old backup timer "15 16" became "0,15 16": 16:00 UTC = 9:30 pm IST usage alert, 16:15 = the 9:45 pm backup release
    if (/^(45 15|15 16|0,15 16) \* \* \*$/.test(c)) {
      if (hm === '16:00') { ctx.waitUntil(saUsage()); return; }
      ctx.waitUntil(startOrAlert(startRelease(env, 'Cloudflare timer ' + (hm === '15:45' ? '45 15' : '15 16')), 'The 9:15 pm widget release')); return;
    }
    // v10 (user, 19-Oct-2026): the 3 daily timers became ONE (the free plan allows 5 timers in all): "0,5,15,45 12,15,16 * * *"; only these
    // times do anything: 12:05 UTC = 6:05 pm IST Placement usage alert (davan-scraper learn-usage.yml), 15:45 = 9:15 pm release,
    // 16:00 = 9:30 pm usage alert, 16:15 = 9:45 pm backup release; the other minutes of the cross product (12:00 / 12:15 / 12:45 ...) are ignored
    if (c === '0,5,15,45 12,15,16 * * *') {
      if (hm === '12:05') ctx.waitUntil(startOrAlert(startPlacement(env), 'The 6:05 pm Placement usage'));
      else if (hm === '16:00') ctx.waitUntil(saUsage());
      else if (hm === '15:45' || hm === '16:15') ctx.waitUntil(startOrAlert(startRelease(env, 'Cloudflare timer ' + (hm === '15:45' ? '45 15' : '15 16')), 'The 9:15 pm widget release'));
      return;
    }
    if (d.getUTCDay() === 0) return;
    const puc = c.split(' ')[0].split(',').indexOf('4') >= 0;   // the PUC timer's minutes are 0,4,18,30,34,48; the college one's 0,15,30,45
    if (puc) { if (PUC_TIMES.indexOf(hm) >= 0) ctx.waitUntil(startOrAlert(startScrape(env, 'Cloudflare timer ' + hm + ' UTC', PUC_WORKFLOW), 'The PUC scrape')); return; }
    if (SCR_TIMES.indexOf(hm) >= 0) ctx.waitUntil(startOrAlert(startScrape(env, 'Cloudflare timer ' + hm + ' UTC'), 'The college scrape'));
  },
  // GET /            -> health check (no release)
  // GET /?now=1      -> "Release now" from the staff app: the job releases only if the Super Admin pressed it
  // GET /?log=CODE   -> a widget log request (log-request.yml -> log-req.json)
  async fetch(request, env) {
    const u = new URL(request.url);
    if (request.method === 'OPTIONS') return new Response('', { headers: CORS });
    if (request.method === 'POST' && u.pathname === '/sa') {   // v9: Super Admin alert
      let b = {}; try { b = JSON.parse(await request.text()); } catch (e) {}
      let r; try { r = await saIncoming(env, b); } catch (e) { r = { ok: false, msg: String(e.message || e) }; }
      return new Response(JSON.stringify(r), { headers: CORS });
    }
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
    return new Response(JSON.stringify({ ok: true, msg: env.GH_TOKEN ? 'ok: key set' : 'GH_TOKEN secret is NOT set yet', gh, ghMsg, scr, scrMsg, ver: 9, sa: true, now: Date.now() }), { headers: CORS });
  },
};
