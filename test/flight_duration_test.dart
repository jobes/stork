import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/flight_duration_provider.dart';

void main() {
  group('Flight Duration Provider Tests', () {
    // Helper to advance time while keeping telemetry speed alive and updating coordinates to simulate movement
    void elapseFlight(
      FakeAsync async,
      TelemetryNotifier notifier,
      Duration duration, {
      double startLat = 48.0,
      double startLon = 17.0,
      double stepLat = 0.0001,
      double stepLon = 0.0001,
    }) {
      final seconds = duration.inSeconds;
      var currentLat = startLat;
      var currentLon = startLon;

      for (var i = 0; i < seconds; i++) {
        async.elapse(const Duration(seconds: 1));
        currentLat += stepLat;
        currentLon += stepLon;
        notifier.updateGPS(
          latitude: currentLat,
          longitude: currentLon,
          groundSpeed: 10.0,
        );
      }
    }

    test('Initial duration is zero, distance is zero, startTime is null, and isFlying is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final summary = container.read(flightDurationProvider);
      final isFlying = container.read(telemetryProvider).isFlying;

      expect(summary.duration, equals(Duration.zero));
      expect(summary.distanceMeters, equals(0.0));
      expect(summary.startTime, isNull);
      expect(isFlying, isFalse);
    });

    test('Starts counting up and records startTime/distance when isFlying becomes true', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final durationSub = container.listen(flightDurationProvider, (prev, next) {});
        final telemetryNotifier = container.read(telemetryProvider.notifier);

        // Start flying by updating ground speed above threshold (2.77) with initial coordinate
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        expect(container.read(telemetryProvider).isFlying, isTrue);

        var summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(Duration.zero));
        expect(summary.startTime, isNotNull);
        expect(summary.distanceMeters, equals(0.0));

        // Advance 1 second, simulating coordinates changing to (48.0001, 17.0001)
        elapseFlight(
          async,
          telemetryNotifier,
          const Duration(seconds: 1),
          startLat: 48.0,
          startLon: 17.0,
          stepLat: 0.0001,
          stepLon: 0.0001,
        );
        
        summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(const Duration(seconds: 1)));
        expect(summary.distanceMeters, isPositive);

        // Advance another 5 seconds with coordinates changing further
        final prevDistance = summary.distanceMeters;
        elapseFlight(
          async,
          telemetryNotifier,
          const Duration(seconds: 5),
          startLat: 48.0001,
          startLon: 17.0001,
          stepLat: 0.0001,
          stepLon: 0.0001,
        );
        
        summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(const Duration(seconds: 6)));
        expect(summary.distanceMeters, greaterThan(prevDistance));
        
        durationSub.close();
      });
    });

    test('Stops counting and keeps last duration and distance when landing', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final durationSub = container.listen(flightDurationProvider, (prev, next) {});
        final telemetryNotifier = container.read(telemetryProvider.notifier);

        // Start flying and maintain for 10 seconds
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        elapseFlight(
          async,
          telemetryNotifier,
          const Duration(seconds: 10),
          startLat: 48.0,
          startLon: 17.0,
        );
        
        var summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(const Duration(seconds: 10)));
        final finalDistance = summary.distanceMeters;
        expect(finalDistance, isPositive);
        final finalStartTime = summary.startTime;

        // Land by updating groundSpeed below threshold (0.0)
        telemetryNotifier.updateGPS(groundSpeed: 0.0);
        expect(container.read(telemetryProvider).isFlying, isFalse);

        // Verify summary fields are held/preserved
        summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(const Duration(seconds: 10)));
        expect(summary.distanceMeters, equals(finalDistance));
        expect(summary.startTime, equals(finalStartTime));

        // Advance time, duration/distance should NOT increment
        async.elapse(const Duration(seconds: 5));
        summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(const Duration(seconds: 10)));
        expect(summary.distanceMeters, equals(finalDistance));

        durationSub.close();
      });
    });

    test('Resets to zero and counts up again on new flight', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final durationSub = container.listen(flightDurationProvider, (prev, next) {});
        final telemetryNotifier = container.read(telemetryProvider.notifier);

        // First flight of 5 seconds
        telemetryNotifier.updateGPS(
          latitude: 48.0,
          longitude: 17.0,
          groundSpeed: 10.0,
        );
        elapseFlight(
          async,
          telemetryNotifier,
          const Duration(seconds: 5),
          startLat: 48.0,
          startLon: 17.0,
        );
        
        var summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(const Duration(seconds: 5)));
        expect(summary.distanceMeters, isPositive);

        // Land
        telemetryNotifier.updateGPS(groundSpeed: 0.0);
        expect(container.read(flightDurationProvider).duration, equals(const Duration(seconds: 5)));

        // Wait 10 seconds on the ground
        async.elapse(const Duration(seconds: 10));
        expect(container.read(flightDurationProvider).duration, equals(const Duration(seconds: 5)));

        // Second flight start
        telemetryNotifier.updateGPS(
          latitude: 49.0,
          longitude: 18.0,
          groundSpeed: 10.0,
        );
        
        // Immediately upon starting, it should reset to 0
        summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(Duration.zero));
        expect(summary.distanceMeters, equals(0.0));
        expect(summary.startTime, isNotNull);

        // Advance 3 seconds
        elapseFlight(
          async,
          telemetryNotifier,
          const Duration(seconds: 3),
          startLat: 49.0,
          startLon: 18.0,
        );
        summary = container.read(flightDurationProvider);
        expect(summary.duration, equals(const Duration(seconds: 3)));
        expect(summary.distanceMeters, isPositive);

        durationSub.close();
      });
    });
  });
}
