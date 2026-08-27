import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/native/dronecan/fix2.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

import '../../helpers/sensors_mock.dart';

Fix2 _fix2({
  double latitude = 48.0,
  double longitude = 17.0,
  int satellites = 10,
  int status = 3,
  int gnssTimestamp = 0,
  int gnssTimeStandard = 0,
  int numLeapSeconds = 0,
}) {
  return Fix2(
    timestamp: 0,
    gnssTimestamp: gnssTimestamp,
    gnssTimeStandard: gnssTimeStandard,
    numLeapSeconds: numLeapSeconds,
    latitude: latitude,
    longitude: longitude,
    altitude: 300.0,
    groundSpeed: 12.0,
    heading: 45.0,
    satellites: satellites,
    status: status,
    pdop: 1.0,
    mode: 0,
    subMode: 0,
    positionCovariance: const [],
    velocityCovariance: const [],
    horizontalAccuracy: 5.0,
    verticalAccuracy: 6.0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockSensorsPlus();
    SharedPreferences.setMockInitialValues({});
  });

  test('an invalid Fix2 (no fix, no satellites) is never published as the '
      'DroneCAN GPS source', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final published = publishDroneCanFix(
      _fix2(status: 0, satellites: 0),
      container.read(telemetryProvider.notifier),
    );

    expect(published, isFalse);
    final state = container.read(telemetryProvider);
    // The critical assertion: DroneCAN GPS must NOT be marked active and the
    // (stale/zero) position must NOT reach telemetry — otherwise the phone
    // GPS stream would be suppressed and the map would freeze.
    expect(state.isGpsDroneCan, isFalse);
    expect(state.latitude, isNull);
    expect(state.longitude, isNull);
    expect(state.groundSpeed, isNull);
    expect(state.gpsHorizontalAccuracy, isNull);
  });

  test(
    'a zero-coordinate Fix2 is never published as the DroneCAN GPS source',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final published = publishDroneCanFix(
        _fix2(latitude: 0.0, longitude: 0.0, status: 3, satellites: 8),
        container.read(telemetryProvider.notifier),
      );

      expect(published, isFalse);
      final state = container.read(telemetryProvider);
      expect(state.isGpsDroneCan, isFalse);
      expect(state.latitude, isNull);
      expect(state.longitude, isNull);
    },
  );

  test('a valid Fix2 is published as the DroneCAN GPS source', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final published = publishDroneCanFix(
      _fix2(status: 3, satellites: 10),
      container.read(telemetryProvider.notifier),
    );

    expect(published, isTrue);
    final state = container.read(telemetryProvider);
    expect(state.isGpsDroneCan, isTrue);
    expect(state.latitude, 48.0);
    expect(state.longitude, 17.0);
    expect(state.groundSpeed, 12.0);
    expect(state.gpsSatelliteCount, 10);
    expect(state.gpsHorizontalAccuracy, 5.0);
    expect(state.gpsVerticalAccuracy, 6.0);
    expect(state.gpsAltitude, 300.0);
  });

  group('gpsTimestamp conversion from Fix2.gnssTimeStandard', () {
    const microsPerSecond = 1000000;
    // Microseconds since the standard's own epoch (same value for all cases).
    const gnssTs = 123456789000000;

    DateTime? publishedTimestamp({
      required int gnssTimeStandard,
      required int numLeapSeconds,
    }) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      publishDroneCanFix(
        _fix2(
          gnssTimestamp: gnssTs,
          gnssTimeStandard: gnssTimeStandard,
          numLeapSeconds: numLeapSeconds,
        ),
        container.read(telemetryProvider.notifier),
      );

      return container.read(telemetryProvider).gpsTimestamp;
    }

    test('UTC standard publishes the timestamp directly', () {
      expect(
        publishedTimestamp(gnssTimeStandard: 2, numLeapSeconds: 18),
        DateTime.fromMicrosecondsSinceEpoch(gnssTs, isUtc: true),
      );
    });

    test('GPS standard converts using numLeapSeconds and the 9 s offset', () {
      const leap = 18;
      const gpsUtcOffsetSeconds = 9;
      expect(
        publishedTimestamp(gnssTimeStandard: 3, numLeapSeconds: leap),
        DateTime.fromMicrosecondsSinceEpoch(
          gnssTs -
              leap * microsPerSecond +
              gpsUtcOffsetSeconds * microsPerSecond,
          isUtc: true,
        ),
      );
    });

    test('TAI standard converts using numLeapSeconds and the 10 s offset', () {
      const leap = 37;
      const taiUtcOffsetSeconds = 10;
      expect(
        publishedTimestamp(gnssTimeStandard: 1, numLeapSeconds: leap),
        DateTime.fromMicrosecondsSinceEpoch(
          gnssTs -
              leap * microsPerSecond -
              taiUtcOffsetSeconds * microsPerSecond,
          isUtc: true,
        ),
      );
    });

    test('UNKNOWN standard yields no UTC timestamp', () {
      expect(
        publishedTimestamp(gnssTimeStandard: 0, numLeapSeconds: 18),
        isNull,
      );
    });

    test('unsupported standard yields no UTC timestamp', () {
      expect(
        publishedTimestamp(gnssTimeStandard: 5, numLeapSeconds: 18),
        isNull,
      );
    });
  });
}
