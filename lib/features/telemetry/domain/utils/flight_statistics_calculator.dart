import '../../../../core/utils/geo_utils.dart';
import '../models/flight_statistics.dart';
import '../models/telemetry_entry.dart';

class FlightStatisticsCalculator {
  double ascent = 0.0;
  double descent = 0.0;
  double totalDist = 0.0;
  double maxDistFromTakeoff = 0.0;

  double? maxAlt;
  double? maxGs;
  double? maxIas;

  double? takeoffLat;
  double? takeoffLon;
  double? lastLat;
  double? lastLon;
  double? lastAlt;
  int validAltCount = 0;

  double altTimeSum = 0.0;
  double altTimeTotal = 0.0;
  double gsTimeSum = 0.0;
  double gsTimeTotal = 0.0;
  double iasTimeSum = 0.0;
  double iasTimeTotal = 0.0;
  double rpmTimeSum = 0.0;
  double rpmTimeTotal = 0.0;

  double? currentAlt;
  double? currentGs;
  double? currentIas;
  double? currentRpm;
  double? currentLat;
  double? currentLon;

  DateTime? lastTimestamp;

  void addEntries(List<TelemetryEntry> entries) {
    for (final entry in entries) {
      final timestamp = entry.timestamp;

      final alt = entry.data['gps_altitude'] as double?;
      final gs = entry.data['ground_speed'] as double?;
      final ias = entry.data['indicated_air_speed'] as double?;
      final rpm = entry.data['engine_rpm'] as double?;
      final lat = entry.data['latitude'] as double?;
      final lon = entry.data['longitude'] as double?;

      if (lastTimestamp != null) {
        final dt =
            timestamp.difference(lastTimestamp!).inMilliseconds.toDouble() /
            1000.0;
        if (dt > 0) {
          if (currentAlt != null) {
            altTimeSum += currentAlt! * dt;
            altTimeTotal += dt;
          }
          if (currentGs != null) {
            gsTimeSum += currentGs! * dt;
            gsTimeTotal += dt;
          }
          if (currentIas != null) {
            iasTimeSum += currentIas! * dt;
            iasTimeTotal += dt;
          }
          if (currentRpm != null) {
            rpmTimeSum += currentRpm! * dt;
            rpmTimeTotal += dt;
          }
        }
      }

      if (alt != null) {
        currentAlt = alt;
        if (maxAlt == null || alt > maxAlt!) maxAlt = alt;

        if (lastAlt != null) {
          final diff = alt - lastAlt!;
          if (diff > 0) {
            ascent += diff;
          } else {
            descent += diff.abs();
          }
        }
        lastAlt = alt;
        validAltCount++;
      }

      if (gs != null) {
        currentGs = gs;
        if (maxGs == null || gs > maxGs!) maxGs = gs;
      }

      if (ias != null) {
        currentIas = ias;
        if (maxIas == null || ias > maxIas!) maxIas = ias;
      }

      if (rpm != null) {
        currentRpm = rpm;
      }

      if (lat != null) {
        currentLat = lat;
      }
      if (lon != null) {
        currentLon = lon;
      }

      if (lat != null || lon != null) {
        final cLat = currentLat;
        final cLon = currentLon;
        if (cLat != null && cLon != null) {
          final tLat = takeoffLat;
          final tLon = takeoffLon;
          if (tLat == null || tLon == null) {
            takeoffLat = cLat;
            takeoffLon = cLon;
          } else {
            final distFromTakeoff = GeoUtils.distanceBetween(
              tLat,
              tLon,
              cLat,
              cLon,
            );
            if (distFromTakeoff > maxDistFromTakeoff) {
              maxDistFromTakeoff = distFromTakeoff;
            }
          }

          final lLat = lastLat;
          final lLon = lastLon;
          if (lLat != null && lLon != null) {
            final stepDist = GeoUtils.distanceBetween(
              lLat,
              lLon,
              cLat,
              cLon,
            );
            totalDist += stepDist;
          }
          lastLat = cLat;
          lastLon = cLon;
        }
      }

      lastTimestamp = timestamp;
    }
  }

  FlightStatistics getStatistics() {
    final avgAlt = altTimeTotal > 0 ? altTimeSum / altTimeTotal : currentAlt;
    final avgGs = gsTimeTotal > 0 ? gsTimeSum / gsTimeTotal : currentGs;
    final avgIas = iasTimeTotal > 0 ? iasTimeSum / iasTimeTotal : currentIas;
    final avgRpm = rpmTimeTotal > 0 ? rpmTimeSum / rpmTimeTotal : currentRpm;

    return FlightStatistics(
      maxAltitude: maxAlt,
      totalAscent: validAltCount > 1 ? ascent : null,
      totalDescent: validAltCount > 1 ? descent : null,
      avgAltitude: avgAlt,
      maxGroundSpeed: maxGs,
      maxIndicatedAirSpeed: maxIas,
      avgGroundSpeed: avgGs,
      avgIndicatedAirSpeed: avgIas,
      totalDistance:
          (lastLat != null && lastLon != null && totalDist > 0)
              ? totalDist
              : null,
      maxDistanceFromTakeoff:
          (takeoffLat != null && takeoffLon != null && maxDistFromTakeoff > 0)
              ? maxDistFromTakeoff
              : null,
      avgEngineRPM: avgRpm,
    );
  }
}
