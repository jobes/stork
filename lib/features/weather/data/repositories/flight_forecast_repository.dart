import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_route.dart';
import '../models/forecast_series.dart';

part 'flight_forecast_repository.g.dart';

const _cacheKey = 'flight_forecasts';
const _batchSize = 20;
const _maxSavedProfiles = 160;

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
Future<FlightForecastRepository> flightForecastRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final client = http.Client();
  ref.onDispose(client.close);
  return FlightForecastRepository(client, prefs);
}

typedef _CachedSeries = ({
  DateTime downloaded,
  Map<String, dynamic> json,
  ForecastSeries series,
});

Map<String, _CachedSeries> _decodeForecastCache(String stored) {
  final entries = jsonDecode(stored) as Map<String, dynamic>;
  return entries.map((key, entry) {
    final json = entry['data'] as Map<String, dynamic>;
    final downloaded = DateTime.parse(entry['downloaded'] as String);
    return MapEntry(key, (
      json: json,
      downloaded: downloaded,
      series: ForecastSeries.fromJson(json, downloaded),
    ));
  });
}

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
        json: data,
        downloaded: batch.downloaded,
        series: ForecastSeries.fromJson(data, batch.downloaded),
      ),
  ];
}

({String json, Set<String> keys}) _encodeForecastCache(
  Map<String, ({DateTime downloaded, Map<String, dynamic> json})> cache,
) {
  final entries = cache.entries.toList()
    ..sort((a, b) => b.value.downloaded.compareTo(a.value.downloaded));
  final newest = entries.take(_maxSavedProfiles);
  return (
    json: jsonEncode({
      for (final entry in newest)
        entry.key: {
          'downloaded': entry.value.downloaded.toIso8601String(),
          'data': entry.value.json,
        },
    }),
    keys: newest.map((entry) => entry.key).toSet(),
  );
}

class FlightForecastRepository {
  final http.Client _client;
  final SharedPreferences _prefs;
  final _cache = <String, _CachedSeries>{};
  final _outsideModel = <String>{};
  Future<void> _pending = Future.value();

  FlightForecastRepository(this._client, this._prefs) {
    final stored = _prefs.getString(_cacheKey);
    if (stored != null) _pending = _restore(stored);
  }

  Future<void> _restore(String stored) async {
    try {
      _cache.addAll(
        await compute(
          _decodeForecastCache,
          stored,
          debugLabel: 'Restore flight forecast cache',
        ),
      );
    } on FormatException {
      debugPrint('Could not decode the saved flight forecast.');
    } on TypeError {
      debugPrint('Unexpected saved flight forecast format.');
    }
  }

  Future<ForecastProfiles> load(ForecastQuery query) {
    final result = _pending.then((_) => _load(query));
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<ForecastProfiles> _load(ForecastQuery query) async {
    final now = clock.now().toUtc();
    final missing = query.locations.keys.where((key) {
      if (_outsideModel.contains(key)) return false;
      final cached = _cache[key];
      return cached == null ||
          now.difference(cached.downloaded) >= forecastRefreshInterval ||
          !cached.series.covers(query.start) ||
          !cached.series.covers(query.end);
    }).toList();
    var refreshFailed = false;
    var updated = false;
    for (var i = 0; i < missing.length; i += _batchSize) {
      final batch = missing.skip(i).take(_batchSize).toList();
      try {
        if (await _refreshBatch(batch, query, now)) updated = true;
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
    if (updated) await _save();
    return result;
  }

  Future<bool> _refreshBatch(
    List<String> batch,
    ForecastQuery query,
    DateTime now,
  ) async {
    try {
      final rows = await _request(batch, query, now);
      for (final (index, key) in batch.indexed) {
        _cache[key] = rows[index];
      }
      return true;
    } on _LocationOutsideModel {
      if (batch.length == 1) {
        _outsideModel.add(batch.single);
        return false;
      }
      final middle = batch.length ~/ 2;
      final left = await _refreshBatch(batch.sublist(0, middle), query, now);
      final right = await _refreshBatch(batch.sublist(middle), query, now);
      return left || right;
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

  Future<void> _save() async {
    try {
      final packed = await compute(_encodeForecastCache, {
        for (final entry in _cache.entries)
          entry.key: (
            downloaded: entry.value.downloaded,
            json: entry.value.json,
          ),
      }, debugLabel: 'Encode flight forecast cache');
      _cache.removeWhere((key, value) => !packed.keys.contains(key));
      final saved = await _prefs.setString(_cacheKey, packed.json);
      if (!saved) debugPrint('Could not persist flight forecast profiles.');
    } on Exception {
      debugPrint('Could not persist flight forecast profiles.');
    }
  }
}
