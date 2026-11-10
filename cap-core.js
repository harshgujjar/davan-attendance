/* cap-core.js v1 - the ONE 200-unit forecast used by the meter web app, the Meter Tracker widget (via DB1 electric/capAlert)
   and the 3-hourly cloud job (tools/cap-job.js). Pure function: CapCore.compute(readings, settings, nowMs) -> result with the
   finished text lines, so every surface shows the same words. All dates are IST (UTC+5:30), so the phone and the cloud agree. */
(function (g) {
  var IST = 330 * 60000, DAY = 864e5, MN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  function dtOf(d, t) { return new Date(d + 'T' + (t || '00:00') + ':00+05:30'); }
  function rdt(r) { return dtOf(r.d, r.t); }
  function parts(ms) { var x = new Date(+ms + IST); return { y: x.getUTCFullYear(), m: x.getUTCMonth(), d: x.getUTCDate() }; }
  function istNoon(y, m, d) { return new Date(Date.UTC(y, m, d, 12, 0) - IST); }
  function fmt(ms) { var p = parts(ms); return p.d + ' ' + MN[p.m]; }
  function iso(ms) { var p = parts(ms), z = function (n) { return (n < 10 ? '0' : '') + n; }; return p.y + '-' + z(p.m + 1) + '-' + z(p.d); }
  function dur(ms) {
    var m = Math.max(0, Math.round(ms / 60000)), d = Math.floor(m / 1440), h = Math.floor((m % 1440) / 60), mm = m % 60;
    if (d > 0) return d + (d === 1 ? ' day' : ' days') + (h ? ' ' + h + (h === 1 ? ' hour' : ' hours') : '');
    if (h > 0) return h + (h === 1 ? ' hour' : ' hours') + (mm >= 10 ? ' ' + mm + ' min' : '');
    return mm + ' min';
  }
  function upsLog(s) { return (s.upsLog || []).slice().sort(function (a, b) { return a.t < b.t ? -1 : 1; }); }
  function upsEvAt(s, ms) { var ev = null; upsLog(s).forEach(function (e) { if (dtOf(e.t.slice(0, 10), e.t.slice(11)) <= ms) ev = e; }); return ev; }
  function upsOnAt(s, ms) { var e = upsEvAt(s, ms); return e ? !!e.on : true; }
  function evMs(e) { return +dtOf(e.t.slice(0, 10), e.t.slice(11)); }
  /* pace over the last 14 days, same UPS state as now; the first 24 h after the UPS is switched ON (battery recharge) left out;
     UPS saving is measured (3 days ON + 2 days OFF) else unknown (0.5 is only a cautious fallback) */
  function rate(rs, s, now) {
    var from = now - 14 * DAY, nowOn = upsOnAt(s, now), uOn = 0, dOn = 0, uOff = 0, dOff = 0;
    for (var i = 1; i < rs.length; i++) {
      var a = +rdt(rs[i - 1]), b = +rdt(rs[i]); if (b < from) continue;
      var days = (b - a) / DAY, u = rs[i].u - rs[i - 1].u; if (days <= 0 || u < 0) continue;
      var mid = (a + b) / 2, ev = upsEvAt(s, mid);
      if (ev && ev.on && a < evMs(ev) + DAY) continue;
      if (upsOnAt(s, mid)) { uOn += u; dOn += days; } else { uOff += u; dOff += days; }
    }
    var known = dOn >= 3 && dOff >= 2, save = known ? Math.max(0, Math.min(3, uOn / dOn - uOff / dOff)) : 0.5, r, note;
    if (nowOn) { if (dOn >= 2) { r = uOn / dOn; note = 'UPS ON pace'; } else { r = (uOff + uOn) / Math.max(dOn + dOff, 1) + (dOff ? save : 0); note = 'UPS ON, adjusted'; } }
    else { if (dOff >= 2) { r = uOff / dOff; note = 'UPS OFF pace'; } else { r = (uOn + uOff) / Math.max(dOn + dOff, 1) - save; note = 'UPS OFF, adjusted'; } }
    var ev2 = upsEvAt(s, now);
    return { rate: Math.max(r || 0, 0), note: note, nowOn: nowOn, save: save, known: known, recharging: !!(ev2 && ev2.on && upsLog(s).length > 1 && now - evMs(ev2) < DAY && now >= evMs(ev2)) };
  }
  function compute(readings, s, now) {
    s = s || {}; now = now || Date.now();
    var all = (readings || []).filter(function (r) { return r && r.d && typeof r.u === 'number'; });
    var rs = all.filter(function (r) { return r.type !== 'meter'; }).sort(function (a, b) { return rdt(a) - rdt(b); });
    var anchors = all.filter(function (r) { return r.type === 'bill' || r.type === 'meter'; }).sort(function (a, b) { return rdt(b) - rdt(a); });
    if (!rs.length || !anchors.length) return null;
    var a = anchors[0], lat = rs[rs.length - 1], cap = +s.subsidy || 200, bd = +rdt(a), latDT = +rdt(lat);
    var used = Math.max(0, lat.u - a.u), elapsedMs = Math.max(0, now - bd), elapsed = elapsedMs / DAY, R = rate(rs, s, now), rd = +s.readerDay || 9;
    var bp = parts(bd), m = bp.m, y = bp.y, best = +istNoon(y, m, rd);
    while (best <= bd + 10 * DAY) { m++; best = +istNoon(y, m, rd); }
    var worst = best + DAY, totalDays = (worst - bd) / DAY;
    var proj = function (d) { return used + R.rate * Math.max(0, (d - latDT) / DAY); };
    var pB = proj(best), pW = proj(worst), dToBest = Math.ceil((best - now) / DAY), dToWorst = Math.max(1, (worst - latDT) / DAY);
    var safePace = (cap - 3) / totalDays, calm = elapsed < 15;
    var level = calm ? 'green' : pW >= cap ? 'red' : (pB >= cap - 3 || pW >= cap - 5) ? 'yellow' : 'green';
    var allowed = Math.max(0, (cap - 3 - used) / dToWorst), cut = Math.max(0, R.rate - allowed);
    var bills = all.filter(function (r) { return r.type === 'bill'; }).sort(function (x, z) { return x.d < z.d ? -1 : 1; }), ly = null, bm = parts(best);
    for (var i = 1; i < bills.length; i++) { var e = parts(+rdt(bills[i])); if (e.y === bm.y - 1 && e.m === bm.m) ly = bills[i].u - bills[i - 1].u; }
    var hot = [2, 3, 4].indexOf(bm.m) >= 0 || (ly != null && ly >= 185);
    var called = !!(s.readerCalled && +dtOf(s.readerCalled.slice(0, 10), s.readerCalled.slice(11)) > bd);
    var icon = level === 'red' ? '🚨' : level === 'yellow' ? '⚠️' : '✅';
    var head = level === 'red' ? 'You will CROSS ' + cap + ' units if the reader comes on ' + fmt(worst) : level === 'yellow' ? 'Very close to ' + cap + ' units - act now' : calm ? 'New cycle - on track' : 'On track under ' + cap + ' units';
    var f1 = function (v) { return v.toFixed(1); }, L = [];
    L.push('Used **' + f1(used) + '** units in ' + dur(elapsedMs) + ' · pace **' + f1(R.rate) + '**/day (' + R.note + ') · safe pace **' + f1(safePace) + '**/day');
    L.push('🟢 Reader on **' + fmt(best) + '**: ~**' + pB.toFixed(0) + '** units   🔴 on **' + fmt(worst) + '**: ~**' + pW.toFixed(0) + '** units');
    if (calm && R.rate > safePace * 1.1) L.push('Pace is a little above the safe pace. No action needed yet; warnings start from day 15.');
    if (level !== 'green') L.push('Stay under **' + f1(allowed) + '** units/day from now' + (cut > 0.05 ? ' (cut **' + f1(cut) + '**/day' + (R.nowOn ? (R.known ? ' - UPS OFF saves ~' + f1(R.save) + '/day (measured)' : ' - UPS OFF saving not measured yet') : '') + ')' : '') + '. Going over loses the whole free subsidy.');
    if (R.recharging) L.push('🔋 UPS battery recharging after reconnect - the first 24 hours are not counted in the pace.');
    if (hot) L.push('🔥 Hot month' + (ly != null ? ' - same cycle last year was ' + ly.toFixed(0) + ' units' : ' (Mar-May)') + '. Save from day 1.');
    var showCall = dToBest <= 3 && dToBest >= 0;
    if (showCall) L.push('📞 Reader comes ' + (dToBest <= 0 ? 'today' : 'in ' + dToBest + (dToBest === 1 ? ' day' : ' days')) + ' (' + fmt(best) + ') - ask him to come on the ' + rd + 'th.' + (called ? ' ✅ Called.' : ''));
    else if (level !== 'green' && dToBest > 3) L.push('📞 Call the reader on **' + fmt(best - 2 * DAY) + '** (2 days before) - the call button appears then.');
    var staleMs = now - latDT, stale = staleMs > 2 * DAY;
    if (stale) L.push('⏱ No reading for ' + dur(staleMs) + ' - the forecast may be old. Log a reading.');
    var bar = function (t) { return t.replace(/\*\*/g, ''); };
    return {
      v: 1, ts: now, level: level, icon: icon, head: head, calm: calm, cap: cap,
      short: icon + ' ~' + pB.toFixed(0) + '–' + pW.toFixed(0) + ' units', tag: 'Used ' + f1(used) + ' · pace ' + f1(R.rate) + '/day · safe ' + f1(safePace),
      lines: L, plain: L.map(bar), used: +used.toFixed(1), pace: +R.rate.toFixed(2), safePace: +safePace.toFixed(2), paceNote: R.note,
      pB: Math.round(pB), pW: Math.round(pW), best: iso(best), bestTxt: fmt(best), worstTxt: fmt(worst), daysToReader: dToBest, showCall: showCall, called: called,
      calledAt: called ? s.readerCalled : null, phone: (s.readerPhone || '').replace(/[^\d+]/g, '') || null, readerDay: rd, allowed: +allowed.toFixed(1), cut: +cut.toFixed(1),
      upsOn: R.nowOn, recharging: R.recharging, upsSaveKnown: R.known, upsSave: +R.save.toFixed(2), hot: hot, stale: stale, staleHours: Math.round(staleMs / 36e5),
      elapsed: elapsed, elapsedTxt: dur(elapsedMs), latestElapsed: Math.max((latDT - bd) / DAY, 0), totalDays: totalDays, startMs: bd, startTxt: fmt(bd), pW_raw: pW,
      safeNow: safePace * Math.max((latDT - bd) / DAY, 0), pts: [{ x: 0, y: 0 }].concat(rs.filter(function (r) { return rdt(r) > bd; }).map(function (r) { return { x: +((rdt(r) - bd) / DAY).toFixed(3), y: Math.max(0, +(r.u - a.u).toFixed(1)) }; }))
    };
  }
  g.CapCore = { compute: compute, fmt: fmt, dur: dur };
  if (typeof module !== 'undefined' && module.exports) module.exports = g.CapCore;
})(typeof window !== 'undefined' ? window : globalThis);
