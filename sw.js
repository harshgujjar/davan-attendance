// sw.js — Davan Attendance System v6
const CACHE_VERSION = 'davan-v6';
const APP_URL = 'https://harshgujjar.github.io/davan-attendance/';
const ICON_URL = 'https://harshgujjar.github.io/davan-attendance/icon-192.png';

const BYPASS_URLS = [
  'firestore.googleapis.com',
  'firebase.googleapis.com',
  'identitytoolkit.googleapis.com',
  'securetoken.googleapis.com',
  'firebaseinstallations.googleapis.com',
  'googleapis.com',
  'ngrok',
  'workers.dev',
  'fcm.googleapis.com',
];

self.addEventListener('install', e => {
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_VERSION).map(k => caches.delete(k)))
    ).then(() => clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = e.request.url;
  if (BYPASS_URLS.some(b => url.includes(b))) return;
  if (e.request.method !== 'GET') return;

  // 2026-09-13 — FIX: tapping a link to a SIBLING page at this same origin
  // (parent_ptm.html, puc.html, results.html, library.html, meter.html,
  // student_portal.html, faculty.html, Grocery.html — separate apps that
  // happen to live in the same /davan-attendance/ folder as this one) was
  // opening inside THIS PWA's own shell instead of a normal browser tab or
  // its own installed app. Root cause: this fetch handler had no concept
  // of "pages this service worker actually owns" — it intercepted every
  // same-origin GET, including navigations to those other pages, and
  // served/cached them exactly as if they were part of this app. Combined
  // with index.html's manifest previously not having a narrow enough
  // scope (separately fixed — index.html now links manifest-admin.json,
  // which has "scope":"/davan-attendance/index.html"), a tapped link to
  // one of those pages could render inside this app's window rather than
  // falling through to a plain page load or its own PWA. FIX: navigation
  // requests (e.request.mode === 'navigate' — set by the browser for a
  // real top-level page load/link tap, never for a CSS/JS/image/XHR
  // sub-resource fetch this app makes for itself) are checked against
  // OWN_PAGES below; anything NOT in that list is NOT intercepted at all
  // (early return, same as the BYPASS_URLS check above) — the browser
  // then handles it as an ordinary navigation with no PWA caching or
  // shell involved, exactly like tapping the link with no service worker
  // installed. Every non-navigation request (the actual JS/CSS/image/
  // font/XHR fetches THIS app's own page makes while running) is
  // completely unaffected — those don't have mode 'navigate' and skip
  // this check entirely, so this app's own caching/offline behavior is
  // unchanged. Sibling pages are free to register their own service
  // workers and PWA behavior independently; this one now stays out of
  // their way. This is the PERMANENT, once-only fix for this bug class —
  // any future new page added to this repo is automatically safe without
  // ever touching this file again, since OWN_PAGES is an allow-list of
  // this app's own two possible paths, not a block-list that would need
  // a new entry per sibling.
  if (e.request.mode === 'navigate') {
    const OWN_PAGES = ['/davan-attendance/', '/davan-attendance/index.html'];
    let path;
    try { path = new URL(url).pathname; } catch (err) { path = ''; }
    if (!OWN_PAGES.includes(path)) return;
  }

  e.respondWith(
    fetch(e.request).then(res => {
      if (res.ok && res.type === 'basic') {
        const clone = res.clone();
        caches.open(CACHE_VERSION).then(c => c.put(e.request, clone));
      }
      return res;
    }).catch(() => caches.match(e.request))
  );
});

self.addEventListener('push', e => {
  let data = { title: 'Davan College', body: 'You have a notification.' };
  try { data = e.data.json(); } catch(err) {
    try { data.body = e.data.text(); } catch(e2) {}
  }
  const options = {
    body:    data.body    || '',
    icon:    data.icon    || ICON_URL,
    badge:   data.badge   || ICON_URL,
    image:   data.image   || undefined,
    vibrate: [200, 100, 200],
    tag:     data.tag     || 'davan-alert',
    data:    data.data    || {},
    actions: data.actions || [],
  };
  e.waitUntil(self.registration.showNotification(data.title || 'Davan College', options));
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const client of list) {
        if (client.url.includes('davan-attendance') && 'focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow(APP_URL);
    })
  );
});

self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});
