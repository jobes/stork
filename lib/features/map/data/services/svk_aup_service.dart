import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../domain/models/airspace_activity_status.dart';
import '../../domain/services/aup_service.dart';

/// AUP/UUP client for the Slovak LzPS (AIS SR) source.
///
/// Queries the public ArcGIS FeatureServer used by the official LzPS airspace
/// reservation viewer (the same endpoint the laamap map uses, see
/// `airspaces-activation-state.service.ts`). The `where` clause restricts the
/// result to GA/VFR-relevant reservations (below FL195, excluding NPZ) whose
/// status is `ACTIVE`, `APPROVED`, `ALLOCATED`, `REFERENCE_ALLOCATED` or
/// `PENDING`, so every returned feature is treated as currently active.
class SvkAupService implements AupService {
  /// Stable source identifier for the activities produced by this service.
  static const String sourceCodeValue = 'SVK_LZPS';

  final http.Client _client;
  final bool _useWebProxy;

  SvkAupService({http.Client? client, bool? useWebProxy})
    : _client = client ?? http.Client(),
      _useWebProxy = useWebProxy ?? kIsWeb;

  /// ArcGIS `where` clause: reservations relevant for GA/VFR flying (below
  /// FL195, excluding NPZ) that are active or about to be activated.
  static const String _whereClause =
      "(lower_fl <> 'FL' OR lower_val <= 195) AND "
      "(localtype_txt IS NULL OR localtype_txt <> 'NPZ') AND "
      "(status = 'ACTIVE' OR status = 'APPROVED' OR status = 'ALLOCATED' "
      "OR status = 'REFERENCE_ALLOCATED' OR status = 'PENDING')";

  @override
  String get sourceCode => sourceCodeValue;

  /// Slovak FIRs (LZ*), e.g. LZBB (Bratislava), LZPP (Piešťany).
  @override
  List<String> get firPrefixes => const ['LZ'];

  /// openAIP country code for Slovak airspaces.
  @override
  String get countryCode => 'SK';

  @override
  Future<List<AupAirspaceActivity>> fetchAupData(
    String countryOrFirCode,
  ) async {
    final query = Uri(
      queryParameters: {
        'f': 'json',
        'where': _whereClause,
        'returnGeometry': 'false',
        'spatialRel': 'esriSpatialRelIntersects',
        'outFields': 'airspace',
        'outSR': '102100',
        'resultOffset': '0',
        'resultRecordCount': '1000',
      },
    ).query;
    final rawUrl = '${ApiConstants.svkAupQueryUrl}?$query';
    final url = _useWebProxy
        ? '${ApiConstants.webProxyNotamSearchUrl}${Uri.encodeComponent(rawUrl)}'
        : rawUrl;
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception(
          'LzPS AUP request failed for $countryOrFirCode: HTTP ${response.statusCode}',
        );
      }
      return parseLzpsGisResponse(utf8.decode(response.bodyBytes));
    } on TimeoutException catch (e) {
      debugPrint('LzPS AUP: timeout fetching $countryOrFirCode: $e');
      return const [];
    } on SocketException catch (e) {
      debugPrint('LzPS AUP: network error fetching $countryOrFirCode: $e');
      return const [];
    } catch (e) {
      debugPrint('LzPS AUP: failed to fetch $countryOrFirCode: $e');
      return const [];
    }
  }

  /// Parses an LzPS ArcGIS FeatureServer response into
  /// [AupAirspaceActivity] entries.
  ///
  /// The query `where` clause already filters by status, so every returned
  /// feature represents a currently active reservation. The response only
  /// carries the airspace designator (no status or validity window), so each
  /// entry gets [AirspaceActivityStatus.active] and no time window.
  static List<AupAirspaceActivity> parseLzpsGisResponse(String body) {
    final Object? decoded;
    try {
      decoded = json.decode(body);
    } catch (_) {
      return const [];
    }
    if (decoded is! Map) return const [];

    final features = decoded['features'];
    if (features is! List) return const [];

    final now = clock.now();
    final result = <AupAirspaceActivity>[];
    for (final dynamic raw in features) {
      if (raw is! Map) continue;
      final attributes = raw['attributes'];
      if (attributes is! Map) continue;
      final designator = (attributes['airspace'] ?? '').toString().trim();
      if (designator.isEmpty) continue;

      result.add(
        AupAirspaceActivity(
          airspaceId: designator,
          designator: designator,
          name: designator,
          status: AirspaceActivityStatus.active,
          source: sourceCodeValue,
          updatedAt: now,
        ),
      );
    }
    return result;
  }
}
