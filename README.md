# 🎓 Davan Attendance System

> Single-file attendance and faculty management web app for **Davan Institute of Advanced Management Studies**, Davangere.

[![Version](https://img.shields.io/badge/version-v255-gold)](#) [![Firebase](https://img.shields.io/badge/backend-Firebase-orange)](#) [![Students](https://img.shields.io/badge/students-578-green)](#)

---

## 📌 Overview

A **single HTML file** web application that runs entirely in the browser. Uses **Firebase Firestore** for real-time data and **Firebase Auth** for role-based access. Manages student attendance, faculty leave, internal exam timetables, and administrative workflows across 3 courses (BCA, BBA, B.Com) and 3 years.

**Live app:** `arshgujjar.github.io/davan-attendance`  
**Companion file:** `results.html` — student results and report cards

---

## ✨ Features

### 📊 Attendance
- Student-wise attendance percentage with visual bar charts
- Class-level attendance grouped by subject
- Absentee tracking with photo upload
- Shortage report — students below 75%
- Subject-wise Class View with faculty name per subject

### 👥 Leave Manager
- Mark faculty leave by date and auto-find substitutes (tiered priority logic)
- WhatsApp-ready substitute assignment message
- Compensation slot tracking — who owes what, when it's due
- Full leave history with search and filters
- Admin history and per-faculty records

### 📝 Internal Timetable
- View, Create/Edit, Duty, and Download tabs
- **8 default time slots per date** (4 morning + 4 afternoon) — admin enters start time, end = start + 1 hour
- **Smart subject dropdowns** — auto-populated from allocation data per batch/year, labs excluded, used subjects hidden
- **Faculty Incharge** — two fulltime faculty per internal, printed in timetable footer
- **Duty allocation** — multiple faculty per exam slot, grouped by date → time slot; same slot = no duplicates
- Export as **PDF** (print window) or **Excel** (XLSX, morning/afternoon sheets)
- Creates next internal as copy of previous (same subjects, blank dates)

### 🗓️ Timetable & Allocation
- Class-wise timetable viewer (by class or faculty)
- Editable timetable and allocation tables
- Faculty allocation viewer with subject codes
- Subject Index tab — full grid of all classes

### 🤖 Smart Assist *(v255)*
Rule-based intelligence — no external API, works offline.

| Tab | What it does |
|-----|-------------|
| 👤 Substitute | Scores all available faculty using 6 rules and ranks best matches |
| 🚨 Alerts | Checks attendance, leave patterns, workload imbalance, duty gaps |
| 🔎 Search | Plain-English queries: "III BCA low attendance", "Anitha leave this week" |

### 📢 Banner System
| Banner | Position | Audience |
|--------|----------|----------|
| Banner 1 | Fixed below topbar (admin broadcast) | All users |
| Banner 2 | Animated holiday ticker above footer | All users |
| Banner 3 | Internal duty reminder | Faculty/Visiting only |

### 🔔 Notifications
- Faculty push notification subscriptions
- Day-before attendance alerts
- Test notification to all subscribed faculty

### ⚙️ Admin
- User management (create, edit, delete accounts)
- Academic calendar with holidays and events
- Login activity log
- Global settings panel

---

## 👤 Roles & Access

| Role | Access |
|------|--------|
| `admin` | Full access — all panels, user management, settings |
| `manager` | All except user management and admin settings |
| `vp` | Vice Principal — analysis, internals, duty |
| `fulltime` | Own timetable, leave, smart assist |
| `visiting` | Own timetable and duty only |

---

## 🗄️ Data Architecture

### Firebase Collections
| Collection | Document | Content |
|-----------|----------|---------|
| `app_data` | `live_banner` | Banner 1 message |
| `app_data` | `live_banner_2` | Banner 2 toggle |
| `app_data` | `internals_meta` | Current internal doc ID |
| `app_data` | `academic_calendar` | Holidays + events |
| `internals` | `{docId}` | `{meta, batches, slots, duties}` |
| `users` | `{uid}` | User profile, role, faculty key |

### localStorage Keys
| Key | Content |
|-----|---------|
| `davan_leave_history` | Leave records + substitution assignments |
| `davan_timetable` | Class timetable data |
| `davan_allocations` | Faculty-subject-class mapping |
| `davan_students` | Scraped student attendance data |
| `davan_comp_log` | Compensation tracking |
| `davan_sec_*` | Sidebar section collapse state |

---

## 🤖 Smart Assist Rules Reference

### Substitute Suggester
Scores each available faculty out of 100 base points:

| Rule | Effect |
|------|--------|
| Teaches same subject as absent faculty | +40 per subject |
| On leave today | Filtered out |
| Already subbing today | −20 per period |
| Visiting faculty (< 3 allocations) | −15 |
| 4+ subs this week | −25 |
| 2–3 subs this week | −10 |

### Alerts Engine
| Alert | Trigger | Level |
|-------|---------|-------|
| Critically low attendance | avg_pct < 75% | 🔴 Red |
| At-risk attendance | 75% ≤ avg_pct < 80% | 🟡 Amber |
| Frequent leave | 3+ leaves this month | 🟡 Amber |
| Sub load imbalance | Max > 2.5× average | 🟡 Amber |
| Internal duty gap | Slot with no duty assigned | 🟡 Amber |
| All clear | No issues | 🟢 Green |

### Quick Search Queries
```
"defaulters"           → Students below 75%
"low attendance"       → Students 75–80%
"III BCA"              → That class's attendance
"Anitha leave"         → Her leave + sub history
"leave this week"      → All faculty leaves this week
"absent today"         → Who's on leave today
"faculty workload"     → Substitution count ranked
```

---

## 🔔 UI System

All browser `alert()` and `confirm()` dialogs (31 total) replaced with three custom components:

```javascript
dvToast(msg, type, duration)    // 'ok' | 'error' | 'warn' | 'info'
dvConfirm(title, msg, callback) // Modal with Cancel + Confirm
dvAlert(title, msg)             // Modal with OK button
```

All Smart Assist actions log to browser console with `[SA]` prefix for debugging.

---

## 🏗️ Internal Timetable — Batch Mapping

Subject dropdowns auto-populated from `LM_ALLOC_DEFAULT`:

| Batch Name | Course | Semester |
|------------|--------|---------|
| I BCA | BCA | Sem II |
| II BCA | BCA | Sem IV |
| III BCA | BCA | Sem VI |
| I BBA | BBA | Sem II |
| II BBA | BBA | Sem IV |
| III BBA | BBA | Sem VI |
| I B.Com | BCom | Sem II |
| II B.Com | BCom | Sem IV |
| III B.Com | BCom | Sem VI |

---

## 📋 Version History (Recent)

| Version | Date | Key Change |
|---------|------|-----------|
| v255 | 20 Mar 2026 | Smart Assist: substitute suggester, alerts, quick search |
| v254 | 20 Mar 2026 | Fix subject pre-fill: build grid immediately after form render |
| v249 | 20 Mar 2026 | Fix batch→sem map: use Roman numerals (II/IV/VI) |
| v247 | 20 Mar 2026 | Fix all missing confirmations and toasts across app |
| v246 | 20 Mar 2026 | Universal toast/confirm/alert system (31 replacements) |
| v245 | 20 Mar 2026 | Fix Firebase reserved ID `__default__` → `int_default_1` |
| v244 | 20 Mar 2026 | Duty: serial numbers, slot-level faculty deduplication |
| v243 | 20 Mar 2026 | Internals View: dark theme, colour-coded batch columns |
| v242 | 20 Mar 2026 | Per-date time slots, subject dropdowns, 2nd internal copies from 1st |
| v241 | 20 Mar 2026 | Faculty Incharge footer; edit tab auto-loads current internal |
| v240 | 20 Mar 2026 | Duty grouped by date+slot; Faculty Incharge 2 dropdowns |
| v238–239 | 20 Mar 2026 | Full Internals module + Apr 2026 default timetable |
| v236–237 | 20 Mar 2026 | Sidebar collapsible sections + compact styling |
| v229–235 | 19–20 Mar 2026 | Banner system: 3 banners, positioning, mobile fixes |
| v222 | 18 Mar 2026 | Stable base — all attendance and leave features complete |

---

## 📁 Files

```
index.html          Main app (~15,900 lines, v255)
results.html        Student results and report cards (r398)
davan_logo_2026.gif College logo (28×28px)
davan_degree1.png   Degree college logo (used in internal timetable)
```

---

## 🛠️ Setup

1. Clone the repo
2. Open `index.html` in a browser — no build step required
3. Firebase config is embedded — connects automatically
4. Login with admin credentials to access all features

---

## 🏫 About

**Davan Institute of Advanced Management Studies**  
Davan-Nutana Alliance · LIC Colony, BIET Road, Davangere  
Director: Harsha A Gujjar · Session: 05.02.2026 – 24.05.2026 · Students: 578

*Built and maintained for internal use by Davan College.*
