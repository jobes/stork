import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/map_metadata_repository.dart';
import '../../domain/airspace_metadata.dart';

part 'airspace_metadata_provider.g.dart';

@Riverpod(keepAlive: true)
class AirspaceMetadataCache extends _$AirspaceMetadataCache {
  final Map<String, AirspaceMetadata> _memoryCache = {};
  final Set<String> _downloadedCountries = {};
  final Map<String, Future<void>> _inflightDownloads = {};

  Map<String, AirspaceMetadata> get memoryCache => _memoryCache;

  @override
  void build() {
    // Keep-alive provider that holds the session cache until app restart.
  }

  Future<AirspaceMetadata?> getMetadata(
    String airspaceId,
    String countryCode,
  ) async {
    // 1. Check local in-memory cache first
    if (_memoryCache.containsKey(airspaceId)) {
      return _memoryCache[airspaceId];
    }

    final repo = ref.read(mapMetadataRepositoryProvider);

    // 2. Check offline SQLite database
    final dbFeature = await repo.fetchFeatureFromDb(airspaceId, 'asp');
    if (dbFeature != null) {
      final metadata = AirspaceMetadata.fromJson(dbFeature);
      _memoryCache[airspaceId] = metadata;
      return metadata;
    }

    // 3. If the country has not been downloaded in this session, fetch it
    final lowerCountryCode = countryCode.toLowerCase();
    if (!_downloadedCountries.contains(lowerCountryCode)) {
      final inflight = _inflightDownloads[lowerCountryCode];
      if (inflight != null) {
        try {
          await inflight;
        } catch (e) {
          throw Exception(
            'Failed to fetch airspace metadata for country $countryCode: $e',
          );
        }
        return _memoryCache[airspaceId];
      }

      final future = () async {
        final parsedFeatures = await repo.fetchAirspacesFromNetwork(
          lowerCountryCode,
        );
        _memoryCache.addAll(parsedFeatures);
        _downloadedCountries.add(lowerCountryCode);
      }();

      _inflightDownloads[lowerCountryCode] = future;

      try {
        await future;
      } catch (e) {
        throw Exception(
          'Failed to fetch airspace metadata for country $countryCode: $e',
        );
      } finally {
        _inflightDownloads.remove(lowerCountryCode);
      }
    }

    // 4. Return from memory cache if we just fetched it
    return _memoryCache[airspaceId];
  }

  void clearCache() {
    _memoryCache.clear();
    _downloadedCountries.clear();
    _inflightDownloads.clear();
  }
}

@riverpod
Future<AirspaceMetadata?> airspaceMetadata(
  Ref ref,
  String airspaceId,
  String countryCode,
) async {
  final metadata = await ref
      .read(airspaceMetadataCacheProvider.notifier)
      .getMetadata(airspaceId, countryCode);

  if (metadata != null && ref.mounted) {
    ref.keepAlive();
  }
  return metadata;
}
