import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/decayable_field.dart';

void main() {
  group('Telemetry Timeout and Null Defaults', () {
    test('Everything in telemetry is null on start except mapViewState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(telemetryProvider);

      expect(state.latitude, isNull);
      expect(state.longitude, isNull);
      expect(state.heading, isNull);
      expect(state.groundSpeed, isNull);
      expect(state.indicatedAirSpeed, isNull);
      expect(state.isFlying, isFalse);
      expect(state.engineRPM, isNull);
      expect(state.airPressure, isNull);
      expect(state.gpsAltitude, isNull);
      expect(state.gpsSatelliteCount, isNull);
      expect(state.gpsHorizontalAccuracy, isNull);
      expect(state.gpsVerticalAccuracy, isNull);
      expect(state.mapViewState, equals(MapViewState.init));
    });

    test('Data field nullified after 2 seconds if not updated', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(telemetryProvider.notifier);

        // Update GPS fields
        notifier.updateGPS(
          latitude: 45.0,
          longitude: 12.0,
          heading: 90.0,
          groundSpeed: 10.0,
        );

        var state = container.read(telemetryProvider);
        expect(state.latitude, equals(45.0));
        expect(state.longitude, equals(12.0));
        expect(state.heading, equals(90.0));
        expect(state.groundSpeed, equals(10.0));

        // Advance 1.9 seconds, should still be there
        async.elapse(const Duration(milliseconds: 1900));
        state = container.read(telemetryProvider);
        expect(state.latitude, equals(45.0));
        expect(state.longitude, equals(12.0));
        expect(state.heading, equals(90.0));
        expect(state.groundSpeed, equals(10.0));

        // Advance another 0.11 seconds (over 2 seconds), should be null again
        async.elapse(const Duration(milliseconds: 110));
        state = container.read(telemetryProvider);
        expect(
          state.latitude,
          equals(45.0),
        ); // Latitude never decays (timeout: Duration.zero)
        expect(
          state.longitude,
          equals(12.0),
        ); // Longitude never decays (timeout: Duration.zero)
        expect(state.heading, isNull);
        expect(state.groundSpeed, isNull);
      });
    });

    test('Updating to same value resets the timer', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(telemetryProvider.notifier);

        notifier.updateEngineRPM(2500);

        var state = container.read(telemetryProvider);
        expect(state.engineRPM, equals(2500));

        // Advance 0.5 seconds
        async.elapse(const Duration(milliseconds: 500));
        state = container.read(telemetryProvider);
        expect(state.engineRPM, equals(2500));

        // Update to same value
        notifier.updateEngineRPM(2500);

        // Advance 0.5 seconds (total 1s since start, but only 0.5s since update)
        async.elapse(const Duration(milliseconds: 500));
        state = container.read(telemetryProvider);
        expect(state.engineRPM, equals(2500));

        // Advance 1.1 seconds (over 1.5s since update), should be null again
        async.elapse(const Duration(milliseconds: 1100));
        state = container.read(telemetryProvider);
        expect(state.engineRPM, isNull);
      });
    });

    test('isEngineRpmSupported remains true after engineRPM decays', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(telemetryProvider.notifier);

        var state = container.read(telemetryProvider);
        expect(state.isEngineRpmSupported, isFalse);

        notifier.updateEngineRPM(2500);
        state = container.read(telemetryProvider);
        expect(state.isEngineRpmSupported, isTrue);

        // Advance 2 seconds to trigger decay
        async.elapse(const Duration(seconds: 2));
        state = container.read(telemetryProvider);
        expect(state.engineRPM, isNull);
        expect(state.isEngineRpmSupported, isTrue);
      });
    });

    test('mapViewState and isFlying are excluded from 2-second timeout', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(telemetryProvider.notifier);

        notifier.updateGPS(
          groundSpeed: 20.0,
        ); // Above default flight threshold (2.77)
        notifier.setMapViewState(MapViewState.follow);

        var state = container.read(telemetryProvider);
        expect(state.groundSpeed, equals(20.0));
        expect(state.isFlying, isTrue);
        expect(state.mapViewState, equals(MapViewState.follow));

        // Advance over 2 seconds
        async.elapse(const Duration(seconds: 3));

        state = container.read(telemetryProvider);
        expect(state.groundSpeed, isNull); // decayed
        expect(
          state.isFlying,
          isFalse,
        ); // decayed as groundSpeed decayed and is null
        expect(
          state.mapViewState,
          equals(MapViewState.follow),
        ); // maintained (excluded from timeout)
      });
    });

    test('DecayableField does not start timer if timeout is 0 or less', () {
      fakeAsync((async) {
        double? recordedValue;
        final field = DecayableField<double>(
          timeout: Duration.zero,
          onChanged: (val) => recordedValue = val,
        );

        field.update(42.0);
        expect(field.value, equals(42.0));
        expect(recordedValue, equals(42.0));

        // Elapse time, should not decay
        async.elapse(const Duration(seconds: 5));
        expect(field.value, equals(42.0));
        expect(recordedValue, equals(42.0));
      });
    });
  });
}
