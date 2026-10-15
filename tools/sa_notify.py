"""Super Admin alert from a GitHub job (v1853, user 15-Oct-2026: "tell me when a cloud job is done or FAILED - only me").
Last step of a job (if: always()):  python3 tools/sa_notify.py "<job name>" <kind>   with env JOB_STATUS = ${{ job.status }}.
The job's own scripts may leave $RUNNER_TEMP/sa.json = {"title", "body", "color", "skip"}: skip = true sends nothing (a slot that had
nothing to do); no file + success = nothing sent unless SA_ALWAYS=1. A failed job always sends a red alert. The Cloudflare worker
davan-release (POST /sa) checks that this run really is running, saves the alert for the Super Admin's phone app (DB2 davan_pub/sa_ev)
and pushes it to his laptops. Never fails the job."""
import json, os, sys, urllib.request

name = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("GITHUB_WORKFLOW", "Cloud job")
kind = sys.argv[2] if len(sys.argv) > 2 else "job"
ok = os.environ.get("JOB_STATUS", "success") == "success"
f = os.path.join(os.environ.get("RUNNER_TEMP", "."), "sa.json")
ev = None
try:
    ev = json.load(open(f)) if os.path.exists(f) else None
except Exception as e:
    print("sa.json unreadable:", e)
if not ok:
    ev = {"title": "❌ " + name + " FAILED", "body": ((ev or {}).get("body") or "A step failed - open the run for the log.")
          + (" (cancelled)" if os.environ.get("JOB_STATUS") == "cancelled" else ""), "color": "red"}
    kind = "fail"
elif ev is None:
    if os.environ.get("SA_ALWAYS") != "1":
        print("nothing to tell the Super Admin"); sys.exit(0)
    ev = {"title": "✅ " + name + " done", "color": "green"}
elif ev.get("skip"):
    print("skipped - no alert:", ev.get("body", "")); sys.exit(0)
ev.update(repo=os.environ.get("GITHUB_REPOSITORY", ""), run=os.environ.get("GITHUB_RUN_ID", ""), kind=ev.get("kind") or kind,
          by=ev.get("by") or ("GitHub · " + ("timer" if os.environ.get("GITHUB_EVENT_NAME") == "schedule" else "Cloudflare / by hand")))
try:
    req = urllib.request.Request("https://davan-release.harshgujjar.workers.dev/sa", data=json.dumps(ev).encode(),
                                 headers={"Content-Type": "text/plain", "User-Agent": "davan-sa-notify"})
    print("Super Admin alert:", urllib.request.urlopen(req, timeout=30).read().decode()[:300])
except Exception as e:
    print("alert not sent:", e)
