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
 * One-time setup (Cloudflare dashboard, works on the phone) - see RELEASE-WORKER.md in the repo for the steps with pictures-free detail:
 *  1. Workers & Pages -> Create -> Worker -> name it  davan-release  -> Deploy -> Edit code -> paste this file -> Deploy.
 *  2. Settings -> Variables and Secrets -> Add -> type Secret, name GH_TOKEN, value = the GitHub key (Actions: read and write,
 *     only the davan-attendance repository).
 *  3. Settings -> Trigger events -> Add -> Cron triggers:  45 15 * * *   and   15 16 * * *   (Cloudflare times are UTC).
 *  4. Open https://davan-release.<your-subdomain>.workers.dev/ - it must say "ok: key set".
 */
const REPO = 'harshgujjar/davan-attendance';
const WORKFLOW = 'release-widgets.yml';

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
  // the timer: 9:15 pm IST + 9:45 pm backup
  async scheduled(event, env, ctx) { ctx.waitUntil(startRelease(env, 'Cloudflare timer ' + event.cron)); },
  // GET /            -> health check (no release)
  // GET /?now=1      -> "Release now" from the staff app: the job releases only if the Super Admin pressed it
  // GET /?log=CODE   -> a widget log request (log-request.yml -> log-req.json)
  async fetch(request, env) {
    const u = new URL(request.url);
    if (u.searchParams.get('log')) return new Response(JSON.stringify(await logRequest(env, String(u.searchParams.get('log')).trim().toUpperCase())), { headers: CORS });
    if (u.searchParams.get('now') === '1') return new Response(JSON.stringify(await startRelease(env, 'Release now button')), { headers: CORS });
    // 07-Oct-2026 (user: "show whether my new Cloudflare worker is connected"): gh = the GitHub key really opens the release job
    // (one read-only GitHub call); the staff app's Faculty Class Alerts page and Widget updates card show it. crons = its timers.
    let gh = null, ghMsg = '';
    if (env.GH_TOKEN) try {
      const r = await fetch('https://api.github.com/repos/' + REPO + '/actions/workflows/' + WORKFLOW, { headers: { 'Authorization': 'Bearer ' + env.GH_TOKEN,
        'Accept': 'application/vnd.github+json', 'User-Agent': 'davan-release-worker', 'X-GitHub-Api-Version': '2022-11-28' } });
      gh = r.status === 200; ghMsg = gh ? 'GitHub key works' : 'GitHub said ' + r.status + (r.status === 401 ? ' (key wrong or expired)' : '');
    } catch (e) { ghMsg = 'GitHub not reachable: ' + e.message; }
    return new Response(JSON.stringify({ ok: true, msg: env.GH_TOKEN ? 'ok: key set' : 'GH_TOKEN secret is NOT set yet', gh, ghMsg, ver: 3, now: Date.now() }), { headers: CORS });
  },
};
