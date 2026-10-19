/* Davan 🎯 Placement (v1, 18-Oct-2026) - one file shared by the student app (student_portal.html) and the staff app (index.html).
   Content: learn/bank.json (tracks -> levels -> lesson cards + questions, words, tips, Japanese words, speaking lines).
   Data (bank.db = DB4 lessonplan-archive now; change bank.json "db" to move to DB5, no app build):
     <root>/prog/<ID> {n, c, r, xp, st, ld, d, lv:{track:n}, best:{track_n:%}, sp}      one small row per learner
     <root>/log/<ID>/<push> {t, k, tr, l, s, of}                                          one row per finished practice / test / speak
     <root>/qs/<qid> {n, ok, p0..p3}   <root>/stats/<date>/{act/<ID>, q/<qid>/...}        counters (.sv increment)
     <root>/hide/<qid> true   <root>/qx/<qid> {q,o,a,e}                                     Super Admin: hide / edit a question
   PLC.open(el, {id, name, cls, role:'stu'|'stf', course:'BCA'|'BBA'|'BCOM'|'', preview:false, sa:false})
   preview = Super Admin looking at someone else: their real data is shown, nothing is written (user, 18-Oct). */
(function () {
  const VER = 3;   // bank cache key (content unchanged); v4 code = history mode (o.hist) for the student app
  const S = { bank: null, prog: null, o: null, el: null, v: 'home', a: {}, tok: null, tokExp: 0, hide: {}, qx: {} };
  const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const ist = (d) => new Date((d || Date.now()) + 330 * 60000).toISOString().slice(0, 10);
  const dayNo = () => Math.floor((Date.now() + 330 * 60000) / 864e5) - 20454;   // 0 on 1-Jan-2026
  const key = s => String(s || '').toUpperCase().replace(/[.#$\[\]\/\s]+/g, '_');
  const SA_ID = 'STF_HARSHA';

  // ── database (anonymous auth, REST) ──
  async function tok() {
    if (S.tok && Date.now() < S.tokExp) return S.tok;
    const k = 'plc_tok_' + S.bank.db.key.slice(-6);
    try { const c = JSON.parse(sessionStorage.getItem(k) || 'null'); if (c && c.exp > Date.now()) { S.tok = c.t; S.tokExp = c.exp; return S.tok; } } catch (e) {}
    const r = await fetch('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + S.bank.db.key, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"returnSecureToken":true}' });
    const j = await r.json(); S.tok = j.idToken; S.tokExp = Date.now() + 50 * 60000;
    try { sessionStorage.setItem(k, JSON.stringify({ t: S.tok, exp: S.tokExp })); } catch (e) {}
    return S.tok;
  }
  const url = (p, q) => S.bank.db.url + '/' + S.bank.db.root + '/' + p + '.json?' + (q ? q + '&' : '');
  async function get(p, q) { const r = await fetch(url(p, q) + 'auth=' + await tok()); if (!r.ok) throw new Error('read ' + r.status); return r.json(); }
  async function put(m, p, v) {
    if (S.o && S.o.preview) return;   // preview: never write someone else's record
    try { await fetch(url(p, 'print=silent') + 'auth=' + await tok(), { method: m, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(v) }); } catch (e) { console.warn('[plc]', e.message); }
  }
  const inc = { '.sv': { increment: 1 } };

  // ── bank ──
  async function loadBank() {
    if (S.bank) return;
    const ck = 'plc_bank_v' + VER;
    try { const c = JSON.parse(localStorage.getItem(ck) || 'null'); if (c && c.day === ist()) S.bank = c.b; } catch (e) {}
    if (!S.bank) {
      const base = (document.querySelector('script[src*="learn/placement.js"]') || {}).src || '';
      const r = await fetch(base.replace(/placement\.js.*$/, 'bank.json') + '?d=' + ist());
      S.bank = await r.json();
      try { localStorage.setItem(ck, JSON.stringify({ day: ist(), b: S.bank })); } catch (e) {}
    }
    try { const [h, x] = await Promise.all([get('hide'), get('qx')]); S.hide = h || {}; S.qx = x || {}; } catch (e) {}
  }
  const tracks = () => S.bank.tracks.filter(t => t.g !== 'tech' || !S.o.course || t.course === S.o.course || S.o.role === 'stf');
  const track = id => S.bank.tracks.find(t => t.id === id);
  const qOf = q => Object.assign({}, q, S.qx[q.id] || {});
  const qsOf = (t, l) => {
    if (l.pro) { const all = []; t.levels.filter(x => !x.pro).forEach(x => (x.qs || []).forEach(q => { if (!S.hide[q.id]) all.push(Object.assign({ tag: x.tag, lvn: x.name }, qOf(q))); })); return all.sort(() => Math.random() - .5).slice(0, 12); }
    return (l.qs || []).filter(q => !S.hide[q.id]).map(q => Object.assign({ lvn: l.name }, qOf(q)));
  };
  const allApt = () => { const o = []; S.bank.tracks.filter(t => t.g === 'apt').forEach(t => t.levels.filter(l => !l.pro).forEach(l => qsOf(t, l).forEach(q => o.push(Object.assign({ tr: t.id, tag: l.tag }, q))))); return o; };
  const today = () => { const n = dayNo(), b = S.bank, ap = allApt(); return { word: b.words[n % b.words.length], q: ap.length ? ap[(n * 7) % ap.length] : null, jp: b.jp[n % b.jp.length], tip: b.tips[n % b.tips.length] }; };

  // ── progress ──
  const P = () => S.prog || (S.prog = {});
  const lv = id => (P().lv || {})[id] || 0;
  function ready() {
    const a = (lv('quant') + lv('reason') + lv('verbal')) / 30 * 40, e = lv('english') / 10 * 30;
    const tt = S.bank.tracks.find(t => t.g === 'tech' && t.course === S.o.course); const t = tt ? lv(tt.id) / 10 * 30 : 0;
    return { all: Math.round(a + e + t), a: Math.round(a), e: Math.round(e), t: Math.round(t) };
  }
  function touch(xp) {
    const p = P(), d = ist(), y = ist(Date.now() - 864e5);
    if (p.ld !== d) { p.st = p.ld === y ? (p.st || 0) + 1 : 1; p.d = (p.d || 0) + 1; p.ld = d; }
    p.xp = (p.xp || 0) + (xp || 0); p.n = S.o.name; p.c = S.o.cls || ''; p.r = S.o.role; p.rs = ready().all;
    put('PATCH', 'prog/' + S.o.id, p);
    put('PATCH', 'stats/' + d + '/act', { [S.o.id]: 1 });
  }
  function log(k, tr, l, s, of) { put('POST', 'log/' + S.o.id, { t: Date.now(), k, tr, l, s, of }); }
  function stat(q, pick) {
    const v = { n: inc }; if (pick === q.a) v.ok = inc; v['p' + pick] = inc;
    put('PATCH', 'qs/' + q.id, v);
  }

  // ── speech ──
  function say(text, lang) {
    try { const u = new SpeechSynthesisUtterance(text); u.lang = lang || 'en-IN'; u.rate = lang === 'ja-JP' ? 0.8 : 0.95; speechSynthesis.cancel(); speechSynthesis.speak(u); } catch (e) { alert('Voice is not available on this phone'); }
  }
  function listen(lang, done) {
    const R = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!R) { done(null, 'Speaking practice needs Chrome on Android'); return; }
    const r = new R(); r.lang = lang || 'en-IN'; r.interimResults = false; r.maxAlternatives = 1;
    r.onresult = e => done(e.results[0][0].transcript); r.onerror = e => done(null, e.error === 'not-allowed' ? 'Allow the microphone to practise speaking' : 'Did not hear you - try again'); r.start();
  }
  function compare(target, heard) {
    const n = s => s.toLowerCase().replace(/[^a-z0-9 ]/g, '').split(/\s+/).filter(Boolean);
    const t = n(target), h = new Set(n(heard || '')); let ok = 0;
    const words = target.split(/\s+/).map(w => { const good = h.has(n(w)[0] || ''); if (good) ok++; return { w, good }; });
    return { pct: Math.round(ok * 100 / Math.max(1, t.length)), words };
  }

  // ── styles ──
  const CSS = `.plc{--pk:#FDE8D4;--cr:#FFFAF2;--ye:#FFF1C4;--li:#EEE6FB;--gr:#E3F5E6;--ro:#FDE2E4;--wa:#DFF1FB;--ink:#1F1A15;--br:#5C3D05;--mu:#6B5F55;--btn:#FFE08A;
  font-family:'DM Sans',system-ui,sans-serif;color:var(--ink);background:var(--pk);border-radius:20px;padding:16px 14px 76px;max-width:560px;margin:0 auto;position:relative}
  .plc *{box-sizing:border-box}.plc .bb,.plc h2{font-family:'Bebas Neue',sans-serif;letter-spacing:1px;margin:0;line-height:1;font-weight:400}.plc h2{font-size:34px}
  .plc .k{border:2px solid var(--ink);box-shadow:4px 4px 0 var(--ink);border-radius:20px;padding:14px;background:var(--cr);margin:12px 0}
  .plc .row{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.plc .g2{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
  .plc .b{border:2px solid var(--ink);box-shadow:3px 3px 0 var(--ink);background:var(--btn);color:var(--br);border-radius:14px;padding:10px 14px;font:800 14px 'DM Sans',system-ui,sans-serif;cursor:pointer}
  .plc .b:active,.plc .tr:active,.plc .tile:active{transform:translate(2px,2px);box-shadow:1px 1px 0 var(--ink)}.plc .b.dk{background:var(--ink);color:var(--btn)}.plc .b.w{background:var(--cr)}
  .plc .pill{display:inline-block;border:1.5px solid var(--ink);border-radius:99px;padding:4px 11px;font-size:12px;font-weight:800;background:var(--ye)}
  .plc .chip{border:2px solid var(--ink);border-radius:99px;padding:8px 14px;font:800 13px 'DM Sans',sans-serif;cursor:pointer;background:var(--cr);color:var(--ink);flex-shrink:0}.plc .chip.on{background:#f0a500}
  .plc .mu{color:var(--mu);font-size:13px}.plc .kick{font-size:11px;font-weight:800;letter-spacing:.08em}
  .plc .big{font-family:'Bebas Neue',sans-serif;font-size:64px;line-height:.9}.plc .bar{height:10px;border:1.5px solid var(--ink);border-radius:8px;background:#fff;overflow:hidden}.plc .bar i{display:block;height:100%;background:linear-gradient(90deg,#f0a500,#ff6b3d)}
  .plc .tr{border:2px solid var(--ink);box-shadow:4px 4px 0 var(--ink);border-radius:20px;padding:14px;cursor:pointer;color:var(--ink);text-align:left;font-family:inherit;display:flex;flex-direction:column;gap:4px;position:relative}
  .plc .tile{border:2px solid var(--ink);box-shadow:3px 3px 0 var(--ink);border-radius:20px;background:var(--cr);min-height:96px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;cursor:pointer;font-family:inherit;color:var(--ink)}
  .plc .opt{display:block;width:100%;text-align:left;margin:8px 0;padding:14px;font-size:16px;font-weight:700;border:2px solid var(--ink);border-radius:16px;background:var(--cr);box-shadow:3px 3px 0 var(--ink);cursor:pointer;font-family:inherit;color:var(--ink)}
  .plc .ok{background:linear-gradient(135deg,#22c55e,#14b8a6)!important}.plc .no{background:linear-gradient(135deg,#ef4444,#ec4899)!important;color:#fff!important}.plc .pv{background:#1F1A15;color:#FFE08A;border-radius:12px;padding:8px 12px;font-weight:800;margin-bottom:8px}
  .plc table{width:100%;border-collapse:collapse;font-size:13px}.plc td,.plc th{padding:6px;border-bottom:1px solid #e8d2b8;text-align:left}.plc tr.sel{background:var(--ye)}
  .plc .lv{width:56px;height:56px;border-radius:50%;border:2px solid var(--ink);box-shadow:3px 3px 0 var(--ink);display:flex;align-items:center;justify-content:center;font:400 24px 'Bebas Neue',sans-serif;cursor:pointer;flex-shrink:0}
  .plc .av{width:48px;height:48px;border-radius:50%;padding:3px;background:conic-gradient(#f0a500,#ff6b3d,#ec4899,#8b5cf6,#3b82f6,#f0a500)}.plc .av div{width:42px;height:42px;border-radius:50%;background:#FFF1C4;display:flex;align-items:center;justify-content:center;font-weight:800}
  .plc .nav{position:absolute;left:0;right:0;bottom:0;display:flex;justify-content:space-around;padding:10px 6px 12px;background:var(--cr);border-top:2px solid var(--ink);border-radius:0 0 20px 20px}
  .plc .nav button{border:0;background:none;font:800 11px 'DM Sans',sans-serif;color:var(--mu);display:flex;flex-direction:column;align-items:center;gap:2px;cursor:pointer}.plc .nav button span{font-size:20px}.plc .nav .on{color:#c47f00}
  @keyframes plcFl{0%,100%{transform:scale(1) rotate(-4deg)}50%{transform:scale(1.18) rotate(4deg)}}@keyframes plcGl{0%,100%{box-shadow:4px 4px 0 #1F1A15}50%{box-shadow:4px 4px 0 #1F1A15,0 0 26px 2px rgba(240,165,0,.45)}}
  @keyframes plcPu{0%,100%{box-shadow:3px 3px 0 #1F1A15,0 0 0 0 rgba(240,165,0,.6)}50%{box-shadow:3px 3px 0 #1F1A15,0 0 0 12px rgba(240,165,0,0)}}@keyframes plcPop{0%{transform:scale(.7);opacity:0}70%{transform:scale(1.06);opacity:1}100%{transform:scale(1)}}
  @keyframes plcWv{0%,100%{transform:scaleY(.35)}50%{transform:scaleY(1)}}
  .plc .flame{display:inline-block;animation:plcFl 1.2s ease-in-out infinite}.plc .glow{animation:plcGl 2.4s ease-in-out infinite}.plc .now{animation:plcPu 1.6s ease-out infinite}.plc .pop{animation:plcPop .35s ease-out}
  .plc .wv{display:inline-block;width:5px;height:30px;border-radius:3px;background:#ec4899;animation:plcWv .9s ease-in-out infinite;margin:0 2px}`;
  function css() {
    if (document.getElementById('plc-css')) return;
    const s = document.createElement('style'); s.id = 'plc-css'; s.textContent = CSS; document.head.appendChild(s);
    if (!document.querySelector('link[href*="Bebas+Neue"]')) { const l = document.createElement('link'); l.rel = 'stylesheet'; l.href = 'https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:wght@400;600;700;800&display=swap'; document.head.appendChild(l); }
  }
  const GRAD = { gold: 'linear-gradient(135deg,#f0a500,#ff6b3d 55%,#ec4899)', apt: 'linear-gradient(135deg,#3b82f6,#8b5cf6)', eng: 'linear-gradient(135deg,#ec4899,#8b5cf6)', tech: 'linear-gradient(135deg,#22c55e,#14b8a6)', jp: 'linear-gradient(135deg,#ef4444,#ec4899)', blue: 'linear-gradient(135deg,#3b82f6,#8b5cf6 60%,#ec4899)' };
  const GROUP = { apt: ['quant', 'reason', 'verbal'] };
  const nav = (on) => `<div class="nav">${[['home', '🎯', 'Placement'], ['mocks', '📝', 'Mocks'], ['speak', '🎤', 'Speak'], ['cert', '🏅', 'Certificates']].map(([v, e, t]) => `<button class="${on === v ? 'on' : ''}" onclick="PLC.go('${v}')"><span>${e}</span>${t}</button>`).join('')}</div>`;
  const hdr = (title, right) => `<div class="row" style="margin-bottom:6px"><button class="b w" style="padding:8px 12px" onclick="PLC.go('${homeV()}')">←</button><h2 style="flex:1">${title}</h2>${right || ''}</div>`;

  // ── views ──
  function go(v, a) { S.v = v; S.a = a || {}; draw(); try { S.el.scrollIntoView({ block: 'start', behavior: 'smooth' }); } catch (e) {} }
  function draw() {
    const h = { home, track: trackV, lesson, quiz, speak, jp: jpV, cert, report, qbank, gate: () => gate0() + (S.o.hist ? lockedList() : ''), mocks, hhome, hlog, hsol, hlevel, htips, hpick }[S.v] || (S.o.hist ? hhome : home);
    // v4 (user, 18-Oct): no big preview banner - a small 👀 ↩ chip (back to me) and 🏠 (the app's home) on the Placement home only
    const top = S.v !== 'home' || (!S.o.onHome && !S.o.preview) ? '' : '<div class="row" style="gap:6px;margin-bottom:6px">' +
      (S.o.onHome ? '<button class="b w" style="padding:6px 12px" title="Home" onclick="PLC.home()">🏠</button>' : '') +
      (S.o.preview && S.back ? '<button class="b w" style="padding:6px 12px" title="Back to me" onclick="PLC.me()">👀 ↩</button>' : '') + '</div>';
    S.el.innerHTML = '<div class="plc">' + top + h() + '</div>';
  }
  const homeV = () => S.o.hist ? 'hhome' : 'home';
  const back = (v, a) => `<button class="b w" onclick="PLC.go('${v || homeV()}'${a ? ',' + esc(JSON.stringify(a)) : ''})">←</button>`;

  function home() {
    const p = P(), r = ready(), t = today(), w = t.word, q = t.q, done = (p.qd === ist()), first = (S.o.name || '').split(' ')[0];
    const ini = (S.o.name || '?').split(' ').map(x => x[0]).join('').slice(0, 2).toUpperCase();
    const mk = S.bank.mocks || [], co = mk.find(m => m.id === S.a.co) || mk[0];
    const tt = S.bank.tracks.find(x => x.g === 'tech' && x.course === S.o.course) || S.bank.tracks.find(x => x.g === 'tech');
    const card = (g, emoji, name, sub, go, extra) => `<button class="tr" style="background:${GRAD[g]}" onclick="${go}">${extra || ''}<span style="font-size:28px">${emoji}</span><span class="bb" style="font-size:26px">${name}</span><span style="font-size:12px;font-weight:800">${sub}</span></button>`;
    let qh = '';
    if (q) {
      const pick = S.a.qod, short = q.o.every(o => o.length <= 12);
      qh = `<div class="k"><div class="row" style="justify-content:space-between"><span class="kick" style="color:#1A5C8A">🧠 QUESTION OF THE DAY</span><span class="pill" style="background:#cfe0ff">🏷 ${esc(q.tag || '')}</span></div>
        <div style="font-weight:700;font-size:17px;margin:10px 0">${esc(q.q)}</div>` +
        (done && pick == null ? `<div class="mu">✅ Answered today · a new one tomorrow</div>` :
        `<div class="${short ? 'g2' : ''}">` + q.o.map((o, i) => { const c = pick != null ? (i === q.a ? 'ok' : i === pick ? 'no' : '') : '';
          return short ? `<button class="tile ${c}" onclick="PLC.qod(${i})"><span class="kick">${'ABCD'[i]}</span><span class="bb" style="font-size:30px">${esc(o)}</span></button>` : `<button class="opt ${c}" onclick="PLC.qod(${i})">${esc(o)}</button>`; }).join('') + '</div>' +
        (pick != null ? `<div class="k pop" style="margin-bottom:0;background:${pick === q.a ? 'var(--gr)' : 'var(--ro)'}"><b>${pick === q.a ? '🎉 NAILED IT · +20 XP' : '😅 SO CLOSE · it’s ' + esc(q.o[q.a])}</b><div>${esc(q.e)}</div></div>` : '')) + '</div>';
    }
    const tips = S.bank.tips, cats = [...new Set(tips.map(x => x.c))], ci = S.a.tc || tips[dayNo() % tips.length].c, tip = tips.filter(x => x.c === ci)[dayNo() % tips.filter(x => x.c === ci).length];
    if (S.act == null) { S.act = 0; get('stats/' + ist() + '/act', 'shallow=true').then(v => { S.act = v ? Object.keys(v).length : 0; if (S.v === 'home') draw(); }).catch(() => {}); }
    return `<div class="row" style="justify-content:space-between"><div class="row"><div class="av"><div>${esc(ini)}</div></div><div><div class="mu">Hey ${esc(first)} 👋</div><div class="bb" style="font-size:38px">PLACEMENT</div></div></div>
        <span class="pill" style="font-size:16px;padding:7px 14px;background:#FFF1C4;box-shadow:3px 3px 0 #1F1A15"><span class="flame">🔥</span> ${p.st || 0}</span></div>
      <div class="k glow" style="background:${GRAD.gold};display:flex;gap:12px;align-items:center"><div style="flex:1"><div class="kick">YOUR READY SCORE</div><div class="big">${r.all}<span style="font-size:26px">/100</span></div><div style="font-weight:800;font-size:13px">⚡ ${p.xp || 0} XP · ${p.d || 0} days practised</div></div>
        <div style="display:flex;flex-direction:column;gap:6px;font-size:12px;font-weight:800">${[['🧠 APT', r.a, 40], ['🗣 ENG', r.e, 30], ['💻 TECH', r.t, 30]].map(([a, b, c]) => `<span style="background:#1F1A15;color:#f0a500;padding:7px 10px;border-radius:10px">${a}<br>${b}/${c}</span>`).join('')}</div></div>
      ${co ? `<div class="kick" style="color:var(--mu);margin-top:6px">PREPARE FOR 🎯</div><div class="row" style="flex-wrap:nowrap;overflow-x:auto;padding:8px 2px">${mk.map(m => `<button class="chip ${m === co ? 'on' : ''}" onclick="PLC.go('home',{co:'${m.id}'})">${esc(m.name.replace(/ pattern mock$/, ''))}</button>`).join('')}</div>
        <button class="k" style="width:100%;text-align:left;cursor:pointer;display:flex;gap:10px;align-items:center;font-family:inherit;color:var(--ink);margin-top:4px" onclick="PLC.mock('${co.id}')"><span style="font-size:24px">📝</span><span style="flex:1"><b>${esc(co.name)} · ${co.min} min</b><br><span class="mu">${co.sec.map(x => esc(x[0])).join(' · ')} · same timing as the real test${(p.mk || {})[co.id] != null ? ' · best ' + p.mk[co.id] + '%' : ''}</span></span><b style="color:#c47f00">Start →</b></button>` : ''}
      <div class="g2">${card('apt', '🧠', 'APTITUDE', `Quant L${lv('quant') + 1} · Reasoning L${lv('reason') + 1} · Verbal L${lv('verbal') + 1}`, "PLC.go('track',{t:'quant'})")}
        ${card('eng', '🗣️', 'ENGLISH', `Level ${Math.min(10, lv('english') + 1)} · speak 🎤`, "PLC.go('track',{t:'english'})")}
        ${tt ? card('tech', '💻', 'TECHNICAL', `${esc(tt.course === 'BCOM' ? 'BCom' : tt.course)} · Level ${Math.min(10, lv(tt.id) + 1)}`, `PLC.go('track',{t:'${tt.id}'})`) : ''}
        ${card('jp', '🇯🇵', 'JAPANESE', `Japan jobs · JLPT N5 · L${Math.min(10, lv('japanese') + 1)}`, "PLC.go('jp')", '<span class="pill" style="position:absolute;top:10px;right:10px;background:#1F1A15;color:#f0a500;border-color:#1F1A15">NEW</span>')}</div>
      <div class="k" style="background:var(--li);display:flex;align-items:center;gap:12px"><div style="flex:1"><div class="kick" style="color:#5B3E96">WORD OF THE DAY ✨</div><div class="bb" style="font-size:30px;margin-top:4px">${esc(w.w.toUpperCase())}</div><div class="mu" style="color:var(--ink)">${esc(w.m)} · <b>${esc(w.kn)}</b></div><div class="mu" style="font-style:italic">"${esc(w.ex)}"</div></div>
        <button class="b" style="width:52px;height:52px;border-radius:50%;padding:0;background:#8b5cf6;font-size:20px" onclick="PLC.say(${esc(JSON.stringify(w.w + '. ' + w.ex))})">🔊</button></div>
      ${qh}
      <div class="row" style="margin:6px 0"><span style="display:flex"><span style="width:24px;height:24px;border-radius:50%;background:#3b82f6;border:2px solid #FDE8D4"></span><span style="width:24px;height:24px;border-radius:50%;background:#ec4899;border:2px solid #FDE8D4;margin-left:-8px"></span><span style="width:24px;height:24px;border-radius:50%;background:#22c55e;border:2px solid #FDE8D4;margin-left:-8px"></span></span>
        <span class="mu"><b style="color:var(--ink)">${Math.max(1, S.act || 0)} ${Math.max(1, S.act || 0) === 1 ? 'learner' : 'learners'}</b> practising today · keep your 🔥 streak</span></div>
      ${S.o.sa ? `<div class="row"><button class="b dk" onclick="PLC.go('report')">📊 Report</button><button class="b dk" onclick="PLC.go('qbank')">📚 Question bank</button></div>` : ''}
      <div class="row" style="justify-content:space-between;margin-top:14px"><span class="bb" style="font-size:28px">💡 PLACEMENT TIPS</span><span class="mu">new tip every day</span></div>
      <div class="row" style="margin-top:8px">${cats.map(c => `<button class="chip ${c === ci ? 'on' : ''}" style="${c === ci ? 'background:#22c55e' : ''}" onclick="PLC.go('home',{tc:'${esc(c)}',co:'${co ? co.id : ''}'})">${esc(c)}</button>`).join('')}</div>
      <div class="k" style="background:linear-gradient(135deg,rgba(34,197,94,.22),rgba(59,130,246,.16))"><div class="kick" style="color:#1E7B3A">📄 ${esc(ci.toUpperCase())}</div><div style="font-weight:800;font-size:18px;margin:6px 0">${esc(tip.t)}</div><div style="line-height:1.55">${esc(tip.b)}</div><div class="mu" style="margin-top:4px">${esc(tip.kn)}</div>
        <div class="row" style="margin-top:10px"><button class="b w" onclick="PLC.say(${esc(JSON.stringify(tip.t + '. ' + tip.b))})">🔊 Listen</button></div></div>` + nav('home');
  }
  function trackV() {
    const t = track(S.a.t), n = lv(t.id), g = t.g, grp = g === 'apt' ? GROUP.apt.map(track) : g === 'tech' && S.o.role === 'stf' ? S.bank.tracks.filter(x => x.g === 'tech') : [t];
    const cur = Math.min(t.levels.length, n + 1), sel = S.a.sel || cur, best = P().best || {}, stars = Object.keys(best).filter(k => k.startsWith(t.id + '_')).length;
    const title = g === 'apt' ? '🧠 APTITUDE' : t.emoji + ' ' + esc(t.name.toUpperCase());
    const nodes = t.levels.map((l, i) => { const st = l.n <= n ? 'done' : l.n === n + 1 ? 'now' : 'lock', off = [0, 70, 120, 70, 0, 70, 120, 70, 0, 60][i % 10];
      const bg = l.pro ? 'linear-gradient(135deg,#f0a500,#ec4899)' : st === 'done' ? GRAD.tech : st === 'now' ? 'linear-gradient(135deg,#f0a500,#ff6b3d)' : '#FFF1C4';
      return `<div class="row" style="padding-left:${off}px;margin:6px 0;flex-wrap:nowrap"><button class="lv ${st === 'now' ? 'now' : ''}" style="background:${bg};${l.n === sel ? 'outline:3px solid #1F1A15;outline-offset:3px' : ''}" onclick="PLC.go('track',{t:'${t.id}',sel:${l.n}})">${l.pro ? '👑' : st === 'done' ? '✓' : st === 'lock' ? '🔒' : l.n}</button>
        <div><div style="font-weight:800;font-size:14px">${esc(l.name)}</div><div class="mu">${st === 'done' ? '⭐ ' + (best[t.id + '_' + l.n] || '') + '%' : st === 'now' ? 'you are here 👇' : l.pro ? 'gold certificate 🏅' : 'locked'}</div></div></div>`; }).join('');
    const L = t.levels.find(x => x.n === sel), ss = sel <= n ? 'done' : sel === n + 1 ? 'now' : 'lock';
    return hdr(title, `<span class="pill">⭐ ${stars}</span>`) +
      (grp.length > 1 ? `<div class="row" style="background:var(--cr);border:2px solid var(--ink);border-radius:14px;padding:4px;flex-wrap:nowrap">${grp.map(x => `<button class="b ${x.id === t.id ? 'dk' : 'w'}" style="flex:1;box-shadow:none;border:0;padding:8px 4px" onclick="PLC.go('track',{t:'${x.id}'})">${esc(x.name)}</button>`).join('')}</div>` : '') +
      `<div style="padding:8px 4px">${nodes}</div>
      <div class="k" style="background:var(--cr)"><div class="row" style="justify-content:space-between"><span class="bb" style="font-size:26px">LEVEL ${L.pro ? 'PRO' : L.n} · ${esc(L.name.toUpperCase())}</span><span class="mu">${ss === 'done' ? 'done ✓' : ss === 'now' ? 'in progress' : 'locked'}</span></div>
        <div style="font-size:12px;font-weight:800;color:#c47f00;margin:4px 0 10px">🏷 ${esc(L.tag)}</div>
        <div class="g2" style="grid-template-columns:repeat(3,minmax(0,1fr));gap:8px">${[['📖 LEARN', `${L.cards.length} cards`, 'var(--gr)'], ['✍️ PRACTICE', L.pro ? '12 mixed' : `${(L.qs || []).length} Qs`, 'var(--ye)'], ['🏁 TEST', `pass ${Math.round(S.bank.pass * 100)}%`, 'var(--li)']].map(([a, b, c]) => `<div style="background:${c};border:1.5px solid var(--ink);border-radius:14px;padding:10px"><div class="kick">${a}</div><div style="font-weight:700;font-size:13px">${b}</div></div>`).join('')}</div>
        ${ss === 'lock' ? `<div class="mu" style="margin-top:10px">🔒 Finish level ${cur} first</div>` : `<div class="row" style="margin-top:12px"><button class="b w" onclick="PLC.go('lesson',{t:'${t.id}',l:${L.n},i:0})">📖 Learn</button><button class="b w" onclick="PLC.start('${t.id}',${L.n},'prac')">✍️ Practice</button><button class="b dk" style="flex:1" onclick="PLC.start('${t.id}',${L.n},'test')">🏁 Take the test →</button></div>`}</div>
      <div class="mu">🥉 bronze at level 2 · 🥈 silver at level 5 · 👑 gold when you pass the PRO test</div>`;
  }
  function lesson() {
    const t = track(S.a.t), l = t.levels.find(x => x.n === S.a.l), i = S.a.i || 0, c = l.cards[i], kn = S.a.kn;
    const nav2 = (j, k) => `PLC.go('lesson',{t:'${t.id}',l:${l.n},i:${j},kn:${k}})`;
    return `<div class="row" style="flex-wrap:nowrap;gap:5px">${l.cards.map((_, k) => `<div style="flex:1;height:5px;border-radius:4px;background:${k <= i ? '#1F1A15' : '#E8D2B8'}"></div>`).join('')}</div>
      <div class="row" style="margin:12px 0;flex-wrap:nowrap"><div style="width:40px;height:40px;border-radius:50%;background:${GRAD[t.g]};border:2px solid #1F1A15;display:flex;align-items:center;justify-content:center;font-size:20px">${t.emoji}</div>
        <div style="flex:1"><div style="font-weight:800;font-size:14px">${esc(l.name)} · Level ${l.n}</div><div class="mu">🏷 ${esc(l.tag)}</div></div>
        <div style="display:flex;border:2px solid var(--ink);border-radius:99px;overflow:hidden"><button class="b" style="border:0;box-shadow:none;border-radius:0;padding:6px 10px;${kn ? 'background:var(--cr)' : ''}" onclick="${nav2(i, false)}">EN</button><button class="b" style="border:0;box-shadow:none;border-radius:0;padding:6px 10px;${kn ? '' : 'background:var(--cr)'}" onclick="${nav2(i, true)}">ಕನ್ನಡ</button></div>
        <button class="b w" style="padding:6px 10px" onclick="PLC.go('track',{t:'${t.id}',sel:${l.n}})">✕</button></div>
      <div class="k pop" style="min-height:340px;position:relative;overflow:hidden"><div style="position:absolute;right:-40px;top:-40px;width:160px;height:160px;border-radius:50%;background:radial-gradient(circle,rgba(240,165,0,.4),rgba(240,165,0,0) 70%)"></div>
        <div style="font-size:44px">${t.emoji}</div><h2 style="font-size:36px;margin:8px 0">${esc(c.t)}</h2><p style="font-size:17px;line-height:1.55;white-space:pre-line">${esc(c.b)}</p>
        <div class="k" style="background:${GRAD.gold};font-weight:800;font-size:18px;white-space:pre-line">${esc(c.box)}</div>${kn ? `<p style="font-size:18px;font-weight:800">${esc(c.kn)}</p>` : ''}
        <button class="b w" onclick="PLC.say(${esc(JSON.stringify(c.t + '. ' + c.b + '. ' + c.box))})">🔊 Read it to me</button></div>
      <div class="row" style="flex-wrap:nowrap">${i > 0 ? `<button class="b w" onclick="${nav2(i - 1, !!kn)}">←</button>` : ''}
        ${i < l.cards.length - 1 ? `<button class="b dk" style="flex:1;padding:15px" onclick="${nav2(i + 1, !!kn)}">Next card →</button>` : `<button class="b" style="flex:1;padding:15px;background:${GRAD.gold}" onclick="PLC.start('${t.id}',${l.n},'prac')">Got it! Start practice 💪</button>`}</div>`;
  }
  function start(tid, n, mode) {
    const t = track(tid), l = t.levels.find(x => x.n === n), qs = qsOf(t, l).map(q => { const ord = q.o.map((_, i) => i).sort(() => Math.random() - .5); return Object.assign({}, q, { ord }); });
    S.quiz = { t: tid, n, mode, qs, i: 0, ok: 0, pick: null, t0: Date.now(), tag: l.tag }; go('quiz');
  }
  function quiz() {
    const z = S.quiz;
    if (z.i >= z.qs.length && z.mode === 'mock') return mockResult();
    if (z.i >= z.qs.length) {
      const pct = Math.round(z.ok * 100 / z.qs.length), pass = z.mode === 'test' && pct >= S.bank.pass * 100;
      return `<div class="k pop" style="text-align:center;background:${pass ? GRAD.tech : z.mode === 'test' ? 'var(--ro)' : GRAD.gold}"><div class="kick">${z.mode === 'test' ? 'TEST RESULT' : 'PRACTICE DONE'}</div><div class="big" style="font-size:80px">${pct}%</div>
        <div class="bb" style="font-size:26px">${pass ? '🎉 LEVEL ' + z.n + ' CLEARED · +50 XP' : z.mode === 'test' ? '😅 NEED ' + Math.round(S.bank.pass * 100) + '% · PRACTISE AND TRY AGAIN' : z.ok + ' OF ' + z.qs.length + ' RIGHT 💪'}</div></div>
        <div class="row"><button class="b w" onclick="PLC.go('track',{t:'${z.t}'})">← Levels</button><button class="b" onclick="PLC.start('${z.t}',${z.n},'${z.mode}')">↺ Again</button>${z.mode === 'prac' ? `<button class="b dk" style="flex:1" onclick="PLC.start('${z.t}',${z.n},'test')">🏁 Take the test</button>` : ''}</div>`;
    }
    const q = z.qs[z.i], pk = z.pick, fb = z.mode === 'prac' && pk != null, short = q.o.every(o => o.length <= 12);
    const cls = i => fb ? (i === q.a ? 'ok' : i === pk ? 'no' : '') : (pk === i ? 'ok' : '');
    return `<div class="row" style="flex-wrap:nowrap"><button class="b w" style="padding:6px 10px" onclick="PLC.go('${z.mode === 'mock' ? 'mocks' : 'track'}',{t:'${z.t}'})">✕</button><div class="bar" style="flex:1"><i style="width:${Math.round(z.i * 100 / z.qs.length)}%"></i></div><b>${z.i + 1}/${z.qs.length}</b>${z.end ? '<span class="pill" id="plc-timer" style="background:#ffc9c9">⏱</span>' : ''}</div>
      <div class="row" style="margin:10px 0"><span class="pill" style="background:#3b82f6;color:#fff;border-color:#1F1A15">🏷 ${esc(q.tag || z.tag)}</span><span class="pill">${z.mode === 'test' ? '🏁 Test' : z.mode === 'mock' ? '📝 ' + esc(q.sec) : '✍️ Practice'}</span></div>
      <div class="k" style="font-size:19px;font-weight:700;line-height:1.45">${esc(q.q)}</div>
      ${short ? `<div class="g2">${q.ord.map(i => `<button class="tile ${cls(i)}" onclick="PLC.pick(${i})"><span class="kick">${'ABCD'[q.ord.indexOf(i)]}</span><span class="bb" style="font-size:32px">${esc(q.o[i])}</span><span style="font-size:18px">${cls(i) === 'ok' && pk != null ? '✅' : cls(i) === 'no' ? '❌' : ''}</span></button>`).join('')}</div>`
        : q.ord.map(i => `<button class="opt ${cls(i)}" onclick="PLC.pick(${i})">${esc(q.o[i])}</button>`).join('')}
      ${fb ? `<div class="k pop" style="background:${pk === q.a ? GRAD.tech : 'var(--ro)'}"><div class="bb" style="font-size:26px">${pk === q.a ? 'NAILED IT 🎉 +10 XP' : 'SO CLOSE 😅 IT’S ' + esc(q.o[q.a])}</div><div style="margin-top:4px">${esc(q.e)}</div></div>` : ''}
      ${pk != null ? `<button class="b dk" style="width:100%;padding:15px" onclick="PLC.next()">Next →</button>` : ''}`;
  }
  function pick(i) {
    const z = S.quiz, q = z.qs[z.i]; if (z.pick != null) return;
    z.pick = i; if (i === q.a) z.ok++; stat(q, i);
    if (z.wrong && i !== q.a) z.wrong.push(q.lvn || '');
    if (z.secOk && i === q.a) z.secOk[q.sec] = (z.secOk[q.sec] || 0) + 1;
    if (z.mode === 'test' || z.mode === 'mock') return next();
    draw();
  }
  function next() {
    const z = S.quiz; z.i++; z.pick = null;
    if (z.i >= z.qs.length && z.mode === 'mock') { if (!z.saved) { z.saved = 1; clearInterval(S.tick); const pct = Math.round(z.ok * 100 / z.qs.length), p = P(); p.mk = p.mk || {}; p.mk[z.t] = Math.max(p.mk[z.t] || 0, pct); touch(z.ok * 2); log('mock', z.t, 0, z.ok, z.qs.length); } return draw(); }
    if (z.i >= z.qs.length) {
      const pct = Math.round(z.ok * 100 / z.qs.length), p = P(); p.best = p.best || {}; const bk = z.t + '_' + z.n;
      p.best[bk] = Math.max(p.best[bk] || 0, pct); p.lv = p.lv || {};
      let xp = z.ok * (z.mode === 'prac' ? 10 : 5);
      if (z.mode === 'test' && pct >= S.bank.pass * 100 && lv(z.t) < z.n) { p.lv[z.t] = z.n; xp += 50; }
      touch(xp); log(z.mode, z.t, z.n, z.ok, z.qs.length);
    }
    draw();
  }
  function mocks() {
    const p = P();
    return hdr('📝 MOCK TESTS') + `<div class="mu">${esc(S.bank.mockNote || '')}</div>` +
      (S.bank.mocks || []).map((m, i) => `<div class="k" style="background:${i % 2 ? 'var(--cr)' : 'var(--ye)'}"><div class="row" style="justify-content:space-between"><span class="bb" style="font-size:24px">${esc(m.name.toUpperCase())}</span><span class="pill" style="background:#ffc9c9">⏱ ${m.min} min</span></div>
        <div class="mu" style="margin:6px 0">${m.sec.map(x => esc(x[0]) + ' ' + x[2]).join(' · ')} questions${(p.mk || {})[m.id] != null ? ' · <b>your best ' + p.mk[m.id] + '%</b>' : ''}</div>
        <button class="b dk" onclick="PLC.mock('${m.id}')">Start →</button></div>`).join('') + nav('mocks');
  }
  function mock(id) {
    const m = S.bank.mocks.find(x => x.id === id), qs = [];
    m.sec.forEach(([nm, tid, n]) => { const t = track(tid), pool = []; t.levels.filter(l => !l.pro).forEach(l => (l.qs || []).forEach(q => { if (!S.hide[q.id]) pool.push(Object.assign({ tag: l.tag, lvn: t.name + ' · ' + l.name, sec: nm }, qOf(q))); }));
      pool.sort(() => Math.random() - .5).slice(0, n).forEach(q => qs.push(q)); });
    qs.forEach(q => { q.ord = q.o.map((_, i) => i).sort(() => Math.random() - .5); });
    S.quiz = { t: id, n: 0, mode: 'mock', qs, i: 0, ok: 0, pick: null, t0: Date.now(), tag: m.name, end: Date.now() + m.min * 60000, wrong: [], secOk: {}, m };
    clearInterval(S.tick); S.tick = setInterval(() => { const z = S.quiz; if (!z || z.mode !== 'mock' || z.i >= z.qs.length) return clearInterval(S.tick);
      const left = Math.max(0, z.end - Date.now()), el = document.getElementById('plc-timer'); if (el) el.textContent = '⏱ ' + Math.floor(left / 60000) + ':' + String(Math.floor(left / 1000) % 60).padStart(2, '0');
      if (!left) { z.i = z.qs.length - 1; z.pick = null; next(); } }, 1000);
    go('quiz');
  }
  function mockResult() {
    const z = S.quiz, m = z.m, pct = Math.round(z.ok * 100 / z.qs.length), weak = {};
    z.wrong.forEach(w => { if (w) weak[w] = (weak[w] || 0) + 1; });
    const wk = Object.entries(weak).sort((a, b) => b[1] - a[1]).slice(0, 3), best = (P().mk || {})[m.id];
    return `<div class="row"><button class="b w" style="padding:6px 10px" onclick="PLC.go('mocks')">✕</button><span class="mu" style="font-weight:800">📝 ${esc(m.name)} · ${m.min} min</span></div>
      <div class="k pop" style="text-align:center;background:${GRAD.blue}"><div class="kick">YOUR SCORE</div><div class="big" style="font-size:84px">${pct}%</div><div style="font-weight:800">${z.ok} of ${z.qs.length} right · ${Math.max(1, Math.round((Date.now() - z.t0) / 60000))} min${best != null && best > pct ? ' · best ' + best + '%' : ''}</div>
        <span class="pill" style="margin-top:8px;background:rgba(31,26,21,.75);color:#FFE08A;border-color:#1F1A15">Your target: 70% ${pct >= 70 ? '✅ reached' : '· ' + (70 - pct) + '% to go'}</span></div>
      <div class="bb" style="font-size:24px;margin-top:6px">SECTIONS</div>
      ${m.sec.map(([nm, , n]) => { const ok = z.secOk[nm] || 0, p = Math.round(ok * 100 / n), c = p >= 65 ? '#1E7B3A' : p >= 50 ? '#9A5B00' : '#B3261E'; return `<div class="k" style="margin:8px 0"><div class="row" style="justify-content:space-between"><b>${esc(nm)}</b><b style="color:${c}">${ok} / ${n}</b></div><div class="bar" style="margin-top:6px"><i style="width:${p}%;background:${c}"></i></div></div>`; }).join('')}
      ${wk.length ? `<div class="k" style="background:var(--ye)"><div class="kick" style="color:#9A5B00">😬 FIX THESE ${wk.length} FIRST</div><div style="margin-top:4px">${wk.map(([w, c]) => esc(w) + ' (' + c + ' wrong)').join(' · ')}</div></div>` : ''}
      <div class="row"><button class="b w" onclick="PLC.go('mocks')">← Mock tests</button><button class="b" style="flex:1;background:${GRAD.gold}" onclick="PLC.mock('${m.id}')">↺ Try again 💪</button></div>`;
  }
  function gate0() {
    const w = today().word;
    return `<div class="k glow" style="background:${GRAD.gold}"><div class="bb" style="font-size:40px">🎯 PLACEMENT</div><div style="font-weight:800;font-size:17px;margin:8px 0">Get ready for campus drives: English, Aptitude (TCS NQT · Infosys · Wipro · Accenture · AMCAT pattern), Technical for your course and 🇯🇵 Japanese.</div>
      <div style="font-weight:700">Levels 1 → 10 · company mock tests · speaking practice · certificates for your resume</div></div>
      <div class="k"><div class="bb" style="font-size:26px">🔓 UNLOCK IT IN 2 MINUTES</div>
        <div style="margin:10px 0;line-height:2;font-size:15px">1️⃣ Install the <b>Davan widget</b> on your home screen<br>2️⃣ Swipe to its 🎯 <b>Placement</b> page<br>3️⃣ Answer today's <b>Question of the day</b> on the widget<br>4️⃣ Come back here - everything opens 🎉</div>
        <div class="row"><button class="b dk" onclick="PLC.install()">📲 Install the widget</button><button class="b w" onclick="PLC.recheck()">✅ I answered - check again</button></div></div>
      <div class="k" style="background:var(--li)"><div class="kick" style="color:#5B3E96">✨ TODAY'S WORD (a taste)</div><div class="bb" style="font-size:30px;margin-top:4px">${esc(w.w.toUpperCase())}</div><div>${esc(w.m)} · <b>${esc(w.kn)}</b></div></div>`;
  }
  function qod(i) {
    const q = today().q, p = P(); if (S.a.qod != null || p.qd === ist()) return;
    S.a.qod = i; p.qd = ist(); stat(q, i); put('PATCH', 'stats/' + ist() + '/q/' + q.id, { n: inc, ['p' + i]: inc }); touch(i === q.a ? 20 : 5); log('qod', q.tr, 0, i === q.a ? 1 : 0, 1); draw();
  }
  function speak() {
    const L = S.bank.speak, i = (S.a.i == null ? dayNo() : S.a.i) % L.length, s = L[i], r = S.a.res;
    return hdr('🗣️ SPEAKING', '<span class="pill" style="background:#ec4899;color:#fff;border-color:#1F1A15">🏷 HR interview</span>') +
      `<div class="k"><div class="kick" style="color:#ec4899">🎧 LISTEN, THEN SAY IT · ${i + 1}/${L.length}</div><div style="font-size:21px;font-weight:700;margin:10px 0;line-height:1.4">${esc(s.s)}</div><div class="mu">${esc(s.kn)}</div>
        <div class="row" style="margin-top:10px"><button class="b" style="background:#ec4899;color:#fff" onclick="PLC.say(${esc(JSON.stringify(s.s))})">🔊 Listen</button><button class="b w" onclick="PLC.slow(${esc(JSON.stringify(s.s))})">🐢 Slow</button></div></div>
      ${r ? `<div class="k pop">${r.err ? esc(r.err) : `<div class="row" style="justify-content:space-between"><span class="kick" style="color:var(--mu)">WHAT THE PHONE HEARD</span><span class="bb" style="font-size:40px;color:${r.pct >= 70 ? '#1E7B3A' : '#B3261E'}">${r.pct}% ${r.pct >= 70 ? '🔥' : ''}</span></div>
        <div style="font-size:18px;font-weight:700;line-height:1.9">${r.words.map(w => `<span style="padding:2px 7px;border-radius:8px;${w.good ? 'color:#1E7B3A' : 'background:#ef4444;color:#fff'}">${esc(w.w)}</span>`).join(' ')}</div><div class="mu">Heard: "${esc(r.heard)}"</div>`}</div>` : ''}
      <div style="text-align:center;margin:20px 0">${r ? '' : '<div style="height:34px">' + [0, 1, 2, 3, 4].map(k => `<span class="wv" style="animation-delay:${k * .15}s"></span>`).join('') + '</div>'}
        <button class="b" style="width:100px;height:100px;border-radius:50%;font-size:42px;background:${r && !r.err && r.pct >= 70 ? GRAD.tech : GRAD.eng};box-shadow:3px 3px 0 #1F1A15,0 0 34px rgba(236,72,153,.45)" onclick="PLC.mic(${i})">🎤</button><div class="mu" style="margin-top:10px;font-weight:700">${r ? 'Tap to try again' : 'Tap and say it 🎙️'}</div></div>
      <div class="row"><button class="b w" onclick="PLC.go('speak',{i:${(i + L.length - 1) % L.length}})">‹ Previous</button><button class="b w" style="flex:1" onclick="PLC.go('speak',{i:${(i + 1) % L.length}})">Next sentence ›</button></div>` + nav('speak');
  }
  function mic(i) {
    const s = S.bank.speak[i];
    listen('en-IN', (heard, err) => { if (err) { S.a = { i, res: { err } }; return draw(); }
      const c = compare(s.s, heard); S.a = { i, res: Object.assign({ heard }, c) };
      const p = P(); p.sp = (p.sp || 0) + 1; touch(c.pct >= 70 ? 15 : 5); log('speak', 'english', 0, c.pct, 100); draw(); });
  }
  function jpV() {
    const L = S.bank.jp, i = (S.a.i == null ? dayNo() : S.a.i) % L.length, w = L[i], open = S.a.open, t = track('japanese'), n = lv('japanese');
    return hdr('🇯🇵 JAPANESE', '<span class="pill" style="background:#ef4444;color:#fff;border-color:#1F1A15">JLPT N5 path</span>') +
      `<button class="k" style="width:100%;min-height:270px;background:${GRAD.jp};cursor:pointer;text-align:center;font-family:inherit;color:#fff" onclick="PLC.go('jp',{i:${i},open:${!open}})">
        <div style="font-size:66px;font-weight:800">${esc(w.j)}</div>${open ? `<div style="font-size:22px;font-weight:800">${esc(w.r)} · ${esc(w.ks)}</div><div style="font-size:18px;font-weight:800;background:rgba(31,26,21,.35);border-radius:12px;padding:6px 12px;display:inline-block;margin:8px 0">ಕನ್ನಡ: ${esc(w.kn)}</div><div style="font-weight:700">English: ${esc(w.en)}</div>` : '<div style="font-weight:800;margin-top:8px">tap to flip 🔄</div>'}</button>
      <div class="row"><button class="b w" onclick="PLC.say(${esc(JSON.stringify(w.j))},'ja-JP')">🔊 Hear it</button><button class="b dk" style="flex:1" onclick="PLC.go('jp',{i:${(i + 1) % L.length}})">Next →</button></div>
      <div class="k"><div class="kick" style="color:#c47f00">YOUR PATH TO N5 🗾</div>${t.levels.map(l => { const st = l.n <= n ? 'done' : l.n === n + 1 ? 'now' : 'lock';
        return `<div class="row" style="margin-top:8px;cursor:pointer" onclick="PLC.go('track',{t:'japanese',sel:${l.n}})"><span class="lv" style="width:30px;height:30px;font-size:14px;box-shadow:none;background:${st === 'done' ? '#22c55e' : st === 'now' ? '#f0a500' : '#FFF1C4'}">${st === 'done' ? '✓' : st === 'now' ? '⚡' : '🔒'}</span><span style="flex:1;font-weight:700">${esc(l.name)}</span><span class="mu">${st === 'done' ? 'done' : st === 'now' ? 'start →' : 'locked'}</span></div>`; }).join('')}</div>
      <div class="k" style="background:var(--ye);font-size:14px;line-height:1.5">ಅ-ಕ-ಸ <b>Kannada helps:</b> Japanese letters are sounds, like ಕ, ಸ, ಮ - so every word is also shown in Kannada letters. 💼 <b>Why Japanese?</b> Japan is hiring skilled workers from India, and many IT companies have Japanese clients.</div>`;
  }
  function cert() {
    const p = P(), have = tracks().map(t => ({ t, n: lv(t.id) })).filter(x => x.n >= 2);
    const tier = n => n >= 10 ? ['👑 GOLD · PRO', '#f0a500'] : n >= 5 ? ['🥈 SILVER', '#9aa4b2'] : ['🥉 BRONZE', '#c47f3a'];
    const c = S.a.c != null ? have.find(x => x.t.id === S.a.c) : null;
    if (c) { const [nm, col] = tier(c.n), id = 'DVP-' + key(S.o.id).slice(-8) + '-' + c.t.id.toUpperCase() + '-' + c.n;
      return `<div class="row">${back('cert')}<button class="b" onclick="window.print()">⬇ Save PDF / print</button></div>
        <div class="k" style="text-align:center;border:6px double ${col};background:#fffaf2"><div style="font-weight:800;letter-spacing:1px"><span style="color:#2B2A84">DA</span><span style="color:#D3262E">V</span><span style="color:#2B2A84">AN</span> · PLACEMENT</div>
        <div style="font-family:Georgia,serif;font-size:26px;color:#5C3D05;margin:8px 0">Certificate of Achievement</div><div class="mu">This is to certify that</div><div style="font-family:Georgia,serif;font-size:28px">${esc(S.o.name)}</div><div class="mu">${esc(S.o.cls || '')}</div>
        <p style="font-size:15px">has completed level ${c.n} of <b>${esc(c.t.name)}</b> on Davan Placement.</p><span class="pill" style="background:${col}">${nm}</span><div class="mu" style="margin-top:10px">${ist()} · ID ${id}</div></div>`; }
    return `<div class="row">${back()}<h2>🏅 CERTIFICATES</h2></div>` + (have.length ? have.map(x => `<button class="tr k" style="width:100%;background:var(--ye)" onclick="PLC.go('cert',{c:'${x.t.id}'})">${tier(x.n)[0]} · ${esc(x.t.name)} · level ${x.n}</button>`).join('') : '<div class="k">Clear level 2 of any track to earn your first 🥉 certificate.</div>') + `<div class="k mu">Add them to your resume and LinkedIn (Licences &amp; certifications).</div>`;
  }

  // ── Super Admin: report + question bank ──
  async function loadAll() { if (!S.all || Date.now() - S.allAt > 120000) { S.all = (await get('prog')) || {}; S.allAt = Date.now(); S.qs = (await get('qs')) || {}; S.st = (await get('stats/' + ist())) || {}; } }
  function report() {
    if (!S.all) { loadAll().then(draw).catch(e => { S.el.innerHTML = '<div class="plc">Could not read: ' + esc(e.message) + '</div>'; }); return '<div>Loading…</div>'; }
    const f = S.a.f || 'stu', min = S.a.min || 0, d7 = ist(Date.now() - 7 * 864e5);
    const rows = Object.entries(S.all).map(([id, p]) => Object.assign({ id }, p)).filter(p => (f === 'all' || p.r === f || (f === 'BCA' || f === 'BBA' || f === 'BCOM') && p.r === 'stu' && String(p.c).toUpperCase().replace(/[.\s]/g, '').includes(f)) && (p.rs || 0) >= min).sort((a, b) => (b.rs || 0) - (a.rs || 0) || (b.xp || 0) - (a.xp || 0));
    const all = Object.values(S.all), act = Object.keys(S.st.act || {}).length, wk = all.filter(p => (p.ld || '') >= d7).length, t = today(), qs = (S.st.q || {})[t.q ? t.q.id : ''] || {};
    const cls = {}; all.filter(p => p.r === 'stu').forEach(p => { cls[p.c] = (cls[p.c] || 0) + 1; });
    const sel = S.a.sel && S.all[S.a.sel];
    return `<div class="row">${back()}<h2>📊 PLACEMENT REPORT</h2><span class="pill" style="background:#ffc9c9">Super Admin only</span><button class="b w" onclick="PLC.reload()">⟳</button></div>
      <div class="g2" style="grid-template-columns:repeat(4,minmax(0,1fr))">${[['ACTIVE TODAY', act], ['THIS WEEK', wk], ['LEARNERS', all.length], ['LEVELS CLEARED', all.reduce((s, p) => s + Object.values(p.lv || {}).reduce((a, b) => a + b, 0), 0)]].map(([a, b]) => `<div class="k" style="margin:0"><div class="kick">${a}</div><div class="big" style="font-size:40px">${b}</div></div>`).join('')}</div>
      <div class="k" style="background:var(--li)"><b>Today:</b> word <b>${esc(t.word.w)}</b> · question "${esc(t.q ? t.q.q : '')}" · answered ${qs.n || 0}${t.q ? ' · picks ' + t.q.o.map((o, i) => esc(o) + ' ' + (qs['p' + i] || 0)).join(' / ') : ''}</div>
      <div class="row">${['stu', 'stf', 'BCA', 'BBA', 'BCOM', 'all'].map(x => `<button class="b ${f === x ? 'dk' : 'w'}" onclick="PLC.go('report',{f:'${x}',min:${min}})">${{ stu: 'Students', stf: 'Staff', all: 'All' }[x] || x}</button>`).join('')}
        ${[0, 45, 70].map(m => `<button class="b ${min === m ? 'dk' : 'w'}" onclick="PLC.go('report',{f:'${f}',min:${m}})">${m ? 'Ready ' + m + '+' : 'Any score'}</button>`).join('')}<button class="b" onclick="PLC.csv()">⬇ CSV</button></div>
      ${sel ? `<div class="k" style="background:var(--ye)"><b>${esc(sel.n)}</b> · ${esc(sel.c)} · Ready ${sel.rs || 0} · ${sel.xp || 0} XP · 🔥 ${sel.st || 0} · ${sel.d || 0} days · last ${esc(sel.ld || '-')}<div>Levels: ${esc(Object.entries(sel.lv || {}).map(([k, v]) => k + ' ' + v).join(' · ') || 'none yet')}</div><div id="plc-log" class="mu">Loading tries…</div>
        <button class="b dk" onclick="PLC.previewOf('${esc(S.a.sel)}')">👀 Open their Placement page (preview)</button></div>` : ''}
      <div class="k" style="overflow-x:auto"><table><tr><th>Name</th><th>Class</th><th>Ready</th><th>XP</th><th>🔥</th><th>Days</th><th>Last</th><th>Levels</th></tr>
      ${rows.slice(0, 400).map(p => `<tr class="${S.a.sel === p.id ? 'sel' : ''}" style="cursor:pointer" onclick="PLC.go('report',{f:'${f}',min:${min},sel:'${esc(p.id)}'})"><td><span>${esc(p.n)}</span></td><td>${esc(p.c)}</td><td><b>${p.rs || 0}</b></td><td>${p.xp || 0}</td><td>${p.st || 0}</td><td>${p.d || 0}</td><td>${esc(p.ld || '')}</td><td>${Object.values(p.lv || {}).reduce((a, b) => a + b, 0)}</td></tr>`).join('')}</table>${rows.length ? '' : '<div class="mu">Nobody yet.</div>'}</div>
      <div class="k"><b>Students by class</b><div class="mu">${Object.entries(cls).sort().map(([c, n]) => esc(c) + ': ' + n).join(' · ') || '-'}</div></div>`;
  }
  async function showLog(id) {
    try { const l = (await get('log/' + id, 'orderBy="$key"&limitToLast=12')) || {};
      const el = document.getElementById('plc-log'); if (el) el.innerHTML = Object.values(l).reverse().map(x => esc(new Date(x.t).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' }) + ' · ' + ({ prac: 'practice', test: 'test', qod: 'question of the day', speak: 'speaking' }[x.k] || x.k) + ' · ' + x.tr + (x.l ? ' L' + x.l : '') + ' · ' + x.s + '/' + x.of)).join('<br>') || 'No tries yet';
    } catch (e) {}
  }
  function qbank() {
    if (!S.qs) { loadAll().then(draw); return '<div>Loading…</div>'; }
    const tid = S.a.t || 'quant', t = track(tid), n0 = dayNo(), ap = allApt();
    const days = [0, 1, 2, 3, 4, 5, 6].map(k => { const n = n0 + k; return { d: ist(Date.now() + k * 864e5), w: S.bank.words[n % S.bank.words.length].w, q: ap.length ? ap[(n * 7) % ap.length].q : '' }; });
    return `<div class="row">${back()}<h2>📚 QUESTION BANK</h2><span class="pill" style="background:#ffc9c9">Super Admin only</span></div>
      <div class="k" style="background:var(--li)"><b>📅 Coming next</b>${days.map(x => `<div class="mu">${x.d} · <b>${esc(x.w)}</b> · ${esc(x.q)}</div>`).join('')}</div>
      <div class="row">${S.bank.tracks.map(x => `<button class="b ${x.id === tid ? 'dk' : 'w'}" onclick="PLC.go('qbank',{t:'${x.id}'})">${x.emoji} ${esc(x.name)}</button>`).join('')}</div>
      ${t.levels.map(l => `<div class="k"><b>Level ${l.n} · ${esc(l.name)}</b> <span class="pill">🏷 ${esc(l.tag)}</span><div class="mu">Lesson: ${l.cards.map(c => esc(c.t)).join(' · ')}</div>
        <table><tr><th>Question</th><th>Answer</th><th>% right</th><th>Tries</th><th></th></tr>${l.qs.map(q0 => { const q = qOf(q0), s = S.qs[q.id] || {}, h = S.hide[q.id];
          return `<tr style="${h ? 'opacity:.45' : ''}"><td>${esc(q.q)}</td><td>${esc(q.o[q.a])}</td><td><b style="color:${!s.n ? '#6B5F55' : s.ok / s.n >= .6 ? '#1E7B3A' : '#B3261E'}">${s.n ? Math.round((s.ok || 0) * 100 / s.n) + '%' : '–'}</b></td><td>${s.n || 0}</td>
          <td style="white-space:nowrap"><button class="b w" onclick="PLC.hide('${q.id}')">${h ? '👁 Show' : '🙈 Hide'}</button> <button class="b w" onclick="PLC.edit('${q.id}')">✎</button></td></tr>`; }).join('')}</table></div>`).join('')}
      <div class="k mu">🙈 Hide takes a question out for everyone from the next refresh. ✎ Edit changes the text / options / answer (saved on top of the bank). New questions: ask Claude to add them to learn/bank.json.</div>`;
  }
  function findQ(id) { for (const t of S.bank.tracks) for (const l of t.levels) for (const q of l.qs) if (q.id === id) return qOf(q); }
  async function hide(id) { const v = !S.hide[id]; S.hide[id] = v; await put('PATCH', 'hide', { [id]: v || null }); draw(); }
  async function edit(id) {
    const q = findQ(id); const t = prompt('Question', q.q); if (t == null) return;
    const o = prompt('Options separated by |', q.o.join(' | ')); if (o == null) return;
    const opts = o.split('|').map(s => s.trim()).filter(Boolean); const a = prompt('Correct option number (1-' + opts.length + ')', q.a + 1); if (a == null) return;
    const e = prompt('Explanation', q.e); if (e == null) return;
    const v = { q: t, o: opts, a: Math.max(0, Math.min(opts.length - 1, (+a || 1) - 1)), e }; S.qx[id] = v; await put('PUT', 'qx/' + id, v); draw();
  }
  function csv() {
    const L = [['Name', 'Class', 'Role', 'Ready', 'XP', 'Streak', 'Days', 'Last', 'Levels']].concat(Object.values(S.all || {}).map(p => [p.n, p.c, p.r, p.rs || 0, p.xp || 0, p.st || 0, p.d || 0, p.ld || '', JSON.stringify(p.lv || {})]));
    const txt = L.map(r => r.map(x => '"' + String(x).replace(/"/g, '""') + '"').join(',')).join('\n');
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([txt], { type: 'text/csv' })); a.download = 'placement-' + ist() + '.csv'; a.click();
  }


  // ── v4 (user, 19-Oct-2026): the student APP page is history & review only - progress, history, solutions, tricks, certificates.
  //    Practice, tests and speaking happen in the Davan widget; every screen sends the student back there. Opened with o.hist = true.
  const MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const when = t => { const d = new Date(t + 330 * 60000), h = d.getUTCHours(); return d.getUTCDate() + ' ' + MON[d.getUTCMonth()] + ' · ' + ((h % 12) || 12) + ':' + String(d.getUTCMinutes()).padStart(2, '0') + (h < 12 ? ' am' : ' pm'); };
  const KIND = { qod: '❓ Question of the day', speak: '🎤 Speaking', mock: '📝 Mock test', prac: '✍️ Practice', test: '🏁 Level test', word: '💬 Word of the day', ok: '✅ Quick answer' };
  const wbar = t => `<div class="k" style="background:${GRAD.gold}"><div style="font-weight:800;font-size:15px;line-height:1.45">${t}</div><div class="row" style="margin-top:8px"><button class="b dk" onclick="PLC.install()">📲 Davan widget</button></div></div>`;
  const hback = t => `<div class="row" style="margin-bottom:6px"><button class="b w" style="padding:8px 12px" onclick="PLC.go('hhome')">←</button><h2 style="flex:1">${t}</h2></div>`;
  const doneLv = t => Math.min(t.levels.filter(l => !l.pro).length, lv(t.id));
  const SECS = [['📊', 'My progress', 'Ready score, streak, level of every track'], ['📜', 'My history', 'Every practice, test, mock and speaking session'], ['📖', 'Solutions & tricks', 'Lessons, formulas, answers and explanations of the levels you cleared'], ['💡', 'Placement tips', 'Resume, interview and campus-drive tips'], ['🏅', 'Certificates', 'Download the ones you earned']];
  function lockedList() {
    return `<div class="k" style="background:#f1ece4"><div class="kick" style="color:#6B5F55">🔒 OPENS AFTER YOUR FIRST ANSWER ON THE WIDGET</div>` +
      SECS.map(([e, t, d]) => `<div class="row" style="opacity:.55;margin-top:8px;flex-wrap:nowrap"><span style="font-size:22px">${e}</span><div style="flex:1"><div style="font-weight:800">${t} 🔒</div><div class="mu">${d}</div></div></div>`).join('') + '</div>';
  }
  function hhome() {
    const p = P(), r = ready(), ini = (S.o.name || '?').split(' ').map(x => x[0]).join('').slice(0, 2).toUpperCase();
    const tr = tracks().filter(t => !t.levels.every(l => l.pro));
    const tiles = [['hlog', '📜', 'My history'], ['hsol', '📖', 'Solutions & tricks'], ['htips', '💡', 'Placement tips'], ['cert', '🏅', 'Certificates']];
    return `<div class="k" style="background:${GRAD.gold}"><div class="bb" style="font-size:34px">🎯 MY PLACEMENT</div><div style="font-weight:700;margin-top:4px">${esc(S.o.name || '')} · history, solutions &amp; certificates</div></div>` +
      wbar('Practise, take tests and speak in your <b>Davan widget</b> - that is where you get ready for campus drives. This page keeps your record.') +
      `<div class="k"><div class="kick">📊 MY PROGRESS</div><div class="g2" style="grid-template-columns:repeat(4,minmax(0,1fr));gap:8px;margin-top:8px;text-align:center">` +
      [['🎯', r.all + '%', 'ready'], ['🔥', p.st || 0, 'day streak'], ['📅', p.d || 0, 'days'], ['⭐', p.xp || 0, 'XP']].map(([e, v, l]) => `<div style="background:var(--ye);border:2px solid var(--ink);border-radius:12px;padding:8px 2px"><div style="font-size:18px">${e}</div><div class="bb" style="font-size:22px">${v}</div><div class="mu" style="font-size:11px">${l}</div></div>`).join('') + `</div>` +
      tr.map(t => { const n = doneLv(t), tot = t.levels.filter(l => !l.pro).length, pc = Math.round(n * 100 / tot); return `<div style="margin-top:10px"><div class="row" style="justify-content:space-between"><b>${t.emoji} ${esc(t.name)}</b><span class="mu">level ${n} / ${tot}</span></div><div style="height:10px;border:2px solid var(--ink);border-radius:8px;background:#fff;overflow:hidden"><div style="width:${pc}%;height:100%;background:${GRAD.tech}"></div></div></div>`; }).join('') + `</div>` +
      `<div class="g2" style="grid-template-columns:repeat(2,minmax(0,1fr));gap:10px">${tiles.map(([v, e, t]) => `<button class="b w" style="padding:16px 8px;font-size:15px" onclick="PLC.go('${v}')"><div style="font-size:26px">${e}</div>${t}</button>`).join('')}</div>` +
      wbar('Keep your 🔥 streak going - open the 🎯 Placement page on your widget and clear the next level.');
  }
  function hlog() {
    if (!S.hl) {
      get('log/' + S.o.id, 'orderBy=%22$key%22&limitToLast=100').then(r => { S.hl = Object.values(r || {}).filter(x => x && x.t).sort((a, b) => b.t - a.t); if (S.v === 'hlog') draw(); }).catch(() => { S.hl = []; S.hlErr = 1; if (S.v === 'hlog') draw(); });
      return hback('📜 MY HISTORY') + '<div class="mu">Loading…</div>';
    }
    const mk = S.bank.mocks || [];
    const row = x => {
      const t = track(x.tr), m = mk.find(q => q.id === x.tr), nm = t ? t.emoji + ' ' + t.name : m ? m.name || m.id : x.tr || '';
      const sc = x.of > 1 ? (x.of === 100 ? x.s + '%' : x.s + ' / ' + x.of) : (x.s ? '✓ right' : '✗ wrong');
      const good = x.of > 1 ? x.s * 100 / x.of >= 65 : !!x.s;
      const pk = x.pk ? ` onclick="PLC.go('hpick',{i:${S.hl.indexOf(x)}})" style="margin:8px 0;padding:10px 12px;cursor:pointer"` : ` style="margin:8px 0;padding:10px 12px"`;
      return `<div class="k"${pk}><div class="row" style="justify-content:space-between;flex-wrap:nowrap"><div><div style="font-weight:800">${KIND[x.k] || esc(x.k || 'Session')}</div><div class="mu">${esc(nm)}${x.l ? ' · level ' + x.l : ''}</div></div><div style="text-align:right"><span class="pill" style="background:${good ? 'var(--gr)' : 'var(--ro)'}">${sc}</span><div class="mu" style="font-size:11px;margin-top:2px">${when(x.t)}</div></div></div>${x.pk ? '<div class="mu" style="margin-top:6px;font-weight:800;color:#5B3E96">▸ See my answers</div>' : ''}</div>`;
    };
    return hback('📜 MY HISTORY') + (S.hl.length ? `<div class="mu">Your last ${S.hl.length} sessions, newest first.</div>` + S.hl.map(row).join('') : `<div class="k">${S.hlErr ? 'Could not load your history - check the internet.' : 'Nothing yet - your practice, tests and mocks from the widget show here.'}</div>`) +
      wbar('Every session you finish in the widget is added here. Go and add one today!');
  }
  // v4: one finished session with what the student picked (log row field pk = "qid:pick,...", saved by widget w252 / w303 onwards)
  function hpick() {
    const x = (S.hl || [])[S.a.i];
    if (!x || !x.pk) return hlog();
    const t = track(x.tr), nm = t ? t.emoji + ' ' + t.name : x.tr || '';
    const items = String(x.pk).split(',').map(z => { const [id, pk] = z.split(':'); const q = findQ(id); return q ? { q: qOf(q), pick: parseInt(pk, 10) } : null; }).filter(Boolean);
    return `<div class="row" style="margin-bottom:6px"><button class="b w" style="padding:8px 12px" onclick="PLC.go('hlog')">←</button><h2 style="flex:1">${KIND[x.k] || 'SESSION'}</h2></div><div class="k"><b>${esc(nm)}${x.l ? ' · level ' + x.l : ''}</b><div class="mu">${when(x.t)} · ${x.of > 1 ? x.s + ' / ' + x.of : x.s ? '✓ right' : '✗ wrong'}</div></div>` +
      items.map((m, i) => { const q = m.q, ok = m.pick === q.a; return `<div class="k" style="background:${ok ? 'var(--gr)' : 'var(--ro)'}"><div style="font-weight:800">${i + 1}. ${esc(q.q)}</div>` +
        (q.o || []).map((o, j) => `<div style="margin-top:6px;padding:6px 10px;border:2px solid var(--ink);border-radius:10px;background:${j === q.a ? '#cdeccf' : j === m.pick ? '#f8c9cd' : '#fff'}">${j === q.a ? '✅ ' : j === m.pick ? '❌ ' : ''}${esc(o)}${j === m.pick ? ' <b>← you chose</b>' : ''}</div>`).join('') + (q.e ? `<div style="margin-top:8px;line-height:1.5">💡 ${esc(q.e)}</div>` : '') + '</div>'; }).join('') +
      (items.length ? '' : '<div class="k">These questions are no longer in the bank.</div>') + wbar('Wrong ones are the best teachers - try them again in the widget.');
  }
  function hsol() {
    const tr = tracks().filter(t => !t.levels.every(l => l.pro));
    return hback('📖 SOLUTIONS &amp; TRICKS') + `<div class="mu">Open a level you have cleared to see its lessons, formulas and tricks, and every question with the answer and why.</div>` +
      tr.map(t => { const n = doneLv(t), tot = t.levels.filter(l => !l.pro).length;
        return `<div class="k"><div class="row" style="justify-content:space-between"><b>${t.emoji} ${esc(t.name)}</b><span class="mu">${n} / ${tot} cleared</span></div><div class="row" style="margin-top:8px">` +
          t.levels.filter(l => !l.pro).map(l => l.n <= n ? `<button class="b w" style="padding:6px 10px" onclick="PLC.go('hlevel',{t:'${t.id}',l:${l.n}})">${l.n} · ${esc(l.name)}</button>` : `<span class="pill" style="background:#eee;color:#888">🔒 ${l.n}</span>`).join('') + '</div></div>'; }).join('') +
      wbar('Locked levels open when you clear them in the widget.');
  }
  function hlevel() {
    const t = track(S.a.t), l = t && t.levels.find(x => x.n === S.a.l); if (!l || l.n > lv(t.id)) return hsol();
    const qs = qsOf(t, l);
    return `<div class="row" style="margin-bottom:6px"><button class="b w" style="padding:8px 12px" onclick="PLC.go('hsol')">←</button><h2 style="flex:1">${t.emoji} ${esc(t.name.toUpperCase())} · LEVEL ${l.n}</h2></div><div class="k" style="background:var(--cr)"><b>${esc(l.name)}</b><div class="mu">🏷 ${esc(l.tag)}</div></div>` +
      '<div class="kick" style="margin:10px 0 0">📖 LESSON &amp; TRICKS</div>' +
      (l.cards || []).map(c => `<div class="k"><div style="font-weight:800">${esc(c.t)}</div><div style="margin-top:4px;line-height:1.5">${esc(c.b)}</div>${c.box ? `<div style="margin-top:8px;padding:8px 10px;background:var(--ye);border:2px dashed var(--ink);border-radius:12px;font-weight:800">⚡ ${esc(c.box)}</div>` : ''}${c.kn ? `<div class="mu" style="margin-top:6px">${esc(c.kn)}</div>` : ''}</div>`).join('') +
      '<div class="kick" style="margin:14px 0 0">✍️ QUESTIONS WITH ANSWERS</div>' +
      qs.map((q, i) => `<div class="k"><div style="font-weight:800">${i + 1}. ${esc(q.q)}</div>${(q.o || []).map((o, j) => `<div style="margin-top:6px;padding:6px 10px;border:2px solid var(--ink);border-radius:10px;background:${j === q.a ? 'var(--gr)' : '#fff'}">${j === q.a ? '✅ ' : ''}${esc(o)}</div>`).join('')}${q.e ? `<div style="margin-top:8px;line-height:1.5">💡 ${esc(q.e)}</div>` : ''}</div>`).join('') +
      wbar('Understood this level? Take the next one in your widget.');
  }
  function htips() {
    const tr = tracks().filter(t => !t.levels.every(l => l.pro));
    const tricks = tr.map(t => { const n = doneLv(t), items = t.levels.filter(l => !l.pro && l.n <= n).map(l => (l.cards || []).filter(c => c.box).map(c => `<div style="margin-top:6px"><span class="mu">${esc(l.name)} · ${esc(c.t)}</span><div style="font-weight:800">⚡ ${esc(c.box)}</div></div>`).join('')).join('');
      return items ? `<div class="k"><b>${t.emoji} ${esc(t.name)}</b>${items}</div>` : ''; }).join('');
    return hback('💡 TRICKS &amp; TIPS') + (tricks ? '<div class="kick">⚡ FORMULAS &amp; SHORTCUTS FROM YOUR CLEARED LEVELS</div>' + tricks : '') +
      '<div class="kick" style="margin-top:12px">🎓 PLACEMENT TIPS</div>' +
      (S.bank.tips || []).map(x => `<div class="k"><div class="kick">${esc(x.c)}</div><div style="font-weight:800;margin-top:2px">${esc(x.t)}</div><div style="margin-top:4px;line-height:1.5">${esc(x.b)}</div></div>`).join('') +
      wbar('Use these tricks in your next widget practice.');
  }

  // ── public ──
  async function open(el, o) {
    css(); S.el = el; S.o = o; S.prog = null; S.hl = null; S.v = o.view || (o.hist ? 'hhome' : 'home'); S.a = {};
    el.innerHTML = '<div class="plc">Loading 🎯 Placement…</div>';
    try { await loadBank(); S.prog = (await get('prog/' + o.id)) || {}; } catch (e) { el.innerHTML = '<div class="plc">Could not load Placement: ' + esc(e.message) + '</div>'; return; }
    if (o.role === 'stu' && !o.preview && !(S.prog.xp > 0)) S.v = 'gate';   // v2 (user, 18-Oct): students unlock the app page by answering on the widget
    draw();
  }
  window.PLC = {
    open, go: (v, a) => { go(v, a); if (v === 'report' && a && a.sel) showLog(a.sel); }, say, slow: t => { try { const u = new SpeechSynthesisUtterance(t); u.lang = 'en-IN'; u.rate = .6; speechSynthesis.speak(u); } catch (e) {} },
    start, pick, next, qod, mic, hide, edit, csv, mock, install: () => { if (S.o.onInstall) S.o.onInstall(); }, recheck: () => open(S.el, S.o), reload: () => { S.all = null; S.qs = null; draw(); },
    previewOf: id => { const p = S.all[id] || {}; if (!S.o.preview) S.back = S.o; S.v = 'home'; open(S.el, { id, name: p.n, cls: p.c, role: p.r, course: (String(p.c).toUpperCase().replace(/[.\s]/g, '').match(/BCA|BBA|BCOM/) || [''])[0], preview: true, sa: false, onHome: S.back && S.back.onHome }); },
    me: () => { const b = S.back; S.back = null; S.v = 'home'; if (b) open(S.el, b); }, home: () => { if (S.o.onHome) S.o.onHome(); },
    get _el() { return S.el; }, key, courseOf: c => (String(c || '').toUpperCase().replace(/[.\s]/g, '').match(/BCA|BBA|BCOM/) || [''])[0]
  };
})();
