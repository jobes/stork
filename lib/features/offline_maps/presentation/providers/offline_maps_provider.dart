import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/offline_maps_state.dart';
import 'package:maplibre/maplibre.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vector_tile/vector_tile.dart';

import '../../../../services/database/database_service.dart';
import '../../../../core/services/tile_download_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/tile_utils.dart';
import '../../../map/domain/airport_metadata.dart';

part 'offline_maps_provider.g.dart';

@riverpod
class OfflineMapsNotifier extends _$OfflineMapsNotifier {
  static const _defaultExtractZoom = 10;
  static const _fallbackExtractZoom = 7;
  static const _maxTilesBeforeFallback = 500;
  static const _metaDataTypes = ['asp', 'apt'];

  Timer? _progressTimer;

  @override
  OfflineMapsState build() {
    Future.microtask(() => loadFromDatabase());
    return OfflineMapsState();
  }

  Future<void> loadFromDatabase() async {
    if (kIsWeb) return;

    final regions = await DatabaseService.getRegions();
    final counts = await DatabaseService.getTileCounts();
    final metadataSize = await DatabaseService.getMetadataSize();
    final lastDate = await DatabaseService.getLastDownloadDate();

    _updateStateFromCounts(regions, counts, metadataSize, lastDate);
  }

  void _updateStateFromCounts(
    List<OfflineMapArea> regions,
    Map<String, int> counts,
    int metadataSize,
    DateTime? lastDate,
  ) {
    final total = counts['total'] ?? 0;
    final downloaded = counts['downloaded'] ?? 0;

    state = state.copyWith(
      regions: regions,
      downloadedTiles: downloaded,
      totalTiles: total,
      downloadedBytes: counts['size'] ?? 0,
      worldBytes: counts['worldSize'] ?? 0,
      openAipBytes: counts['openAipSize'] ?? 0,
      terrainBytes: counts['terrainSize'] ?? 0,
      metadataBytes: metadataSize,
      downloadDate: lastDate,
      isDownloaded: total > 0 && downloaded == total,
    );
  }

  String addRegion(Geographic nw, Geographic se) {
    final id = const Uuid().v4();
    final region = OfflineMapArea(id: id, northwest: nw, southeast: se);
    state = state.copyWith(regions: [...state.regions, region]);
    return id;
  }

  void updateRegion(String id, {Geographic? nw, Geographic? se}) {
    state = state.copyWith(
      regions: state.regions.map((r) {
        if (r.id == id) {
          return r.copyWith(northwest: nw, southeast: se);
        }
        return r;
      }).toList(),
    );
  }

  void removeRegion(String id) {
    state = state.copyWith(
      regions: state.regions.where((r) => r.id != id).toList(),
    );
  }

  Future<void> clearAll() async {
    state = OfflineMapsState(regions: []);
    if (!kIsWeb) {
      await DatabaseService.resetDatabase();
    }
  }

  Future<void> startDownload() async {
    if (kIsWeb || state.regions.isEmpty) return;

    state = state.copyWith(
      isDownloading: true,
      isDownloaded: false,
      downloadedTiles: 0,
      totalTiles: 0,
      hasError: false,
    );

    await DatabaseService.resetDatabase();
    await DatabaseService.insertRegions(state.regions);

    final allTiles = _generateTileSet();
    final totalInserted = await DatabaseService.insertEmptyTiles(allTiles);
    state = state.copyWith(totalTiles: totalInserted);

    await updateProgress();

    _startProgressPolling();

    unawaited(_runDownloadSequence());
  }

  Future<void> cancelDownload() async {
    if (!state.isDownloading) return;

    state = state.copyWith(isDownloading: false, isDownloadingMetadata: false);

    _progressTimer?.cancel();

    await TileDownloadService.stopDownload();
    await DatabaseService.clearMapData();
    await loadFromDatabase();
  }

