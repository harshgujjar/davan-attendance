(function () {
C._installJudge("(function () {\nC.numbers = function (text, loose) {\n    var t = String(text || '').toLowerCase().replace(/(\\d),(\\d)/g, '$1$2').replace(/-/g, ' ').replace(/[^a-z0-9 ]/g, ' ');\n    var w = t.split(/\\s+/).filter(Boolean), out = [], cur = null;\n    function end() { if (cur !== null) { out.push(cur); cur = null; } }\n    for (var i = 0; i < w.length; i++) {\n      var x = w[i];\n      if (/^\\d+$/.test(x)) { end(); out.push(+x); continue; }\n      if (/^\\d+(st|nd|rd|th)$/.test(x)) { end(); out.push(parseInt(x, 10)); continue; }\n      if (x in ONES) {\n        if (cur !== null && cur >= 20 && cur % 10 === 0 && cur % 100 !== 0 && ONES[x] < 10) cur += ONES[x];   /* fifty six */\n        else if (cur !== null && cur % 100 === 0 && cur > 0) cur += ONES[x];                      /* hundred and two */\n        else { end(); cur = ONES[x]; }\n        continue;\n      }\n      if (x in TENS) { if (cur !== null && cur % 100 === 0 && cur > 0) cur += TENS[x]; else { end(); cur = TENS[x]; } continue; }\n      if (x === 'hundred') { cur = (cur === null ? 1 : cur) * 100; continue; }\n      if (x === 'and' && cur !== null && cur % 100 === 0) continue;\n      if (loose && x in SOUND) { end(); out.push(SOUND[x]); continue; }\n      end();\n    }\n    end();\n    return out;\n  };\nC.answerNum = function (text) {\n    var n = C.numbers(text, false);\n    if (!n.length) n = C.numbers(text, true);\n    return n.length ? n[n.length - 1] : null;\n  };\nC.hasNum = function (text, want) { return C.numbers(text, true).indexOf(want) >= 0; };\nC.tableOne = function (text, a, b) {\n    var t = String(text || '').toLowerCase().replace(/\\b(ja+|za+|jha|is|are|equals?|equal to|into|times|multiplied by|x)\\b/g, ' , ').replace(/\\bones\\b/g, 'one');\n    var ans = a * b;\n    /* one short word that Google writes instead of the answer (\"the\" / \"tree\" for three - log 01-Nov 19:09): right ONLY when it\n       sounds like THE answer; any other single filler word = not heard */\n    var SOUNDS = { 1: 'one won van wan', 2: 'two to too tu do', 3: 'three the tree free tea three', 4: 'four for fore far', 5: 'five fife hive', 6: 'six sex sicks sick',\n      7: 'seven heaven', 8: 'eight ate hate it', 9: 'nine nein line mine', 10: 'ten tan tin then when', 11: 'eleven', 12: 'twelve' };\n    var one = String(text || '').toLowerCase().replace(/[^a-z ]/g, ' ').trim().split(/\\s+/);\n    if (one.length === 1 && one[0] && !/\\d/.test(String(text)) && SOUNDS[ans] && SOUNDS[ans].split(' ').indexOf(one[0]) >= 0) return { n: ans, ok: true };\n    var nums = C.numbers(t, true);\n    if (!nums.length) return { n: null, ok: false };\n    /* mostly other words (\"18 years pilot\", \"computer\") = not an answer -> ask again, never mark wrong (log 01-Nov 19:08) */\n    var KNOWN = /^(\\d+|zero|oh|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fourty|fifty|sixty|seventy|eighty|ninety|hundred|and|won|to|too|tu|for|fore|ate|tree|free|sex|sicks|nein|tin|tan|ja+|za+|jha|is|are|equals?|equal|into|times|multiplied|by|x|ones|the|a|its|it's|answer)$/;\n    var w = String(text || '').toLowerCase().replace(/[^a-z0-9' ]/g, ' ').split(/\\s+/).filter(Boolean), junk = w.filter(function (x) { return !KNOWN.test(x); }).length;\n    if (junk >= 2 && junk > w.length / 2 && nums.indexOf(ans) < 0) return { n: null, ok: false, junk: true };\n    /* v43 (Mangala, log 15-Nov 19:43): \"eight three za twenty four\" while the app is on 8 x 4 = she is still saying line 3 -> not wrong, listen on */\n    if (nums.length >= 3 && nums[0] === a && nums[1] !== b && nums[1] >= 1 && nums[1] <= 20 && nums[2] === a * nums[1] && nums.indexOf(ans) < 0) return { n: null, ok: false, other: nums[1] };\n    var last = nums[nums.length - 1];\n    if (last === ans) return { n: ans, ok: true };\n    /* v44 (Mangala, log 16-Nov 18:15-18:18, 12 x 5): \"sixty\" heard as \"sixteen\" again and again - the -ty / -teen twin of the answer (60 / 16, 30 / 13 ... 90 / 19)\n       is never itself the answer of that line, so it counts as the answer */\n    if (ans % 10 === 0 && ans >= 30 && ans <= 90 && last === 10 + ans / 10 && nums.indexOf(a * b) < 0) return { n: ans, ok: true, twin: true };\n    /* v43 (Mangala, log 15-Nov 19:44-19:45, 8 x 2): the right answer said FIRST, then noise (\"sixteen ... one\", \"sixteen twenty six ten\") = right;\n       a changed answer comes with words (\"sixteen no eighteen\") and stays judged by the last number */\n    var rest = nums.slice(); if ((rest[0] === a && rest[1] === b) || (rest[0] === b && rest[1] === a)) rest = rest.slice(2);\n    if (rest[0] === ans && ans !== a && ans !== b && !/\\b(no|not|sorry|wait|mean|actually)\\b/.test(String(text).toLowerCase())) return { n: ans, ok: true };\n    /* v49 (Aryan, log 03-Nov 21:01: 17 x 10 - \"one seventy\" was marked 70): in India \"one seventy\" = 170, \"two forty\" = 240 (no \"hundred\") */\n    if (ans >= 100) for (var q = 0; q + 1 < nums.length; q++) if (nums[q] >= 1 && nums[q] <= 9 && nums[q + 1] >= 10 && nums[q + 1] <= 99 && nums[q] * 100 + nums[q + 1] === ans) return { n: ans, ok: true };\n    /* only the question's own numbers (\"7 * 4 =\", \"4 7 ja ...\") = the child is still saying the question, not an answer -> listen on\n       (log 01-Nov 19:50: \" 7 * 4 =\" was marked wrong as 4) */\n    if (nums.length <= 3 && nums.every(function (x) { return x === a || x === b; }) && String(text || '').replace(/\\d/g, '').length < 40\n        && !/\\b(\\d+)\\s*$/.test(String(text).replace(/[=\\s]+$/, '') + ' x') ) return { n: null, ok: false, question: true };\n    var digits = nums.join(''), pre = [String(a) + String(b), String(b) + String(a)];\n    for (var i = 0; i < pre.length; i++) if (digits.length > pre[i].length && digits.indexOf(pre[i]) === 0 && digits.slice(pre[i].length) === String(ans)) return { n: ans, ok: true };\n    /* v48 (Vihaan, log 17-Nov 11:14, 13 x 9): \"one one seven\" - the three digits said one by one - is 117 */\n    if (ans >= 100 && nums.length >= 2 && nums.every(function (x) { return x <= 9; }) && digits === String(ans)) return { n: ans, ok: true };\n    /* v49 core (Aryan, TV log 27-Nov 22:09, 25 x 6): \"one twenty five\" was read as 25 (then \"not sure, say it again\" again and again) - in India it is 125:\n       a big answer said the short way is read as that number, so a WRONG answer is told as wrong at once */\n    if (ans >= 100 && nums.length >= 2) { var p1 = nums[nums.length - 2], p2 = nums[nums.length - 1]; if (p1 >= 1 && p1 <= 9 && p2 >= 10 && p2 <= 99 && !/hundred/.test(String(text).toLowerCase())) last = p1 * 100 + p2; }\n    /* v49 core (TV log 27-Nov 22:05, 12 x 9): \"one hundred\" ... \"eight\" - the pause cut the answer in two; only the hundreds of the answer = not finished yet, listen on */\n    if (ans > 100 && ans % 100 && last === Math.floor(ans / 100) * 100 && /hundred\\s*$/.test(String(text).toLowerCase().replace(/[^a-z ]/g, ' ').trim())) return { n: null, ok: false, part: true };\n    return { n: last, ok: false };\n  };\nvar ATOM = { zero: 0, oh: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10, eleven: 11, twelve: 12,\n    thirteen: 13, fourteen: 14, fifteen: 15, sixteen: 16, seventeen: 17, eighteen: 18, nineteen: 19, twenty: 20, thirty: 30, forty: 40,\n    fourty: 40, fifty: 50, sixty: 60, seventy: 70, eighty: 80, ninety: 90, won: 1, to: 2, too: 2, for: 4, ate: 8 };\nvar SEP = /^(ja+|za+|jha|is|are|into|times|equals?|equal|x)$/;\nfunction atomsOf(words) { var a = []; words.forEach(function (w) { if (/^\\d+$/.test(w)) a.push({ v: +w, d: true }); else if (w === 'hundred') a.push({ v: 100, h: true }); else if (w in ATOM) a.push({ v: ATOM[w] }); }); return a; }\nfunction oneNum(at) {\n    if (!at.length) return null;\n    var v = 0, cur = 0, i = 0;\n    if (at.length === 1) return at[0].h ? 100 : at[0].v;\n    for (i = 0; i < at.length; i++) {\n      var x = at[i];\n      if (x.h) { cur = (cur || 1) * 100; continue; }\n      if (x.d) { if (i !== at.length - 1 || cur % 100 !== 0) return null; cur += x.v; continue; }\n      if (x.v >= 20 && x.v % 10 === 0) { if (cur % 100 !== 0) return null; cur += x.v; continue; }\n      if (x.v < 10) { if (cur % 10 !== 0 || (cur % 100 >= 10 && cur % 100 < 20)) return null; if (i > 0 && !(at[i - 1].v >= 20 && at[i - 1].v % 10 === 0) && !at[i - 1].h) return null; cur += x.v; continue; }\n      if (cur % 100 !== 0) return null; cur += x.v;\n    }\n    return cur;\n  }\nfunction readNums(at, i) {               /* every way to read 1-4 atoms from i as one number: [{v, j}] */\n    var out = [];\n    for (var n = 1; n <= 4 && i + n <= at.length; n++) {\n      var part = at.slice(i, i + n); if (part.some(function (x) { return x.sep || x.unk; })) break;\n      var v = oneNum(part); if (v !== null) out.push({ v: v, j: i + n });\n    }\n    return out;\n  }\nfunction skipSep(at, i) { while (i < at.length && (at[i].sep || at[i].unk)) i++; return i; }\nC.numsIn = function (text) {\n    var words = String(text || '').toLowerCase().replace(/\\[unk\\]/g, ' unk ').replace(/[^a-z0-9 ]/g, ' ').split(/\\s+/).filter(Boolean), at = [], out = [];\n    words.forEach(function (w) {\n      if (SEP.test(w)) at.push({ sep: true }); else if (w === 'unk') at.push({ unk: true });\n      else if (/^\\d+$/.test(w)) at.push({ v: +w, d: true }); else if (w === 'hundred') at.push({ v: 100, h: true }); else if (w in ATOM) at.push({ v: ATOM[w] });\n    });\n    for (var i = 0; i < at.length;) {\n      var done = false;\n      for (var n = Math.min(4, at.length - i); n >= 1 && !done; n--) {\n        var part = at.slice(i, i + n); if (part.some(function (x) { return x.sep || x.unk; })) continue;\n        var v = oneNum(part); if (v !== null) { out.push(v); i += n; done = true; }\n      }\n      if (!done) i++;\n    }\n    return out;\n  };\nC.parseRecite = function (text, t, up) {\n    var words = String(text || '').toLowerCase().replace(/\\[unk\\]/g, ' unk ').replace(/[^a-z0-9 ]/g, ' ').split(/\\s+/).filter(Boolean), at = [];\n    words.forEach(function (w) {\n      if (SEP.test(w)) at.push({ sep: true, w: w }); else if (w === 'unk') at.push({ unk: true });\n      else if (/^\\d+$/.test(w)) at.push({ v: +w, d: true }); else if (w === 'hundred') at.push({ v: 100, h: true }); else if (w in ATOM) at.push({ v: ATOM[w] });\n    });\n    var lineAt = function (i, b) {            /* does \"t b\" (b = the given line, or any line when b = 0) start at i? */\n      i = skipSep(at, i); var ts = readNums(at, i).filter(function (x) { return x.v === t; });\n      for (var q = 0; q < ts.length; q++) { var bs = readNums(at, ts[q].j).filter(function (x) { return b ? x.v === b : x.v >= 1 && x.v <= up; }); if (bs.length) return bs[0]; }\n      return null;\n    };\n    var out = [], i = 0, prevB = 0, guard = 0;\n    while (i < at.length && guard++ < 400) {\n      i = skipSep(at, i);\n      var bHit = lineAt(i, prevB + 1) || lineAt(i, 0);\n      if (!bHit && prevB + 1 <= up) {   /* v34 (22:48 \"two into two\" = \"2 one za 2\": a fast \"one\" heard as \"into\"): table · ja · next line's answer */\n        var t0 = readNums(at, i).filter(function (x) { return x.v === t; })[0];\n        if (t0 && t0.j < at.length && at[t0.j].sep) { var nb = prevB + 1, an = readNums(at, skipSep(at, t0.j)).filter(function (x) { return x.v === t * nb; })[0];\n          if (an && (lineAt(an.j, nb + 1) || skipSep(at, an.j) >= at.length)) { out.push({ b: nb, said: an.v }); i = an.j; prevB = nb; continue; } }\n      }\n      if (!bHit) { i++; continue; }\n      var b = bHit.v, k = skipSep(at, bHit.j), hadUnk = false;\n      for (var z = bHit.j; z < k; z++) if (at[z].unk) hadUnk = true;\n      var best = null;\n      var cand = function (from, pen) {\n        readNums(at, from).forEach(function (c) {\n          var nxt = lineAt(c.j, b + 1), any = nxt || lineAt(c.j, 0), end = skipSep(at, c.j) >= at.length;\n          var sc = (c.v === t * b ? 2 : 0) + (nxt ? 4 : any ? 2 : end ? 3 : 0) + (c.j - k) * 0.1 - pen;\n          if (!best || sc > best.sc) best = { v: c.v, j: c.j, sc: sc };\n        });\n      };\n      cand(k, 0);\n      /* v33 (Vihaan's real recording 01-Nov 22:34: \"two six two twelve\"): a fast \"za\" is often heard as \"two\" / \"to\" - try the answer\n         after one such word too */\n      if (k < at.length && !at[k].sep && !at[k].unk && (at[k].v === 2 || at[k].v === t)) cand(skipSep(at, k + 1), 0.5);\n      if (best && (best.sc >= 2 || !lineAt(k, 0))) {\n        /* \"twenty\" said fast is heard as \"into ten\" / \"into four\" (22:35 \"two ten into ten\"): not wrong - ask that line again */\n        var fz = best.v !== t * b && k > 0 && at[k - 1].sep && at[k - 1].w === 'into' && t * b >= 20 && t * b < 30 && (best.v === 10 ? t * b === 20 : best.v === t * b - 20);\n        /* out of order + the answer is the NEXT line's (heard \"one two into seven\" where he said \"one seven za seven\"): the line number was misheard */\n        if (b !== prevB + 1 && prevB + 1 <= up && best.v !== t * b && best.v === t * (prevB + 1)) b = prevB + 1;\n        out.push(fz ? { b: b, said: best.v, fz: true } : { b: b, said: best.v }); i = best.j; }\n      else { out.push({ b: b, said: null, unk: hadUnk }); i = k; }\n      prevB = b;\n    }\n    return out;\n  };\nC.checkRecite = function (text, t, up) {\n    var facts = C.parseRecite(text, t, up), seen = {}, wrong = [], done = [];\n    /* he goes back and says lines again (log 21:46: ... one seven seven, one five za five, one six six ...): his LATEST version of each line counts */\n    /* v45 (user, 03-Nov: \"3 x 8 = 24, he says it, it is not taken\" - the engine heard \"three ONE twenty four\", \"three za into twenty four\"): the line\n       number is the part it loses; an answer above the table's range (12, 15, 18 ... in table 3) is unique to ONE line, so a heard answer\n       that belongs to another line is that line's answer, and a line whose answer is heard anywhere counts */\n    var big = {}; for (var bb = 1; bb <= up; bb++) { var vv = t * bb; if (vv > up && vv !== t) big[vv] = bb; }\n    var raw = facts; facts = [];\n    raw.forEach(function (f, k) {\n      if (f.said !== null && f.said !== t * f.b && big[f.said]) {          /* \"three ONE twenty four\": the answer belongs to line 8, between its neighbours in the order he said them */\n        var b2 = big[f.said], pb = facts.length ? facts[facts.length - 1].b : 0, nb = raw[k + 1] ? raw[k + 1].b : up + 1;\n        if (pb < b2 && b2 < nb) { facts.push({ b: b2, said: f.said, re: 1 }); return; }\n      }\n      facts.push(f);\n    });\n    var last = {}; facts.forEach(function (f) { if (f.said !== null || last[f.b] === undefined) last[f.b] = f; });\n    facts = Object.keys(last).map(function (b) { return last[b]; }).sort(function (a, b) { return a.b - b.b; });\n    facts.forEach(function (f) {\n      if (f.b < 1 || f.b > up) return;\n      var right = f.said === t * f.b;\n      if (seen[f.b] === undefined || right) seen[f.b] = right;\n      if (!right && f.said !== null && wrong.filter(function (w) { return w.b === f.b; }).length === 0) wrong.push({ b: f.b, said: f.said });\n      if (right) done.push(f.b);\n    });\n    wrong = wrong.filter(function (w) { return !seen[w.b]; });\n    /* v48: line 1 (table x 1 = the table) is the one everybody knows - never asked about, whatever the engine heard */\n    if (seen[1] === undefined || seen[1] === false) { seen[1] = true; wrong = wrong.filter(function (w) { return w.b !== 1; }); done.push(1); }\n    var missing = []; for (var b = 1; b <= up; b++) if (seen[b] === undefined) missing.push(b);\n    var noAns = facts.filter(function (f) { return f.said === null && !seen[f.b]; }).map(function (f) { return f.b; });\n    /* fifteen / fifty, thirteen / thirty ... : the engine can mix them up - ask him to say that line again instead of \"wrong\" */\n    var mix = function (x, y) { for (var d = 3; d <= 9; d++) if ((x === 10 + d && y === 10 * d) || (y === 10 + d && x === 10 * d)) return true; return false; };\n    var fzB = {}; facts.forEach(function (f) { if (f.fz) fzB[f.b] = 1; });\n    /* v43 (his real table-3 recitation 02-Nov 21:18-21:20: \"thirty three\" for 3, \"one\" for twelve, \"ten\" for fifteen - he said it right):\n       an answer that is ONE digit away from the right one (3 / 33, 12 / 1, 15 / 10, 21 / 24 ...) cannot be told from a mishearing, so it is\n       \"unsure\" - that line is asked again alone - never \"wrong\" */\n    var alike = function (x, y) {\n      var a = String(x), b = String(y); if (a === b) return true; if (mix(x, y)) return true;\n      var d = []; for (var i = 0; i <= a.length; i++) d[i] = [i]; for (var j = 1; j <= b.length; j++) d[0][j] = j;\n      for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++) d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));\n      return d[a.length][b.length] <= 1 || (a.length > 1 && b.length > 1 && a.slice(0, -1) === b.slice(0, -1) && Math.abs(+a.slice(-1) - +b.slice(-1)) <= 3 && false);\n    };\n    /* v45 (user, 03-Nov: \"it is the software not hearing, not his mistake\"): the long recitation is the LEAST reliable listening (slow speech, pauses,\n       misheard numbers, lines said twice). It never says \"wrong\" any more: every doubtful line is asked again alone - a short question with only\n       the right answers allowed, where the hearing is good - and THAT decides. */\n    var unsure = wrong.slice(), sure = [];\n    return { ok: !wrong.length && !missing.length && !noAns.length, wrong: sure, unsure: unsure, missing: missing, unclear: noAns, done: done, facts: facts };\n  };\nC.qGrammar = function (a, b) {\n    var p = a * b, ns = {}, ph = [], W = C.numWord;\n    [p, p - a, p + a, p - b, p + b, p - 1, p + 1, p - 2, p + 2, p - 10, p + 10, a + b].forEach(function (n) { if (n >= 0 && n <= 999) ns[n] = 1; });\n    var q = W(a) + ' ' + W(b) + ' ';\n    Object.keys(ns).forEach(function (n) { var w = W(+n); ph.push(w, q + w, q + 'ja ' + w, q + 'into ' + w, 'ja ' + w, a + b === +n ? w : 'is ' + w); });\n    /* v63 (08-Nov, TV: he said \"twenty one\" for 9 x 3 and the app heard \"twenty seven\" = right): a grammar that holds only the right answer and its neighbours\n       forces ANY number onto the nearest one. Every number 1-100 is now allowed as a bare answer (and after the line), so a different number is heard as it is. */\n    for (var m = 1; m <= 100; m++) if (!ns[m]) { var wm = W(m); ph.push(wm, 'ja ' + wm, q + wm, q + 'ja ' + wm); }\n    ph = ph.concat(W(a).split(' '), W(b).split(' '), ['ja', 'za', 'times', 'ready', 'yes', 'stop', 'repeat', 'skip', 'pass', \"i don't know\", \"don't know\", 'no idea', '[unk]']);   /* v49: skip / I don't know heard */\n    return JSON.stringify(ph.filter(function (x, i) { return ph.indexOf(x) === i; }));\n  };\nC.grammar = function (t, up) {\n    var g = 'zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty thirty forty fifty sixty seventy eighty ninety hundred'.split(' ');\n    if (t) {   /* testing one table: only its words - fewer look-alikes (four / forty, two / into) - plus the usual wrong answers */\n      var nums = {}, add = function (n) { if (n >= 0 && n <= 999) C.numWord(n).split(' ').forEach(function (w) { nums[w] = 1; }); };\n      add(t); for (var b = 1; b <= up; b++) { add(b); add(t * b); add(t * b + t); add(t * b - t); add(t * b + 1); add(t * b - 1); add(t * b + 10); add(t * b - 10); }\n      g = Object.keys(nums);\n    }\n    g = g.concat(['ja', 'za', 'into', 'times', 'is', 'equals', 'ready', 'yes', 'stop']);\n    if (t) for (var b = 1; b <= up; b++) { var tb = C.numWord(t) + ' ' + C.numWord(b) + ' ', a = C.numWord(t * b); g.push(tb + 'ja ' + a); g.push(tb + 'into ' + a); g.push(tb + a); }   /* fast: no \"ja\" */\n    g.push('[unk]');\n    return JSON.stringify(g);\n  };\nC.numAlike = function (x, y) {\n    var a = String(x), b = String(y); if (a === b) return true;\n    for (var d = 3; d <= 9; d++) if ((x === 10 + d && y === 10 * d) || (y === 10 + d && x === 10 * d)) return true;\n    var m = []; for (var i = 0; i <= a.length; i++) m[i] = [i]; for (var j = 1; j <= b.length; j++) m[0][j] = j;\n    for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++) m[i][j] = Math.min(m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));\n    return m[a.length][b.length] <= 1;\n  };\nC.numTruncated = function (n, ans) { return n !== null && n < ans && ((ans >= 100 && n < 100) || (ans >= 20 && n < 10) || (ans >= 30 && n <= ans / 4)); };\nC.tableJudge = function (alts, a, b) {\n    alts = (alts || []).filter(Boolean);\n    var first = alts.length ? C.tableOne(alts[0], a, b) : { n: null, ok: false };\n    if (first.ok) return { ok: true, n: first.n, s: alts[0] };\n    for (var i = 1; i < alts.length; i++) { var r = C.tableOne(alts[i], a, b); if (r.ok && first.n === null) return { ok: true, n: r.n, s: alts[i] }; }\n    if (first.n === null) for (var j = 1; j < alts.length; j++) { var r2 = C.tableOne(alts[j], a, b); if (r2.n !== null) return { ok: false, n: r2.n, s: alts[j] }; }\n    var altOk = alts.slice(1).some(function (x) { return C.tableOne(x, a, b).ok; });   /* another guess was right: ask again (\"Did you say 72?\") */\n    return { ok: false, n: first.n, s: alts[0] || '', altOk: altOk, part: !!first.part && !altOk };   /* v49: \"one hundred\" for 108 = only the start - listen on */\n  };\nfunction lev(a, b) {\n    if (Math.abs(a.length - b.length) > 2) return 9;\n    var d = [], i, j; for (i = 0; i <= a.length; i++) d[i] = [i];\n    for (j = 1; j <= b.length; j++) d[0][j] = j;\n    for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++)\n      d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));\n    return d[a.length][b.length];\n  }\nfunction near(w, list) {\n    for (var i = 0; i < list.length; i++) {\n      var x = list[i];\n      if (x === w) return true;\n      if (w.length >= 4 && (x.indexOf(w) === 0 || w.indexOf(x) === 0) && Math.min(x.length, w.length) >= 4) return true;  /* plant / plants */\n      if (w.length >= 5 && lev(w, x) <= 1) return true;\n      if (w.length >= 8 && lev(w, x) <= 2) return true;\n    }\n    return false;\n  }\nC.checkOral = function (item, said) {\n    var got = words(said), keys = C.keysOf(item), hit = [], miss = [];\n    var nums = C.numbers(said, true);\n    keys.forEach(function (k) {\n      var ok = k.split(' ').every(function (p) { return /^\\d+$/.test(p) ? nums.indexOf(+p) >= 0 || got.indexOf(p) >= 0 : near(p, got) || (ONES[p] !== undefined && nums.indexOf(ONES[p]) >= 0); });\n      (ok ? hit : miss).push(k);\n    });\n    var need = item.k ? keys.length : Math.max(1, Math.ceil(keys.length * 0.7));\n    return { ok: hit.length >= need, hit: hit, miss: miss };\n  };\nvar LET = { ay: 'a', eh: 'a', bee: 'b', be: 'b', see: 'c', sea: 'c', she: 'c', dee: 'd', de: 'd', ee: 'e', ef: 'f', eff: 'f', gee: 'g', ji: 'g', jee: 'g',\n    aitch: 'h', edge: 'h', haitch: 'h', eye: 'i', aye: 'i', jay: 'j', kay: 'k', okay: 'k', el: 'l', elle: 'l', em: 'm', en: 'n', oh: 'o', owe: 'o',\n    pee: 'p', pea: 'p', cue: 'q', queue: 'q', are: 'r', ar: 'r', es: 's', ess: 's', tea: 't', tee: 't', you: 'u', yu: 'u', vee: 'v', why: 'y',\n    ex: 'x', zed: 'z', zee: 'z', zet: 'z', ah: 'a', hey: 'a', bi: 'b', si: 'c', pe: 'p', ti: 't', vi: 'v', ze: 'z', jai: 'j', kai: 'k', ell: 'l', double: 'w' };\nC.letters = function (said, word) {\n    word = String(word || '').toLowerCase().replace(/[^a-z]/g, '');\n    var w = String(said || '').toLowerCase().replace(/double u|double you/g, 'w').replace(/[^a-z ]/g, ' ').split(/\\s+/).filter(Boolean);\n    var allOne = w.length > 1 && w.every(function (x) { return x.length === 1 || LET[x]; });\n    if (w.length === 1 && w[0] === word && word.length > 1) return { whole: true, text: w[0] };     /* said the word, not the letters */\n    var s = '';\n    w.forEach(function (x) { if (x.length === 1) s += x; else if (LET[x] && (allOne || w.length > 2)) s += LET[x]; else if (x === 'capital' || x === 'small') return; else s += x; });\n    return { whole: false, text: s };\n  };\nC.checkSpell = function (word, said) {\n    var r = C.letters(said, word), want = String(word).toLowerCase().replace(/[^a-z]/g, '');\n    return { ok: !r.whole && r.text === want, whole: r.whole, got: r.text };\n  };\nC.letterSeq = function (said) {\n    var w = String(said || '').toLowerCase().replace(/double u|double you/g, 'w').replace(/[^a-z ]/g, ' ').split(/\\s+/).filter(Boolean), s = '';\n    w.forEach(function (x) { if (x.length === 1) s += x; else if (LET[x]) s += LET[x]; });\n    return s;\n  };\nvar SIM = ['bdptvcegz', 'mn', 'fsx', 'ajk', 'iy', 'uq'];\nfunction simL(a, b) { for (var i = 0; i < SIM.length; i++) if (SIM[i].indexOf(a) >= 0 && SIM[i].indexOf(b) >= 0) return true; return false; }\nfunction spellTokens(said) {\n    var w = String(said || '').toLowerCase().replace(/double u|double you/g, 'w').replace(/\\[unk\\]/g, ' ? ').replace(/[^a-z? ]/g, ' ').split(/\\s+/).filter(Boolean), t = [];\n    w.forEach(function (x) { if (x === '?') t.push({ u: 1 }); else if (x.length === 1) t.push({ c: x }); else if (LET[x]) t.push({ c: LET[x] }); });\n    return t;\n  }\nfunction spellCost(t, want) {\n    var n = t.length, m = want.length, D = [], i, j;\n    function extra(k) { var x = t[k]; if (x.u) return 0.2; if (x.c === 'e' && t[k + 1] && t[k + 1].c && 'mnflsx'.indexOf(t[k + 1].c) >= 0) return 0.2; return 0.6; }   /* em / en / ef / el / es / ex come back as \"e\" + the letter */\n    function sub(k, c) { var x = t[k]; if (x.u) return 0.3; if (x.c === c) return 0; if (simL(x.c, c) || (x.c === 'e' && 'mnflsx'.indexOf(c) >= 0)) return 0.5; return 1.5; }\n    for (i = 0; i <= n; i++) { D[i] = []; for (j = 0; j <= m; j++) D[i][j] = 0; }\n    for (j = 1; j <= m; j++) D[0][j] = j * 1.2;\n    for (i = 1; i <= n; i++) D[i][0] = D[i - 1][0] + extra(i - 1);\n    for (i = 1; i <= n; i++) for (j = 1; j <= m; j++) D[i][j] = Math.min(D[i - 1][j - 1] + sub(i - 1, want[j - 1]), D[i - 1][j] + extra(i - 1), D[i][j - 1] + 1.2);\n    return D[n][m];\n  }\nC.spellJudge = function (word, alts) {\n    var want = String(word).toLowerCase().replace(/[^a-z]/g, ''), best = null;\n    (alts || []).forEach(function (said) {\n      var low = String(said || '').toLowerCase();\n      if (C.letters(said, want).whole || (!/[a-z]/.test(low.replace(/\\[unk\\]/g, '')) ? false : low.replace(/\\[unk\\]/g, ' ').split(/\\s+/).indexOf(want) >= 0 && !spellTokens(said).length)) { if (!best) best = { kind: 'whole', got: want }; return; }\n      var t = spellTokens(said); if (!t.length) return;\n      var cost = spellCost(t, want);\n      /* he may say it twice or talk before / after: the best stretch of about the word's length counts (small price for the rest) */\n      for (var lo = 0; lo < t.length; lo++) for (var ln = Math.max(1, want.length - 2); ln <= want.length + 2 && lo + ln <= t.length; ln++) if (ln < t.length) cost = Math.min(cost, spellCost(t.slice(lo, lo + ln), want) + 0.3);\n      var hasU = t.some(function (x) { return x.u; }), got = t.map(function (x) { return x.u ? '?' : x.c; }).join('');\n      var kind = cost < 1.0 ? 'ok' : (cost <= 3.4 || hasU || t.length < want.length * 0.6) ? 'unsure' : 'wrong';\n      var rank = { ok: 3, unsure: 2, wrong: 1, whole: 0 };\n      if (!best || rank[kind] > rank[best.kind] || (kind === best.kind && cost < best.cost)) best = { kind: kind, got: kind === 'ok' ? want : got, cost: Math.round(cost * 10) / 10, alike: kind === 'ok' && got !== want };\n    });\n    return best || { kind: 'none', got: '' };\n  };\nC.pickWord = function (said, words) {\n    var toks = String(said || '').toLowerCase().replace(/[^a-z ]/g, ' ').split(/\\s+/).filter(Boolean), best = null;\n    function ed(a, b) { var d = []; for (var i = 0; i <= a.length; i++) { d[i] = [i]; } for (var j = 1; j <= b.length; j++) d[0][j] = j;\n      for (i = 1; i <= a.length; i++) for (j = 1; j <= b.length; j++) d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)); return d[a.length][b.length]; }\n    words.forEach(function (w) { var lw = String(w).toLowerCase(); toks.forEach(function (t) { var e = t === lw ? 0 : (t.length > 3 && ed(t, lw) <= 1 ? 1 : 9); if (e < 9 && (!best || e < best.e)) best = { w: w, e: e }; }); });\n    return best ? best.w : null;\n  };\nvar LNAME = { a: 'ay', b: 'bee', c: 'see', d: 'dee', e: 'e', f: 'ef', g: 'gee', h: 'aitch', i: 'eye', j: 'jay', k: 'kay', l: 'el', m: 'em', n: 'en', o: 'oh', p: 'pee', q: 'queue', r: 'are', s: 'ess', t: 'tea', u: 'you', v: 'vee', w: 'double', x: 'ex', y: 'why', z: 'zee' };\nC.spellGrammar = function (word) {\n    var g = 'a b c d e f g h i j k l m n o p q r s t u v w x y z bee see sea dee gee jay kay oh pee queue are tea you vee why ex zee zed eh eye aye owe okay ay ess em en el ef double ah skip next'.split(' ');\n    (Array.isArray(word) ? word : [word]).forEach(function (wd) {\n      var L = String(wd || '').toLowerCase().replace(/[^a-z]/g, '').split(''); if (L.length < 2) return;\n      g.push(L.join(' ')); g.push(L.map(function (c) { return LNAME[c]; }).join(' ')); g.push(L.map(function (c, i) { return i % 2 ? c : LNAME[c]; }).join(' ')); g.push(L.map(function (c, i) { return i % 2 ? LNAME[c] : c; }).join(' '));   /* the spelled word itself helps the engine hold on to the letters */\n    });\n    g.push('[unk]');\n    return JSON.stringify(g.filter(function (x, i, a) { return a.indexOf(x) === i; }));\n  };\nC.spellWhich = function (words, said) {\n    var best = null; words.forEach(function (w) { var j = C.spellJudge(w, [said]); if (j.kind === 'none' || j.kind === 'whole') return; if (!best || j.cost < best.j.cost) best = { w: w, j: j }; });\n    return best;\n  };\nC.liveLetters = function (said, word) {\n    var want = String(word || '').toLowerCase().replace(/[^a-z]/g, ''), t = spellTokens(said), out = [], p = 0, i;\n    if (!want) return t.filter(function (x) { return !(x.c === 'e'); }).map(function () { return '.'; }).join('');\n    for (i = 0; i < want.length; i++) out.push('.');\n    for (i = 0; i < t.length && p < want.length; i++) {\n      var x = t[i];\n      if (x.u) { p++; continue; }\n      if (x.c === want[p] || simL(x.c, want[p])) { out[p] = want[p]; p++; }\n      else if (x.c === 'e' && t[i + 1] && t[i + 1].c && 'mnflsx'.indexOf(t[i + 1].c) >= 0) continue;\n      else if (p + 1 < want.length && (x.c === want[p + 1] || simL(x.c, want[p + 1]))) { out[p + 1] = want[p + 1]; p += 2; }\n    }\n    return out.join('');\n  };\nC.heardView = function (said, word) {\n    var want = String(word || '').toLowerCase().replace(/[^a-z]/g, ''), t = spellTokens(said), out = [], p = 0;\n    for (var i = 0; i < t.length; i++) {\n      var x = t[i];\n      if (x.u) { out.push({ c: '?', st: 'u' }); p++; continue; }\n      if (!want) { if (x.c === 'e' && t[i + 1] && t[i + 1].c && 'mnflsx'.indexOf(t[i + 1].c) >= 0) continue; out.push({ c: x.c, st: 'n' }); continue; }\n      if (p < want.length && x.c === want[p]) { out.push({ c: x.c, st: 'g' }); p++; }\n      else if (p < want.length && simL(x.c, want[p])) { out.push({ c: x.c, st: 'a' }); p++; }\n      else if (x.c === 'e' && t[i + 1] && t[i + 1].c && 'mnflsx'.indexOf(t[i + 1].c) >= 0) continue;\n      else if (p + 1 < want.length && (x.c === want[p + 1] || simL(x.c, want[p + 1]))) { out.push({ c: x.c, st: x.c === want[p + 1] ? 'g' : 'a' }); p += 2; }\n      else { out.push({ c: x.c, st: 'x' }); if (t[i + 1] && !t[i + 1].u && p + 1 < want.length && t[i + 1].c === want[p + 1]) p++; }\n    }\n    return out;\n  };\nC.isSkip = function (said) { return /\\b(skip|next|pass)\\b/.test(String(said || '').toLowerCase()); };\nC.wordGrammar = function (words) { return JSON.stringify(words.map(function (w) { return String(w).toLowerCase(); }).concat(['stop', 'finish', '[unk]'])); };\nC.isReady = function (t) { return /\\b(ready|yes|yeah|yup|start|ok|okay|i am here|i'm here|here|come|coming|let's go|lets go|go)\\b/i.test(t || ''); };\nC.isStop = function (t) { return /\\b(stop|finish|end class|bye|goodbye|quit|enough)\\b/i.test(t || ''); };\nC.isRepeat = function (t) { return /\\b(repeat|again|what|pardon|sorry|didn't hear|did not hear)\\b/i.test(t || ''); };\n})()");
var HC_ENT0 = (window.HC_ENT && typeof window.HC_ENT === 'object' && window.HC_ENT.plan) ? JSON.parse(JSON.stringify(window.HC_ENT)) : { plan: 'paid', tables: 'all', kids: 99, lessons: 'all', follow: true };
function HCENT() { return HC_ENT0; }
function hcOk(t) { var e = HCENT(); return e.tables === 'all' || !Array.isArray(e.tables) || e.tables.indexOf(+t) >= 0; }
function hcAny(a, b) { for (var t = +a; t <= +b; t++) if (hcOk(t)) return true; return false; }
function hcKidOk(kid) { var e = HCENT(); if (!(e.kids < 99)) return true; var ids = kids().map(function (k) { return k.id; }); var i = ids.indexOf(kid && kid.id); return i >= 0 && i < (e.kids || 1); }
function hcSetOk(set) { var e = HCENT(); return e.lessons === 'all' || !!(set && set.sample); }
function fact(a, b) { return a + '×' + b; }
async function askTable(a, b, info) {
  peekSet({ t: a, up: Math.max(10, b), k: 't' });
  if (A && A.setGrammar) A.setGrammar(C.qGrammar ? C.qGrammar(a, b) : C.grammar());
  var ans = a * b, q = fact(a, b), spoken = a + ' ' + b + ' ja';   /* v34 (user, 01-Nov-2026): parents' way "1 eight ja 8", never "1 times 8" */
  S.curQ = 't' + q + '#' + (++S.qn); $('kHeard').innerHTML = '';
  $('kQ').className = 'q'; $('kQ').textContent = a + ' × ' + b + ' = ?';
  if (info) $('kTag').textContent = info;
  bCur(a, b);
  /* v59 (user, 08-Nov): asked AGAIN after a wrong answer - the board must not show the answer he was told, or he just reads it out */
  var ri0 = bFind(a, b); if (ri0 >= 0 && SES.board.rows[ri0][2] === 2) bSet(a, b, null, 0);
  setLive({ mode: 'tables', title: SES.title, q: q + ' = ?' });
  var silent = 0, unclear = 0, askedAgain = false, pend = '';
  await say(spoken + '?');
  var clk = ansLimit() ? { dl: Date.now() + ansLimit() } : null;
  for (;;) {
    var r = await hear({ num: true, clock: clk });
    if (pend && r.text) { r.alts = (r.alts && r.alts.length ? r.alts : [r.text]).map(function (x) { return pend + ' ' + x; }); r.text = r.alts[0]; }   /* v131: "one hundred" ... "eight" */
    pend = '';
    if (r.switched) continue;
    if (r.timeout && !r.text) {
      C.diag('time up: ' + q); SES.to = (SES.to || 0) + 1;
      bSet(a, b, 2, 1); logAns('t', q, ans, '(time up)', false, true);
      flash(false, "Time's up", a + ' × ' + b + ' = ' + ans, 3500);
      await say("Time's up. " + spoken + ' ' + ans + '.', false); hideFlash();
      return false;
    }
    var jd = C.tableJudge(r.alts || [], a, b), n = jd.n;
    if (r.text) C.diag('heard ' + a + '×' + b + ': "' + (r.alts || [r.text]).slice(0, 3).join('" / "') + '" → ' + (jd.ok ? '✓' : (n === null ? '?' : '✗ ' + n)) + (S.lastTm ? ' · ' + S.lastTm : ''));
    if (!r.text) {
      silent++;
      if (b === 1 && silent >= 1) return true;                    /* v48: x 1 is not worth a "I could not hear" - accepted */
      if (clk) continue;                                          /* v54: with an answer time, silence is handled by the clock (countdown -> "Time's up"), not by the sorry sheet */
      if (silent === 1) continue;                     /* first silence: just listen again, no talking */
      if (silent === 2) { var cv = await notHeard(a, b, ans, q); if (cv === 'yes') return true; if (cv === 'skip') throw SKIPQ; await say(spoken + '?'); continue; }
      if (silent >= 5) { await sleepy(); silent = 0; await say(spoken + '?'); continue; }
      await say('Say the answer. ' + spoken + '?');
      continue;
    }
    if (jd.part) { pend = r.text; C.diag('heard the start "' + r.text + '" - listening for the rest'); continue; }
    if (n === null && C.isDontKnow && C.isDontKnow(r.text)) {   /* v131 (user: "if I don't know I say skip / I don't know - it won't take") */
      C.diag('skipped by voice: ' + q + ' ("' + r.text + '")'); var rk = bFind(a, b); bSet(a, b, 2, 1); logAns('t', q, ans, r.text, false, true);
      flash(false, "That's okay", a + ' × ' + b + ' = ' + ans, 2600); await say("That's okay. " + spoken + ' ' + ans + '. We will try it again soon.', false); hideFlash(); return false;
    }
    if (C.isStop(r.text) && n === null) { await askStop(); await say(spoken + '?'); continue; }
    if (n === null) {
      unclear++;
      if (b === 1 && unclear >= 1 && !C.isRepeat(r.text)) return true;
      /* v62: he says "seven two ja" and then stops - the app does NOT talk over him: the screen says what to do and it listens again quietly */
      if (unclear === 1 && /^\s*(\S+\s+){0,2}(ja|za|jha|jaa|zaa|\[unk\])\s*$/i.test(r.text)) { C.diag('line heard, answer not said: "' + r.text + '" - waiting quietly'); $('kHeard').innerHTML = '🎤 Now say the <b>answer</b>'; continue; }
      if (unclear === 1 && !C.isRepeat(r.text)) continue;      /* "Ja", "the", "computer": just listen again quietly */
      if (unclear === 2) { var cv2 = await notHeard(a, b, ans, q); if (cv2 === 'yes') return true; if (cv2 === 'skip') throw SKIPQ; await say(spoken + '?'); continue; }
      if (C.isRepeat(r.text) || unclear < 4) { await say(unclear === 1 && !C.isRepeat(r.text) ? 'Say the number. ' + spoken + '?' : spoken + '?'); continue; }
      n = -1;
    }
    var ok = jd.ok;
    /* v49: a doubtful hearing (70 for 170, 43 for 63) is asked once more, never "Not quite" at the first try */
    if (!ok && !askedAgain && n !== -1 && n !== null && (C.numAlike(n, ans) || C.numTruncated(n, ans))) { askedAgain = true; C.diag('not sure: heard ' + n + ', expected ' + ans + ' - asking once more'); await say('I am not sure I heard that. Say it again.'); continue; }
    if (!ok && jd.altOk && !askedAgain) {               /* Google's first guess wrong, another guess right (52 / 72): ask once more */
      askedAgain = true; C.diag('not sure: "' + r.text + '" or ' + ans + ' - asking again');
      await say('Did you say ' + ans + '? Say it again.'); continue;
    }
    var ri = bFind(a, b), prev = ri >= 0 ? SES.board.rows[ri][2] : 0;
    bSet(a, b, ok ? (prev === 2 ? 3 : 1) : 2, 1);
    if (ok) {
      var pr = rnd(PRAISE); flash(true, pr, a + ' × ' + b + ' = ' + ans, 1100);
      logAns('t', q, ans, r.text, true, true);
      await say(pr, false);
      hideFlash();
      return true;
    }
    logAns('t', q, ans, r.text, false, true);
    flash(false, 'Not quite', a + ' × ' + b + ' = ' + ans, 4200);
    await say('Not quite. ' + spoken + ' ' + ans + '. Say it with me: ' + spoken + ' ' + ans + '.', false);
    hideFlash();
    $('kQ').textContent = a + ' × ' + b + ' = ' + ans;
    for (var t = 0; t < 2; t++) {
      var r2 = await hear({ num: true });
      if (r2.text && C.tableJudge(r2.alts || [], a, b).ok) { await say(t === 0 ? 'Good. Remember it!' : 'Yes. Remember it!', false); return false; }
      if (t === 0) await say(r2.text ? 'Listen again. ' + spoken + ' ' + ans + '. Your turn.' : 'Your turn. Say: ' + spoken + ' ' + ans + '.', false);
    }
    await say("That's okay. " + spoken + ' ' + ans + '. We will try it again soon.', false);
    return false;
  }
}
async function notHeard(a, b, ans, q) {
  C.diag('not heard (app): ' + q + ' - asking');
  SES.nh = (SES.nh || 0) + 1;
  var sheetP = confirmSheet('😔 Sorry - I could not hear you.<br>It is my fault, not yours.<div class="q2">' + a + ' × ' + b + ' = ' + ans + '</div>Did you say it? Say <b>yes</b> or <b>again</b>' + (IS_TV ? ' - or press OK' : ''));
  /* v126 (user, TV 18-Nov: "the box is stuck, the remote cannot move, and the mic is off without telling"): the box also LISTENS - "yes" / "again" / "skip" -
     so the TV mic sign (green / red) shows again; a button press still works and stops the listening */
  var lstP = (async function () {
    try {
      await say('Sorry, I could not hear that. It is my fault. Did you say ' + a + ' ' + b + ' ja ' + ans + '? Say yes, or say again.', false);
      for (var tr = 0; tr < 3 && S.cfmRes; tr++) {
        if (A && A.setGrammar) A.setGrammar(JSON.stringify(['yes', 'yeah', 'yes i said it', 'i said it', 'again', 'say again', 'no', 'skip', 'next', '[unk]']));
        var hr = await hear({}); if (!S.cfmRes) break;
        var t = String(hr.text || '').toLowerCase();
        var w = /\b(yes|yeah|said)\b/.test(t) ? 'yes' : /\b(again|no)\b/.test(t) ? 'again' : /\b(skip|next)\b/.test(t) ? 'skip' : '';
        if (w) { C.diag('not heard box: said "' + t + '" -> ' + w); S.cfmRes(w); break; }
      }
    } catch (e) { if (e === STOP) throw e; }
  })();
  var v = await sheetP;
  releaseWaits(); try { await lstP; } catch (e) { if (e === STOP) throw e; }
  if (v === 'yes') { var ri = bFind(a, b); bSet(a, b, ri >= 0 && SES.board.rows[ri][2] === 2 ? 3 : 1, 1); logAns('t', q, ans, '(said - confirmed)', true, true); C.diag('confirmed: ' + q); flash(true, rnd(PRAISE), a + ' × ' + b + ' = ' + ans, 1000); }
  return v;
}
async function learnFact(a, b) {
  if (A && A.setGrammar) A.setGrammar(C.qGrammar ? C.qGrammar(a, b) : C.grammar());
  var ans = a * b, spoken = a + ' ' + b + ' ja ' + ans;            /* the way parents teach it (user, 01-Nov-2026: "5 one ja 5") */
  S.curQ = 'l' + a + 'x' + b + '#' + (++S.qn); $('kHeard').innerHTML = '';
  $('kQ').className = 'q'; $('kQ').textContent = a + ' × ' + b + ' = ' + ans;
  bCur(a, b); bSet(a, b, 4, 1);
  setLive({ mode: 'learn', title: SES.title, q: a + '×' + b + ' = ' + ans });
  /* v48 (user, 03-Nov: "it always says 5 one ja 5 - I did not hear that - it is not important, everybody knows it, skip it"): the first line
     (table x 1 = the table) is only said, never waited for; and learning is not a test: if he could not be heard it goes on after 2 tries */
  if (b === 1) { bSet(a, b, 1, 1); await say(spoken + '.'); return; }
  await say(spoken + '. Your turn!');
  for (var t = 0; t < 2; t++) {
    var r = await hear({ num: true });
    if (r.text && C.tableJudge(r.alts || [], a, b).ok) {
      bSet(a, b, 1, 1);
      logAns('l', a + '×' + b, ans, r.text, true, t === 0);
      await say(rnd(['Good!', 'Nice!', 'Yes!', 'Super!']), false); return;
    }
    if (!r.text) { if (t === 0) continue; break; }                 /* not heard (the app's problem): listen once more quietly, then go on */
    if (t === 0) await say('Listen. ' + spoken + '. Now you.');
  }
  if (r && r.text) logAns('l', a + '×' + b, ans, r.text, false, true);
  bSet(a, b, 1, 1);
}
async function sleepy() {
  setLive({ mode: 'paused', title: 'Waiting for ' + SES.kid.name });
  await say('Are you there, ' + SES.kid.name + '? Say ready when you come back.');
  var until = Date.now() + 5 * 60000;
  while (Date.now() < until) {
    var r = await hear({ ms: 8000 });
    if (r.text && (C.isReady(r.text) || C.answerNum(r.text) !== null)) { await say('Welcome back!', false); return; }
    if (r.text && C.isStop(r.text)) { S.stop = true; chk(); }
    if (!r.text) await sleep(12000);
  }
  S.endWhy = 'nobody'; S.stop = true; chk();
}
async function askStop() {
  await say('Do you want to stop the class? Say yes or no.');
  var r = await hear({});
  if (/\b(yes|yeah|stop|ok)\b/i.test(r.text || '')) { S.stop = true; chk(); }
  await say("Okay, let's continue!");
}
function timeLeft() { return SES.until - Date.now(); }
async function loadProg(id) {
  var p = null; try { p = await C.get('prog/' + id); } catch (e) { p = C.LS.get('hc_prog_' + id, null); }
  return C.normProg(p);
}
function saveProg() { if (!SES) return; C.LS.set('hc_prog_' + SES.kid.id, SES.prog); C.put('prog/' + SES.kid.id, SES.prog); }
function shuffle(a) { for (var i = a.length - 1; i > 0; i--) { var j = Math.floor(Math.random() * (i + 1)); var t = a[i]; a[i] = a[j]; a[j] = t; } return a; }
function rounds() { return +(S.cfg && S.cfg.rounds) === 2 ? 2 : 1; }
function upto() { return Math.max(10, Math.min(20, +(S.cfg && S.cfg.upto) || 10)); }
function weakAdj(key, ok) {
  var w = SES.prog.weak;
  if (ok) { if (w[key]) { w[key]--; if (w[key] <= 0) delete w[key]; } }
  else w[key] = Math.min(5, (w[key] || 0) + 2);
}
async function round(list, info) {
  var queue = list.slice(), clean = true, tries = {}, bad = {}, i = 0, total = list.length; S.roundFixed = false;
  if (!S.sect) setSect('q');
  bTable(list, info);
  while (queue.length) {
    if (timeLeft() < 0 && i >= 3) return null;               /* time over: stop between questions */
    var f = queue.shift(), key = f[0] + 'x' + f[1];
    i++;
    var ok = await inQ(function () { return askTable(f[0], f[1], info + ' · ' + Math.min(i, total) + ' of ' + total); });
    if (ok === 'skip') { clean = false; bad[key] = 1; continue; }   /* v70 (user, 08-Nov: "I skipped all and it said I finished the table, 5 stars"): a skipped line is not learnt */
    weakAdj(key, ok);
    if (ok) delete bad[key]; else bad[key] = 1;
    if (!ok) { clean = false; tries[key] = (tries[key] || 0) + 1; if (tries[key] < 3) queue.splice(Math.min(2, queue.length), 0, f); }
  }
  S.roundFixed = !Object.keys(bad).length;      /* v63: every line that was wrong came back and was finally right */
  stage(SES.title || '', '');                 /* the app now talks about what comes next - the last question must not stay on screen */
  return clean;
}
function nextTable(k, p, skip) {
  for (var t = +k.from; t <= +k.to; t++) if ((!p.t[t] || p.t[t].st < 3) && !(skip && skip[t]) && hcOk(t)) return t;
  return null;
}
async function tablesLearn(k) {
  var p = SES.prog, from = +k.from || 1, to = +k.to || 10, up = upto();
  var mastered = []; for (var t = from; t <= to; t++) if (p.t[t] && p.t[t].st >= 3 && hcOk(t)) mastered.push(t);
  if (mastered.length) {                                        /* warm-up from tables already learnt */
    S.warmOK = true; setSect('warm'); S.warmX = false;
    try {
      stage('🔥 Warm-up', 'Three quick questions');
      await say('Warm up time! Three quick questions.');
      var w = []; for (var i = 0; i < 3; i++) w.push([rnd(mastered), 2 + Math.floor(Math.random() * (up - 1))]);
      await round(w, 'Warm-up');
    } catch (e) {
      if (e !== WARMX) { S.warmOK = false; throw e; }
      S.warmX = false; S.warmOK = false; C.diag('warm-up skipped'); stage('📚 Tables', ''); await say('OK, no warm-up today.', false);
    }
    S.warmOK = false; setSect(''); stage('', '');
  }
  SES.skipT = SES.skipT || {}; S.jumpOK = true;
  while (timeLeft() > 30000) {
    var cur, jumped = false;
    if (S.jumpTo && S.jumpTo >= from && S.jumpTo <= to) { cur = S.jumpTo; jumped = true; S.jumpTo = null; }
    else {
      cur = nextTable(k, p, SES.skipT);
      if (cur === null && Object.keys(SES.skipT).length && nextTable(k, p) !== null) { SES.skipT = {}; cur = nextTable(k, p); await say("Let's go back to the tables we skipped."); }
    }
    if (cur === null) { S.nextOK = false; S.jumpOK = false; hbShow(); await say('You have learnt all the tables from ' + from + ' to ' + to + '! Now quick revision.'); return tablesRevise(k); }
    if (jumped) { for (var jt = from; jt < cur; jt++) if (!p.t[jt] || p.t[jt].st < 3) SES.skipT[jt] = 1; }    /* skipped over for now - they come back at the end */
    S.nextOK = true; hbShow();
    try {
    var st = p.t[cur] || (p.t[cur] = { st: 0, ok: 0 });
    stage('📚 Table of ' + cur, C.STAGES[st.st] || '');
    SES.tablesText = 'Table of ' + cur;
    SES.title = 'Table of ' + cur + ' · ' + C.STAGES[st.st];
    if (st.st === 0) {
      $('kTag').textContent = 'Learning the table of ' + cur;
      S.testOK = true; S.testNow = false; setSect('learn');
      try {
        await say("Let's learn the table of " + cur + '. Listen and say it after me, like this: ' + cur + ' one ja ' + cur + '.');
        var lb = []; for (var b0 = 1; b0 <= up; b0++) lb.push([cur, b0]);
        bTable(lb, 'Learning the table of ' + cur);
        for (var b = 1; b <= up; b++) { if (timeLeft() < 0 && b > 3) break; await inQ(function () { return learnFact(cur, b); }); }
        if (b > up) { st.st = 1; saveProg(); }
      } catch (e) {
        if (e !== TESTN) { S.testOK = false; throw e; }
        S.testNow = false; S.testOK = false; C.diag('test me now: table ' + cur); st.st = 1; saveProg();      /* v46: "test me" while learning = straight to the test without seeing */
        stage('🙈 Test · table of ' + cur, ''); await say('OK! Let us test the table of ' + cur + ' without looking.', false);
      }
      S.testOK = false;
    } else if (st.st === 1 && reciteOk()) {
      SES.title = 'Table of ' + cur + ' · say it all'; setSect('recite');
      var ro = { mode: 'test' }, rr = await reciteTable(cur, up, ro);
      if (rr === true && !ro.proven) rr = await randomCheck(cur, ro.unsure || [], up);
      if (rr === true) {
        st.st = 3; st.at = C.day(); st.ok = rounds(); SES.mastered.push(cur); confetti();
        logAns('r', 'Table of ' + cur + ' (said all)', 'all right', 'perfect', true, true);
        flash(true, 'Table of ' + cur + ' learnt!', '⭐ +5 stars', 3200); SES.stars += 5;
        await say('Super! You said the whole table of ' + cur + ' without a mistake! Five bonus stars!', false); hideFlash();
      }
      saveProg();
    } else if (st.st === 1) {
      setSect('q'); await say('Table of ' + cur + ', in order. Tell me the answers.');
      var l = []; for (var c = 1; c <= up; c++) l.push([cur, c]);
      var r = await round(l, 'Table of ' + cur + ' · in order');
      if (r === true) { st.st = 2; await say('Perfect round! Now mixed up.'); } else if (r === false) await say('Good work. We will do it again to make it perfect.');
      saveProg();
    } else {
      setSect('q'); await say('Table of ' + cur + ', mixed up!');
      var m = []; for (var d = 1; d <= up; d++) m.push([cur, d]);
      var r2 = await round(shuffle(m), 'Table of ' + cur + ' · mixed');
      if (r2 === true) {
        st.ok++;
        if (st.ok >= rounds()) {
          st.st = 3; st.at = C.day(); SES.mastered.push(cur); confetti();
          flash(true, 'Table of ' + cur + ' mastered!', '⭐ +5 stars', 3200); SES.stars += 5;
          await say('Hurray! You have mastered the table of ' + cur + '! Five bonus stars!', false); hideFlash();
        } else await say('Perfect! ' + (rounds() - st.ok === 1 ? 'One more perfect round' : (rounds() - st.ok) + ' more perfect rounds') + ' and the table of ' + cur + ' is yours.');
      } else if (r2 === false) { st.ok = 0; await say('Nice try. Practice makes perfect!'); }
      saveProg();
    }
    } catch (e) {
      if (e !== NEXTT) { S.nextOK = false; S.jumpOK = false; throw e; }
      S.nextT = false; S.reciting = false; RC = null; hideFlash(); $('kClear').style.display = 'none'; hbShow();
      if (!S.jumpTo) SES.skipT[cur] = 1;
      C.diag('table ' + cur + ' skipped' + (S.jumpTo ? ' - going to table ' + S.jumpTo : ''));
      S.nextOK = false; stage('', ''); await say(S.jumpTo ? 'OK. Table of ' + S.jumpTo + '.' : 'OK, next table.', false);
    }
    S.nextOK = false; setSect(''); S.testOK = false;
  }
  S.nextOK = false; S.jumpOK = false; setSect('');
}
async function tablesRevise(k) {
  var from = +k.from || 1, to = +k.to || 10, up = upto(), p = SES.prog;
  if (!hcAny(from, to)) { await say('Your free tables are not in this range. Please ask a parent.'); return; }
  SES.tablesText = 'Tables ' + from + ' to ' + to;
  SES.title = 'Revision · tables ' + from + '–' + to;
  setSect('q'); stage('🔁 Revision', 'Tables ' + from + ' to ' + to);
  await say('Quick revision of tables ' + from + ' to ' + to + '. Ready? Go!');
  while (timeLeft() > 20000) {
    var weak = Object.keys(p.weak).filter(function (x) { var a = +x.split('x')[0]; return a >= from && a <= to && hcOk(a); });
    var l = [];
    /* each fact only ONCE per round (user, 01-Nov: "already correct but it asks the same question again") */
    var used = {}, tries = 0;
    while (l.length < 10 && tries++ < 400) {
      var f;
      if (weak.length && Math.random() < 0.4) { var w = rnd(weak).split('x'); f = [+w[0], +w[1]]; }
      else f = [from + Math.floor(Math.random() * (to - from + 1)), 2 + Math.floor(Math.random() * (up - 1))];
      var key = f[0] + 'x' + f[1]; if (used[key] || !hcOk(f[0])) continue; used[key] = 1; l.push(f);
    }
    var before = SES.right;
    var r = await round(l, 'Revision');
    saveProg();
    if (r === null) break;
    var got = SES.right - before;
    await say(r ? 'Ten out of ten! Amazing!' : 'You got ' + got + ' right the first time. Keep going!');
  }
}
async function runSet(set, mode) {
  if (!hcSetOk(set)) { toast('🔒 Spelling and Questions lessons are part of the Paid plan - ask a parent'); C.diag('lesson refused (free plan)'); return; }
  var items = (set.items || []).filter(function (x) { return x && x.q && (x.a || set.type === 'spell'); });
  if (!items.length) return;
  if (set.type === 'spell' && mode === 'parent') return parentSpell(set);
  SES.title = setLabel(set); SES.showW = !!set.show; SES.mode = 'set'; setSect(set.type === 'spell' ? 'spell' : 'oral');
  var res = { title: setLabel(set), ok: 0, n: items.length };
  stage(setLabel(set), items.length + (set.type === 'spell' ? ' words' : ' questions'));
  $('kTag').textContent = setLabel(set);
  await say((set.type === 'spell' ? 'Spelling time! ' : 'Now, questions from ') + set.title + '.');
  var queue = items.map(function (x, i) { return { it: x, i: i, tries: 0 }; }), done = 0;
  while (queue.length) {
    var e = queue.shift(), it = e.it;
    $('kTag').textContent = setLabel(set) + ' · ' + Math.min(done + 1, items.length) + ' of ' + items.length;
    var ok = set.type === 'spell' ? await askSpell(it, e.tries === 0) : await inQ(function () { return askOral(it, e.tries === 0); });
    if (ok === true && e.tries === 0) res.ok++;
    if (ok === false && ++e.tries < 2) queue.splice(Math.min(2, queue.length), 0, e); else done++;
  }
  SES.sets[set.id] = res; stage(set.title, ''); setSect('');
  await say('You got ' + res.ok + ' out of ' + res.n + ' right the first time' + (res.ok === res.n ? '. Perfect!' : '. Well done!'));
}
async function askOral(it, first) {
  if (A && A.setGrammar) A.setGrammar('google');
  S.curQ = 'o' + it.q + '#' + (++S.qn);
  hideFlash(); $('kHeard').innerHTML = ''; $('kCap').textContent = '';
  $('kQ').className = 'q txt'; $('kQ').textContent = it.q; peekSet({ a: it.a, k: 'q' });
  bNew('o', { title: SES.title, keys: C.keysOf(it) });
  setLive({ mode: 'set', title: SES.title, q: it.q });
  await say(it.q);
  var oclk = ansLimit() ? { dl: Date.now() + Math.max(ansLimit(), 20000) } : null;     /* v70: answer time + countdown like the tables */
  for (var t = 0; ; t++) {
    var r = await hear({ ms: 12000, clock: oclk });
    if (r.timeout && !r.text) {
      C.diag('time up: ' + it.q); logAns('o', it.q, it.a, '(time up)', false, first); SES.board.res = 2; SES.board.a = it.a;
      flash(false, "Time's up", 'Answer: ' + it.a, 5000); await say("Time's up. The answer is: " + it.a + '.', false); hideFlash(); return false;
    }
    if (!r.text) { if (t < 2) { await say(t === 0 ? 'Take your time. ' + it.q : it.q); continue; } await sleepy(); await say(it.q); t = 0; continue; }
    if (C.isRepeat(r.text) && r.text.split(' ').length < 4) { await say(it.q); continue; }
    var best = null;
    (r.alts || [r.text]).forEach(function (x) { var c = C.checkOral(it, x); if (!best || c.hit.length > best.hit.length) { best = c; best.s = x; } });
    SES.board.res = best.ok ? 1 : 2; SES.board.a = it.a; SES.board.hit = best.hit;
    if (best.ok) {
      var pr = rnd(PRAISE); flash(true, pr, it.a, 1500); logAns('o', it.q, it.a, best.s, true, first);
      await say(pr, false); hideFlash(); return true;
    }
    logAns('o', it.q, it.a, r.text, false, first);
    flash(false, best.hit.length ? 'Almost!' : 'Not quite', 'Answer: ' + it.a, 5200);
    await say((best.hit.length ? 'Almost! ' : 'Not quite. ') + 'The answer is: ' + it.a + '. Say it with me.', false);
    hideFlash(); $('kCap').textContent = 'Answer: ' + it.a;
    var r2 = await hear({ ms: 12000 });
    var c2 = C.checkOral(it, r2.text || '');
    await say(c2.ok ? 'Good. Remember it!' : 'Remember: ' + it.a + '. We will try again.', false);
    return false;
  }
}
function spellAccept(j, n, len) { var f = 1 + Math.max(0, (len || 0) - 6) * 0.12; /* long words lose more letters */ return j.kind === 'ok' || (j.kind === 'unsure' && j.cost !== undefined && j.cost < (1.0 + 0.5 * (n - 1) * (n > 2 ? 1.6 : 1.2)) * (n > 1 ? f : 1)); }
async function askSpell(it, first, o) {
  o = o || {};
  var w = it.q, sen = it.s ? ' ' + it.s + '. ' + w + '.' : '', up = w.toUpperCase().split('').join(' ');
  if (!(reciteOk() && !useKeys())) return askSpellG(it, first);
  S.curQ = 's' + w + '#' + (++S.qn); S.skipSpell = false; S.clearSpell = false;
  hideFlash(); $('kHeard').innerHTML = ''; $('kCap').textContent = ''; SES.partial = '';       /* nothing of the last word stays on screen */
  $('kQ').className = 'q txt'; $('kQ').textContent = SES.showW ? '✏️ ' + String(w).toUpperCase() : '✏️ Listen and spell'; peekSet(SES.showW ? null : { w: w, k: 's' });   /* v109: per lesson - 👀 shown (learning) or 🙈 hidden until spelt right (test) */
  bNew('s', { title: SES.title, w: w });
  setLive({ mode: 'set', title: SES.title, q: 'Spell: ' + w });
  spellBtns(true);
  try {
    if (!o.silentWord) await say('Spell the word: ' + w + '.' + sen + ' Say the letters one by one.');
    for (var t = 0, n = 0, quietN = 0; ; t++) {
      if (S.skipSpell) { S.skipSpell = false; return skipWord(w, first); }
      await sleep(castOn() ? 1500 : 900);   /* the voice (Google Home) may still be finishing - never let the mic hear it (photo 9:52: extra "E S" before BONES) */
      S.reciting = true; hbShow(); ding(); SES.partial = ''; $('kHeard').innerHTML = '🎤 <b>Spell it</b> - say the letters one by one'; spellBtns(true);
      var text = await spellListen(w, { wait: 14000 }), redo = S.clearSpell, skip = S.skipSpell; S.clearSpell = false;
      S.reciting = false; RC = null; hbShow(); chk(); SES.partial = ''; drawBoard();
      C.diag('spell ' + w + ': "' + text + '"' + (redo ? ' (cleared)' : '') + (skip ? ' (skip)' : ''));
      if (skip || C.isSkip(text)) { S.skipSpell = false; return skipWord(w, first); }
      if (redo) { await say('OK. Spell ' + w + ' again.', false); t--; continue; }
      if (!text) { if (++quietN <= 2) { await say('Spell: ' + w + '.'); continue; } await sleepy(); quietN = 0; await say('Spell: ' + w + '.'); continue; }
      if (C.isRepeat(text) && text.split(' ').length < 3) { await say(w + '.' + sen); continue; }
      var j = C.spellJudge(w, [text]);
      if (j.kind === 'whole') { await say('Good, that is the word! Now say the letters, one by one.'); continue; }
      if (j.kind === 'none') { if (t < 3) { await say('I did not catch the letters. Spell: ' + w + '.'); continue; } j = { kind: 'unsure', got: '', cost: 9 }; }
      n++;
      C.diag('spell ' + w + ' try ' + n + ' -> ' + j.kind + ' cost ' + j.cost + ' (' + (j.got || '') + ')');
      if (spellAccept(j, n, w.length)) {
        $('kQ').innerHTML = '<span style="color:#16b46c">✅ ' + C.esc(String(w).toUpperCase()) + '</span>'; SES.board.res = 1; drawBoard(); peekSet(null);   /* v112: the right word stays big and green until the next word */
        logAns('s', 'Spell ' + w, w, w, true, first && n === 1);
        await say(rnd(PRAISE), false);
        await spellOut(true, '✅ ' + w, w, C.heardView(text, w)); hideFlash(); return true;
      }
      if (j.kind === 'unsure' && n < 3) {
        await say(n === 1 ? 'I did not catch all the letters. Say ' + w + ' again, slowly.' : 'Once more, slowly. Or press skip.', false); SES.board.res = 0; continue;
      }
      if (j.kind === 'unsure') {          /* three doubtful hearings: show it, no "Not quite" */
        $('kQ').textContent = w; SES.board.res = 2; SES.board.got = ''; drawBoard(); logAns('s', 'Spell ' + w, w, '(not heard)', false, first);
        await spellOut(true, 'Let us look at it', w, C.heardView(text, w));
        await say('We will try it again soon.', false); hideFlash(); return false;
      }
      /* really different letters, clearly heard */
      SES.board.res = 2; SES.board.got = j.got; $('kQ').textContent = w; drawBoard();
      logAns('s', 'Spell ' + w, w, (j.got || '').toUpperCase(), false, first);
      await say('Not quite.', false);
      await spellOut(false, 'Not quite', w, C.heardView(text, w));
      await say('Say it with me.', false);
      hideFlash();
      S.reciting = true; hbShow(); ding(); S.clearSpell = false; S.skipSpell = false;
      var t2 = await spellListen(w, { wait: 10000 });
      S.reciting = false; RC = null; hbShow(); chk(); S.clearSpell = false; S.skipSpell = false;
      var c2 = C.spellJudge(w, [t2]);
      await say(c2.kind === 'ok' || c2.kind === 'unsure' ? 'Yes! Remember it.' : 'Remember: ' + up.split(' ').map(function (c) { return c === 'A' ? 'A.' : c; }).join(', ') + '. We will try again.', false);
      return false;
    }
  } finally { spellBtns(false); }
}
async function skipWord(w, first) {
  C.diag('spell ' + w + ': skipped');
  logAns('s', 'Spell ' + w, w, '(skipped)', false, first);
  await say('OK, next.', false);
  return 'skip';
}
async function spellOut(ok, head, w, view) {
  var f = $('fb'); f.className = 'fb on ' + (ok ? 'ok' : 'no');
  $('fbE').textContent = ok ? rnd(['🌟', '🎉', '👏', '💪', '🚀', '😃']) : '💡';
  $('fbH').textContent = head;
  var L = String(w).toUpperCase().split(''), row = [];
  var draw = function (cur) { $('fbP').innerHTML = '<div class="pwc" id="pwCur">' + C.esc(cur) + '</div><div class="pwrow">' + C.esc(row.join(' ')) + '</div>' + (view && view.length ? '<div class="pr">I heard: ' + chipsHTML(view) + '</div>' : ''); };
  clearTimeout(f._t); f._t = setTimeout(function () { f.className = 'fb'; }, 60000);
  draw('');
  await say(w + ' is spelt', false);
  if (castOn()) {
    var all = rawSay(L.map(function (c) { return c === 'A' ? 'A.' : c; }).join(', ') + '.');
    for (var i = 0; i < L.length; i++) { draw(L[i]); await sleep(650); row.push(L[i]); chk(); }
    await all;
  } else {
    for (var j = 0; j < L.length; j++) { draw(L[j]); await rawSay(L[j] === 'A' ? 'A.' : L[j]); chk(); row.push(L[j]); }   /* v129 (user, 20-Nov: "it says I for A"): "ay" was read as "I" by the phone's voice; "A." is read as the letter */
  }
  $('fbP').innerHTML = '<div class="pw">' + C.esc(L.join(' ')) + '</div>' + (view && view.length ? '<div class="pr">I heard: ' + chipsHTML(view) + '</div>' : '');
  await say(w + '.', false);
}
async function askSpellG(it, first) {
  if (A && A.setGrammar) A.setGrammar('google');
  var w = it.q, sen = it.s ? ' ' + it.s + '. ' + w + '.' : '';
  S.curQ = 's' + w + '#' + (++S.qn);
  $('kQ').className = 'q txt'; $('kQ').textContent = SES.showW ? '✏️ ' + String(w).toUpperCase() : '✏️ Listen and spell'; peekSet(SES.showW ? null : { w: w, k: 's' });   /* v109: per lesson - 👀 shown (learning) or 🙈 hidden until spelt right (test) */
  bNew('s', { title: SES.title, w: w });
  setLive({ mode: 'set', title: SES.title, q: 'Spell: ' + w });
  await say('Spell the word: ' + w + '.' + sen + ' Say the letters one by one.');
  var sclk = ansLimit() ? { dl: Date.now() + Math.max(ansLimit(), 20000) } : null;     /* v70: the same answer time + countdown as the tables (at least 20 s to spell) */
  for (var t = 0; ; t++) {
    var r = await hear({ ms: 14000, clock: sclk });
    if (r.timeout && !r.text) {
      C.diag('time up: spell ' + w); logAns('s', 'Spell ' + w, w, '(time up)', false, first); SES.board.res = 2; SES.board.got = '';
      drawBoard(); await say("Time's up.", false); await spellOut(false, "Time's up", w, null); hideFlash(); return false;
    }
    if (!r.text) { if (t < 2) { await say('Spell: ' + w + '.'); continue; } await sleepy(); await say('Spell: ' + w + '.'); t = 0; continue; }
    if (C.isRepeat(r.text) && r.text.split(' ').length < 3) { await say(w + '.' + sen); continue; }
    var best = null;
    (r.alts || [r.text]).forEach(function (x) { var c = C.checkSpell(w, x); if (!best || c.ok) best = c; });
    if (best.whole) { await say('Good, that is the word! Now say the letters, one by one.'); continue; }
    var letters = w.toUpperCase().split('').map(function (c) { return c === 'A' ? 'A.' : c; }).join(' - ');
    SES.board.res = best.ok ? 1 : 2; SES.board.got = best.got;
    if (best.ok) {      /* v75 (user: "the letters pop up on the phone after answering, not on the TV"): the same spelt-out letters as the phone */
      logAns('s', 'Spell ' + w, w, best.got, true, first); drawBoard();
      await spellOut(true, '✅ ' + w, w, null); hideFlash(); return true;
    }
    logAns('s', 'Spell ' + w, w, best.got.toUpperCase(), false, first); drawBoard();
    await say('Not quite.', false);
    await spellOut(false, 'Not quite', w, null);
    await say('Say it with me.', false); hideFlash();
    var r2 = await hear({ ms: 14000 });
    var c2 = C.checkSpell(w, r2.text || '');
    await say(c2.ok ? 'Yes! Remember it.' : 'Remember: ' + w.toUpperCase().split('').map(function (c) { return c === 'A' ? 'A.' : c; }).join(', ') + '. We will try again.', false);
    return false;
  }
}
async function parentSpell(set) {
  var items = (set.items || []).filter(function (x) { return x && x.q; }), names = items.map(function (x) { return x.q; }), done = {}, res = { title: setLabel(set), ok: 0, n: items.length }, miss = 0, lastW = '', n = 0;
  SES.title = setLabel(set); SES.showW = !!set.show; SES.mode = 'set'; S.skipSpell = false; S.clearSpell = false; setSect('spell');
  stage(setLabel(set), '👨‍👩‍👦 Mom / Dad says a word');
  $('kTag').textContent = setLabel(set) + ' · 👨‍👩‍👦 say a word';
  await say('Mom or Dad says a word. Then spell it without looking.');
  try {
    while (Object.keys(done).length < items.length) {
      var left = names.filter(function (x) { return !done[x]; });
      $('kQ').className = 'q txt'; $('kQ').textContent = '🎧 Say a word, then spell it';
      bNew('s', { title: SES.title, w: '' }); drawBoard();
      $('kCap').textContent = Object.keys(done).length ? '✅ ' + Object.keys(done).join(' · ') : '';
      S.reciting = true; hbShow(); ding(); spellBtns(true); $('kHeard').innerHTML = '🎧 <b>Mom / Dad says a word</b> - then spell it';
      var text = await spellListen(left, { wait: 40000 }), redo = S.clearSpell, skip = S.skipSpell; S.clearSpell = false; S.skipSpell = false;
      S.reciting = false; RC = null; hbShow(); chk(); SES.partial = ''; drawBoard();
      C.diag('parent spell: "' + text + '"' + (redo ? ' (cleared)' : '') + (skip ? ' (skip)' : ''));
      if (redo || skip) { lastW = ''; n = 0; continue; }
      if (!text) { if (++miss >= 3) { toast('Say a word, then spell it - or press ⏹ Stop', 4000); miss = 0; } continue; }
      var best = C.spellWhich(left, text);
      if (!best) { toast('Did not catch the letters - say the word and spell it again', 3000); continue; }
      miss = 0; var w = best.w, it = items.filter(function (x) { return x.q === w; })[0];
      n = w === lastW ? n + 1 : 1; lastW = w;
      C.diag('parent spell -> ' + w + ' ' + best.j.kind + ' cost ' + best.j.cost + ' try ' + n);
      if (spellAccept(best.j, n, best.w.length)) {
        done[w] = 1; res.ok += n === 1 ? 1 : 0; lastW = ''; n = 0;
        $('kQ').className = 'q'; $('kQ').textContent = w; SES.board.res = 1; drawBoard();
        logAns('s', 'Spell ' + w, w, w, true, true);
        await say(rnd(PRAISE), false);
        await spellOut(true, '✅ ' + w, w, C.heardView(text, w)); hideFlash();
      } else if (n >= 3 || best.j.kind === 'wrong') {
        done[w] = 1; lastW = ''; n = 0;
        $('kQ').className = 'q'; $('kQ').textContent = w; SES.board.res = 2; SES.board.got = best.j.kind === 'wrong' ? best.j.got : ''; drawBoard();
        logAns('s', 'Spell ' + w, w, best.j.kind === 'wrong' ? best.j.got.toUpperCase() : '(not heard)', false, true);
        if (best.j.kind === 'wrong') await say('Not quite.', false);
        await spellOut(best.j.kind !== 'wrong', best.j.kind === 'wrong' ? 'Not quite' : 'Let us look at it', w, C.heardView(text, w));
        await say('We will try it again soon.', false); hideFlash();
      } else {
        await say('I did not catch all the letters. Say the word and spell it again, slowly.', false);
      }
      $('kCap').textContent = '✅ ' + Object.keys(done).join(' · ');
      await sleep(500);
    }
  } finally { spellBtns(false); }
  SES.sets[set.id] = res; stage(set.title, ''); setSect('');
  await say('You got ' + res.ok + ' out of ' + res.n + ' right the first time' + (res.ok === res.n ? '. Perfect!' : '. Well done!'));
}
function activeSets(k) {
  var d = C.day();
  return Object.keys(S.sets || {}).map(function (id) { var s = S.sets[id]; s.id = id; return s; })
    .filter(function (s) { return C.setActive(s, k.id, d); })
    .sort(function (a, b) { return (a.until || '9999') < (b.until || '9999') ? -1 : 1; });
}
function mixedSets(k) { return activeSets(k).filter(function (s) { return !!s.mix; }); }
async function runClass(kid, why, opt) {
  if (S.running) return;
  if (!hcKidOk(kid)) { toast('🔒 More children need the Paid plan - ask a parent'); C.diag('class refused: child ' + (kid && kid.name) + ' (free plan)'); return; }
  var lv = S.live[kid.id];
  if (lv && lv.on && lv.dev !== C.devId() && Date.now() - lv.at < 90000) { toast(kid.name + "'s class is on " + (lv.devName || 'another device') + ' now'); return; }
  S.running = true; S.stop = false; S.pause = false; S.endWhy = ''; S.nextT = false; S.skipQ = false; S.qOK = false; S.nextOK = false; S.jumpOK = false; S.jumpTo = null; S.warmX = false; S.warmOK = false; S.testNow = false; S.testOK = false; S.sect = ''; micBroken = 0; S.forceKeys = false; warm();
  if (S.speaking) { try { A.stopSpeak(); } catch (x) {} if (S.sayId) window.hcSpoke(String(S.sayId)); }   /* the old class's goodbye must not talk over the new one */
  C.diag('class start ' + kid.name + ' (' + (why || '') + ')' + (opt && opt.set ? ' · lesson ' + ((S.sets[opt.set] || {}).title || opt.set) : '') + ' · ' + kid.style + ' ' + kid.from + '-' + kid.to + ' · ' + (kid.min || 15) + ' min · mic ' + (useKeys() ? 'off (keys)' : 'on'));
  if (A && A.setBusy) A.setBusy(true);
  if (A && A.keepOn) A.keepOn(true);
  var base = null; try { base = await C.get('days/' + C.day() + '/' + kid.id); } catch (e) {}
  SES = { kid: kid, t0: Date.now(), until: Date.now() + (kid.min || 15) * 60000, right: 0, wrong: 0, stars: 0, asked: 0, mist: {}, sets: {}, mastered: [], base: base || {}, mode: 'tables', title: '' };
  SES.prog = await loadProg(kid.id);
  document.body.style.setProperty('--kc', kid.color || '#5b4bff');
  $('kAv').textContent = kid.emoji || '🙂'; $('kName').textContent = kid.name; $('kQ').textContent = ''; $('kCap').textContent = ''; $('kHeard').textContent = ''; $('kTag').textContent = '';
  $('kBoard').classList.remove('on'); document.body.classList.remove('bOn');
  $('sClass').classList.remove('done'); SES.again = (opt && (opt.mode || opt.set)) ? { kid: kid, why: why, opt: { mode: opt.mode, t: opt.t, set: opt.set, smode: opt.smode } } : null;
  show('sClass'); updBar(); S.qn = 0; hbShow();
  setLive({ mode: 'start', title: 'Starting', why: why || '' });
  var tick = setInterval(updBar, 1000);
  try {
    var one = opt && opt.set ? setById(opt.set) : null;
    var sets = one ? [one] : opt && opt.mode ? [] : mixedSets(kid);
    if (sets.length && !one) SES.until = SES.t0 + (kid.min || 15) * 60000 * 0.6;
    await say(rnd(['Hello ', 'Hi ', 'Welcome ']) + kid.name + '! ' + (one ? "Let's practise " + one.title + '.' : rnd(["Let's start.", "Let's learn!", 'Ready to shine?'])));
    if (opt && opt.set && !one) { C.diag('lesson ' + opt.set + ' not found (deleted?)', 'w'); await say('I could not find that lesson.'); }
    else if (one) { SES.title = one.title; }
    else if (opt && opt.mode) await practice(kid, opt);
    else if (kid.style === 'learn') await tablesLearn(kid); else await tablesRevise(kid);
    if (sets.length) {
      SES.until = SES.t0 + (kid.min || 15) * 60000 + (one ? 30 : 10) * 60000;   /* lessons always finish (mixed: up to 10 min extra) */
      for (var i = 0; i < sets.length; i++) { if (timeLeft() < 0) break; await runSet(sets[i], one && opt.smode); }
    }
  } catch (e) { if (e !== STOP) { console.error(e); } }
  clearInterval(tick);
  S.stop = false;
  try { await finish(); } catch (e) { C.diag('finish error: ' + e.message, 'e'); S.running = false; hbShow(); }
}
async function finish() {
  if (!SES) { S.running = false; hbShow(); return; }
  var mine = SES, k = SES.kid;
  saveDay(); saveProg();
  try { if (window.HCPass && window.HCPass.inviteDone) window.HCPass.inviteDone(); } catch (e) {}
  C.put('live/' + k.id, { on: false, at: Date.now(), dev: C.devId(), devName: S.devName, ended: S.endWhy || 'done', right: SES.right, wrong: SES.wrong, stars: SES.stars, t0: SES.t0 });
  hideFlash();
  var total = SES.right + SES.wrong;
  peekSet(null);
  C.diag('class end ' + k.name + ' · ' + (S.endWhy || 'done') + ' · right ' + SES.right + ' wrong ' + SES.wrong + ' · ' + Math.round((Date.now() - SES.t0) / 1000) + ' s · mic errors ' + micBroken);
  $('dE').textContent = SES.mastered.length ? '🏆' : (SES.stars >= 10 ? '🌟' : '👏');
  $('dT').textContent = (S.endWhy === 'nobody' ? 'See you soon, ' : 'Well done, ') + k.name + '!';
  $('dS').textContent = total ? (SES.right + ' right the first time out of ' + total + '.' + (SES.mastered.length ? ' New table mastered: ' + SES.mastered.join(', ') + '!' : '')) : 'Class ended.';
  $('dStars').textContent = '⭐ ' + SES.stars + ' stars today';
  var inPlace = !!SES.again && S.endWhy !== 'nobody';
  if (inPlace) {                                  /* v124 (user: "after a practised table is right it opens another page - show it there only"): the result stays on the class screen, with 🔁 / 🏠 */
    S.againKid = SES.again; $('kBoard').classList.remove('on'); document.body.classList.remove('bOn'); S.sect = ''; $('kTag').textContent = '';
    $('kQ').className = 'q txt'; $('kQ').textContent = $('dE').textContent + ' ' + $('dT').textContent;
    $('kCap').textContent = $('dS').textContent + '  ' + $('dStars').textContent; $('kHeard').innerHTML = '';
    $('sClass').classList.add('done');
  } else show('sDone');
  if (SES.stars) confetti();
  S.running = false; hbShow(); if (HB.id) { try { A.stopListen(); } catch (x) {} HB.id = null; }
  if (S.endWhy !== 'nobody') {
    try { await rawSay(total ? 'Class over! You got ' + SES.right + ' right, and earned ' + SES.stars + ' stars. See you tomorrow, ' + k.name + '!' : 'Bye ' + k.name + '!'); } catch (e) {}
  }
  /* v43 (log 02-Nov 21:16 and 21:21: "stuck on Welcome"): a new class started while this one was still saying "Class over!" and this line then
     wiped the NEW class's data (SES = null) - only clear it when it is still ours */
  if (!S.running) { if (A && A.setBusy) A.setBusy(false); if (A && A.keepOn) A.keepOn(false); }
  if (SES === mine) SES = null;
  setTimeout(function () { if ((S.screen === 'sDone' || (S.screen === 'sClass' && $('sClass').classList.contains('done'))) && !S.running) goHome(); }, 25000);
  loadProgAll();
}
function stopClass(why) {
  if (!S.running) return;
  S.endWhy = why || 'stopped'; S.stop = true; S.pause = false;
  if (A) { try { A.stopSpeak(); A.stopListen(); } catch (e) {} } else if (window.speechSynthesis) speechSynthesis.cancel();
  if (typedRes) typed('');
  if (S.reciteWait) { var w0 = S.reciteWait; S.reciteWait = null; w0(); }
  Object.keys(spokeCb).forEach(function (id) { window.hcSpoke(id); });
  Object.keys(heardCb).forEach(function (id) { window.hcHeardErr(id, 'stop'); });
}
function reciteOk() { return !IS_TV && A &&   /* v69: TV sound 21:37 - the remote's Bluetooth mic sends sound only for the first ~7 s, so a 45 s recitation is lost: the TV tests a table by questions */ A.reciteStart && A.voskState && A.voskState() === 'ready'; }
function spellListen(w, o) {
  o = o || {};
  return new Promise(function (res) {
    var id = String(++nid), quiet = 2200;
    RC = { id: id, spell: 1, w: Array.isArray(w) ? '' : (w || ''), list: Array.isArray(w) ? w : null, text: '', at: Date.now(), t0: Date.now(), res: res, stopping: false };
    A.setGrammar(C.spellGrammar(w)); A.reciteStart(id);
    var tk = setInterval(function () {
      if (!RC || RC.id !== id) return clearInterval(tk);
      var q = Date.now() - (RC.chg || RC.at), total = Date.now() - RC.t0;     /* quiet = the letters stopped CHANGING (a partial that repeats is not activity) */
      /* v47 (user, 03-Nov photo 9:45: "when I am correct I still need to press Done"): the spelling is complete and exact -> finish by itself
         0.9 s after the last letter (a doubtful / different spelling still waits the normal 2.2 s of quiet) */
      var early = false;
      if (RC.text && Date.now() - (RC.chg || 0) > 900) {
        if (RC.list) { var eb = C.spellWhich(RC.list, RC.text); early = !!(eb && eb.j.kind === 'ok' && eb.j.cost === 0); }
        else if (RC.w) { var ej = C.spellJudge(RC.w, [RC.text]); early = ej.kind === 'ok' && ej.cost === 0; }
      }
      /* long words: he pauses to think between letter groups - while clearly fewer letters than the word have been heard, wait longer */
      var qq = quiet;
      if (RC.text && !early) { var tg = RC.w; if (RC.list) { var tb2 = C.spellWhich(RC.list, RC.text); tg = tb2 ? tb2.w : ''; } if (tg && C.letterSeq(RC.text).length < tg.length * 0.75) qq = 3800; }
      if (S.stop || S.skipSpell || S.clearSpell || early || (RC.text && q > qq) || (!RC.text && total > (o.wait || 14000)) || total > 60000) { clearInterval(tk); if (!RC.stopping) { RC.stopping = true; A.reciteStop(); } }
    }, 300);
  });
}
function reciteListen(t, up) {
  return new Promise(function (res) {
    var id = String(++nid);
    RC = { id: id, t: t, up: up, text: '', at: Date.now(), t0: Date.now(), res: res, stopping: false };
    A.setGrammar(C.grammar(t, up)); A.reciteStart(id);
    var tk = setInterval(function () {
      if (!RC || RC.id !== id) return clearInterval(tk);
      var quiet = Date.now() - RC.at, total = Date.now() - RC.t0;
      if (S.stop || S.nextT || S.skipQ || (RC.text && quiet > 4500) || (!RC.text && total > 20000) || total > 120000) { clearInterval(tk); if (!RC.stopping) { RC.stopping = true; A.reciteStop(); } }
    }, 400);
  });
}
function waitStart(label) {
  return new Promise(function (res) { S.reciteWait = res; hbShow(); hbLabel(label || '▶ Start saying'); $('kHold').classList.remove('on'); if (IS_TV) setTimeout(function () { try { $('kHold').focus(); } catch (e) {} }, 150); });
}
async function randomCheck(t, unsure, up) {
  var skipB = function (b) { return b === 1 || b === 10; }, pool = [];
  for (var b = 1; b <= up; b++) if (!skipB(b)) pool.push(b);
  var us = shuffle((unsure || []).filter(function (b) { return !skipB(b) && pool.indexOf(b) >= 0; })).slice(0, 5);
  var rest = shuffle(pool.filter(function (b) { return us.indexOf(b) < 0; })).slice(0, 5 - us.length);
  var l = shuffle(us.concat(rest)).map(function (b) { return [t, b]; });
  if (!l.length) return true;
  C.diag('check ' + t + ': ' + l.length + ' lines (' + us.length + ' unsure)');
  stage('✅ Quick check', 'Table of ' + t);
  await say((unsure && unsure.length ? 'Good. ' : 'Super! You said the whole table of ' + t + '. ') + 'Now a quick check: ' + (l.length === 1 ? 'one question.' : l.length + ' questions.'));
  var r = await round(l, 'Table of ' + t + ' · quick check');
  if (r === false && S.roundFixed) { C.diag('check ' + t + ': wrong lines came back and were right - table learnt'); r = true; }
  if (r === false) await say('Good work. We will do the table of ' + t + ' once more to make it perfect.');
  return r;
}
async function followLine(t, b) {
  var fPend = '';
  for (var k = 0; k < 2; k++) {
    var r = await hear({ num: true, ms: 7000 });
    if (r.switched) { k--; continue; }
    if (!r.text) return null;
    if (fPend && r.text) { r.alts = (r.alts && r.alts.length ? r.alts : [r.text]).map(function (x) { return fPend + ' ' + x; }); r.text = r.alts[0]; }
    fPend = '';
    var jd = C.tableJudge(r.alts || [], t, b);
    if (jd.part && k === 0) { fPend = r.text; C.diag('follow ' + t + '×' + b + ': heard the start "' + r.text + '" - listening for the rest'); continue; }
    if (jd.n === null && C.isDontKnow && C.isDontKnow(r.text)) { C.diag('follow ' + t + '×' + b + ': skipped by voice ("' + r.text + '")'); return 'skip'; }
    /* v118 (user, 17-Nov-2026: "if I say the table fast it is not taken"): SMART PACE - a clip with several lines ("13 2 ja 26, 13 3 ja 39") is read line by line;
       every line said right counts (the current one too), the app then skips the lines already heard */
    if ((S.fastUp || 0) > b && S.fastRead) {
      var fxBest = [], selfHit = !!S.liveSelf;
      (r.alts || [r.text]).slice(0, 3).forEach(function (al) {
        var fr = S.fastRead(al, t, b, S.fastUp);
        if (fr.ex.length > fxBest.length) fxBest = fr.ex;
        if (fr.self) selfHit = true;
      });
      if (fxBest.length) { S.fastX = (S.fastX || []).concat(fxBest.filter(function (x) { return (S.fastX || []).indexOf(x) < 0; })); C.diag('follow ' + t + ': fast - also heard line' + (fxBest.length > 1 ? 's ' : ' ') + fxBest.join(', ')); }
      if (!jd.ok && selfHit) { jd = { ok: true, n: t * b, fast: true }; }
    }
    /* v130 (TV log 27-Nov 21:54-21:55, 12 table: line 4 was missed, the app moved on while he was still saying "12 4 ja 48" - heard at line 5, and line 5's "60" at line 6):
       the answer of a line missed just before, said late, counts for THAT line (big answers only, never the current line's answer) */
    if ((S.fastMiss || []).length && (S.fastUp || 0)) {
      var late = [];
      (r.alts || [r.text]).slice(0, 3).forEach(function (al) {
        var nm2 = []; try { nm2 = C.numbers(al, true) || []; } catch (e) { nm2 = []; }
        S.fastMiss.forEach(function (L) { var want = t * L; if (want > S.fastUp && want !== t * b && nm2.indexOf(want) >= 0 && late.indexOf(L) < 0) late.push(L); });
      });
      if (late.length) { S.fastLate = (S.fastLate || []).concat(late); C.diag('follow ' + t + ': late - line' + (late.length > 1 ? 's ' : ' ') + late.join(', ') + ' said now, counted'); }
    }
    C.diag('follow ' + t + '×' + b + ': "' + (r.alts || [r.text]).slice(0, 2).join('" / "') + '" → ' + (jd.ok ? '✓' : (jd.n === null ? '?' : '✗ ' + jd.n)) + (S.lastTm ? ' · ' + S.lastTm : ''));
    if (jd.ok) return true;
    if (jd.n !== null) return false;
    return null;
  }
  return null;
}
async function followTable(t, up, o) {
  peekSet((o.mode || 'test') === 'answers' ? null : { t: t, up: up, k: 't' });
  var mode = o.mode || 'test', lines = []; for (var b0 = 1; b0 <= up; b0++) lines.push([t, b0]);
  bTable(lines, (mode === 'answers' ? '👀 Answers shown' : '🙈 From memory') + ' · ' + t + ' × 1 to ' + t + ' × ' + up + ' · line by line');
  if (mode === 'answers') SES.board.rows.forEach(function (r) { r[3] = 1; });
  setLive({ mode: 'recite', title: SES.title, q: 'Table of ' + t + (mode === 'test' ? ' (from memory)' : ' (answers shown)') });
  $('kQ').className = 'q txt'; $('kQ').textContent = (mode === 'answers' ? '👀 ' : '🙈 ') + 'Say the table of ' + t; drawBoard();
  await say('Say the table of ' + t + (mode === 'answers' ? ', looking at the answers' : ' from memory') + ', line by line. Say each line when it lights up.');
  var miss = [], todo = lines.map(function (l) { return l[1]; });
  S.fastUp = up; S.fastX = []; S.liveSelf = false; S.liveB = 0; S.fastSkip = [];
  /* v119/v120 helper: what a clip says. ex = later lines said right; self = this line said right. Line numbers are often misheard, so answers are matched in order too (2+ or this line's own). */
  S.fastRead = function (al, t, b, up) {
    var ex = [], self = false, ps, nm = [], pos = 0, oh = [];
    try { ps = C.parseRecite(al, t, up) || []; } catch (e) { ps = []; }
    ps.forEach(function (f) { if (f.said === t * f.b) { if (f.b > b) ex.push(f.b); else if (f.b === b) self = true; } });
    try { nm = C.numbers(al, true) || []; } catch (e) { nm = []; }
    for (var L = b; L <= up; L++) {
      var want = t * L; if (L === 1 || want <= up) continue;
      for (var q = pos; q < nm.length; q++) if (nm[q] === want) { oh.push(L); pos = q + 1; break; }
    }
    if (oh.length >= 2 || (oh.length === 1 && oh[0] === b)) {
      if (oh.indexOf(b) >= 0) self = true;
      oh.forEach(function (x) { if (x > b && ex.indexOf(x) < 0) ex.push(x); });
    }
    /* v120 (log 18-Nov 08:08, 14 x 1): line 1's answer IS the table number, so "fourteen fourteen two ja twenty eight ..." = line 1 said, then line 2 */
    if (b === 1 && !self && ex.length && nm[0] === t && (nm[1] === t || (nm[1] === 1 && nm[2] === t))) self = true;
    return { ex: ex, self: self };
  };
  /* v120 (user, 18-Nov-2026: "as I say the table it does not turn green - it keeps hearing and makes all green at once"): the live words from the mic turn each line green as soon as the NEXT line has begun */
  S.liveCb = function (txt) {
    if (!S.liveB || !SES || !SES.board) return;
    var ps; try { ps = C.parseRecite(txt, t, up) || []; } catch (e) { return; }
    var hit = false;
    if (S.liveB === 1 && !S.liveSelf && ps.length >= 2 && S.fastRead(txt, t, 1, up).self) { S.liveSelf = true; bSet(t, 1, 1, 1); hit = true; }   /* line 1 = "fourteen fourteen ..." */
    ps.slice(0, -1).forEach(function (f) {
      if (f.said !== t * f.b || f.b < S.liveB) return;
      if (f.b === S.liveB) { if (!S.liveSelf) { S.liveSelf = true; bSet(t, f.b, 1, 1); hit = true; } }
      else if (S.fastX.indexOf(f.b) < 0) { S.fastX.push(f.b); bSet(t, f.b, 1, 1); hit = true; }
    });
    if (hit) drawBoard();
  };
  try {
  for (var pass = 1; pass <= 2 && todo.length; pass++) {
    var next = []; S.fastMiss = next; S.fastLate = [];
    for (var i = 0; i < todo.length; i++) {
      var b = todo[i]; chk();
      if (S.fastX.indexOf(b) >= 0) continue;                       /* v118: already heard inside an earlier fast clip */
      bCur(t, b); S.curQ = 'f' + t + 'x' + b + '#' + (++S.qn);
      $('kQ').className = 'q'; $('kQ').textContent = t + ' × ' + b + ' = ' + (mode === 'answers' ? t * b : '?');
      $('kHeard').innerHTML = '🎤 <b>' + t + ' × ' + b + '</b>'; drawBoard();
      if (A && A.setGrammar) {                                     /* v118: this line's words + the next two lines', so a fast child is heard too */
        var gj = JSON.parse(C.qGrammar(t, b));
        for (var nb = b + 1; nb <= Math.min(up, b + 2); nb++) JSON.parse(C.qGrammar(t, nb)).forEach(function (x) { if (gj.indexOf(x) < 0) gj.push(x); });
        if (next.length) JSON.parse(C.qGrammar(t, next[next.length - 1])).forEach(function (x) { if (gj.indexOf(x) < 0) gj.push(x); });   /* v130: the line missed just before, said late */
        A.setGrammar(JSON.stringify(gj));
      }
      if (i === 0) ding();
      S.liveB = b; S.liveSelf = false;
      var lateIn = function () { (S.fastLate || []).forEach(function (L) { var ix = next.indexOf(L); if (ix >= 0) next.splice(ix, 1); bSet(t, L, 1, 1); }); S.fastLate = []; drawBoard(); };
      var got = await inQ(function () { return followLine(t, b); }); lateIn();
      if (got !== true && got !== 'skip') { S.liveB = 0; await say(t + ' ' + b + ' ja?'); S.liveB = b; got = await inQ(function () { return followLine(t, b); }); lateIn(); }
      S.liveB = 0;   /* (B) asked by voice at once */
      S.fastX.forEach(function (fb) { bSet(t, fb, 1, 1); });
      if (got === true) { bSet(t, b, 1, 1); setLive({ mode: 'recite', title: SES.title, q: t + ' × ' + b + ' ✓' }); }
      else if (got === 'skip') { S.fastSkip.push(b); bSet(t, b, 2, 1); await say("That's okay. " + t + ' ' + b + ' ja ' + (t * b) + '.', false); }   /* v131: skipped by voice - shown, told, not asked again */
      else next.push(b);
      drawBoard();
    }
    todo = next;
    if (todo.length && pass === 1 && todo.length >= Math.ceil(up / 2)) { await say('I could not hear some lines. Let us say them once more.'); continue; }
    break;
  }
  } finally { S.liveCb = null; S.liveB = 0; S.liveSelf = false; S.fastUp = 0; S.fastMiss = null; S.fastLate = []; }
  S.fastX = [];
  miss = todo.concat((S.fastSkip || []).filter(function (x) { return todo.indexOf(x) < 0; })); S.fastSkip = [];   /* v131: lines skipped by voice are not known - the quick check asks them */ bCur(t, -1); drawBoard();
  C.diag('follow ' + t + ': ' + (up - miss.length) + ' of ' + up + ' heard' + (miss.length ? ' · not heard ' + miss.join(', ') : ' · all proven'));
  o.unsure = miss; o.proven = !miss.length;
  if (miss.length >= Math.ceil(up / 2)) { await say('I could not hear enough lines. We will try the table of ' + t + ' again later.'); return false; }
  return true;
}
async function reciteTable(t, up, o) {
  o = o || {}; if (!o.long && HCENT().follow !== false) return followTable(t, up, o);
  var mode = o.mode || 'test', tries = o.tries || (mode === 'answers' ? 2 : 3);
  var lines = []; for (var b = 1; b <= up; b++) lines.push([t, b]);
  for (var attempt = 1; attempt <= tries; attempt++) {
    bTable(lines, (mode === 'answers' ? '👀 Say it - the answers are shown' : '🙈 From memory') + ' · ' + t + ' × 1 to ' + t + ' × ' + up);
    if (mode === 'answers') SES.board.rows.forEach(function (r) { r[3] = 1; });
    $('kQ').className = 'q txt'; $('kQ').textContent = (mode === 'answers' ? '👀 ' : '🙈 ') + 'Say the table of ' + t;
    S.curQ = 'r' + t + '#' + (++S.qn); drawBoard();
    setLive({ mode: 'recite', title: SES.title, q: 'Table of ' + t + (mode === 'test' ? ' (from memory)' : ' (answers shown)') });
    await say(attempt === 1 ? (mode === 'test' ? 'Now say the table of ' + t + ' from memory, from ' + t + ' one to ' + t + ' ' + up + '. Press start, then say it.'
        : 'Say the table of ' + t + '. You can look at the answers. Press start, then say it.')
      : 'Now say the whole table of ' + t + ' one more time. Press start, then say it.');
    $('kHeard').innerHTML = '👉 Press <b>▶ Start saying</b>';
    await waitStart('▶ Start saying'); chk();
    S.reciting = true; hbShow(); ding();
    $('kHeard').innerHTML = '🗣️ <b>Say the table of ' + t + '</b> - press <b>■ Done</b> when you finish';
    setLive({ mode: 'recite', title: SES.title, q: 'Table of ' + t });
    var text = await reciteListen(t, up);
    S.reciting = false; RC = null; hbShow();
    chk();
    var r = C.checkRecite(text, t, up);
    C.diag('recite ' + t + ' (try ' + attempt + '): "' + text + '" -> ' + (r.ok ? 'PERFECT' : 'wrong ' + JSON.stringify(r.wrong) + ' unsure ' + JSON.stringify(r.unsure) + ' missing ' + JSON.stringify(r.missing)));
    if (!text) { await say("I did not hear you. Let's try again."); continue; }
    if (!r.facts.length) { await say('I could not follow that. Say it slowly: ' + t + ' one ja ' + t + '.'); continue; }
    if (r.ok) { o.unsure = []; r.done.forEach(function (b) { bSet(t, b, 1, 1); }); drawBoard(); return true; }
    /* v60 (user, 08-Nov, option B): a line the app was only UNSURE about counts as right (green) and is not asked again; it goes into the short check after the table */
    var uns = (o.unsure || []).concat(r.unsure.map(function (w) { return w.b; }));
    r.unsure.forEach(function (w) { bSet(t, w.b, 1, 1); });
    /* v61 (user, 08-Nov: "9 2 zaa was not heard properly ... fix it differently"): his 9-table recording had 9 clear spoken lines but the listening caught only 3 (even a
       one-line-at-a-time test on the same sound failed from line 3) - the long recitation is the weakest listening there is. Lines it did not catch are NOT asked one by one
       any more: they go into the short random check (first, with the unsure ones), where the listening is short and good, and THAT decides. */
    var heardN = r.done.length + r.unsure.length;
    if (heardN < Math.ceil(up / 2)) {           /* v69 (user, 08-Nov: "I didn't finish the table, the app says I finished"): only 2 of 10 lines heard is not a table said */
      C.diag('recite ' + t + ': only ' + heardN + ' of ' + up + ' lines heard - asking for the whole table again');
      await say('I could hear only ' + (heardN === 1 ? 'one line' : heardN + ' lines') + '. Say the whole table again, a bit louder.'); continue;
    }
    if (!r.wrong.length) {
      var lost = r.missing.concat(r.unclear);
      o.unsure = uns.concat(lost);
      C.diag('recite ' + t + ': ' + lost.length + ' lines not heard, ' + uns.length + ' unsure - none asked one by one, they go into the quick check');
      r.done.forEach(function (b) { bSet(t, b, 1, 1); }); drawBoard(); return true;
    }
    r.wrong.forEach(function (w) { bSet(t, w.b, 2, 1); }); drawBoard();
    var fix = [];
    r.wrong.slice(0, 3).forEach(function (w) { fix.push({ b: w.b, msg: 'You said ' + t + ' ' + w.b + ' ja ' + w.said + '. That is wrong. ' + t + ' ' + w.b + ' ja ' + (t * w.b) + '. Say it with me.' }); });
    r.missing.concat(r.unclear).slice(0, 6).forEach(function (b) { fix.push({ b: b, msg: 'You missed ' + t + ' ' + b + '. ' + t + ' ' + b + ' ja ' + (t * b) + '. Say it.' }); });
    var nWrong = r.wrong.length, nMiss = r.missing.length + r.unclear.length, allFixed = true;
    /* v33 (user, 01-Nov-2026: "it stays back till it understands"): lines the app did not catch (missed / not sure) are asked one by
       one; if that was all and he says each one right, the table counts - no whole table again. A WRONG answer still means the whole table once more. */
    var onlyCatch = !nWrong && fix.length === nMiss;
    o.unsure = uns;
    if (fix.length) await say(nWrong ? 'Good try! ' + (nWrong === 1 ? 'One line was wrong.' : nWrong + ' lines were wrong.') : (nMiss ? 'Almost! ' + (nMiss === 1 ? 'One line was missing.' : nMiss + ' lines were missing.') : 'Almost!'));
    for (var i = 0; i < fix.length; i++) {
      var f = fix[i]; bCur(t, f.b);
      $('kQ').className = 'q'; $('kQ').textContent = t + ' × ' + f.b + ' = ' + (f.hide ? '?' : (t * f.b));   /* a doubtful line is a real question: the answer is not shown / said until he has tried */
      S.curQ = 'f' + t + 'x' + f.b + '#' + (++S.qn);
      A.setGrammar(C.qGrammar(t, f.b));
      await say(f.msg);
      var got = false;
      for (var k = 0; k < 2; k++) {
        var h = await hear({ num: true });
        if (h.text && C.tableJudge(h.alts || [], t, f.b).ok) { got = true; bSet(t, f.b, 3, 1); drawBoard(); await say(rnd(['Good!', 'Yes!', 'Right!']), false); break; }
        if (k === 0) await say('Listen. ' + t + ' ' + f.b + ' ja ' + (t * f.b) + '. Now you.');
      }
      if (!got) allFixed = false;
    }
    if (onlyCatch && allFixed) {
      C.diag('recite ' + t + ': only missed / unsure lines - each said right one by one, table counts');
      r.done.forEach(function (b) { bSet(t, b, 1, 1); }); drawBoard(); return true;
    }
    o.unsure = [];
    logAns('r', 'Table of ' + t + ' (said all)', 'all right', text.slice(0, 120), false, true);
  }
  await say(mode === 'answers' ? 'Good practice! Keep practising, then take the test without seeing.' : 'Well done for trying! We will say the table of ' + t + ' again next time.');
  return false;
}
async function practice(kid, o) {
  S.nextOK = true; S.jumpOK = false; setSect(o.mode === 'app' ? 'learn' : 'recite'); $('kNextT').textContent = '⏭ Stop this table';
  try { await practice0(kid, o); }
  catch (e) { if (e !== NEXTT) throw e; S.nextT = false; S.reciting = false; RC = null; hideFlash(); S.nextOK = false; hbShow(); await say('OK.', false); }
  finally { S.nextOK = false; S.testOK = false; $('kNextT').textContent = '⏭ Next table'; setSect(''); }
}
async function practice0(kid, o) {
  var t = +o.t, up = upto(); if (!hcOk(t)) { toast('🔒 Table ' + t + ' is not one of your free tables - ask a parent'); C.diag('locked table ' + t + ' (free plan)'); return; }
  SES.tablesText = 'Table of ' + t; SES.title = 'Table of ' + t;
  if (o.mode === 'app') {                        /* 🗣️ with the app: listen and repeat each line, then the test */
    var lb = []; for (var b0 = 1; b0 <= up; b0++) lb.push([t, b0]);
    bTable(lb, '🗣️ Say it with the app · table of ' + t);
    S.testOK = true; S.testNow = false; hbShow();
    try {
      await say("Let's say the table of " + t + ' together. Listen and say it after me.');
      for (var b = 1; b <= up; b++) await inQ(function () { return learnFact(t, b); });
    } catch (e) {
      if (e !== TESTN) { S.testOK = false; throw e; }
      S.testNow = false; stage('🙈 Test · table of ' + t, ''); await say('OK! Let us test the table of ' + t + ' without looking.', false);
    }
    S.testOK = false; setSect('recite');
    o.mode = 'test';
  }
  /* v127 (user, 18-Nov-2026: "when I speak fast, as we fixed on the mobile, it does not happen on the TV"): the TV also says the table LINE BY LINE (smart pace -
     one short mic window per line suits the remote's mic) for 👀 with answers and for 🙈 test 🔢 In order; 🔀 Mixed stays question by question */
  var tvF = IS_TV && A && A.setGrammar && (!A.voskState || A.voskState() === 'ready') && (o.mode !== 'test' || (S.testOrder || C.LS.get('hc_test_order', 'mix')) === 'order');
  var ro = { mode: o.mode }, ok, byQ = !reciteOk() && !tvF;
  if (byQ) {                                       /* v69 (TV): the whole table as questions - mixed for the test, in order with answers shown for 👀 */
    var ql = []; for (var bq = 1; bq <= up; bq++) ql.push([t, bq]);
    var mixQ = o.mode === 'test' && (S.testOrder || C.LS.get('hc_test_order', 'mix')) !== 'order';      /* v122: mixed (default) or in order, chosen on the practise screen */
    setSect('q'); await say(mixQ ? 'Table of ' + t + ', mixed up. Tell me the answers.' : 'Table of ' + t + ', in order. Tell me the answers.');
    ok = await round(mixQ ? shuffle(ql) : ql, 'Table of ' + t + (o.mode === 'test' ? (mixQ ? ' · test' : ' · test in order') : ' · in order'));
    ok = ok === true || (ok === false && S.roundFixed);
    if (!ok) await say('Good try! We will practise the table of ' + t + ' again.');
  } else {
    ok = await reciteTable(t, up, ro);
    if (ok && o.mode === 'test' && !ro.proven) ok = await randomCheck(t, ro.unsure || [], up);
  }
  if (ok && o.mode === 'test') {
    var p = SES.prog, st = p.t[t] || (p.t[t] = { st: 0, ok: 0 });
    st.st = 3; st.ok = rounds(); st.at = C.day(); SES.mastered.push(t); saveProg(); confetti();
    logAns('r', 'Table of ' + t + ' (from memory)', 'all right', 'perfect', true, true);
    flash(true, 'Table of ' + t + ' learnt!', '⭐ +5 stars', 3200); SES.stars += 5;
    await say(byQ ? 'Super! You know the whole table of ' + t + '! Five bonus stars!' : 'Super! You said the whole table of ' + t + ' from memory without a mistake! Five bonus stars!', false); hideFlash();
  } else if (ok) {
    logAns('r', 'Table of ' + t + ' (answers shown)', 'all right', 'perfect', true, true);
    if (o.mode === 'answers') {                     /* v120 (user, 17-Nov-2026: "ask me - more practice or the test; only if I press / say test it tests, else practise the same table again") */
      S.choice = ''; S.choiceOK = true; hbShow();
      var ch = '', hr;
      try {
        await say('Perfect! Do you want more practice, or the test? Say test, or say practice. You can also press a button.');
        ch = S.choice;
        for (var tr = 0; !ch && tr < 3; tr++) {
          if (A && A.setGrammar) A.setGrammar(JSON.stringify(['test', 'take test', 'take the test', 'test me', 'exam', 'practice', 'practise', 'more practice', 'more', 'again', 'repeat', 'stop', '[unk]']));
          hr = await hear({});
          ch = S.choice || (/\b(test|exam|quiz)\b/i.test(hr.text || '') ? 'test' : /\b(practice|practise|more|again|repeat)\b/i.test(hr.text || '') ? 'more' : '');
          if (!ch && tr < 2) await say('Say test, or say practice.');
        }
      } finally { S.choiceOK = false; S.choice = ''; hbShow(); }
      C.diag('practice ' + t + ': asked - ' + (ch || 'nothing said') + ' -> ' + (ch === 'test' ? 'test' : 'practise again'));
      if (ch === 'test') { o.mode = 'test'; return practice0(kid, o); }
      o.rep = (o.rep || 0) + 1; if (o.rep >= 5 || timeLeft() < 0) { await say('Good practice! Come back soon.'); return; }
      return practice0(kid, o);                       /* no "test" said or pressed: the same table again, answers shown */
    }
    await say('Perfect! Now try it without looking: the test.');
  }
}
return {fact: fact, askTable: askTable, notHeard: notHeard, learnFact: learnFact, sleepy: sleepy, askStop: askStop, timeLeft: timeLeft, loadProg: loadProg, saveProg: saveProg, shuffle: shuffle, rounds: rounds, upto: upto, weakAdj: weakAdj, round: round, nextTable: nextTable, tablesLearn: tablesLearn, tablesRevise: tablesRevise, runSet: runSet, askOral: askOral, spellAccept: spellAccept, askSpell: askSpell, skipWord: skipWord, spellOut: spellOut, askSpellG: askSpellG, parentSpell: parentSpell, activeSets: activeSets, mixedSets: mixedSets, runClass: runClass, finish: finish, stopClass: stopClass, reciteOk: reciteOk, spellListen: spellListen, reciteListen: reciteListen, waitStart: waitStart, randomCheck: randomCheck, followLine: followLine, followTable: followTable, reciteTable: reciteTable, practice: practice, practice0: practice0};
})()