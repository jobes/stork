import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/presentation/models/map_alert.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';

void main() {
  group('mostImportantAlert', () {
    test('returns null when nothing is active', () {
      expect(mostImportantAlert(const {}), isNull);
    });

    test('prefers GPS problems over every lower signal', () {
      expect(
        mostImportantAlert(const {
          MapAlertKind.internetUnavailable,
          MapAlertKind.trafficSourceOffline,
          MapAlertKind.gpsFixLost,
          MapAlertKind.altitudeSourceChanged,
        }),
        MapAlertKind.gpsFixLost,
      );
    });

    test('falls back to the next condition once the top one clears', () {
      expect(
        mostImportantAlert(const {
          MapAlertKind.internetUnavailable,
          MapAlertKind.airspaceDataUnavailable,
        }),
        MapAlertKind.airspaceDataUnavailable,
      );
    });

    test('keeps a lost telemetry link above a stale one', () {
      expect(
        mostImportantAlert(const {
          MapAlertKind.telemetryStale,
          MapAlertKind.telemetryLinkLost,
        }),
        MapAlertKind.telemetryLinkLost,
      );
    });

    test('severity outranks the declaration order', () {
      // `telemetryStale` is declared first but is only a warning, so a
      // critical missing altitude must win.
      expect(
        mostImportantAlert(const {
          MapAlertKind.telemetryStale,
          MapAlertKind.altitudeUnavailable,
        }),
        MapAlertKind.altitudeUnavailable,
      );
      // `internetUnavailable` is informational and declared first, so it must
      // not hide warnings.
      expect(
        mostImportantAlert(const {
          MapAlertKind.internetUnavailable,
          MapAlertKind.terrainUnavailable,
          MapAlertKind.offlineMapsError,
        }),
        MapAlertKind.terrainUnavailable,
      );
    });

    test('declaration order breaks ties inside one severity', () {
      expect(
        mostImportantAlert(const {
          MapAlertKind.trafficSourceOffline,
          MapAlertKind.telemetryStale,
        }),
        MapAlertKind.telemetryStale,
      );
    });

    test('never picks a condition less severe than any active one', () {
      for (final a in MapAlertKind.values) {
        for (final b in MapAlertKind.values) {
          final winner = mostImportantAlert({a, b})!;
          expect(winner.severity.index, lessThanOrEqualTo(a.severity.index));
          expect(winner.severity.index, lessThanOrEqualTo(b.severity.index));
        }
      }
    });
  });

  group('MapAlertKind severity', () {
    test('severe conditions are critical', () {
      expect(
        MapAlertKind.mapStyleUnavailable.severity,
        MapAlertSeverity.critical,
      );
      expect(
        MapAlertKind.gpsPermissionDenied.severity,
        MapAlertSeverity.critical,
      );
      expect(MapAlertKind.gpsFixLost.severity, MapAlertSeverity.critical);
      expect(
        MapAlertKind.telemetryLinkLost.severity,
        MapAlertSeverity.critical,
      );
      expect(
        MapAlertKind.altitudeUnavailable.severity,
        MapAlertSeverity.critical,
      );
    });

    test('degraded but usable conditions are warnings', () {
      expect(MapAlertKind.telemetryStale.severity, MapAlertSeverity.warning);
      expect(
        MapAlertKind.trafficSourceOffline.severity,
        MapAlertSeverity.warning,
      );
      expect(
        MapAlertKind.terrainUnavailable.severity,
        MapAlertSeverity.warning,
      );
      expect(MapAlertKind.offlineMapsError.severity, MapAlertSeverity.warning);
    });

    test('informational conditions do not pulse', () {
      // Flying without mobile data is normal for gliders, so a lost network
      // link must not raise a pulsing warning.
      expect(MapAlertKind.internetUnavailable.severity, MapAlertSeverity.info);
      expect(
        MapAlertKind.altitudeSourceChanged.severity,
        MapAlertSeverity.info,
      );
    });
  });

  test('MapAlert exposes the kind severity', () {
    final alert = MapAlert(
      kind: MapAlertKind.telemetryStale,
      since: DateTime(2026, 11, 11),
    );

    expect(alert.severity, MapAlertSeverity.warning);
    expect(alert, equals(MapAlert(kind: alert.kind, since: alert.since)));
  });

  test(
    'orders aircraft link loss before measured overheating and data loss',
    () {
      final since = DateTime(2026, 11, 11);
      final alerts = [
        MapAlert(
          kind: MapAlertKind.oilTemperature,
          since: since,
          instrumentIssue: (
            state: ThresholdState.maxError,
            unavailable: true,
            channel: null,
          ),
        ),
        MapAlert(kind: MapAlertKind.telemetryLinkLost, since: since),
        MapAlert(
          kind: MapAlertKind.cylinderTemperature,
          since: since,
          instrumentIssue: (
            state: ThresholdState.maxError,
            unavailable: false,
            channel: 2,
          ),
        ),
        MapAlert(kind: MapAlertKind.collisionThreat, since: since),
      ]..sort((a, b) => a.comparePriority(b));

      expect(alerts.map((alert) => alert.kind), [
        MapAlertKind.collisionThreat,
        MapAlertKind.telemetryLinkLost,
        MapAlertKind.cylinderTemperature,
        MapAlertKind.oilTemperature,
      ]);
    },
  );

  test(
    'ranks stale telemetry before instrument warnings within its severity',
    () {
      final since = DateTime(2026, 11, 11);
      final stale = MapAlert(kind: MapAlertKind.telemetryStale, since: since);
      final warning = MapAlert(
        kind: MapAlertKind.oilTemperature,
        since: since,
        instrumentIssue: (
          state: ThresholdState.maxWarning,
          unavailable: false,
          channel: null,
        ),
      );
      expect(stale.comparePriority(warning), lessThan(0));
    },
  );
}
