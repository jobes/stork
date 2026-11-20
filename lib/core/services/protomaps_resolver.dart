import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProtomapsResolver {
  static const fallbackUrl = 'https://build.protomaps.com/20260112.pmtiles';
  static const cacheKey = 'protomaps_archive_url';
  static String _sessionUrl = fallbackUrl;
  static bool _selected = false;

  static String get sessionUrl => _sessionUrl;

  /// Select once; refreshing metadata must never switch an active archive.
  static void useCachedUrl(SharedPreferences prefs) {
    if (_selected) return;
    _selected = true;
    final cached = prefs.getString(cacheKey);
    if (cached != null && _validUrl(cached)) _sessionUrl = cached;
  }

  static bool _validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'build.protomaps.com' &&
        uri.path.endsWith('.pmtiles');
  }

  static Future<void> refreshForNextLaunch(
    SharedPreferences prefs, {
    http.Client? client,
  }) async {
    final ownedClient = client ?? http.Client();
    try {
      final response = await ownedClient
          .get(Uri.parse('https://build-metadata.protomaps.dev/builds.json'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) {
        debugPrint(
          'Protomaps catalog refresh failed: HTTP ${response.statusCode}',
        );
        return;
      }
      final builds = jsonDecode(response.body) as List<dynamic>;
      final urls = [
        for (final build in builds)
          if (build is Map && build['key'] is String)
            'https://build.protomaps.com/${build['key']}',
      ].where(_validUrl).toList()..sort();
      if (urls.isNotEmpty) await prefs.setString(cacheKey, urls.last);
    } catch (error) {
      debugPrint('Protomaps catalog refresh failed: $error');
      // A failed refresh keeps both the selected archive and the stored cache.
    } finally {
      if (client == null) ownedClient.close();
    }
  }
}
