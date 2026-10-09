# 🎓 Davan Attendance System

> Open-source campus management system for **Davan Institute of Advanced Management Studies**, Davangere (India) —
> attendance, results, timetables, notifications and home-screen widgets for students, faculty, office and hostel staff.

[![License: GPL v3](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE) [![Staff app](https://img.shields.io/badge/staff%20app-v1818-gold)](CHANGELOG-admin.md) [![Student portal](https://img.shields.io/badge/student%20portal-v11.54-gold)](CHANGELOG-portal.md) [![Backend](https://img.shields.io/badge/backend-Firebase-orange)](#-architecture) [![Students](https://img.shields.io/badge/students-578-green)](#)

In daily use by about **578 students** and all teaching, office and hostel staff of the college (BCA, BBA, B.Com and PUC).
It runs on free-tier infrastructure: GitHub Pages, Firebase, GitHub Actions and a Cloudflare Worker.

---

## 📱 Apps

Every app is an installable web app (PWA) with its own manifest and service worker.

| App | File | Who uses it |
|---|---|---|
| **Staff app** | [`index.html`](https://harshgujjar.github.io/davan-attendance/index.html) (built from `src/index.src.html`) | Principal, admins, managers, faculty, office and hostel staff |
| **Student portal** | [`student_portal.html`](https://harshgujjar.github.io/davan-attendance/student_portal.html) | Students |
| Results | `results.html` | Results and report cards |
| PUC dashboard / PUC faculty | `puc.html`, `faculty.html` | PUC (pre-university) classes |
| Parent progress card | `parent_ptm.html` | Parent-teacher meetings |
| Library | `library.html` | Library staff |
| Hostel | `Grocery.html`, `cleaning.html`, `meter.html` | Hostel grocery, cleaning, electricity meters |
| **Davan Student** widget | `Davan.Student.apk` | Android home-screen widget for students |
| **Davan Staff** widget | `DavanWidget.apk` | Android home-screen widget for faculty, admin and hostel staff |

## ✨ Main features

- **Attendance** — student-, subject- and class-wise attendance, day-wise attendance, shortage reports (below 75%), absentee tracking.
- **Student portal** — own attendance, results, timetable, college calendar and events, lesson plans, alerts.
- **Faculty & leave** — leave with ranked substitute suggestions, compensation tracking, allocations, class and faculty timetables.
- **Internal exams** — internal timetables, duty allocation, PDF / Excel export.
- **Notifications** — one registry of push alerts (class reminders, day wrap-up, admin alerts), within 7 am – 9 pm and outside class periods.
- **Widgets** — Today page with a live countdown to the next class, lock-screen card, results, spoken alerts; they update themselves.
- **Admin** — user and role management, academic calendar, global switches, device and usage reports, data scraper monitor.

## 🏗️ Architecture

```
src/index.src.html ──(tools/build_index.js)──> index.html + js/admin-<n>-<hash>.js
student_portal.html, results.html, ...         plain HTML apps, no build step
Firebase (Firestore / Realtime Database)       data, auth, roles
GitHub Pages                                   hosting for all apps and APKs
GitHub Actions + Cloudflare Worker             nightly widget release (release-widgets.yml,
                                               tools/cloudflare-release-worker.js)
```

**Widget release channels:** a new widget build goes to the `-next` files first (`Davan.Student-next.apk`, `DavanWidget-next.apk`
and their json). Every night the release workflow copies it to the public APK and version json, and the widgets update
themselves. The Super Admin can stop or force a release from the staff app.

## 🛠️ Development

```bash
# staff app: edit src/index.src.html, never index.html or js/admin-*.js
cd tools && npm install && cd ..
node tools/build_index.js     # writes index.html + js/admin-*.js
```

Other apps are single HTML files — edit and open them in a browser. Working rules for contributors (versions, changelogs,
release channels) are in [`CLAUDE.md`](CLAUDE.md); the current state of work is in [`HANDOFF.md`](HANDOFF.md).

**Changelogs:** [`CHANGELOG-admin.md`](CHANGELOG-admin.md) (staff app) · [`CHANGELOG-portal.md`](CHANGELOG-portal.md) (student portal).

> Note: the Android widget sources and the college data scraper are kept in a separate private repository;
> this repository holds the web apps, build tools, release workflows and the published APKs.

## 👤 Roles

| Role | Access |
|---|---|
| `admin` | Everything, incl. user management and global switches |
| `manager` | All except user management and admin settings |
| `vp` | Vice Principal — analysis, internals, duty |
| `fulltime` | Own timetable, leave, attendance, alerts |
| `visiting` | Own timetable and duty |
| Office / hostel staff | Their own pages (library, hostel, office tools) |

## 📄 License

[GNU GPL v3](LICENSE). Other colleges are welcome to reuse and adapt it.

## 🏫 About

**Davan Institute of Advanced Management Studies** · Davan-Nutana Alliance · LIC Colony, BIET Road, Davangere

Built and maintained by **Harsharaj A Gujjar** ([@harshgujjar](https://github.com/harshgujjar)).
