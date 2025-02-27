self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open('vite').then(function(cache) {
      return cache.addAll([
        '/',
        '/index.html',
        '/manifest.json',
        '/service-worker.js',
        // Add more files as needed
      ]);
    })
  );
});

self.addEventListener('fetch', function(event) {
  const apiURL = 'https://api.auroville.social';
  
  // Check if this is an API request
  if (event.request.url.includes('/api/')) {
    // Don't cache API requests, always fetch from network
    event.respondWith(fetch(event.request));
    return;
  }
  
  // For non-API requests, try the cache first, then network
  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response || fetch(event.request);
    })
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(self.registration.unregister());
});
