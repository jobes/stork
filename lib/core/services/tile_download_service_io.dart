import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pmtiles/pmtiles.dart';
import 'database/database_service.dart';
import 'map_assets_server.dart';

/// Service responsible for downloading map tiles for offline use.
///
/// Design Decisions:
/// - Tiles are fetched from the database in batches ordered by `kind` and `tile_id`.
///   This ensures that tiles within a single batch are sequential in their respective
///   PMTiles archives, enabling the library to optimize network usage through
///   HTTP Range Requests (fetching multiple tiles in one request).
/// - The implementation prioritizes sequential range requests over archive-level
///   parallelism. Since internet bandwidth is shared, minimizing HTTP overhead
///   via range requests is more efficient than competing concurrent connections.
/// - It uses a [StreamController] and a dedicated database update loop to provide
///   smooth progress updates and decouple downloading from database writes.
/// - [stopDownload] is a waitable Future, ensuring that background work and
///   database transactions are cleanly completed before the process stops.
class TileDownloadService {
  static bool _isDownloading = false;
  static bool get isDownloading => _isDownloading;

  static const int _batchSize = 5000;
  static Completer<void>? _downloadCompleter;

  /// Starts the tile download process.
  ///
  /// Fetches empty tiles from the database and downloads them in batches.
  /// Maintains a [_downloadCompleter] to allow tracking and waiting for completion.
  static Future<void> startDownload() async {
    if (_isDownloading) return;

    _isDownloading = true;
    _downloadCompleter = Completer<void>();

    try {
      debugPrint('TileDownloadService: Starting download process...');

      while (_isDownloading) {
        final hasMore = await _processNextBatch();
        if (!hasMore) {
          debugPrint('TileDownloadService: No more tiles to download.');
          break;
        }

        if (!_isDownloading) break;

        // Minimal delay between batches to keep event loop responsive
        await Future.delayed(const Duration(milliseconds: 10));
      }
    } finally {
      _isDownloading = false;
      _downloadCompleter?.complete();
      _downloadCompleter = null;
      debugPrint('TileDownloadService: Download process stopped.');
    }
  }

  /// Stops the current download process and waits for it to finish.
  static Future<void> stopDownload() async {
    if (!_isDownloading) return;

    debugPrint(
      'TileDownloadService: Stopping download and waiting for completion...',
    );
    _isDownloading = false;
    await _downloadCompleter?.future;
  }

  /// Fetches the next batch of empty tiles and processes them.
  /// Returns true if more tiles might be available.
  static Future<bool> _processNextBatch() async {
    final emptyTiles = await DatabaseService.getEmptyTiles(limit: _batchSize);
    if (emptyTiles.isEmpty) return false;

    final controller = StreamController<Map<String, dynamic>>();

    // Start the database update loop as a separate future
    final updateFuture = _runDatabaseUpdateLoop(controller.stream);

    // Group tiles by kind to optimize PMTiles archive access
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final tile in emptyTiles) {
      grouped.putIfAbsent(tile['kind'] as String, () => []).add(tile);
    }

    debugPrint(
      'TileDownloadService: Processing batch of ${emptyTiles.length} tiles. Kinds: ${grouped.keys.join(', ')}',
    );

    // Start downloads for each archive concurrently
    final downloadFutures = grouped.entries
        .map(
          (entry) => _downloadArchiveBatch(entry.key, entry.value, controller),
        )
        .toList();

    await Future.wait(downloadFutures);
    await controller.close();
    await updateFuture;

    return true;
  }

  /// Consumes a stream of downloaded tile data and updates the database in batches.
  static Future<void> _runDatabaseUpdateLoop(
    Stream<Map<String, dynamic>> stream,
  ) async {
    final List<Map<String, dynamic>> batch = [];

    await for (final res in stream) {
      batch.add(res);
      if (batch.length >= 50) {
        await DatabaseService.updateTilesData(batch);
        batch.clear();
      }
    }

    if (batch.isNotEmpty) {
      await DatabaseService.updateTilesData(batch);
    }
  }

  /// Downloads a batch of tiles from a specific PMTiles archive.
  static Future<void> _downloadArchiveBatch(
    String kind,
    List<Map<String, dynamic>> tiles,
    StreamController<Map<String, dynamic>> controller,
  ) async {
    final archive = await MapAssetsServer.getArchive(kind);

    final idToCoords = {
      for (final t in tiles)
        ZXY(t['z'] as int, t['x'] as int, t['y'] as int).toTileId(): t,
    };

    final tileIds = idToCoords.keys.toList();
    debugPrint(
      'TileDownloadService: Requesting ${tileIds.length} tiles for $kind. IDs range: ${tileIds.first} - ${tileIds.last}',
    );

    await _downloadWithFallback(archive, tileIds, kind, idToCoords, controller);
  }

  /// Downloads a list of tile IDs using batching, with fallback to smaller chunks if some tiles are missing.
  static Future<void> _downloadWithFallback(
    PmTilesArchive archive,
    List<int> ids,
    String kind,
    Map<int, Map<String, dynamic>> idToCoords,
    StreamController<Map<String, dynamic>> controller,
  ) async {
    if (ids.isEmpty || !_isDownloading) return;

    try {
      // Try to fetch the whole chunk at once for maximum speed
      final stream = archive.tiles(ids);

      await for (final tileData in stream) {
        if (!_isDownloading) break;

        final coords = idToCoords[tileData.id];
        if (coords == null) continue;

        final bytes = tileData.bytes();
        if (bytes.isNotEmpty) {
          final type = kind == 'terrain' ? 'png' : 'pbf';

          controller.add({
            'z': coords['z'],
            'x': coords['x'],
            'y': coords['y'],
            'kind': kind,
            'data': bytes,
            'type': type,
          });
        } else {
          _addPlaceholder(controller, coords, kind, 'none');
        }
      }
    } catch (e) {
      if (e is TileNotFoundException) {
        if (ids.length == 1) {
          // Found the missing tile, skip it
          final coords = idToCoords[ids.first];
          if (coords != null) {
            debugPrint(
              'TileDownloadService: Tile not found (skipping): ${coords['z']}/${coords['x']}/${coords['y']} ($kind)',
            );
            _addPlaceholder(controller, coords, kind, 'none');
          }
        } else {
          // Some tiles in this chunk are missing, split and retry
          final mid = ids.length ~/ 2;
          await _downloadWithFallback(
            archive,
            ids.sublist(0, mid),
            kind,
            idToCoords,
            controller,
          );
          await _downloadWithFallback(
            archive,
            ids.sublist(mid),
            kind,
            idToCoords,
            controller,
          );
        }
      } else {
        debugPrint(
          'TileDownloadService: Critical error during batch fetch for $kind: $e',
        );
        rethrow;
      }
    }
  }

  /// Adds a placeholder record to the stream when a tile is missing or has an error.
  static void _addPlaceholder(
    StreamController<Map<String, dynamic>> controller,
    Map<String, dynamic> coords,
    String kind,
    String type,
  ) {
    controller.add({
      'z': coords['z'],
      'x': coords['x'],
      'y': coords['y'],
      'kind': kind,
      'data': Uint8List.fromList([0]),
      'type': type,
    });
  }
}
