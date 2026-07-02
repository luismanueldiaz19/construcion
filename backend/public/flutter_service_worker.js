'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "86d560358705aff31c687bd63c858108",
"assets/AssetManifest.bin.json": "0c984a1a9cb7b7fb4b7bbd90f905c03c",
"assets/assets/12560218.png": "20f6259ccaa01693600d32559e50de7f",
"assets/assets/analisis.png": "84d58c2aa1d35859998158f3a6f7ad1f",
"assets/assets/app.png": "312867c732f621cf49b64b4a9cd8248f",
"assets/assets/background.png": "57afe8b34a0602febb8c5ff8732da5e9",
"assets/assets/bottom_logo.png": "10db2e644f1e3809c9f21e9c93f714b1",
"assets/assets/car-wash.gif": "1ff9a27e7ea6cdcd6a0fca79f7d75531",
"assets/assets/delete.png": "8dfc6d67b7128147dff9a2b9ee0df13e",
"assets/assets/distribution.png": "78ef8efa246adb78c10a35750b1a8c3c",
"assets/assets/edificion_contruccion.png": "aa4c13b07f62921e97a9ec37bb17b13d",
"assets/assets/error-message.png": "0a2526a0ec3e717c3e6bab412804f94a",
"assets/assets/existencias.gif": "046f47f71c2478164806ba9995eede4a",
"assets/assets/factura.gif": "345fadd2dcc8a9996718bd70d2da7940",
"assets/assets/facturacion_electronica.png": "0348dfa6653dea60f343a6e3039c2a89",
"assets/assets/fonts/Inter-Black.otf": "e6fef702b507237e0033f4244cc4389c",
"assets/assets/fonts/Inter-BlackItalic.otf": "6b9a465122dcdddf666caa17a1447e67",
"assets/assets/fonts/Inter-Bold.otf": "d759e235e88e47f838062c7ab97308b1",
"assets/assets/fonts/Inter-BoldItalic.otf": "b186ce584f0824196eb2ef3a38e0da38",
"assets/assets/fonts/Inter-ExtraBold.otf": "b799b6950c238082c8e314d127842845",
"assets/assets/fonts/Inter-ExtraBoldItalic.otf": "83ba0d6212dc1fb6107c7749729798f9",
"assets/assets/fonts/Inter-ExtraLight.otf": "97592cd01de5f8e5db834265c3e2a0d4",
"assets/assets/fonts/Inter-ExtraLightItalic.otf": "c76c911e77ac5bb473f419cad8376b6d",
"assets/assets/fonts/Inter-Italic.otf": "0f9f3b37376a39136b2f0c63e287ad0f",
"assets/assets/fonts/Inter-Light.otf": "d7019947105844db1899d246172f06b4",
"assets/assets/fonts/Inter-LightItalic.otf": "4268ddecb3b091fc039efae1719cf1d6",
"assets/assets/fonts/Inter-Medium.otf": "ef3d193e6a6ad033724c7872aec1cff7",
"assets/assets/fonts/Inter-MediumItalic.otf": "3d33faa33190d4a4c271dbaf7a6dfb86",
"assets/assets/fonts/Inter-Regular.otf": "76e872bc911c3d908aeaf31b2c16bc63",
"assets/assets/fonts/Inter-SemiBold.otf": "ef2dede4404ddb4cb3ed69d196ef2722",
"assets/assets/fonts/Inter-SemiBoldItalic.otf": "cc0173dae3b39bd7bbb34674b8d576e1",
"assets/assets/fonts/Inter-Thin.otf": "72869267880104b27bed47fdf7e5c75d",
"assets/assets/fonts/Inter-ThinItalic.otf": "efd29db88022972e4835288ca2c43d32",
"assets/assets/fonts/Inter-V.ttf": "8d63a82f5fc6d6eba21050dd9111520d",
"assets/assets/fonts/SIL%2520Open%2520Font%2520License.txt": "21d30e8ea3e48726a246baca529ddb2a",
"assets/assets/gasoline.png": "2e8be152c15b77ab433fda8ec16903e9",
"assets/assets/icono_cuadrado_estil.png": "70bbc1d6c331f98913a734a1aca6efa8",
"assets/assets/informe.png": "b525fa2411fc14aac24bce74d69e9b7d",
"assets/assets/issue.png": "f9e1299396dba11c200754f611d86d2a",
"assets/assets/layers.png": "40fd9bc3ba8c0c1dbccc56287772ce0f",
"assets/assets/logo.jpeg": "edc7dc6841fe62b18c7599bfd3f8eee5",
"assets/assets/logo.png": "762919d9805a550116c36d8bf8feedf3",
"assets/assets/logo_lu.png": "b0afbf4ae9e42f14eb9a53dd2c2ccffe",
"assets/assets/logo_sin_fondo.png": "b0afbf4ae9e42f14eb9a53dd2c2ccffe",
"assets/assets/mapa_track.jpg": "67504c2063704330574b483b7ef0e3e6",
"assets/assets/no-truck.png": "c195ded0b6036838c7f797993ea66143",
"assets/assets/personalized-support.png": "a820f9de6eec7e25d21f837f7363f4cd",
"assets/assets/plan.png": "3c7b3f1dc38c29b8aae59687d0f90793",
"assets/assets/planificacion.jpeg": "b12608e509c67765344ab27b011d0845",
"assets/assets/sin-datos.png": "dc2ea7b29fae86ba2a9c559e9613b268",
"assets/assets/standby.png": "2a26d79b3c272d9f92cc17800bcef2aa",
"assets/assets/tamano-de-la-pantalla.png": "5be2459cb5ab817217eb34ba014314f1",
"assets/assets/timon.png": "7e34be13c7b4f62c6f16ee7cf00a7f92",
"assets/assets/top_logo.png": "9ddf22df97f70d9201eb3cbd32d27eb5",
"assets/assets/update.png": "c92721ef062c4e97855d264ee9a3c1c5",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "a1d9296e5ff041b19835fd9c5fdd5d41",
"assets/NOTICES": "ac4b6cd70a4750b86dbfda45b2e47ffa",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "7924d3649d97caa3f87665d79819dc77",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "51a4e042c52a4a5e8597576e8a084120",
"icons/Icon-192.png": "1eeb0cf377252e0d324c1e58f288e06e",
"icons/Icon-512.png": "5bda64ece4aca723b36c13afcb5046d4",
"icons/Icon-maskable-192.png": "1eeb0cf377252e0d324c1e58f288e06e",
"icons/Icon-maskable-512.png": "5bda64ece4aca723b36c13afcb5046d4",
"index.html": "9e51b911e3348568e978695147f65a93",
"/": "9e51b911e3348568e978695147f65a93",
"main.dart.js": "b45ace9bf4cbbf2997d4e2baded2d8de",
"manifest.json": "b91980a0628d2b0fef4c1e9de30b349f",
"version.json": "d182cde8616469a4f45c5539b6216641"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
