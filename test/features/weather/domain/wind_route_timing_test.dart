import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/weather/domain/flight_forecast.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/domain/wind_route_timing.dart';

final _departure = DateTime.utc(2026, 11, 16, 14);

ForecastRoutePoint _point(
  String id,
  double distance,
  double latitude, {
  int? index,
}) => ForecastRoutePoint(
  id: id,
  location: (latitude: latitude, longitude: 17),
  eta: _departure,
  duration: Duration.zero,
  distanceMeters: distance,
  altitudeFeet: 2500,
  waypointIndex: index,
);

void main() {
  test(
    'anchors both headings to GPS even when the forecast wind is biased',
    () {
      final wind = ForecastWind.fromKmh(5, 0);

      for (final (track, gps, estimatedTas) in [
        (0.0, 100.0, 105.0),
        (180.0, 120.0, 115.0),
      ]) {
        final measurement = (speedMs: gps / 3.6, bearing: track);
        final tas = tasFromGroundTrack(measurement, wind);
        expect(tas * 3.6, closeTo(estimatedTas, 0.001));
        expect(
          groundSpeedForTrack(tas, wind, track)! * 3.6,
          closeTo(gps, 0.001),
        );

        final timing = calculateWindRouteTiming(
          points: [
            _point('origin', 0, 48),
            _point('finish', gps * 100, track == 0 ? 49 : 47, index: 0),
          ],
          profileTas: 110 / 3.6,
          gpsSpeed: gps / 3.6,
          groundTrack: measurement,
          currentAltitudeMeters: 762,
          windAt: (_, _, _) => wind,
        );
        expect(timing['finish']!.duration, const Duration(minutes: 6));
        expect(timing['finish']!.sources, {
          RouteTimingSource.gps,
          RouteTimingSource.wind,
        });
      }
    },
  );

  test('uses profile TAS on a later reciprocal leg', () {
    final timing = calculateWindRouteTiming(
      points: [
        _point('origin', 0, 48),
        _point('turn', 20000, 49, index: 0),
        _point('finish', 40000, 48, index: 1),
      ],
      profileTas: 110 / 3.6,
      gpsSpeed: 100 / 3.6,
      groundTrack: (speedMs: 100 / 3.6, bearing: 0),
      currentAltitudeMeters: 762,
      windAt: (_, _, _) => ForecastWind.fromKmh(5, 0),
    );
    expect(timing['turn']!.duration, const Duration(minutes: 12));
    expect(timing['finish']!.duration, const Duration(seconds: 1346));
  });

  test('plans through forecast wind and adjusts time along the route', () {
    final readTimes = <DateTime>[];
    final timing = calculateWindRouteTiming(
      points: [
        _point('origin', 0, 48),
        _point('midpoint', 30000, 48.5),
        _point('finish', 60000, 49, index: 0),
      ],
      profileTas: 100 / 3.6,
      gpsSpeed: null,
      groundTrack: null,
      currentAltitudeMeters: null,
      windAt: (point, time, altitude) {
        readTimes.add(time);
        expect(altitude, 762);
        return ForecastWind.fromKmh(20, 0);
      },
    );
    expect(
      timing['midpoint']!.eta,
      _departure.add(const Duration(minutes: 22, seconds: 30)),
    );
    expect(timing['finish']!.duration, const Duration(minutes: 45));
    expect(timing['finish']!.windEffect, const Duration(minutes: 9));
    expect(readTimes[2].isAfter(readTimes[0]), isTrue);
  });

  test(
    'crosswind reduces along-track speed and impossible progress has no ETA',
    () {
      expect(
        groundSpeedForTrack(10, const ForecastWind(6, 0), 0),
        closeTo(8, 0.001),
      );
      final timing = calculateWindRouteTiming(
        points: [
          _point('origin', 0, 48),
          _point('first', 10000, 48.1, index: 0),
          _point('finish', 20000, 48.2, index: 1),
        ],
        profileTas: 10,
        gpsSpeed: null,
        groundTrack: null,
        currentAltitudeMeters: null,
        windAt: (_, _, _) => const ForecastWind(0, -11),
      );
      expect(timing['first']!.eta, isNull);
      expect(timing['finish']!.duration, isNull);
      expect(timing['finish']!.sources, {RouteTimingSource.blocked});
    },
  );

  test(
    'uses the existing GPS estimate for a segment without forecast data',
    () {
      final timing = calculateWindRouteTiming(
        points: [
          _point('origin', 0, 48),
          _point('finish', 10000, 48.1, index: 0),
        ],
        profileTas: 40,
        gpsSpeed: 20,
        groundTrack: null,
        currentAltitudeMeters: null,
        windAt: (_, _, _) => null,
      );
      expect(timing['finish']!.duration, const Duration(seconds: 500));
      expect(timing['finish']!.sources, {RouteTimingSource.gps});
      expect(timing['finish']!.windEffect, isNull);
    },
  );
}
