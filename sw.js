// ═══════════════════════════════════════════
// Rocket Shield VPN — Service Worker
// ═══════════════════════════════════════════
const CACHE_NAME = 'rocket-shield-v2';
const ASSETS = [
  '/',
  '/index.html',
  '/docs.html',
  '/start-here.html',
  '/packet-journey.html',
  '/attack-simulator.html',
  '/config-generator.html',
  '/speed-test.html',
  '/vpn-status.html',
  '/password-generator.html',
  '/dns-explorer.html',
  '/encryption-playground.html',
  '/crypto-quiz.html',
  '/phishing-detector.html',
  '/firewall-builder.html',
  '/vpn-dashboard.html',
  '/icon-512.png',
  '/manifest.json'
];

// Install: cache all assets
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate: clean old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Fetch: cache-first, fallback to network
self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(response => {
        if (response.ok && e.request.method === 'GET') {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        }
        return response;
      }).catch(() => {
        // Offline fallback for HTML pages
        if (e.request.headers.get('accept').includes('text/html')) {
          return caches.match('/index.html');
        }
      });
    })
  );
});
