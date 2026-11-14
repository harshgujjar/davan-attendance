"""E-Library link check (library.html v1.44, user 14-Nov-2026: "build properly the log ... links work or not").
Checks every link of the e-library - elibrary.json (main) + the librarian's own items (DB2 library/elib/items) - and writes
elibrary-health.json, which library.html reads: a page gone (404/410) on 2 checks in a row is hidden from students
(staff still see it in red). Runs every Sunday by itself, when elibrary.json changes, and within 3 hours of the
"Check again" button (DB2 library/elib/cfg/checkReq). New hidden links -> Super Admin alert (tools/sa_notify.py)."""
import json, os, sys, time, urllib.request, urllib.error, urllib.parse, concurrent.futures as cf, datetime

KEY = 'AIzaSyBnWSfjilDwri7dBpONF2GwgXDJnc1W--w'
DB2 = 'https://davan-student-portal-default-rtdb.asia-southeast1.firebasedatabase.app'
UA = 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'
OUT = 'elibrary-health.json'
now = int(time.time() * 1000)
ist = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None) + datetime.timedelta(hours=5, minutes=30)
event = os.environ.get('GITHUB_EVENT_NAME', 'workflow_dispatch')

def db2(path):
    try:
        r = urllib.request.Request('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + KEY,
                                   data=b'{"returnSecureToken":true}', headers={'Content-Type': 'application/json'})
        tok = json.load(urllib.request.urlopen(r, timeout=20))['idToken']
        return json.load(urllib.request.urlopen(DB2 + '/' + path + '.json?auth=' + tok, timeout=30))
    except Exception as e:
        print('DB2 read failed', path, e); return None

old = {}
try: old = json.load(open(OUT))
except Exception: pass
cfg = db2('library/elib/cfg') or {}
last = old.get('checkedAt', 0)
req = int((cfg or {}).get('checkReq') or 0)
due = event in ('workflow_dispatch', 'push') or req > last or (now - last) > 6.5 * 86400
def sa(ev):
    try: json.dump(ev, open(os.path.join(os.environ.get('RUNNER_TEMP', '.'), 'sa.json'), 'w'))
    except Exception: pass
if not due:
    print('nothing due (last check %s, request %s)' % (last, req)); sa({'skip': True, 'body': 'nothing due'}); sys.exit(0)

seed = json.load(open('elibrary.json'))
items = {i['id']: i for i in seed.get('items', [])}
own = db2('library/elib/items') or {}
for k, v in (own.items() if isinstance(own, dict) else []):
    if isinstance(v, dict): items[k] = dict(items.get(k, {}), **v)
urls = sorted({i.get('u') for i in items.values() if i.get('u') and not i.get('del')})

def check(u):
    host = urllib.parse.urlparse(u).netloc
    for tries in (1, 2):
        try:
            r = urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent': UA, 'Accept': 'text/html,*/*'}), timeout=30)
            fin = r.geturl(); h2 = urllib.parse.urlparse(fin).netloc
            base = lambda h: h.lower().split(':')[0].removeprefix('www.').removeprefix('m.')   # mobile / www copies are the same site
            moved = base(h2) != base(host)
            return u, {'st': 'moved' if moved else 'ok', 'code': r.status, 'to': fin if moved else ''}
        except urllib.error.HTTPError as e:
            if e.code in (404, 410): return u, {'st': 'dead', 'code': e.code}
            if e.code in (401, 403, 405, 406, 429, 503, 520, 521, 522, 525): return u, {'st': 'bot', 'code': e.code}
            last_err = {'st': 'down', 'code': e.code}
        except Exception as e:
            last_err = {'st': 'down', 'code': 0, 'err': str(e)[:80]}
        time.sleep(4)
    return u, last_err

res = {}
with cf.ThreadPoolExecutor(8) as ex:
    for u, r in ex.map(check, urls): res[u] = r
prev = old.get('results', {})
hidden_new = []
for u, r in res.items():
    bad = r['st'] in ('dead', 'down')
    r['n'] = (prev.get(u, {}).get('n', 0) + 1) if bad else 0
    # hide only a page that is really gone (404/410 twice); 'no answer' is often an Indian govt site refusing
    # foreign cloud servers while it opens fine on students' phones - it stays visible, staff see it in red
    r['hide'] = r['st'] == 'dead' and r['n'] >= 2
    if r['hide'] and not prev.get(u, {}).get('hide'): hidden_new.append(u)
cnt = {k: sum(1 for r in res.values() if r['st'] == k) for k in ('ok', 'moved', 'bot', 'dead', 'down')}
stamp = ist.strftime('%d-%b %H:%M')
log = (old.get('log') or [])[-40:]
log.append('%s CHECK %d links · ok %d · moved %d · site-blocks-robots %d · dead %d · no answer %d (%s)' % (
    stamp, len(urls), cnt['ok'], cnt['moved'], cnt['bot'], cnt['dead'], cnt['down'], event))
for u, r in sorted(res.items()):
    if r['st'] in ('dead', 'down', 'moved'):
        log.append('%s   %s %s %s%s' % (stamp, r['st'].upper(), r.get('code') or '', u, ' -> ' + r['to'] if r.get('to') else (' (hidden)' if r['hide'] else '')))
json.dump({'checkedAt': now, 'checkedIST': ist.strftime('%d %b %Y, %I:%M %p IST'), 'total': len(urls), 'counts': cnt,
           'results': res, 'log': log}, open(OUT, 'w'), indent=1)
print(log[-1])
if hidden_new:
    sa({'title': '📚 E-Library: %d link%s hidden' % (len(hidden_new), 's' if len(hidden_new) > 1 else ''),
        'body': 'Dead on 2 checks, hidden from students: ' + ', '.join(hidden_new[:5]), 'color': 'orange'})
else:
    sa({'skip': True, 'body': 'no new broken links'})
