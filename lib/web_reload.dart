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

  // Force reload with cache-busting timestamp
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final currentUrl = html.window.location.href;
  final separator = currentUrl.contains('?') ? '&' : '?';
  html.window.location.href = '$currentUrl${separator}v=$timestamp';
}
