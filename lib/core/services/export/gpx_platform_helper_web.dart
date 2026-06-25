import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class GpxPlatformHelper {
  static Future<XFile?> saveGpx(String gpxString, String fileName) async {
    return XFile.fromData(
      utf8.encode(gpxString),
      name: fileName,
      mimeType: 'application/gpx+xml',
    );
  }
}
