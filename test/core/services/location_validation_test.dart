import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/core/services/location_service.dart';

import '../../helpers/fake_geolocator_platform.dart';

class _Sensors {
  final acceleration = StreamController<AccelerometerEvent?>.broadcast();
  final magnetic = StreamController<MagnetometerEvent?>.broadcast();
}

class _Gps extends FakeGeolocatorPlatform {
  _Gps(super.controller, this.position);
  final Position position;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => position;
}

void main() {
  for (final platform in [
    TargetPlatform.linux,
    TargetPlatform.windows,
    TargetPlatform.macOS,
  ]) {
    testWidgets('$platform accepts sensors and recovers after removal', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final sensors = _Sensors();
      final container = ProviderContainer(
        overrides: [
          accelerometerSourceProvider.overrideWithValue(
            sensors.acceleration.stream,
          ),
          magnetometerSourceProvider.overrideWithValue(sensors.magnetic.stream),
        ],
      );
      try {
        container.listen(compassStreamProvider, (_, _) {});
        await tester.pump();
        final fallback = container.read(compassOrientationOffsetProvider);
        expect(sensors.acceleration.hasListener, isTrue);
        expect(sensors.magnetic.hasListener, isTrue);
        sensors.acceleration.add(
          AccelerometerEvent(-9.8, 0, 0, DateTime.now()),
        );
        sensors.magnetic.add(MagnetometerEvent(0, 1, 0, DateTime.now()));
        await tester.pump();
        expect(container.read(compassStreamProvider).requireValue, isNotNull);
        expect(container.read(compassOrientationOffsetProvider), -90);

        sensors.acceleration.add(null);
        sensors.magnetic.add(null);
        await tester.pump();
        expect(container.read(compassStreamProvider).requireValue, isNull);
        expect(container.read(compassOrientationOffsetProvider), fallback);
        // A reconnect must wait for a fresh pair, not reuse pre-removal data.
        sensors.magnetic.add(MagnetometerEvent(0, 1, 0, DateTime.now()));
        await tester.pump();
        expect(container.read(compassStreamProvider).requireValue, isNull);
        sensors.acceleration.add(AccelerometerEvent(0, 0, 9.8, DateTime.now()));
        await tester.pump();
        expect(container.read(compassStreamProvider).requireValue, isNotNull);
      } finally {
        container.dispose();
        await sensors.acceleration.close();
        await sensors.magnetic.close();
      }
    });
  }

  testWidgets(
    'non-finite sensor headings are ignored and valid headings still arrive',
    (tester) async {
      final sensors = _Sensors();
      final container = ProviderContainer(
        overrides: [
          compassOrientationOffsetProvider.overrideWithValue(0),
          accelerometerSourceProvider.overrideWithValue(
            sensors.acceleration.stream,
          ),
          magnetometerSourceProvider.overrideWithValue(sensors.magnetic.stream),
        ],
      );
      final headings = <double>[];
      container.listen(compassStreamProvider, (_, next) {
        if (next.value case final value?) headings.add(value);
      });
      await tester.pump();
      sensors.acceleration.add(AccelerometerEvent(0, 0, 9.8, DateTime.now()));
      sensors.magnetic.add(MagnetometerEvent(double.nan, 1, 0, DateTime.now()));
      await tester.pump();
      expect(headings, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      sensors.magnetic.add(MagnetometerEvent(0, 1, 0, DateTime.now()));
      await tester.pump();
      expect(headings, [0]);
      await tester.pump(const Duration(seconds: 1));
      sensors.magnetic.add(
        MagnetometerEvent(double.infinity, 1, 0, DateTime.now()),
      );
      await tester.pump();
      expect(headings, [0]);
      container.dispose();
      await sensors.acceleration.close();
      await sensors.magnetic.close();
    },
  );

  test('quiet last-known lookup rejects invalid native coordinates', () async {
    final previous = GeolocatorPlatform.instance;
    final controller = StreamController<Position>.broadcast();
    try {
      for (final position in [
        makePosition(lat: double.nan),
        makePosition(lat: 91),
        makePosition(lon: double.infinity),
        makePosition(lon: 181),
        makePosition(lat: 0, lon: 0),
      ]) {
        GeolocatorPlatform.instance = _Gps(controller, position);
        expect(await LocationService.getGpsLocationOnly(), isNull);
      }
      GeolocatorPlatform.instance = _Gps(
        controller,
        makePosition(lat: 0, lon: 17),
      );
      final location = await LocationService.getGpsLocationOnly();
      expect(location!.lat, 0);
      expect(location.lon, 17);
    } finally {
      GeolocatorPlatform.instance = previous;
      await controller.close();
    }
  });
}
