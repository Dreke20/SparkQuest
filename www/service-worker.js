const CACHE_NAME = 'sparkquest-v2';
const ASSETS = [
  '/',
  '/index.html',
  '/style.css',
  '/main_v2.js',
  '/js/supabase-config.js',
  '/js/db-service.js',
  '/js/ai-service.js',
  '/js/leaflet.js',
  '/style-leaflet.css',
  '/images/marker-icon.png',
  '/images/marker-icon-2x.png',
  '/images/marker-shadow.png',
  '/manifest.json'
];

// Install Event — skip waiting to activate immediately
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS);
    })
  );
});

// Fetch Event — NETWORK FIRST, fall back to cache
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Update cache with fresh response
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, clone);
        });
        return response;
      })
      .catch(() => {
        return caches.match(event.request);
      })
  );
});

// Activate Event (Cleanup old caches + claim all clients)
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(
        keyList.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});
