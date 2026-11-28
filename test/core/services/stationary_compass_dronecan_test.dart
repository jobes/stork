import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/native/dronecan/fix2.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

import '../../helpers/sensors_mock.dart';

Fix2 fix(double speed, double? track) => Fix2(
  timestamp: 0,
  gnssTimestamp: 0,
  gnssTimeStandard: 0,
  numLeapSeconds: 0,
  latitude: 48.769,
  longitude: 18.591,
  altitude: 260,
  groundSpeed: speed,
  heading: track,
  satellites: 12,
  status: 3,
  pdop: 1,
  mode: 0,
  subMode: 0,
  positionCovariance: const [],
  velocityCovariance: const [],
  horizontalAccuracy: 1,
  verticalAccuracy: 2,
);

void main() {
  setUp(() {
    mockSensorsPlus();
    SharedPreferences.setMockInitialValues({});
  });

  test('stationary DroneCAN GPS preserves compass heading and GPS source', () {
    fakeAsync((async) {
      final acceleration = StreamController<AccelerometerEvent?>.broadcast();
      final magnetic = StreamController<MagnetometerEvent?>.broadcast();
      final container = ProviderContainer(
        overrides: [
          accelerometerSourceProvider.overrideWithValue(acceleration.stream),
          magnetometerSourceProvider.overrideWithValue(magnetic.stream),
          compassOrientationOffsetProvider.overrideWithValue(0),
        ],
      );
      container.listen(telemetryProvider, (_, _) {}, fireImmediately: true);
      final notifier = container.read(telemetryProvider.notifier);
      publishDroneCanFix(fix(0, null), notifier);
      async.elapse(Duration.zero);
      void sample() {
        final now = DateTime.now();
        acceleration.add(AccelerometerEvent(0, 0, 9.80665, now));
        magnetic.add(
          MagnetometerEvent(
            -50 * math.sin(220 * math.pi / 180),
            50 * math.cos(220 * math.pi / 180),
            -35,
            now,
          ),
        );
        async.elapse(Duration.zero);
      }

      sample();
      async.elapse(Duration.zero);
      expect(container.read(telemetryProvider).heading, closeTo(220, 0.000001));
      expect(container.read(telemetryProvider).isGpsDroneCan, isTrue);
      for (var i = 0; i < 35; i++) {
        publishDroneCanFix(fix(0, null), notifier);
        sample();
        async.elapse(const Duration(milliseconds: 100));
      }
      expect(container.read(telemetryProvider).heading, closeTo(220, 0.000001));
      expect(container.read(telemetryProvider).groundSpeed, 0);
      expect(container.read(telemetryProvider).isFlying, isFalse);
      expect(container.read(telemetryProvider).isGpsDroneCan, isTrue);
      async.elapse(const Duration(milliseconds: 2100));
      expect(container.read(telemetryProvider).heading, isNull);
      container.dispose();
      acceleration.close();
      magnetic.close();
      async.flushMicrotasks();
    });
  });

  test(
    'moving DroneCAN ground track wins in flight; compass resumes on ground',
    () {
      final container = ProviderContainer();
      container.listen(telemetryProvider, (_, _) {}, fireImmediately: true);
      final notifier = container.read(telemetryProvider.notifier);
      publishDroneCanFix(fix(30, 40), notifier);
      expect(container.read(telemetryProvider).isFlying, isTrue);
      notifier.updateCompassHeading(220);
      expect(container.read(telemetryProvider).heading, 40);
      publishDroneCanFix(fix(0, null), notifier);
      notifier.updateCompassHeading(220);
      expect(container.read(telemetryProvider).isFlying, isFalse);
      expect(container.read(telemetryProvider).heading, closeTo(220, 0.000001));
      expect(container.read(telemetryProvider).isGpsDroneCan, isTrue);
      container.dispose();
    },
  );
}
