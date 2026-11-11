@Tags(['visual'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart' show Geographic;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/services/mdns_service.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/map/presentation/components/controls/map_alert_indicator.dart';
import 'package:stork/features/map/presentation/components/controls/map_controls.dart';
import 'package:stork/features/map/presentation/components/controls/map_drawer.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/features/map/presentation/providers/map_alerts_provider.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/navigation/presentation/widgets/navigation_telemetry_widget.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/cannelloni_device.dart';
import 'package:stork/features/settings/domain/models/pilot.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
import 'package:stork/features/settings/domain/models/widget_position.dart';
import 'package:stork/features/settings/presentation/pages/settings_page.dart';
import 'package:stork/features/settings/presentation/pages/map_settings_page.dart';
import 'package:stork/features/settings/presentation/pages/flight_settings_page.dart';
import 'package:stork/features/settings/presentation/pages/traffic_settings_page.dart';
import 'package:stork/features/settings/presentation/pages/gateway_settings_page.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/settings/presentation/providers/pilot_provider.dart';
import 'package:stork/features/settings/presentation/providers/aircraft_provider.dart';
import 'package:stork/features/telemetry/data/puretrack_auth_service.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/domain/models/resolved_altitude.dart';
import 'package:stork/features/telemetry/domain/models/vario_state.dart';
import 'package:stork/features/telemetry/presentation/providers/agl_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/flight_duration_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/puretrack_auth_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/gdl90_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/vario_provider.dart';
import 'package:stork/features/telemetry/presentation/widgets/collision_warning_banner.dart';
import 'package:stork/features/telemetry/presentation/widgets/telemetry_card.dart';
import 'package:stork/features/telemetry/presentation/widgets/altitude_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/cylinder_temp_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/egt_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/flight_time_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/fuel_status_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/oil_pressure_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/oil_temp_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/rpm_horizontal_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/speed_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/vario_telemetry_widget.dart';
import 'package:stork/features/telemetry/presentation/widgets/vhf_radio_telemetry_widget.dart';
import 'package:stork/l10n/app_localizations.dart';

const _frame = ValueKey('visual-frame');

/// Muted, map-like backdrop so the indicator is judged against the surface it
/// is normally drawn over instead of a plain white page.
const _mapBackdrop = Color(0xFF7C8F9B);
const _devices = {
  'phone_portrait': Size(412, 892),
  'phone_landscape': Size(892, 412),
  'tablet_portrait': Size(800, 1280),
  'tablet_landscape': Size(1280, 800),
};
const _device = CannelloniDevice(
  name: 'Demo gateway',
  hostname: 'demo.local',
  ip: '192.0.2.10',
  port: 2000,
);

// Replace external services at the provider boundary. Never use saved user
// preferences, credentials, live GPS, sockets or online map tiles in goldens.
class _Settings extends AppSettingsNotifier {
  _Settings(this.mapFontSize);

  final double mapFontSize;

  @override
  AppSettings build() => AppSettings(
    autoSelectDevice: false,
    selectedDevice: _device,
    pilotId: 'demo-pilot',
    airplaneId: 'demo-aircraft',
    mapFontSize: mapFontSize,
    widgetPositions: const {'speed_widget': WidgetPosition(top: 100, left: 30)},
  );
}

class _Pilots extends PilotState {
  @override
  List<Pilot> build() => [const Pilot(id: 'demo-pilot', name: 'Demo pilot')];
}

class _Aircraft extends AircraftState {
  @override
  List<Aircraft> build() => [
    const Aircraft(id: 'demo-aircraft', name: 'Stork Demo'),
  ];
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState(
    isActive: true,
    points: [
      NavigationPoint(latitude: 48.6, longitude: 17.8, name: 'Piešťany'),
    ],
  );
}

class _OfflineMaps extends OfflineMapsNotifier {
  @override
  OfflineMapsState build() => OfflineMapsState(
    isDownloaded: true,
    downloadDate: DateTime(2026, 11, 6),
    regions: [
      OfflineMapArea(
        id: 'demo-area',
        northwest: const Geographic(lat: 49, lon: 17),
        southeast: const Geographic(lat: 48, lon: 18),
      ),
    ],
  );
}

class _Gateway extends CannelloniService {
  _Gateway(this.connected);

  final bool connected;

  @override
  bool build() => connected;
}

const _liveTelemetry = TelemetryState(
  latitude: 48.48,
  longitude: 17.65,
  isFlying: true,
  indicatedAirSpeed: 27,
  groundSpeed: 29,
  engineRPM: 5820,
  oilTemperature: 363.15,
  oilPressure: 540,
  isChtSupported: true,
  isEgtSupported: true,
  cylinderHeadTemperatures: [377.15, 412.15],
  exhaustGasTemperatures: [943.15, 981.15],
  fuelLevelPercent: 63,
  fuelVolumeLiters: 19,
  radioActiveFrequency: 118575,
  radioStandbyFrequency: 123500,
  radioActiveStationName: 'PIESTANY',
  radioStandbyStationName: 'AIR TO AIR',
  radioNodeId: 42,
  radioFlags: 6,
);

const _missingTelemetry = TelemetryState(
  isChtSupported: true,
  isEgtSupported: true,
  cylinderHeadTemperatures: [null, null],
  exhaustGasTemperatures: [null, null],
);

class _Telemetry extends TelemetryNotifier {
  _Telemetry(this.telemetry);

  final TelemetryState telemetry;

  @override
  TelemetryState build() => telemetry;
}

/// Drives the map status indicator without touching any health provider.
class _MapAlerts extends MapAlerts {
  _MapAlerts(this.alert);

  final MapAlert? alert;

  @override
  List<MapAlert> build() => [?alert];
}

class _Vario extends VarioNotifier {
  _Vario(this.hasFlightData);

  final bool hasFlightData;

  @override
  VarioState build() => hasFlightData
      ? const VarioState(verticalSpeed: 1.8, source: VarioSource.baro)
      : const VarioState();
}

class _FlightDuration extends FlightDuration {
  _FlightDuration(this.hasFlightData);

  final bool hasFlightData;

  @override
  FlightSummary build() => hasFlightData
      ? const FlightSummary(duration: Duration(minutes: 48, seconds: 12))
      : const FlightSummary();
}

class _Auth extends PureTrackNotifier {
  @override
  PureTrackAuthState build() => PureTrackAuthState.unauthenticated;
}

class _AuthService implements PureTrackAuthService {
  @override
  String? get currentUsername => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keep a fresh capture even when the baseline comparison succeeds.
class _CaptureComparator extends LocalFileComparator {
  _CaptureComparator(super.testFile);

  Future<void> _capture(Uri golden, Uint8List bytes) async {
    final root =
        Platform.environment['STORK_VISUAL_REPORT_DIR'] ?? 'build/visual-tests';
    final file = File('$root/current/${golden.pathSegments.last}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await _capture(golden, imageBytes);
    return super.compare(imageBytes, golden);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await _capture(golden, imageBytes);
    await super.update(golden, imageBytes);
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget page,
  Brightness brightness,
  Size size, {
  double mapFontSize = 1,
  double? collisionDistance,
  TelemetryState? telemetry,
  MapAlert? mapAlert,
  bool disableAnimations = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(() => _Settings(mapFontSize)),
        pilotStateProvider.overrideWith(_Pilots.new),
        navigationProvider.overrideWith(_Navigation.new),
        offlineMapsProvider.overrideWith(_OfflineMaps.new),
        aircraftStateProvider.overrideWith(_Aircraft.new),
        discoveredDevicesProvider.overrideWith(
          (ref) => Stream.value([_device]),
        ),
        cannelloniServiceProvider.overrideWith(
          () => _Gateway(telemetry?.indicatedAirSpeed != null),
        ),
        mapAlertsProvider.overrideWith(() => _MapAlerts(mapAlert)),
        if (telemetry != null) ...[
          telemetryProvider.overrideWith(() => _Telemetry(telemetry)),
          varioProvider.overrideWith(() => _Vario(telemetry.isFlying)),
          flightDurationProvider.overrideWith(
            () => _FlightDuration(telemetry.isFlying),
          ),
          aglProvider.overrideWith(
            (ref) => telemetry.isFlying
                ? const AglState(
                    heightAboveGround: 450,
                    resolvedAltitude: ResolvedAltitude(
                      mslValue: 750,
                      source: AltitudeSource.baro,
                    ),
                  )
                : const AglState(
                    resolvedAltitude: ResolvedAltitude(
                      source: AltitudeSource.none,
                    ),
                  ),
          ),
        ],
        pureTrackProvider.overrideWith(_Auth.new),
        pureTrackAuthServiceProvider.overrideWithValue(_AuthService()),
        gdl90HeartbeatActiveProvider.overrideWith((ref) => Stream.value(false)),
        if (collisionDistance != null) ...[
          activeCollisionAlertProvider.overrideWith(
            (ref) => TrafficAircraft(
              id: 'demo-traffic',
              callsign: 'OM-DEMO',
              latitude: 48.1,
              longitude: 17.1,
              altitude: 1100,
              track: 180,
              groundSpeed: 35,
              verticalSpeed: 0,
              aircraftType: 1,
              lastSeen: DateTime.utc(2026),
              isCollisionThreat: true,
              tCpa: 20,
              minDistance: collisionDistance,
            ),
          ),
          resolvedAltitudeProvider.overrideWith(
            (ref) => const ResolvedAltitude(
              mslValue: 1000,
              source: AltitudeSource.baro,
            ),
          ),
        ],
      ],
      child: RepaintBoundary(
        key: _frame,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
              disableAnimations: disableAnimations,
            ),
            child: child!,
          ),
          home: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  await expectLater(find.byKey(_frame), matchesGoldenFile('goldens/$name.png'));
}

Future<void> _checkCollisionBanner(
  WidgetTester tester,
  Brightness brightness,
  Size size, {
  required double mapFontSize,
  required double distance,
  required String expectedDistance,
  required String screenshot,
}) async {
  await _pump(
    tester,
    Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 40 * mapFontSize,
            left: 0,
            right: 0,
            child: const CollisionWarningBanner(),
          ),
        ],
      ),
    ),
    brightness,
    size,
    mapFontSize: mapFontSize,
    collisionDistance: distance,
  );
  expect(find.text(expectedDistance), findsOneWidget);
  expect(find.text('20 s'), findsOneWidget);
  expect(find.text('+100 m'), findsOneWidget);
  expect(
    tester.getBottomRight(find.byType(CollisionWarningBanner)).dy,
    lessThanOrEqualTo(size.height),
  );
  await _shot(tester, screenshot);
}

