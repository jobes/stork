import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/airspace_activity_status.dart';
import '../../domain/services/aup_service.dart';
import '../services/cze_aup_service.dart';
import '../services/svk_aup_service.dart';
import 'map_metadata_repository.dart';

part 'aup_repository.g.dart';

/// Aggregates the available AUP/UUP services and binds parsed activity entries
/// to existing openAIP airspace ids via the local database
/// (`openaip_features` table), falling back to a network metadata lookup when
/// the airspace is not present in the offline database.
class AupRepository {
  final List<AupService> _services;
  final MapMetadataRepository _metadataRepository;

  /// Per-country openAIP id index (`normalized name -> id`) fetched from the
  /// network as a fallback for airspaces missing from the offline database.
  final Map<String, Map<String, String>> _networkIdIndexByCountry = {};

  /// Cached openAIP `asp` features from the offline database, loaded once per
  /// session so binding does not re-scan the SQLite table on every fetch.
  Future<List<Map<String, dynamic>>>? _aspFeaturesCache;

  AupRepository(this._services, this._metadataRepository);

  /// Returns the AUP service responsible for the given FIR (e.g. `LZBB` ->
  /// Slovak LzPS). Each service declares the FIR prefixes it covers (see
  /// [AupService.firPrefixes]); the first matching service wins. Returns
  /// `null` when no service covers the FIR.
  AupService? serviceForFir(String firIcao) {
    final upper = firIcao.toUpperCase();
    for (final service in _services) {
      for (final prefix in service.firPrefixes) {
        if (upper.startsWith(prefix)) return service;
      }
    }
    return null;
  }

  /// Fetches the current AUP/UUP activity for [firIcao] and binds the parsed
  /// entries to openAIP airspace ids (offline database first, network as a
  /// fallback).
  Future<List<AupAirspaceActivity>> fetchActivitiesForFir(
    String firIcao,
  ) async {
    final service = serviceForFir(firIcao);
    if (service == null) {
      debugPrint('AUP: no service configured for FIR $firIcao');
      return const [];
    }
    final activities = await service.fetchAupData(firIcao);
    return bindToOpenAipIds(activities, firIcao);
  }

  /// Binds AUP entries to openAIP airspace ids.
  ///
  /// Matching order:
  /// 1. exact openAIP feature id (`_id` / `id`) equal to the AUP designator;
  /// 2. openAIP feature name matching the AUP designator (ignoring whitespace
  ///    and case, e.g. designator `R33` matches name `R 33`);
  /// 3. an openAIP name token equal to the AUP designator — OpenAIP airspace
  ///    names are `designator + ' ' + name` (e.g. `LZP23 SALA`), so the token
  ///    index matches designator `LZP23` to name `LZP23 SALA`;
  /// 4. network metadata lookup for the FIR's country (used when the airspace
  ///    is not present in the offline database).
  ///
  /// When no match is found the entry keeps its designator as [airspaceId] so
  /// it can still be looked up by designator.
  Future<List<AupAirspaceActivity>> bindToOpenAipIds(
    List<AupAirspaceActivity> activities,
    String firIcao,
  ) async {
    if (activities.isEmpty) return activities;

    final aspFeatures = await _fetchAspFeatures();

    final Map<String, Map<String, dynamic>> byId = {};
    final Map<String, String> byNormalizedName = {};
    final Map<String, String> byNameToken = {};
    for (final feature in aspFeatures) {
      final id = (feature['_id'] ?? feature['id'] ?? '').toString();
      if (id.isEmpty) continue;
      byId[id] = feature;
      final name = (feature['name'] ?? '').toString().trim().toUpperCase();
      if (name.isNotEmpty) {
        byNormalizedName[_normalize(name)] = id;
        for (final token in name.split(RegExp(r'\s+'))) {
          byNameToken.putIfAbsent(_normalize(token), () => id);
        }
      }
    }

    // The openAIP country for the network fallback comes from the AUP service
    // covering the FIR — each service declares the country code of its FIRs,
    // so the prefix -> country mapping lives in exactly one place.
    final country = serviceForFir(firIcao)?.countryCode;

    final result = <AupAirspaceActivity>[];
    for (final activity in activities) {
      final designator = activity.designator.trim();
      String? boundId;

      final exact = byId[designator] ?? byId[designator.toUpperCase()];
      if (exact != null) {
        boundId =
            exact['_id']?.toString() ?? exact['id']?.toString() ?? designator;
      } else {
        final normalized = _normalize(designator.toUpperCase());
        final matchedId =
            byNormalizedName[normalized] ?? byNameToken[normalized];
        if (matchedId != null) {
          boundId = matchedId;
        }
      }

      boundId ??= await _resolveIdFromNetwork(designator, country);

      result.add(activity.copyWith(airspaceId: boundId ?? designator));
    }
    return result;
  }

  /// Resolves the openAIP id for [designator] from the network metadata of
  /// [country] (cached per country). Returns `null` when unavailable.
  Future<String?> _resolveIdFromNetwork(
    String designator,
    String? country,
  ) async {
    if (country == null || designator.isEmpty) return null;
    final index = await _networkIdIndexForCountry(country);
    if (index.isEmpty) return null;
    return index[designator] ?? index[_normalize(designator.toUpperCase())];
  }

  /// Loads the openAIP `asp` features from the offline database once and
  /// caches them for the rest of the session (the offline map data does not
  /// change at runtime).
  Future<List<Map<String, dynamic>>> _fetchAspFeatures() {
    return _aspFeaturesCache ??= _metadataRepository.fetchAllFeaturesFromDb(
      'asp',
    );
  }

  Future<Map<String, String>> _networkIdIndexForCountry(String country) async {
    final lower = country.toLowerCase();
    final cached = _networkIdIndexByCountry[lower];
    if (cached != null) return cached;

    Map<String, String> index;
    try {
      final metadata = await _metadataRepository.fetchAirspacesFromNetwork(
        lower,
      );
      index = <String, String>{};
      for (final entry in metadata.entries) {
        index[entry.key] = entry.key;
        final name = entry.value.name.trim().toUpperCase();
        if (name.isNotEmpty) {
          index[_normalize(name)] = entry.key;
          for (final token in name.split(RegExp(r'\s+'))) {
            index.putIfAbsent(_normalize(token), () => entry.key);
          }
        }
      }
    } catch (e) {
      debugPrint('AUP: network metadata fallback failed for $country: $e');
      index = const {};
    }
    _networkIdIndexByCountry[lower] = index;
    return index;
  }

  static String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '');
}

@Riverpod(keepAlive: true)
AupRepository aupRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  final metadataRepository = ref.watch(mapMetadataRepositoryProvider);
  return AupRepository([
    SvkAupService(client: client),
    CzeAupService(client: client),
  ], metadataRepository);
}
