import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/map_metadata_repository.dart';
import '../../domain/airport_metadata.dart';

part 'airport_metadata_provider.g.dart';

@Riverpod(keepAlive: true)
class AirportMetadataCache extends _$AirportMetadataCache {
  final Map<String, AirportMetadata> _memoryCache = {};
  final Set<String> _downloadedCountries = {};
  final Map<String, Future<void>> _inflightDownloads = {};

  Map<String, AirportMetadata> get memoryCache => _memoryCache;

  @override
  void build() {
    // Keep-alive provider that holds the session cache until app restart.
  }

  Future<AirportMetadata?> getMetadata(
    String airportId,
    String countryCode,
  ) async {
    // 1. Check local in-memory cache first
    if (_memoryCache.containsKey(airportId)) {
      return _memoryCache[airportId];
    }

    final repo = ref.watch(mapMetadataRepositoryProvider);

    // 2. Check offline SQLite database
    final dbFeature = await repo.fetchFeatureFromDb(airportId, 'apt');
    if (dbFeature != null) {
      final metadata = AirportMetadata.fromJson(dbFeature);
      if (metadata.latitude != null && metadata.longitude != null) {
        // Add to memory cache for faster subsequent access
        _memoryCache[airportId] = metadata;
        return metadata;
      }
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
            'Failed to fetch airport metadata for country $countryCode: $e',
          );
        }
        return _memoryCache[airportId];
      }

      final future = () async {
        final parsedFeatures = await repo.fetchAirportsFromNetwork(
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
          'Failed to fetch airport metadata for country $countryCode: $e',
        );
      } finally {
        _inflightDownloads.remove(lowerCountryCode);
      }
    }

    // 4. Return from memory cache if we just fetched it
    return _memoryCache[airportId];
  }

  void clearCache() {
    _memoryCache.clear();
    _downloadedCountries.clear();
    _inflightDownloads.clear();
    // Invalidate all family instances so previously cached arguments refetch.
    ref.invalidate(airportMetadataProvider);
  }
}

@riverpod
Future<AirportMetadata?> airportMetadata(
  Ref ref,
  String airportId,
  String countryCode,
) async {
  final metadata = await ref
      .read(airportMetadataCacheProvider.notifier)
      .getMetadata(airportId, countryCode);

  if (metadata != null && ref.mounted) {
    ref.keepAlive();
  }
  return metadata;
}

@riverpod
String openAipApiKey(Ref ref) {
  return dotenv.env['OPENAIP_API_KEY'] ?? '';
}
