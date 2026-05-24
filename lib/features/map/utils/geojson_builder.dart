import 'dart:convert';
import 'package:maplibre/maplibre.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../settings/domain/app_settings.dart';
import '../../telemetry/domain/models/telemetry_state.dart';

/// A utility class for constructing GeoJSON strings required by MapLibre sources.
class GeoJsonBuilder {
  /// Builds a GeoJSON Point feature for the aircraft symbol.
  static String buildAircraftGeoJson(double? lat, double? lon, double? heading) {
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

    final speedKmH = telemetry.speed ?? telemetry.indicatedAirSpeed ?? 0.0;
    if (speedKmH <= 0.0) {
      return jsonEncode({'type': 'FeatureCollection', 'features': []});
    }

    // Convert km/h to m/s for calculation
    final speedMS = speedKmH * 1000 / 3600;

    final segmentDuration = settings?.courseLineSegmentDuration ?? 60;
    final segmentsCount = settings?.courseLineSegmentsCount ?? 5;
    final heading = telemetry.heading ?? 0.0;

    final distancePerSegment = speedMS * segmentDuration.toDouble();

    final features = [];
    Geographic currentPoint = Geographic(lon: telemetry.longitude!, lat: telemetry.latitude!);

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
        'properties': {
          'isEven': i % 2 == 0,
        },
      });

      currentPoint = nextPoint;
    }

    return jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });
  }
}
