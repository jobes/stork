import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/weather/data/models/forecast_series.dart';
import 'package:stork/features/weather/domain/forecast_profile.dart';

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

  test('resolves terrain and airport references with one shared rule', () {
    final blockedByTerrain = series.atReference(
      time,
      altitudeFeet: 3609,
      reference: (terrainMeters: 1150, airportMeters: 1000),
    )!;
    expect(blockedByTerrain.wind, isNull);

    final airportReference = series.atReference(
      time,
      altitudeFeet: 3609,
      reference: (terrainMeters: null, airportMeters: 1000),
    )!;
    expect(airportReference.wind, isNotNull);
    expect(airportReference.qfeHpa, isNotNull);
  });
}
