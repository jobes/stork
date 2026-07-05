import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils Tests', () {
    test('calculates distance between same points as 0', () {
      final distance = GeoUtils.distanceBetween(
        37.7749,
        -122.4194,
        37.7749,
        -122.4194,
      );
      expect(distance, closeTo(0.0, 0.001));
    });

    test('calculates distance between two different points correctly', () {
      // Distance between SF (37.7749, -122.4194) and NY (40.7128, -74.0060) is approx 4130000 meters
      final distance = GeoUtils.distanceBetween(
        37.7749,
        -122.4194,
        40.7128,
        -74.0060,
      );
      expect(distance, closeTo(4130000.0, 10000.0));
    });

    test('handles antipodal points without producing NaN', () {
      // Antipodal points on the equator: (0, 0) and (0, 180)
      final distance = GeoUtils.distanceBetween(0.0, 0.0, 0.0, 180.0);
      expect(distance.isNaN, isFalse);
      expect(distance, closeTo(math.pi * GeoUtils.earthRadiusMeters, 0.001));
    });

    test('calculates distance to segment correctly', () {
      // SF to LA segment approx
      final distance = GeoUtils.distanceToSegment(
        37.7749,
        -122.4194, // SF
        37.7749,
        -122.4194, // SF
        34.0522,
        -118.2437, // LA
      );
      expect(distance, closeTo(0.0, 0.001));
    });

    test(
      'calculates distance to polygons (inside is 0, outside is positive)',
      () {
        final polygons = [
          [
            [
              [0.0, 0.0],
              [10.0, 0.0],
              [10.0, 10.0],
              [0.0, 10.0],
              [0.0, 0.0],
            ],
          ],
        ];
        // Point inside polygon
        final insideDist = GeoUtils.distanceToPolygons(5.0, 5.0, polygons);
        expect(insideDist, 0.0);

        // Point outside polygon
        final outsideDist = GeoUtils.distanceToPolygons(11.0, 5.0, polygons);
        expect(outsideDist, greaterThan(0.0));
      },
    );
  });
}
