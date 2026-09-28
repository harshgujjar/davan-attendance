# Davan attendance — working rules

## Changelog entries: full, with line numbers (DEFAULT for every change, every file)

Every change adds a changelog entry in the file it changes, **in the same commit**:

| File | Where |
|---|---|
| `index.html` | `HTML_CHANGELOG` (newest first) + bump `CODE_BUILD` |
| `student_portal.html` | `VERSION : vX.YY (date) -- ...` line at the top + bump `APP_VERSION` and the footer / topbar version strings |
| other app files (`faculty.html`, `puc.html`, `cleaning.html`, `results.html`, ...) | that file's own changelog / version header |
| student widget source (kept out of git) | `W<nn>_CHANGES.md` in the widget folder |

Each entry is a **full** entry, never a one-liner:
1. **What changed** for the user (in plain words) and **why** (the report / bug / request).
2. **Data** touched: database paths read / written, their shape, and the Firebase cost (free plan: say what extra reads or writes it adds, or that it adds none).
3. **Pairs with**: the matching versions of the other apps (e.g. `Pairs with portal v9.93 and widget w101`).
4. **Verified**: what was actually tested (and what could not be, e.g. no APK build here).
5. **FILES** part at the end, one per changed file, with the function / const names and their **current line numbers**:
   `FILES (index.html): hcRatingsWho 82990; hcRatingsHtml (tap average) 83014.`
   Widget: `FILES (StudentHostel.kt): onRate 663; syncAnswers 653.`
   The first word of each item must be the code name at that line (the checker below relies on it).

## Keep the line numbers right

Line numbers move with every edit. Before **every** commit run:

```
python3 tools/changelog_lines.py --fix index.html student_portal.html   # add any other changed .html
python3 tools/changelog_lines.py index.html student_portal.html          # must print "stale refs: 0"
```

It rewrites stale refs in **all** entries (old ones too) to the nearest line that mentions the name.
