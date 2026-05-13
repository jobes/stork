import 'dart:convert';
import 'package:flutter/services.dart';

import 'protomaps_resolver.dart';

class StyleService {
  static const _stylePath = 'assets/openaip/styles.json';

  static Future<String> loadStyle() async {
    var styleJson = await rootBundle.loadString(_stylePath);
    styleJson = styleJson.replaceAll('asset://', '${Uri.base.origin}/assets/');

    final latestUrl = await ProtomapsResolver.getLatestUrl();
    final proxyUrl =
        'https://www.stork-nav.app/nocors.php?url=${Uri.encodeComponent(latestUrl)}';
    final newUrl = 'pmtiles://$proxyUrl';

    final styleMap = jsonDecode(styleJson) as Map<String, dynamic>;
    final sources = styleMap['sources'] as Map<String, dynamic>?;
    if (sources != null && sources.containsKey('protomaps')) {
      sources['protomaps']['url'] = newUrl;
      styleJson = jsonEncode(styleMap);
    }

    return styleJson;
  }
}
