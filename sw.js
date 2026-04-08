// sw.js — Davan Attendance System v5
const CACHE_VERSION = 'davan-v5';
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
  if (BYPASS_URLS.some(b => url.includes(b))) return;
  if (e.request.method !== 'GET') return;
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
  console.log('[SW] Push received');
  let data = { title: 'Davan College', body: 'You have a notification.' };
  try {
    data = e.data.json();
    console.log('[SW] Push data:', JSON.stringify(data));
  } catch(err) {
    try { data.body = e.data.text(); } catch(e2) {}
  }

  // Build options — keep it simple, no image field (causes silent failure on some Android)
  const options = {
    body:    data.body  || '',
    icon:    data.icon  || ICON_URL,
    badge:   data.badge || ICON_URL,
    vibrate: [200, 100, 200],
    tag:     data.tag   || 'davan-alert',
    data:    { title: data.title, body: data.body, icon: data.icon || '🔔' },
  };

  console.log('[SW] Showing notification:', data.title, '| icon:', options.icon);

  e.waitUntil(
    self.registration.showNotification(data.title || 'Davan College', options)
    .then(() => {
      console.log('[SW] Notification shown OK');
      // Post to all open clients to store in inbox
      return clients.matchAll({ type: 'window' }).then(list => {
        list.forEach(c => c.postMessage({
          type: 'PUSH_RECEIVED',
          title: data.title || 'Davan College',
          body:  data.body  || '',
          icon:  data.icon  || '🔔',
          ts:    Date.now()
        }));
      });
    })
    .catch(err => console.error('[SW] showNotification failed:', err))
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  const data = e.notification.data || {};
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const client of list) {
        if (client.url.includes('davan-attendance') && 'focus' in client) {
          client.postMessage({ type: 'NOTIF_CLICKED', ...data });
          return client.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(APP_URL);
    })
  );
});

self.addEventListener('message', e => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});
