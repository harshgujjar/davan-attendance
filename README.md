# DAVAN Attendance System

> Attendance analysis and leave management system for Davan Institute of Advanced Management Studies.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## Features

- **Live attendance data** — synced from davandvg.com portal via scheduled scrape (5:30 PM daily)
- **Role-based login** — Admin, Manager, Vice Principal, Full-Time Faculty, Visiting Faculty
- **Shortage Report** — per-student, per-subject attendance shortage analysis
- **Shortage Summary** — consolidated one-row-per-student view with expandable subject pills
- **Leave Manager** — mark leave, assign substitutes, track compensation
- **Timetable Viewer** — morning/afternoon side-by-side view with workload summary
- **Subject Exemptions** — exclude subjects like Placement Training from analysis
- **Login Activity Log** — admin can see who logged in, when, and from what device
- **Firebase backend** — all data stored in Firestore, accessible from anywhere

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | HTML / CSS / JS (single file) |
| Auth | Firebase Authentication |
| Database | Firebase Firestore |
| Hosting | GitHub Pages |
| Scraper | Python (`app.py`) — runs locally |
| Charts | Chart.js |
| Excel | SheetJS (xlsx) |

---

## Setup

### 1. Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Open project `davan-attendance-2026`
3. Enable **Authentication → Email/Password**
4. Enable **Firestore Database**
5. Set Firestore rules (see below)

### 2. Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can read their own profile
    match /users/{uid} {
      allow read: if request.auth.uid == uid;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // App data (students, timetable, allocations) — any logged-in user can read
    match /app_data/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin','manager','vp'];
    }

    // Leave history — authenticated users only
    match /leave_history/{doc} {
      allow read, write: if request.auth != null;
    }

    // Comp log — authenticated users only
    match /comp_log/{doc} {
      allow read, write: if request.auth != null;
    }

    // Login activity — admin/manager read, any auth write (for logging)
    match /login_activity/{doc} {
      allow read: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin','manager'];
      allow write: if request.auth != null;
    }
  }
}
```

### 3. GitHub Pages

1. Push this repo to `github.com/harshgujjar/davan-attendance`
2. Go to **Settings → Pages → Source → main branch → / (root)**
3. Your app will be live at `https://harshgujjar.github.io/davan-attendance`
4. Add this URL to Firebase Console → Authentication → Authorised Domains

### 4. First Login

- **Username:** `admin`
- **Password:** `1234`
- ⚠️ Change the admin password immediately after first login via User Management

### 5. Scheduled Scrape (app.py)

The scraper runs locally on your machine and pushes data to Firestore at 5:30 PM daily.

**Windows Task Scheduler:**
```
Action: python C:\path\to\app.py --scrape
Trigger: Daily at 17:30
```

**Mac/Linux cron:**
```
30 17 * * * cd /path/to/project && python app.py --scrape
```

Your laptop must be on at 5:30 PM for the scheduled scrape to run.
Manual scrape: click **Scrape Now** in Admin panel (requires localhost:5000 running).

---

## Roles

| Role | Scrape | Edit TT | All Student Data | Own Shortage | Leave/Comp | User Mgmt |
|---|---|---|---|---|---|---|
| Admin | ✅ | ✅ | ✅ | ✅ | All | ✅ |
| Manager | ❌ | ✅ | ✅ | ✅ | All | ❌ |
| Vice Principal | ❌ | ✅ | ✅ | ✅ | All (read) | ❌ |
| Full-Time | ❌ | ❌ | ✅ read | ✅ | Own | ❌ |
| Visiting | ❌ | ❌ | ❌ | ✅ own subjects | Own | ❌ |

---

## Version History

See hidden comment block in `index.html` for full changelog.

Current version: **v089** — 11 Mar 2026

---

## License

Copyright © 2026 Davan Institute of Advanced Management Studies.
Licensed under the [GNU General Public License v3.0](LICENSE).
