import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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
}
