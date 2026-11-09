/* Gujjar Home Class - shared code for the parent app (homeclass.html) and the kids app (homeclass-kid.html,
   shown inside the Android app on the kids' phone and the Google TV). History: CHANGELOG-homeclass.md, plan: HOMECLASS.md.
   Data = DB3 (davan-student-news) homeclass/<familyKey>/... over REST + live EventSource. No login: the 28-character
   family key is the lock (rules: homeclass/$fam needs a key of 24+ characters; the root cannot be listed).
   Pairing: hcpair/<6 digits> = {fam, exp} for 15 min. Writes made offline wait in localStorage and go out when online. */
(function () {
  'use strict';
  var C = window.HCcore = {};
  C.VER = 42;
  C.DB = 'https://davan-student-news-default-rtdb.asia-southeast1.firebasedatabase.app/';
  var LS = {
    get: function (k, d) { try { var v = localStorage.getItem(k); return v == null ? d : JSON.parse(v); } catch (e) { return d; } },
    set: function (k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} },
    del: function (k) { try { localStorage.removeItem(k); } catch (e) {} }
  };
  C.LS = LS;

  /* ---------- family key ---------- */
  C.fam = function () { return LS.get('hc_fam', ''); };
  C.setFam = function (k) { LS.set('hc_fam', k); };
  C.newKey = function (n) {
    var a = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789', b = new Uint8Array(n || 28), s = '';
    crypto.getRandomValues(b); for (var i = 0; i < b.length; i++) s += a[b[i] % a.length]; return s;
  };
  C.devId = function () { var d = LS.get('hc_dev', ''); if (!d) { d = C.newKey(10); LS.set('hc_dev', d); } return d; };

  /* ---------- REST ---------- */
  function url(p) { return C.DB + 'homeclass/' + C.fam() + (p ? '/' + p : '') + '.json'; }
  C.url = url;
  C.get = function (p, q) {
    return fetch(url(p) + (q ? '?' + q : ''), { cache: 'no-store' }).then(function (r) { if (!r.ok) throw new Error('DB ' + r.status); return r.json(); });
  };
  function send(m, p, v) {
    return fetch(url(p), { method: m, body: v === undefined ? undefined : JSON.stringify(v) }).then(function (r) {
      if (!r.ok) throw new Error('DB ' + r.status); return r.json();
    });
  }
  /* writes: tried at once; if offline they wait in the queue (kept across restarts) and go in order later */
  var Q = LS.get('hc_q', []), flushing = false;
  function qsave() { if (Q.length > 400) Q = Q.slice(-400); LS.set('hc_q', Q); }
  C.write = function (m, p, v) {
    if (!C.fam()) return Promise.resolve(null);
    if (m === 'POST') { m = 'PUT'; p = p + '/' + pushId(); }   /* own ids so a queued write is never doubled */
    if (Q.length || !navigator.onLine) { Q.push([m, C.fam(), p, v]); qsave(); C.flush(); return Promise.resolve(null); }
    return send(m, p, v).catch(function (e) { C.diag('write ' + p.split('/')[0] + ' failed: ' + e.message + ' - queued', 'w'); Q.push([m, C.fam(), p, v]); qsave(); return null; });
  };
  C.put = function (p, v) { return C.write('PUT', p, v); };
  C.patch = function (p, v) { return C.write('PATCH', p, v); };
  C.push = function (p, v) { return C.write('POST', p, v); };
  C.del = function (p) { return C.write('DELETE', p); };
  C.pending = function () { return Q.length; };
  C.flush = function () {
    if (flushing || !Q.length || !navigator.onLine) return;
    flushing = true;
    (function next() {
      if (!Q.length) { flushing = false; qsave(); return; }
      var w = Q[0];
      if (w[1] !== C.fam()) { Q.shift(); qsave(); return next(); }
      send(w[0], w[2], w[3]).then(function () { Q.shift(); qsave(); next(); })
        .catch(function () { flushing = false; });
    })();
  };
  window.addEventListener('online', C.flush);
  setInterval(C.flush, 20000);
  var lastT = 0, seq = 0;
  function pushId() { var t = Date.now(); seq = t === lastT ? seq + 1 : 0; lastT = t; return t.toString(36) + '-' + seq + C.newKey(4); }

  /* ---------- live: EventSource keeps a local copy of a node and calls cb(value) on every change ---------- */
  /* Browsers allow only 6 open connections to one server; each live EventSource keeps one open for ever, so with 6 every other
     request (writes, the pairing code) waits for ever (seen 01-Nov in the Android app). So: at most 3 live streams; any other
     node is checked every `poll` seconds instead (only while the page is visible). */
  var streams = 0, MAX_STREAMS = 3;
  C.listen = function (p, cb, poll) {
    if (poll || streams >= MAX_STREAMS) return C.poll(p, cb, poll || 20);
    streams++;
    var data = null, es = null, dead = false, retry = 0;
    function setAt(path, v, merge) {
      if (path === '/' || path === '') {
        if (merge) { data = data && typeof data === 'object' ? data : {}; for (var k in v) { if (v[k] === null) delete data[k]; else data[k] = v[k]; } }
        else data = v;
        return;
      }
      var parts = path.split('/').filter(Boolean);
      if (!data || typeof data !== 'object') data = {};
      var o = data;
      for (var i = 0; i < parts.length - 1; i++) { if (!o[parts[i]] || typeof o[parts[i]] !== 'object') o[parts[i]] = {}; o = o[parts[i]]; }
      var last = parts[parts.length - 1];
      if (merge) { if (!o[last] || typeof o[last] !== 'object') o[last] = {}; for (var j in v) { if (v[j] === null) delete o[last][j]; else o[last][j] = v[j]; } }
      else if (v === null) delete o[last]; else o[last] = v;
    }
    function open() {
      if (dead || !C.fam()) return;
      try { es = new EventSource(url(p)); } catch (e) { return later(); }
      function ev(merge) { return function (e) { try { var m = JSON.parse(e.data); setAt(m.path, m.data, merge); retry = 0; cb(data); } catch (x) {} }; }
      es.addEventListener('put', ev(false));
      es.addEventListener('patch', ev(true));
      es.addEventListener('cancel', function () { es.close(); later(); });
      es.addEventListener('auth_revoked', function () { es.close(); later(); });
      es.onerror = function () { if (es.readyState === 2) { C.diag('live ' + p + ' closed - retry'); later(); } };
      es.onopen = function () { if (retry) C.diag('live ' + p + ' back'); };
    }
    function later() { if (dead) return; retry = Math.min(retry + 1, 6); setTimeout(open, 2000 * retry); }
    open();
    return { close: function () { if (!dead) streams--; dead = true; if (es) es.close(); }, value: function () { return data; } };
  };
  C.poll = function (p, cb, sec) {
    var last = null, dead = false, t = null, data = null;
    function run() {
      if (dead) return;
      if (document.hidden) { t = setTimeout(run, 3000); return; }
      C.get(p).then(function (v) { var j = JSON.stringify(v); if (j !== last) { last = j; data = v; cb(v); } })
        .catch(function () {}).then(function () { if (!dead) t = setTimeout(run, sec * 1000); });
    }
    run();
    document.addEventListener('visibilitychange', function () { if (!document.hidden && !dead) { clearTimeout(t); run(); } });
    return { close: function () { dead = true; clearTimeout(t); }, value: function () { return data; } };
  };

  /* ---------- pairing (6-digit code, 15 minutes) ---------- */
  C.makeCode = function () {
    var code = String(100000 + (crypto.getRandomValues(new Uint32Array(1))[0] % 900000));
    var body = { fam: C.fam(), exp: Date.now() + 15 * 60000 };
    return fetch(C.DB + 'hcpair/' + code + '.json', { method: 'PUT', body: JSON.stringify(body) })
      .then(function (r) { if (!r.ok) throw new Error('code ' + r.status); return { code: code, exp: body.exp }; });
  };
  /* v42 (user, 09-Nov-2026: "one permanent family code, always visible"): the family keeps ONE code (cfg.code). It is renewed for 5 more years every time a parent
     app opens (the DB3 rule lets the same family rewrite its own code), so it never runs out; 🔁 New code makes a fresh one and frees the old one. */
  C.famCode = function (cfg, renew) {
    var old = cfg && cfg.code, exp = Date.now() + 5 * 365 * 864e5;
    function put(code) { return fetch(C.DB + 'hcpair/' + code + '.json', { method: 'PUT', body: JSON.stringify({ fam: C.fam(), exp: exp, perm: 1 }) }).then(function (r) { if (!r.ok) throw new Error('code ' + r.status); return code; }); }
    if (old && !renew) return put(old).catch(function () { return C.famCode(cfg, true); });
    var code = String(100000 + (crypto.getRandomValues(new Uint32Array(1))[0] % 900000));
    return fetch(C.DB + 'hcpair/' + code + '.json', { cache: 'no-store' }).then(function (r) { return r.json(); }).then(function (v) {
      if (v && v.fam && v.fam !== C.fam() && v.exp > Date.now()) return C.famCode(cfg, true);      /* taken by another family: pick again */
      return put(code).then(function () {
        if (old && old !== code) fetch(C.DB + 'hcpair/' + old + '.json', { method: 'DELETE' }).catch(function () {});
        C.patch('cfg', { code: code }); if (cfg) cfg.code = code; C.diag('family code ' + (old ? 'changed' : 'made') + ': …' + code.slice(-2)); return code;
      });
    });
  };
  C.useCode = function (code) {
    return fetch(C.DB + 'hcpair/' + code + '.json', { cache: 'no-store' }).then(function (r) { return r.json(); }).then(function (v) {
      if (!v || !v.fam || v.exp < Date.now()) throw new Error('This code is wrong or too old. Make a new one in the parent app.');
      C.setFam(v.fam);
      return v.fam;
    });
  };

  /* ---------- dates (IST) ---------- */
  C.day = function (d) {
    var x = new Date((d ? +d : Date.now()) + 5.5 * 3600000);
    return x.toISOString().slice(0, 10);
  };
  C.istNow = function () { var x = new Date(Date.now() + 5.5 * 3600000); return { h: x.getUTCHours(), m: x.getUTCMinutes(), wd: x.getUTCDay() }; };
  C.fmtDay = function (k) {
    var t = C.day(), y = C.day(Date.now() - 864e5);
    if (k === t) return 'Today'; if (k === y) return 'Yesterday';
    var d = new Date(k + 'T00:00:00Z');
    return d.toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', timeZone: 'UTC' });
  };
  C.fmtTime = function (hhmm) {
    if (!hhmm) return ''; var p = hhmm.split(':'), h = +p[0], m = p[1];
    return (h % 12 || 12) + ':' + m + (h < 12 ? ' am' : ' pm');
  };
  C.ago = function (t) {
    var s = Math.round((Date.now() - t) / 1000);
    if (s < 60) return 'just now'; if (s < 3600) return Math.round(s / 60) + ' min ago';
    if (s < 86400) return Math.round(s / 3600) + ' h ago'; return Math.round(s / 86400) + ' days ago';
  };
  C.plural = function (n, one, many) { return n + ' ' + (n === 1 ? one : (many || one + 's')); };

  /* ---------- default settings (parents change them in the parent app) ---------- */
  C.DEFAULT_CFG = {
    kids: {
      k1: { name: 'Aryan', std: 7, from: 11, to: 30, style: 'revise', min: 15, time: '18:00', days: [1, 2, 3, 4, 5, 6], on: true, emoji: '🦁', color: '#6d5dfc' },
      k2: { name: 'Vihaan', std: 2, from: 1, to: 10, style: 'learn', min: 15, time: '18:30', days: [1, 2, 3, 4, 5, 6], on: true, emoji: '🐯', color: '#ff7a45' }
    },
    upto: 10
  };
  C.kidList = function (cfg) {
    var k = (cfg && cfg.kids) || (cfg && cfg.v2 ? {} : C.DEFAULT_CFG.kids);   /* v40: a new family (cfg.v2) starts with no children - never the Gujjar children */
    return Object.keys(k).sort().map(function (id) { var o = k[id]; o.id = id; return o; });
  };
  /* v40 (user, 09-Nov-2026: other families test the app): app name + family name everywhere */
  C.famName = function (cfg) { var n = cfg && String(cfg.famName || '').trim(); return n || ''; };
  C.appTitle = function (cfg) { var n = C.famName(cfg); return n ? n + ' Home Class' : 'Home Class'; };
  C.newFamCfg = function (name) { return { v2: 1, famName: String(name || '').trim().slice(0, 30), upto: 10, rec: true, joiner: 'zaa', at: Date.now() }; };   /* v41: testing phase - voice clips always on; "zaa" by default */
  C.JOIN_DEF = 'zaa';
  /* v41 (user, 09-Nov: "a refresh button in both apps, every build uses it"): clears the page caches and loads the newest copy */
  C.hardRefresh = function () {
    var go = function () { var q = location.search.replace(/[?&](v|r)=\d+/g, '').replace(/^&/, '?'); location.replace(location.pathname + (q ? q + '&' : '?') + 'r=' + Date.now() + location.hash); };
    try { LS.del('hc_try_kid'); LS.del('hc_try_par'); } catch (e) {}
    if (window.caches && caches.keys) caches.keys().then(function (ks) { return Promise.all(ks.filter(function (k) { return !/^dv-/.test(k); }).map(function (k) { return caches.delete(k); })); }).then(go, go); else go();
  };
  C.stdName = function (n) { n = +n; if (!n) return ''; var s = ['th', 'st', 'nd', 'rd'], v = n % 100; return n + (s[(v - 20) % 10] || s[v] || s[0]) + ' std'; };
  C.styleName = function (s) { return s === 'learn' ? 'Learn step by step' : 'Quick revision (mixed)'; };
  C.STAGES = ['Learning', 'In order', 'Mixed', 'Mastered'];
  /* progress as read from the database: Firebase turns {"1":{..},"2":{..}} into a list [null,{..},{..}] - make it an object again
     (bug 01-Nov: the kids home screen crashed on the null and the phone stopped answering) */
  C.normProg = function (p) {
    p = p && typeof p === 'object' ? p : {};
    var t = {}, src = p.t || {};
    Object.keys(src).forEach(function (k) { var v = src[k]; if (v && typeof v === 'object') t[k] = { st: +v.st || 0, ok: +v.ok || 0, at: v.at }; });
    p.t = t;
    var w = {}; Object.keys(p.weak || {}).forEach(function (k) { if (p.weak[k]) w[k] = +p.weak[k]; }); p.weak = w;
    return p;
  };

  /* ---------- understanding what a child said ---------- */
  var ONES = { zero: 0, oh: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10, eleven: 11,
    twelve: 12, thirteen: 13, fourteen: 14, fifteen: 15, sixteen: 16, seventeen: 17, eighteen: 18, nineteen: 19 };
  var TENS = { twenty: 20, thirty: 30, forty: 40, fourty: 40, fifty: 50, sixty: 60, seventy: 70, eighty: 80, ninety: 90 };
  var SOUND = { won: 1, to: 2, too: 2, tu: 2, for: 4, fore: 4, ate: 8, tree: 3, free: 3, sex: 6, sicks: 6, nein: 9, tin: 10, tan: 10 };
  /* all numbers in a sentence, in order: digits and number words ("fifty six", "one hundred and twelve") */
  C.numbers = function (text, loose) {
    var t = String(text || '').toLowerCase().replace(/(\d),(\d)/g, '$1$2').replace(/-/g, ' ').replace(/[^a-z0-9 ]/g, ' ');
    var w = t.split(/\s+/).filter(Boolean), out = [], cur = null;
    function end() { if (cur !== null) { out.push(cur); cur = null; } }
    for (var i = 0; i < w.length; i++) {
      var x = w[i];
      if (/^\d+$/.test(x)) { end(); out.push(+x); continue; }
      if (/^\d+(st|nd|rd|th)$/.test(x)) { end(); out.push(parseInt(x, 10)); continue; }
      if (x in ONES) {
        if (cur !== null && cur >= 20 && cur % 10 === 0 && cur % 100 !== 0 && ONES[x] < 10) cur += ONES[x];   /* fifty six */
        else if (cur !== null && cur % 100 === 0 && cur > 0) cur += ONES[x];                      /* hundred and two */
        else { end(); cur = ONES[x]; }
        continue;
      }
      if (x in TENS) { if (cur !== null && cur % 100 === 0 && cur > 0) cur += TENS[x]; else { end(); cur = TENS[x]; } continue; }
      if (x === 'hundred') { cur = (cur === null ? 1 : cur) * 100; continue; }
      if (x === 'and' && cur !== null && cur % 100 === 0) continue;
      if (loose && x in SOUND) { end(); out.push(SOUND[x]); continue; }
      end();
    }
    end();
    return out;
  };
  /* the child's answer = the LAST number said ("7 times 8 is 56" -> 56); sound-alikes ("for", "ate") only when no real number */
  C.answerNum = function (text) {
    var n = C.numbers(text, false);
    if (!n.length) n = C.numbers(text, true);
    return n.length ? n[n.length - 1] : null;
  };
  C.hasNum = function (text, want) { return C.numbers(text, true).indexOf(want) >= 0; };
  /* tables the way the kids say them (user, 01-Nov-2026): "two one ja two", "2 too ja four", "two ones are two", "2 into 3 is 6".
     Google often joins quick numbers ("two one two" -> "212", "21 ja 2"): when the numbers start with a and b, the rest is the answer.
     Returns {n: the answer heard or null, ok}. */
  C.tableOne = function (text, a, b) {
    var t = String(text || '').toLowerCase().replace(/\b(ja+|za+|jha|is|are|equals?|equal to|into|times|multiplied by|x)\b/g, ' , ').replace(/\bones\b/g, 'one');
    var ans = a * b;
    /* one short word that Google writes instead of the answer ("the" / "tree" for three - log 01-Nov 19:09): right ONLY when it
       sounds like THE answer; any other single filler word = not heard */
    var SOUNDS = { 1: 'one won van wan', 2: 'two to too tu do', 3: 'three the tree free tea three', 4: 'four for fore far', 5: 'five fife hive', 6: 'six sex sicks sick',
      7: 'seven heaven', 8: 'eight ate hate it', 9: 'nine nein line mine', 10: 'ten tan tin then when', 11: 'eleven', 12: 'twelve' };
    var one = String(text || '').toLowerCase().replace(/[^a-z ]/g, ' ').trim().split(/\s+/);
    if (one.length === 1 && one[0] && !/\d/.test(String(text)) && SOUNDS[ans] && SOUNDS[ans].split(' ').indexOf(one[0]) >= 0) return { n: ans, ok: true };
    var nums = C.numbers(t, true);
    if (!nums.length) return { n: null, ok: false };
    /* mostly other words ("18 years pilot", "computer") = not an answer -> ask again, never mark wrong (log 01-Nov 19:08) */
    var KNOWN = /^(\d+|zero|oh|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fourty|fifty|sixty|seventy|eighty|ninety|hundred|and|won|to|too|tu|for|fore|ate|tree|free|sex|sicks|nein|tin|tan|ja+|za+|jha|is|are|equals?|equal|into|times|multiplied|by|x|ones|the|a|its|it's|answer)$/;
    var w = String(text || '').toLowerCase().replace(/[^a-z0-9' ]/g, ' ').split(/\s+/).filter(Boolean), junk = w.filter(function (x) { return !KNOWN.test(x); }).length;
    if (junk >= 2 && junk > w.length / 2 && nums.indexOf(ans) < 0) return { n: null, ok: false, junk: true };
    var last = nums[nums.length - 1];
    if (last === ans) return { n: ans, ok: true };
    /* v49 (Aryan, log 03-Nov 21:01: 17 x 10 - "one seventy" was marked 70): in India "one seventy" = 170, "two forty" = 240 (no "hundred") */
    if (ans >= 100) for (var q = 0; q + 1 < nums.length; q++) if (nums[q] >= 1 && nums[q] <= 9 && nums[q + 1] >= 10 && nums[q + 1] <= 99 && nums[q] * 100 + nums[q + 1] === ans) return { n: ans, ok: true };
    /* only the question's own numbers ("7 * 4 =", "4 7 ja ...") = the child is still saying the question, not an answer -> listen on
       (log 01-Nov 19:50: " 7 * 4 =" was marked wrong as 4) */
    if (nums.length <= 3 && nums.every(function (x) { return x === a || x === b; }) && String(text || '').replace(/\d/g, '').length < 40
        && !/\b(\d+)\s*$/.test(String(text).replace(/[=\s]+$/, '') + ' x') ) return { n: null, ok: false, question: true };
    var digits = nums.join(''), pre = [String(a) + String(b), String(b) + String(a)];
    for (var i = 0; i < pre.length; i++) if (digits.length > pre[i].length && digits.indexOf(pre[i]) === 0 && digits.slice(pre[i].length) === String(ans)) return { n: ans, ok: true };
    return { n: last, ok: false };
  };
  /* ---------- 🗣️ reciting a whole table (user, 01-Nov-2026: "he tells the 5 table fast - 5 one ja 5, 5 two ja 10 ... - the app follows,
     notes every mistake, tells him where, and asks him to say it again") ----------
     words -> facts. Separators (ja / za / is / into / times / equals) split the speech; before each separator come the table number and
     the line number ("five seven"), after it the answer - which runs into the next line's "five eight". The split that keeps the line
     numbers in order wins, so "fifty five four" after "five three ja" is read as "fifty | five four". Returns [{b, said}] in the order said. */
  var ATOM = { zero: 0, oh: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10, eleven: 11, twelve: 12,
    thirteen: 13, fourteen: 14, fifteen: 15, sixteen: 16, seventeen: 17, eighteen: 18, nineteen: 19, twenty: 20, thirty: 30, forty: 40,
    fourty: 40, fifty: 50, sixty: 60, seventy: 70, eighty: 80, ninety: 90, won: 1, to: 2, too: 2, for: 4, ate: 8 };
  var SEP = /^(ja+|za+|jha|is|are|into|times|equals?|equal|x)$/;
  function atomsOf(words) { var a = []; words.forEach(function (w) { if (/^\d+$/.test(w)) a.push({ v: +w, d: true }); else if (w === 'hundred') a.push({ v: 100, h: true }); else if (w in ATOM) a.push({ v: ATOM[w] }); }); return a; }
  /* all ways to read a list of atoms as ONE number (twenty + five, one hundred + twenty) */
  function oneNum(at) {
    if (!at.length) return null;
    var v = 0, cur = 0, i = 0;
    if (at.length === 1) return at[0].h ? 100 : at[0].v;
    for (i = 0; i < at.length; i++) {
      var x = at[i];
      if (x.h) { cur = (cur || 1) * 100; continue; }
      if (x.d) { if (i !== at.length - 1 || cur % 100 !== 0) return null; cur += x.v; continue; }
      if (x.v >= 20 && x.v % 10 === 0) { if (cur % 100 !== 0) return null; cur += x.v; continue; }
      if (x.v < 10) { if (cur % 10 !== 0 || (cur % 100 >= 10 && cur % 100 < 20)) return null; if (i > 0 && !(at[i - 1].v >= 20 && at[i - 1].v % 10 === 0) && !at[i - 1].h) return null; cur += x.v; continue; }
      if (cur % 100 !== 0) return null; cur += x.v;
    }
    return cur;
  }
  /* v31 (user, 01-Nov-2026: "it does not go with my speed" - log 21:46: fast speech drops "ja": "one six six, one seven seven"):
     follow the PATTERN table · line · answer, with or without ja / za / into. Words -> number atoms; at each step read the table
     number, then the line number, then the answer - the answer ends where the next "table · next line" begins. */
  function readNums(at, i) {               /* every way to read 1-4 atoms from i as one number: [{v, j}] */
    var out = [];
    for (var n = 1; n <= 4 && i + n <= at.length; n++) {
      var part = at.slice(i, i + n); if (part.some(function (x) { return x.sep || x.unk; })) break;
      var v = oneNum(part); if (v !== null) out.push({ v: v, j: i + n });
    }
    return out;
  }
  function skipSep(at, i) { while (i < at.length && (at[i].sep || at[i].unk)) i++; return i; }
  /* every number spoken in the text, in order (answers are found even when the line number next to them was misheard) */
  C.numsIn = function (text) {
    var words = String(text || '').toLowerCase().replace(/\[unk\]/g, ' unk ').replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter(Boolean), at = [], out = [];
    words.forEach(function (w) {
      if (SEP.test(w)) at.push({ sep: true }); else if (w === 'unk') at.push({ unk: true });
      else if (/^\d+$/.test(w)) at.push({ v: +w, d: true }); else if (w === 'hundred') at.push({ v: 100, h: true }); else if (w in ATOM) at.push({ v: ATOM[w] });
    });
    for (var i = 0; i < at.length;) {
      var done = false;
      for (var n = Math.min(4, at.length - i); n >= 1 && !done; n--) {
        var part = at.slice(i, i + n); if (part.some(function (x) { return x.sep || x.unk; })) continue;
        var v = oneNum(part); if (v !== null) { out.push(v); i += n; done = true; }
      }
      if (!done) i++;
    }
    return out;
  };
  C.parseRecite = function (text, t, up) {
    var words = String(text || '').toLowerCase().replace(/\[unk\]/g, ' unk ').replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter(Boolean), at = [];
    words.forEach(function (w) {
      if (SEP.test(w)) at.push({ sep: true, w: w }); else if (w === 'unk') at.push({ unk: true });
      else if (/^\d+$/.test(w)) at.push({ v: +w, d: true }); else if (w === 'hundred') at.push({ v: 100, h: true }); else if (w in ATOM) at.push({ v: ATOM[w] });
    });
    var lineAt = function (i, b) {            /* does "t b" (b = the given line, or any line when b = 0) start at i? */
      i = skipSep(at, i); var ts = readNums(at, i).filter(function (x) { return x.v === t; });
      for (var q = 0; q < ts.length; q++) { var bs = readNums(at, ts[q].j).filter(function (x) { return b ? x.v === b : x.v >= 1 && x.v <= up; }); if (bs.length) return bs[0]; }
      return null;
    };
    var out = [], i = 0, prevB = 0, guard = 0;
    while (i < at.length && guard++ < 400) {
      i = skipSep(at, i);
      var bHit = lineAt(i, prevB + 1) || lineAt(i, 0);
      if (!bHit && prevB + 1 <= up) {   /* v34 (22:48 "two into two" = "2 one za 2": a fast "one" heard as "into"): table · ja · next line's answer */
        var t0 = readNums(at, i).filter(function (x) { return x.v === t; })[0];
        if (t0 && t0.j < at.length && at[t0.j].sep) { var nb = prevB + 1, an = readNums(at, skipSep(at, t0.j)).filter(function (x) { return x.v === t * nb; })[0];
          if (an && (lineAt(an.j, nb + 1) || skipSep(at, an.j) >= at.length)) { out.push({ b: nb, said: an.v }); i = an.j; prevB = nb; continue; } }
      }
      if (!bHit) { i++; continue; }
      var b = bHit.v, k = skipSep(at, bHit.j), hadUnk = false;
      for (var z = bHit.j; z < k; z++) if (at[z].unk) hadUnk = true;
      var best = null;
      var cand = function (from, pen) {
        readNums(at, from).forEach(function (c) {
          var nxt = lineAt(c.j, b + 1), any = nxt || lineAt(c.j, 0), end = skipSep(at, c.j) >= at.length;
          var sc = (c.v === t * b ? 2 : 0) + (nxt ? 4 : any ? 2 : end ? 3 : 0) + (c.j - k) * 0.1 - pen;
          if (!best || sc > best.sc) best = { v: c.v, j: c.j, sc: sc };
        });
      };
      cand(k, 0);
      /* v33 (Vihaan's real recording 01-Nov 22:34: "two six two twelve"): a fast "za" is often heard as "two" / "to" - try the answer
         after one such word too */
      if (k < at.length && !at[k].sep && !at[k].unk && (at[k].v === 2 || at[k].v === t)) cand(skipSep(at, k + 1), 0.5);
      if (best && (best.sc >= 2 || !lineAt(k, 0))) {
        /* "twenty" said fast is heard as "into ten" / "into four" (22:35 "two ten into ten"): not wrong - ask that line again */
        var fz = best.v !== t * b && k > 0 && at[k - 1].sep && at[k - 1].w === 'into' && t * b >= 20 && t * b < 30 && (best.v === 10 ? t * b === 20 : best.v === t * b - 20);
        /* out of order + the answer is the NEXT line's (heard "one two into seven" where he said "one seven za seven"): the line number was misheard */
        if (b !== prevB + 1 && prevB + 1 <= up && best.v !== t * b && best.v === t * (prevB + 1)) b = prevB + 1;
        out.push(fz ? { b: b, said: best.v, fz: true } : { b: b, said: best.v }); i = best.j; }
      else { out.push({ b: b, said: null, unk: hadUnk }); i = k; }
      prevB = b;
    }
    return out;
  };
  /* check a recitation of table t (1 .. up): {ok, wrong:[{b, said}], missing:[b], done:[b...], order} */
  C.checkRecite = function (text, t, up) {
    var facts = C.parseRecite(text, t, up), seen = {}, wrong = [], done = [];
    /* he goes back and says lines again (log 21:46: ... one seven seven, one five za five, one six six ...): his LATEST version of each line counts */
    /* v45 (user, 03-Nov: "3 x 8 = 24, he says it, it is not taken" - the engine heard "three ONE twenty four", "three za into twenty four"): the line
       number is the part it loses; an answer above the table's range (12, 15, 18 ... in table 3) is unique to ONE line, so a heard answer
       that belongs to another line is that line's answer, and a line whose answer is heard anywhere counts */
    var big = {}; for (var bb = 1; bb <= up; bb++) { var vv = t * bb; if (vv > up && vv !== t) big[vv] = bb; }
    var raw = facts; facts = [];
    raw.forEach(function (f, k) {
      if (f.said !== null && f.said !== t * f.b && big[f.said]) {          /* "three ONE twenty four": the answer belongs to line 8, between its neighbours in the order he said them */
        var b2 = big[f.said], pb = facts.length ? facts[facts.length - 1].b : 0, nb = raw[k + 1] ? raw[k + 1].b : up + 1;
        if (pb < b2 && b2 < nb) { facts.push({ b: b2, said: f.said, re: 1 }); return; }
      }
      facts.push(f);
    });
    var last = {}; facts.forEach(function (f) { if (f.said !== null || last[f.b] === undefined) last[f.b] = f; });
    facts = Object.keys(last).map(function (b) { return last[b]; }).sort(function (a, b) { return a.b - b.b; });
    facts.forEach(function (f) {
      if (f.b < 1 || f.b > up) return;
      var right = f.said === t * f.b;
      if (seen[f.b] === undefined || right) seen[f.b] = right;
      if (!right && f.said !== null && wrong.filter(function (w) { return w.b === f.b; }).length === 0) wrong.push({ b: f.b, said: f.said });
      if (right) done.push(f.b);
    });
    wrong = wrong.filter(function (w) { return !seen[w.b]; });
    /* v48: line 1 (table x 1 = the table) is the one everybody knows - never asked about, whatever the engine heard */
    if (seen[1] === undefined || seen[1] === false) { seen[1] = true; wrong = wrong.filter(function (w) { return w.b !== 1; }); done.push(1); }
    var missing = []; for (var b = 1; b <= up; b++) if (seen[b] === undefined) missing.push(b);
    var noAns = facts.filter(function (f) { return f.said === null && !seen[f.b]; }).map(function (f) { return f.b; });
    /* fifteen / fifty, thirteen / thirty ... : the engine can mix them up - ask him to say that line again instead of "wrong" */
    var mix = function (x, y) { for (var d = 3; d <= 9; d++) if ((x === 10 + d && y === 10 * d) || (y === 10 + d && x === 10 * d)) return true; return false; };
    var fzB = {}; facts.forEach(function (f) { if (f.fz) fzB[f.b] = 1; });
    /* v43 (his real table-3 recitation 02-Nov 21:18-21:20: "thirty three" for 3, "one" for twelve, "ten" for fifteen - he said it right):
       an answer that is ONE digit away from the right one (3 / 33, 12 / 1, 15 / 10, 21 / 24 ...) cannot be told from a mishearing, so it is
       "unsure" - that line is asked again alone - never "wrong" */
    var alike = function (x, y) {
      var a = String(x), b = String(y); if (a === b) return true; if (mix(x, y)) return true;
      var d = []; for (var i = 0; i <= a.length; i++) d[i] = [i]; for (var j = 1; j <= b.length; j++) d[0][j] = j;
      for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++) d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
      return d[a.length][b.length] <= 1 || (a.length > 1 && b.length > 1 && a.slice(0, -1) === b.slice(0, -1) && Math.abs(+a.slice(-1) - +b.slice(-1)) <= 3 && false);
    };
    /* v45 (user, 03-Nov: "it is the software not hearing, not his mistake"): the long recitation is the LEAST reliable listening (slow speech, pauses,
       misheard numbers, lines said twice). It never says "wrong" any more: every doubtful line is asked again alone - a short question with only
       the right answers allowed, where the hearing is good - and THAT decides. */
    var unsure = wrong.slice(), sure = [];
    return { ok: !wrong.length && !missing.length && !noAns.length, wrong: sure, unsure: unsure, missing: missing, unclear: noAns, done: done, facts: facts };
  };
  C.numWord = function (n) {
    var W = 'zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen'.split(' '),
      T = { 2: 'twenty', 3: 'thirty', 4: 'forty', 5: 'fifty', 6: 'sixty', 7: 'seventy', 8: 'eighty', 9: 'ninety' };
    if (n < 20) return W[n];
    if (n < 100) return T[Math.floor(n / 10)] + (n % 10 ? ' ' + W[n % 10] : '');
    return C.numWord(Math.floor(n / 100)) + ' hundred' + (n % 100 ? ' ' + C.numWord(n % 100) : '');
  };
  /* the words the offline engine may hear: numbers up to 999 by parts + the ways children join a line; phrases of one table help it follow fast speech */
  /* v34 (user, 01-Nov-2026: "while I was telling 12 the app was not able to recognise it at all" - 2×6 heard as "one" 3 times):
     one question = only the answers that make sense for it (right one, near misses, neighbours in the table), the question said back
     ("two six ja twelve") and the commands. With every number allowed, a fast "twelve" came out as "one" / "two" / nothing. */
  C.qGrammar = function (a, b) {
    var p = a * b, ns = {}, ph = [], W = C.numWord;
    [p, p - a, p + a, p - b, p + b, p - 1, p + 1, p - 2, p + 2, p - 10, p + 10, a + b].forEach(function (n) { if (n >= 0 && n <= 999) ns[n] = 1; });
    var q = W(a) + ' ' + W(b) + ' ';
    Object.keys(ns).forEach(function (n) { var w = W(+n); ph.push(w, q + w, q + 'ja ' + w, q + 'into ' + w, 'ja ' + w, a + b === +n ? w : 'is ' + w); });
    /* v63 (08-Nov, TV: he said "twenty one" for 9 x 3 and the app heard "twenty seven" = right): a grammar that holds only the right answer and its neighbours
       forces ANY number onto the nearest one. Every number 1-100 is now allowed as a bare answer (and after the line), so a different number is heard as it is. */
    for (var m = 1; m <= 100; m++) if (!ns[m]) { var wm = W(m); ph.push(wm, 'ja ' + wm, q + wm, q + 'ja ' + wm); }
    ph = ph.concat(W(a).split(' '), W(b).split(' '), ['ja', 'za', 'times', 'ready', 'yes', 'stop', 'repeat', '[unk]']);
    return JSON.stringify(ph.filter(function (x, i) { return ph.indexOf(x) === i; }));
  };
  C.grammar = function (t, up) {
    var g = 'zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty thirty forty fifty sixty seventy eighty ninety hundred'.split(' ');
    if (t) {   /* testing one table: only its words - fewer look-alikes (four / forty, two / into) - plus the usual wrong answers */
      var nums = {}, add = function (n) { if (n >= 0 && n <= 999) C.numWord(n).split(' ').forEach(function (w) { nums[w] = 1; }); };
      add(t); for (var b = 1; b <= up; b++) { add(b); add(t * b); add(t * b + t); add(t * b - t); add(t * b + 1); add(t * b - 1); add(t * b + 10); add(t * b - 10); }
      g = Object.keys(nums);
    }
    g = g.concat(['ja', 'za', 'into', 'times', 'is', 'equals', 'ready', 'yes', 'stop']);
    if (t) for (var b = 1; b <= up; b++) { var tb = C.numWord(t) + ' ' + C.numWord(b) + ' ', a = C.numWord(t * b); g.push(tb + 'ja ' + a); g.push(tb + 'into ' + a); g.push(tb + a); }   /* fast: no "ja" */
    g.push('[unk]');
    return JSON.stringify(g);
  };

  /* all of Google's guesses: right when the best guess is right, or when the best guess had no clear number and another guess is right */
  /* an answer one digit away from the right one (70 / 170, 43 / 63, 15 / 10, 33 / 3) cannot be told from a mishearing */
  /* v50 (user, 03-Nov: "I want it to say Aryan properly - it sounds 'Arien'"): how the voice should SAY a name. A parent can set it per child
     (settings -> "How to say the name"); these are the built-in defaults (spelling the voice reads right, shown on screen as normal) */
  C.NAME_SAY = { aryan: 'Aar yun' };
  C.sayName = function (text, kids) {
    var t = String(text || '');
    (kids || []).forEach(function (k) {
      if (!k || !k.name) return;
      var nm = String(k.name).trim(), say = (k.say && String(k.say).trim().toLowerCase() !== nm.toLowerCase()) ? String(k.say).trim() : C.NAME_SAY[nm.toLowerCase()];   /* typing the name itself = not set */
      if (say) t = t.replace(new RegExp('\\b' + String(k.name).trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b', 'gi'), say);
    });
    return t;
  };
  /* v52 (Aryan's class, 03-Nov: "it says 2 one 3 za but it is 21 3 za"): the voice read "21 3 ja" digit by digit, the child answered what he heard ("one three ja
     sixty three"). Every number in a spoken line goes out as WORDS, and the table number and the line number are split by a comma (a short pause):
     "21 3 ja 63" -> "twenty one, three ja sixty three" */
  C.speakNums = function (text) {
    var t = String(text || '').replace(/(\d+) (\d+)/g, '$1, $2');     /* two numbers side by side = a table line: pause between them */
    return t.replace(/(^|[^\w.])(\d{1,3})(?![\w])/g, function (m, pre, n) { return pre + C.numWord(+n); });
  };
  C.numAlike = function (x, y) {
    var a = String(x), b = String(y); if (a === b) return true;
    for (var d = 3; d <= 9; d++) if ((x === 10 + d && y === 10 * d) || (y === 10 + d && x === 10 * d)) return true;
    var m = []; for (var i = 0; i <= a.length; i++) m[i] = [i]; for (var j = 1; j <= b.length; j++) m[0][j] = j;
    for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++) m[i][j] = Math.min(m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    return m[a.length][b.length] <= 1;
  };
  /* v54 (Aryan's log 21:41-21:44: "nine" for 88, "sixty" for 161, "seventy" for 170): a heard answer far smaller than the right one is the engine dropping
     the first words ("eighty", "one hundred"), not a mistake -> asked once more */
  C.numTruncated = function (n, ans) { return n !== null && n < ans && ((ans >= 100 && n < 100) || (ans >= 20 && n < 10) || (ans >= 30 && n <= ans / 4)); };
  C.tableJudge = function (alts, a, b) {
    alts = (alts || []).filter(Boolean);
    var first = alts.length ? C.tableOne(alts[0], a, b) : { n: null, ok: false };
    if (first.ok) return { ok: true, n: first.n, s: alts[0] };
    for (var i = 1; i < alts.length; i++) { var r = C.tableOne(alts[i], a, b); if (r.ok && first.n === null) return { ok: true, n: r.n, s: alts[i] }; }
    if (first.n === null) for (var j = 1; j < alts.length; j++) { var r2 = C.tableOne(alts[j], a, b); if (r2.n !== null) return { ok: false, n: r2.n, s: alts[j] }; }
    var altOk = alts.slice(1).some(function (x) { return C.tableOne(x, a, b).ok; });   /* another guess was right: ask again ("Did you say 72?") */
    return { ok: false, n: first.n, s: alts[0] || '', altOk: altOk };
  };

  var STOP = ' a an the is are was were be of to in on at for and or it its this that these those with by as from i we you he she they my our your his her their do does did has have had will can so but not no yes what which who whom why how when where there here '.split(' ');
  function words(s) { return String(s || '').toLowerCase().replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter(Boolean); }
  C.words = words;
  function lev(a, b) {
    if (Math.abs(a.length - b.length) > 2) return 9;
    var d = [], i, j; for (i = 0; i <= a.length; i++) d[i] = [i];
    for (j = 1; j <= b.length; j++) d[0][j] = j;
    for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++)
      d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    return d[a.length][b.length];
  }
  function near(w, list) {
    for (var i = 0; i < list.length; i++) {
      var x = list[i];
      if (x === w) return true;
      if (w.length >= 4 && (x.indexOf(w) === 0 || w.indexOf(x) === 0) && Math.min(x.length, w.length) >= 4) return true;  /* plant / plants */
      if (w.length >= 5 && lev(w, x) <= 1) return true;
      if (w.length >= 8 && lev(w, x) <= 2) return true;
    }
    return false;
  }
  /* key words of an answer: the parent's keywords, else the answer's main words */
  C.keysOf = function (item) {
    if (item.k) return String(item.k).split(',').map(function (s) { return s.trim().toLowerCase(); }).filter(Boolean);
    var w = words(item.a).filter(function (x) { return STOP.indexOf(x) < 0; });
    return w.length ? w : words(item.a);
  };
  /* oral answer check: parent's keywords -> every one must be said; else 70% of the main words */
  C.checkOral = function (item, said) {
    var got = words(said), keys = C.keysOf(item), hit = [], miss = [];
    var nums = C.numbers(said, true);
    keys.forEach(function (k) {
      var ok = k.split(' ').every(function (p) { return /^\d+$/.test(p) ? nums.indexOf(+p) >= 0 || got.indexOf(p) >= 0 : near(p, got) || (ONES[p] !== undefined && nums.indexOf(ONES[p]) >= 0); });
      (ok ? hit : miss).push(k);
    });
    var need = item.k ? keys.length : Math.max(1, Math.ceil(keys.length * 0.7));
    return { ok: hit.length >= need, hit: hit, miss: miss };
  };
  /* spelling: "b e c a u s e" / "bee see ..." -> letters */
  var LET = { ay: 'a', eh: 'a', bee: 'b', be: 'b', see: 'c', sea: 'c', she: 'c', dee: 'd', de: 'd', ee: 'e', ef: 'f', eff: 'f', gee: 'g', ji: 'g', jee: 'g',
    aitch: 'h', edge: 'h', haitch: 'h', eye: 'i', aye: 'i', jay: 'j', kay: 'k', okay: 'k', el: 'l', elle: 'l', em: 'm', en: 'n', oh: 'o', owe: 'o',
    pee: 'p', pea: 'p', cue: 'q', queue: 'q', are: 'r', ar: 'r', es: 's', ess: 's', tea: 't', tee: 't', you: 'u', yu: 'u', vee: 'v', why: 'y',
    ex: 'x', zed: 'z', zee: 'z', zet: 'z', ah: 'a', hey: 'a', bi: 'b', si: 'c', pe: 'p', ti: 't', vi: 'v', ze: 'z', jai: 'j', kai: 'k', ell: 'l', double: 'w' };
  C.letters = function (said, word) {
    word = String(word || '').toLowerCase().replace(/[^a-z]/g, '');
    var w = String(said || '').toLowerCase().replace(/double u|double you/g, 'w').replace(/[^a-z ]/g, ' ').split(/\s+/).filter(Boolean);
    var allOne = w.length > 1 && w.every(function (x) { return x.length === 1 || LET[x]; });
    if (w.length === 1 && w[0] === word && word.length > 1) return { whole: true, text: w[0] };     /* said the word, not the letters */
    var s = '';
    w.forEach(function (x) { if (x.length === 1) s += x; else if (LET[x] && (allOne || w.length > 2)) s += LET[x]; else if (x === 'capital' || x === 'small') return; else s += x; });
    return { whole: false, text: s };
  };
  C.checkSpell = function (word, said) {
    var r = C.letters(said, word), want = String(word).toLowerCase().replace(/[^a-z]/g, '');
    return { ok: !r.whole && r.text === want, whole: r.whole, got: r.text };
  };
  /* v35 (user, 01-Nov-2026: "when I spell it takes 'you' ... so much misunderstanding in the Evs class"): spelling is judged here.
     Letters that SOUND alike (b d p t v c e g z / m n / f s x / a j k / i y / u q) cannot be told apart safely by any engine: if every
     difference is such a pair the answer is "unsure" (ask him to say it again), never "wrong". */
  /* v36 (log 02-Nov 08:20: "we were in yes b o n e s" counted as wrong): when spelling, ONLY letters count - every other word the engine
     hears (room talk, "yes", "huh", the speaker's own voice) is dropped */
  C.letterSeq = function (said) {
    var w = String(said || '').toLowerCase().replace(/double u|double you/g, 'w').replace(/[^a-z ]/g, ' ').split(/\s+/).filter(Boolean), s = '';
    w.forEach(function (x) { if (x.length === 1) s += x; else if (LET[x]) s += LET[x]; });
    return s;
  };
  var SIM = ['bdptvcegz', 'mn', 'fsx', 'ajk', 'iy', 'uq'];
  function simL(a, b) { for (var i = 0; i < SIM.length; i++) if (SIM[i].indexOf(a) >= 0 && SIM[i].indexOf(b) >= 0) return true; return false; }
  /* v38 (his real recordings 02-Nov 08:39-08:40, "for n it tells 'en', all wrong"): N is said "en" and the engine returns "e" + "en", or
     [unk], or "i". So the heard tokens are ALIGNED to the target word: a letter token that matches costs 0, a sound-alike 0.5, [unk]
     can be any one letter (0.3), an extra "e" before "en" 0.2, other extra tokens 0.6, a missing letter 1, a clearly different letter 1.5.
     total <= 1: right; <= 2.6 (or anything with [unk]): unsure -> say it again; else wrong. */
  function spellTokens(said) {
    var w = String(said || '').toLowerCase().replace(/double u|double you/g, 'w').replace(/\[unk\]/g, ' ? ').replace(/[^a-z? ]/g, ' ').split(/\s+/).filter(Boolean), t = [];
    w.forEach(function (x) { if (x === '?') t.push({ u: 1 }); else if (x.length === 1) t.push({ c: x }); else if (LET[x]) t.push({ c: LET[x] }); });
    return t;
  }
  function spellCost(t, want) {
    var n = t.length, m = want.length, D = [], i, j;
    function extra(k) { var x = t[k]; if (x.u) return 0.2; if (x.c === 'e' && t[k + 1] && t[k + 1].c && 'mnflsx'.indexOf(t[k + 1].c) >= 0) return 0.2; return 0.6; }   /* em / en / ef / el / es / ex come back as "e" + the letter */
    function sub(k, c) { var x = t[k]; if (x.u) return 0.3; if (x.c === c) return 0; if (simL(x.c, c) || (x.c === 'e' && 'mnflsx'.indexOf(c) >= 0)) return 0.5; return 1.5; }
    for (i = 0; i <= n; i++) { D[i] = []; for (j = 0; j <= m; j++) D[i][j] = 0; }
    for (j = 1; j <= m; j++) D[0][j] = j * 1.2;
    for (i = 1; i <= n; i++) D[i][0] = D[i - 1][0] + extra(i - 1);
    for (i = 1; i <= n; i++) for (j = 1; j <= m; j++) D[i][j] = Math.min(D[i - 1][j - 1] + sub(i - 1, want[j - 1]), D[i - 1][j] + extra(i - 1), D[i][j - 1] + 1.2);
    return D[n][m];
  }
  C.spellJudge = function (word, alts) {
    var want = String(word).toLowerCase().replace(/[^a-z]/g, ''), best = null;
    (alts || []).forEach(function (said) {
      var low = String(said || '').toLowerCase();
      if (C.letters(said, want).whole || (!/[a-z]/.test(low.replace(/\[unk\]/g, '')) ? false : low.replace(/\[unk\]/g, ' ').split(/\s+/).indexOf(want) >= 0 && !spellTokens(said).length)) { if (!best) best = { kind: 'whole', got: want }; return; }
      var t = spellTokens(said); if (!t.length) return;
      var cost = spellCost(t, want);
      /* he may say it twice or talk before / after: the best stretch of about the word's length counts (small price for the rest) */
      for (var lo = 0; lo < t.length; lo++) for (var ln = Math.max(1, want.length - 2); ln <= want.length + 2 && lo + ln <= t.length; ln++) if (ln < t.length) cost = Math.min(cost, spellCost(t.slice(lo, lo + ln), want) + 0.3);
      var hasU = t.some(function (x) { return x.u; }), got = t.map(function (x) { return x.u ? '?' : x.c; }).join('');
      var kind = cost < 1.0 ? 'ok' : (cost <= 3.4 || hasU || t.length < want.length * 0.6) ? 'unsure' : 'wrong';
      var rank = { ok: 3, unsure: 2, wrong: 1, whole: 0 };
      if (!best || rank[kind] > rank[best.kind] || (kind === best.kind && cost < best.cost)) best = { kind: kind, got: kind === 'ok' ? want : got, cost: Math.round(cost * 10) / 10, alike: kind === 'ok' && got !== want };
    });
    return best || { kind: 'none', got: '' };
  };
  /* the parent says a word from the list (any order): which one? exact, else nearest (1 letter off) */
  C.pickWord = function (said, words) {
    var toks = String(said || '').toLowerCase().replace(/[^a-z ]/g, ' ').split(/\s+/).filter(Boolean), best = null;
    function ed(a, b) { var d = []; for (var i = 0; i <= a.length; i++) { d[i] = [i]; } for (var j = 1; j <= b.length; j++) d[0][j] = j;
      for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++) d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)); return d[a.length][b.length]; }
    words.forEach(function (w) { var lw = String(w).toLowerCase(); toks.forEach(function (t) { var e = t === lw ? 0 : (t.length > 3 && ed(t, lw) <= 1 ? 1 : 9); if (e < 9 && (!best || e < best.e)) best = { w: w, e: e }; }); });
    return best ? best.w : null;
  };
  /* v37 (his real recordings 02-Nov): with the free engine "b o n e s" came out "b o in a yes" (n -> "in", e -> "a", s -> "yes") and the
     room talk came out as words; with ONLY letter names allowed it is "bee owe n e s" and the talk becomes [unk]. */
  var LNAME = { a: 'ay', b: 'bee', c: 'see', d: 'dee', e: 'e', f: 'ef', g: 'gee', h: 'aitch', i: 'eye', j: 'jay', k: 'kay', l: 'el', m: 'em', n: 'en', o: 'oh', p: 'pee', q: 'queue', r: 'are', s: 'ess', t: 'tea', u: 'you', v: 'vee', w: 'double', x: 'ex', y: 'why', z: 'zee' };
  C.spellGrammar = function (word) {
    var g = 'a b c d e f g h i j k l m n o p q r s t u v w x y z bee see sea dee gee jay kay oh pee queue are tea you vee why ex zee zed eh eye aye owe okay ay ess em en el ef double ah skip next'.split(' ');
    (Array.isArray(word) ? word : [word]).forEach(function (wd) {
      var L = String(wd || '').toLowerCase().replace(/[^a-z]/g, '').split(''); if (L.length < 2) return;
      g.push(L.join(' ')); g.push(L.map(function (c) { return LNAME[c]; }).join(' ')); g.push(L.map(function (c, i) { return i % 2 ? c : LNAME[c]; }).join(' ')); g.push(L.map(function (c, i) { return i % 2 ? LNAME[c] : c; }).join(' '));   /* the spelled word itself helps the engine hold on to the letters */
    });
    g.push('[unk]');
    return JSON.stringify(g.filter(function (x, i, a) { return a.indexOf(x) === i; }));
  };
  /* parent says a word, the child spells: which word of the list was it? the one the letters fit best */
  C.spellWhich = function (words, said) {
    var best = null; words.forEach(function (w) { var j = C.spellJudge(w, [said]); if (j.kind === 'none' || j.kind === 'whole') return; if (!best || j.cost < best.j.cost) best = { w: w, j: j }; });
    return best;
  };
  /* v40 (his 09:15 recordings: the live letters showed "e s" / "e m" for S / M, he thought it was wrong, pressed Clear in the middle of the
     word): while he spells, only letters that FIT the target word are shown (a dot for the rest) - raw engine noise is never shown */
  C.liveLetters = function (said, word) {
    var want = String(word || '').toLowerCase().replace(/[^a-z]/g, ''), t = spellTokens(said), out = [], p = 0, i;
    if (!want) return t.filter(function (x) { return !(x.c === 'e'); }).map(function () { return '.'; }).join('');
    for (i = 0; i < want.length; i++) out.push('.');
    for (i = 0; i < t.length && p < want.length; i++) {
      var x = t[i];
      if (x.u) { p++; continue; }
      if (x.c === want[p] || simL(x.c, want[p])) { out[p] = want[p]; p++; }
      else if (x.c === 'e' && t[i + 1] && t[i + 1].c && 'mnflsx'.indexOf(t[i + 1].c) >= 0) continue;
      else if (p + 1 < want.length && (x.c === want[p + 1] || simL(x.c, want[p + 1]))) { out[p + 1] = want[p + 1]; p += 2; }
    }
    return out.join('');
  };
  /* v41 (user, 02-Nov-2026: "pop up what it is reading, marked"): what the engine heard, cleaned of the "e" + letter splits and marked against
     the target: st 'g' = the letter fits, 'a' = sound-alike (accepted), 'x' = a different letter, 'u' = not understood, 'n' = no target */
  C.heardView = function (said, word) {
    var want = String(word || '').toLowerCase().replace(/[^a-z]/g, ''), t = spellTokens(said), out = [], p = 0;
    for (var i = 0; i < t.length; i++) {
      var x = t[i];
      if (x.u) { out.push({ c: '?', st: 'u' }); p++; continue; }
      if (!want) { if (x.c === 'e' && t[i + 1] && t[i + 1].c && 'mnflsx'.indexOf(t[i + 1].c) >= 0) continue; out.push({ c: x.c, st: 'n' }); continue; }
      if (p < want.length && x.c === want[p]) { out.push({ c: x.c, st: 'g' }); p++; }
      else if (p < want.length && simL(x.c, want[p])) { out.push({ c: x.c, st: 'a' }); p++; }
      else if (x.c === 'e' && t[i + 1] && t[i + 1].c && 'mnflsx'.indexOf(t[i + 1].c) >= 0) continue;
      else if (p + 1 < want.length && (x.c === want[p + 1] || simL(x.c, want[p + 1]))) { out.push({ c: x.c, st: x.c === want[p + 1] ? 'g' : 'a' }); p += 2; }
      else { out.push({ c: x.c, st: 'x' }); if (t[i + 1] && !t[i + 1].u && p + 1 < want.length && t[i + 1].c === want[p + 1]) p++; }
    }
    return out;
  };
  C.isSkip = function (said) { return /\b(skip|next|pass)\b/.test(String(said || '').toLowerCase()); };
  C.wordGrammar = function (words) { return JSON.stringify(words.map(function (w) { return String(w).toLowerCase(); }).concat(['stop', 'finish', '[unk]'])); };
  /* yes / ready / start words */
  C.isReady = function (t) { return /\b(ready|yes|yeah|yup|start|ok|okay|i am here|i'm here|here|come|coming|let's go|lets go|go)\b/i.test(t || ''); };
  C.isStop = function (t) { return /\b(stop|finish|end class|bye|goodbye|quit|enough)\b/i.test(t || ''); };
  C.isRepeat = function (t) { return /\b(repeat|again|what|pardon|sorry|didn't hear|did not hear)\b/i.test(t || ''); };

  /* ---------- lessons typed by parents ---------- */
  /* oral: one per line "Question = Answer" (optional "| key, words"); spelling: one word per line (optional "= sentence") */
  C.parseItems = function (type, text) {
    return String(text || '').split('\n').map(function (l) { return l.trim(); }).filter(Boolean).map(function (l) {
      var k = '', s = l, bar = l.indexOf('|');
      if (bar >= 0) { k = l.slice(bar + 1).trim(); s = l.slice(0, bar).trim(); }
      var eq = s.indexOf('=');
      if (type === 'spell') {
        var word = (eq >= 0 ? s.slice(0, eq) : s).trim(), sen = eq >= 0 ? s.slice(eq + 1).trim() : '';
        return word ? { q: word, a: word.toLowerCase(), s: sen } : null;
      }
      if (eq < 0) { var qm = s.indexOf('?'); if (qm < 0 || qm === s.length - 1) return { q: s, a: '', bad: true }; eq = qm; return { q: s.slice(0, qm + 1).trim(), a: s.slice(qm + 1).trim(), k: k }; }
      return { q: s.slice(0, eq).trim(), a: s.slice(eq + 1).trim(), k: k };
    }).filter(function (x) { return x; });
  };
  C.itemsToText = function (type, items) {
    return (items || []).map(function (it) {
      if (type === 'spell') return it.q + (it.s ? ' = ' + it.s : '');
      return it.q + ' = ' + it.a + (it.k ? ' | ' + it.k : '');
    }).join('\n');
  };
  C.setActive = function (set, kidId, dayKey) {
    if (!set || set.off) return false;
    if (set.who && set.who !== 'all' && set.who !== kidId) return false;
    if (set.until && dayKey > set.until) return false;
    return true;
  };
  C.typeName = function (t) { return t === 'spell' ? 'Spelling' : 'Oral questions'; };
  C.esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); };

  /* ---------- diagnostics log (user, 01-Nov-2026: "read the log from the TV, child and parent apps so you can decide the problem") ----------
     Every app writes short lines to DB3 homeclass/<fam>/diag/<deviceId>/<YYYY-MM-DD>/<id> {t, m, l?} (+ diag/<dev>/info), in batches
     every 15 s (errors at once), max 800 lines per device per day; the Android app adds its own lines (HCA.takeLog). Read them in the
     parent app (Settings -> 🩺 Diagnostics, 📋 Copy) or with the davan-student-news "DB3 peek" job. Kept 14 days (C.diagClean). */
  var DQ = [], dTimer = null;
  C.diagInfo = {};
  C.diag = function (msg, lvl) {
    var e = { t: Date.now(), m: String(msg).slice(0, 500) }; if (lvl) e.l = lvl;
    var ring = LS.get('hc_diag', []); ring.push(e); var cut = Date.now() - 864e5; ring = ring.filter(function (x) { return x.t > cut; }); if (ring.length > 1500) ring = ring.slice(-1500); LS.set('hc_diag', ring);
    var cnt = LS.get('hc_diagn', {}); if (cnt.d !== C.day()) cnt = { d: C.day(), n: 0 };
    if (cnt.n >= 800 && lvl !== 'e') return;
    cnt.n++; LS.set('hc_diagn', cnt);
    DQ.push(e);
    if (!dTimer) dTimer = setTimeout(C.diagFlush, lvl === 'e' ? 1500 : 15000);
  };
  C.diagFlush = function () {
    dTimer = null;
    /* v39: app h28 writes "mic: no sound ... reopened it" every 1.5 s on the TV - 70+ lines a class filled the 800-lines-a-day log (08-Nov: the screen's own
       lines stopped at 22:55). Those lines are counted and sent as ONE summary line per flush. */
    if (window.HCA && window.HCA.takeLog) { try { var reo = 0, reoT = 0; JSON.parse(window.HCA.takeLog() || '[]').forEach(function (e) { if (/reopened it/.test(e.m)) { reo++; reoT = e.t; return; } e.m = '📱 ' + e.m; DQ.push(e); });
      if (reo) DQ.push({ t: reoT, m: '📱 mic: no sound - reopened ' + reo + ' times (TV remote asleep)' }); } catch (x) {} }
    if (!DQ.length || !C.fam() || !navigator.onLine) { if (DQ.length) dTimer = setTimeout(C.diagFlush, 30000); return; }
    var batch = {}, part = DQ.splice(0, 80);
    part.forEach(function (e) { batch[pushId()] = e; });
    fetch(C.DB + 'homeclass/' + C.fam() + '/diag/' + C.devId() + '/' + C.day() + '.json', { method: 'PATCH', body: JSON.stringify(batch) })
      .then(function (r) { if (!r.ok) throw new Error(r.status); }).catch(function () { DQ = part.concat(DQ); dTimer = setTimeout(C.diagFlush, 60000); });
    if (DQ.length && !dTimer) dTimer = setTimeout(C.diagFlush, 4000);
  };
  C.diagStart = function (kind, ver, extra) {
    C.diagInfo = { kind: kind, ver: ver, ua: navigator.userAgent.slice(0, 160), at: Date.now() };
    for (var x in extra || {}) C.diagInfo[x] = extra[x];
    C.diag('▶ open ' + kind + ' v' + ver + ' core v' + C.VER + ' · ' + JSON.stringify(extra || {}) + ' · online ' + navigator.onLine + ' · queued ' + Q.length);
    if (C.fam()) fetch(C.DB + 'homeclass/' + C.fam() + '/diag/' + C.devId() + '/info.json', { method: 'PUT', body: JSON.stringify(C.diagInfo) }).catch(function () {});
    window.addEventListener('error', function (e) { C.diag('JS error: ' + e.message + ' @' + String(e.filename || '').split('/').pop() + ':' + e.lineno, 'e'); });
    window.addEventListener('unhandledrejection', function (e) { C.diag('Promise error: ' + ((e.reason && e.reason.message) || e.reason), 'e'); });
    window.addEventListener('online', function () { C.diag('network: online'); });
    window.addEventListener('offline', function () { C.diag('network: OFFLINE'); });
    document.addEventListener('visibilitychange', function () { C.diag(document.hidden ? 'screen: hidden (app in background / screen off)' : 'screen: visible'); if (document.hidden) C.diagFlush(); });
    setInterval(function () { if (DQ.length) C.diagFlush(); }, 60000);
  };
  /* family moved (user had made 3 families by tapping "Start" on several phones, 01-Nov-2026): homeclass/<old>/moved = <new key>
     -> this device switches to the new family by itself and reloads. Returns true when it is switching. */
  C.checkMoved = function () {
    if (!C.fam()) return Promise.resolve(false);
    return C.get('moved').then(function (to) {
      if (typeof to === 'string' && to.length >= 24 && to !== C.fam()) {
        C.diag('family moved -> …' + to.slice(-4)); C.setFam(to); LS.del('hc_cfg'); LS.del('hc_sets');
        setTimeout(function () { location.reload(); }, 300); return true;
      }
      return false;
    }).catch(function () { return false; });
  };
  /* 🩺 this device's log, last 24 h (user, 01-Nov-2026: "keep the log on the phones and TV for 1 day, show only when I tap") */
  C.diagText = function () {
    var cut = Date.now() - 864e5, rows = {}, add = function (e) { if (e && e.t > cut) rows[e.t + '|' + e.m] = e; };
    LS.get('hc_diag', []).forEach(add);
    var days = [C.day(Date.now() - 864e5), C.day()];
    return Promise.all(days.map(function (d) { return C.get('diag/' + C.devId() + '/' + d).catch(function () { return null; }); })).then(function (r) {
      r.forEach(function (o) { Object.keys(o || {}).forEach(function (k) { add(o[k]); }); });
      var l = Object.keys(rows).map(function (k) { return rows[k]; }).sort(function (a, b) { return a.t - b.t; });
      return 'Home Class log · ' + (C.diagInfo.kind || '') + ' v' + (C.diagInfo.ver || '') + (C.diagInfo.app ? ' · app ' + C.diagInfo.app : '') + ' · last 24 h · ' + l.length + ' lines\n' +
        l.map(function (e) { var d = new Date(e.t + 5.5 * 36e5); return d.toISOString().slice(5, 10).replace('-', '/') + ' ' + d.toISOString().slice(11, 19) + (e.l === 'e' ? ' ❌ ' : e.l === 'w' ? ' ⚠️ ' : '  ') + e.m; }).join('\n');
    });
  };
  C.copyText = function (t, btn) {
    var ok = function () { if (btn) { var o = btn.textContent; btn.textContent = '✅ Copied'; setTimeout(function () { btn.textContent = o; }, 2000); } };
    (navigator.clipboard ? navigator.clipboard.writeText(t) : Promise.reject()).then(ok).catch(function () {
      var ta = document.createElement('textarea'); ta.value = t; document.body.appendChild(ta); ta.select(); try { document.execCommand('copy'); ok(); } catch (e) {} ta.remove(); });
  };
  C.diagClean = function () {
    var d = C.day(); if (LS.get('hc_diagclean', '') === d) return; LS.set('hc_diagclean', d);
    var cut = C.day(Date.now() - 14 * 864e5);
    C.get('diag', 'shallow=true').then(function (devs) {
      Object.keys(devs || {}).forEach(function (dv) {
        C.get('diag/' + dv, 'shallow=true').then(function (days) {
          var keys = Object.keys(days || {}).filter(function (k) { return k !== 'info'; });
          keys.forEach(function (k) { if (k < cut) C.del('diag/' + dv + '/' + k); });
          if (keys.length && !keys.some(function (k) { return k >= cut; })) C.del('diag/' + dv);
        }).catch(function () {});
      });
    }).catch(function () {});
  };

  /* ---------- auto-update (user, 01-Nov-2026: "as soon as you update, it should update by itself and show what is updating") ----------
     homeclass-ver.json on GitHub Pages {kid, par, kidApk, parApk, news:[{k:'kid'|'par'|'all', v, at, t}]} is checked every 60 s and when
     the app comes back to the screen. Newer page -> card "🆕 Updating…" with what changed -> reload (?v=new so no cache serves the old copy).
     Never during a class / while a lesson is being typed (busy()). Newer APK -> the app downloads + installs it (bridge.checkUpdate) and
     tells each step through window.hcUpd(state, info). After a reload: "✅ Updated" card with the news. */
  var VER_URL = 'https://harshgujjar.github.io/davan-attendance/homeclass-ver.json';
  function upCard(html, ms) {
    var c = document.getElementById('hcUpCard');
    if (!c) {
      c = document.createElement('div'); c.id = 'hcUpCard';
      c.style.cssText = 'position:fixed;left:50%;top:max(14px,env(safe-area-inset-top));transform:translateX(-50%);z-index:99;width:min(460px,92vw);' +
        'background:#22223b;color:#fff;border-radius:20px;padding:14px 16px;box-shadow:0 12px 36px rgba(0,0,0,.35);font:600 15px/1.45 Nunito,system-ui,sans-serif';
      document.body.appendChild(c);
    }
    c.innerHTML = html; c.style.display = '';
    clearTimeout(c._t); if (ms) c._t = setTimeout(function () { c.style.display = 'none'; }, ms);
    c.onclick = function () { c.style.display = 'none'; };
    if (!upCard._k) { upCard._k = 1; document.addEventListener('keydown', function (e) {   /* v38 (user, 08-Nov: "tap to close does not work on the TV"): any remote key closes it */
      var cc = document.getElementById('hcUpCard'); if (cc && cc.style.display !== 'none') { cc.style.display = 'none'; if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); e.stopPropagation(); } }
    }, true); }
  }
  C.upCard = upCard;
  function newsHTML(list) {
    if (!list.length) return '';
    return '<ul style="margin:8px 0 0;padding-left:18px">' + list.slice(0, 5).map(function (n) { return '<li>' + C.esc(n.t) + '</li>'; }).join('') + '</ul>';
  }
  function newsFor(v, kind, from, to) {
    return ((v && v.news) || []).filter(function (n) { return (n.k === kind || n.k === 'all') && n.v > from && n.v <= to; });
  }
  C.watchUpdate = function (kind, myVer, opt) {
    opt = opt || {};
    var bridge = opt.bridge, label = kind === 'kid' ? 'Home Class' : 'Home Class · Parents', pending = null, lastChk = 0, apkAsked = 0;
    /* just updated? say so once, with what changed */
    var seen = C.LS.get('hc_ver_' + kind, 0);
    if (seen && seen < myVer) {
      C.LS.set('hc_ver_' + kind, myVer);
      fetch(VER_URL + '?t=' + Date.now(), { cache: 'no-store' }).then(function (r) { return r.json(); }).then(function (v) {
        upCard('<b>✅ Updated to v' + myVer + '</b>' + newsHTML(newsFor(v, kind, seen, myVer)) + '<div style="opacity:.6;font-size:12px;margin-top:6px">Tap to close</div>', 12000);
      }).catch(function () { upCard('<b>✅ Updated to v' + myVer + '</b>', 5000); });
    } else if (!seen) C.LS.set('hc_ver_' + kind, myVer);
    function go(v) {
      if (opt.busy && opt.busy()) { pending = v; return; }
      pending = null;
      var tried = C.LS.get('hc_try_' + kind, {});                 /* never loop: one reload per new version per 10 min */
      if (tried.v === v[kind] && Date.now() - tried.at < 10 * 60000) return;
      C.LS.set('hc_try_' + kind, { v: v[kind], at: Date.now() });
      var news = newsFor(v, kind, myVer, v[kind]);
      upCard('<b>🆕 Updating ' + label + ' v' + myVer + ' → v' + v[kind] + '…</b>' + newsHTML(news) +
        '<div style="height:6px;background:rgba(255,255,255,.2);border-radius:9px;margin-top:10px;overflow:hidden"><i id="hcUpBar" style="display:block;height:100%;width:5%;background:#ffb703;transition:width 3.5s linear"></i></div>');
      setTimeout(function () { var b = document.getElementById('hcUpBar'); if (b) b.style.width = '100%'; }, 50);
      setTimeout(function () {
        var q = location.search.replace(/[?&]v=\d+/g, '').replace(/^&/, '?');
        location.replace(location.pathname + (q ? q + '&' : '?') + 'v=' + v[kind] + location.hash);
      }, 3800);
    }
    function check(force) {
      if (!force && (document.hidden || Date.now() - lastChk < 20000)) return;
      lastChk = Date.now();
      if (force) upCard('<b>🔎 Checking for updates…</b>', 0);
      fetch(VER_URL + '?t=' + Date.now(), { cache: 'no-store' }).then(function (r) { return r.json(); }).then(function (v) {
        var apkKey = kind + 'Apk';
        var appNew = bridge && bridge.ver && bridge.checkUpdate && v[apkKey] > bridge.ver();
        if (appNew && (force || Date.now() - Math.max(apkAsked, C.LS.get('hc_apkask', 0)) > 3 * 60000) && !(opt.busy && opt.busy())) {
          apkAsked = Date.now(); C.LS.set('hc_apkask', apkAsked);
          if (bridge.checkUpdateTo) bridge.checkUpdateTo(v[apkKey], v[apkKey + 'Name'] || ''); else bridge.checkUpdate();
          C.diag('update: app ' + bridge.ver() + ' -> ' + v[apkKey]);
          upCard('<b>📦 New app version found (' + C.esc(v[apkKey + 'Name'] || ('#' + v[apkKey])) + ')</b><br>Downloading… it installs by itself.', 8000);
        }
        if (v[kind] > myVer) { C.diag('update: page v' + myVer + ' -> v' + v[kind]); go(v); }
        else if (force) {   /* the button shows BOTH the screen and the app (user, 01-Nov: "it only says v27, it does not check h19") */
          var appNow = bridge && bridge.verName ? bridge.verName() : '';
          upCard(appNew ? '<b>✅ Screen v' + myVer + ' is up to date</b><br>📦 App ' + C.esc(appNow) + ' → ' + C.esc(v[apkKey + 'Name'] || '#' + v[apkKey]) + ': downloading now - it installs by itself' :
            '<b>✅ All up to date</b> · screen v' + myVer + (appNow ? ' · app ' + C.esc(appNow) : ''), appNew ? 10000 : 4000);
        }
      }).catch(function () { if (force) upCard('⚠️ Could not check for updates (offline?)', 4000); });
    }
    /* the app's update, step by step, on the screen (user, 01-Nov-2026: "show what is happening - downloading, installing ...") */
    window.hcUpd = function (st, info) {
      if (st !== 'progress' && st !== 'mprogress') C.diag('app update: ' + st + ' ' + (info || ''), st === 'failed' ? 'e' : '');
      var bar = function (pct) { return '<div style="height:8px;background:rgba(255,255,255,.2);border-radius:9px;margin-top:10px;overflow:hidden"><i style="display:block;height:100%;width:' + Math.max(3, pct) + '%;background:#ffb703;transition:width .6s"></i></div>'; };
      /* h23: the speech model (41 MB) downloads once on Wi-Fi - same card */
      if (st === 'mprogress') {
        var q = String(info || '').split('|');
        upCard('<b>🧠 Getting the listening (once)' + (+q[0] >= 0 ? ' · ' + q[0] + '%' : '') + '</b><div style="opacity:.75;font-size:13px">' + q[1] + (+q[2] ? ' of ' + q[2] : '') + ' MB · Google listens until it is ready</div>' + bar(+q[0] >= 0 ? +q[0] : 30), 0);
        return;
      }
      if (st === 'model') {
        var mt = { ready: '✅ Offline listening ready', wifi: '📶 The listening (41 MB, once) downloads when the phone is on Wi-Fi - Google listens until then', stopped: '⚠️ Listening download stopped - it continues by itself in 10 min', unpacking: '🧠 Unpacking the listening…' }[info];
        if (mt) upCard('<b>' + mt + '</b>', info === 'unpacking' ? 0 : 8000);
        return;
      }
      if (st === 'progress') {
        var p = String(info || '').split('|'), pct = +p[0], mb = +p[1], tot = +p[2], nm = p[3] || '';
        upCard('<b>📥 Downloading app ' + C.esc(nm) + (pct >= 0 ? ' · ' + pct + '%' : '') + '</b><div style="opacity:.75;font-size:13px">' + mb + (tot ? ' of ' + tot : '') + ' MB · keep the app open</div>' + bar(pct >= 0 ? pct : 30), 0);
        return;
      }
      var t = { checking: '🔎 Checking for an app update…', downloading: '📥 Downloading app ' + (info || '') + '…', uptodate: '✅ The app is up to date (' + (info || '') + ')',
        oldfile: '⏳ GitHub still has the old app file - trying again in 3 minutes by itself',
        installing: '📦 Installing the app update now… the app restarts by itself in a few seconds',
        'installing-tap': '📦 Installing the app update now… the app closes for a moment - tap the "✅ updated" notification (or the app icon) to open it again',
        tap: '👆 Android shows an "Update this app?" window - press UPDATE / INSTALL (only this first time). No window? Pull down the notifications → "Tap to install"',
        ready: (opt.busy && opt.busy()) ? '✅ App update downloaded - it installs as soon as this class ends' : '✅ App update downloaded - press the phone / TV HOME button once: it installs then',
        done: '✅ App updated', wifi: '📶 App update ' + (info || '') + ' waits for Wi-Fi (no mobile data used)', failed: '⚠️ App update: ' + (info || 'failed') + '' }[st] || st;
      var stay = st === 'downloading' || st === 'checking' || /^installing/.test(st);
      upCard('<b>' + C.esc(t).replace(/&quot;/g, '"') + '</b>' + (st === 'downloading' ? bar(2) : '') + '<div style="opacity:.6;font-size:12px;margin-top:6px">Tap to close</div>', stay ? 0 : 15000);
    };
    setInterval(function () { if (pending && !(opt.busy && opt.busy())) go(pending); else check(false); }, 60000);
    document.addEventListener('visibilitychange', function () { if (!document.hidden) check(false); });
    window.addEventListener('focus', function () { check(false); });
    setTimeout(function () { check(false); }, 4000);
    return { check: function () { check(true); }, retry: function () { if (pending) go(pending); } };
  };

  /* v40: the admin's family list (only the admin's phone can read it). Every device registers its family once a day at homeclass/<C.REG>/<id>:
     the family key + name are ENCRYPTED for the admin (ECDH P-256 + AES-GCM), so the list is useless to anyone else. */
  C.REG = 'hcreg-admin-family-list-encrypted-v1';   /* under homeclass/ (the existing DB3 rules allow 24+ character keys) - every value is encrypted */
  C.ADMIN_PUB = { kty: 'EC', crv: 'P-256', x: '6xVF-sTOmfFzgmQdWRcSAJHWSJH0Zh6n1fvaWHNIGxM', y: '5y_KX5FMfUMkSKZQdfj9_e0I6Je1C8F4BoytX-o3p14' };
  function b64(u8) { var s = ''; for (var i = 0; i < u8.length; i++) s += String.fromCharCode(u8[i]); return btoa(s); }
  C.register = function (cfg, role) {
    try {
      if (!C.fam() || !window.crypto || !crypto.subtle || !window.TextEncoder) return;
      var last = LS.get('hc_reg', {}); if (last.f === C.fam() && last.n === C.famName(cfg) && Date.now() - last.at < 864e5) return;
      var enc = new TextEncoder(), sub = crypto.subtle, fam = C.fam(), name = C.famName(cfg), id, pubK, eph, aes, iv, ct;
      sub.digest('SHA-256', enc.encode('hc:' + fam))
        .then(function (h) { id = Array.prototype.map.call(new Uint8Array(h), function (x) { return ('0' + x.toString(16)).slice(-2); }).join('').slice(0, 20);
          return sub.importKey('jwk', C.ADMIN_PUB, { name: 'ECDH', namedCurve: 'P-256' }, false, []); })
        .then(function (k) { pubK = k; return sub.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']); })
        .then(function (k) { eph = k; return sub.deriveBits({ name: 'ECDH', public: pubK }, eph.privateKey, 256); })
        .then(function (bits) { return sub.digest('SHA-256', bits); })
        .then(function (kraw) { return sub.importKey('raw', kraw, 'AES-GCM', false, ['encrypt']); })
        .then(function (k) { aes = k; iv = crypto.getRandomValues(new Uint8Array(12));
          return sub.encrypt({ name: 'AES-GCM', iv: iv }, aes, enc.encode(JSON.stringify({ f: fam, n: name, r: role || '', at: Date.now() }))); })
        .then(function (c) { ct = new Uint8Array(c); return sub.exportKey('jwk', eph.publicKey); })
        .then(function (ej) { return fetch(C.DB + 'homeclass/' + C.REG + '/' + id + '.json', { method: 'PUT', body: JSON.stringify(JSON.stringify({ x: ej.x, y: ej.y, i: b64(iv), c: b64(ct) })) }); })
        .then(function (r) { if (r.ok) LS.set('hc_reg', { f: fam, n: name, at: Date.now() }); else C.diag('register: DB ' + r.status, 'w'); })
        .catch(function (e) { C.diag('register: ' + e.message, 'w'); });
    } catch (e) {}
  };
  /* v40: 🆘 Report a problem - note (+ voice note) + the last log lines, to homeclass/<fam>/reports; the admin page shows the family 🔴 */
  C.ADMIN_WA = '919844542132';
  C.report = function (o) {
    var ring = (LS.get('hc_diag', []) || []).slice(-150).map(function (e) { return new Date(e.t).toTimeString().slice(0, 8) + ' ' + e.m; }).join('\n');
    var id = Date.now() + '_' + C.newKey(4);
    var r = { at: Date.now(), st: 'open', dev: C.devId(), devName: o.devName || '', who: o.who || '', note: String(o.note || '').slice(0, 1000),
      heard: String(o.heard || '').slice(0, 1000), aud: o.aud || null, recFrom: o.recFrom || 0, recTo: o.recTo || 0, ver: o.ver || '', app: o.app || '', model: o.model || '', log: ring.slice(-20000) };
    return fetch(C.url('reports/' + id), { method: 'PUT', body: JSON.stringify(r) }).then(function (x) { if (!x.ok) throw new Error('DB ' + x.status); C.diag('🆘 problem reported: ' + r.note.slice(0, 80)); return id; });
  };
  C.waLink = function (cfg, note) {
    var t = '🆘 Home Class' + (C.famName(cfg) ? ' - ' + C.famName(cfg) + ' family' : '') + ': ' + (note || 'I reported a problem in the app') + ' (…' + C.fam().slice(-4) + ')';
    return 'https://wa.me/' + C.ADMIN_WA + '?text=' + encodeURIComponent(t);
  };
})();
