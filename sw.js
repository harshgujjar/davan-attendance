// sw.js — Save this file as sw.js in your GitHub repo root
// Must be accessible at: https://harshgujjar.github.io/davan-attendance/sw.js

const CACHE_NAME = 'davan-v1';

self.addEventListener('install', e => {
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(clients.claim());
});

self.addEventListener('push', e => {
  let data = { title: 'Davan College', body: 'You have a notification.' };
  try { data = e.data.json(); } catch(err) {
    try { data.body = e.data.text(); } catch(e2) {}
  }

  const options = {
    body:    data.body    || '',
    icon:    data.icon    || '/davan-attendance/davan_degree1.png',
    badge:   data.badge   || '/davan-attendance/davan_degree1.png',
    vibrate: [200, 100, 200],
    tag:     data.tag     || 'davan-alert',
    data:    data.data    || {},
    actions: data.actions || [],
  };

  e.waitUntil(
    self.registration.showNotification(data.title || 'Davan College', options)
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const client of list) {
        if (client.url.includes('harshgujjar.github.io') && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});
