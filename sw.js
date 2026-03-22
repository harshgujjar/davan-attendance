// sw.js — Davan Attendance System
// Place this file at: github.com/harshgujjar/davan-attendance/sw.js

const CACHE_VERSION = 'davan-v3';
const APP_URL = 'https://harshgujjar.github.io/davan-attendance/';

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
  if (e.request.method !== 'GET') return;
  e.respondWith(
    fetch(e.request).then(res => {
      const clone = res.clone();
      caches.open(CACHE_VERSION).then(c => c.put(e.request, clone));
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
