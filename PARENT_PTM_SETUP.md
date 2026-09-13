# parent_ptm.html — PWA manifest fix

## Why
`parent_ptm.html` had no manifest of its own, so it had no real `scope`.
Tapping a link to it let Android route the tap to whichever installed
WebAPK claims that URL — the admin app, since its scope covers more than
just its own page. This is the same issue every other page in this repo
(`results.html`, `puc.html`, `faculty.html`, `library.html`, `meter.html`,
`Grocery.html`) already had and already fixed, per `README-manifests.md`.
`parent_ptm.html` was simply never added to that fix.

## Files in this delivery
- `manifest-parent_ptm.json` — new manifest, same shape as the others
- `icon-parent_ptm-192.png`
- `icon-parent_ptm-512.png`
- `icon-parent_ptm-maskable-512.png`

## What to do
1. Upload all 4 files above to the repo root
   (`harshgujjar.github.io/davan-attendance/`), alongside `index.html`.

2. In `parent_ptm.html`'s `<head>`, add (same pattern as every other app
   in `README-manifests.md`):

   ```html
   <link rel="manifest" href="manifest-parent_ptm.json">
   <meta name="apple-mobile-web-app-capable" content="yes">
   <meta name="apple-mobile-web-app-title" content="Davan PTM">
   <link rel="apple-touch-icon" sizes="192x192" href="icon-parent_ptm-192.png">
   ```

   If `parent_ptm.html` already has a `<link rel="manifest" ...>` line
   pointing somewhere else (a generic/shared manifest, or none at all),
   replace it with the line above rather than adding a second one.

3. If anyone already has an old "parent_ptm" icon/shortcut installed from
   before this fix, it was never a real separate PWA (no manifest = no
   real install) — it should be removed from the home screen and
   re-added AFTER these files are live, so it picks up the new manifest's
   scope instead of falling back to the admin app.

## Notes
- `scope` in the new manifest is `/davan-attendance/parent_ptm.html` —
  the exact file, not the folder — matching every other manifest in this
  repo. This is what stops the admin app's broader scope from claiming
  this page's links.
- `id` is version-free (`/davan-attendance/parent_ptm`) so future edits
  to `parent_ptm.html` update the same installed app instead of creating
  a duplicate install.
- Icons are built from the real DAVAN Pre-University College seal
  (Spurthi Educational Trust). The maskable version keeps the full seal
  inside Android's circular safe zone with margin to spare — verified
  against a simulated circular crop, nothing gets clipped.
