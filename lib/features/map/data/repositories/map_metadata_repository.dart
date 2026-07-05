import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/database/database_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/airport_metadata.dart';
import '../../domain/airspace_metadata.dart';

part 'map_metadata_repository.g.dart';

Map<String, AirportMetadata> parseAirportFeatures(String responseBody) {
  final data = json.decode(responseBody);
  final features = data['features'] as List<dynamic>?;
  final result = <String, AirportMetadata>{};

  if (features != null) {
    for (final f in features) {
      if (f is Map<String, dynamic>) {
        final Map<String, dynamic> properties = Map<String, dynamic>.from(
          f['properties'] as Map? ?? {},
        );
        final geometry = f['geometry'] as Map<String, dynamic>?;
        if (geometry != null && geometry['type'] == 'Point') {
          final coordinates = geometry['coordinates'] as List<dynamic>?;
          if (coordinates != null && coordinates.length >= 2) {
            properties['latitude'] = (coordinates[1] as num).toDouble();
            properties['longitude'] = (coordinates[0] as num).toDouble();
          }
        }
        final feature = GeoJsonFeature.fromJson({
          ...f,
          'properties': properties,
        });
        if (feature.properties.id.isNotEmpty) {
          result[feature.properties.id] = feature.properties;
        }
      }
    }
  }
  return result;
}

Map<String, AirspaceMetadata> parseAirspaceFeatures(String responseBody) {
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
            final map = Map<String, dynamic>.from(props);
            if (f['geometry'] != null) {
              map['geometry'] = f['geometry'];
            }
            result[id] = AirspaceMetadata.fromJson(map);
          }
        }
      }
    }
  }
  return result;
}

class MapMetadataRepository {
  final http.Client _client;

  MapMetadataRepository({http.Client? client})
    : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> fetchFeatureFromDb(
    String id,
    String type,
  ) async {
    return await DatabaseService.getOpenAipFeature(id, type);
  }

  /// Loads all records of the given type from the local SQLite database (offline map).
  /// Use this instead of calling [DatabaseService.getAllOpenAipFeatures] directly
  /// from other feature layers — keeps direct DB access inside the repository layer.
  Future<List<Map<String, dynamic>>> fetchAllFeaturesFromDb(String type) async {
    return await DatabaseService.getAllOpenAipFeatures(type);
  }

  Future<Map<String, AirportMetadata>> fetchAirportsFromNetwork(
    String countryCode,
  ) async {
    final lowerCountryCode = countryCode.toLowerCase();
    final rawUrl =
        '${ApiConstants.openAipMetadataBaseUrl}/${lowerCountryCode}_apt.geojson?alt=media';
    final url = kIsWeb
        ? '${ApiConstants.webProxyNotamSearchUrl}${Uri.encodeComponent(rawUrl)}'
        : rawUrl;
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP status ${response.statusCode}');
    }

    return await compute(parseAirportFeatures, utf8.decode(response.bodyBytes));
  }

  Future<Map<String, AirspaceMetadata>> fetchAirspacesFromNetwork(
    String countryCode,
  ) async {
    final lowerCountryCode = countryCode.toLowerCase();
    final rawUrl =
        '${ApiConstants.openAipMetadataBaseUrl}/${lowerCountryCode}_asp.geojson?alt=media';
    final url = kIsWeb
        ? '${ApiConstants.webProxyNotamSearchUrl}${Uri.encodeComponent(rawUrl)}'
        : rawUrl;
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP status ${response.statusCode}');
    }

    return await compute(
      parseAirspaceFeatures,
      utf8.decode(response.bodyBytes),
    );
  }
}

@Riverpod(keepAlive: true)
MapMetadataRepository mapMetadataRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return MapMetadataRepository(client: client);
}
