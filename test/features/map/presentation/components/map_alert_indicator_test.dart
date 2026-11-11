import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/presentation/components/controls/map_alert_indicator.dart';
import 'package:stork/features/map/presentation/components/controls/map_controls.dart';
import 'package:stork/features/map/presentation/providers/map_alert_history_provider.dart';
import 'package:stork/features/map/presentation/providers/map_alerts_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/domain/models/flight_alert_record.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/temperature_trend_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

class _StubMapAlerts extends MapAlerts {
  _StubMapAlerts(this.alerts);

  final List<MapAlert> alerts;

  @override
  List<MapAlert> build() => alerts;

  void emit(List<MapAlert> alerts) => state = alerts;
}

class _Telemetry extends TelemetryNotifier {
  _Telemetry(this.initial);

  final TelemetryState initial;

  @override
  TelemetryState build() => initial;

  void emit(TelemetryState next) => state = next;
}

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

Widget _app({
  required MapAlert? alert,
  List<MapAlert> otherAlerts = const [],
  bool disableAnimations = true,
  TelemetryState telemetry = const TelemetryState(),
  Widget body = const Center(child: MapAlertIndicator()),
}) {
  return ProviderScope(
    overrides: [
      telemetryProvider.overrideWith(() => _Telemetry(telemetry)),
      appSettingsProvider.overrideWith(_Settings.new),
      mapAlertsProvider.overrideWith(
        () => _StubMapAlerts([?alert, ...otherAlerts]),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: body),
      ),
    ),
  );
}

/// Combined scale applied by the entrance and pulse transforms.
double _badgeScale(WidgetTester tester) {
  final transforms = tester
      .widgetList<Transform>(
        find.ancestor(
          of: find.byIcon(Icons.gps_off),
          matching: find.byType(Transform),
        ),
      )
      .toList();
  var scale = 1.0;
  for (final transform in transforms) {
    scale *= transform.transform.getMaxScaleOnAxis();
  }
  return scale;
}

