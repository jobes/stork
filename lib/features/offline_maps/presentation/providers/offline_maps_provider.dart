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

import '../../../../core/services/database/database_service.dart';
import '../../../../core/services/tile_download_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/tile_utils.dart';
import '../../../map/data/repositories/notam_catalog_repository.dart';
import '../../../map/presentation/providers/airport_metadata_provider.dart';
import '../../../map/presentation/providers/airspace_metadata_provider.dart';

part 'offline_maps_provider.g.dart';

@riverpod
class OfflineMapsNotifier extends _$OfflineMapsNotifier {
  static const _defaultExtractZoom = 10;
  static const _fallbackExtractZoom = 7;
  static const _maxTilesBeforeFallback = 500;
  static const _metaDataTypes = ['asp', 'apt'];

  Timer? _progressTimer;
  Object? _downloadToken;

  @override
  OfflineMapsState build() {
    Future.microtask(() async {
      if (ref.mounted && _downloadToken == null) await loadFromDatabase();
    });
    return OfflineMapsState();
  }

  Future<void> loadFromDatabase() async {
    if (kIsWeb || !ref.mounted) return;
    final token = _downloadToken;
    final wasDownloading = state.isDownloading;

    final regions = await DatabaseService.getRegions();
    final counts = await DatabaseService.getTileCounts();
    final metadataSize = await DatabaseService.getMetadataSize();
    final lastDate = await DatabaseService.getLastDownloadDate();

    if (!ref.mounted ||
        !identical(token, _downloadToken) ||
        wasDownloading != state.isDownloading) {
      return;
    }
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
      isDownloaded: total > 0 && downloaded == total && lastDate != null,
    );
  }

  String addRegion(Geographic nw, Geographic se) {
    final id = const Uuid().v4();
    final region = OfflineMapArea(id: id, northwest: nw, southeast: se);
    state = state.copyWith(
      regions: [...state.regions, region],
      isDownloaded: false,
    );
    return id;
  }

  void updateRegion(String id, {Geographic? nw, Geographic? se}) {
    state = state.copyWith(
      isDownloaded: false,
      regions: state.regions.map((r) {
        if (r.id == id) {
          return r.copyWith(northwest: nw, southeast: se);
        }
        return r;
      }).toList(),
    );
  }

  /// Removes an area and keeps a downloaded selection ready while areas remain.
  void removeRegion(String id) {
    final regions = state.regions.where((r) => r.id != id).toList();
    state = state.copyWith(
      regions: regions,
      isDownloaded: state.isDownloaded && regions.isNotEmpty,
    );
  }

  Future<void> clearAll() async {
    if (state.isDownloading) await cancelDownload();
    state = OfflineMapsState(regions: []);
    if (!kIsWeb) {
      await DatabaseService.resetDatabase();
    }
  }

  Future<void> startDownload() async {
    if (kIsWeb || state.regions.isEmpty || _downloadToken != null) return;
    final token = _downloadToken = Object();

    state = state.copyWith(
      isDownloading: true,
      isDownloaded: false,
      downloadDate: null,
      downloadedTiles: 0,
      totalTiles: 0,
      hasError: false,
    );

    ref.read(airportMetadataCacheProvider.notifier).clearCache();
    ref.read(airspaceMetadataCacheProvider.notifier).clearCache();

    try {
      await DatabaseService.resetDatabase();
      if (!_isCurrent(token)) return;
      await DatabaseService.insertRegions(state.regions);

      if (!_isCurrent(token)) return;
      final allTiles = _generateTileSet();
      final totalInserted = await DatabaseService.insertEmptyTiles(allTiles);
      if (!_isCurrent(token)) return;
      state = state.copyWith(totalTiles: totalInserted);

      await updateProgress();
      if (!_isCurrent(token)) return;
      _startProgressPolling();
      unawaited(_runDownloadSequence(token));
    } catch (error) {
      if (!_isCurrent(token)) return;
      debugPrint('OfflineMapsNotifier: Download setup error: $error');
      _downloadToken = null;
      state = state.copyWith(isDownloading: false, hasError: true);
    }
  }

  Future<void> cancelDownload() async {
    if (!state.isDownloading) return;

    state = state.copyWith(isDownloading: false, isDownloadingMetadata: false);

    _progressTimer?.cancel();

    try {
      await TileDownloadService.stopDownload();
      await DatabaseService.clearMapData();
      await loadFromDatabase();
    } finally {
      _downloadToken = null;
    }
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

  bool _isCurrent(Object token) =>
      ref.mounted && identical(_downloadToken, token) && state.isDownloading;

  Future<void> _runDownloadSequence(Object token) async {
    bool isCurrent() => _isCurrent(token);

    try {
      await TileDownloadService.startDownload();

      if (!isCurrent()) return;

      final countries = await _extractCountries();

      if (!isCurrent()) return;

      await _downloadOpenAipMetadata(countries, isCurrent);

      if (!isCurrent()) return;

      await DatabaseService.updateLastDownloadDate();
      if (!isCurrent()) return;
      await loadFromDatabase();
      if (!isCurrent()) return;

      _downloadToken = null;
      state = state.copyWith(isDownloading: false, isDownloaded: true);
      _progressTimer?.cancel();
    } catch (e) {
      if (!isCurrent()) return;
      debugPrint('OfflineMapsNotifier: Download error: $e');
      _progressTimer?.cancel();
      await TileDownloadService.stopDownload();
      await DatabaseService.clearMapData();
      await loadFromDatabase();
      _downloadToken = null;
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

  Future<void> _downloadOpenAipMetadata(
    List<String> countries,
    bool Function() isCurrent,
  ) async {
    final catalogs = ref.read(notamCatalogRepositoryProvider);
    state = state.copyWith(
      isDownloadingMetadata: true,
      totalMetadataCountries:
          countries.length * _metaDataTypes.length +
          NotamCatalogRepository.files.length,
      downloadedMetadataCountries: 0,
    );

    await catalogs.downloadForOffline(
      isCurrent: isCurrent,
      onFileDownloaded: () {
        state = state.copyWith(
          downloadedMetadataCountries: state.downloadedMetadataCountries + 1,
        );
      },
    );
    if (!isCurrent()) return;

    int accumulatedBytes = await DatabaseService.getMetadataSize();
    if (!isCurrent()) return;
    state = state.copyWith(metadataBytes: accumulatedBytes);

    for (final country in countries) {
      for (final type in _metaDataTypes) {
        if (!isCurrent()) return;
        final bytes = await _downloadAndStoreMetadata(country, type, isCurrent);
        if (!isCurrent()) return;
        accumulatedBytes += bytes;
        state = state.copyWith(
          downloadedMetadataCountries: state.downloadedMetadataCountries + 1,
          metadataBytes: accumulatedBytes,
        );
      }
    }

    state = state.copyWith(isDownloadingMetadata: false);
  }

  Future<int> _downloadAndStoreMetadata(
    String country,
    String type,
    bool Function() isCurrent,
  ) async {
    final url =
        '${ApiConstants.openAipMetadataBaseUrl}/${country.toLowerCase()}_$type.geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (!isCurrent()) return 0;
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        if (data is Map<String, dynamic> && data['features'] is List) {
          await _storeFeatures(data['features'] as List, country, type);
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

  @visibleForTesting
  Future<void> storeFeaturesForTesting(
    List<dynamic> features,
    String country,
    String type,
  ) => _storeFeatures(features, country, type);

  Future<void> _storeFeatures(
    List<dynamic> features,
    String country,
    String type,
  ) async {
    final dbFeatures = features
        .map((f) {
          if (f is Map<String, dynamic>) {
            if (f['properties'] case Map<String, dynamic> props) {
              final id = (props['_id'] ?? props['id'] ?? '').toString();
              if (id.isNotEmpty) {
                final Map<String, dynamic> propsWithGeo =
                    Map<String, dynamic>.from(props);
                if (f['geometry'] case Map<String, dynamic> geometry) {
                  propsWithGeo['geometry'] = geometry;
                  if (geometry['type'] == 'Point') {
                    if (geometry['coordinates']
                        case List<dynamic> coordinates) {
                      if (coordinates.length >= 2) {
                        propsWithGeo['latitude'] = (coordinates[1] as num)
                            .toDouble();
                        propsWithGeo['longitude'] = (coordinates[0] as num)
                            .toDouble();
                      }
                    }
                  }
                }
                return {
                  'id': id,
                  'json': json.encode(propsWithGeo),
                  'country': country,
                  'type': type,
                };
              }
            }
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (dbFeatures.isNotEmpty) {
      await DatabaseService.insertOpenAipFeatures(dbFeatures);
    }
  }

  Future<void> updateProgress() async {
    final token = _downloadToken;
    if (token == null || !_isCurrent(token)) return;
    final counts = await DatabaseService.getTileCounts();
    final metadataSize = await DatabaseService.getMetadataSize();
    if (!_isCurrent(token)) return;
    _updateStateFromCounts(
      state.regions,
      counts,
      metadataSize,
      state.downloadDate,
    );
  }
}
