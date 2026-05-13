import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:maplibre/maplibre.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:pmtiles/pmtiles.dart';

import '../../features/offline_maps/domain/offline_maps_state.dart';
import '../../features/offline_maps/domain/tile_utils.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<String> get _dbPath async {
    final docs = await getApplicationSupportDirectory();
    return p.join(docs.path, 'offline_maps.db');
  }

  static Future<Database> _initDatabase() async {
    final path = await _dbPath;
    final db = sqlite3.open(path);
    _setupTables(db);
    return db;
  }

  static Future<void> resetDatabase() async {
    if (_db != null) {
      _db!.close();
      _db = null;
    }
    final path = await _dbPath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await database;
  }

  static void _setupTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS offline_regions (
          id TEXT PRIMARY KEY,
          downloaded_at DATETIME,
          min_lat REAL NOT NULL,
          min_lon REAL NOT NULL,
          max_lat REAL NOT NULL,
          max_lon REAL NOT NULL
      );
      
      CREATE TABLE IF NOT EXISTS map_tiles (
          z INTEGER NOT NULL,
          x INTEGER NOT NULL,
          y INTEGER NOT NULL,
          kind TEXT NOT NULL,
          tile_id INTEGER,
          tile_type TEXT NOT NULL,
          tile_data BLOB NOT NULL,
          PRIMARY KEY (z, x, y, kind)
      );

      CREATE TABLE IF NOT EXISTS openaip_features (
          id TEXT PRIMARY KEY,
          json TEXT NOT NULL,
          country TEXT NOT NULL,
          type TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_tiles_zxyk ON map_tiles (z, x, y, kind);
      CREATE INDEX IF NOT EXISTS idx_tiles_kind_id ON map_tiles (kind, tile_id);
      CREATE INDEX IF NOT EXISTS idx_openaip_country_type ON openaip_features (country, type);
    ''');
  }

  static Future<void> insertRegions(List<OfflineMapArea> regions) async {
    final db = await database;
    final stmt = db.prepare('''
      INSERT INTO offline_regions (id, min_lat, min_lon, max_lat, max_lon)
      VALUES (?, ?, ?, ?, ?)
    ''');

    for (final region in regions) {
      stmt.execute([
        region.id,
        min(region.northwest.lat, region.southeast.lat),
        min(region.northwest.lon, region.southeast.lon),
        max(region.northwest.lat, region.southeast.lat),
        max(region.northwest.lon, region.southeast.lon),
      ]);
    }
    stmt.close();
  }

  static Future<int> insertEmptyTiles(Set<TileCoord> tiles) async {
    final db = await database;
    db.execute('BEGIN TRANSACTION');
    try {
      final stmt = db.prepare('''
        INSERT OR IGNORE INTO map_tiles (z, x, y, kind, tile_id, tile_type, tile_data)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''');

      for (final tile in tiles) {
        stmt.execute([
          tile.z,
          tile.x,
          tile.y,
          tile.kind,
          ZXY(tile.z, tile.x, tile.y).toTileId(),
          '',
          Uint8List(0),
        ]);
      }
      stmt.close();
      db.execute('COMMIT');
      return tiles.length;
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Future<Map<String, int>> getTileCounts() async {
    final db = await database;

    final counts = <String, int>{
      'total': _querySingleInt(db, 'SELECT COUNT(*) FROM map_tiles'),
      'downloaded': _querySingleInt(
        db,
        'SELECT COUNT(*) FROM map_tiles WHERE length(tile_data) > 0',
      ),
      'size': _querySingleInt(
        db,
        'SELECT SUM(length(tile_data)) FROM map_tiles',
      ),
    };

    final kindResults = db.select(
      'SELECT kind, SUM(length(tile_data)) as size FROM map_tiles GROUP BY kind',
    );
    for (final row in kindResults) {
      final kind = row['kind'] as String;
      final size = (row['size'] as num? ?? 0).toInt();
      if (kind == 'protomaps') counts['worldSize'] = size;
      if (kind == 'openaip') counts['openAipSize'] = size;
      if (kind == 'terrain') counts['terrainSize'] = size;
    }

    return counts;
  }

  static int _querySingleInt(Database db, String sql) {
    final result = db.select(sql);
    if (result.isEmpty) return 0;
    return (result.first.values.first as num? ?? 0).toInt();
  }

  static Future<List<OfflineMapArea>> getRegions() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = db.select(
      'SELECT id, min_lat, min_lon, max_lat, max_lon FROM offline_regions',
    );

    return results.map((row) {
      return OfflineMapArea(
        id: row['id'] as String,
        northwest: Geographic(
          lon: row['min_lon'] as double,
          lat: row['max_lat'] as double,
        ),
        southeast: Geographic(
          lon: row['max_lon'] as double,
          lat: row['min_lat'] as double,
        ),
      );
    }).toList();
  }

  static Future<DateTime?> getLastDownloadDate() async {
    if (kIsWeb) return null;
    final db = await database;
    final result = db.select(
      'SELECT MAX(downloaded_at) as last_date FROM offline_regions',
    );
    final dateStr = result.isEmpty
        ? null
        : result.first['last_date'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  static Future<void> updateLastDownloadDate() async {
    if (kIsWeb) return;
    final db = await database;
    db.execute('UPDATE offline_regions SET downloaded_at = CURRENT_TIMESTAMP');
  }

  static Future<List<Map<String, dynamic>>> getEmptyTiles({
    int limit = 100,
  }) async {
    final db = await database;
    return db.select(
      'SELECT z, x, y, kind FROM map_tiles WHERE length(tile_data) = 0 ORDER BY kind, tile_id LIMIT ?',
      [limit],
    ).toList();
  }

  static Future<void> updateTilesData(List<Map<String, dynamic>> tiles) async {
    final db = await database;
    db.execute('BEGIN TRANSACTION');
    try {
      final stmt = db.prepare('''
        UPDATE map_tiles SET tile_data = ?, tile_type = ? 
        WHERE z = ? AND x = ? AND y = ? AND kind = ?
      ''');
      for (final tile in tiles) {
        stmt.execute([
          tile['data'],
          tile['type'],
          tile['z'],
          tile['x'],
          tile['y'],
          tile['kind'],
        ]);
      }
      stmt.close();
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getTile(
    int z,
    int x,
    int y,
    String kind,
  ) async {
    if (kIsWeb) return null;
    final db = await database;
    final result = db.select(
      'SELECT tile_data, tile_type FROM map_tiles WHERE z = ? AND x = ? AND y = ? AND kind = ?',
      [z, x, y, kind],
    );
    if (result.isEmpty) return null;
    final data = result.first['tile_data'] as Uint8List;
    return data.isEmpty
        ? null
        : {'data': data, 'type': result.first['tile_type'] as String};
  }

  static Future<List<Uint8List>> getTilesByKindAndZoom(
    String kind,
    int z,
  ) async {
    if (kIsWeb) return [];
    final db = await database;
    final results = db.select(
      'SELECT tile_data FROM map_tiles WHERE kind = ? AND z = ? AND length(tile_data) > 0',
      [kind, z],
    );
    return results.map((row) => row['tile_data'] as Uint8List).toList();
  }

  static Future<void> insertOpenAipFeatures(
    List<Map<String, dynamic>> features,
  ) async {
    final db = await database;
    db.execute('BEGIN TRANSACTION');
    try {
      final stmt = db.prepare(
        'INSERT OR REPLACE INTO openaip_features (id, json, country, type) VALUES (?, ?, ?, ?)',
      );
      for (final feature in features) {
        stmt.execute([
          feature['id'],
          feature['json'],
          feature['country'],
          feature['type'],
        ]);
      }
      stmt.close();
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Future<int> getMetadataSize() async {
    if (kIsWeb) return 0;
    final db = await database;
    return _querySingleInt(
      db,
      'SELECT SUM(length(json)) FROM openaip_features',
    );
  }

  static Future<void> clearMapData() async {
    final db = await database;
    db.execute('DELETE FROM map_tiles');
    db.execute('DELETE FROM openaip_features');
    db.execute('UPDATE offline_regions SET downloaded_at = NULL');
  }
}
