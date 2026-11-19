import 'dart:convert';
import 'dart:math' as math;
import 'package:maplibre/maplibre.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../navigation/domain/models/navigation_state.dart';
import '../../settings/domain/models/app_settings.dart';
import '../../telemetry/domain/models/telemetry_state.dart';

/// A utility class for constructing GeoJSON strings required by MapLibre sources.
class GeoJsonBuilder {
  /// Draw saved legs independently of GPS. An optional known position adds
  /// the connector to the first waypoint without publishing a new GPS fix.
  static String buildNavigationRouteGeoJson(
    NavigationState? navigation, {
    Geographic? origin,
  }) {
    const empty = '{"type":"FeatureCollection","features":[]}';
    if (navigation == null ||
        !navigation.isActive ||
        navigation.points.isEmpty) {
      return empty;
    }
    final points = [
      ?GeoUtils.validatedPosition(origin?.lat, origin?.lon),
      for (final point in navigation.points)
        Geographic(lat: point.latitude, lon: point.longitude),
    ];
    final coordinates = <List<double>>[];
    for (var i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final leg = _interpolateGreatCircle(
        start.lat,
        start.lon,
        end.lat,
        end.lon,
      );
      if (leg == null || leg.isEmpty) continue;
      coordinates.addAll(coordinates.isEmpty ? leg : leg.skip(1));
    }
    if (coordinates.length < 2) return empty;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {'type': 'LineString', 'coordinates': coordinates},
        },
      ],
    });
  }

  static List<List<double>>? _interpolateGreatCircle(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) {
      return null;
    }

    final lat1Rad = lat1 * math.pi / 180.0;
    final lon1Rad = lon1 * math.pi / 180.0;
    final lat2Rad = lat2 * math.pi / 180.0;
    final lon2Rad = lon2 * math.pi / 180.0;

    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;
    final sinLatSq = math.sin(dLat / 2) * math.sin(dLat / 2);
    final sinLonSq = math.sin(dLon / 2) * math.sin(dLon / 2);
    final a = sinLatSq + math.cos(lat1Rad) * math.cos(lat2Rad) * sinLonSq;
    final d = 2 * math.asin(math.sqrt(math.min(1.0, a)));

    if (d < 1e-6) {
      return [
        [lon1, lat1],
        [lon2, lat2],
      ];
    }

    final distanceMeters = d * 6371000.0;
    final segments = (distanceMeters / 50000.0).clamp(5, 100).toInt();

    final List<List<double>> path = [];
    final sinD = math.sin(d);

    for (int i = 0; i <= segments; i++) {
      final f = i / segments;
      final weightA = math.sin((1.0 - f) * d) / sinD;
      final weightB = math.sin(f * d) / sinD;

      final x =
          weightA * math.cos(lat1Rad) * math.cos(lon1Rad) +
          weightB * math.cos(lat2Rad) * math.cos(lon2Rad);
      final y =
          weightA * math.cos(lat1Rad) * math.sin(lon1Rad) +
          weightB * math.cos(lat2Rad) * math.sin(lon2Rad);
      final z = weightA * math.sin(lat1Rad) + weightB * math.sin(lat2Rad);

      final lat = math.atan2(z, math.sqrt(x * x + y * y));
      final lon = math.atan2(y, x);

      path.add([lon * 180.0 / math.pi, lat * 180.0 / math.pi]);
    }

    return path;
  }

  /// Builds a GeoJSON Point feature for the aircraft symbol.
  static String buildAircraftGeoJson(
    double? lat,
    double? lon,
    double? heading,
  ) {
    if (lat == null || lon == null || (lat == 0.0 && lon == 0.0)) {
      return jsonEncode({'type': 'FeatureCollection', 'features': []});
    }
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [lon, lat],
          },
          'properties': {'heading': heading ?? 0.0},
        },
      ],
    });
  }

  /// Builds a GeoJSON FeatureCollection containing line segments for the predictive course line.
  /// Alternates the 'isEven' property for styling purposes.
  static String buildCourseLineGeoJson(
    TelemetryState telemetry,
    AppSettings? settings,
  ) {
    if (!telemetry.isFlying ||
        telemetry.latitude == null ||
        telemetry.longitude == null ||
        (telemetry.latitude == 0.0 && telemetry.longitude == 0.0)) {
      return jsonEncode({'type': 'FeatureCollection', 'features': []});
    }

    final speedMS = telemetry.groundSpeed ?? telemetry.indicatedAirSpeed ?? 0.0;
    if (speedMS <= 0.0) {
      return jsonEncode({'type': 'FeatureCollection', 'features': []});
    }

    final segmentDuration = settings?.courseLineSegmentDuration ?? 60;
    final segmentsCount = settings?.courseLineSegmentsCount ?? 5;
    final heading = telemetry.heading ?? 0.0;

    final distancePerSegment = speedMS * segmentDuration.toDouble();

    final features = [];
    Geographic currentPoint = Geographic(
      lon: telemetry.longitude!,
      lat: telemetry.latitude!,
    );

    for (int i = 0; i < segmentsCount; i++) {
      final nextPoint = GeoUtils.calculateDestination(
        currentPoint,
        heading,
        distancePerSegment,
      );

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [currentPoint.lon, currentPoint.lat],
            [nextPoint.lon, nextPoint.lat],
          ],
        },
        'properties': {'isEven': i % 2 == 0},
      });

      currentPoint = nextPoint;
    }

    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }
}
