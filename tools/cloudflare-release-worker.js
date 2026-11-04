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
 *  - v18 (04-Nov-2026): 🖥️ Davan PC Doctor - POST /lab/tok, /lab/pc, /lab/alert, /lab/ai + the hourly lab check (secret DB5_SA).
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
const IG_CRON = '5 * * * *';   // v20: every hour, 24 h (the free plan allows only 5 timers per ACCOUNT) - Instagram still only 00-18 UTC, below
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
  const e = { at, kind: clip(ev.kind || 'job', 20), color, title: clip(ev.title, 120), body: clip(ev.body, ev.kind === 'wupd_hr' ? 1500 : 500), by: clip(ev.by, 60), link: clip(ev.link, 200), who: clip(ev.who, 60) };
  if (ev.mode) e.mode = clip(ev.mode, 10); if (ev.say) e.say = clip(ev.say, 900);   // v20: wupd_hr - On / Quiet + the spoken text
  const key = 'e' + at + String(Math.floor(Math.random() * 90) + 10);
  await db2('PUT', 'davan_pub/sa_ev/' + key, e);
  await db2('PUT', 'davan_pub/sa_ev_at', at);
  const subs = (await db2('GET', 'davan_pub/sa_push')) || {};
  const list = e.mode === 'quiet' ? [] : Object.entries(subs).filter(([, s]) => s && s.endpoint && s.keys);   // v20: Quiet = no push
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
  if (b.kind === 'wupd') return wupdCant(b);   // v18: student "My phone can't update"
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

/* v18 (user, 03-Nov-2026: "6:05 alert - don't depend on GitHub, use Cloudflare"): the daily 📲 widget update alert, made here.
   Reads DB2 student_widget_report / student_widget_active / staff_widget_report / wupd (the steps the student app and widgets write) and the
   public version jsons; writes davan_pub/wupd_idx/<URN> {code, model, v, at} (the student app finds a student's widget even on a new browser)
   and davan_pub/wupd_sum/<IST date> (the report page's daily numbers); deletes wupd entries untouched for 60 days. One alert, nothing new = none. */
