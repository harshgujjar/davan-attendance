"""
test_day_attendance.py  -  small TEST only (does not touch app.py, writes NO database)

Asks davandvg.com for ONE class (default BCA Sem 3 Sec A) for ONE day, trying
several date formats, and prints what came back for each.

Run (in the same folder as app.py):
    python test_day_attendance.py 2026-10-06
    python test_day_attendance.py 2026-10-06 1 3 1      (course 1=BCA 2=BCom 3=BBA, sem, section 1=A..5=E)

Login: env DAVAN_PORTAL_USER / DAVAN_PORTAL_PASS, else read from app.py next to
this file, else it asks you.
Each reply is also saved as day_test_<n>.html so it can be opened in a browser.
"""
import os, re, sys, getpass
from datetime import datetime, timedelta
import requests
from bs4 import BeautifulSoup

BASE = "http://www.davandvg.com"
AJAX = BASE + "/dashboard/redicore.php"
DASH = BASE + "/dashboard/attendance.php"
COURSES = {"1": ("BCA", "B"), "2": ("BCom", "C"), "3": ("BBA", "BA")}

def creds():
    u = os.environ.get("DAVAN_PORTAL_USER"); p = os.environ.get("DAVAN_PORTAL_PASS")
    app = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app.py")
    if (not u or not p) and os.path.exists(app):
        src = open(app, encoding="utf-8", errors="ignore").read()
        mu = re.search(r'AUTO_SCRAPE_USER\s*=.*?"([^"]+)"\s*$', src, re.M)
        mp = re.search(r'AUTO_SCRAPE_PASS\s*=.*?"([^"]+)"\s*$', src, re.M)
        u = u or (mu and mu.group(1)); p = p or (mp and mp.group(1))
    if not u: u = input("Portal user: ").strip()
    if not p: p = getpass.getpass("Portal password: ")
    return u, p

def login(u, p):
    s = requests.Session()
    s.headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124 Safari/537.36"
    s.get(BASE + "/index.php", timeout=15)
    r = s.post(BASE + "/rediCore.php", data={"reqst": "login", "ty": "a", "u": u, "p": p},
               headers={"X-Requested-With": "XMLHttpRequest"}, timeout=15)
    print("LOGIN reply:", repr(r.text.strip()[:40]))
    if r.text.strip() != "1":
        sys.exit("Login failed - stop.")
    s.get(DASH, timeout=15)   # open the attendance page once, like a browser
    return s

def summary(html):
    soup = BeautifulSoup(html, "html.parser")
    tables = soup.find_all("table")
    rows = soup.find_all("tr")
    n_bad = html.count("-1 -1")
    ct = [c.get_text(" ", strip=True) for c in soup.select("td.bsum")]
    ca = [c.get_text(" ", strip=True) for c in soup.select("td.asum")]
    nums = []
    for t in ct:
        for x in t.split():
            if x.lstrip("-").isdigit(): nums.append(int(x))
    urns = sorted(set(re.findall(r"\b[0-9A-Z]{2,}\d{4,}[0-9A-Z]*\b", soup.get_text(" "))))
    first = ""
    for tr in rows:
        tds = tr.find_all("td")
        if len(tds) > 4:
            first = " | ".join(td.get_text(" ", strip=True) for td in tds[:12]); break
    return (f"tables={len(tables)} rows={len(rows)} CTcells={len(ct)} CAcells={len(ca)} "
            f"maxCT={max(nums) if nums else '-'} '-1 -1'={n_bad} urn-like={len(urns)}\n"
            f"      first row: {first[:220] or '(none)'}\n"
            f"      text start: {soup.get_text(' ', strip=True)[:160]!r}")

def main():
    day = datetime.strptime(sys.argv[1], "%Y-%m-%d") if len(sys.argv) > 1 else datetime.now()
    crs = sys.argv[2] if len(sys.argv) > 2 else "1"
    sem = sys.argv[3] if len(sys.argv) > 3 else "3"
    sx  = sys.argv[4] if len(sys.argv) > 4 else "1"
    name, crstxt = COURSES[crs]
    print(f"Class: {name} Sem {sem} Sec {'ABCDE'[int(sx)-1]}   Day: {day:%Y-%m-%d}\n")
    s = login(*creds())
    nxt = day + timedelta(days=1)
    tries = [("TERM (blank dates, for comparison)", "", "")]
    for f in ["%d-%m-%Y", "%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y", "%Y/%m/%d"]:
        tries.append((f"same day  {f}", day.strftime(f), day.strftime(f)))
    for f in ["%d-%m-%Y", "%Y-%m-%d", "%d/%m/%Y"]:
        tries.append((f"day..next {f}", day.strftime(f), nxt.strftime(f)))
    for i, (label, dtf, dtt) in enumerate(tries, 1):
        params = {"reqst": "srch", "key": "fata", "cig": "1", "sx": sx, "csm": sem, "sm": sem,
                  "crs": crs, "crstxt": crstxt, "brch": "-1", "dtf": dtf, "dtt": dtt,
                  "subId": "undefined", "studId": "undefined"}
        try:
            r = s.get(AJAX, params=params, timeout=30,
                      headers={"X-Requested-With": "XMLHttpRequest", "Referer": DASH})
            fn = f"day_test_{i}.html"
            open(fn, "w", encoding="utf-8").write(r.text)
            print(f"[{i}] {label:32} dtf={dtf!r} dtt={dtt!r}  HTTP {r.status_code} len={len(r.text)}  -> {fn}")
            print("      " + summary(r.text) + "\n")
        except Exception as e:
            print(f"[{i}] {label}: ERROR {e}\n")
    print("Done. Copy ALL the text above and paste it back to Claude.")

if __name__ == "__main__":
    main()
