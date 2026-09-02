/* 地图标注软件 Service Worker：应用壳离线缓存
 * 策略：首页 network-first（开发期始终拉新）+ 离线回退缓存；
 *       同源静态资源 cache-first 并后台更新；
 *       跨域请求（高德/天地图瓦片等）不拦截，保持在线加载。
 */
var CACHE = 'ditu-shell-v2';
var ASSETS = [
  './',
  './index.html',
  './leaflet.js',
  './leaflet.css',
  './earth_1024.jpg',
  './clouds_1024.jpg',
  './night_lights_1024.jpg',
  './icon.svg',
  './manifest.webmanifest'
];

self.addEventListener('install', function(e){
  e.waitUntil(
    caches.open(CACHE).then(function(c){ return c.addAll(ASSETS).catch(function(){ /* 任一资源不可用也不阻断安装 */ }); })
      .then(function(){ return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function(e){
  e.waitUntil(
    caches.keys().then(function(keys){
      return Promise.all(keys.filter(function(k){ return k !== CACHE; }).map(function(k){ return caches.delete(k); }));
    }).then(function(){ return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(e){
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  if (url.origin !== self.location.origin) return;   // 不拦截跨域（瓦片/高德 API）

  if (req.mode === 'navigate'){
    e.respondWith(
      fetch(req).then(function(r){
        var cp = r.clone();
        caches.open(CACHE).then(function(c){ c.put(req.url, cp); });
        return r;
      }).catch(function(){
        return caches.match(req).then(function(m){ return m || caches.match('./index.html'); });
      })
    );
    return;
  }

  e.respondWith(
    caches.match(req).then(function(m){
      if (m) return m;
      return fetch(req).then(function(r){
        if (r && r.status === 200 && (r.type === 'basic' || r.type === 'cors')){
          var cp = r.clone();
          caches.open(CACHE).then(function(c){ c.put(req.url, cp); });
        }
        return r;
      });
    })
  );
});
