import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stork/core/providers/location_access_provider.dart';
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/presentation/providers/gps_health_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() => const TelemetryState();

  void emit(TelemetryState next) => state = next;
}

class _DeniedLocationAccess extends LocationAccess {
  @override
  LocationAccessState build() =>
      const LocationAccessState(permissionDenied: true, servicesDisabled: true);

  @override
  Future<void> refresh() async {}
}

class _FailedPhoneGps extends GeolocatorStream {
  @override
  ({Stream<Position> stream, GeolocatorStreamStatus status}) build() => (
    stream: const Stream.empty(),
    status: GeolocatorStreamFailed(StateError('GPS failed'), StackTrace.empty),
  );
}

void main() {
  final requestedAt = DateTime.utc(2026, 11, 11, 12);

  test('reports phone GPS failures only when DroneCAN is inactive', () {
    fakeAsync((async) {
      final container = ProviderContainer.test(
        overrides: [
          telemetryProvider.overrideWith(_Telemetry.new),
          locationAccessProvider.overrideWith(_DeniedLocationAccess.new),
          geolocatorStreamProvider.overrideWith(_FailedPhoneGps.new),
        ],
      );
      final telemetry =
          container.read(telemetryProvider.notifier) as _Telemetry;
      final droneCan = TelemetryState(
        mapViewState: MapViewState.overview,
        isGpsDroneCan: true,
        gpsLastFixAt: clock.now(),
      );
      telemetry.emit(droneCan);
      container.listen(gpsHealthProvider, (_, _) {});

      expect(container.read(gpsHealthProvider), const GpsHealthState());

      async.elapse(const Duration(seconds: 5));
      telemetry.emit(droneCan.copyWith(isGpsDroneCan: false));
      final health = container.read(gpsHealthProvider);
      expect(health.permissionDenied, isTrue);
      expect(health.servicesDisabled, isTrue);
      expect(health.streamFailed, isTrue);
      expect(health.droneCanFallback, isFalse);
    });
  });

  group('evaluateGpsFixHealth', () {
    test('reports nothing while GPS is not expected', () {
      final health = evaluateGpsFixHealth(
        now: requestedAt.add(const Duration(minutes: 5)),
        gpsExpected: false,
        lastFixAt: null,
        expectedSince: requestedAt,
      );

      expect(health, const GpsFixHealth());
    });

    test('waits for the first fix without complaining too early', () {
      final health = evaluateGpsFixHealth(
        now: requestedAt.add(const Duration(seconds: 10)),
        gpsExpected: true,
        lastFixAt: null,
        expectedSince: requestedAt,
      );

      expect(health.awaitingFirstFix, isFalse);
      expect(health.hasIssue, isFalse);
    });

    test('reports a missing first fix after the timeout', () {
      final health = evaluateGpsFixHealth(
        now: requestedAt.add(GpsHealth.noFixAfter),
        gpsExpected: true,
        lastFixAt: null,
        expectedSince: requestedAt,
      );

      expect(health.awaitingFirstFix, isTrue);
    });

    test('accepts a fresh fix', () {
      final health = evaluateGpsFixHealth(
        now: requestedAt.add(const Duration(seconds: 3)),
        gpsExpected: true,
        lastFixAt: requestedAt,
        expectedSince: requestedAt,
      );

      expect(health, const GpsFixHealth());
    });

    test('reports a lost fix once the last fix goes stale', () {
      final health = evaluateGpsFixHealth(
        now: requestedAt.add(GpsHealth.fixStaleAfter),
        gpsExpected: true,
        lastFixAt: requestedAt,
        expectedSince: requestedAt,
      );

      expect(health.fixLost, isTrue);
      expect(health.awaitingFirstFix, isFalse);
    });
  });

  group('GpsHealthState', () {
    test('treats any issue as a problem except the informational fallback', () {
      expect(const GpsHealthState().hasIssue, isFalse);
      expect(const GpsHealthState(permissionDenied: true).hasIssue, isTrue);
      expect(const GpsHealthState(droneCanFallback: true).hasIssue, isFalse);
    });

    test('compares by value', () {
      expect(
        const GpsHealthState(fixLost: true),
        equals(const GpsHealthState(fixLost: true)),
      );
      expect(
        const GpsHealthState(fixLost: true),
        isNot(equals(const GpsHealthState(streamFailed: true))),
      );
    });
  });
}
