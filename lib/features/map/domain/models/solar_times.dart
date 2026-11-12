import 'dart:math' as math;

enum SolarEvent {
  civilDawn(96, true),
  sunrise(90.833, true),
  sunset(90.833, false),
  civilDusk(96, false);

  const SolarEvent(this.zenith, this.rising);

  final double zenith;
  final bool rising;
}

typedef SolarCrossing = ({SolarEvent event, DateTime time});

class SolarTimes {
  const SolarTimes.empty() : crossings = const [];

  SolarTimes._(List<SolarCrossing> crossings)
    : crossings = List.unmodifiable(crossings);

  /// All crossings in chronological order. A local day can contain more
  /// than one occurrence of the same event.
  final List<SolarCrossing> crossings;

  DateTime? firstTimeOf(SolarEvent event) {
    for (final crossing in crossings) {
      if (crossing.event == event) return crossing.time;
    }
    return null;
  }
}

({SolarCrossing crossing, bool tomorrow})? nextCivilTwilight({
  required DateTime now,
  required SolarTimes today,
  required SolarTimes tomorrow,
}) {
  for (final (times, isTomorrow) in [(today, false), (tomorrow, true)]) {
    for (final crossing in times.crossings) {
      if ((crossing.event == SolarEvent.civilDawn ||
              crossing.event == SolarEvent.civilDusk) &&
          crossing.time.isAfter(now)) {
        return (crossing: crossing, tomorrow: isTomorrow);
      }
    }
  }
  return null;
}

const _radiansPerDegree = math.pi / 180;
const _sampleStep = Duration.millisecondsPerHour;

/// Calculates UTC events within one local calendar day's instant range.
/// Latitude and longitude are in degrees, positive north and east.
SolarTimes calculateSolarTimes({
  required double latitude,
  required double longitude,
  required DateTime start,
  required DateTime end,
}) {
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180 ||
      !start.isBefore(end)) {
    return const SolarTimes.empty();
  }

  final first = start.millisecondsSinceEpoch;
  final last = end.millisecondsSinceEpoch;
  final latitudeRadians = latitude * _radiansPerDegree;
  final sinLatitude = math.sin(latitudeRadians);
  final cosLatitude = math.cos(latitudeRadians);

  double elevationSine(int milliseconds) {
    final (declination, equationOfTime) = _solarPosition(
      2440587.5 + milliseconds / Duration.millisecondsPerDay,
    );
    final utcMinutes =
        (milliseconds % Duration.millisecondsPerDay) /
        Duration.millisecondsPerMinute;
    final hourAngle =
        ((utcMinutes + equationOfTime + 4 * longitude) / 4 - 180) *
        _radiansPerDegree;
    return sinLatitude * math.sin(declination) +
        cosLatitude * math.cos(declination) * math.cos(hourAngle);
  }

  // Sample beyond both bounds to locate extrema near local midnight. Refine
  // each extremum so a brief dip below (or rise above) a twilight threshold
  // can be found even when both hourly samples are on the same side.
  final hourly = [
    for (
      var time = first - _sampleStep;
      time < last + 2 * _sampleStep;
      time += _sampleStep
    )
      (time: time, elevation: elevationSine(time)),
  ];
  final samples = [...hourly];
  for (var i = 1; i < hourly.length - 1; i++) {
    final previous = hourly[i - 1];
    final current = hourly[i];
    final next = hourly[i + 1];
    final maximum =
        current.elevation >= previous.elevation &&
        current.elevation > next.elevation;
    final minimum =
        current.elevation <= previous.elevation &&
        current.elevation < next.elevation;
    if (maximum || minimum) {
      final time = _extremum(
        previous.time,
        next.time,
        elevationSine,
        maximum: maximum,
      );
      samples.add((time: time, elevation: elevationSine(time)));
    }
  }
  samples.sort((a, b) => a.time.compareTo(b.time));

  final crossings = <SolarCrossing>[];
  final thresholds = {
    for (final event in SolarEvent.values)
      event: math.cos(event.zenith * _radiansPerDegree),
  };
  for (var i = 1; i < samples.length; i++) {
    final left = samples[i - 1];
    final right = samples[i];
    if (right.time < first || left.time >= last) continue;
    for (final event in SolarEvent.values) {
      final threshold = thresholds[event]!;
      final leftAbove = left.elevation >= threshold;
      final rightAbove = right.elevation >= threshold;
      if (leftAbove == rightAbove || rightAbove != event.rising) continue;

      var before = left.time;
      var after = right.time;
      while (after - before > 1) {
        final middle = before + (after - before) ~/ 2;
        if ((elevationSine(middle) >= threshold) == leftAbove) {
          before = middle;
        } else {
          after = middle;
        }
      }
      if (after >= first && after < last) {
        crossings.add((
          event: event,
          time: DateTime.fromMillisecondsSinceEpoch(after, isUtc: true),
        ));
      }
    }
  }
  crossings.sort((a, b) => a.time.compareTo(b.time));
  return SolarTimes._(crossings);
}

int _extremum(
  int left,
  int right,
  double Function(int) elevation, {
  required bool maximum,
}) {
  while (right - left > 3) {
    final third = (right - left) ~/ 3;
    final a = left + third;
    final b = right - third;
    if ((elevation(a) < elevation(b)) == maximum) {
      left = a;
    } else {
      right = b;
    }
  }
  return left + (right - left) ~/ 2;
}

// NOAA's solar calculator uses Meeus's solar position equations:
// https://gml.noaa.gov/grad/solcalc/calcdetails.html
(double declination, double equationOfTime) _solarPosition(double julianDay) {
  final century = (julianDay - 2451545) / 36525;
  final meanLongitude =
      (280.46646 + century * (36000.76983 + century * 0.0003032)) % 360;
  final anomaly =
      (357.52911 + century * (35999.05029 - 0.0001537 * century)) *
      _radiansPerDegree;
  final eccentricity =
      0.016708634 - century * (0.000042037 + 0.0000001267 * century);
  final center =
      math.sin(anomaly) *
          (1.914602 - century * (0.004817 + 0.000014 * century)) +
      math.sin(2 * anomaly) * (0.019993 - 0.000101 * century) +
      math.sin(3 * anomaly) * 0.000289;
  final omega = (125.04 - 1934.136 * century) * _radiansPerDegree;
  final apparentLongitude =
      (meanLongitude + center - 0.00569 - 0.00478 * math.sin(omega)) *
      _radiansPerDegree;
  final obliquity =
      (23 +
          (26 +
                  (21.448 -
                          century *
                              (46.815 +
                                  century * (0.00059 - century * 0.001813))) /
                      60) /
              60 +
          0.00256 * math.cos(omega)) *
      _radiansPerDegree;
  final declination = math.asin(
    math.sin(obliquity) * math.sin(apparentLongitude),
  );
  final longitude = meanLongitude * _radiansPerDegree;
  final tangent = math.tan(obliquity / 2);
  final y = tangent * tangent;
  final equationOfTime =
      y * math.sin(2 * longitude) -
      2 * eccentricity * math.sin(anomaly) +
      4 * eccentricity * y * math.sin(anomaly) * math.cos(2 * longitude) -
      0.5 * y * y * math.sin(4 * longitude) -
      1.25 * eccentricity * eccentricity * math.sin(2 * anomaly);
  return (declination, 4 * equationOfTime / _radiansPerDegree);
}
