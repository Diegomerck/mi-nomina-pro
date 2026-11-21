import 'dart:convert';
import 'dart:io';

Future<String?> fetchLatestReleaseJson() async {
  HttpClient? client;
  try {
    client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    final request = await client.getUrl(
      Uri.parse(
          'https://api.github.com/repos/Diegomerck/mi-nomina-pro/releases/latest'),
    );
    request.headers.set('User-Agent', 'MiNominaPro-App');
    request.headers.set('Accept', 'application/vnd.github.v3+json');
    final response =
        await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      return responseBody;
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    client?.close();
  }
}