Future<void> _checkMapWidgets(
  WidgetTester tester,
  Brightness brightness,
  Size size, {
  required String screenshot,
  TelemetryState telemetry = _liveTelemetry,
  double mapFontSize = 1,
  bool flightOnly = false,
}) async {
  await _pump(
    tester,
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 16,
          children: [
            // These rows receive loose horizontal constraints on the map.
            const IntrinsicWidth(child: SpeedTelemetryWidget()),
            const IntrinsicWidth(child: AltitudeTelemetryWidget()),
            const IntrinsicWidth(child: VarioTelemetryWidget()),
            const FlightTimeTelemetryWidget(),
            const NavigationTelemetryWidget(),
            if (!flightOnly) ...[
              const OilTempTelemetryWidget(),
              const OilPressureTelemetryWidget(),
              const CylinderTempTelemetryWidget(),
              const EgtTelemetryWidget(),
              const FuelStatusTelemetryWidget(),
              const RpmHorizontalTelemetryWidget(),
              const VhfRadioTelemetryWidget(),
            ],
          ],
        ),
      ),
    ),
    brightness,
    size,
    telemetry: telemetry,
    mapFontSize: mapFontSize,
  );
  final instruments = find.byType(TelemetryCard);
  expect(instruments, findsNWidgets(flightOnly ? 5 : 12));
  for (final instrument in instruments.evaluate()) {
    final bounds = tester.getRect(find.byWidget(instrument.widget));
    expect(bounds.right, lessThanOrEqualTo(size.width));
    expect(bounds.bottom, lessThanOrEqualTo(size.height));
  }
  await _shot(tester, screenshot);
}

