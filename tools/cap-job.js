// Every 3 hours (GitHub Action cap-alert.yml): recompute the 200-unit forecast with the SAME file as the meter app (cap-core.js)
// and save it in DB1 harsha_home_bills/electric/capAlert, so the Meter Tracker widget is never waiting for the app to be opened.
const C = require('../cap-core.js');
const DB = 'https://davan-attendance-2026-default-rtdb.asia-southeast1.firebasedatabase.app/harsha_home_bills/electric';
async function get(p) { for (let i = 0; i < 3; i++) { try { const r = await fetch(DB + '/' + p + '.json'); if (r.ok) return await r.json(); } catch (e) {} await new Promise(r => setTimeout(r, 3000 * (i + 1))); } throw new Error('read failed: ' + p); }
(async () => {
  let rd = await get('readings'); if (rd && !Array.isArray(rd)) rd = Object.values(rd);
  const set = (await get('settings')) || {}, old = (await get('capAlert')) || {};
  const r = C.compute(rd || [], set, Date.now());
  if (!r) { console.log('no readings'); return; }
  const sig = x => [x.level, x.pB, x.pW, x.called, x.upsOn, x.showCall, x.stale, x.phone, x.daysToReader].join('|');
  if (sig(old) === sig(r) && Date.now() - (old.ts || 0) < 100 * 60000) { console.log('unchanged', sig(r)); return; }
  delete r.pts; delete r.lines;
  const res = await fetch(DB + '/capAlert.json', { method: 'PUT', body: JSON.stringify(r) });
  if (!res.ok) throw new Error('write failed ' + res.status);
  console.log('capAlert saved', r.level, r.short);
})().catch(e => { console.error(e.message); process.exit(1); });
