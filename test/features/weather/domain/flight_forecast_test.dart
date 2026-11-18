import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/weather/domain/flight_forecast.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';

void main() {
  final time = DateTime.utc(2026, 11, 16, 14);
  late ForecastSeries series;

  setUp(() {
    series = ForecastSeries.fromJson({
      'elevation': 950,
      'hourly': {
        'time': [
          for (var i = 0; i < 3; i++)
            time.add(Duration(hours: i)).millisecondsSinceEpoch ~/ 1000,
        ],
        'surface_pressure': [900, 901, 900],
        'temperature_2m': [10, 12, 10],
        'wind_speed_925hPa': [200, 200, 200],
        'wind_direction_925hPa': [180, 180, 180],
        'geopotential_height_925hPa': [900, 900, 900],
        'wind_speed_80m': [36, 36, 36],
        'wind_direction_80m': [350, 10, 350],
        'wind_speed_850hPa': [36, 36, 36],
        'wind_direction_850hPa': [350, 10, 350],
        'geopotential_height_850hPa': [1300, 1400, 1300],
        'wind_gusts_10m': [18, 36, 72],
        'precipitation': [1, 2, 4],
      },
    }, time);
  });

  test(
    'samples near-surface and pressure levels through north and over time',
    () {
      final forecast = series.at(
        time.add(const Duration(minutes: 30)),
        altitudeMeters: 1150,
      )!;

      expect(forecast.wind!.speedMs, closeTo(9.848, 0.001));
      expect(forecast.wind!.directionFrom % 360, closeTo(0, 0.001));
      expect(forecast.gustMs, 10);
      expect(forecast.precipitationMm, 2);
      expect(forecast.intervalEnd, time.add(const Duration(hours: 1)));
    },
  );

  test(
    'excludes samples below terrain and outside the profile or time range',
    () {
      final forecast = series.at(time, altitudeMeters: 1020)!;
      expect(forecast.wind, isNull);
      expect(
        series.at(time, altitudeMeters: 1100, terrainMeters: 1150)!.wind,
        isNull,
      );
      expect(series.at(time, altitudeMeters: 1500)!.wind, isNull);
      expect(series.at(time.subtract(const Duration(minutes: 1))), isNull);
    },
  );

  test('requires a ground reference for QFE and uses the surface for QNH', () {
    final withoutTerrain = series.at(time)!;
    final atModelElevation = series.at(time, pressureReferenceMeters: 950)!;
    final higherAirport = series.at(time, pressureReferenceMeters: 1000)!;

    expect(withoutTerrain.qfeHpa, isNull);
    expect(withoutTerrain.qnhHpa, greaterThan(900));
    expect(atModelElevation.qfeHpa, 900);
    expect(atModelElevation.qnhHpa, closeTo(withoutTerrain.qnhHpa!, 0.01));
    expect(higherAirport.qfeHpa, lessThan(900));
    expect(higherAirport.qnhHpa, greaterThan(higherAirport.qfeHpa!));
  });

  test('uses gust maximum for the hour starting at the ETA boundary', () {
    expect(series.at(time)!.gustMs, 10);
    expect(series.at(time.add(const Duration(hours: 1)))!.gustMs, 20);
    expect(series.at(time.add(const Duration(hours: 2)))!.gustMs, isNull);
  });

  test('places stable 10-minute route samples and interpolates climb', () {
    const origin = (latitude: 48.0, longitude: 17.0);
    const waypoints = [
      NavigationPoint(
        latitude: 48.18,
        longitude: 17,
        name: 'A',
        weatherAltitudeFeet: 4000,
      ),
      NavigationPoint(
        latitude: 48.43,
        longitude: 17,
        name: 'B',
        weatherAltitudeFeet: 2000,
      ),
    ];
    final plan = ForecastRoute.plan(origin, waypoints, 20);
    final before = plan.forecastPoints(
      position: origin,
      points: waypoints,
      departure: time,
      groundSpeed: 20,
      flying: false,
      defaultAltitudeFeet: 2000,
    );
    final first = before.firstWhere((point) => point.id == 'sample-0');
    expect(first.duration, const Duration(minutes: 10));
    expect(first.altitudeFeet, closeTo(3200, 2));
    final during = plan.forecastPoints(
      position: (latitude: 48.01, longitude: 17),
      points: waypoints,
      departure: time,
      groundSpeed: 35,
      flying: true,
      defaultAltitudeFeet: 2000,
    );
    final sameSample = during.firstWhere((point) => point.id == first.id);
    expect(sameSample.location, first.location);
    expect(sameSample.duration, lessThan(first.duration));

    final remaining = waypoints.skip(1).toList();
    expect(plan.matches(remaining), isTrue);
    final after = plan.forecastPoints(
      position: (latitude: 48.18, longitude: 17),
      points: remaining,
      departure: time,
      groundSpeed: 20,
      flying: true,
      defaultAltitudeFeet: 2000,
      previousWaypointAltitudeFeet: 4000,
    );
    expect(after.any((point) => point.id == first.id), isFalse);
    expect(
      after.firstWhere((point) => point.waypointIndex == 0).id,
      'waypoint-1',
    );
    expect(after.first.altitudeFeet, 4000);
  });
}
