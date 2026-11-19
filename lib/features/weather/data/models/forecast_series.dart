import 'dart:math' as math;

import '../../../../core/utils/aviation_math.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_profile.dart';

/// Open-Meteo request field names used by the forecast profiles.
const forecastModel = 'dwd_icon_eu_native';
const forecastPressureLevels = [
  1000,
  975,
  950,
  925,
  900,
  850,
  800,
  700,
  600,
  500,
];
const forecastWindHeights = [10, 80, 120, 180];
const forecastTemperatureHeights = [2, 80, 120, 180];
const forecastGustField = 'wind_gusts_10m';

/// Parsed Open-Meteo hourly profile: model elevation, timestamps and the raw
/// hourly columns. Interpolates wind, temperature, pressure and precipitation
/// for a requested time and altitude.
class ForecastSeries implements ForecastProfile {
  final double modelElevationMeters;
  final DateTime downloadedAt;
  final List<DateTime> times;
  final Map<String, List<dynamic>> _hourly;

  ForecastSeries._(
    this.modelElevationMeters,
    this.downloadedAt,
    this.times,
    this._hourly,
  );

  factory ForecastSeries.fromJson(
    Map<String, dynamic> json,
    DateTime downloadedAt,
  ) {
    if (json case {
      'elevation': num elevation,
      'hourly': Map<String, dynamic> hourly,
    }) {
      if (hourly case {'time': List<dynamic> timestamps}) {
        if (!elevation.isFinite || timestamps.any((t) => t is! int)) {
          throw const FormatException(
            'Invalid forecast timestamps or elevation',
          );
        }
        final columns = <String, List<dynamic>>{};
        for (final entry in hourly.entries) {
          if (entry.value case List<dynamic> values) {
            columns[entry.key] = List.unmodifiable(values);
          } else {
            throw const FormatException('Invalid forecast column');
          }
        }
        final times = timestamps
            .map(
              (t) => DateTime.fromMillisecondsSinceEpoch(
                (t as int) * 1000,
                isUtc: true,
              ),
            )
            .toList(growable: false);
        for (var i = 1; i < times.length; i++) {
          if (!times[i].isAfter(times[i - 1])) {
            throw const FormatException('Unordered forecast timestamps');
          }
        }
        return ForecastSeries._(
          elevation.toDouble(),
          downloadedAt,
          List.unmodifiable(times),
          Map.unmodifiable(columns),
        );
      }
    }
    throw const FormatException('Invalid forecast response');
  }

  @override
  bool covers(DateTime time) =>
      times.isNotEmpty &&
      !time.isBefore(times.first) &&
      !time.isAfter(times.last);

  double? _value(String key, int index) {
    final values = _hourly[key];
    if (values == null || index >= values.length) return null;
    final value = values[index];
    return value is num && value.isFinite ? value.toDouble() : null;
  }

  @override
  ForecastWind? windAt(
    DateTime time,
    double altitudeMeters, {
    double? terrainMeters,
  }) {
    final minimum = math.max(
      modelElevationMeters,
      terrainMeters ?? modelElevationMeters,
    );
    if (!covers(time) || altitudeMeters < minimum) return null;
    final next = times.indexWhere((t) => !t.isBefore(time));
    final b = _windAt(next, altitudeMeters, minimum);
    if (b == null || times[next].isAtSameMomentAs(time)) return b;
    final a = _windAt(next - 1, altitudeMeters, minimum);
    if (a == null) return null;
    final fraction =
        time.difference(times[next - 1]).inMilliseconds /
        times[next].difference(times[next - 1]).inMilliseconds;
    return a.interpolate(b, fraction);
  }

