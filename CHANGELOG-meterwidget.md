# DavanMeterWidget (Electricity / Water / Chetak home-screen widgets)

`DavanMeterWidget.apk` is the latest build. Its source stays out of git: folder `DavanMeterWidget_w<nn>` with `build.sh` and `meter.jks`. Every update must be signed with that same key. Each build also writes its own `W<nn>_CHANGES.md` in that folder.

- **w14 (4 Oct 2026)**: In a 2-row frame, Water and Chetak no longer leave empty space above and below. Water now uses the Electricity layout: readings, "+1 KL · Est. ~₹255", a cycle bar (KL used plus the 30-day estimate), and avg KL/day. Chetak (idle) shows battery % and ₹/km big in a new top row, with a taller button. Data: none new. Pairs with meter.html v2.10.50. Main code: Widgets.reading / chetakWide / sizes, Graph.water, Store.WaterStats.
- **w13 (4 Oct 2026)**: Water and Chetak fit in one home-screen row (strip card); minimum resize height lowered to 60dp.
- **w12 (4 Oct 2026)**: The coloured card fills the whole widget frame, with the content centred.
