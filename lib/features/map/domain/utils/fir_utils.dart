import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre/maplibre.dart';
import '../../../../core/utils/geo_utils.dart';

class FirFeature {
  final String icao;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
  final List<List<List<List<double>>>> polygons;

  FirFeature({
    required this.icao,
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
    required this.polygons,
  });
}

class FirUtils {
  static List<FirFeature>? _features;

  /// Loads the GeoJSON asset and parses all FIR features in memory.
  static Future<void> initialize({
    String assetPath = 'assets/geojson/fir.geojson',
    String? rawJson,
  }) async {
    if (_features != null) return;
    try {
      final jsonString = rawJson ?? await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      final List<dynamic> featuresList = data['features'] as List<dynamic>;

      final List<FirFeature> parsedFeatures = [];
      for (final dynamic f in featuresList) {
        final Map<String, dynamic> feature = f as Map<String, dynamic>;
        final Map<String, dynamic> properties =
            feature['properties'] as Map<String, dynamic>;
        final Map<String, dynamic> geometry =
            feature['geometry'] as Map<String, dynamic>;

        final String icao =
            properties['ICAO'] as String? ??
            properties['name'] as String? ??
            'UNKNOWN';
        final double minLat =
            double.tryParse(properties['MinLat']?.toString() ?? '') ?? -90.0;
        final double minLon =
            double.tryParse(properties['MinLon']?.toString() ?? '') ?? -180.0;
        final double maxLat =
            double.tryParse(properties['MaxLat']?.toString() ?? '') ?? 90.0;
        final double maxLon =
            double.tryParse(properties['MaxLon']?.toString() ?? '') ?? 180.0;

        final String type = geometry['type'] as String;
        final List<dynamic> coords = geometry['coordinates'] as List<dynamic>;
        final List<List<List<List<double>>>> polygons = [];

        List<List<List<double>>> parsePolygon(List<dynamic> polyCoords) {
          final List<List<List<double>>> poly = [];
          for (final dynamic ringObj in polyCoords) {
            final List<List<double>> ring = [];
            for (final dynamic pt in ringObj) {
              ring.add([(pt[0] as num).toDouble(), (pt[1] as num).toDouble()]);
            }
            poly.add(ring);
          }
          return poly;
        }

        if (type == 'Polygon') {
          polygons.add(parsePolygon(coords));
        } else if (type == 'MultiPolygon') {
          for (final dynamic polyObj in coords) {
            polygons.add(parsePolygon(polyObj as List<dynamic>));
          }
        }

        parsedFeatures.add(
          FirFeature(
            icao: icao,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            polygons: polygons,
          ),
        );
      }
      _features = parsedFeatures;
    } catch (_) {
      _features = null;
      rethrow;
    }
  }

  static String? getFirForCoordinate(double lat, double lon) {
    final features = _features;
    if (features == null || features.isEmpty) {
      return null;
    }

    for (final feature in features) {
      // 1. Quick bounding box check
      if (lat < feature.minLat ||
          lat > feature.maxLat ||
          lon < feature.minLon ||
          lon > feature.maxLon) {
        continue;
      }

      // 2. Precise point-in-polygon check
      if (GeoUtils.isPointInPolygons(lon, lat, feature.polygons)) {
        return feature.icao;
      }
    }

    return null;
  }

  static List<Geographic> getRouteChunkPoints(
    List<Geographic> routePoints,
    double chunkDistanceMeters,
  ) {
    if (chunkDistanceMeters <= 0) {
      throw ArgumentError('chunkDistanceMeters must be greater than zero.');
    }
    final List<Geographic> result = [];
    if (routePoints.isEmpty) return result;

    result.add(routePoints.first);
    if (routePoints.length == 1) return result;

    double distanceToNextChunk = chunkDistanceMeters;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final p1 = routePoints[i];
      final p2 = routePoints[i + 1];

      final segmentDist = GeoUtils.distanceBetween(
        p1.lat,
        p1.lon,
        p2.lat,
        p2.lon,
      );
      if (segmentDist == 0) continue;

      double coveredDist = 0;
      while (segmentDist - coveredDist >= distanceToNextChunk) {
        coveredDist += distanceToNextChunk;
        double fraction = coveredDist / segmentDist;
        double interpolatedLat = p1.lat + (p2.lat - p1.lat) * fraction;
        double interpolatedLon = p1.lon + (p2.lon - p1.lon) * fraction;
        result.add(Geographic(lat: interpolatedLat, lon: interpolatedLon));
        distanceToNextChunk = chunkDistanceMeters;
      }
      distanceToNextChunk -= (segmentDist - coveredDist);
    }

    // Always add the last point if it is not already very close to the last added point
    final lastPoint = routePoints.last;
    final lastAdded = result.last;
    final finalDist = GeoUtils.distanceBetween(
      lastAdded.lat,
      lastAdded.lon,
      lastPoint.lat,
      lastPoint.lon,
    );
    if (finalDist > 1000) {
      result.add(lastPoint);
    }

    return result;
  }
}