void main() {
  testWidgets('shows stored flight alerts with channel and duration', (
    tester,
  ) async {
    final start = DateTime(2026, 11, 11, 12);
    await tester.pumpWidget(
      _app(
        alert: null,
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showRecordedFlightAlerts(
              context,
              Future.value([
                FlightAlertRecord(
                  flightUuid: 'flight',
                  episodeId: 'alert',
                  kind: 'cylinderTemperature',
                  severity: 'critical',
                  startedAt: start,
                  endedAt: start.add(const Duration(seconds: 25)),
                  threshold: 'maxError',
                  channel: 2,
                ),
              ]),
            ),
            child: const Text('Open flight alerts'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open flight alerts'));
    await tester.pumpAndSettle();

    expect(find.text('Engine overheating · CHT'), findsOneWidget);
    expect(find.textContaining('Cylinder 2'), findsOneWidget);
    expect(find.textContaining('Duration 00:25'), findsOneWidget);
  });

  testWidgets('shows an overheating icon and identifies the cylinder', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        alert: MapAlert(
          kind: MapAlertKind.cylinderTemperature,
          since: DateTime(2026, 11, 10, 12),
          instrumentIssue: (
            state: ThresholdState.maxError,
            unavailable: false,
            channel: 2,
          ),
        ),
      ),
    );

    final indicator = find.byType(MapAlertIndicator);
    expect(find.byIcon(Icons.thermostat), findsOneWidget);
    await tester.tap(indicator);
    await tester.pumpAndSettle();
    expect(find.text('Engine overheating · CHT'), findsOneWidget);
    expect(find.textContaining('Cylinder 2'), findsOneWidget);
    expect(find.textContaining('upper critical limit'), findsOneWidget);
  });

  testWidgets(
    'keeps map controls and alert geometry stable across severities',
    (tester) async {
      const gpsKey = ValueKey('gps');
      const menuKey = ValueKey('menu');
      await tester.pumpWidget(
        _app(
          alert: null,
          body: Align(
            alignment: Alignment.topCenter,
            child: MapControls(
              mapViewState: MapViewState.follow,
              onMenuPressed: () {},
              onGpsPressed: () {},
              gpsButtonKey: gpsKey,
              menuButtonKey: menuKey,
            ),
          ),
        ),
      );
      final indicator = find.byType(MapAlertIndicator);
      final gps = find.byKey(gpsKey);
      final menu = find.byKey(menuKey);
      final target = tester.getRect(indicator);
      final gpsRect = tester.getRect(gps);
      final menuRect = tester.getRect(menu);
      final alerts =
          ProviderScope.containerOf(
                tester.element(indicator),
                listen: false,
              ).read(mapAlertsProvider.notifier)
              as _StubMapAlerts;

      expect(target.size, const Size.square(48));
      expect(
        tester.getCenter(find.byIcon(Icons.shield_outlined)),
        target.center,
      );
      for (final kind in [
        MapAlertKind.internetUnavailable,
        MapAlertKind.terrainUnavailable,
        MapAlertKind.gpsFixLost,
      ]) {
        alerts.emit([MapAlert(kind: kind, since: DateTime(2026, 11, 11))]);
        await tester.pumpAndSettle();

        expect(tester.getRect(indicator), target);
        expect(tester.getRect(gps), gpsRect);
        expect(tester.getRect(menu), menuRect);
        final icon = find.byIcon(mapAlertIcon(kind));
        expect(tester.getCenter(icon), target.center);
        expect(tester.widget<Icon>(icon).size, 25);
      }
    },
  );

  testWidgets('shows a quiet shield when no alert is active', (tester) async {
    await tester.pumpWidget(_app(alert: null));

    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.byIcon(Icons.gps_off), findsNothing);
  });

  testWidgets('shows the most important alert icon', (tester) async {
    await tester.pumpWidget(
      _app(
        alert: MapAlert(
          kind: MapAlertKind.internetUnavailable,
          since: DateTime(2026, 11, 10, 12),
        ),
      ),
    );

    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    // No visible text next to the icon; the condition is only announced to
    // screen readers through the semantics label.
    expect(find.text('No internet connection'), findsNothing);
  });

  testWidgets('keeps pulsing while a critical alert is active', (tester) async {
    await tester.pumpWidget(
      _app(
        alert: MapAlert(
          kind: MapAlertKind.gpsFixLost,
          since: DateTime(2026, 11, 10, 12, 5),
        ),
        disableAnimations: false,
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    final firstScale = _badgeScale(tester);

    await tester.pump(const Duration(milliseconds: 400));
    final secondScale = _badgeScale(tester);

    expect(secondScale, isNot(equals(firstScale)));
  });

  testWidgets('does not pulse when the system disables animations', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        alert: MapAlert(
          kind: MapAlertKind.gpsFixLost,
          since: DateTime(2026, 11, 10, 12, 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstScale = _badgeScale(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(_badgeScale(tester), equals(firstScale));
  });

  testWidgets('opens a detail with all active alerts in priority order', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        alert: MapAlert(
          kind: MapAlertKind.gpsFixLost,
          since: DateTime(2026, 11, 10, 12, 5),
        ),
        otherAlerts: [
          MapAlert(
            kind: MapAlertKind.internetUnavailable,
            since: DateTime(2026, 11, 10, 12),
          ),
        ],
      ),
    );

    // Let the entrance animation finish so the badge is fully hit-testable.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(tester.getCenter(find.byIcon(Icons.gps_off)));
    await tester.pumpAndSettle();

    expect(find.text('GPS signal lost'), findsAtLeastNWidgets(1));
    expect(find.text('2 active alerts'), findsOneWidget);
    expect(
      find.textContaining(
        'The aircraft position on the map may be out of date',
      ),
      findsOneWidget,
    );
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.textContaining('Active since'), findsNWidgets(2));
  });

  testWidgets('shows live readings and limits for simultaneous alerts', (
    tester,
  ) async {
    final since = DateTime(2026, 11, 10, 12);
    const telemetry = TelemetryState(
      isChtSupported: true,
      cylinderHeadTemperatures: [408.15, 429.15],
      isFuelSupported: true,
      fuelLevelPercent: 15,
    );
    await tester.pumpWidget(
      _app(
        telemetry: telemetry,
        alert: MapAlert(
          kind: MapAlertKind.cylinderTemperature,
          since: since,
          instrumentIssue: (
            state: ThresholdState.maxError,
            unavailable: false,
            channel: 2,
          ),
        ),
        otherAlerts: [
          MapAlert(
            kind: MapAlertKind.fuelLevel,
            since: since,
            instrumentIssue: (
              state: ThresholdState.minWarning,
              unavailable: false,
              channel: null,
            ),
          ),
        ],
      ),
    );
    final indicator = find.byType(MapAlertIndicator);
    final container = ProviderScope.containerOf(
      tester.element(indicator),
      listen: false,
    );
    await tester.tap(indicator);
    await tester.pumpAndSettle();

    expect(find.text('2 active alerts'), findsOneWidget);
    expect(find.text('Cylinder 2'), findsOneWidget);
    expect(find.text('Measured 156.0 °C'), findsOneWidget);
    expect(find.text('Critical limit 150.0 °C'), findsOneWidget);
    expect(find.text('Cylinder 1'), findsOneWidget);
    expect(find.text('Warning limit 130.0 °C'), findsOneWidget);
    expect(find.text('Measured 15.0 %'), findsOneWidget);
    expect(find.text('Warning limit 20.0 %'), findsOneWidget);

    final trend = container.read(temperatureTrendProvider.notifier);
    for (var second = 0; second <= 30; second++) {
      trend.sample(
        since.add(Duration(seconds: second)),
        telemetry.copyWith(
          cylinderHeadTemperatures: TelemetryValue([
            408.15,
            426.15 + second / 10,
          ]),
        ),
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('Temperature rising · +3.0 °C in 30 s'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);

    trend.sample(
      since.add(const Duration(seconds: 31)),
      telemetry.copyWith(
        cylinderHeadTemperatures: const TelemetryValue([408.15, null]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.trending_up), findsNothing);

    final source = container.read(telemetryProvider.notifier) as _Telemetry;
    source.emit(
      telemetry.copyWith(
        cylinderHeadTemperatures: const TelemetryValue([408.15, 431.15]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Measured 158.0 °C'), findsOneWidget);
    expect(find.text('Measured 156.0 °C'), findsNothing);
  });

  testWidgets('opens completed history from the quiet status dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_app(alert: null));
    final indicator = find.byType(MapAlertIndicator);
    final container = ProviderScope.containerOf(
      tester.element(indicator),
      listen: false,
    );
    final history = container.read(mapAlertHistoryProvider.notifier);
    final start = DateTime(2026, 11, 11, 12);
    history.observeSystemAlerts([
      MapAlert(kind: MapAlertKind.gpsFixLost, since: start),
    ], start);
    history.observeSystemAlerts([], start.add(const Duration(seconds: 25)));

    await tester.tap(indicator);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alert history'));
    await tester.pumpAndSettle();
    expect(find.text('GPS signal lost'), findsOneWidget);
    expect(find.textContaining('Duration 00:25'), findsOneWidget);
  });

  testWidgets('explains that all systems are fine when tapped without alerts', (
    tester,
  ) async {
    await tester.pumpWidget(_app(alert: null));

    final target = tester.getRect(find.byType(MapAlertIndicator));
    final tap = target.centerLeft + const Offset(2, 0);
    expect(
      tester.getRect(find.byIcon(Icons.shield_outlined)).contains(tap),
      isFalse,
    );
    await tester.tapAt(tap);
    await tester.pumpAndSettle();

    expect(find.text('System status'), findsOneWidget);
    expect(
      find.text('All monitored systems are working normally.'),
      findsOneWidget,
    );
  });

  testWidgets('updates the open dialog as alerts appear and clear', (
    tester,
  ) async {
    await tester.pumpWidget(_app(alert: null));
    final indicator = find.byType(MapAlertIndicator);
    final container = ProviderScope.containerOf(
      tester.element(indicator),
      listen: false,
    );
    final alerts = container.read(mapAlertsProvider.notifier) as _StubMapAlerts;
    await tester.tap(indicator);
    await tester.pumpAndSettle();

    alerts.emit([
      MapAlert(
        kind: MapAlertKind.gpsFixLost,
        since: DateTime(2026, 11, 10, 12),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('GPS signal lost'), findsOneWidget);

    alerts.emit([]);
    await tester.pumpAndSettle();
    expect(find.text('GPS signal lost'), findsNothing);
    expect(
      find.text('All monitored systems are working normally.'),
      findsOneWidget,
    );
  });
}
