// app-sw.js - the small shared pass-through worker for the Davan apps (2026-09-30).
// Each app registers it for ITS OWN PAGE ONLY, e.g. register('app-sw.js', {scope: './meter.html'}),
// never for the whole /davan-attendance/ folder, so apps can no longer replace each other's worker.
// It caches nothing (every request goes to the network, like before); it exists so Chrome treats each page as installable.
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', function () { /* pass-through: the browser loads it normally */ });
