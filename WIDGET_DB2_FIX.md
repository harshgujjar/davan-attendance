# Widget DB2 fix — handoff

**For:** the session that owns the Android student widget source (w101 and later).
**From:** the session that fixed the student portal's DB2 usage (portal v9.78 → v9.96, index.html v1535).
**Goal:** the widget downloads only **its own student's results** and **its own class's lesson plan**, and only **when they change** — the same way `student_portal.html` already does.

---

## 1. The problem (measured, DB2 meter, 29-Sep-2026)

| App | Path | Reads | Avg | Total | % of day |
|---|---|---|---|---|---|
| **Widget** | `davan_pub/results` | 63 | 1.6 MB | **98.1 MB** | 38.8% |
| **Widget** | `davan_pub/lessonPlan` | 95 | 642.7 KB | **59.6 MB** | 23.6% |
| Student portal | `davan_pub/results` | 3 | 1.5 MB | 4.6 MB | (admin Publish only) |
| Student portal | `davan_pub/lessonPlan` (+ per-subject reads) | 394 | 6.7 KB | 2.6 MB | (names + own subjects) |

Day total: **252.5 MB**. The widget alone = **158 MB (62%)**.
After this fix the day should be **~90–100 MB** (≈3 GB/month, free plan is 10 GB).

- `davan_pub/results` = **every student's university results**, ~1.5 MB. A student needs only their own rows.
- `davan_pub/lessonPlan` = **all 72 subjects of all classes**, ~640 KB. A class needs only its own 6–11 subjects (~50–160 KB), and after that only a subject whose `updated_at` changed.

The data the widget needs **already exists in DB2** — the portal publishes it. **No database, rules, index.html or app.py change is needed.** Only the widget's read code changes.

DB2 = `https://davan-student-portal-default-rtdb.asia-southeast1.firebasedatabase.app` (same DB the widget already reads).

---

## 2. First, find what the widget actually uses

Before changing anything, search the widget source for every read of:

