import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/flight_forecast.dart';
import '../../domain/forecast_route.dart';
import '../models/forecast_series.dart';

part 'flight_forecast_repository.g.dart';

const _batchSize = 20;

class _LocationOutsideModel implements Exception {
  const _LocationOutsideModel();
}

final _hourlyVariables = [
  'surface_pressure',
  'weather_code',
  forecastGustField,
  'precipitation',
  'cloud_cover_low',
  for (final height in forecastWindHeights) ...[
    'wind_speed_${height}m',
    'wind_direction_${height}m',
  ],
  for (final height in forecastTemperatureHeights) 'temperature_${height}m',
  for (final level in forecastPressureLevels) ...[
    'wind_speed_${level}hPa',
    'wind_direction_${level}hPa',
    'temperature_${level}hPa',
    'geopotential_height_${level}hPa',
  ],
].join(',');

String forecastLocationKey(ForecastLocation location) =>
    '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';

/// The moving aircraft reuses one forecast profile per ~3 km grid cell so small
/// movements do not invalidate the cached profile.
const forecastLocationGrid = 0.03;

ForecastLocation quantizeForecastLocation(ForecastLocation location) => (
  latitude:
      (location.latitude / forecastLocationGrid).round() * forecastLocationGrid,
  longitude:
      (location.longitude / forecastLocationGrid).round() *
      forecastLocationGrid,
);

/// Profile lookup location for a forecast point. The live aircraft position is
/// quantized; route points keep their own coordinates.
ForecastLocation forecastProfileLocation(ForecastRoutePoint point) =>
    point.id == 'origin' || point.id == 'aircraft'
    ? quantizeForecastLocation(point.location)
    : point.location;

class ForecastQuery {
  final Map<String, ForecastLocation> locations;
  final DateTime start;
  final DateTime end;

  ForecastQuery(Iterable<ForecastLocation> locations, this.start, this.end)
    : locations = {
        for (final location in locations)
          forecastLocationKey(location): location,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastQuery &&
          start == other.start &&
          end == other.end &&
          locations.length == other.locations.length &&
          locations.keys.every(other.locations.containsKey);

  @override
  int get hashCode =>
      Object.hash(start, end, Object.hashAllUnordered(locations.keys));
}

typedef ForecastProfiles = ({
  Map<String, ForecastSeries> series,
  bool refreshFailed,
});

@Riverpod(keepAlive: true)
FlightForecastRepository flightForecastRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return FlightForecastRepository(client);
}

typedef _CachedSeries = ({DateTime downloaded, ForecastSeries series});

List<_CachedSeries> _decodeForecastBatch(
  ({List<int> body, int count, DateTime downloaded}) batch,
) {
  final decoded = jsonDecode(utf8.decode(batch.body));
  final rows = decoded is List ? decoded : [decoded];
  if (rows.length != batch.count) {
    throw const FormatException('Incomplete forecast batch');
  }
  return [
    for (final data in rows.cast<Map<String, dynamic>>())
      (
        downloaded: batch.downloaded,
        series: ForecastSeries.fromJson(data, batch.downloaded),
      ),
  ];
}

/// Forecast profiles are kept in memory only. Weather is a planning aid, so a
/// restart never reuses an older forecast: each session fetches its own
/// profiles and reuses them only for network outages within the same session.
class FlightForecastRepository {
  final http.Client _client;
  final _cache = <String, _CachedSeries>{};
  final _outsideModel = <String>{};
  Future<void> _pending = Future.value();
  bool _refreshAll = false;

  FlightForecastRepository(this._client);

  /// Requests a fresh profile for every location on the next load. A failed
  /// refresh keeps the profiles already held by this session.
  void requestRefresh() => _refreshAll = true;

  Future<ForecastProfiles> load(ForecastQuery query) {
    final result = _pending.then((_) => _load(query));
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<ForecastProfiles> _load(ForecastQuery query) async {
    final now = clock.now().toUtc();
    final refreshAll = _refreshAll;
    _refreshAll = false;
    final missing = query.locations.keys.where((key) {
      if (_outsideModel.contains(key)) return false;
      if (refreshAll) return true;
      final cached = _cache[key];
      return cached == null ||
          now.difference(cached.downloaded) >= forecastRefreshInterval ||
          !cached.series.covers(query.start) ||
          !cached.series.covers(query.end);
    }).toList();
    var refreshFailed = false;
    for (var i = 0; i < missing.length; i += _batchSize) {
      final batch = missing.skip(i).take(_batchSize).toList();
      try {
        await _refreshBatch(batch, query, now);
      } on Exception catch (error) {
        debugPrint(
          'Flight forecast refresh unavailable (${error.runtimeType}).',
        );
        refreshFailed = true;
        break;
      } on TypeError {
        debugPrint('Unexpected flight forecast format.');
        refreshFailed = true;
        break;
      }
    }
    final result = (
      series: {
        for (final key in query.locations.keys)
          if (_cache[key] case final entry?) key: entry.series,
      },
      refreshFailed: refreshFailed,
    );
    return result;
  }

  Future<void> _refreshBatch(
    List<String> batch,
    ForecastQuery query,
    DateTime now,
  ) async {
    try {
      final rows = await _request(batch, query, now);
      for (final (index, key) in batch.indexed) {
        _cache[key] = rows[index];
      }
    } on _LocationOutsideModel {
      if (batch.length == 1) {
        _outsideModel.add(batch.single);
        return;
      }
      final middle = batch.length ~/ 2;
      await _refreshBatch(batch.sublist(0, middle), query, now);
      await _refreshBatch(batch.sublist(middle), query, now);
    }
  }

  Future<List<_CachedSeries>> _request(
    List<String> keys,
    ForecastQuery query,
    DateTime downloaded,
  ) async {
    String hour(DateTime time) => time.toIso8601String().substring(0, 16);
    final locations = keys.map((key) => query.locations[key]!).toList();
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': locations.map((p) => p.latitude.toStringAsFixed(4)).join(','),
      'longitude': locations
          .map((p) => p.longitude.toStringAsFixed(4))
          .join(','),
      'elevation': List.filled(locations.length, 'nan').join(','),
      'cell_selection': 'nearest',
      'models': forecastModel,
      'timeformat': 'unixtime',
      'start_hour': hour(query.start),
      'end_hour': hour(query.end),
      'hourly': _hourlyVariables,
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 400 &&
        response.body.contains('No data is available for this location')) {
      throw const _LocationOutsideModel();
    }
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Forecast request failed (${response.statusCode})',
      );
    }
    return compute(_decodeForecastBatch, (
      body: response.bodyBytes,
      count: keys.length,
      downloaded: downloaded,
    ), debugLabel: 'Decode flight forecast batch');
  }
}
