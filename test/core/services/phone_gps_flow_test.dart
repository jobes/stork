import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

import '../../helpers/fake_geolocator_platform.dart';
import '../../helpers/sensors_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<Position> controller;
  late FakeGeolocatorPlatform fakePlatform;

  setUp(() {
    mockSensorsPlus();
    SharedPreferences.setMockInitialValues({});
    controller = StreamController<Position>.broadcast();
    fakePlatform = FakeGeolocatorPlatform(controller);
    GeolocatorPlatform.instance = fakePlatform;
  });

  tearDown(() async {
    await controller.close();
  });

  test(
    'phone GPS positions flow all the way into telemetry and keep updating',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Activate the background GPS listener (as main.dart does at startup).
      container.read(gpsListenerProvider);
      await Future<void>.delayed(Duration.zero);

      // Before GPS is enabled, the native stream must NOT be created yet.
      expect(fakePlatform.getPositionStreamCallCount, 0);

      // Simulate the map enabling GPS: start the persistent stream (this is
      // what handleGpsToggle/autoStartGps now do) and leave init.
      container.read(geolocatorStreamProvider.notifier).start();
      container
          .read(telemetryProvider.notifier)
          .setMapViewState(MapViewState.follow);
      await Future<void>.delayed(Duration.zero);

      // The persistent native stream is created exactly once.
      expect(fakePlatform.getPositionStreamCallCount, 1);

      // First fix. NOTE: no extra listener on the stream here — only
      // gpsListener's direct subscription should drive the flow, exactly like
      // in the real app.
      controller.add(makePosition(lat: 48.0, lon: 17.0, accuracy: 5.0));
      await Future<void>.delayed(Duration.zero);

      var telemetry = container.read(telemetryProvider);
      expect(telemetry.latitude, 48.0);
      expect(telemetry.longitude, 17.0);
      expect(telemetry.groundSpeed, 12.0);
      expect(telemetry.gpsHorizontalAccuracy, 5.0);
      expect(telemetry.gpsVerticalAccuracy, 6.0);
      expect(telemetry.gpsAltitude, 300.0);

      // A second fix must keep the stream alive (no re-creation).
      controller.add(makePosition(lat: 48.01, lon: 17.01, accuracy: 4.0));
      await Future<void>.delayed(Duration.zero);

      telemetry = container.read(telemetryProvider);
      expect(telemetry.latitude, 48.01);
      expect(telemetry.longitude, 17.01);
      expect(telemetry.gpsHorizontalAccuracy, 4.0);
      expect(fakePlatform.getPositionStreamCallCount, 1);

      // Map-state changes must NOT kill the underlying stream: accuracy keeps
      // flowing afterwards.
      container
          .read(telemetryProvider.notifier)
          .setMapViewState(MapViewState.overview);
      container
          .read(telemetryProvider.notifier)
          .setMapViewState(MapViewState.follow);
      await Future<void>.delayed(Duration.zero);

      controller.add(makePosition(lat: 48.02, lon: 17.02, accuracy: 3.0));
      await Future<void>.delayed(Duration.zero);

      telemetry = container.read(telemetryProvider);
      expect(telemetry.latitude, 48.02);
      expect(telemetry.gpsHorizontalAccuracy, 3.0);
      expect(fakePlatform.getPositionStreamCallCount, 1);
    },
  );
}
