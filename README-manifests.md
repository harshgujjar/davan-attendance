# Per-app PWA manifests — davan-attendance

Six new manifests + matching icons, following the same shape as your existing
`manifest-admin.json` / `manifest-student_portal.json`.

Drop all files into the repo root (`harshgujjar.github.io/davan-attendance/`).

| App | Manifest | id | short_name | Icon |
|---|---|---|---|---|
| results.html | `manifest-results.json` | `/davan-attendance/results` | Davan Results | gold **R** |
| puc.html | `manifest-puc.json` | `/davan-attendance/puc` | Davan PUC | orange **P** |
| faculty.html | `manifest-faculty.json` | `/davan-attendance/faculty` | PUC Faculty | cyan **F** |
| library.html | `manifest-library.json` | `/davan-attendance/library` | Davan Library | violet **L** |
| meter.html | `manifest-meter.json` | `/davan-attendance/meter` | Meter | blue **M** |
| Grocery.html | `manifest-grocery.json` | `/davan-attendance/grocery` | Grocery | green **G** |

Every app gets a distinct `id`, `start_url` and `scope`, so each installs as its
own home-screen entry instead of overwriting a sibling.

---

## Head tags to add

**results.html** — no manifest link today, add after the existing
`apple-touch-icon` line:

```html
<link rel="manifest" href="manifest-results.json">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Davan Results">
<link rel="apple-touch-icon" sizes="192x192" href="icon-results-192.png">
```

**puc.html** — currently builds the manifest + apple-touch-icon at runtime
(canvas → PNG, around line 4046). Add the static link and you can delete that
block:

```html
<link rel="manifest" href="manifest-puc.json">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Davan PUC">
<link rel="apple-touch-icon" sizes="192x192" href="icon-puc-192.png">
```

**faculty.html** — line 9 points at `faculty-manifest.json`. Either rename the
new file to that, or change the link:

```html
<link rel="manifest" href="manifest-faculty.json">
<link rel="apple-touch-icon" sizes="192x192" href="icon-faculty-192.png">
```

**library.html** — line 18 is a `data:application/manifest+json,...` URI.
Replace it (and the base64 `apple-touch-icon` on line 11) with:

```html
<link rel="manifest" href="manifest-library.json">
<link rel="apple-touch-icon" sizes="192x192" href="icon-library-192.png">
```

**meter.html** — line 9 is `<link rel="manifest" href="#" id="manifestLink">`
and line ~11007 assigns a blob URL to it. Replace the link and delete that JS
line:

```html
<link rel="manifest" href="manifest-meter.json">
<link rel="apple-touch-icon" sizes="192x192" href="icon-meter-192.png">
```

**Grocery.html** — line 209 is a data-URI manifest. Replace it (and the base64
`apple-touch-icon` on line 210) with:

```html
<link rel="manifest" href="manifest-grocery.json">
<link rel="apple-touch-icon" sizes="192x192" href="icon-grocery-192.png">
```

---

## Notes

- **`start_url` uses the plain filename.** If a file is deployed versioned —
  `puc_v5.2xx.html`, `library_v1.32.html` — point `start_url` and `scope` at the
  real deployed name, or (better) keep a stable `puc.html` / `library.html` that
  redirects to the current version, so an installed PWA doesn't break on every
  release. `id` is deliberately version-free so re-releases update the same
  installed app instead of creating a duplicate.
- **`scope` is the file path, not a directory** — same as your existing two
  manifests. This is what keeps the apps from swallowing each other's URLs on a
  single-repo GitHub Pages host.
- Data-URI manifests (Grocery, library) install fine on Chrome Android but are
  unreliable on iOS and can't be updated without editing the HTML — worth moving
  to the static files.
- Theme colours are taken from each app's existing `<meta name="theme-color">`
  so the status bar doesn't shift after install. `results` keeps the gold
  `#c4a02a` you already use in `manifest-admin.json`; background is its real
  page background `#0b0d11`.
- Icons are 192/512 plus a separate maskable 512 with the glyph inside the
  Android safe zone, so it won't get clipped into a circle.