  @override
  FlightForecast? at(
    DateTime time, {
    double? altitudeMeters,
    double? terrainMeters,
    double? pressureReferenceMeters,
  }) {
    if (!covers(time)) return null;
    final next = times.indexWhere((t) => !t.isBefore(time));
    final previous = times[next].isAtSameMomentAs(time) ? next : next - 1;
    final fraction = previous == next
        ? 0.0
        : time.difference(times[previous]).inMilliseconds /
              times[next].difference(times[previous]).inMilliseconds;

    T? interpolateTime<T>(
      T? Function(int) atHour,
      T Function(T, T, double) mix,
    ) {
      final a = atHour(previous);
      if (a == null || previous == next) return a;
      final b = atHour(next);
      return b == null ? null : mix(a, b, fraction);
    }

    final minimumHeight = math.max(
      modelElevationMeters,
      terrainMeters ?? modelElevationMeters,
    );
    final canSampleAltitude =
        altitudeMeters != null && altitudeMeters >= minimumHeight;
    final wind = canSampleAltitude
        ? interpolateTime(
            (i) => _windAt(i, altitudeMeters, minimumHeight),
            (a, b, f) => a.interpolate(b, f),
          )
        : null;
    final temperature = canSampleAltitude
        ? interpolateTime(
            (i) => _temperatureAt(i, altitudeMeters, minimumHeight),
            linearInterpolate,
          )
        : null;

    // Hourly sums and maxima belong to the interval ending at the timestamp.
    final interval = times[next].isAtSameMomentAs(time) ? next + 1 : next;
    final hasInterval =
        interval < times.length &&
        !time.isBefore(times[interval].subtract(const Duration(hours: 1)));
    final surfacePressure = interpolateTime(
      (i) => _value('surface_pressure', i),
      linearInterpolate,
    );
    final surfaceTemperature = interpolateTime(
      (i) => _value('temperature_2m', i),
      linearInterpolate,
    );
    final elevation = pressureReferenceMeters ?? modelElevationMeters;
    double? referencePressure = surfacePressure;
    if (pressureReferenceMeters != null && elevation != modelElevationMeters) {
      referencePressure = surfacePressure == null || surfaceTemperature == null
          ? null
          : surfacePressure *
                math.exp(
                  -9.80665 *
                      (elevation - modelElevationMeters) /
                      (287.05 * (surfaceTemperature + 273.15)),
                );
    }
    final gustKmh = hasInterval ? _value(forecastGustField, interval) : null;
    return FlightForecast(
      // Weather codes describe an instant; ties select the later timestamp.
      weatherCode: _value(
        'weather_code',
        fraction < 0.5 ? previous : next,
      )?.toInt(),
      wind: wind,
      temperatureC: temperature,
      gustMs: gustKmh == null ? null : gustKmh / 3.6,
      precipitationMm: hasInterval ? _value('precipitation', interval) : null,
      lowCloudPercent: interpolateTime(
        (i) => _value('cloud_cover_low', i),
        linearInterpolate,
      ),
      qnhHpa: referencePressure == null
          ? null
          : AviationMath.altitudeToQnhHpa(referencePressure * 100, elevation),
      qfeHpa: pressureReferenceMeters == null ? null : referencePressure,
      intervalEnd: hasInterval ? times[interval] : null,
      downloadedAt: downloadedAt,
    );
  }

  Iterable<({int pressure, double height})> _pressureHeights(
    int index,
    double minimumHeight,
  ) sync* {
    final surfacePressure = _value('surface_pressure', index);
    if (surfacePressure == null) return;
    for (final pressure in forecastPressureLevels) {
      final height = _value('geopotential_height_${pressure}hPa', index);
      if (pressure <= surfacePressure &&
          height != null &&
          height >= minimumHeight) {
        yield (pressure: pressure, height: height);
      }
    }
  }

  ForecastWind? _windAt(int index, double altitude, double minimumHeight) {
    final samples = <double, ForecastWind>{};
    void add(double height, String suffix) {
      final speed = _value('wind_speed_$suffix', index);
      final direction = _value('wind_direction_$suffix', index);
      if (speed != null && direction != null) {
        samples[height] = ForecastWind.fromKmh(speed, direction);
      }
    }

    for (final level in _pressureHeights(index, minimumHeight)) {
      add(level.height, '${level.pressure}hPa');
    }
    for (final height in forecastWindHeights) {
      final elevation = modelElevationMeters + height;
      if (elevation >= minimumHeight) add(elevation, '${height}m');
    }
    return _atHeight(samples, altitude, (a, b, f) => a.interpolate(b, f));
  }

  double? _temperatureAt(int index, double altitude, double minimumHeight) {
    final samples = <double, double>{};
    void add(double height, String suffix) {
      final value = _value('temperature_$suffix', index);
      if (value != null) samples[height] = value;
    }

    for (final level in _pressureHeights(index, minimumHeight)) {
      add(level.height, '${level.pressure}hPa');
    }
    for (final height in forecastTemperatureHeights) {
      final elevation = modelElevationMeters + height;
      if (elevation >= minimumHeight) add(elevation, '${height}m');
    }
    return _atHeight(samples, altitude, linearInterpolate);
  }

  T? _atHeight<T extends Object>(
    Map<double, T> samples,
    double height,
    T Function(T, T, double) mix,
  ) {
    final exact = samples[height];
    if (exact != null) return exact;
    final heights = samples.keys.toList()..sort();
    final upper = heights.indexWhere((value) => value > height);
    if (upper <= 0) return null;
    final below = heights[upper - 1];
    final above = heights[upper];
    return mix(
      samples[below]!,
      samples[above]!,
      (height - below) / (above - below),
    );
  }
}
