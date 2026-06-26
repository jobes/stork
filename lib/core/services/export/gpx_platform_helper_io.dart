import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class GpxPlatformHelper {
  static Future<XFile?> saveGpx(String gpxString, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(gpxString);
    return XFile(file.path);
  }
}
