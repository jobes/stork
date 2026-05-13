import 'package:flutter/services.dart';

class MapAssetsServer {
  static late AssetBundle bundle;
  static String get baseUrl => throw UnsupportedError(
    'MapAssetsServer is not available on this platform',
  );

  static Future<void> start() async {
    // No-op on platforms without dart:io (e.g. web).
  }

  static Future<void> stop() async {
    // No-op on platforms without dart:io (e.g. web).
  }

  static Map<String, String> get pmtilesUrls => {};

  static Future<dynamic> getArchive(String id) async {
    throw UnsupportedError('PMTiles is not available on this platform');
  }
}
