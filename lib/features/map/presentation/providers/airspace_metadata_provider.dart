import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../services/database/database_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/airspace_metadata.dart';

part 'airspace_metadata_provider.g.dart';

// Top-level function for compute to parse JSON in a background isolate
Map<String, AirspaceMetadata> _parseAirspaceFeatures(String responseBody) {
  final data = json.decode(responseBody);
  final features = data['features'] as List<dynamic>?;
  final result = <String, AirspaceMetadata>{};

  if (features != null) {
    for (final f in features) {
      if (f is Map<String, dynamic>) {
        final props = f['properties'] as Map<String, dynamic>?;
        if (props != null) {
          final id = (props['_id'] ?? props['id'] ?? '').toString();
          if (id.isNotEmpty) {
            result[id] = AirspaceMetadata.fromJson(props);
          }
        }
      }
    }
  }
  return result;
}

@Riverpod(keepAlive: true)
class AirspaceMetadataCache extends _$AirspaceMetadataCache {
  final Map<String, AirspaceMetadata> _memoryCache = {};
  final Set<String> _downloadedCountries = {};
  final Map<String, Future<void>> _inflightDownloads = {};

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

    // 2. Check offline SQLite database
    final dbFeature = await DatabaseService.getOpenAipFeature(airspaceId);
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
        final url =
            '${ApiConstants.openAipMetadataBaseUrl}/${lowerCountryCode}_asp.geojson?alt=media';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('HTTP status ${response.statusCode}');
        }

        // Use compute to parse large JSON in a separate isolate to prevent UI jank
        final parsedFeatures = await compute(
          _parseAirspaceFeatures,
          utf8.decode(response.bodyBytes),
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
) {
  ref.keepAlive();
  return ref
      .watch(airspaceMetadataCacheProvider.notifier)
      .getMetadata(airspaceId, countryCode);
}
