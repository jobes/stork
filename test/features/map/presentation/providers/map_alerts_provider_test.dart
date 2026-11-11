import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/providers/connectivity_provider.dart';
import 'package:stork/core/services/style_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_data_status_provider.dart';
import 'package:stork/features/map/presentation/providers/map_alert_history_provider.dart';
import 'package:stork/features/map/presentation/providers/map_alerts_provider.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
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

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(
    oilTempThresholds: RangeThresholds.raw(maxWarning: 365, maxError: 380),
  );
}

class _GpsHealth extends GpsHealth {
  _GpsHealth(this.value);

  final GpsHealthState value;

  @override
  GpsHealthState build() => value;

  @override
  void refresh() {}
}

class _LinkHealth extends TelemetryLinkHealth {
  _LinkHealth(this.value);

  final TelemetryLinkHealthState value;

  @override
  TelemetryLinkHealthState build() => value;

  @override
  void refresh() {}
}

class _TrafficHealth extends TrafficSourceHealth {
  _TrafficHealth(this.value);

  final TrafficSourceHealthState value;

  @override
  TrafficSourceHealthState build() => value;

  @override
  void refresh() {}
}

class _AltitudeHealth extends AltitudeHealth {
  _AltitudeHealth(this.value);

  final AltitudeHealthState value;

  @override
  AltitudeHealthState build() => value;

  @override
  void refresh() {}
}

class _OnlineLinks extends NetworkLinkAvailability {
  _OnlineLinks(this.online);

  final bool online;

  @override
  bool build() => online;
}

class _OfflineMaps extends OfflineMapsNotifier {
  @override
  OfflineMapsState build() => OfflineMapsState();
}

ProviderContainer _container({
  GpsHealthState gps = const GpsHealthState(),
  TelemetryLinkHealthState link = const TelemetryLinkHealthState(),
  TrafficSourceHealthState traffic = const TrafficSourceHealthState(),
  AltitudeHealthState altitude = const AltitudeHealthState(),
  bool linkAvailable = true,
}) {
  return ProviderContainer(
    overrides: [
      telemetryProvider.overrideWith(_Telemetry.new),
      appSettingsProvider.overrideWith(_Settings.new),
      activeCollisionAlertProvider.overrideWithValue(null),
      gpsHealthProvider.overrideWith(() => _GpsHealth(gps)),
      telemetryLinkHealthProvider.overrideWith(() => _LinkHealth(link)),
      trafficSourceHealthProvider.overrideWith(() => _TrafficHealth(traffic)),
      altitudeHealthProvider.overrideWith(() => _AltitudeHealth(altitude)),
      networkLinkAvailabilityProvider.overrideWith(
        () => _OnlineLinks(linkAvailable),
      ),
      offlineMapsProvider.overrideWith(_OfflineMaps.new),
      mapStyleProvider.overrideWith((ref) async => '{}'),
    ],
  );
}

Future<MapAlert?> _firstAlert(ProviderContainer container) async {
  final subscription = container.listen(mapAlertsProvider, (_, _) {});
  addTearDown(subscription.close);
  await pumpEventQueue();
  return container.read(mapAlertsProvider).firstOrNull;
}

