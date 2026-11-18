import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stork/features/weather/data/repositories/flight_forecast_repository.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';

void main() {
  test(
    'batches locations, reuses hourly profiles and keeps them for a failed refresh',
    () async {
      final start = DateTime.utc(2026, 11, 16, 14);
      var now = start;
      var requestCount = 0;
      var offline = false;
      final client = MockClient((request) async {
        requestCount++;
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.queryParameters['models'], 'dwd_icon_eu_native');
        expect(request.url.queryParameters['latitude'], '48.1700,48.8780');
        expect(
          request.url.queryParameters['hourly'],
          contains('wind_gusts_10m'),
        );
        if (offline) return http.Response('offline', 503);
        return http.Response(
          jsonEncode([
            for (final height in [165, 996])
              {
                'elevation': height,
                'hourly': {
                  'time': [
                    start.millisecondsSinceEpoch ~/ 1000,
                    start
                            .add(const Duration(hours: 1))
                            .millisecondsSinceEpoch ~/
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
        now = start.add(const Duration(minutes: 35));
        final refreshed = await repository.load(query);
        expect(requestCount, 2);
        expect(refreshed.refreshFailed, isTrue);
        expect(refreshed.series.values.first.at(now)!.gustMs, 10);
        expect(
          refreshed.series.values.first.at(start.add(const Duration(hours: 2))),
          isNull,
        );
      });
    },
  );

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
    },
  );

  test('reuses one profile location within a ~3 km grid cell', () {
    const base = (latitude: 48.17, longitude: 17.21);
    const nearby = (latitude: 48.171, longitude: 17.211);
    const distant = (latitude: 48.24, longitude: 17.21);
    final eta = DateTime.utc(2026, 11, 16, 14);

    expect(quantizeForecastLocation(nearby), quantizeForecastLocation(base));
    expect(
      quantizeForecastLocation(distant),
      isNot(quantizeForecastLocation(base)),
    );

    ForecastRoutePoint point(
      String id,
      ({double latitude, double longitude}) location,
    ) => ForecastRoutePoint(
      id: id,
      location: location,
      eta: eta,
      duration: Duration.zero,
      distanceMeters: 0,
      altitudeFeet: null,
    );

    expect(
      forecastProfileLocation(point('origin', base)),
      quantizeForecastLocation(base),
    );
    expect(forecastProfileLocation(point('waypoint-0', nearby)), nearby);
  });
}
