import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stork/features/weather/data/repositories/flight_forecast_repository.dart';
import 'package:stork/features/weather/domain/flight_forecast.dart';
import 'package:stork/features/weather/domain/forecast_query.dart';

void main() {
  test('batches locations, reuses hourly profiles and keeps them for a failed refresh', () async {
    final start = DateTime.utc(2026, 11, 16, 14);
    var now = start;
    var requestCount = 0;
    var offline = false;
    final client = MockClient((request) async {
      requestCount++;
      expect(request.url.host, 'api.open-meteo.com');
      expect(request.url.queryParameters['models'], 'dwd_icon_eu_native');
      expect(request.url.queryParameters['latitude'], '48.1700,48.8780');
      expect(request.url.queryParameters['hourly'], contains('wind_gusts_10m'));
      if (offline) return http.Response('offline', 503);
      return http.Response(
        jsonEncode([
          for (final height in [165, 996])
            {
              'elevation': height,
              'hourly': {
                'time': [
                  start.millisecondsSinceEpoch ~/ 1000,
                  start.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                      1000,
                ],
                'wind_gusts_10m': [18, 36],
              },
            },
        ]),
        200,
      );
    });
    addTearDown(client.close);
    final query = ForecastQuery(
      [
        (latitude: 48.17, longitude: 17.21),
        (latitude: 48.878, longitude: 19.226),
      ],
      start,
      start.add(const Duration(hours: 1)),
    );

    await withClock(Clock(() => now), () async {
      final repository = FlightForecastRepository(client);
      final initial = await repository.load(query);
      expect(initial.series.length, 2);
      expect(initial.refreshFailed, isFalse);
      expect(requestCount, 1);

      now = start.add(const Duration(minutes: 5));
      await repository.load(query);
      expect(requestCount, 1);

      offline = true;
      now = start.add(forecastRefreshInterval);
      final refreshed = await repository.load(query);
      expect(requestCount, 2);
      expect(refreshed.refreshFailed, isTrue);
      expect(
        refreshed.series.values.first
            .at(start.add(const Duration(minutes: 30)))!
            .gustMs,
        10,
      );
      expect(
        refreshed.series.values.first.at(start.add(const Duration(hours: 2))),
        isNull,
      );
    });
  });

  test('a restarted session never shows a forecast fetched earlier', () async {
    final start = DateTime.utc(2026, 11, 16, 14);
    var online = true;
    final client = MockClient((request) async {
      if (!online) return http.Response('offline', 503);
      return http.Response(
        jsonEncode({
          'elevation': 165,
          'hourly': {
            'time': [start.millisecondsSinceEpoch ~/ 1000],
            'wind_gusts_10m': [18],
          },
        }),
        200,
      );
    });
    addTearDown(client.close);
    final query = ForecastQuery(
      [(latitude: 48.17, longitude: 17.21)],
      start,
      start,
    );

    final session = await FlightForecastRepository(client).load(query);
    expect(session.series, hasLength(1));
    expect(session.refreshFailed, isFalse);

    online = false;
    final restarted = await FlightForecastRepository(client).load(query);
    expect(restarted.series, isEmpty);
    expect(restarted.refreshFailed, isTrue);
  });

  test('a manual refresh requests every profile again', () async {
    final start = DateTime.utc(2026, 11, 16, 14);
    var now = start;
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response(
        jsonEncode({
          'elevation': 165,
          'hourly': {
            'time': [start.millisecondsSinceEpoch ~/ 1000],
            'wind_gusts_10m': [18],
          },
        }),
        200,
      );
    });
    addTearDown(client.close);
    final query = ForecastQuery(
      [(latitude: 48.17, longitude: 17.21)],
      start,
      start,
    );

    await withClock(Clock(() => now), () async {
      final repository = FlightForecastRepository(client);
      await repository.load(query);
      expect(requests, 1);

      now = start.add(const Duration(minutes: 5));
      await repository.load(query);
      expect(requests, 1);

      repository.requestRefresh();
      await repository.load(query);
      expect(requests, 2);
    });
  });

  test(
    'a point outside the model does not hide the rest of the batch',
    () async {
      final start = DateTime.utc(2026, 11, 16, 14);
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        if (request.url.queryParameters['latitude']!.contains('-33.8600')) {
          return http.Response(
            '{"error":true,"reason":"No data is available for this location"}',
            400,
          );
        }
        return http.Response(
          jsonEncode({
            'elevation': 165,
            'hourly': {
              'time': [start.millisecondsSinceEpoch ~/ 1000],
            },
          }),
          200,
        );
      });
      addTearDown(client.close);
      final location = (latitude: 48.17, longitude: 17.21);
      final query = ForecastQuery(
        [location, (latitude: -33.86, longitude: 151.21)],
        start,
        start,
      );
      final repository = FlightForecastRepository(client);

      final profiles = await repository.load(query);
      expect(profiles.refreshFailed, isFalse);
      expect(profiles.series.keys, [forecastLocationKey(location)]);
      expect(requests, 3);

      await repository.load(query);
      expect(requests, 3);

      // A manual refresh retries the location the model did not cover.
      repository.requestRefresh();
      final refreshed = await repository.load(query);
      expect(requests, 6);
      expect(refreshed.refreshFailed, isFalse);
      expect(refreshed.series.keys, [forecastLocationKey(location)]);
    },
  );

  test(
    'recoverable failures do not prevent later independent batches',
    () async {
      final start = DateTime.utc(2026, 11, 16, 14);
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        if (requests == 1) return http.Response('offline', 503);
        if (requests == 2) return http.Response('{bad json', 200);
        return http.Response(
          jsonEncode({
            'elevation': 100,
            'hourly': {
              'time': [start.millisecondsSinceEpoch ~/ 1000],
            },
          }),
          200,
        );
      });
      addTearDown(client.close);
      final result = await FlightForecastRepository(client).load(
        ForecastQuery(
          [
            for (var i = 0; i < 41; i++)
              (latitude: 48 + i / 100, longitude: 17.0),
          ],
          start,
          start,
        ),
      );
      expect(requests, 3);
      expect(result.refreshFailed, isTrue);
      expect(result.series, hasLength(1));
    },
  );

  for (final status in [401, 403, 429]) {
    test(
      'HTTP $status logs once, stops later batches and preserves cache',
      () async {
        final start = DateTime.utc(2026, 11, 16, 14);
        var requests = 0;
        var blocked = false;
        final client = MockClient((request) async {
          requests++;
          if (blocked) return http.Response('unavailable', status);
          final count = request.url.queryParameters['latitude']!
              .split(',')
              .length;
          return http.Response(
            jsonEncode([
              for (var i = 0; i < count; i++)
                {
                  'elevation': 100,
                  'hourly': {
                    'time': [start.millisecondsSinceEpoch ~/ 1000],
                  },
                },
            ]),
            200,
          );
        });
        addTearDown(client.close);
        final query = ForecastQuery(
          [
            for (var i = 0; i < 21; i++)
              (latitude: 48 + i / 100, longitude: 17.0),
          ],
          start,
          start,
        );
        final repository = FlightForecastRepository(client);
        final initial = await repository.load(query);
        expect(initial.series, hasLength(21));
        expect(requests, 2);
        final messages = <String?>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) =>
            messages.add(message);
        addTearDown(() => debugPrint = previousDebugPrint);
        blocked = true;
        repository.requestRefresh();
        final refreshed = await repository.load(query);
        expect(requests, 3);
        expect(refreshed.refreshFailed, isTrue);
        expect(refreshed.series, initial.series);
        expect(messages, ['Flight forecast requests stopped (HTTP $status).']);
      },
    );
  }

  test('manual refresh belongs to its queued load', () async {
    final start = DateTime.utc(2026, 11, 16, 14);
    final release = Completer<void>();
    final started = Completer<void>();
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      if (requests == 1) {
        started.complete();
        await release.future;
      }
      return http.Response(
        jsonEncode({
          'elevation': 100,
          'hourly': {
            'time': [start.millisecondsSinceEpoch ~/ 1000],
          },
        }),
        200,
      );
    });
    addTearDown(client.close);
    await withClock(Clock.fixed(start), () async {
      final repository = FlightForecastRepository(client);
      final query = ForecastQuery(
        [(latitude: 48.0, longitude: 17.0)],
        start,
        start,
      );
      final initial = repository.load(query);
      await started.future;
      final older = repository.load(query);
      repository.requestRefresh();
      final manual = repository.load(query);
      final ordinary = repository.load(query);
      release.complete();
      await initial;
      await older;
      expect(requests, 1);
      await manual;
      await ordinary;
      expect(requests, 2);
    });
  });

  test(
    'query freezes keys and compares their sets independently of coordinates',
    () {
      final start = DateTime.utc(2026, 11, 16);
      final locations = [(latitude: 48.0, longitude: 17.0)];
      final query = ForecastQuery(locations, start, start);
      locations.clear();
      expect(query.locations, hasLength(1));
      expect(() => query.locations.clear(), throwsUnsupportedError);
      final equivalent = ForecastQuery(
        [(latitude: 48.000001, longitude: 17.0)],
        start,
        start,
      );
      expect(query, equivalent);
      expect(query.hashCode, equivalent.hashCode);
    },
  );

  test('quantizes nearby positions into one profile key', () {
    const base = (latitude: 48.17, longitude: 17.21);
    const nearby = (latitude: 48.171, longitude: 17.211);
    const distant = (latitude: 48.24, longitude: 17.21);

    expect(quantizeForecastLocation(nearby), quantizeForecastLocation(base));
    expect(
      quantizeForecastLocation(distant),
      isNot(quantizeForecastLocation(base)),
    );
  });

  test('drops profiles that are no longer part of the plan', () async {
    final start = DateTime.utc(2026, 11, 16, 14);
    final client = MockClient((request) async {
      final count = request.url.queryParameters['latitude']!.split(',').length;
      return http.Response(
        jsonEncode([
          for (var i = 0; i < count; i++)
            {
              'elevation': 165,
              'hourly': {
                'time': [start.millisecondsSinceEpoch ~/ 1000],
                'wind_gusts_10m': [18],
              },
            },
        ]),
        200,
      );
    });
    addTearDown(client.close);
    final repository = FlightForecastRepository(client);

    await repository.load(
      ForecastQuery(
        [
          (latitude: 48.17, longitude: 17.21),
          (latitude: 48.878, longitude: 19.226),
        ],
        start,
        start,
      ),
    );
    expect(repository.cachedProfileCount, 2);

    final result = await repository.load(
      ForecastQuery([(latitude: 48.17, longitude: 17.21)], start, start),
    );
    expect(repository.cachedProfileCount, 1);
    expect(result.series, hasLength(1));
  });
}