// The dialog displays wall-clock time. Keep it stable across host time zones.
final _alertSince = DateTime(2026, 11, 10, 13, 5);

Future<void> _checkMapAlert(
  WidgetTester tester,
  Brightness brightness,
  Size size, {
  required MapAlert? alert,
  required String screenshot,
  bool openDialog = false,
}) async {
  await _pump(
    tester,
    Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: _mapBackdrop)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MapControls(
              mapViewState: MapViewState.follow,
              onMenuPressed: () {},
              onGpsPressed: () {},
            ),
          ),
        ],
      ),
    ),
    brightness,
    size,
    mapAlert: alert,
    // A pulsing badge never settles; the captured frame must stay stable.
    disableAnimations: true,
  );

  final expectedIcon = alert == null
      ? Icons.shield_outlined
      : mapAlertIcon(alert.kind);
  expect(find.byIcon(expectedIcon), findsOneWidget);

  // The touch target stays 48 dp even when the visible badge is smaller.
  final target = tester.getRect(find.byType(MapAlertIndicator));
  expect(target.width, greaterThanOrEqualTo(48));
  expect(target.height, greaterThanOrEqualTo(48));

  if (openDialog) {
    await tester.tapAt(tester.getCenter(find.byIcon(expectedIcon)));
    await tester.pumpAndSettle();
    expect(find.byType(BaseDetailsDialog), findsOneWidget);
    expect(find.textContaining('Active since'), findsOneWidget);
  }

  await _shot(tester, screenshot);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    for (final entry in {
      'Roboto': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
      'MaterialIcons': ['MaterialIcons-Regular.otf'],
      // Explicit TextStyles and canvas labels use the test engine fallback.
      'Ubuntu': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
      'Arial': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
      'sans-serif': ['Roboto-Regular.ttf'],
      'monospace': ['Roboto-Regular.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final name in entry.value) {
        loader.addFont(
          File(
            'test/visual/fonts/$name',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      }
      await loader.load();
    }
    goldenFileComparator = _CaptureComparator(
      File('test/visual/stork_visual_test.dart').absolute.uri,
    );
  });

  for (final device in _devices.entries) {
    for (final brightness in Brightness.values) {
      final suffix = '${device.key}_en_${brightness.name}';
      final landscape = device.value.width > device.value.height;
      testWidgets('collision_$suffix', (tester) async {
        await _checkCollisionBanner(
          tester,
          brightness,
          device.value,
          mapFontSize: 1,
          distance: landscape ? 1000 : 1200,
          expectedDistance: landscape ? '1.0 km' : '1.2 km',
          screenshot: 'collision_$suffix',
        );
      });
      if (device.key.startsWith('phone')) {
        final name = 'collision_large_$suffix';
        testWidgets(name, (tester) async {
          await _checkCollisionBanner(
            tester,
            brightness,
            device.value,
            mapFontSize: 3,
            distance: landscape ? 999 : 1200,
            expectedDistance: landscape ? '999 m' : '1.2 km',
            screenshot: name,
          );
        });
      }
      testWidgets('drawer_$suffix', (tester) async {
        await _pump(
          tester,
          const Scaffold(drawer: MapDrawer(), drawerScrimColor: Colors.black45),
          brightness,
          device.value,
        );
        final context = tester.element(find.byType(Scaffold));
        final icon = AssetImage(
          brightness == Brightness.dark
              ? 'assets/images/app_icon_dark.png'
              : 'assets/images/app_icon.png',
        );
        await tester.runAsync(() async {
          await precacheImage(ResizeImage(icon, width: 84), context);
        });
        tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
        await tester.pumpAndSettle();
        expect(
          tester.widget<Image>(find.byType(Image)).image,
          ResizeImage(icon, width: 84),
        );
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
        await _shot(tester, 'drawer_$suffix');
      });
      for (final entry in <String, MapAlert?>{
        'quiet': null,
        'critical': MapAlert(kind: MapAlertKind.gpsFixLost, since: _alertSince),
        'warning': MapAlert(
          kind: MapAlertKind.terrainUnavailable,
          since: _alertSince,
        ),
        'info': MapAlert(
          kind: MapAlertKind.internetUnavailable,
          since: _alertSince,
        ),
      }.entries) {
        testWidgets('alert_${entry.key}_$suffix', (tester) async {
          await _checkMapAlert(
            tester,
            brightness,
            device.value,
            alert: entry.value,
            screenshot: 'alert_${entry.key}_$suffix',
          );
        });
      }
      if (device.key == 'phone_portrait') {
        testWidgets('alert_dialog_$suffix', (tester) async {
          await _checkMapAlert(
            tester,
            brightness,
            device.value,
            alert: MapAlert(kind: MapAlertKind.gpsFixLost, since: _alertSince),
            screenshot: 'alert_dialog_$suffix',
            openDialog: true,
          );
        });
      }
      for (final entry in <String, Widget>{
        'settings': const SettingsPage(),
        'map': const MapSettingsPage(),
        'flight': const FlightSettingsPage(),
        'traffic': const TrafficSettingsPage(),
        'gateway': const GatewaySettingsPage(),
      }.entries) {
        testWidgets('${entry.key}_$suffix', (tester) async {
          await _pump(tester, entry.value, brightness, device.value);
          final firstCard = tester.getRect(find.byType(Card).first);
          expect(firstCard.left, 16);
          expect(firstCard.right, device.value.width - 16);
          if (entry.key == 'map' || entry.key == 'traffic') {
            final firstSlider = tester.getRect(find.byType(Slider).first);
            expect(firstSlider.width, firstCard.width - 32);
            expect(firstSlider.height, greaterThanOrEqualTo(48));
          }
          await _shot(tester, '${entry.key}_$suffix');
          if (entry.key == 'flight' ||
              entry.key == 'traffic' ||
              entry.key == 'map') {
            final scrollable = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
            await tester.pumpAndSettle();
            await _shot(tester, '${entry.key}_bottom_$suffix');
          }
          if (entry.key == 'map') {
            await tester.tap(find.byIcon(Icons.restore).first);
            await tester.pumpAndSettle();
            await _shot(tester, 'map_reset_$suffix');
          }
        });
      }
      testWidgets('map_widgets_$suffix', (tester) async {
        await _checkMapWidgets(
          tester,
          brightness,
          device.value,
          screenshot: 'map_widgets_$suffix',
        );
      });
      if (device.key == 'phone_portrait') {
        testWidgets('map_widgets_no_data_$suffix', (tester) async {
          await _checkMapWidgets(
            tester,
            brightness,
            device.value,
            screenshot: 'map_widgets_no_data_$suffix',
            telemetry: _missingTelemetry,
          );
        });
        testWidgets('map_widgets_large_$suffix', (tester) async {
          await _checkMapWidgets(
            tester,
            brightness,
            device.value,
            screenshot: 'map_widgets_large_$suffix',
            mapFontSize: 2,
            flightOnly: true,
          );
        });
      }
      testWidgets('telemetry_$suffix', (tester) async {
        final width = device.value.width > device.value.height
            ? (device.value.width - 80) / 3
            : device.value.width - 48;
        await _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 24,
                  children: [
                    for (final state in [
                      ThresholdState.operational,
                      ThresholdState.maxWarning,
                      ThresholdState.maxError,
                    ])
                      SizedBox(
                        width: width,
                        child: TelemetryCard(
                          state: state,
                          disableAnimations: true,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'RPM  5 800\n${state.name}',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          brightness,
          device.value,
        );
        await _shot(tester, 'telemetry_$suffix');
      });
    }
  }
}