- `davan_pub/results` (probably for SGPA / ranks / last result on the widget face)
- `davan_pub/lessonPlan` (probably for "syllabus %" / today's topic)

Also check **how** it reads:

- **`addValueEventListener` / `onValue` (a live listener) on these nodes is the worst case** — every change anywhere (any student, any subject) re-downloads the whole node. Replace with a single read (`get()` / `addListenerForSingleValueEvent`) as part of this fix.
- Note how often the widget refreshes (e.g. every 30 min / on each app-widget update). 63 results reads + 95 LP reads in one day ≈ a full download on every refresh.

---

## 3. Fix A — results: read only the student's own copy

### 3.1 What the portal publishes (already live)

When admin presses **Controls → Global → "📊 Publish results to students"** in `student_portal.html`, it writes:

| Path | Value |
|---|---|
| `davan_pub/results_by_urn/<URN>` | `{ docs: {...}, ranks: {...} }` — this student's copy (~5–30 KB) |
| `davan_pub/results_ver/<URN>` | short fingerprint string of that copy (e.g. `"1a2b3c.4f"`); **`"0"` = student has no results** |
| `davan_pub/results_ver/_pub` | the publish stamp (number, ms) |
| `controls/global/resultsSliceVer` | the same publish stamp (number, ms) |

`<URN>` = upper-case URN, e.g. `U13DI24S0001`.

- `docs` has **the same shape as `davan_pub/results`** (same doc IDs like `BCA_SemIII_2026`, same `regular` / `backlog` arrays, same nested `BCA → semIII → {regular, backlog, subjects}` slots), but every `regular` / `backlog` array contains **only this student's row**. Docs the student is not in keep only their `subjects` name lists. **→ Any existing code that parses `davan_pub/results` works unchanged on `docs`.**
- `ranks` = ranks computed at publish time by the portal's own `computeStudentRanks()` (so they match the portal exactly). Key = `COURSE_SEM` with course upper-case and sem in roman: e.g. `BCA_III`, `BCOM_V`, `BBA_I`. Value:
  ```json
  { "college": 12, "cls": 5, "nu": 0, "di": 7,
    "collegeRanked": 180, "collegeTotal": 240,
    "clsRanked": 40, "clsTotal": 55,
    "campusRanked": 90, "campusTotal": 120 }
  ```
  (`di` = Davan campus rank, `nu` = Nutana campus rank; one of them is 0.) **→ The widget no longer needs the whole cohort to show a rank.**

### 3.2 Read algorithm (copy of the portal's `rcGetSlice`, student_portal.html ~line 24595)

```
gv  = controls/global/resultsSliceVer          (13 bytes; the widget already reads controls/global)
if gv is empty  -> OLD PATH (read davan_pub/results as today)      // never published

saved = local cache { gv, h, val }  (SharedPreferences / file, key "rs_<URN>")
if saved.gv == gv                   -> use saved.val, NO network

h = davan_pub/results_ver/<URN>                (a few bytes)
if h is null:
    pub = davan_pub/results_ver/_pub           (a few bytes)
    if pub == gv  -> val = {docs:{}, ranks:{}}  // student simply has no results (e.g. first-year)
    else          -> OLD PATH                   // node missing/wiped -> safe fallback
elif h == "0"                       -> val = {docs:{}, ranks:{}}
elif saved.h == h                   -> val = saved.val            // unchanged for this student
else                                -> val = davan_pub/results_by_urn/<URN>   (only download)
                                       if that read fails -> keep saved.val, else OLD PATH
save { gv, h, val }
```

Result: normal day = **0 downloads** (gv unchanged); after a Publish = a few bytes, plus one small download **only if this student's marks changed** (revaluation touches only the changed students).

**Important — do not skip these two rules** (both were real bugs in the portal):
1. **Read `gv` from `controls/global/resultsSliceVer` directly** if your controls object isn't loaded yet. The portal once used an empty `gv` during startup and fell back to the full 1.5 MB file every time.
2. **`h == null` + `_pub == gv` means "no results", not "fall back".** Without this, every first-year downloaded the full file on every refresh.

---

## 4. Fix B — lesson plan: only the student's own subjects

### 4.1 Data facts (from the real node, 28-Sep-2026)

- `davan_pub/lessonPlan` has **72 entries**, ~9 KB each.
- Entry key format: **`COURSE-SUBJECT-SemROMAN-SecX`**, e.g. `BCA-Jpro-SemIII-SecA`, `BCom-FIMA-SemV-SecA`, `BCA-ADAP - LAB-SemV-SecB` (**keys can contain spaces** → URL-encode them in REST paths; `%20`).
- Each entry has: `semester, topics, course, subject, total_topics, section, covered_topics, lp_id, handled_count, pct, faculty_id, updated_at, faculty`.
- The subject is in the middle of the key, so **one class's entries are NOT a contiguous key range** (a `startAt/endAt` range on keys does not work).
- There are **no Sem II / Sem IV entries** right now → students in those classes simply have **no lesson plan** (return empty — do **not** fall back to the full node; the portal did that by mistake and paid 637 KB per open).

### 4.2 Class matching rules (copy exactly — `_lpKeyForClass` / `_lpSemOk`, student_portal.html ~line 18305)

Student class string looks like `Davan-BCA-Sem3-SecA` (prefix `Davan`/`Nutana` optional).

```
course  = part after Davan-/Nutana- (e.g. "BCA");       key must CONTAIN course (case-insensitive)
semNum  = digits after "Sem" (e.g. "3"); semRom = I, II, III, IV, V, VI for 1..6
semester: take the WHOLE token after "SEM" in the key:
          regex  SEM([IVX]+|\d+)(?![IVX\d])   ->  token must EQUAL semRom or semNum
          (NOT "contains": "SEMI" is inside "SEMIII" — that bug showed Sem III subjects
           to Sem I students until portal v9.87)
section:  if the key has "-SEC<letter>", it must be "-SEC" + student's section
```

Checked against the real 72 names: BCA Sem1 SecA → 11 entries (all SemI), BCom Sem1 → 9, BBA Sem1 → 9, BCA Sem3 SecA → 9, BCA Sem5 SecA/SecB → 7 each, BBA Sem5 → 6, BCom Sem5 → 6.

(The portal additionally hides some subjects on screen — `controls/lpExceptions`, codes `SPORTS, SYF, NSS, NCC, YRC, QSPIDER, HINL, EXTRA`, names matching `qspider|sports|physical education|nss|ncc|yrc|samskruthi|festival`, and entries with `updated_at` before the semester start. Apply the same if the widget shows a subject list.)

### 4.3 Read algorithm (copy of the portal's `stuLoadOwnLP`)

The portal gets the 72 **names** with a REST shallow read (`davan_pub/lessonPlan.json?shallow=true&auth=<token>`, ~3 KB). **The Firebase Android SDK has no "shallow" read**, so pick one:

- **Option 1 (recommended if the widget can make an HTTPS call):** REST GET
  `https://davan-student-portal-default-rtdb.asia-southeast1.firebasedatabase.app/davan_pub/lessonPlan.json?shallow=true&auth=<ID token>`
  (ID token = `FirebaseAuth.getInstance().currentUser.getIdToken(false)`). Returns `{ "<key>": true, ... }`.
- **Option 2 (SDK only):** build the keys from what the widget already knows — its own timetable / allocation subject codes + course + `Sem<ROMAN>` + `Sec<X>` — and read `davan_pub/lessonPlan/<key>` for each. Treat a missing key as "no lesson plan for that subject".

Then:

```
saved = local cache { cls, items: { key: entry } }   (key "lp_own_v1"; drop it if cls changed)
mine  = names matching the class (rules 4.2)
if mine is empty -> return {} and cache {}          // Sem 2 / Sem 4 today
for each key in mine:
    if saved has it with updated_at:
        u = davan_pub/lessonPlan/<key>/updated_at   (28 bytes)
        if u == saved.updated_at -> keep saved entry, NO download
    entry = davan_pub/lessonPlan/<key>              (~6–13 KB, only if new/changed)
save { cls, items }
if the names read itself fails -> fall back to the old full read (once), never show empty by error
```

Result per refresh: first time ~50–160 KB, later ~2 KB (only `updated_at` checks), one updated subject ≈ 10 KB. (If app.py rewrites `updated_at` on every scrape even without changes, each scrape costs one own-class download ≈ 80 KB — still far below 640 KB.)

---

## 5. Metering (so the DB2 meter shows the new reads)

The widget already reports to the DB2 meter (`davan_pub/meter/<DATE>/widget/...`, app key `widget`). Keep that working for the new paths — the portal's meter groups them as `davan_pub/results_by_urn/<URN>`, `davan_pub/results_ver/<URN>`, `davan_pub/lessonPlan/<key>` and `.../updated_at`.

---

## 6. How to test

1. Install the new widget on a test phone (V NEESHA's account, `U13NU25S0031`, is the admin's test login).
2. Refresh the widget 3 times. **Expected:**
   - 1st refresh: `results_ver/<URN>` (bytes) + `results_by_urn/<URN>` (~30 KB); lesson-plan names (~3 KB) + own subjects (~70 KB for BCA Sem3).
   - 2nd and 3rd refresh: **no** `davan_pub/results` and **no** full `davan_pub/lessonPlan`; only tiny `updated_at` reads.
3. Widget shows the **same** SGPA / ranks / lesson-plan % as before and as the student portal.
4. Admin presses **Publish** in the portal → next widget refresh reads `results_ver/<URN>` (bytes) and downloads the copy **only if that student's marks changed**.
5. A **Sem 1** student's widget shows **no Sem III subjects**; a **Sem 2 / Sem 4** student shows an empty lesson plan without any full download.
6. Next day: in the portal, **Controls → Data Usage → 📋 Copy all** → the `Widget | davan_pub/results` and `Widget | davan_pub/lessonPlan` rows should be gone or near zero.

---

## 7. Reference — where the portal does this (student_portal.html, portal v9.96)

| Function | ~Line | What |
|---|---|---|
| `rcCtlVers` | 24582 | reads the stamps before controls load |
| `rcGetSlice` | 24595 | own-results read algorithm (section 3.2) |
| `rcRankKey` | 24624 | `COURSE_SEM` rank key |
| `stuPublishResults` | 24671 | what admin Publish writes (section 3.1) |
| `_lpSemOk` | 18305 | whole-token semester match |
| `_lpKeyForClass` | 18310 | class matching (section 4.2) |
| `stuLoadOwnLP` | 18324 | own-class lesson plan read (section 4.3) |

Line numbers are for portal v9.96 and move as the file changes — search by function name.

**Nothing on the portal / DB side needs to change for this fix.** If anything about the published data looks different from this file, check it in `student_portal.html` first.
