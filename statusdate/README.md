# Status Date - update channel

Personal side app (day / date / month on the status bar). The installed app reads `statusdate-version.json` twice a day and installs
`StatusDate.apk` when `apkVersion` is newer. To release a new version: copy the new APK here as StatusDate.apk and raise `apkVersion`
AND the `?v=` in `apkUrl` (GitHub caches the old file otherwise). Source: private davan-scraper `apps/statusdate`.
