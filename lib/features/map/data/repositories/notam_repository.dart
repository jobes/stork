import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/models/notam.dart';
import '../../domain/repositories/notam_repository.dart';
import '../utils/notam_decoder.dart';

part 'notam_repository.g.dart';

class HttpNotamRepository implements NotamRepository {
  final http.Client _client;

  HttpNotamRepository({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<List<Notam>> fetchNotamsByFirs(List<String> firs) async {
    final url = kIsWeb
        ? '${ApiConstants.webProxyNotamSearchUrl}${Uri.encodeComponent(ApiConstants.faaNotamSearchUrl)}'
        : ApiConstants.faaNotamSearchUrl;

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'searchType': '0',
              'designatorsForLocation': firs.join(','),
              'offset': '0',
              'notamsOnly': 'false',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load NOTAMs for FIRs: ${response.statusCode}',
        );
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final list = data['notamList'] as List<dynamic>? ?? [];
      return _decodeRawNotams(list);
    } on TimeoutException catch (e) {
      debugPrint('NOTAMS: Timeout fetching NOTAMs for FIRs: $e');
      return [];
    } on SocketException catch (e) {
      debugPrint('NOTAMS: Network error fetching NOTAMs for FIRs: $e');
      return [];
    }
  }

  @override
  Future<List<Notam>> fetchNotamsAroundPoint(
    Geographic point,
    int radiusMeters,
  ) async {
    final url = kIsWeb
        ? '${ApiConstants.webProxyNotamSearchUrl}${Uri.encodeComponent(ApiConstants.faaNotamSearchUrl)}'
        : ApiConstants.faaNotamSearchUrl;
    final lat = point.lat;
    final lon = point.lon;

    // Convert decimal degrees to Degrees/Minutes/Seconds
    final latDeg = lat.abs().floor();
    final latMin = ((lat.abs() - latDeg) * 60).floor();
    final latSec = (((lat.abs() - latDeg) * 60 - latMin) * 60).floor();
    final latDir = lat >= 0 ? 'N' : 'S';

    final lonDeg = lon.abs().floor();
    final lonMin = ((lon.abs() - lonDeg) * 60).floor();
    final lonSec = (((lon.abs() - lonDeg) * 60 - lonMin) * 60).floor();
    final lonDir = lon >= 0 ? 'E' : 'W';

    final radiusNm = (radiusMeters / 1852.0).ceil();

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'searchType': '3',
              'latDegrees': latDeg.toString(),
              'latMinutes': latMin.toString(),
              'latSeconds': latSec.toString(),
              'latitudeDirection': latDir,
              'longDegrees': lonDeg.toString(),
              'longMinutes': lonMin.toString(),
              'longSeconds': lonSec.toString(),
              'longitudeDirection': lonDir,
              'radius': radiusNm.toString(),
              'offset': '0',
              'notamsOnly': 'false',
              'radiusSearchOnDesignator': 'false',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load NOTAMs around coordinate: ${response.statusCode}',
        );
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final list = data['notamList'] as List<dynamic>? ?? [];
      return _decodeRawNotams(list);
    } on TimeoutException catch (e) {
      debugPrint('NOTAMS: Timeout fetching NOTAMs around point: $e');
      return [];
    } on SocketException catch (e) {
      debugPrint('NOTAMS: Network error fetching NOTAMs around point: $e');
      return [];
    }
  }

  List<Notam> _decodeRawNotams(List<dynamic> list) {
    final result = <Notam>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(NotamDecoder.decode(item));
        } catch (e) {
          debugPrint('NOTAMS: Skipped decoding NOTAM: $e');
        }
      }
    }
    return result;
  }
}

@Riverpod(keepAlive: true)
NotamRepository notamRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return HttpNotamRepository(client: client);
}