void main() {
  test('stays quiet when every signal is healthy', () async {
    final container = _container();
    addTearDown(container.dispose);

    expect(await _firstAlert(container), isNull);
  });

  test('surfaces a denied location permission', () async {
    final container = _container(
      gps: const GpsHealthState(permissionDenied: true),
    );
    addTearDown(container.dispose);

    final alert = await _firstAlert(container);
    expect(alert?.kind, MapAlertKind.gpsPermissionDenied);
    expect(alert?.severity, MapAlertSeverity.critical);
  });

  test('surfaces an AUP download failure', () async {
    final container = _container();
    addTearDown(container.dispose);
    container.read(airspaceDataStatusProvider.notifier).markFailure('LZBB');

    final alert = await _firstAlert(container);
    expect(alert?.kind, MapAlertKind.airspaceDataUnavailable);
    expect(alert?.severity, MapAlertSeverity.warning);
  });

  test('updates oil temperature alerts at the configured limits', () async {
    final container = _container();
    addTearDown(container.dispose);
    expect(await _firstAlert(container), isNull);
    final telemetry = container.read(telemetryProvider.notifier) as _Telemetry;

    telemetry.emit(
      const TelemetryState(isOilTempSupported: true, oilTemperature: 365),
    );
    await pumpEventQueue();
    final warning = container.read(mapAlertsProvider).single;
    expect(warning.kind, MapAlertKind.oilTemperature);
    expect(warning.severity, MapAlertSeverity.warning);

    telemetry.emit(
      const TelemetryState(isOilTempSupported: true, oilTemperature: 380),
    );
    await pumpEventQueue();
    final critical = container.read(mapAlertsProvider).single;
    expect(critical.isEngineOverheating, isTrue);
    expect(critical.severity, MapAlertSeverity.critical);
    expect(critical.since, warning.since);

    telemetry.emit(
      const TelemetryState(isOilTempSupported: true, oilTemperature: 360),
    );
    await pumpEventQueue();
    expect(container.read(mapAlertsProvider), isEmpty);
  });

  test('records ground alerts, peak readings and repeat episodes', () async {
    var now = DateTime.utc(2026, 11, 11, 12);
    await withClock(Clock(() => now), () async {
      final container = _container();
      addTearDown(container.dispose);
      expect(await _firstAlert(container), isNull);
      final telemetry =
          container.read(telemetryProvider.notifier) as _Telemetry;
      Future<void> emit(double temperature) async {
        telemetry.emit(
          TelemetryState(isOilTempSupported: true, oilTemperature: temperature),
        );
        await pumpEventQueue();
      }

      final started = now;
      await emit(370);
      now = now.add(const Duration(seconds: 5));
      await emit(385);
      now = now.add(const Duration(seconds: 1));
      await emit(390);
      now = now.add(const Duration(seconds: 4));
      await emit(360);

      final ended = container.read(mapAlertHistoryProvider).single;
      expect(ended.alert.since, started);
      expect(ended.alert.severity, MapAlertSeverity.critical);
      expect(ended.peak, 390);
      expect(ended.endedAt!.difference(started), const Duration(seconds: 10));
      expect(container.read(mapAlertsProvider), isEmpty);

      now = now.add(const Duration(seconds: 2));
      await emit(370);
      final entries = container.read(mapAlertHistoryProvider);
      expect(entries, hasLength(2));
      expect(entries.first.endedAt, isNull);
      expect(entries.first.alert.since, now);
      expect(entries.last, same(ended));
    });
  });

  test(
    'prioritizes overheating and identifies the affected cylinder',
    () async {
      final container = _container(gps: const GpsHealthState(fixLost: true));
      addTearDown(container.dispose);
      final telemetry =
          container.read(telemetryProvider.notifier) as _Telemetry;
      telemetry.emit(
        const TelemetryState(
          isOilTempSupported: true,
          isChtSupported: true,
          cylinderHeadTemperatures: [null, 430],
          isFuelSupported: true,
          fuelLevelPercent: 15,
        ),
      );

      final alert = await _firstAlert(container);
      expect(alert?.kind, MapAlertKind.cylinderTemperature);
      expect(alert?.instrumentIssue?.channel, 2);
      expect(alert?.isEngineOverheating, isTrue);
      expect(container.read(mapAlertsProvider).map((alert) => alert.kind), [
        MapAlertKind.cylinderTemperature,
        MapAlertKind.oilTemperature,
        MapAlertKind.gpsFixLost,
        MapAlertKind.fuelLevel,
      ]);
    },
  );

  test('retains every active condition in priority order', () async {
    final container = _container(
      gps: const GpsHealthState(fixLost: true),
      link: const TelemetryLinkHealthState(linkLost: true),
      traffic: const TrafficSourceHealthState(unavailable: true),
    );
    addTearDown(container.dispose);

    final alert = await _firstAlert(container);
    expect(alert?.kind, MapAlertKind.telemetryLinkLost);
    expect(container.read(mapAlertsProvider).map((alert) => alert.kind), [
      MapAlertKind.telemetryLinkLost,
      MapAlertKind.gpsFixLost,
      MapAlertKind.trafficSourceOffline,
    ]);
  });

  test('suppresses a short network drop', () async {
    final container = _container(linkAvailable: false);
    addTearDown(container.dispose);

    await _firstAlert(container);
    expect(container.read(mapAlertsProvider), isEmpty);
  });

  group('isInternetUnavailable', () {
    final now = DateTime.utc(2026, 11, 11, 12);

    test('is false while the link is available', () {
      expect(
        isInternetUnavailable(
          now: now,
          linkAvailable: true,
          offlineSince: now.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('waits for the grace period', () {
      expect(
        isInternetUnavailable(
          now: now,
          linkAvailable: false,
          offlineSince: now.subtract(const Duration(seconds: 2)),
        ),
        isFalse,
      );
      expect(
        isInternetUnavailable(
          now: now,
          linkAvailable: false,
          offlineSince: now.subtract(MapAlerts.internetGrace),
        ),
        isTrue,
      );
    });

    test('is false without an offline timestamp', () {
      expect(
        isInternetUnavailable(
          now: now,
          linkAvailable: false,
          offlineSince: null,
        ),
        isFalse,
      );
    });
  });
}
