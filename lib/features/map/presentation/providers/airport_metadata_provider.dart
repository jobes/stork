import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../services/database/database_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/airport_metadata.dart';

part 'airport_metadata_provider.g.dart';

// Top-level function for compute to parse JSON in a background isolate
Map<String, AirportMetadata> _parseAirportFeatures(String responseBody) {
  final data = json.decode(responseBody);
  final features = data['features'] as List<dynamic>?;
  final result = <String, AirportMetadata>{};

  if (features != null) {
    for (final f in features) {
      if (f is Map<String, dynamic>) {
        final feature = GeoJsonFeature.fromJson(f);
        if (feature.properties.id.isNotEmpty) {
          result[feature.properties.id] = feature.properties;
        }
      }
    }
  }
  return result;
}

@Riverpod(keepAlive: true)
class AirportMetadataCache extends _$AirportMetadataCache {
  final Map<String, AirportMetadata> _memoryCache = {};
  final Set<String> _downloadedCountries = {};

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

    // 2. Check offline SQLite database
    final dbFeature = await DatabaseService.getOpenAipFeature(airportId);
    if (dbFeature != null) {
      // Add to memory cache for faster subsequent access
      _memoryCache[airportId] = dbFeature;
      return dbFeature;
    }

    // 3. If the country has not been downloaded in this session, fetch it
    final lowerCountryCode = countryCode.toLowerCase();
    if (!_downloadedCountries.contains(lowerCountryCode)) {
      try {
        final url =
            '${ApiConstants.openAipMetadataBaseUrl}/${lowerCountryCode}_apt.geojson?alt=media';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          // Use compute to parse large JSON in a separate isolate to prevent UI jank
          final parsedFeatures = await compute(_parseAirportFeatures, response.body);
          _memoryCache.addAll(parsedFeatures);
          _downloadedCountries.add(lowerCountryCode);
        }
      } catch (e) {
        // Return null or rethrow, allowing UI to handle the error
        return null;
      }
    }

    // 4. Return from memory cache if we just fetched it
    return _memoryCache[airportId];
  }

  void clearCache() {
    _memoryCache.clear();
    _downloadedCountries.clear();
  }
}

@riverpod
Future<AirportMetadata?> airportMetadata(
  Ref ref,
  String airportId,
  String countryCode,
) {
  return ref
      .read(airportMetadataCacheProvider.notifier)
      .getMetadata(airportId, countryCode);
}
