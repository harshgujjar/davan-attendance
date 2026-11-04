"""🖥️ PC Doctor: writes pcdoctor/lab-version.json (ROADMAP-pcdoctor.md 13) - run after every change in pcdoctor/:
    python3 tools/pcdoctor_version.py "short note for 🆕 What's new"
- adds the UTF-8 BOM to every src/*.ps1 (Windows PowerShell 5.1 reads a file without it as ANSI and breaks the emoji)
- SHA-256 of every file the loader downloads (a changed / fake file is refused by the PCs)
- bumps the build of each part whose files changed (agent / tray / checks / fixes / rescue / console), with version, IST date-time, notes."""
import hashlib, json, os, sys, datetime as dt
R = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "pcdoctor")
P = os.path.join(R, "lab-version.json")
IST = dt.timezone(dt.timedelta(hours=5, minutes=30))
note = (sys.argv[1] if len(sys.argv) > 1 else "").strip()
PARTS = {"agent": ["agent.ps1", "common.ps1", "loader.ps1", "install.ps1", "dlh.ps1"], "checks": ["checks.ps1"], "fixes": ["fixes.ps1"],
         "tray": ["tray.ps1"], "rescue": ["../DavanRescue.cmd"], "console": ["../../lab.html"]}
for f in os.listdir(os.path.join(R, "src")):
    if f.endswith(".ps1"):
        p = os.path.join(R, "src", f); b = open(p, "rb").read()
        if not b.startswith(b"\xef\xbb\xbf"): open(p, "wb").write(b"\xef\xbb\xbf" + b)
# 04-Nov-2026: PowerShell names are case-blind - a function that uses $s (a sample / loop item) AND the agent state $S silently
# overwrites the state (first real PC: $S.ring null, no minute rows). Refuse to publish until it is renamed.
import re
bad = []
for f in sorted(os.listdir(os.path.join(R, "src"))):
    if not f.endswith(".ps1"): continue
    L = open(os.path.join(R, "src", f), encoding="utf-8-sig").read().split("\n")
    st = [i for i, l in enumerate(L) if re.match(r"\s*function\s", l)]
    for n, a in enumerate(st):
        body = "\n".join(l.split("#")[0] for l in L[a:(st[n + 1] if n + 1 < len(st) else len(L))])
        if re.search(r"\$s\b", body) and re.search(r"\$S\b", body): bad.append("%s:%d %s" % (f, a + 1, L[a].strip()[:60]))
if bad: sys.exit("STOP - these functions use both $s and $S (same variable in PowerShell), rename $s:\n  " + "\n  ".join(bad))
sha = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
old = json.load(open(P)) if os.path.exists(P) else {}
files = {f: sha(os.path.join(R, "src", f)) for f in sorted(os.listdir(os.path.join(R, "src"))) if f.endswith(".ps1")}
now = dt.datetime.now(IST); ms = int(now.timestamp() * 1000)
out = {"_about": "Davan PC Doctor versions (pcdoctor/lab-version.json). The loader on every PC reads this; files = SHA-256 of src/*. Made by tools/pcdoctor_version.py.",
       "files": files, "rescue": sha(os.path.join(R, "DavanRescue.cmd")), "setup": sha(os.path.join(R, "PCDoctor-Setup.cmd")), "news": old.get("news", [])}
changed_any = False
for part, fl in PARTS.items():
    paths = [os.path.normpath(os.path.join(R, "src", f)) for f in fl]
    h = hashlib.sha256("".join(sha(p) for p in paths if os.path.exists(p)).encode()).hexdigest()[:16]
    o = old.get(part) or {}
    if o.get("h") != h:
        b = int(o.get("build") or 0) + 1; changed_any = True
        o = {"build": b, "ver": "1.%d" % b if part != "console" else o.get("ver", "1.%d" % b), "h": h, "at": ms, "ist": now.strftime("%d %b %Y, %I:%M %p IST").replace(" 0", " "), "notes": note or o.get("notes", "")}
    if part == "console":   # the Console's own LAB_BUILD (open Consoles reload when lab-version.json shows a higher one)
        import re
        lb = int(re.search(r"const LAB_BUILD = (\d+)", open(os.path.join(R, "..", "lab.html"), encoding="utf-8").read()).group(1))
        if o.get("build") != lb: o = dict(o, build=lb, ver="1.%d" % lb, at=ms, ist=now.strftime("%d %b %Y, %I:%M %p IST").replace(" 0", " "), notes=note or o.get("notes", ""))
    out[part] = o
# the agent build moves when ANY downloaded file changed (the loader compares agent.build)
fh = hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest()[:16]
a = out["agent"]
if (old.get("agent") or {}).get("fh") != fh:
    if (old.get("agent") or {}).get("build") == a["build"]: a = dict(a, build=a["build"] + 1, at=ms, ist=out["agent"]["ist"] if out["agent"].get("ist") else "", notes=note or a.get("notes", ""))
    a["ver"] = "1.%d" % a["build"]; a["fh"] = fh; a["at"] = ms; a["ist"] = now.strftime("%d %b %Y, %I:%M %p IST").replace(" 0", " "); changed_any = True
out["agent"] = a
if note and changed_any: out["news"] = ([{"t": ms, "ist": out["agent"]["ist"], "build": a["build"], "text": note}] + out["news"])[:40]
json.dump(out, open(P, "w"), indent=1, ensure_ascii=False); open(P, "a").write("\n")
print("lab-version.json: agent %s (build %d)" % (a["ver"], a["build"]), "| changed" if changed_any else "| no change")
