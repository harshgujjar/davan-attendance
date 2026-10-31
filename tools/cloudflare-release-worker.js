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
 *  - v14 (23-Oct-2026): POST /ai also answers widgets for ONE task (fb_reply), checked by the widget code.
 *  - v13 (23-Oct-2026): Sunday 🤖 coach notes for Placement learners with Ready 70+ (coachRun -> DB4 learn/coach).
 *  - v11 (23-Oct-2026): POST /ai - AI for the staff app (Workers AI binding AI; Gemini / a 2nd account later), daily limits in DB2.
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
// v10 (user, 21-Oct-2026): starts davan-scraper ig-posts.yml (Instagram numbers + the Super Admin's commands). The job is cheap and its own
// concurrency group queues double starts; this also refuses a second start within 45 s.
let _igLast = 0;
async function startIg(env) {
  if (!env.GH_TOKEN) return { ok: false, msg: 'GH_TOKEN secret is not set' };
  if (Date.now() - _igLast < 45000) return { ok: true, msg: 'already started a moment ago' };
  _igLast = Date.now();
  const r = await fetch('https://api.github.com/repos/' + SCR_REPO + '/actions/workflows/ig-posts.yml/dispatches', { method: 'POST', headers: GH_HDR(env), body: JSON.stringify({ ref: 'main' }) });
  return { ok: r.status === 204, msg: r.status === 204 ? 'ig-posts.yml started' : 'GitHub said ' + r.status };
}
// v16 (user, 31-Oct-2026: "new post is on Instagram but not showing"): GitHub ran the hourly ig-posts.yml only ~3 times a day, so a new post
// waited up to 7 h. The worker's own timer IG_CRON now starts it every hour, 5:35 am - 11:35 pm IST (00:05-18:05 UTC); GitHub's own
// schedule stays as a backup (the job's concurrency group queues a double start). A failed start alerts the Super Admin once a day only.
const IG_CRON = '5 0-18 * * *';
let _igAlertDay = '';
async function igTimer(env) {
  const r = await startIg(env), day = new Date().toISOString().slice(0, 10);
  if (!r.ok && _igAlertDay !== day) { _igAlertDay = day; await saEvent({ kind: 'fail', color: 'red', title: '❌ The hourly Instagram job did not start', body: r.msg, by: 'Cloudflare timer' }); }
  return r;
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


// ── v11 (user, 23-Oct-2026: "go AI - when the day's AI is used up we stop for that day; later more accounts, maybe Gemini") ─────────
// POST /ai {token, task, prompt, system?, max?}  ->  {ok, text, provider, left, msg}
// - Who: a logged-in staff member of the staff app (Firebase email/password ID token of davan-attendance-2026, checked here with
//   Google's public keys). Students / widgets come later (their own check).
// - Providers in order (PROVIDERS): 'cf' = this account's Workers AI (binding AI, free daily allowance), 'gemini' = Google Gemini
//   (secret GEMINI_KEY, only when set), 'cf2' = a second Cloudflare account over its REST API (secrets CF2_ACCOUNT + CF2_TOKEN, only
//   when set). A provider that fails with a limit / quota answer is marked "out" for the rest of the IST day and the next one is tried.
//   When all are out: "AI is resting - back tomorrow".
// - Limits + meter: DB2 davan_pub/ai_cfg {on (default true), max (calls a day, default 300), perUser (default 60)};
//   davan_pub/ai_use/<IST date> {n, out:{provider:true}, u:{uid:n}, p:{provider:n}}. 2 tiny DB2 reads + 1 write per call.
// v12 (23-Oct-2026: Cloudflare retired llama-3.1-8b-instruct on 30-May-2026): models tried in order; DB2 davan_pub/ai_cfg.model (set on the
// staff app's AI page) goes first, so a future retirement needs no new deploy.
const AI_MODELS = ['@cf/zai-org/glm-4.7-flash', '@cf/meta/llama-3.1-8b-instruct-fast'];
const AI_MODEL = AI_MODELS[1];   // the 2nd Cloudflare account / REST path
const STAFF_PROJECT = 'davan-attendance-2026';
let _jwk = null, _jwkAt = 0;
const b64u = x => Uint8Array.from(atob(x.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((x.length + 3) % 4)), ch => ch.charCodeAt(0));
async function staffFromToken(tok) {
  const p = String(tok || '').split('.'); if (p.length !== 3) return null;
  const head = JSON.parse(new TextDecoder().decode(b64u(p[0]))), body = JSON.parse(new TextDecoder().decode(b64u(p[1])));
  if (!_jwk || Date.now() - _jwkAt > 6 * 3600000) {
    const r = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'); _jwk = (await r.json()).keys || []; _jwkAt = Date.now(); }
  const k = _jwk.find(x => x.kid === head.kid); if (!k) return null;
  const key = await crypto.subtle.importKey('jwk', k, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64u(p[2]), new TextEncoder().encode(p[0] + '.' + p[1]));
  const now = Date.now() / 1000;
  if (!ok || body.aud !== STAFF_PROJECT || body.iss !== 'https://securetoken.google.com/' + STAFF_PROJECT || body.exp < now || !body.sub) return null;
  if ((body.firebase || {}).sign_in_provider !== 'password') return null;   // staff logins only (never an anonymous token)
  return { uid: body.sub, email: body.email || '' };
}
function aiProviders(env) {
  const l = [];
  if (env.AI) l.push('cf');
  if (env.GEMINI_KEY) l.push('gemini');
  if (env.CF2_ACCOUNT && env.CF2_TOKEN) l.push('cf2');
  return l;
}
const isLimit = (status, txt) => status === 429 || /quota|limit|exceed|neuron|allocation|exhaust|RESOURCE_EXHAUSTED/i.test(String(txt || ''));
const aiText = r => { if (!r) return ''; if (typeof r.response === 'string') return r.response;
  const c = r.choices && r.choices[0] && r.choices[0].message; if (c && typeof c.content === 'string') return c.content;
  return r.result ? aiText(r.result) : ''; };
async function aiCall(env, prov, messages, max, cfgModel) {
  if (prov === 'cf') {
    const errs = [], list = [cfgModel, ...AI_MODELS].filter((m, i, a) => m && a.indexOf(m) === i);
    for (const model of list) {
      try { const r = await env.AI.run(model, { messages, max_tokens: model.includes('glm') ? max + 1200 : max });   // glm thinks first - room for the answer
        const t = String(aiText(r) || '').replace(/<think>[\s\S]*?<\/think>/g, '').trim(); if (t) return { text: t, model }; errs.push(model + ': empty answer');
      } catch (e) { const m = String(e.message || e); if (isLimit(0, m) && !/deprecat/i.test(m)) return { err: m, limit: true }; errs.push(model + ': ' + m.slice(0, 120)); }
    }
    return { err: errs.join(' / ') };
  }
  if (prov === 'cf2') {
    const r = await fetch('https://api.cloudflare.com/client/v4/accounts/' + env.CF2_ACCOUNT + '/ai/run/' + AI_MODEL, { method: 'POST',
      headers: { Authorization: 'Bearer ' + env.CF2_TOKEN, 'Content-Type': 'application/json' }, body: JSON.stringify({ messages, max_tokens: max }) });
    const t = await r.text(); if (!r.ok) return { err: 'cf2 ' + r.status + ' ' + t.slice(0, 200), limit: isLimit(r.status, t) };
    try { return { text: String(JSON.parse(t).result.response || '').trim() }; } catch (e) { return { err: 'cf2 answer not readable' }; }
  }
  if (prov === 'gemini') {
    const sys = messages.filter(m => m.role === 'system').map(m => m.content).join('\n');
    const contents = messages.filter(m => m.role !== 'system').map(m => ({ role: m.role === 'assistant' ? 'model' : 'user', parts: [{ text: m.content }] }));
    const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models/' + (env.GEMINI_MODEL || 'gemini-2.5-flash') + ':generateContent?key=' + env.GEMINI_KEY, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents, systemInstruction: sys ? { parts: [{ text: sys }] } : undefined, generationConfig: { maxOutputTokens: max } }) });
    const t = await r.text(); if (!r.ok) return { err: 'gemini ' + r.status + ' ' + t.slice(0, 200), limit: isLimit(r.status, t) };
    try { return { text: (JSON.parse(t).candidates[0].content.parts || []).map(x => x.text || '').join('').trim() }; } catch (e) { return { err: 'gemini answer not readable' }; }
  }
  return { err: 'unknown provider ' + prov };
}
async function aiIncoming(env, b) {
  let who = await staffFromToken(b.token).catch(() => null);
  // v14 (user, 23-Oct-2026 - S4 leftovers): a widget (student or staff) may ask for ONE kind of answer - the short reply to its Placement
  // feedback words (task fb_reply). Checked by its widget code: DB2 davan_pub/student_widget_active/<code> must exist. The system prompt and
  // the length are set HERE, never by the phone.
  let widget = false;
  if (!who && b.code && b.task === 'fb_reply') {
    const code = String(b.code).trim().toUpperCase();
    if (/^[A-Z0-9-]{4,12}$/.test(code) && await db2('GET', 'davan_pub/student_widget_active/' + code, undefined, 'shallow=true')) { who = { uid: 'w_' + code }; widget = true; }
  }
  if (!who) return { ok: false, msg: 'Please log in to the staff app again.' };
  if (widget) { b.system = 'You are the friendly placement coach of Davan College, Davangere. A student wrote feedback about the Placement training in the college app. Reply in ONE or TWO short sentences of simple English: thank them for their words, answer their point kindly and give one small practical tip if it fits. Never promise anything on behalf of the college, never invent facts, no lists.'; b.max = 160; }
  const prompt = clip(b.prompt, 4000).trim(); if (!prompt) return { ok: false, msg: 'Nothing to ask.' };
  const day = istDate(Date.now()), cfg = (await db2('GET', 'davan_pub/ai_cfg')) || {}, use = (await db2('GET', 'davan_pub/ai_use/' + day)) || {};
  if (cfg.on === false) return { ok: false, msg: 'AI is switched off (Super Admin).' };
  const max = +cfg.max || 300, per = +cfg.perUser || 60, mine = ((use.u || {})[who.uid]) || 0, out = use.out || {};
  if ((use.n || 0) >= max) return { ok: false, msg: 'Today\'s AI limit (' + max + ') is used up - back tomorrow.', left: 0 };
  if (mine >= per) return { ok: false, msg: 'You used your ' + per + ' AI answers for today - back tomorrow.', left: 0 };
  const messages = [{ role: 'system', content: clip(b.system, 12000) || 'You are a helpful assistant for Davan College, Davangere (India). Answer clearly and briefly in simple English.' },
    { role: 'user', content: prompt }];
  const mx = Math.min(Math.max(+b.max || 400, 50), 1200), tried = [];
  for (const prov of aiProviders(env)) {
    if (out[prov]) continue;
    const r = await aiCall(env, prov, messages, mx, cfg.model).catch(e => ({ err: String(e.message || e) }));
    if (r.text) {
      const patch = { n: (use.n || 0) + 1, ['u/' + who.uid]: mine + 1, ['p/' + prov]: (((use.p || {})[prov]) || 0) + 1, last: Date.now() };
      await db2('PATCH', 'davan_pub/ai_use/' + day, patch);
      return { ok: true, text: r.text, provider: prov + (r.model ? ' · ' + r.model.split('/').pop() : ''), left: Math.max(0, Math.min(max - patch.n, per - mine - 1)) };
    }
    tried.push(prov + ': ' + clip(r.err, 160));
    if (r.limit) await db2('PATCH', 'davan_pub/ai_use/' + day + '/out', { [prov]: true });   // used up for today -> next provider
  }
  const rest = Object.keys(out).length || tried.some(t => isLimit(0, t) && !/deprecat/i.test(t));
  return { ok: false, msg: (rest ? 'AI is resting - back tomorrow.' : 'AI error - not a daily limit, the AI will be fixed.') + (tried.length ? ' (' + tried.join(' | ') + ')' : '') };
}

// v13 (user, 23-Oct-2026: "build the report card next"): 🤖 coach notes - every Sunday the worker writes a short personal note for each
// Placement learner with Ready 70+ (DB4 learn/coach/<ID> {at, text}); the report card (widgets PlcRep, learn/placement.js repV) shows it.
// Runs Sunday 12:15 / 12:45 / 15:00 / 15:15 UTC (5:45 / 6:15 / 8:30 / 8:45 pm IST), max 12 learners a run (free plan: 50 sub-requests),
// only learners whose note is older than 5 days -> at most ~48 notes a week. DB4 address + key come from learn/bank.json (db), so a DB move needs no deploy.
const BANK_URL = 'https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/learn/bank.json';
async function coachRun(env) {
  if (!env.AI) return;
  const bank = await (await fetch(BANK_URL + '?t=' + Date.now())).json(), db = bank.db || {};
  const tk = (await (await fetch('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + db.key, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"returnSecureToken":true}' })).json()).idToken;
  const u = p => db.url + '/' + db.root + '/' + p + '.json?auth=' + tk;
  const prog = (await (await fetch(u('prog'))).json()) || {}, done = (await (await fetch(u('coach') + '&shallow=false')).json()) || {};
  const tn = { quant: 'Quant', reason: 'Reasoning', verbal: 'Verbal', english: 'English', bca: 'BCA Technical', bba: 'BBA Technical', bcom: 'BCom Technical', japanese: 'Japanese' };
  const due = Object.entries(prog).filter(([id, p]) => p && (p.rs || 0) >= 70 && !(done[id] && Date.now() - (done[id].at || 0) < 5 * 864e5)).sort((a, b) => (b[1].rs || 0) - (a[1].rs || 0)).slice(0, 12);
  let n = 0;
  for (const [id, p] of due) {
    try {
      const lg = Object.values((await (await fetch(u('log/' + id) + '&orderBy=%22$key%22&limitToLast=200')).json()) || {});
      const byT = {}; lg.forEach(x => { const k = (x.tr || '?') + (x.l ? ' L' + x.l : ''); byT[k] = byT[k] || [0, 0]; byT[k][0] += x.s || 0; byT[k][1] += x.of || 0; });
      const weak = Object.entries(byT).filter(([, v]) => v[1] >= 5).map(([k, v]) => [k, Math.round(v[0] * 100 / v[1])]).sort((a, b) => a[1] - b[1]).slice(0, 4);
      const hours = {}; lg.forEach(x => { const h = new Date(x.t + 5.5 * 3600e3).getUTCHours(); if (x.of) { hours[h] = hours[h] || [0, 0]; hours[h][0] += x.s || 0; hours[h][1] += x.of; } });
      const bestH = Object.entries(hours).filter(([, v]) => v[1] >= 10).sort((a, b) => b[1][0] / b[1][1] - a[1][0] / a[1][1])[0];
      const facts = ['Name: ' + (p.n || ''), 'Ready score: ' + p.rs + '/100', 'XP ' + (p.xp || 0) + ', days practised ' + (p.d || 0) + ', streak ' + (p.st || 0),
        'Levels: ' + Object.entries(p.lv || {}).map(([t, l]) => (tn[t] || t) + ' ' + l).join(', '),
        'Mock tests (best %): ' + (Object.entries(p.mk || {}).map(([m, v]) => m + ' ' + v).join(', ') || 'none yet'),
        'Weakest areas in the last answers (% right): ' + (weak.map(([k, v]) => k + ' ' + v + '%').join(', ') || 'not enough answers'),
        bestH ? 'Best time of day: around ' + bestH[0] + ':00 (' + Math.round(bestH[1][0] * 100 / bestH[1][1]) + '% right)' : ''].filter(Boolean).join('\n');
      const r = await env.AI.run(AI_MODELS[0], { max_tokens: 1400, messages: [
        { role: 'system', content: 'You are a friendly placement coach at Davan College, Davangere. Write ONE short note (3 to 4 sentences, simple English, speak to the student as "you", first name only) from the facts given: one thing they do well, the one area to work on next with a concrete step, and one tip (e.g. their best time of day). Use only the facts; never invent numbers. No lists, no headings.' },
        { role: 'user', content: facts }] });
      const text = String(aiText(r) || '').replace(/<think>[\s\S]*?<\/think>/g, '').trim().slice(0, 900);
      if (!text) continue;
      await fetch(u('coach/' + id), { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ at: Date.now(), text }) }); n++;
    } catch (e) { if (isLimit(0, String(e.message || e))) break; }
  }
  if (n) { const day = istDate(Date.now()), use = (await db2('GET', 'davan_pub/ai_use/' + day)) || {}; await db2('PATCH', 'davan_pub/ai_use/' + day, { n: (use.n || 0) + n, 'p/coach': (((use.p || {}).coach) || 0) + n }); }
}

