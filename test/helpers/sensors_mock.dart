import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stubs the `sensors_plus` platform channels so unit tests can build
/// providers that subscribe to the device compass (`compassStreamProvider`,
/// `CompassOrientationOffset`) without a real device or a running plugin.
///
/// - The method channel is stubbed so sampling-period configuration calls
///   (`setAccelerationSamplingPeriod`, `setMagnetometerSamplingPeriod`, ...)
///   succeed and return null instead of throwing `MissingPluginException`.
/// - The event channels accept the `listen`/`cancel` calls but never emit
///   sensor data, so the compass heading simply stays `null` and
///   telemetry/compass logic does nothing.
///
/// Mock handlers are cleared automatically after each test, so this can be
/// called once at the start of `main()` (it is idempotent). Use it in any test
/// file that reads providers which listen to sensors (e.g. `telemetryProvider`,
/// `aglProvider`, `navigationProvider`).
void mockSensorsPlus() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // Sampling-period configuration calls are no-ops (return null).
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
    (call) async => null,
  );

  // Event channels: 'listen'/'cancel' return null, i.e. the subscription is
  // accepted but no sensor event is ever delivered.
  for (final name in const [
    'dev.fluttercommunity.plus/sensors/accelerometer',
    'dev.fluttercommunity.plus/sensors/magnetometer',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => null,
    );
  }
}
