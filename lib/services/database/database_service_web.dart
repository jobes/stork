import 'dart:typed_data';
import '../../features/offline_maps/domain/offline_maps_state.dart';
import '../../features/offline_maps/domain/tile_utils.dart';

class DatabaseService {
  static Future<void> get database async =>
      throw UnsupportedError('SQLite is not supported on web.');

  static Future<void> resetDatabase() async {
    // No-op on web
  }

  static Future<void> insertRegions(List<OfflineMapArea> regions) async {
    // No-op on web
  }

  static Future<int> insertEmptyTiles(Set<TileCoord> tiles) async {
    // No-op on web
    return 0;
  }

  static Future<Map<String, int>> getTileCounts() async {
    return {'downloaded': 0, 'total': 0, 'size': 0};
  }

  static Future<List<OfflineMapArea>> getRegions() async {
    return [];
  }

  static Future<DateTime?> getLastDownloadDate() async {
    return null;
  }

  static Future<void> updateLastDownloadDate() async {
    // No-op on web
  }

  static Future<List<Map<String, dynamic>>> getEmptyTiles({
    int limit = 100,
  }) async {
    return [];
  }

  static Future<Map<String, dynamic>?> getTile(
    int z,
    int x,
    int y,
    String kind,
  ) async {
    return null;
  }

  static Future<void> updateTilesData(List<Map<String, dynamic>> tiles) async {
    // No-op on web
  }

  static Future<List<Uint8List>> getTilesByKindAndZoom(
    String kind,
    int z,
  ) async {
    return [];
  }

  static Future<void> insertOpenAipFeatures(
    List<Map<String, dynamic>> features,
  ) async {
    // No-op on web
  }

  static Future<int> getMetadataSize() async {
    return 0;
  }

  static Future<void> clearMapData() async {
    // No-op on web
  }
}
