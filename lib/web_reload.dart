// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> reloadApp() async {
  // Unregister all Service Workers
  if (html.window.navigator.serviceWorker != null) {
    try {
      final registrations = await html.window.navigator.serviceWorker!.getRegistrations();
      for (final registration in registrations) {
        await registration.unregister();
      }
    } catch (e) {
      // ignore
    }
  }

  // Clear Web Cache Storage API
  try {
    final caches = html.window.caches;
    if (caches != null) {
      final keys = await caches.keys();
      for (final key in keys) {
        await caches.delete(key);
      }
    }
  } catch (e) {
    // ignore
  }

  // Clear session storage
  try {
    html.window.sessionStorage.clear();
  } catch (e) {
    // ignore
  }

  // Force clean reload with cache-busting timestamp without chaining params
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(html.window.location.href);
    final cleanParams = Map<String, String>.from(uri.queryParameters)..remove('v');
    cleanParams['v'] = '$timestamp';
    final newUri = uri.replace(queryParameters: cleanParams);
    html.window.location.replace(newUri.toString());
  } catch (_) {
    html.window.location.reload();
  }
}