// v15 (user, 31-Oct-2026: "add AI paragraph with ✨ in the gold / silver analysis"): after the news job (fetch_news v1.9.0) writes the numbers to DB3
// widgetConfig/newsSourceConfig/ratesInsight, the worker writes ONE short paragraph about them to .../ratesInsight/ai {k, d, text, prov, at}; rates.html shows it
// under "✨ AI · College AI" only when ai.k matches (the news job drops `ai` each time the rates change). Runs on the existing daily timer at 12:15 / 12:45 / 15:00 UTC
// (5:45 / 6:15 / 8:30 pm IST, not Sunday), once per rate change. Same limits and providers as /ai (DB2 davan_pub/ai_cfg + ai_use); a failure writes nothing and the page simply has no paragraph.
const DB3 = 'https://davan-student-news-default-rtdb.asia-southeast1.firebasedatabase.app';
async function ratesAiRun(env) {
  const I = await (await fetch(DB3 + '/widgetConfig/newsSourceConfig/ratesInsight.json?t=' + Date.now())).json().catch(() => null);
  if (!I || !I.silver || !I.k || (I.ai && I.ai.k === I.k)) return;
  const day = istDate(Date.now()), cfg = (await db2('GET', 'davan_pub/ai_cfg')) || {}, use = (await db2('GET', 'davan_pub/ai_use/' + day)) || {}, out = use.out || {};
  if (cfg.on === false || (use.n || 0) >= (+cfg.max || 300)) return;
  const R = n => '₹' + Math.round(Math.abs(n)).toLocaleString('en-IN');
  const ch = (o, w) => o && typeof o.d === 'number' ? w + ' ' + (o.d < 0 ? 'down ' : 'up ') + R(o.d) + ' (' + Math.abs(o.p) + '%)' : '';
  const line = (A, nm, u) => !A ? '' : nm + ' per ' + u + ': ' + R(A.cur) + '; ' + [ch(A.ch.day, 'since yesterday'), ch(A.ch.week, 'this week'), ch(A.ch.month, 'this month')].filter(Boolean).join(', ') +
    '; highest of the year ' + R(A.hi.v) + ', lowest ' + R(A.lo.v) + '; buy zone up to ' + R(A.buyBelow) + ', sell zone from ' + R(A.sellFrom) + '; app signal: ' + A.verdict + '.';
  const prompt = ['IBJA rates of ' + I.asOf + ' (before 3% GST and making):', line(I.silver, 'Silver', 'kg'), line(I.gold24, 'Gold 24K', '10 g'), line(I.gold22, 'Gold 22K', '10 g')].filter(Boolean).join('\n');
  const messages = [{ role: 'system', content: 'You write for the students and staff of Davan College, Davangere (India). Using ONLY the numbers given, write ONE paragraph of 70 to 90 words in simple English: what silver and gold did (use rupee amounts and %), whether it looks sensible to start buying in small parts or to wait, and when to think about selling a part. No markdown, no emoji, no promises about the future. End with: General guidance, not financial advice.' }, { role: 'user', content: prompt }];
  for (const prov of aiProviders(env)) {
    if (out[prov]) continue;
    const r = await aiCall(env, prov, messages, 300, cfg.model).catch(e => ({ err: String(e.message || e) }));
    if (r.text) {
      const text = String(r.text).replace(/[*_#`]/g, '').replace(/\s+/g, ' ').trim().slice(0, 900);
      if (text.length < 40) return;
      await fetch(DB3 + '/widgetConfig/newsSourceConfig/ratesInsight/ai.json', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ k: I.k, d: I.asOf, text, prov: prov + (r.model ? ' · ' + r.model.split('/').pop() : ''), at: new Date().toISOString() }) });
      await db2('PATCH', 'davan_pub/ai_use/' + day, { n: (use.n || 0) + 1, ['u/rates']: (((use.u || {}).rates) || 0) + 1, ['p/' + prov]: (((use.p || {})[prov]) || 0) + 1, last: Date.now() });
      return;
    }
    if (r.limit) await db2('PATCH', 'davan_pub/ai_use/' + day + '/out', { [prov]: true });
  }
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
      else if (d.getUTCDay() === 0 && ['12:15', '12:45', '15:00', '15:15'].includes(hm)) ctx.waitUntil(coachRun(env).catch(() => {}));   // v13: Sunday coach notes
      else if (d.getUTCDay() !== 0 && ['12:15', '12:45', '15:00'].includes(hm)) ctx.waitUntil(ratesAiRun(env).catch(() => {}));   // v15: ✨ gold / silver paragraph
      else if (hm === '16:00') ctx.waitUntil(saUsage());
      else if (hm === '15:45' || hm === '16:15') ctx.waitUntil(startOrAlert(startRelease(env, 'Cloudflare timer ' + (hm === '15:45' ? '45 15' : '15 16')), 'The 9:15 pm widget release'));
      return;
    }
    if (c === IG_CRON) { ctx.waitUntil(igTimer(env).catch(() => {})); return; }   // v16: hourly Instagram, every day incl. Sunday
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
    if (request.method === 'POST' && u.pathname === '/ai') {   // v11: AI for the staff app (Super Admin test box first)
      let b = {}; try { b = JSON.parse(await request.text()); } catch (e) {}
      let r; try { r = await aiIncoming(env, b); } catch (e) { r = { ok: false, msg: 'AI error: ' + String(e.message || e) }; }
      return new Response(JSON.stringify(r), { headers: CORS });
    }
    if (u.searchParams.get('marks')) return new Response(JSON.stringify(await startMarks(env, String(u.searchParams.get('marks')).trim(), u.searchParams.get('cls') || '')), { headers: CORS });
    if (u.searchParams.get('log')) return new Response(JSON.stringify(await logRequest(env, String(u.searchParams.get('log')).trim().toUpperCase())), { headers: CORS });
    if (u.searchParams.get('ig') === '1') return new Response(JSON.stringify(await startIg(env)), { headers: CORS });   // v10: the staff app's Instagram page - Run now / after a command
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
    return new Response(JSON.stringify({ ok: true, msg: env.GH_TOKEN ? 'ok: key set' : 'GH_TOKEN secret is NOT set yet', gh, ghMsg, scr, scrMsg, ver: 16, sa: true, ai: aiProviders(env), now: Date.now() }), { headers: CORS });
  },
};
