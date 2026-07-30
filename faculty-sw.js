// Minimal service worker — exists so the app is installable as a PWA.
// Network-first: always prefer live data (attendance/marks change constantly),
// fall back to cache only when offline.
const CACHE = 'puc-faculty-v1';
const SHELL = ['faculty.html', 'faculty-manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks =>
    Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))
  ));
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  const url = e.request.url;
  // Never cache Firebase/API traffic — it must always be live.
  if (e.request.method !== 'GET' || /firebase|googleapis|cloudinary/.test(url)) return;
  e.respondWith(
    fetch(e.request)
      .then(r => {
        const copy = r.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        return r;
      })
      .catch(() => caches.match(e.request))
  );
});
