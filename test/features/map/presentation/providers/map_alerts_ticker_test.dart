import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/providers/connectivity_provider.dart';
import 'package:stork/core/services/style_provider.dart';
import 'package:stork/features/map/presentation/providers/map_alerts_provider.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/altitude_health_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/gps_health_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_link_health_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_source_health_provider.dart';

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() => const TelemetryState();

  void emit(TelemetryState next) => state = next;
}

class _GpsHealth extends GpsHealth {
  @override
  GpsHealthState build() => const GpsHealthState();

  @override
  void refresh() {}
}

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _TrafficHealth extends TrafficSourceHealth {
  @override
  TrafficSourceHealthState build() => const TrafficSourceHealthState();

  @override
  void refresh() {}
}

class _AltitudeHealth extends AltitudeHealth {
  @override
  AltitudeHealthState build() => const AltitudeHealthState();

  @override
  void refresh() {}
}

class _CountingLink extends TelemetryLinkHealth {
  int refreshCount = 0;

  @override
  TelemetryLinkHealthState build() => const TelemetryLinkHealthState();

  @override
  void refresh() => refreshCount++;
}

class _OnlineLinks extends NetworkLinkAvailability {
  @override
  bool build() => true;
}

class _OfflineMaps extends OfflineMapsNotifier {
  @override
  OfflineMapsState build() => OfflineMapsState();
}

/// Every health signal is an inert stub, so only [MapAlerts] drives the clock.
ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      telemetryProvider.overrideWith(_Telemetry.new),
      appSettingsProvider.overrideWith(_Settings.new),
      activeCollisionAlertProvider.overrideWithValue(null),
      gpsHealthProvider.overrideWith(_GpsHealth.new),
      telemetryLinkHealthProvider.overrideWith(_CountingLink.new),
      trafficSourceHealthProvider.overrideWith(_TrafficHealth.new),
      altitudeHealthProvider.overrideWith(_AltitudeHealth.new),
      networkLinkAvailabilityProvider.overrideWith(_OnlineLinks.new),
      offlineMapsProvider.overrideWith(_OfflineMaps.new),
      mapStyleProvider.overrideWith((ref) async => '{}'),
    ],
  );
}

void main() {
  test('keeps aging time-based windows while the map is idle', () {
    fakeAsync((async) {
      final container = _container();
      final subscription = container.listen(mapAlertsProvider, (_, _) {});
      async.flushMicrotasks();

      final link =
          container.read(telemetryLinkHealthProvider.notifier) as _CountingLink;
      final initial = link.refreshCount;
      expect(initial, greaterThanOrEqualTo(1));

      // The map is idle (`init`, not flying) and no telemetry arrives; a lost
      // link still has to finish its confirmation window.
      async.elapse(const Duration(seconds: 3));

      expect(link.refreshCount, initial + 3);
      expect(container.read(mapAlertsProvider), isEmpty);

      subscription.close();
      container.dispose();
    });
  });

  test('does not recompute for every telemetry packet', () {
    fakeAsync((async) {
      final container = _container();
      final subscription = container.listen(mapAlertsProvider, (_, _) {});
      async.flushMicrotasks();

      final link =
          container.read(telemetryLinkHealthProvider.notifier) as _CountingLink;
      final before = link.refreshCount;

      final telemetry =
          container.read(telemetryProvider.notifier) as _Telemetry;
      telemetry.emit(const TelemetryState(isFlying: true, groundSpeed: 30));
      async.flushMicrotasks();

      expect(
        link.refreshCount,
        before,
        reason: 'telemetry flooding the UI must not drive recomputation',
      );

      subscription.close();
      container.dispose();
    });
  });
}
