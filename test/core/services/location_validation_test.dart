import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/core/services/location_service.dart';

import '../../helpers/fake_geolocator_platform.dart';

class _Sensors extends SensorsPlatform {
  final acceleration = StreamController<AccelerometerEvent>.broadcast();
  final magnetic = StreamController<MagnetometerEvent>.broadcast();
  @override
  Stream<AccelerometerEvent> accelerometerEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => acceleration.stream;
  @override
  Stream<MagnetometerEvent> magnetometerEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => magnetic.stream;
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
  testWidgets(
    'non-finite sensor headings are ignored and valid headings still arrive',
    (tester) async {
      final previous = SensorsPlatform.instance;
      final sensors = _Sensors();
      SensorsPlatform.instance = sensors;
      final container = ProviderContainer(
        overrides: [compassOrientationOffsetProvider.overrideWithValue(0)],
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
      SensorsPlatform.instance = previous;
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