  Set<TileCoord> _generateTileSet() {
    final allTiles = <TileCoord>{};
    for (final region in state.regions) {
      final minLat = min(region.northwest.lat, region.southeast.lat);
      final maxLat = max(region.northwest.lat, region.southeast.lat);
      final minLon = min(region.northwest.lon, region.southeast.lon);
      final maxLon = max(region.northwest.lon, region.southeast.lon);

      for (final kind in ['openaip', 'protomaps', 'terrain']) {
        final maxZ = kind == 'terrain' ? 12 : 14;
        allTiles.addAll(
          getTilesForRegion(
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            minZ: 0,
            maxZ: maxZ,
            kind: kind,
          ),
        );
      }
    }
    return allTiles;
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateProgress(),
    );
  }

  Future<void> _runDownloadSequence() async {
    try {
      await TileDownloadService.startDownload();

      if (!state.isDownloading) return;

      final countries = await _extractCountries();

      if (!state.isDownloading) return;

      if (countries.isNotEmpty) {
        await _downloadOpenAipMetadata(countries);
      }

      if (!state.isDownloading) return;

      await DatabaseService.updateLastDownloadDate();
      await loadFromDatabase();

      state = state.copyWith(
        isDownloading: false,
        isDownloaded: true,
        downloadDate: DateTime.now(),
      );
      _progressTimer?.cancel();
    } catch (e) {
      debugPrint('OfflineMapsNotifier: Download error: $e');
      _progressTimer?.cancel();
      await TileDownloadService.stopDownload();
      await DatabaseService.clearMapData();
      await loadFromDatabase();
      state = state.copyWith(
        isDownloading: false,
        isDownloadingMetadata: false,
        hasError: true,
      );
    }
  }

  Future<List<String>> _extractCountries() async {
    debugPrint('OfflineMapsNotifier: Extracting countries...');
    final countries = <String>{};

    try {
      int zoom = _defaultExtractZoom;
      var tiles = await DatabaseService.getTilesByKindAndZoom('openaip', zoom);

      if (tiles.length > _maxTilesBeforeFallback) {
        debugPrint(
          'OfflineMapsNotifier: Large region, falling back to zoom $_fallbackExtractZoom',
        );
        zoom = _fallbackExtractZoom;
        tiles = await DatabaseService.getTilesByKindAndZoom('openaip', zoom);
      }

      for (final tileBytes in tiles) {
        final data = _decompressTileIfNeeded(tileBytes);
        countries.addAll(_extractCountriesFromTile(data));
      }

      if (countries.isNotEmpty) {
        final sorted = countries.toList()..sort();
        debugPrint('DOWNLOADED COUNTRIES: ${sorted.join(', ')}');
        return sorted;
      }
    } catch (e) {
      debugPrint('OfflineMapsNotifier: Extraction error: $e');
      rethrow;
    }
    return [];
  }

  Uint8List _decompressTileIfNeeded(Uint8List data) {
    if (data.length > 2 && data[0] == 0x1f && data[1] == 0x8b) {
      try {
        return Uint8List.fromList(gzip.decode(data));
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  Set<String> _extractCountriesFromTile(Uint8List data) {
    final countries = <String>{};
    try {
      final tile = VectorTile.fromBytes(bytes: data);
      for (final layer in tile.layers) {
        for (final feature in layer.features) {
          for (int i = 0; i < feature.tags.length; i += 2) {
            final key = layer.keys[feature.tags[i]];
            if (key == 'country') {
              final val = layer.values[feature.tags[i + 1]].stringValue;
              if (val != null && val.isNotEmpty) countries.add(val);
            }
          }
        }
      }
    } catch (_) {}
    return countries;
  }

  Future<void> _downloadOpenAipMetadata(List<String> countries) async {
    state = state.copyWith(
      isDownloadingMetadata: true,
      totalMetadataCountries: countries.length * _metaDataTypes.length,
      downloadedMetadataCountries: 0,
    );

    int accumulatedBytes = 0;

    for (final country in countries) {
      if (!state.isDownloading) break;

      for (final type in _metaDataTypes) {
        if (!state.isDownloading) break;

        final bytes = await _downloadAndStoreMetadata(country, type);
        accumulatedBytes += bytes;
        state = state.copyWith(
          downloadedMetadataCountries: state.downloadedMetadataCountries + 1,
          metadataBytes: accumulatedBytes,
        );
      }
    }

    state = state.copyWith(isDownloadingMetadata: false);
  }

  Future<int> _downloadAndStoreMetadata(String country, String type) async {
    final url =
        '${ApiConstants.openAipMetadataBaseUrl}/${country.toLowerCase()}_$type.geojson?alt=media';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['features'] is List) {
          final featuresList = List<GeoJsonFeature>.from(
            (data['features'] as List).map(
              (e) => GeoJsonFeature.fromJson(e as Map<String, dynamic>),
            ),
          );
          await _storeFeatures(featuresList, country, type);
          return response.bodyBytes.length;
        }
      } else {
        throw Exception('Failed to download metadata: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OfflineMapsNotifier: Error downloading $url: $e');
      rethrow;
    }
    return 0;
  }

  Future<void> _storeFeatures(
    List<GeoJsonFeature> features,
    String country,
    String type,
  ) async {
    final dbFeatures = features
        .where((f) => f.properties.id.isNotEmpty)
        .map(
          (f) => {
            'id': f.properties.id,
            'json': json.encode(f.properties.toJson()),
            'country': country,
            'type': type,
          },
        )
        .toList();

    if (dbFeatures.isNotEmpty) {
      await DatabaseService.insertOpenAipFeatures(dbFeatures);
    }
  }

  Future<void> updateProgress() async {
    final counts = await DatabaseService.getTileCounts();
    final metadataSize = await DatabaseService.getMetadataSize();
    _updateStateFromCounts(
      state.regions,
      counts,
      metadataSize,
      state.downloadDate,
    );
  }
}
