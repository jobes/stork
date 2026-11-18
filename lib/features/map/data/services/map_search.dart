import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/map_search_result.dart';
import '../repositories/map_metadata_repository.dart';
import '../repositories/notam_catalog_repository.dart';

const mapSearchLimit = 20;
final _accentedCharacters = RegExp(r'[\u00e0-\u024f\u0300-\u036f]');

String normalizeMapSearchText(String text) {
  const variants = {
    'a': 'àáâãäåāăą',
    'c': 'çćĉċč',
    'd': 'ďđð',
    'e': 'èéêëēĕėęě',
    'g': 'ĝğġģ',
    'h': 'ĥħ',
    'i': 'ìíîïĩīĭįı',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľł',
    'n': 'ñńņň',
    'o': 'òóôõöøōŏő',
    'r': 'ŕŗř',
    's': 'śŝşšș',
    't': 'ţťț',
    'u': 'ùúûüũūŭůűų',
    'w': 'ŵ',
    'y': 'ýÿŷ',
    'z': 'źżž',
  };
  return text.trim().toLowerCase().replaceAllMapped(_accentedCharacters, (
    match,
  ) {
    final character = match[0]!;
    if (character.codeUnitAt(0) >= 0x0300) return '';
    for (final MapEntry(:key, :value) in variants.entries) {
      if (value.contains(character)) return key;
    }
    return character;
  });
}

final airportSearchRecordsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final metadata = ref.watch(mapMetadataRepositoryProvider);
      final catalogs = ref.watch(notamCatalogRepositoryProvider);
      final offline = await metadata.fetchAllFeaturesFromDb('apt');
      if (offline.isNotEmpty || !ref.mounted) return offline;

      final geoJson = await catalogs.loadOnlineAirports();
      return compute(_parseAirportFeatures, geoJson);
    }, retry: (_, _) => null);

List<Map<String, dynamic>> _parseAirportFeatures(Uint8List bytes) {
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded case {
    'type': 'FeatureCollection',
    'features': List<dynamic> features,
  }) {
    return features.whereType<Map<String, dynamic>>().toList();
  }
  throw const FormatException('Expected an airport GeoJSON FeatureCollection');
}

List<MapSearchResult> searchAirportRecords(
  Iterable<Map<String, dynamic>> records,
  String query,
) {
  final nameQuery = normalizeMapSearchText(query);
  if (nameQuery.isEmpty) return [];
  final codeQuery = query.trim().toUpperCase();
  final exactCodes = <MapSearchResult>[];
  final codePrefixes = <MapSearchResult>[];
  final names = <MapSearchResult>[];

  for (final record in records) {
    final properties = record['properties'];
    final fields = properties is Map<String, dynamic> ? properties : record;
    final rawCode = fields['icaoCode'] ?? fields['icao'];
    final rawName = fields['name'];
    final code = rawCode is String ? rawCode.trim().toUpperCase() : '';
    final name = rawName is String ? rawName.trim() : '';
    final matches = switch (code) {
      _ when code == codeQuery => exactCodes,
      _ when code.startsWith(codeQuery) => codePrefixes,
      _ when normalizeMapSearchText(name).contains(nameQuery) => names,
      _ => null,
    };
    if (matches == null || matches.length == mapSearchLimit) continue;

    final result = _airportResult(record, fields, name: name, code: code);
    if (result == null) continue;
    matches.add(result);
    if (exactCodes.length == mapSearchLimit) return exactCodes;
  }

  return [
    ...exactCodes,
    ...codePrefixes,
    ...names,
  ].take(mapSearchLimit).toList();
}

MapSearchResult? _airportResult(
  Map<String, dynamic> record,
  Map<String, dynamic> fields, {
  required String name,
  required String code,
}) {
  Object? lat = record['latitude'];
  Object? lon = record['longitude'];
  if (lat is! num || lon is! num) {
    if (record['geometry'] case {
      'type': 'Point',
      'coordinates': [final x, final y, ...],
    }) {
      lat = y;
      lon = x;
    }
  }
  if (lat is! num ||
      lon is! num ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat.abs() > 90 ||
      lon.abs() > 180) {
    return null;
  }
  return MapSearchResult(
    type: MapSearchResultType.airport,
    name: name.isEmpty ? code : name,
    icaoCode: code,
    airportId: (fields['source_id'] ?? fields['_id'] ?? fields['id'])
        ?.toString(),
    airportCountry: fields['country']?.toString(),
    latitude: lat.toDouble(),
    longitude: lon.toDouble(),
  );
}

class PhotonSearch {
  const PhotonSearch(this._client);

  final http.Client _client;

  Future<List<MapSearchResult>> search(
    String query, {
    required double latitude,
    required double longitude,
    required int limit,
  }) async {
    if (limit <= 0) return [];
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'layer': 'city',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'limit': limit.toString(),
    });
    // Photon rejects the default dart:io User-Agent. Browsers set their own.
    final response = await _client
        .get(
          uri,
          headers: kIsWeb
              ? null
              : const {
                  'User-Agent': 'Stork Navigation (https://www.stork-nav.app/)',
                },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw http.ClientException('Photon HTTP ${response.statusCode}', uri);
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>;
    return features
        .whereType<Map<String, dynamic>>()
        .map(_municipality)
        .nonNulls
        .take(limit)
        .toList();
  }

  MapSearchResult? _municipality(Map<String, dynamic> feature) {
    final properties = feature['properties'];
    final geometry = feature['geometry'];
    if (properties is! Map || geometry is! Map) return null;
    final name = properties['name'];
    final coordinates = geometry['coordinates'];
    if (name is! String ||
        name.trim().isEmpty ||
        geometry['type'] != 'Point' ||
        coordinates is! List ||
        coordinates.length < 2) {
      return null;
    }
    final [lon, lat, ...] = coordinates;
    if (lon is! num ||
        lat is! num ||
        !lon.isFinite ||
        !lat.isFinite ||
        lon.abs() > 180 ||
        lat.abs() > 90) {
      return null;
    }
    final area =
        [properties['county'] ?? properties['state'], properties['country']]
            .whereType<String>()
            .where((value) => value.isNotEmpty && value != name)
            .toSet()
            .join(', ');
    return MapSearchResult(
      type: MapSearchResultType.municipality,
      name: name,
      area: area,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
    );
  }
}

final photonSearchProvider = Provider.autoDispose<PhotonSearch>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return PhotonSearch(client);
});
