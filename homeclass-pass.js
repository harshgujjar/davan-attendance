/* Home Class - pass client (stage 1a, 15-Nov-2026). Built by Gujjar & Company.
   Talks to the pass server (Cloudflare worker homeclass-pass): joining a family with the 6-digit code + the parent's Allow / Deny,
   the signed device pass (2 days, works 3 more days offline), what this family may use (Free / Paid / gifts) and the class engine,
   which the server gives only to a phone with a valid pass. NOT loaded by the live app yet (wired in at stage 1e).
   Needs homeclass-core.js (C.devId, C.fam, C.setFam, C.LS, C.diag). Every call resolves to {ok:true,...} or {ok:false, err, msg} - never throws. */
(function () {
  var P = {};
  P.URL = 'https://homeclass-pass.harshgujjar.workers.dev';
  P.FREE = { plan: 'free', tables: [1, 2, 3, 4, 5], kids: 1, lessons: 'sample', gh: false, live: false, call: true, follow: false, gifts: [] };
  var C = window.C || {};
  var LS = C.LS || { get: function (k, d) { try { var v = localStorage.getItem(k); return v == null ? d : JSON.parse(v); } catch (e) { return d; } }, set: function (k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} }, del: function (k) { try { localStorage.removeItem(k); } catch (e) {} } };
  function diag(m) { try { if (C.diag) C.diag('pass: ' + m); } catch (e) {} }
  function dev() { return C.devId ? C.devId() : (LS.get('hc_dev', '') || (function () { var d = 'd' + Math.random().toString(36).slice(2, 12); LS.set('hc_dev', d); return d; })()); }
  function fam() { return C.fam ? C.fam() : LS.get('hc_fam', ''); }
  var OFFLINE = { ok: false, err: 'offline', msg: 'No internet. Connect once and try again.' };
  function call(path, body, method) {
    var o = { method: method || (body ? 'POST' : 'GET'), cache: 'no-store' };
    if (body) { o.body = JSON.stringify(body); o.headers = { 'content-type': 'application/json' }; }
    return fetch(P.URL + path, o).then(function (r) {
      var ct = r.headers.get('content-type') || '';
      return (ct.indexOf('json') >= 0 ? r.json() : r.text().then(function (t) { return { ok: r.ok, text: t }; })).then(function (j) { if (j && typeof j === 'object' && j.ok === undefined) j.ok = r.ok; return j; });
    }).catch(function () { return OFFLINE; });
  }
  P.dev = dev;
  /* ---------- the stored pass ---------- */
  P.saved = function () { return LS.get('hc_pass', null); };
  P.ent = function () { var s = P.saved(); return s && s.ent && Date.now() < s.grace ? s.ent : P.FREE; };
  P.paid = function () { return P.ent().plan === 'paid'; };
  P.tableOk = function (n) { var t = P.ent().tables; return t === 'all' || (t || []).indexOf(Number(n)) >= 0; };
  P.daysLeft = function () { var s = P.saved(); return s ? Math.max(0, Math.ceil((s.grace - Date.now()) / 864e5)) : 0; };
  function keep(j) { if (j && j.ok && j.pass) { var g = j.exp + 3 * 864e5; LS.set('hc_pass', { pass: j.pass, exp: j.exp, grace: g, ent: j.ent, at: Date.now() }); diag('pass ok · ' + j.ent.plan + ' · until ' + new Date(j.exp).toISOString().slice(0, 16)); } return j; }
  P.renew = function () {
    var f = fam(); if (!f) return Promise.resolve({ ok: false, err: 'no_family', msg: 'This phone is not linked to a family yet.' });
    return call('/pass/renew', { fam: f, dev: dev() }).then(function (j) {
      if (j.ok) return keep(j);
      if (j.err === 'blocked' || j.err === 'unknown_device' || j.err === 'paused') { LS.del('hc_pass'); diag('pass refused: ' + j.err); }
      return j;
    });
  };
  /* use the saved pass while it has more than 12 hours left; otherwise renew; offline -> keep using it until the grace time */
  P.ensure = function () {
    var s = P.saved(), t = Date.now();
    if (s && s.exp - t > 12 * 36e5) return Promise.resolve({ ok: true, cached: true, ent: s.ent });
    return P.renew().then(function (j) {
      if (j.ok) return j;
      if (j.err === 'offline' && s && t < s.grace) return { ok: true, cached: true, offline: true, ent: s.ent };
      if (j.err === 'offline') return { ok: false, err: 'expired', msg: 'Go online to renew the pass - Paid features are paused (Free features still work).' };
      return j;
    });
  };
  /* ---------- joining a family (child phone / TV / 2nd parent) ---------- */
  P.join = function (code, make, role) {
    code = String(code || '').replace(/\D/g, '');
    if (code.length !== 6) return Promise.resolve({ ok: false, err: 'wrong_code', msg: 'The family code has 6 digits.' });
    return call('/pair/start', { code: code, dev: dev(), make: String(make || 'phone').slice(0, 60), role: role || 'kid' }).then(function (j) { if (j.ok) { LS.set('hc_joinreq', { req: j.req, at: Date.now() }); diag('join asked'); } else diag('join: ' + j.err); return j; });
  };
  /* wait for the parent's answer: onTick(secondsWaited) while waiting; resolves {st:'allow'|'deny'|'expired'} */
  P.waitAllow = function (onTick, everyMs, maxMs) {
    var jr = LS.get('hc_joinreq', null); everyMs = everyMs || 3000; maxMs = maxMs || 15 * 60000;
    if (!jr) return Promise.resolve({ ok: false, st: 'expired', msg: 'Type the family code again.' });
    var start = Date.now();
    return new Promise(function (done) {
      (function poll() {
        call('/pair/status?req=' + encodeURIComponent(jr.req) + '&dev=' + encodeURIComponent(dev())).then(function (j) {
          if (j.ok && j.st === 'allow') { LS.del('hc_joinreq'); if (C.setFam) C.setFam(j.fam); else LS.set('hc_fam', j.fam); keep(j); diag('joined the family'); return done({ ok: true, st: 'allow', ent: j.ent }); }
          if (j.ok && j.st === 'deny') { LS.del('hc_joinreq'); diag('join denied'); return done({ ok: true, st: 'deny' }); }
          if (j.err === 'expired' || Date.now() - start > maxMs) { LS.del('hc_joinreq'); return done({ ok: false, st: 'expired', msg: 'The request ran out. Type the code again.' }); }
          if (onTick) try { onTick(Math.round((Date.now() - start) / 1000)); } catch (e) {}
          setTimeout(poll, everyMs);
        });
      })();
    });
  };
  /* ---------- parent phone ---------- */
  P.answer = function (req, allow) {
    return P.ensure().then(function (e) { var s = P.saved(); if (!s) return e.ok ? { ok: false, err: 'no_pass', msg: 'Go online once.' } : e; return call('/pair/answer', { pass: s.pass, fam: fam(), req: req, allow: !!allow }); });
  };
  P.code = function (old, fresh) {
    return P.ensure().then(function (e) { var s = P.saved(); if (!s) return e.ok ? { ok: false, err: 'no_pass', msg: 'Go online once.' } : e; return call('/code/set', { pass: s.pass, fam: fam(), old: old || '', fresh: !!fresh }); });
  };
  /* ---------- class engine: only for a valid pass; the last good copy is kept for offline days ---------- */
  P.engine = function () {
    return P.ensure().then(function (e) {
      var s = P.saved(), cache = LS.get('hc_engine', null), t = Date.now();
      function useCache(why) { if (cache && s && t < s.grace) return { ok: true, js: cache.js, cached: true, why: why }; return { ok: false, err: why === 'offline' ? 'expired' : why, msg: why === 'offline' ? 'Go online once to get today\'s class.' : 'The class could not be loaded.' }; }
      if (!s) return e.ok ? useCache('no_pass') : e;
      return call('/engine?pass=' + encodeURIComponent(s.pass) + '&dev=' + encodeURIComponent(dev())).then(function (j) {
        if (j && j.text && j.ok) { LS.set('hc_engine', { js: j.text, at: t }); return { ok: true, js: j.text }; }
        if (j && j.err === 'offline') return useCache('offline');
        if (j && j.err === 'bad_pass') LS.del('hc_engine');
        return j && j.err ? j : useCache('error');
      });
    });
  };
  P.runEngine = function () {
    return P.engine().then(function (r) {
      if (!r.ok) return r;
      try { (0, eval)(r.js); diag('engine on' + (r.cached ? ' (saved copy)' : '')); return { ok: true, cached: !!r.cached }; }
      catch (e) { diag('engine error: ' + e.message); return { ok: false, err: 'engine_error', msg: 'The class could not start. Try 🔄 Refresh.' }; }
    });
  };
  window.HCPass = P;
})();
