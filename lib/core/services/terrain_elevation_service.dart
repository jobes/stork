import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmtiles/pmtiles.dart';
import '../../services/database/database_service.dart';
import 'map_assets_server.dart';

part 'terrain_elevation_service.g.dart';

/// Represents a specific pixel coordinate within a zoom level 12 terrain tile.
class TerrainPixel {
  final int tileX;
  final int tileY;
  final int pixelX;
  final int pixelY;

  const TerrainPixel({
    required this.tileX,
    required this.tileY,
    required this.pixelX,
    required this.pixelY,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerrainPixel &&
          runtimeType == other.runtimeType &&
          tileX == other.tileX &&
          tileY == other.tileY &&
          pixelX == other.pixelX &&
          pixelY == other.pixelY;

  @override
  int get hashCode => Object.hash(tileX, tileY, pixelX, pixelY);

  @override
  String toString() =>
      'TerrainPixel(tileX: $tileX, tileY: $tileY, pixelX: $pixelX, pixelY: $pixelY)';
}

/// Represents a specific fractional pixel coordinate within a zoom level 12 terrain tile.
class TerrainFractionalPixel {
  final int tileX;
  final int tileY;
  final double pixelX;
  final double pixelY;

  const TerrainFractionalPixel({
    required this.tileX,
    required this.tileY,
    required this.pixelX,
    required this.pixelY,
  });

  /// Converts this fractional coordinate to an integer pixel coordinate on a 256x256 grid.
  TerrainPixel toTerrainPixel() {
    return TerrainPixel(
      tileX: tileX,
      tileY: tileY,
      pixelX: pixelX.floor().clamp(0, 255),
      pixelY: pixelY.floor().clamp(0, 255),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerrainFractionalPixel &&
          runtimeType == other.runtimeType &&
          tileX == other.tileX &&
          tileY == other.tileY &&
          pixelX == other.pixelX &&
          pixelY == other.pixelY;

  @override
  int get hashCode => Object.hash(tileX, tileY, pixelX, pixelY);

  @override
  String toString() =>
      'TerrainFractionalPixel(tileX: $tileX, tileY: $tileY, pixelX: $pixelX, pixelY: $pixelY)';
}

/// Represents a cached terrain tile.
class TerrainTile {
  final ByteData byteData;
  final int sideSize;

  const TerrainTile({required this.byteData, required this.sideSize});
}

/// A lightweight Least-Recently-Used (LRU) cache for terrain tile byte data.
class TileCache {
  final int maxEntries;
  final LinkedHashMap<(int, int), TerrainTile?> _cache =
      LinkedHashMap<(int, int), TerrainTile?>();

  TileCache(this.maxEntries);

  /// Checks if a tile is currently cached (either successfully or as a failure).
  bool contains(int tileX, int tileY) {
    return _cache.containsKey((tileX, tileY));
  }

  /// Checks if a tile is currently cached and returns a record containing:
  /// - `bool isCached`: whether the tile was found in the cache
  /// - `TerrainTile? data`: the cached tile (can be null for cached failures)
  /// Updates the LRU position if the entry exists.
  (bool isCached, TerrainTile? data) getEntry(int tileX, int tileY) {
    final key = (tileX, tileY);
    if (!_cache.containsKey(key)) return (false, null);
    final value = _cache.remove(key);
    _cache[key] = value; // Move to end (most recently used)
    return (true, value);
  }

  TerrainTile? get(int tileX, int tileY) {
    final key = (tileX, tileY);
    if (!_cache.containsKey(key)) return null;
    final value = _cache.remove(key);
    _cache[key] = value; // Move to end (most recently used)
    return value;
  }

  void put(int tileX, int tileY, TerrainTile? data) {
    final key = (tileX, tileY);
    _cache.remove(key);
    if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first); // Evict oldest (least recently used)
    }
    _cache[key] = data;
  }

  void clear() {
    _cache.clear();
  }
}

@Riverpod(keepAlive: true)
TerrainElevationService terrainElevationService(Ref ref) {
  return TerrainElevationService();
}

class TerrainElevationService {
  static const int zoomLevel = 12;
  static const int _numTiles = 1 << zoomLevel; // 4096
  static const double _degToRad = pi / 180;

  final TileCache _cache = TileCache(4);
  final Map<(int, int), Future<TerrainTile?>> _pendingFetches = {};

  /// Clears the in-memory tile cache.
  void clearCache() {
    _cache.clear();
  }

  /// Sets a mock cache for testing purposes.
  @visibleForTesting
  void setMockCache(int tileX, int tileY, ByteData byteData) {
    final int totalPixels = byteData.lengthInBytes ~/ 4;
    final int sideSize = totalPixels == 0 ? 0 : sqrt(totalPixels).round();
    _cache.put(
      tileX,
      tileY,
      TerrainTile(byteData: byteData, sideSize: sideSize),
    );
  }

  /// Translates a given latitude and longitude to its corresponding
  /// Web Mercator zoom level 12 tile and fractional pixel coordinate.
  static TerrainFractionalPixel getFractionalPixelCoordinate(
    double lat,
    double lon,
  ) {
    // Longitude to x coordinate
    final double xDecimal = ((lon + 180) / 360) * _numTiles;
    final int tileX = xDecimal.floor();

    // Latitude to y coordinate (Web Mercator projection)
    final double latRad = lat.clamp(-85.0511, 85.0511) * _degToRad;
    final double yDecimal =
        (1.0 - (log((sin(latRad) + 1.0) / cos(latRad)) / pi)) / 2.0 * _numTiles;
    final int tileY = yDecimal.floor();

    // Fractional pixel coordinates within the 256x256 tile
    final double pixelX = ((xDecimal - tileX) * 256).clamp(0.0, 255.9999);
    final double pixelY = ((yDecimal - tileY) * 256).clamp(0.0, 255.9999);

    return TerrainFractionalPixel(
      tileX: tileX,
      tileY: tileY,
      pixelX: pixelX,
      pixelY: pixelY,
    );
  }

  /// Translates a given latitude and longitude to its corresponding
  /// Web Mercator zoom level 12 tile and pixel coordinate.
  static TerrainPixel getPixelCoordinate(double lat, double lon) {
    return getFractionalPixelCoordinate(lat, lon).toTerrainPixel();
  }

  /// Returns the cached elevation for [lat] and [lon] synchronously if the tile is cached.
  /// Returns `null` if the tile is not cached or if fetching it previously failed.
  double? getCachedElevation(double lat, double lon) {
    final fractionalCoord = getFractionalPixelCoordinate(lat, lon);
    final (isCached, tile) = _cache.getEntry(
      fractionalCoord.tileX,
      fractionalCoord.tileY,
    );
    if (!isCached || tile == null) {
      return null;
    }
    return _decodeElevation(
      tile,
      fractionalCoord.pixelX,
      fractionalCoord.pixelY,
    );
  }

  /// Returns a record `(bool isCached, double? elevation)` indicating whether the tile
  /// is cached, and its decoded elevation if it is cached and valid.
  (bool isCached, double? elevation) getCachedElevationState(
    double lat,
    double lon,
  ) {
    final fractionalCoord = getFractionalPixelCoordinate(lat, lon);
    final (isCached, tile) = _cache.getEntry(
      fractionalCoord.tileX,
      fractionalCoord.tileY,
    );
    if (!isCached) {
      return (false, null);
    }
    if (tile == null) {
      return (true, null);
    }
    final elevation = _decodeElevation(
      tile,
      fractionalCoord.pixelX,
      fractionalCoord.pixelY,
    );
    return (true, elevation);
  }

  /// Checks if the tile containing [lat] and [lon] is in the cache.
  bool isTileCached(double lat, double lon) {
    final fractionalCoord = getFractionalPixelCoordinate(lat, lon);
    return _cache.contains(fractionalCoord.tileX, fractionalCoord.tileY);
  }

  /// Safely manages concurrent fetches for a tile, ensuring that when the future
  /// completes, it updates the cache and removes itself from pending fetches atomically.
  Future<TerrainTile?> _getTileFuture(int tileX, int tileY) {
    final key = (tileX, tileY);
    final pending = _pendingFetches[key];
    if (pending != null) return pending;

    final future = () async {
      try {
        final byteData = await _fetchAndDecodeTile(tileX, tileY);
        if (byteData == null) {
          _cache.put(tileX, tileY, null);
          return null;
        }
        final int totalPixels = byteData.lengthInBytes ~/ 4;
        final int sideSize = totalPixels == 0 ? 0 : sqrt(totalPixels).round();
        final tile = TerrainTile(byteData: byteData, sideSize: sideSize);
        _cache.put(tileX, tileY, tile);
        return tile;
      } catch (e, stack) {
        _cache.put(tileX, tileY, null); // Cache failure as null
        debugPrint('Error fetching/decoding tile $tileX, $tileY: $e\n$stack');
        return null;
      } finally {
        _pendingFetches.remove(key);
      }
    }();

    _pendingFetches[key] = future;
    return future;
  }

  /// Calculates the terrain elevation in meters for a given [lat] and [lon].
  ///
  /// Returns `null` if the tile is not available (either offline or network failure)
  /// or if decoding fails.
  Future<double?> getElevation(double lat, double lon) async {
    try {
      final fractionalCoord = getFractionalPixelCoordinate(lat, lon);
      final int tileX = fractionalCoord.tileX;
      final int tileY = fractionalCoord.tileY;

      // 1. Check synchronous cache
      final (isCached, cachedTile) = _cache.getEntry(tileX, tileY);
      if (isCached) {
        if (cachedTile == null) return null;
        return _decodeElevation(
          cachedTile,
          fractionalCoord.pixelX,
          fractionalCoord.pixelY,
        );
      }

      // 2. Fetch asynchronously (handles deduplication and caching internally)
      final tile = await _getTileFuture(tileX, tileY);
      if (tile == null) return null;

      return _decodeElevation(
        tile,
        fractionalCoord.pixelX,
        fractionalCoord.pixelY,
      );
    } catch (e, stack) {
      debugPrint('Error decoding elevation from terrain tile: $e\n$stack');
      return null;
    }
  }

  double _getHeightAt(ByteData byteData, int x, int y, int sideSize) {
    final int clampedX = x.clamp(0, sideSize - 1);
    final int clampedY = y.clamp(0, sideSize - 1);
    final int pixelIndex = (clampedY * sideSize + clampedX) * 4;
    if (pixelIndex + 2 >= byteData.lengthInBytes) {
      return 0.0;
    }
    final int r = byteData.getUint8(pixelIndex);
    final int g = byteData.getUint8(pixelIndex + 1);
    final int b = byteData.getUint8(pixelIndex + 2);
    // Mapzen Terrarium format formula:
    // elevation = (R * 256 + G + B / 256) - 32768
    return (r * 256.0 + g + b / 256.0) - 32768.0;
  }

  double? _decodeElevation(TerrainTile tile, double pixelX, double pixelY) {
    final byteData = tile.byteData;
    final sideSize = tile.sideSize;
    if (sideSize == 0) return null;

    // Scale pixelX and pixelY from 256x256 space to sideSize space
    final double scaledX = (pixelX / 256.0) * sideSize;
    final double scaledY = (pixelY / 256.0) * sideSize;

    // Bilinear interpolation
    final int x0 = scaledX.floor();
    final int y0 = scaledY.floor();
    final int x1 = x0 + 1;
    final int y1 = y0 + 1;

    final double tx = scaledX - x0;
    final double ty = scaledY - y0;

    final double h00 = _getHeightAt(byteData, x0, y0, sideSize);
    final double h10 = _getHeightAt(byteData, x1, y0, sideSize);
    final double h01 = _getHeightAt(byteData, x0, y1, sideSize);
    final double h11 = _getHeightAt(byteData, x1, y1, sideSize);

    // Interpolate along X
    final double h0 = h00 + tx * (h10 - h00);
    final double h1 = h01 + tx * (h11 - h01);

    // Interpolate along Y
    return h0 + ty * (h1 - h0);
  }

  /// Asynchronously fetches and decodes the tile byte data from database or network.
  Future<ByteData?> _fetchAndDecodeTile(int tileX, int tileY) async {
    Uint8List? tileBytes;

    // 1. Try local database first (if not on web)
    if (!kIsWeb) {
      try {
        final tileMap = await DatabaseService.getTile(
          zoomLevel,
          tileX,
          tileY,
          'terrain',
        );
        if (tileMap != null) {
          tileBytes = tileMap['data'] as Uint8List?;
        }
      } catch (e) {
        debugPrint('Error fetching terrain tile from database: $e');
      }
    }

    // 2. Try remote archive fallback via MapAssetsServer (if not on web)
    if (tileBytes == null || tileBytes.isEmpty) {
      if (!kIsWeb) {
        try {
          final archive = await MapAssetsServer.getArchive('terrain');
          final tileId = ZXY(zoomLevel, tileX, tileY).toTileId();
          final remoteTile = await archive.tile(tileId);
          final bytes = remoteTile.bytes();
          tileBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
        } catch (e) {
          debugPrint('Error fetching remote terrain tile: $e');
        }
      }
    }

    if (tileBytes == null || tileBytes.isEmpty) {
      debugPrint(
        'TerrainElevationService: No tile bytes found for $tileX, $tileY',
      );
      return null;
    }

    try {
      // Decode the PNG tile using Flutter's native ui.Codec
      final ui.Codec codec = await ui.instantiateImageCodec(tileBytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      try {
        debugPrint(
          'TerrainElevationService: Decoded tile $tileX, $tileY. Size: ${image.width}x${image.height}',
        );

        return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      } finally {
        image.dispose();
      }
    } catch (e) {
      debugPrint(
        'TerrainElevationService: Error decoding tile $tileX, $tileY: $e',
      );
      return null;
    }
  }
}
