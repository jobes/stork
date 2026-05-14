import 'dart:convert';
import 'package:flutter/services.dart';
import 'map_assets_server.dart';

class StyleService {
  static const _stylePath = 'assets/openaip/styles.json';

  static Future<String> loadStyle({double fontSize = 1.0}) async {
    var styleStr = await rootBundle.loadString(_stylePath);
    styleStr = styleStr.replaceAll('asset://', '${MapAssetsServer.baseUrl}/');

    final styleMap = jsonDecode(styleStr) as Map<String, dynamic>;
    final sources = styleMap['sources'] as Map<String, dynamic>?;

    if (sources != null) {
      if (sources.containsKey('openaip-data')) {
        sources['openaip-data'].remove('url');
        sources['openaip-data']['tiles'] = [
          '${MapAssetsServer.baseUrl}/pmtiles/openaip/{z}/{x}/{y}.pbf',
        ];
      }
      if (sources.containsKey('protomaps')) {
        sources['protomaps'].remove('url');
        sources['protomaps']['tiles'] = [
          '${MapAssetsServer.baseUrl}/pmtiles/protomaps/{z}/{x}/{y}.pbf',
        ];
      }
      if (sources.containsKey('terrain')) {
        sources['terrain'].remove('url');
        sources['terrain']['tiles'] = [
          '${MapAssetsServer.baseUrl}/pmtiles/terrain/{z}/{x}/{y}.png',
        ];
      }
    }

    return jsonEncode(styleMap);
  }
}