const RAW = 'https://raw.githubusercontent.com/harshgujjar/davan-attendance/main/';
function dueBuild(pub) {   // newest public build out for more than 24 h (a phone gets one night to update by itself)
  let best = 0;
  for (const [b, t] of Object.entries((pub && pub.times) || {})) {
    const at = Date.parse(String(t).replace(/(\d+) (\w+) (\d+), (.*)/, '$2 $1 $3 $4') + ' GMT+0530');
    if (at && Date.now() - at > 864e5 && +b > best) best = +b;
  }
  return best;
}
function wName(pub, b) { const n = (pub && pub.names) || {}; const ks = Object.keys(n).map(Number).filter(k => k <= b); return ks.length ? 'w' + n[Math.max(...ks)] : 'build ' + b; }
async function wupdDaily() {
  const now = Date.now(), cut7 = now - 7 * 864e5, today = istDate(now);
  const get = f => fetch(RAW + f + '?t=' + now).then(r => r.ok ? r.json() : null).catch(() => null);
  const [sp, tp, srep, sact, trep, wl] = await Promise.all([get('student-widget-version.json'), get('davan-widget-version.json'),
    db2('GET', 'davan_pub/student_widget_report'), db2('GET', 'davan_pub/student_widget_active'), db2('GET', 'davan_pub/staff_widget_report'), db2('GET', 'davan_pub/wupd')]);
  // 1. index URN -> newest widget
  const idx = {};
  for (const [code, a] of Object.entries(sact || {})) {
    const r = (srep || {})[code]; if (!a || !a.urn || !r) continue;
    const at = Math.max(+r.ts || 0, +r.workerLastRunAt || 0), k = String(a.urn).toUpperCase().replace(/[.#$\[\]\/]/g, '_');
    if (!idx[k] || idx[k].at < at) idx[k] = { code, model: clip(r.model, 30), v: +r.apkVersion || 0, at, name: clip(a.name, 40), cls: clip(a.class, 30) };
  }
  if (Object.keys(idx).length) await db2('PUT', 'davan_pub/wupd_idx', idx);
  // 2. who is behind
  const sd = dueBuild(sp), td = dueBuild(tp);
  const stuOld = Object.values(idx).filter(x => x.at >= cut7 && sd && x.v < sd);
  const staffOld = Object.values(trep || {}).filter(r => r && r.linked && String(r.name || '').trim() && (+r.at || 0) >= cut7 && td && (+r.v || 0) < td);
  // 3. what students did today (steps written by the student app / widget)
  const c = { saw: 0, upd: 0, dl: 0, ok: 0, cant: 0, dir: 0, later: 0 }, cant = [], dir = [], z = {};
  for (const [k, w] of Object.entries(wl || {})) {
    if (!w) continue; const s = w.s || {};
    for (const e of Object.keys(c)) if (s[e] && istDate(s[e]) === today) c[e]++;
    if (s.cant && istDate(s.cant) === today) cant.push(w.name || k);
    if (s.dir && istDate(s.dir) === today) dir.push(w.name || k);
    if ((+w.last || 0) < now - 60 * 864e5 && !(w.w && Object.values(w.w).some(t => t > now - 60 * 864e5))) z[k] = null;   // clean-up
  }
  if (Object.keys(z).length) await db2('PATCH', 'davan_pub/wupd', z);
  await db2('PUT', 'davan_pub/wupd_sum/' + today, { at: now, stuOld: stuOld.length, staffOld: staffOld.length, ...c });
  if (!stuOld.length && !staffOld.length && !c.saw && !c.ok) return;
  const st = staffOld.sort((a, b) => a.v - b.v).map(r => '• ' + clip(r.name, 30) + ' - ' + wName(tp, +r.v) + ((r.perm || []).includes('install') ? ' (install permission OFF)' : '') + (r.upd && r.upd.res && r.upd.res !== 'ok' ? ' · Android: ' + clip(r.upd.res, 40) : '')).join('\n');   // v19: w363 reports Android's answer
  await saEvent({ kind: 'widgets', color: c.cant || dir.length ? 'red' : 'amber',
    title: '📲 Widgets today: ' + c.ok + ' updated · ' + stuOld.length + ' student + ' + staffOld.length + ' staff still old',
    body: 'Students: saw ' + c.saw + ' · tapped Update ' + c.upd + ' · downloaded ' + c.dl + ' · updated ' + c.ok + ' · later ' + c.later
      + (cant.length ? '\n🆘 Can\'t update: ' + cant.slice(0, 8).join(', ') : '') + (dir.length ? '\n🏢 To meet the Director: ' + dir.slice(0, 8).join(', ') : '')
      + (st ? '\nStaff not updated:\n' + st : '') + '\nDetails: staff app → 📲 Widget update report.',
    by: 'Cloudflare 6:05 pm', link: 'https://harshgujjar.github.io/davan-attendance/index.html?go=wupd' });
}
/** POST /sa {kind: 'wupd'} from the student app's "My phone can't update" - one alert per student per day. */
async function wupdCant(b) {
  const urn = clip(b.urn, 20).toUpperCase().replace(/[^A-Z0-9]/g, ''); if (!urn) return { ok: false, msg: 'no urn' };
  const w = await db2('GET', 'davan_pub/wupd/' + urn); if (!w || !w.s || !w.s.cant || Date.now() - w.s.cant > 10 * 60000) return { ok: false, msg: 'no fresh step' };
  if (w.alertDay === istDate(Date.now())) return { ok: true, msg: 'already told today' };
  await db2('PATCH', 'davan_pub/wupd/' + urn, { alertDay: istDate(Date.now()) });
  return saEvent({ kind: 'widgets', color: 'red', who: clip(w.name, 60), title: '🆘 ' + clip(w.name || urn, 60) + ' can\'t update the widget',
    body: clip(w.cls, 30) + ' · ' + urn + ' · build ' + (+w.v || '?') + (w.model ? ' · ' + clip(w.model, 30) : '') + (w.cantWhy ? '\n"' + clip(w.cantWhy, 120) + '"' : '') + '\nAsked to meet the Director.',
    by: 'student app', link: 'https://harshgujjar.github.io/davan-attendance/index.html?go=wupd' });
}

/* v20 (user, 04-Nov-2026: "one notification only for the Super Admin - which student / staff updated the widget in this new process, and today's
   numbers, one line each, with a voice note; every hour, 24 hours; switches On / Quiet / Off"): runs on IG_CRON, every hour at :05 UTC (= :35 IST).
   Compares the widget reports with the last snapshot (davan_pub/wupd_snap) - who moved to a newer build, who installed a widget for the first time -
   keeps today's counts (davan_pub/wupd_day/<IST date>) and sends ONE ☁️ alert kind wupd_hr with the summary + a spoken text (say / sayKn).
   davan_pub/wupd_cfg.alert: on (default) = notification + voice (night 9 pm - 7 am: no voice, ▶ in the widget), quiet = only the widget's
   messages box with ▶, off = nothing sent (counts still kept). Nobody updated in the hour = no alert. */
async function wupdHourly() {
  const now = Date.now(), today = istDate(now);
  const get = f => fetch(RAW + f + '?t=' + now).then(r => r.ok ? r.json() : null).catch(() => null);
  const [sp, tp, srep, sact, trep, wl, snap, cfg, day, use] = await Promise.all([get('student-widget-version.json'), get('davan-widget-version.json'),
    db2('GET', 'davan_pub/student_widget_report'), db2('GET', 'davan_pub/student_widget_active'), db2('GET', 'davan_pub/staff_widget_report'),
    db2('GET', 'davan_pub/wupd'), db2('GET', 'davan_pub/wupd_snap'), db2('GET', 'davan_pub/wupd_cfg'), db2('GET', 'davan_pub/wupd_day/' + today), db2('GET', 'davan_pub/usage/' + today, undefined, 'shallow=true')]);
  if (!srep || !trep) return;
  const cut7 = now - 7 * 864e5, pv = sp ? +sp.apkVersion : 0, tv = tp ? +tp.apkVersion : 0;
  const nowS = {}, nowT = {}, ups = [], d = Object.assign({ stu: 0, stf: 0, inst: 0 }, day || {});
  const urnOf = code => { const a = (sact || {})[code]; return a && a.urn ? String(a.urn).toUpperCase() : ''; };
  for (const [code, r] of Object.entries(srep)) { if (!r || !urnOf(code)) continue; const v = +r.apkVersion || 0; nowS[code] = v;
    const was = snap && snap.s ? snap.s[code] : undefined, a = sact[code];
    if (snap && was === undefined && v) { ups.push({ n: a.name || urnOf(code), c: String(a.class || '').replace('Davan-', '').replace(/-Sem(\d)-Sec(\w)/, ' $1 sem $2'), to: v, inst: 1 }); d.inst++; }
    else if (snap && was && v > was) { const w = (wl || {})[urnOf(code)] || {}, st = w.s || {}, via = st.upd > now - 3 * 3600e3 ? 'via the update card' : st.dl > now - 3 * 864e5 ? 'via Download' : 'by itself';
      ups.push({ n: a.name || urnOf(code), c: String(a.class || '').replace('Davan-', '').replace(/-Sem(\d)-Sec(\w)/, ' $1 sem $2'), from: was, to: v, via }); d.stu++; } }
  for (const [code, r] of Object.entries(trep)) { if (!r || !r.linked || !String(r.name || '').trim()) continue; const v = +r.v || 0; nowT[code] = v;
    const was = snap && snap.t ? snap.t[code] : undefined;
    if (snap && was && v > was) { ups.push({ n: String(r.name).trim(), c: 'Staff', from: was, to: v, via: r.upd && r.upd.res === 'tap' ? 'with a tap' : 'by itself', staff: 1 }); d.stf++; } }
  await db2('PUT', 'davan_pub/wupd_snap', { at: now, s: nowS, t: nowT });
  await db2('PUT', 'davan_pub/wupd_day/' + today, d);
  if (!snap || !ups.length) return;
  const mode = (cfg && cfg.alert) || 'on'; if (mode === 'off') return;
  const actS = Object.entries(srep).filter(([code, r]) => r && urnOf(code) && Math.max(+r.ts || 0, +r.workerLastRunAt || 0) >= cut7);
  const oldS = actS.filter(([, r]) => (+r.apkVersion || 0) < pv), oldT = Object.values(trep).filter(r => r && r.linked && String(r.name || '').trim() && (+r.at || 0) >= cut7 && (+r.v || 0) < tv);
  const dlS = oldS.filter(([, r]) => r.upd && r.upd.ready).length, dlT = oldT.filter(r => r.upd && r.upd.ready).length;
  const withW = new Set(actS.map(([code]) => urnOf(code))), noW = Object.keys(use || {}).filter(u => !withW.has(String(u).toUpperCase())).length;
  let cant = 0, dir = 0; for (const w of Object.values(wl || {})) { const st = (w && w.s) || {}; if (st.ok) continue; if (st.cant) cant++; if (st.dir) dir++; }
  const W = (pub, b) => wName(pub, b), when = ms => new Date(ms).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', weekday: 'short', day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' }).replace(/\s?(am|pm)$/i, m => ' ' + m.trim().toLowerCase());
  const left = ms => { const x = Math.max(0, ms - now), dd = Math.floor(x / 864e5), h = Math.floor(x % 864e5 / 3600e3); return (dd ? dd + ' day' + (dd > 1 ? 's' : '') + ' ' : '') + h + ' h left'; };
  const relAt = sp && sp.times && sp.times[pv] ? Date.parse(String(sp.times[pv]).replace(/(\d+) (\w+) (\d+), (.*)/, '$2 $1 $3 $4') + ' GMT+0530') : 0;
  const lockS = cfg && cfg.mode === 'auto' && relAt ? relAt + (+cfg.softDays || 2) * 864e5 : 0, lockN = cfg && cfg.getMode === 'req' ? +cfg.getBy || 0 : 0;
  const lines = ups.slice(0, 5).map(u => (u.inst ? '🆕 ' : '✅ ') + u.n + ' · ' + u.c + ' · ' + (u.inst ? 'new widget installed (' + W(sp, u.to) + ')' : W(u.staff ? tp : sp, u.from) + ' → ' + W(u.staff ? tp : sp, u.to) + ' · ' + u.via));
  if (ups.length > 5) lines.push('+ ' + (ups.length - 5) + ' more');
  const hr = new Date(now + 5.5 * 3600e3), h1 = hr.getUTCHours(), fmtH = h => ((h % 12) || 12) + (h < 12 ? ' am' : ' pm');
  const body = lines.join('\n') + '\n── Summary today ──'
    + '\n🔄 Updated today: ' + d.stu + ' student' + (d.stu === 1 ? '' : 's') + ' · ' + d.stf + ' staff'
    + '\n🆕 New installs today: ' + d.inst + ' student' + (d.inst === 1 ? '' : 's')
    + '\n⬇ Downloaded, not installed yet: ' + dlS + ' student' + (dlS === 1 ? '' : 's') + ' · ' + dlT + ' staff'
    + '\n⏳ Still on an old widget: ' + oldS.length + ' student' + (oldS.length === 1 ? '' : 's') + ' · ' + oldT.length + ' staff'
    + '\n📲 No widget yet (opened the app today): ' + noW + ' student' + (noW === 1 ? '' : 's')
    + '\n🆘 Can\'t update: ' + cant + ' · 🏢 To meet the Director: ' + dir
    + (lockS > now ? '\n⏰ Student lock: ' + when(lockS) + ' (' + left(lockS) + ')' : '')
    + (lockN > now ? '\n⏰ No-widget lock: ' + when(lockN) + ' (' + left(lockN) + ')' : '');
  const nm = ups.slice(0, 3).map(u => u.n.split(' ').slice(0, 2).join(' ').toLowerCase().replace(/\b\w/g, x => x.toUpperCase()));
  const say = (ups.length === 1 ? 'One widget' : ups.length + ' widgets') + ' updated in the last hour: ' + nm.join(', ') + (ups.length > 3 ? ' and ' + (ups.length - 3) + ' more' : '') + '. '
    + 'Summary for today: ' + d.stu + ' students and ' + d.stf + ' staff updated. ' + d.inst + ' new widget installs. '
    + dlS + ' students and ' + dlT + ' staff have downloaded but not installed yet. ' + oldS.length + ' students and ' + oldT.length + ' staff are still on an old widget. '
    + noW + ' students have no widget yet. ' + (cant === 1 ? 'One student cannot update' : cant + ' students cannot update') + ', ' + (dir ? dir + ' to meet the Director.' : 'nobody to meet the Director.')
    + (lockS > now ? ' The student lock is on ' + when(lockS).replace(/^(\w+), \d+ \w+, /, '$1 at ') + '.' : '') + (lockN > now ? ' The no-widget lock is on ' + when(lockN).replace(/^(\w+), \d+ \w+, /, '$1 at ') + '.' : '');
  await saEvent({ kind: 'wupd_hr', color: 'green', title: '📲 ' + (ups.length === 1 ? '1 widget' : ups.length + ' widgets') + ' updated in the last hour (' + fmtH((h1 + 23) % 24) + ' – ' + fmtH(h1) + ')',
    body, by: 'Cloudflare hourly', link: 'https://harshgujjar.github.io/davan-attendance/index.html?go=wupd', mode, say });
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

// v17 (user, 03-Nov-2026): the AI prompt says "in the last 7 days" / "in the last 30 days" (rolling windows), not "this week" / "this month".
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
  const line = (A, nm, u) => !A ? '' : nm + ' per ' + u + ': ' + R(A.cur) + '; ' + [ch(A.ch.day, 'since yesterday'), ch(A.ch.week, 'in the last 7 days'), ch(A.ch.month, 'in the last 30 days')].filter(Boolean).join(', ') +
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

// ============================================================================================================================================
// v18 (user, 04-Nov-2026 - ROADMAP-pcdoctor.md 2): 🖥️ Davan PC Doctor. DB5 = Firebase davan-lab. Worker secret DB5_SA = the davan-lab
// service-account JSON (Cloudflare -> davan-release -> Settings -> Variables and Secrets). Without it every /lab route answers
// "DB5 key not set" and the Console shows a clear box - nothing else breaks.
//  POST /lab/tok   {token = staff ID token}            -> DB5 custom token {sa:true} for the Super Admin (Console / staff app)
//  POST /lab/pc    {hwid, key, fp, name, inst, ver}    -> a PC's DB5 custom token (uid pc_<hwid>); a new install is matched to a known PC by
//                                                         its hardware fingerprint (survives an OS reinstall), else gets a new hwid + key
//  POST /lab/alert {idToken (DB5, a PC), kind, title, body, color} -> ☁️ Super Admin alert, at most once per PC + kind per lab/cfg alertGapH
//  POST /lab/mesh  {token} -> a MeshCentral login cookie for the 🖥️ Remote screen (Super Admin)
//  POST /lab/ai    {token = staff or DB5 ID token, prompt, history, system} -> ✨ AI with the lab's own daily limit (lab/cfg aiMax)
//  hourly (IG_CRON): MeshCentral health, PCs left Thawed, PCs turned 🔴, lab-wide problems, the morning summary (lab/cfg sumHour IST).
// ============================================================================================================================================
const DB5 = 'https://davan-lab-default-rtdb.asia-southeast1.firebasedatabase.app';
const DB5_PROJECT = 'davan-lab';
const MESH_URL = 'https://144-24-111-207.sslip.io/';   // overridden by lab/cfg meshUrl (a new VM = a data change, no deploy)
let _sa5 = null, _sa5Key = null, _db5Tok = '', _db5Exp = 0;
const b64uEnc = b => btoa(String.fromCharCode(...new Uint8Array(b))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const b64uStr = s => b64uEnc(new TextEncoder().encode(s));
const hex = b => [...new Uint8Array(b)].map(x => x.toString(16).padStart(2, '0')).join('');
const sha256 = async s => hex(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(String(s))));
async function sa5(env) {
  if (_sa5) return _sa5;
  if (!env.DB5_SA) throw new Error('DB5 key not set on the worker (secret DB5_SA)');
  const j = JSON.parse(env.DB5_SA), pem = String(j.private_key || '').replace(/-----[^-]+-----|\s/g, '');
  _sa5Key = await crypto.subtle.importKey('pkcs8', Uint8Array.from(atob(pem), c => c.charCodeAt(0)), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  _sa5 = j; return j;
}
async function jwt5(env, claims) {
  await sa5(env);
  const h = b64uStr(JSON.stringify({ alg: 'RS256', typ: 'JWT' })), p = b64uStr(JSON.stringify(claims));
  return h + '.' + p + '.' + b64uEnc(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', _sa5Key, new TextEncoder().encode(h + '.' + p)));
}
async function db5Tok(env) {
  if (_db5Tok && Date.now() < _db5Exp) return _db5Tok;
  const j = await sa5(env), now = Math.floor(Date.now() / 1000);
  const a = await jwt5(env, { iss: j.client_email, scope: 'https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email',
    aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600 });
  const r = await fetch('https://oauth2.googleapis.com/token', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + a });
  const t = await r.json(); if (!t.access_token) throw new Error('DB5 key refused by Google: ' + JSON.stringify(t).slice(0, 160));
  _db5Tok = t.access_token; _db5Exp = Date.now() + 50 * 60000; return _db5Tok;
}
async function db5(env, method, path, body, q) {
  const r = await fetch(DB5 + '/' + path + '.json?access_token=' + (await db5Tok(env)) + (q ? '&' + q : ''), { method,
    headers: { 'Content-Type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body) });
  if (!r.ok) throw new Error('DB5 ' + method + ' ' + path + ': ' + r.status);
  return r.json();
}
async function mint5(env, uid, claims) {
  const j = await sa5(env), now = Math.floor(Date.now() / 1000);
  return jwt5(env, { iss: j.client_email, sub: j.client_email, aud: 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
    iat: now, exp: now + 3600, uid, claims });
}
/** Verifies a Firebase ID token of a project (staff project or DB5); returns its body or null. */
async function idTokBody(tok, project) {
  const p = String(tok || '').split('.'); if (p.length !== 3) return null;
  const head = JSON.parse(new TextDecoder().decode(b64u(p[0]))), body = JSON.parse(new TextDecoder().decode(b64u(p[1])));
  if (!_jwk || Date.now() - _jwkAt > 6 * 3600000) {
    const r = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'); _jwk = (await r.json()).keys || []; _jwkAt = Date.now(); }
  const k = _jwk.find(x => x.kid === head.kid); if (!k) return null;
  const key = await crypto.subtle.importKey('jwk', k, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64u(p[2]), new TextEncoder().encode(p[0] + '.' + p[1]));
  if (!ok || body.aud !== project || body.iss !== 'https://securetoken.google.com/' + project || body.exp < Date.now() / 1000 || !body.sub) return null;
  return body;
}
/** The staff login is the Super Admin (same test as the staff app's umMeSuper): its own users/<uid> doc, read with its own token. */
async function staffIsSuper(tok, who) {
  if (String(who.email || '').toLowerCase() === 'admin@davan.local') return true;
  try {
    const r = await fetch('https://firestore.googleapis.com/v1/projects/' + STAFF_PROJECT + '/databases/(default)/documents/users/' + who.uid, { headers: { Authorization: 'Bearer ' + tok } });
    if (!r.ok) return false;
    const f = (await r.json()).fields || {}, sv = k => String((f[k] || {}).stringValue || '');
    return sv('role') === 'admin' && (sv('username').toLowerCase() === 'admin' || (f.superAdmin || {}).booleanValue === true);
  } catch (e) { return false; }
}
async function labTok(env, b) {
  const who = await staffFromToken(b.token).catch(() => null);
  if (!who) return { ok: false, msg: 'Please log in to the staff app again.' };
  if (!(await staffIsSuper(b.token, who))) return { ok: false, msg: 'PC Doctor is for the Super Admin only.' };
  return { ok: true, token: await mint5(env, 'sa_' + who.uid, { sa: true }), apiKey: 'AIzaSyAdebhgQpyjd3ZQgUl_UNhLXYUDRJK1C1s', db: DB5 };
}
// ---- PC identity: scored hardware fingerprint (5. identity survives an OS reinstall) ----
const BLANK_SERIAL = /^(|0+|f+|none|null|default string|to be filled by o\.?e\.?m\.?|system serial number|not specified|not applicable|n\/a|base board serial number|chassis serial number|123456789|0{8}-0{4}-0{4}-0{4}-0{12}|f{8}-f{4}-f{4}-f{4}-f{12})$/i;
const fpClean = v => { v = String(v == null ? '' : v).trim(); return BLANK_SERIAL.test(v) ? '' : v.toUpperCase(); };
const fpList = a => (Array.isArray(a) ? a : []).map(fpClean).filter(Boolean);
function fpScore(a, b) {
  // BIOS UUID 40, board serial 30, onboard MAC 15, CPU id 5, each disk serial 10 (max 20), each RAM serial 5 (max 10) - blank OEM values never count
  let s = 0; const m = { bu: 0, bb: 0, mac: 0, cpu: 0, disk: 0, ram: 0 };
  const eq = (k, w) => { const x = fpClean(a[k]), y = fpClean(b[k]); if (x && x === y) { s += w; m[k] = 1; } };
  eq('bu', 40); eq('bb', 30); eq('mac', 15); eq('cpu', 5);
  const da = fpList(a.disks), db = fpList(b.disks), ra = fpList(a.ram), rb = fpList(b.ram);
  m.disk = da.filter(x => db.includes(x)).length; m.ram = ra.filter(x => rb.includes(x)).length;
  s += Math.min(20, m.disk * 10) + Math.min(10, m.ram * 5);
  return { s, m };
}
const rid = n => hex(crypto.getRandomValues(new Uint8Array(n)));
async function labPc(env, b) {
  const fp = b.fp || {}, name = clip(String(b.name || '').toUpperCase().replace(/[^A-Z0-9-]/g, ''), 20), now = Date.now();
  let hwid = String(b.hwid || '').replace(/[^a-f0-9]/g, '').slice(0, 16), key = String(b.key || '');
  if (hwid && key) {
    const k = await db5(env, 'GET', 'lab/pckey/' + hwid);
    if (k && k.h === await sha256(key)) {
      await db5(env, 'PATCH', 'lab/pckey/' + hwid, { seen: now });
      return { ok: true, hwid, token: await mint5(env, 'pc_' + hwid, { pc: hwid }) };
    }
    if (k) return { ok: false, msg: 'This PC\'s key does not match - run PCDoctor-Setup.cmd again (as admin, Thawed).' };
  }
  // a new install (or a lost key): at most cfg.regMax registrations a day (default 60) so nobody can fill DB5 with fake PCs
  const day = istDate(now), reg = (await db5(env, 'GET', 'lab/reg/' + day)) || 0, cfg = (await db5(env, 'GET', 'lab/cfg')) || {};
  if (reg >= (+cfg.regMax || 60)) return { ok: false, msg: 'Too many new PCs today - try again tomorrow.' };
  const all = (await db5(env, 'GET', 'lab/fp')) || {};
  let best = null;
  for (const [h, f] of Object.entries(all)) { const sc = fpScore(fp, f || {}); if (!best || sc.s > best.sc.s) best = { h, f, sc }; }
  let known = false, merge = '', ev = null;
  if (best && best.sc.s >= 45 && (best.sc.m.bu || best.sc.m.bb)) {
    const k = (await db5(env, 'GET', 'lab/pckey/' + best.h)) || {};
    const live = (await db5(env, 'GET', 'lab/now/' + best.h + '/t')) || 0;
    const sameInst = String(best.f.inst || '') === String(b.inst || '');
    if (live && now - live < 15 * 60000 && sameInst && k.h) return { ok: false, msg: 'Another running PC already has this hardware - check for a cloned disk.' };
    hwid = best.h; known = true;
    const pcs = (await db5(env, 'GET', 'lab/pcs/' + hwid)) || {};
    ev = { t: now, k: sameInst ? 'rekey' : 'reinstall', icon: sameInst ? '🔑' : '🔄', txt: sameInst ? 'PC Doctor installed again (same Windows)' : 'OS reinstalled ' + stampIST(now).split(' ·')[0], name: pcs.name || name };
    // parts that changed on a known board (5. part swap): one event per part, the old serial kept for that part's history
    const da = fpList(best.f.disks), dn = fpList(fp.disks), ra = fpList(best.f.ram), rn = fpList(fp.ram), parts = [];
    da.filter(x => !dn.includes(x)).forEach(x => parts.push({ t: now, k: 'part', part: 'disk', icon: '💾', old: x, txt: 'Disk replaced (old disk ' + x + ')' }));
    ra.filter(x => !rn.includes(x)).forEach(x => parts.push({ t: now, k: 'part', part: 'ram', icon: '🧠', old: x, txt: 'RAM changed (old stick ' + x + ')' }));
    for (const p of parts) await db5(env, 'POST', 'lab/events/' + hwid, p);
  } else {
    hwid = rid(8);
    if (best && best.sc.s >= 20) merge = best.h;   // disk + RAM match a known PC on a new board -> "Looks like PUC2 -> Merge?"
  }
  key = rid(24);
  await db5(env, 'PUT', 'lab/pckey/' + hwid, { h: await sha256(key), at: now, seen: now });
  await db5(env, 'PUT', 'lab/fp/' + hwid, Object.assign({}, fp, { inst: String(b.inst || ''), at: now }));
  await db5(env, 'PUT', 'lab/reg/' + day, reg + 1);
  if (ev) await db5(env, 'POST', 'lab/events/' + hwid, ev);
  if (!known) await db5(env, 'PATCH', 'lab/pcs/' + hwid, { win: name, first: now, merge: merge || null, isNew: true });
  const pcs = known ? ((await db5(env, 'GET', 'lab/pcs/' + hwid)) || {}) : {};
  return { ok: true, hwid, key, known, name: pcs.name || name, merge, token: await mint5(env, 'pc_' + hwid, { pc: hwid }) };
}
async function labAlertSend(env, hwid, a, cfg) {
  const now = Date.now(), gap = (+cfg.alertGapH || 6) * 3600000, kind = clip(String(a.kind || 'pc').replace(/[^a-z0-9_]/gi, ''), 30) || 'pc';
  const last = (await db5(env, 'GET', 'lab/alerts/last/' + hwid + '/' + kind)) || 0;
  if (now - last < gap) return { ok: true, skipped: 'sent ' + Math.round((now - last) / 60000) + ' min ago' };
  const day = istDate(now), n = (await db5(env, 'GET', 'lab/alerts/day/' + day)) || 0;
  if (n >= (+cfg.alertMax || 40)) return { ok: true, skipped: 'daily alert limit' };
  await db5(env, 'PUT', 'lab/alerts/last/' + hwid + '/' + kind, now);
  await db5(env, 'PUT', 'lab/alerts/day/' + day, n + 1);
  await db5(env, 'POST', 'lab/alerts/log', { t: now, h: hwid, kind, title: clip(a.title, 120), body: clip(a.body, 400) });
  return saEvent({ kind: 'lab', color: a.color || 'red', title: clip(a.title, 120), body: clip(a.body, 400), by: 'PC Doctor', link: 'lab.html' + (hwid !== 'lab' ? '#pc=' + hwid : '') });
}
async function labAlert(env, b) {
  const t = await idTokBody(b.idToken, DB5_PROJECT).catch(() => null);
  const hwid = t && String(t.sub || '').startsWith('pc_') ? t.sub.slice(3) : '';
  if (!hwid) return { ok: false, msg: 'not a PC Doctor login' };
  const cfg = (await db5(env, 'GET', 'lab/cfg')) || {};
  if (cfg.alertsOn === false) return { ok: true, skipped: 'alerts switched off' };
  return labAlertSend(env, hwid, b, cfg);
}
// ---- ✨ AI for the Console + the Super Admin laptop's tray (11): the lab's own daily limit, follow-ups in history ----
async function labAi(env, b) {
  let ok = false, who = 'sa';
  const st = await staffFromToken(b.token).catch(() => null);
  if (st) ok = await staffIsSuper(b.token, st);
  if (!ok) { const t = await idTokBody(b.token, DB5_PROJECT).catch(() => null);
    if (t && (t.sa === true)) ok = true;
    else if (t && String(t.sub).startsWith('pc_')) { ok = (await db5(env, 'GET', 'lab/salap/' + t.sub)) === true; who = 'laptop'; } }
  if (!ok) return { ok: false, msg: 'PC Doctor AI is for the Super Admin only.' };
  const cfg = (await db5(env, 'GET', 'lab/cfg')) || {}, day = istDate(Date.now()), max = +cfg.aiMax || 50;
  const used = (await db5(env, 'GET', 'lab/ai_use/' + day)) || 0;
  if (used >= max) return { ok: false, limit: true, msg: 'AI limit used today (' + max + ') - back tomorrow. The rule verdicts keep working.' };
  const sys = clip(b.system, 6000) || 'You are PC Doctor, the computer-lab helper of Davan College, Davangere (India). You get measured data from Windows PCs. Answer in short, plain English for a non-expert: what is wrong, how sure you are, and what to do first. Use only the data given; if it is not enough, say what to check. When a fix button fits, name it exactly (Check now, Clean now, Stop a program, Restart, Repair Windows, Check disk, RAM test, Printer fixes, Roll back driver). Never claim you ran anything.';
  const messages = [{ role: 'system', content: sys }];
  (Array.isArray(b.history) ? b.history.slice(-6) : []).forEach(m => messages.push({ role: m.role === 'assistant' ? 'assistant' : 'user', content: clip(m.content, 2000) }));
  messages.push({ role: 'user', content: clip(b.prompt, 6000) });
  const out = await aiRun(env, messages, Math.min(Math.max(+b.max || 500, 80), 900), (await db2('GET', 'davan_pub/ai_cfg/model')) || '');
  if (!out.text) return { ok: false, msg: out.msg };
  await db5(env, 'PUT', 'lab/ai_use/' + day, used + 1);
  return { ok: true, text: out.text, provider: out.provider, left: max - used - 1, who };
}
/** One AI answer through the provider list (Workers AI -> Gemini -> 2nd account), skipping providers used up today. */
async function aiRun(env, messages, max, model) {
  const tried = [];
  for (const prov of aiProviders(env)) {
    const r = await aiCall(env, prov, messages, max, model).catch(e => ({ err: String(e.message || e) }));
    if (r.text) return { text: r.text, provider: prov + (r.model ? ' · ' + r.model.split('/').pop() : '') };
    tried.push(prov + ': ' + clip(r.err, 120));
  }
  return { msg: 'AI is resting - back tomorrow. (' + tried.join(' | ') + ')' };
}
// ---- 🖥️ Remote screen (10): a MeshCentral login cookie for the Super Admin, made with the server's login-token key (DB5 lab/secret/meshKey,
// saved by the davan-scraper Action "Mesh setup") - same format as MeshCentral's encodeCookie: AES-256-GCM, iv + tag + text, base64 with @ and $.
async function labMesh(env, b) {
  let ok = false;
  const st = await staffFromToken(b.token).catch(() => null);
  if (st) ok = await staffIsSuper(b.token, st);
  if (!ok) { const t = await idTokBody(b.token, DB5_PROJECT).catch(() => null); ok = !!(t && t.sa === true); }
  if (!ok) return { ok: false, msg: 'Remote screen is for the Super Admin only.' };
  const [k, cfg] = await Promise.all([db5(env, 'GET', 'lab/secret/meshKey'), db5(env, 'GET', 'lab/cfg/meshUrl')]);
  const url = cfg || MESH_URL;
  if (!k) return { ok: false, url, msg: 'Remote server not set up yet - run the davan-scraper Action "Mesh setup".' };
  const raw = Uint8Array.from(String(k).match(/../g).map(x => parseInt(x, 16))).slice(0, 32);
  const key = await crypto.subtle.importKey('raw', raw, 'AES-GCM', false, ['encrypt']);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const enc = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, new TextEncoder().encode(JSON.stringify({ u: 'user//admin', a: 3, time: Math.floor(Date.now() / 1000) }))));
  const out = new Uint8Array(12 + enc.length); out.set(iv, 0); out.set(enc.slice(enc.length - 16), 12); out.set(enc.slice(0, enc.length - 16), 28);
  return { ok: true, url, login: btoa(String.fromCharCode(...out)).replace(/\+/g, '@').replace(/\//g, '$') };
}
// ---- hourly (12): MeshCentral health, PCs left Thawed, 🔴 PCs, lab-wide problems, the morning summary ----
const LEVEL = { red: 4, orange: 3, yellow: 2, purple: 3, off: 1, green: 0 };
async function labHourly(env) {
  if (!env.DB5_SA) return;
  const now = Date.now(), cfg = (await db5(env, 'GET', 'lab/cfg')) || {}, st = (await db5(env, 'GET', 'lab/wstate')) || {};
  const nowRows = (await db5(env, 'GET', 'lab/now')) || {}, pcs = (await db5(env, 'GET', 'lab/pcs')) || {};
  const nm = h => ((pcs[h] || {}).name || (pcs[h] || {}).win || h);
  const patch = { at: now }, alerts = [];
  // MeshCentral (remote screen) - 2 failed checks in a row = offline alert, once, then "back online"
  let up = false; try { const r = await fetch(cfg.meshUrl || MESH_URL, { method: 'GET', cf: { cacheTtl: 0 }, signal: AbortSignal.timeout(15000) }); up = r.status < 500; } catch (e) {}
  patch.mesh = { up, t: now, fails: up ? 0 : ((st.mesh || {}).fails || 0) + 1, told: up ? false : !!(st.mesh || {}).told };
  if (!up && patch.mesh.fails >= 2 && !patch.mesh.told) { patch.mesh.told = true; alerts.push({ h: 'lab', kind: 'mesh', color: 'red', title: '🖥️ Remote server offline', body: 'MeshCentral (' + (cfg.meshUrl || MESH_URL) + ') did not answer twice. Run the davan-scraper Action "Mesh setup" to rebuild it.' }); }
  if (up && (st.mesh || {}).told) alerts.push({ h: 'lab', kind: 'mesh_up', color: 'green', title: '🖥️ Remote server back online', body: 'MeshCentral answers again.' });
  // Thawed too long, 🔴 PCs, lab-wide (many PCs with the same problem within the hour)
  const thawH = +cfg.thawRemindH || 3, labN = +cfg.labWideN || 5, recent = now - 70 * 60000, same = {};
  for (const [h, n] of Object.entries(nowRows)) {
    if (!n || (pcs[h] || {}).old) continue;
    if (n.df === 'thawed' && n.dfSince && now - n.dfSince > thawH * 3600000 && n.t > recent)
      alerts.push({ h, kind: 'thawed', color: 'amber', title: '🔥 ' + nm(h) + ' left Thawed', body: 'Thawed for ' + Math.round((now - n.dfSince) / 3600000) + ' h. ' + (n.thawQ ? 'Queued fixes are done - ' : '') + 'set Boot Frozen in Deep Freeze.' });
    if (n.lv === 'red' && n.t > recent) alerts.push({ h, kind: 'red_' + String(n.vk || 'pc').slice(0, 20), color: 'red', title: '🔴 ' + nm(h) + ': ' + clip(n.v, 80), body: clip(n.why, 300) });
    if (n.vk && n.t > recent && LEVEL[n.lv] >= 2) (same[n.vk] = same[n.vk] || []).push(nm(h));
  }
  for (const [vk, list] of Object.entries(same)) if (list.length >= labN)
    alerts.push({ h: 'lab', kind: 'wide_' + vk.slice(0, 20), color: 'purple', title: '🟣 Lab-wide: ' + list.length + ' PCs - ' + vk.replace(/_/g, ' '), body: list.slice(0, 15).join(', ') + ' - check the network, server or a Windows update.' });
  if (cfg.alertsOn !== false) for (const a of alerts.slice(0, 8)) await labAlertSend(env, a.h, a, cfg).catch(() => {});
  // morning summary at lab/cfg sumHour (IST, default 9 -> the :35 tick = 9:35 am), once a day: counts + fixes of the last 24 h + ✨ AI paragraph
  const ist = new Date(now + 5.5 * 3600000), day = istDate(now);
  if (ist.getUTCHours() === (+cfg.sumHour || 9) && st.sumDay !== day) {
    patch.sumDay = day;
    const cnt = { green: 0, yellow: 0, orange: 0, red: 0, purple: 0, off: 0 }, bad = [];
    for (const [h, n] of Object.entries(nowRows)) { if ((pcs[h] || {}).old) continue;
      const lv = n && n.t > now - 30 * 60000 ? (n.lv || 'green') : 'off'; cnt[lv] = (cnt[lv] || 0) + 1; if (LEVEL[lv] >= 2) bad.push(nm(h) + ': ' + clip(n.v, 60)); }
    const fixes = [];   // lab/fixlog/<IST date>/<hwid>/<id> - today + yesterday only
    for (const d of [day, istDate(now - 86400000)]) { const fl = (await db5(env, 'GET', 'lab/fixlog/' + d)) || {};
      for (const [h, x] of Object.entries(fl)) for (const f of Object.values(x || {})) if (f && f.t > now - 86400000) fixes.push(Object.assign({ h, name: nm(h) }, f)); }
    const fixTxt = fixes.length ? fixes.length + ' fix' + (fixes.length === 1 ? '' : 'es') + ' in the last 24 h (' + fixes.filter(f => f.ok).length + ' worked)' : 'No fixes in the last 24 h';
    const total = Object.values(cnt).reduce((a, x) => a + x, 0);
    const base = total ? '🟢 ' + cnt.green + ' healthy · 🟡 ' + cnt.yellow + ' · 🟠 ' + (cnt.orange + cnt.purple) + ' · 🔴 ' + cnt.red + ' · ⚫ ' + cnt.off + ' off. ' + fixTxt + '.' : 'No PCs have reported yet.';
    let ai = '';
    if (total && cfg.aiSummary !== false) {
      const used = (await db5(env, 'GET', 'lab/ai_use/' + day)) || 0;
      if (used < (+cfg.aiMax || 50)) {
        const r = await aiRun(env, [{ role: 'system', content: 'You write a 2-3 sentence morning note about a college computer lab for its admin, plain simple English, no lists, no greetings. Mention what needs attention first. Use only the data.' },
          { role: 'user', content: base + '\nProblems: ' + (bad.slice(0, 20).join('; ') || 'none') + '\nFixes: ' + fixes.slice(-15).map(f => f.name + ' ' + f.fix + (f.ok ? ' ok' : ' failed')).join('; ') }], 220, '').catch(() => ({}));
        if (r.text) { ai = r.text; await db5(env, 'PUT', 'lab/ai_use/' + day, used + 1); }
      }
    }
    await db5(env, 'PUT', 'lab/sum/' + day, { at: now, base, ai, cnt, fixes: fixes.length, bad: bad.slice(0, 30) });
    if (cfg.alertsOn !== false && total) await saEvent({ kind: 'lab', color: cnt.red ? 'red' : 'blue', title: '🖥️ PC Doctor morning summary', body: base + (ai ? '\n✨ ' + ai : ''), by: 'PC Doctor', link: 'lab.html' });
  }
  // 6 / 13: release channel - when every test PC (lab/cfg/test) runs the newest agent build and reports within 15 min for testHoldH hours,
  // lab/cfg/relOk = that build and every other PC takes it at its next hourly check (no test PCs = the loader's own 2 h wait)
  try {
    const lv = await fetch(RAW + 'pcdoctor/lab-version.json?t=' + now).then(r => r.ok ? r.json() : null).catch(() => null);
    const tests = (cfg.test || []).map(x => String(x).toUpperCase());
    if (lv && lv.agent && tests.length && (cfg.relOk || 0) < lv.agent.build) {
      const ver = (await db5(env, 'GET', 'lab/ver')) || {};
      const tp = Object.keys(pcs).filter(h => tests.includes(h.toUpperCase()) || tests.includes(String(nm(h)).toUpperCase()));
      const hold = (+cfg.testHoldH || 2) * 3600000;
      const okAll = tp.length && tp.every(h => (ver[h] || {}).build >= lv.agent.build && now - ((ver[h] || {}).at || now) >= hold && now - ((nowRows[h] || {}).t || 0) < 15 * 60000 && !((ver[h] || {}).rolledBack && ver[h].rolledBack.build === lv.agent.build));
      if (okAll) { await db5(env, 'PATCH', 'lab/cfg', { relOk: lv.agent.build }); patch.rel = { build: lv.agent.build, t: now }; }
    }
  } catch (e) { patch.relErr = String(e.message || e).slice(0, 120); }
  await db5(env, 'PATCH', 'lab/wstate', patch);
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
      if (hm === '12:05') { ctx.waitUntil(startOrAlert(startPlacement(env), 'The 6:05 pm Placement usage')); ctx.waitUntil(wupdDaily().catch(e => saEvent({ kind: 'widgets', color: 'red', title: '❌ 6:05 pm widget alert failed', body: String(e.message || e), by: 'Cloudflare' }))); }
      else if (d.getUTCDay() === 0 && ['12:15', '12:45', '15:00', '15:15'].includes(hm)) ctx.waitUntil(coachRun(env).catch(() => {}));   // v13: Sunday coach notes
      else if (d.getUTCDay() !== 0 && ['12:15', '12:45', '15:00'].includes(hm)) ctx.waitUntil(ratesAiRun(env).catch(() => {}));   // v15: ✨ gold / silver paragraph
      else if (hm === '16:00') ctx.waitUntil(saUsage());
      else if (hm === '15:45' || hm === '16:15') ctx.waitUntil(startOrAlert(startRelease(env, 'Cloudflare timer ' + (hm === '15:45' ? '45 15' : '15 16')), 'The 9:15 pm widget release'));
      return;
    }
    if (c === IG_CRON) {   // v20: the same hourly timer - 📲 widget-update alert every hour, Instagram 5:35 am - 11:35 pm IST as before
      ctx.waitUntil(wupdHourly().catch(e => console.log('wupd hourly', e && e.message)));
      ctx.waitUntil(labHourly(env).catch(e => console.log('lab hourly', e && e.message)));   // v18: 🖥️ PC Doctor
      if (d.getUTCHours() <= 18) ctx.waitUntil(igTimer(env).catch(() => {}));
      return; }   // v16: hourly Instagram, every day incl. Sunday
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
    if (request.method === 'POST' && u.pathname.startsWith('/lab/')) {   // v18: 🖥️ PC Doctor (DB5)
      let b = {}; try { b = JSON.parse(await request.text()); } catch (e) {}
      const fn = { '/lab/tok': labTok, '/lab/pc': labPc, '/lab/alert': labAlert, '/lab/ai': labAi, '/lab/mesh': labMesh }[u.pathname];
      let r; try { r = fn ? await fn(env, b) : { ok: false, msg: 'unknown /lab route' }; } catch (e) { r = { ok: false, msg: String(e.message || e) }; }
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
    return new Response(JSON.stringify({ ok: true, msg: env.GH_TOKEN ? 'ok: key set' : 'GH_TOKEN secret is NOT set yet', gh, ghMsg, scr, scrMsg, ver: 18, sa: true, ai: aiProviders(env), lab: !!env.DB5_SA, now: Date.now() }), { headers: CORS });
  },
};
