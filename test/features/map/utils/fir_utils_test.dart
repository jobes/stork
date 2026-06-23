import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/features/map/domain/utils/fir_utils.dart';

void main() {
  setUpAll(() async {
    final file = File('assets/geojson/fir.geojson');
    final geojson = file.readAsStringSync();
    await FirUtils.initialize(rawJson: geojson);
  });

  group('FirUtils GeoJSON Lookup Tests', () {
    test('LZBB (Slovakia) lookup', () {
      // Bratislava coordinates: ~48.17 N, 17.21 E
      final fir = FirUtils.getFirForCoordinate(48.17, 17.21);
      expect(fir, equals('LZBB'));
    });

    test('LKAA (Czech Republic) lookup', () {
      // Prague coordinates: ~50.10 N, 14.26 E
      final fir = FirUtils.getFirForCoordinate(50.10, 14.26);
      expect(fir, equals('LKAA'));
    });

    test('EPWW (Poland) lookup', () {
      // Warsaw coordinates: ~52.17 N, 20.97 E
      final fir = FirUtils.getFirForCoordinate(52.17, 20.97);
      expect(fir, equals('EPWW'));
    });

    test('LOVV (Austria) lookup', () {
      // Vienna coordinates: ~48.11 N, 16.56 E
      final fir = FirUtils.getFirForCoordinate(48.11, 16.56);
      expect(fir, equals('LOVV-C'));
    });

    test('LHCC (Hungary) lookup', () {
      // Budapest coordinates: ~47.43 N, 19.26 E
      final fir = FirUtils.getFirForCoordinate(47.43, 19.26);
      expect(fir, equals('LHCC'));
    });

    test('Fallback to LZBB is not triggered for NYC (matches KZNY)', () {
      // New York City coordinates: ~40.71 N, -74.00 E
      final fir = FirUtils.getFirForCoordinate(40.71, -74.00);
      expect(fir, equals('KZNY'));
    });

    test('Returns null for out of bounds coordinate', () {
      // Coordinate: 1000, 1000 (completely out of bounds, no FIR covering it)
      final fir = FirUtils.getFirForCoordinate(1000.0, 1000.0);
      expect(fir, isNull);
    });
  });

  group('FirUtils.getRouteChunkPoints Tests', () {
    test('Empty route returns empty list', () {
      final result = FirUtils.getRouteChunkPoints([], 1000.0);
      expect(result, isEmpty);
    });

    test('Single point route returns list containing only that point', () {
      final pts = [Geographic(lat: 48.0, lon: 17.0)];
      final result = FirUtils.getRouteChunkPoints(pts, 1000.0);
      expect(result.length, 1);
      expect(result[0].lat, 48.0);
      expect(result[0].lon, 17.0);
    });

    test('Segments shorter than chunk distance are optimized to avoid redundant overlapping checks', () {
      // A route with 3 points, short distances (roughly 111 meters per 0.001 degree)
      final pts = [
        Geographic(lat: 48.0, lon: 17.0),
        Geographic(lat: 48.001, lon: 17.0),
        Geographic(lat: 48.002, lon: 17.0),
      ];
      // Chunk distance is 50,000 meters (much larger than the actual distance between points)
      final result = FirUtils.getRouteChunkPoints(pts, 50000.0);

      // Under optimization, the 50km circle around the start point covers the entire 222-meter route,
      // so no additional points are added.
      expect(result.length, 1);
      expect(result[0].lat, 48.0);
    });

    test('Segments longer than chunk distance are interpolated with optimal spacing', () {
      // Distance between 48.0 and 49.0 lat at 17.0 lon is ~111,000 meters
      final pts = [
        Geographic(lat: 48.0, lon: 17.0),
        Geographic(lat: 49.0, lon: 17.0),
        Geographic(lat: 50.0, lon: 17.0),
      ];
      // Chunk distance is 50,000 meters.
      final result = FirUtils.getRouteChunkPoints(pts, 50000.0);

      // Points:
      // 1. A (48.0)
      // 2. P1 (interpolated at ~48.45)
      // 3. P2 (interpolated at ~48.90)
      // 4. P3 (interpolated at ~49.35)
      // 5. P4 (interpolated at ~49.80)
      // 6. C (50.0) - last point added because distance from P4 to C (~22km) is > 1000m.
      expect(result.length, 6);
      expect(result[0].lat, 48.0);
      expect(result[5].lat, 50.0);
    });

    test('Throws ArgumentError if chunk distance is zero or negative', () {
      final pts = [Geographic(lat: 48.0, lon: 17.0)];
      expect(
        () => FirUtils.getRouteChunkPoints(pts, 0.0),
        throwsArgumentError,
      );
      expect(
        () => FirUtils.getRouteChunkPoints(pts, -100.0),
        throwsArgumentError,
      );
    });
  });
}
