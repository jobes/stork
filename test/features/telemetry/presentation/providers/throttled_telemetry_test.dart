import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../../../../helpers/sensors_mock.dart';

void main() {
  setUp(mockSensorsPlus);

  group('ThrottledTelemetryProvider Tests', () {
    test('initial state matches raw telemetry state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final raw = container.read(telemetryProvider);
      final throttled = container.read(throttledTelemetryProvider);

      expect(throttled.latitude, equals(raw.latitude));
      expect(throttled.longitude, equals(raw.longitude));
    });

    test('initial GPS fix updates immediately', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Listen to the provider to keep it active and tracked
        final sub = container.listen(
          throttledTelemetryProvider,
          (prev, next) {},
        );
        final notifier = container.read(telemetryProvider.notifier);

        expect(container.read(throttledTelemetryProvider).latitude, isNull);

        // First GPS fix
        notifier.updateGPS(latitude: 48.0, longitude: 17.0);

        // Allow the microtask to run
        async.flushMicrotasks();

        final state = container.read(throttledTelemetryProvider);
        expect(state.latitude, equals(48.0));
        expect(state.longitude, equals(17.0));

        sub.close();
      });
    });

    test('subsequent updates within 5 seconds are throttled', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(
          throttledTelemetryProvider,
          (prev, next) {},
        );
        final notifier = container.read(telemetryProvider.notifier);

        // 1. Initial fix (immediate)
        notifier.updateGPS(latitude: 48.0, longitude: 17.0);
        async.flushMicrotasks();
        expect(
          container.read(throttledTelemetryProvider).latitude,
          equals(48.0),
        );

        // 2. Update 2 seconds later (should be throttled)
        async.elapse(const Duration(seconds: 2));
        notifier.updateGPS(latitude: 48.1, longitude: 17.1);
        async.flushMicrotasks();

        // Still 48.0 because it's within the 5 seconds window
        expect(
          container.read(throttledTelemetryProvider).latitude,
          equals(48.0),
        );

        // 3. Elapse another 3 seconds (5 seconds total from initial update)
        async.elapse(const Duration(seconds: 3));

        // The throttled update should now be applied
        expect(
          container.read(throttledTelemetryProvider).latitude,
          equals(48.1),
        );

        sub.close();
      });
    });

    test('updates after 5 seconds are applied immediately', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(
          throttledTelemetryProvider,
          (prev, next) {},
        );
        final notifier = container.read(telemetryProvider.notifier);

        // 1. Initial fix (immediate)
        notifier.updateGPS(latitude: 48.0, longitude: 17.0);
        async.flushMicrotasks();

        // 2. Wait 6 seconds
        async.elapse(const Duration(seconds: 6));

        // 3. Update (should be immediate since > 5 seconds have passed)
        notifier.updateGPS(latitude: 48.2, longitude: 17.2);
        async.flushMicrotasks();

        expect(
          container.read(throttledTelemetryProvider).latitude,
          equals(48.2),
        );

        sub.close();
      });
    });

    test('microtask coalesces multiple updates in the same tick', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(
          throttledTelemetryProvider,
          (prev, next) {},
        );
        final notifier = container.read(telemetryProvider.notifier);

        // Trigger multiple updates synchronously inside the same event loop tick
        notifier.updateGPS(latitude: 48.0, longitude: 17.0);
        notifier.updateGPS(latitude: 48.1, longitude: 17.1);
        notifier.updateGPS(latitude: 48.2, longitude: 17.2);

        // None should be applied before microtasks run
        expect(container.read(throttledTelemetryProvider).latitude, isNull);

        // Flush microtasks to let the coalesced update execute
        async.flushMicrotasks();

        // Should receive the last update directly (48.2, 17.2) immediately as the initial fix
        expect(
          container.read(throttledTelemetryProvider).latitude,
          equals(48.2),
        );

        sub.close();
      });
    });
  });
}
