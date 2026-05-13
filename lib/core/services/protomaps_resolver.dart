import 'dart:convert';
import 'package:http/http.dart' as http;

class ProtomapsResolver {
  static const String fallbackUrl =
      'https://build.protomaps.com/20260112.pmtiles';

  static Future<String> getLatestUrl() async {
    try {
      final response = await http.get(
        Uri.parse('https://build-metadata.protomaps.dev/builds.json'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> builds = jsonDecode(response.body);
        if (builds.isNotEmpty) {
          builds.sort((a, b) {
            final keyA = (a['key'] as String?) ?? '';
            final keyB = (b['key'] as String?) ?? '';
            return keyA.compareTo(keyB);
          });
          final String key = builds.last['key'];
          return 'https://build.protomaps.com/$key';
        }
      }
    } catch (_) {
      // Ignore network errors, stick with default
    }
    return fallbackUrl;
  }
}
