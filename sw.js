// sw.js — Davan Attendance System v4
const CACHE_VERSION = 'davan-v4';
const APP_URL = 'https://harshgujjar.github.io/davan-attendance/';

// URLs to never cache — let them pass through directly
const BYPASS_URLS = [
  'firestore.googleapis.com',
  'firebase.googleapis.com',
  'identitytoolkit.googleapis.com',
  'securetoken.googleapis.com',
  'firebaseinstallations.googleapis.com',
  'firebase.google.com',
  'googleapis.com',
  'ngrok',
  'workers.dev',
  'fcm.googleapis.com',
];

self.addEventListener('install', e => {
  console.log('[SW] Installing:', CACHE_VERSION);
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  console.log('[SW] Activating:', CACHE_VERSION);
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_VERSION).map(k => caches.delete(k)))
    ).then(() => clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Always bypass Firebase, Google APIs, and external services
  if (BYPASS_URLS.some(b => url.includes(b))) return;

  // Only cache GET requests for same-origin assets
  if (e.request.method !== 'GET') return;

  e.respondWith(
    fetch(e.request).then(res => {
      // Only cache successful same-origin responses
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
    icon:    data.icon    || '/davan-attendance/icon-192.png',
    badge:   data.badge   || '/davan-attendance/icon-192.png',
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
