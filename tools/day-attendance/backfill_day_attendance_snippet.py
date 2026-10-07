# NOT IN USE (paused 07-Oct-2026). Code ready to paste into app.py (after push_day_attendance_to_db2, before build_class_summary)
# plus, in __main__ before --run-once:  if "--backfill" in sys.argv: backfill_day_attendance(int(sys.argv[sys.argv.index("--backfill")+1]))

# v090 (user, 07-Oct-2026: "old data is not taken"): fill the past days too. Same per-day pass as /api/scrape_today, run
# for every day from (today - N) to yesterday, Sundays skipped, oldest first. About 90 portal requests per day, so 35 days
# take roughly 20-30 minutes. Only the last ATT_DAY_KEEP_DAYS days are kept anyway, so N is capped at that.
_backfill_state = {"running": False, "done": [], "current": None, "started": None, "finished": None, "error": None}

def backfill_day_attendance(days=ATT_DAY_KEEP_DAYS, sess=None):
    days = max(1, min(int(days), ATT_DAY_KEEP_DAYS))
    st = _backfill_state
    st.update({"running": True, "done": [], "current": None, "started": datetime.now().isoformat(), "finished": None, "error": None})
    try:
        if sess is None:
            sess, resp_text = _attempt_scheduler_login()
            if sess is None:
                raise RuntimeError("could not log in to davandvg.com (answer: " + repr(resp_text) + ")")
        today = datetime.now().replace(hour=12, minute=0, second=0, microsecond=0)
        for i in range(days, 0, -1):
            day = today - timedelta(days=i)
            key = day.strftime("%Y-%m-%d")
            if day.weekday() == 6:
                st["done"].append({"date": key, "skipped": "Sunday"}); continue
            st["current"] = key
            print(f"[BACKFILL] {key} ...")
            day_map, classes_seen, suspicious = scrape_day_attendance(sess, day)
            if not day_map and classes_seen == 0:
                # maybe the session expired - log in again once and retry this day
                s2, _ = _attempt_scheduler_login()
                if s2 is not None:
                    sess = s2
                    day_map, classes_seen, suspicious = scrape_day_attendance(sess, day)
            res = push_day_attendance_to_db2(day_map, day, suspicious)
            st["done"].append({"date": key, "classes": classes_seen, "students": len(day_map), "saved": res.get("saved", 0),
                               "ok": res.get("ok")})
        print(f"[BACKFILL] ✅ finished: {len(st['done'])} days")
    except Exception as e:
        st["error"] = str(e); print(f"[BACKFILL] ✗ {e}")
    finally:
        st["running"] = False; st["current"] = None; st["finished"] = datetime.now().isoformat()
    return st


@app.route("/api/backfill_days", methods=["POST", "GET"])
def api_backfill_days():
    """v090: fill the last ?days=N days (default 35) in the background. Progress: /api/backfill_days_status."""
    if _backfill_state.get("running"):
        return jsonify({"ok": False, "error": "already running", "status": _backfill_state})
    try:
        n = int(request.args.get("days") or ATT_DAY_KEEP_DAYS)
    except Exception:
        return jsonify({"ok": False, "error": "days must be a number"})
    threading.Thread(target=backfill_day_attendance, args=(n,), daemon=True).start()
    return jsonify({"ok": True, "started": True, "days": min(max(n, 1), ATT_DAY_KEEP_DAYS),
                    "progress": "open /api/backfill_days_status to watch"})


@app.route("/api/backfill_days_status", methods=["GET"])
def api_backfill_days_status():
    return jsonify(_backfill_state)


