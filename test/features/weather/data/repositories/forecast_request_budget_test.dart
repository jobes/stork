import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stork/core/utils/geo_utils.dart';
import 'package:stork/features/weather/data/repositories/flight_forecast_repository.dart';
import 'package:stork/features/weather/domain/flight_forecast.dart';
import 'package:stork/features/weather/domain/forecast_query.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';

final _start = DateTime.utc(2026, 11, 16, 8);
const _origin = (latitude: 48.0, longitude: 17.0);
const _metersPerDegreeLatitude = 111320.0;
const _cruiseSpeedMs = 100 / 3.6;

typedef _Budget = ({
  int requests,
  int locations,
  int originUpdates,
  int refreshes,
});

/// Simulates a flight along the route and drives the real repository with a
/// counting HTTP client. The old policy is approximated with the previous
/// grid-based origin lookup and 30-minute forced refreshes.
Future<_Budget> _simulate({
  required int minutes,
  required bool latchedOrigin,
  required bool legacyRefresh,
}) async {
  var requests = 0;
  var locations = 0;
  var originUpdates = 0;
  var refreshes = 0;
  final hourlyStart = _start.subtract(const Duration(hours: 2));
  final hourly = [
    for (var i = 0; i <= 12; i++)
      hourlyStart.add(Duration(hours: i)).millisecondsSinceEpoch ~/ 1000,
  ];
  final client = MockClient((request) async {
    requests++;
    final count = request.url.queryParameters['latitude']!.split(',').length;
    locations += count;
    return http.Response(
      jsonEncode([
        for (var i = 0; i < count; i++)
          {
            'elevation': 165,
            'hourly': {'time': hourly},
          },
      ]),
      200,
    );
  });

  // A single destination keeps the plan geometry fixed while the simulated
  // aircraft advances along the route.
  final ForecastWaypoint destination = (
    latitude:
        _origin.latitude +
        _cruiseSpeedMs * 60 * minutes / _metersPerDegreeLatitude,
    longitude: _origin.longitude,
    altitudeFeet: null,
  );
  final waypoints = [destination];
  final plan = ForecastRoute.plan(_origin, waypoints, _cruiseSpeedMs);
  final repository = FlightForecastRepository(client);
  var now = _start;
  var latched = _origin;

  try {
    await withClock(Clock(() => now), () async {
      for (var minute = 0; minute <= minutes; minute++) {
        now = _start.add(Duration(minutes: minute));
        final position = (
          latitude:
              _origin.latitude +
              _cruiseSpeedMs * 60 * minute / _metersPerDegreeLatitude,
          longitude: _origin.longitude,
        );

        if (latchedOrigin) {
          if (minute == 0 ||
              GeoUtils.distanceBetween(
                    latched.latitude,
                    latched.longitude,
                    position.latitude,
                    position.longitude,
                  ) >=
                  forecastOriginRefreshDistanceMeters) {
            if (minute > 0) originUpdates++;
            latched = position;
          }
        } else if (minute == 0 ||
            forecastLocationKey(quantizeForecastLocation(latched)) !=
                forecastLocationKey(quantizeForecastLocation(position))) {
          if (minute > 0) originUpdates++;
          latched = position;
        }

        final points = plan.forecastPoints(
          position: position,
          points: waypoints,
          departure: now,
          groundSpeed: _cruiseSpeedMs,
          flying: true,
          defaultAltitudeFeet: 2000,
        );
        final firstEta = points.first.eta;
        final lastEta = points.fold(
          firstEta,
          (last, point) => point.eta.isAfter(last) ? point.eta : last,
        );
        DateTime hour(DateTime value) =>
            DateTime.utc(value.year, value.month, value.day, value.hour);
        final query = ForecastQuery(
          [
            quantizeForecastLocation(latched),
            for (final point in points.skip(1)) point.location,
          ],
          hour(firstEta).subtract(forecastTimeReserve),
          hour(lastEta).add(forecastTimeReserve + const Duration(hours: 1)),
        );

        if (legacyRefresh && minute > 0 && minute % 30 == 0) {
          refreshes++;
          repository.requestRefresh();
        }
        await repository.load(query);
      }
    });
  } finally {
    client.close();
  }

  return (
    requests: requests,
    locations: locations,
    originUpdates: originUpdates,
    refreshes: refreshes,
  );
}

void main() {
  test('measures the request budget on a simulated route', () async {
    final twoHoursNew = await _simulate(
      minutes: 120,
      latchedOrigin: true,
      legacyRefresh: false,
    );
    final twoHoursOld = await _simulate(
      minutes: 120,
      latchedOrigin: false,
      legacyRefresh: true,
    );
    final fourHoursNew = await _simulate(
      minutes: 240,
      latchedOrigin: true,
      legacyRefresh: false,
    );
    final fourHoursOld = await _simulate(
      minutes: 240,
      latchedOrigin: false,
      legacyRefresh: true,
    );

    // New: latch after 10 km, refresh when profiles are two hours old.
    // Old: request every grid-cell crossing, force a refresh every 30 min.
    // ignore: avoid_print
    print(
      '100 km/h\n'
      '2 h / 200 km  new: ${twoHoursNew.requests} requests, '
      '${twoHoursNew.locations} locations, '
      '${twoHoursNew.originUpdates} origin updates; '
      'old: ${twoHoursOld.requests} requests, '
      '${twoHoursOld.locations} locations, '
      '${twoHoursOld.originUpdates} origin updates\n'
      '4 h / 400 km  new: ${fourHoursNew.requests} requests, '
      '${fourHoursNew.locations} locations, '
      '${fourHoursNew.originUpdates} origin updates; '
      'old: ${fourHoursOld.requests} requests, '
      '${fourHoursOld.locations} locations, '
      '${fourHoursOld.originUpdates} origin updates',
    );

    expect(twoHoursNew.originUpdates, lessThan(twoHoursOld.originUpdates));
    expect(twoHoursNew.requests, lessThan(twoHoursOld.requests));
    expect(fourHoursNew.originUpdates, lessThan(fourHoursOld.originUpdates));
    expect(fourHoursNew.requests, lessThan(fourHoursOld.requests));
  });
}
