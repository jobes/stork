@Tags(['visual'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maplibre/maplibre.dart' show Geographic;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/settings/presentation/dialogs/aircraft_settings_dialog.dart';
import 'package:stork/features/navigation/presentation/dialogs/navigation_details_dialog.dart';
import 'package:stork/features/navigation/presentation/pages/navigation_page.dart';
import 'package:stork/features/map/presentation/components/controls/map_features_bottom_sheet.dart';
import 'package:stork/features/weather/presentation/providers/route_timing_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/throttled_telemetry_provider.dart';
import 'package:stork/features/weather/data/models/forecast_series.dart';
import 'package:stork/features/weather/domain/forecast_query.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/domain/wind_route_timing.dart';
import 'package:stork/features/weather/domain/weather_hazard.dart';
import 'package:stork/features/weather/presentation/providers/weather_hazard_provider.dart';
import 'package:stork/features/weather/presentation/dialogs/flight_weather_details_dialog.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/services/mdns_service.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:stork/features/map/data/services/map_search.dart';
import 'package:stork/features/map/domain/models/poi_type.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';
import 'package:stork/features/map/presentation/components/controls/map_alert_indicator.dart';
import 'package:stork/features/map/presentation/components/controls/map_controls.dart';
import 'package:stork/features/map/presentation/components/controls/map_drawer.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/features/map/presentation/components/dialogs/map_search_dialog.dart';
import 'package:stork/features/map/presentation/providers/map_alerts_provider.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/navigation/presentation/widgets/navigation_telemetry_widget.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';
import 'package:stork/features/settings/domain/models/speed_unit.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/cannelloni_device.dart';
import 'package:stork/features/settings/domain/models/pilot.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
import 'package:stork/features/settings/domain/models/widget_position.dart';
import 'package:stork/features/settings/presentation/pages/settings_page.dart';
import 'package:stork/features/settings/presentation/pages/data_sources_page.dart';
import 'package:stork/features/settings/presentation/pages/map_settings_page.dart';
import 'package:stork/features/settings/presentation/pages/widget_settings_page.dart';
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

import '../helpers/source_logo_http.dart';

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
  _Settings(this.mapControlScale);

  final double mapControlScale;

  @override
  AppSettings build() => AppSettings(
    autoSelectDevice: false,
    selectedDevice: _device,
    pilotId: 'demo-pilot',
    airplaneId: 'demo-aircraft',
    mapControlScale: mapControlScale,
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
      NavigationPoint(
        latitude: 48.6,
        longitude: 17.8,
        name: 'Piešťany',
        weatherAltitudeFeet: 2500,
      ),
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

class _Notams extends Notams {
  @override
  Future<NotamFetchResult> build() async => const NotamFetchResult([]);
}

class _SearchFavorites extends FavoritesNotifier {
  @override
  Future<List<FavoritePoint>> build() async => const [
    FavoritePoint(
      id: 'martov-favorite',
      name: 'Martovce riverside',
      latitude: 47.854,
      longitude: 18.122,
      icon: PoiType.viewpoint,
    ),
  ];
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
  double mapControlScale = 1,
  double? collisionDistance,
  TelemetryState? telemetry,
  MapAlert? mapAlert,
  bool disableAnimations = false,
  bool flightWeather = false,
  SpeedUnit windUnit = SpeedUnit.kmh,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith(
          () => flightWeather
              ? _WeatherVisualSettings(windUnit)
              : _Settings(mapControlScale),
        ),
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
        notamsProvider.overrideWith(_Notams.new),
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
        ...overrides,
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

final _weatherTime = DateTime.utc(2026, 11, 16, 14);
const _weatherLocation = (latitude: 48.6, longitude: 17.8);

class _WeatherVisualSettings extends _Settings {
  _WeatherVisualSettings(this.windUnit) : super(1);

  final SpeedUnit windUnit;

  @override
  AppSettings build() =>
      super.build().copyWith(showFlightWeather: true, windSpeedUnit: windUnit);
}

class _WeatherVisualTelemetry extends ThrottledTelemetry {
  @override
  TelemetryState build() => const TelemetryState(
    latitude: 48.2,
    longitude: 17.2,
    groundSpeed: 25,
    isFlying: true,
  );
}

class _WeatherVisualPlan extends FlightWeatherPlanNotifier {
  @override
  List<ForecastRoutePoint> build() => [
    ForecastRoutePoint(
      id: 'waypoint-0',
      location: _weatherLocation,
      eta: _weatherTime.add(const Duration(minutes: 30)),
      duration: const Duration(minutes: 30),
      distanceMeters: 45000,
      altitudeFeet: 2500,
      bearing: 30,
      waypointIndex: 0,
    ),
  ];
}

ForecastSeries _visualWeatherSeries() => ForecastSeries.fromJson({
  'elevation': 165,
  'hourly': {
    'time': [
      for (var i = 0; i < 3; i++)
        _weatherTime.add(Duration(hours: i)).millisecondsSinceEpoch ~/ 1000,
    ],
    'surface_pressure': [997, 996, 995],
    'temperature_2m': [14, 15, 14],
    'wind_speed_950hPa': [18, 22, 20],
    'wind_direction_950hPa': [260, 270, 265],
    'geopotential_height_950hPa': [500, 500, 500],
    'wind_speed_900hPa': [28, 32, 30],
    'wind_direction_900hPa': [280, 290, 285],
    'geopotential_height_900hPa': [1000, 1000, 1000],
    'temperature_950hPa': [12, 13, 12],
    'temperature_900hPa': [8, 9, 8],
    'wind_gusts_10m': [25, 38, 35],
    'precipitation': [0, 0.4, 0],
    'cloud_cover_low': [35, 55, 40],
  },
}, _weatherTime.subtract(const Duration(minutes: 15)));

Future<void> _openWeatherVisual(
  WidgetTester tester,
  Brightness brightness,
  Size size, {
  bool unavailable = false,
  double? terrain = 165,
  bool navigation = false,
  bool routePage = false,
  bool widgetOnly = false,
  bool pointMenu = false,
  bool hazard = false,
  SpeedUnit windUnit = SpeedUnit.kmh,
}) async {
  await _pump(
    tester,
    routePage
        ? const NavigationPage()
        : Scaffold(
            body: widgetOnly
                ? const Center(child: NavigationTelemetryWidget())
                : Consumer(
                    builder: (context, ref, _) => TextButton(
                      onPressed: () {
                        if (pointMenu) {
                          showMapFeaturesBottomSheet(context, const [
                            {
                              'layerType': 'flight-weather',
                              'properties': {'forecastId': 'waypoint-0'},
                            },
                          ], const Geographic(lat: 48.6, lon: 17.8));
                        } else {
                          showDialog<void>(
                            context: context,
                            builder: (_) => navigation
                                ? const NavigationDetailsDialog()
                                : const FlightWeatherDetailsDialog(
                                    pointId: 'waypoint-0',
                                  ),
                          );
                        }
                      },
                      child: const Text('Open forecast'),
                    ),
                  ),
          ),
    brightness,
    size,
    flightWeather: true,
    windUnit: windUnit,
    overrides: [
      activeWeatherHazardDetailsProvider.overrideWith(
        (ref) => hazard
            ? [
                (
                  pointId: 'waypoint-0',
                  location: _weatherLocation,
                  time: _weatherTime.add(const Duration(minutes: 30)),
                  altitudeFeet: 2500.0,
                  hazards: {
                    WeatherHazard.wind,
                    WeatherHazard.gust,
                    WeatherHazard.fog,
                  },
                  windMs: 25 / 3.6,
                  gustMs: 38 / 3.6,
                  windLimitMs: 20 / 3.6,
                  gustLimitMs: 35 / 3.6,
                  precipitationMm: 0.0,
                  intervalEnd: _weatherTime.add(const Duration(hours: 1)),
                ),
              ]
            : [],
      ),
      activeWeatherHazardsProvider.overrideWith(
        (ref) => hazard ? {WeatherHazard.wind, WeatherHazard.fog} : {},
      ),
      throttledTelemetryProvider.overrideWith(_WeatherVisualTelemetry.new),
      flightWeatherPlanProvider.overrideWith(_WeatherVisualPlan.new),
      forecastPointTerrainProvider(
        _weatherLocation,
      ).overrideWith((ref) async => terrain),
      flightForecastProfilesProvider.overrideWith(
        (ref) async => (
          series: unavailable
              ? <String, ForecastSeries>{}
              : {forecastLocationKey(_weatherLocation): _visualWeatherSeries()},
          refreshFailed: !unavailable,
        ),
      ),
      routePointTimingProvider.overrideWith(
        (ref) => {
          'waypoint-0': (
            eta: _weatherTime.add(const Duration(minutes: 30)),
            duration: const Duration(minutes: 30),
            sources: {RouteTimingSource.gps, RouteTimingSource.wind},
            windEffect: const Duration(minutes: 4),
          ),
        },
      ),
    ],
  );
  if (!routePage && !widgetOnly) {
    await tester.tap(find.text('Open forecast'));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollDialogTo(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byType(BaseDetailsDialog).first,
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
  await tester.pumpAndSettle();
  final rect = tester.getRect(target);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
}

Future<void> _shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  await expectLater(find.byKey(_frame), matchesGoldenFile('goldens/$name.png'));
}

Future<void> _checkCollisionBanner(
  WidgetTester tester,
  Brightness brightness,
  Size size, {
  required double mapControlScale,
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
            top: 40 * mapControlScale,
            left: 0,
            right: 0,
            child: const CollisionWarningBanner(),
          ),
        ],
      ),
    ),
    brightness,
    size,
    mapControlScale: mapControlScale,
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
  double mapControlScale = 1,
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
    mapControlScale: mapControlScale,
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
  List<Override> overrides = const [],
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
              onSearchPressed: () {},
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
    overrides: overrides,
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

Future<void> _openMapSearch(
  WidgetTester tester, {
  required Brightness brightness,
  required String device,
  required MockClient photon,
  int airportCount = 1,
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
            child: Builder(
              builder: (context) => MapControls(
                mapViewState: MapViewState.follow,
                onMenuPressed: () {},
                onGpsPressed: () {},
                onSearchPressed: () => showMapSearchDialog(
                  context,
                  latitude: 48.15,
                  longitude: 17.11,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    brightness,
    _devices[device]!,
    disableAnimations: true,
    overrides: [
      airportSearchRecordsProvider.overrideWith(
        (_) => [
          const {
            'name': 'MARTIN',
            'icaoCode': 'LZMA',
            'latitude': 49.0665,
            'longitude': 18.9504,
          },
          for (var i = 1; i < airportCount; i++)
            {
              'name': 'Martin airfield $i',
              'latitude': 49.068,
              'longitude': 18.951,
            },
        ],
      ),
      favoritesProvider.overrideWith(_SearchFavorites.new),
      photonSearchProvider.overrideWithValue(PhotonSearch(photon)),
    ],
  );

  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();
  expect(find.byType(TextField), findsOneWidget);
}

http.Response _mapSearchResponse({required bool hasResults}) => http.Response(
  jsonEncode({
    'features': [
      if (hasResults)
        {
          'properties': {
            'name': 'Martovce',
            'county': 'Komárno district',
            'country': 'Slovakia',
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [18.1257, 47.8566],
          },
        },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _enterMapSearchQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void _expectMapSearchGroups(WidgetTester tester, List<String> labels) {
  final rows = labels.map((label) => find.text(label)).toList();
  for (final row in rows) {
    expect(row.hitTestable(), findsOneWidget);
  }
  for (var i = 1; i < rows.length; i++) {
    expect(
      tester.getTopLeft(rows[i]).dy,
      greaterThan(tester.getTopLeft(rows[i - 1]).dy),
    );
  }
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

  testWidgets('map_search_phone_portrait_en_light', (tester) async {
    await _openMapSearch(
      tester,
      brightness: Brightness.light,
      device: 'phone_portrait',
      photon: MockClient(
        (request) async => _mapSearchResponse(
          hasResults: request.url.queryParameters['q'] == 'mart',
        ),
      ),
    );

    expect(find.text('Airport, favourite or town'), findsOneWidget);
    await _shot(tester, 'map_search_open_phone_portrait_en_light');

    await _enterMapSearchQuery(tester, 'mart');
    await tester.pumpAndSettle();
    _expectMapSearchGroups(tester, [
      'Airports',
      'Favourites',
      'Towns and villages',
    ]);
    await _shot(tester, 'map_search_results_phone_portrait_en_light');

    await _enterMapSearchQuery(tester, 'zzqq');
    await tester.pumpAndSettle();
    expect(find.text('No towns or villages found.'), findsOneWidget);
    await _shot(tester, 'map_search_empty_phone_portrait_en_light');
  });

  testWidgets('map_search_phone_landscape_en_dark', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 165);
    addTearDown(tester.view.resetViewInsets);
    final response = Completer<http.Response>();
    await _openMapSearch(
      tester,
      brightness: Brightness.dark,
      device: 'phone_landscape',
      airportCount: 19,
      photon: MockClient((_) => response.future),
    );

    await _enterMapSearchQuery(tester, 'martin');
    // Capture the spinner at a fixed point in its indeterminate animation.
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.text('Searching for towns and villages…').hitTestable(),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.flight).hitTestable(), findsWidgets);
    await _shot(tester, 'map_search_loading_phone_landscape_en_dark');

    response.complete(http.Response('', 503));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load towns and villages.').hitTestable(),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.flight).hitTestable(), findsWidgets);
    await _shot(tester, 'map_search_error_phone_landscape_en_dark');
  });

  testWidgets('map_search_tablet_landscape_en_dark', (tester) async {
    await _openMapSearch(
      tester,
      brightness: Brightness.dark,
      device: 'tablet_landscape',
      photon: MockClient((_) async => _mapSearchResponse(hasResults: true)),
    );

    await _enterMapSearchQuery(tester, 'mart');
    await tester.pumpAndSettle();
    _expectMapSearchGroups(tester, [
      'Airports',
      'Favourites',
      'Towns and villages',
    ]);
    final field = tester.getRect(find.byType(TextField));
    expect(field.left, lessThan(100));
    expect(field.right, lessThan(500));
    await _shot(tester, 'map_search_results_tablet_landscape_en_dark');
  });

  for (final device in _devices.entries) {
    for (final brightness in Brightness.values) {
      final suffix = '${device.key}_en_${brightness.name}';
      final landscape = device.value.width > device.value.height;
      testWidgets('weather_wind_units_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          navigation: true,
          hazard: true,
          windUnit: SpeedUnit.ms,
        );
        expect(
          find.textContaining('Wind 7 m/s exceeds limit 6 m/s'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Surface gusts 11 m/s exceed limit 10 m/s'),
          findsOneWidget,
        );
        await _shot(tester, 'weather_wind_units_$suffix');
      });
      testWidgets('weather_warning_details_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          navigation: true,
          hazard: true,
        );
        expect(find.text('Weather warnings on the route'), findsOneWidget);
        expect(
          find.textContaining('Wind 25 kph exceeds limit 20 kph'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Surface gusts 38 kph exceed limit 35 kph'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Fog forecast on the route'),
          findsOneWidget,
        );
        await _shot(tester, 'weather_warning_details_$suffix');
      });
      testWidgets('weather_warning_widget_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          widgetOnly: true,
          hazard: true,
        );
        expect(
          tester.widget<TelemetryCard>(find.byType(TelemetryCard)).state,
          ThresholdState.maxWarning,
        );
        await _shot(tester, 'weather_warning_widget_$suffix');
      });
      testWidgets('weather_warning_alert_$suffix', (tester) async {
        await _checkMapAlert(
          tester,
          brightness,
          device.value,
          alert: MapAlert(kind: MapAlertKind.forecastFog, since: _alertSince),
          screenshot: 'weather_warning_alert_$suffix',
          openDialog: true,
        );
      });
      testWidgets('weather_stale_$suffix', (tester) async {
        await _checkMapAlert(
          tester,
          brightness,
          device.value,
          alert: MapAlert(kind: MapAlertKind.forecastStale, since: _alertSince),
          screenshot: 'weather_stale_$suffix',
          openDialog: true,
          overrides: [
            flightForecastProfilesProvider.overrideWith(
              (ref) async => (
                series: {
                  forecastLocationKey(_weatherLocation): _visualWeatherSeries(),
                },
                refreshFailed: true,
              ),
            ),
          ],
        );
        expect(find.text('Refresh forecast'), findsOneWidget);
      });
      testWidgets('weather_route_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          routePage: true,
        );
        expect(find.text('Piešťany'), findsOneWidget);
        await _shot(tester, 'weather_route_$suffix');
      });
      testWidgets('weather_widget_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          widgetOnly: true,
        );
        expect(find.text('30 min'), findsOneWidget);
        await _shot(tester, 'weather_widget_$suffix');
      });
      testWidgets('weather_point_menu_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          pointMenu: true,
        );
        expect(find.text('Route point details'), findsOneWidget);
        await _shot(tester, 'weather_point_menu_$suffix');
      });
      testWidgets('weather_point_$suffix', (tester) async {
        await _openWeatherVisual(tester, brightness, device.value);
        expect(find.text('Piešťany'), findsOneWidget);
        expect(find.text('Air and wind'), findsOneWidget);
        expect(find.text('Wind at planned altitude'), findsOneWidget);
        await _shot(tester, 'weather_point_$suffix');
      });
      testWidgets('weather_pressure_$suffix', (tester) async {
        await _openWeatherVisual(tester, brightness, device.value);
        await _scrollDialogTo(tester, find.text('Estimated QFE'));
        expect(find.text('Estimated QNH'), findsOneWidget);
        await _shot(tester, 'weather_pressure_$suffix');
      });
      testWidgets('weather_no_terrain_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          terrain: null,
        );
        expect(find.text('Estimated QFE'), findsNothing);
        await _scrollDialogTo(tester, find.text('Estimated QNH'));
        await _shot(tester, 'weather_no_terrain_$suffix');
      });
      testWidgets('weather_unavailable_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          unavailable: true,
        );
        await _scrollDialogTo(
          tester,
          find.text('Forecast unavailable for this time and location.'),
        );
        await _shot(tester, 'weather_unavailable_$suffix');
      });
      testWidgets('weather_altitude_$suffix', (tester) async {
        await _openWeatherVisual(tester, brightness, device.value);
        await _scrollDialogTo(tester, find.byIcon(Icons.edit_outlined));
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        expect(find.text('2500'), findsOneWidget);
        expect(find.text('Custom'), findsOneWidget);
        await _shot(tester, 'weather_altitude_$suffix');
      });
      testWidgets('weather_navigation_$suffix', (tester) async {
        await _openWeatherVisual(
          tester,
          brightness,
          device.value,
          navigation: true,
        );
        expect(find.textContaining('Forecast wind'), findsWidgets);
        await _shot(tester, 'weather_navigation_$suffix');
      });
      testWidgets('weather_aircraft_$suffix', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showAircraftSettingsDialog(
                  context,
                  ref,
                  const Aircraft(
                    id: 'demo-aircraft',
                    name: 'Stork Demo',
                    cruiseSpeedMs: 100 / 3.6,
                    weatherAltitudeFeet: 2500,
                  ),
                ),
                child: const Text('Open aircraft'),
              ),
            ),
          ),
          brightness,
          device.value,
        );
        await tester.tap(find.text('Open aircraft'));
        await tester.pumpAndSettle();
        await _scrollDialogTo(tester, find.text('Default weather altitude'));
        expect(find.text('2500'), findsOneWidget);
        await _shot(tester, 'weather_aircraft_$suffix');
      });
      testWidgets('weather_limits_$suffix', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showAircraftSettingsDialog(
                  context,
                  ref,
                  const Aircraft(
                    id: 'demo-aircraft',
                    name: 'Stork Demo',
                    cruiseSpeedMs: 100 / 3.6,
                    weatherAltitudeFeet: 2500,
                  ),
                ),
                child: const Text('Open aircraft'),
              ),
            ),
          ),
          brightness,
          device.value,
        );
        await tester.tap(find.text('Open aircraft'));
        await tester.pumpAndSettle();
        await _scrollDialogTo(tester, find.text('Dangerous surface gusts'));
        expect(find.text('Dangerous wind'), findsOneWidget);
        await _shot(tester, 'weather_limits_$suffix');
      });
      testWidgets('collision_$suffix', (tester) async {
        await _checkCollisionBanner(
          tester,
          brightness,
          device.value,
          mapControlScale: 1,
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
            mapControlScale: 3,
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
      testWidgets('data_sources_$suffix', (tester) async {
        await withSourceLogos(SourceLogoState.loaded, () async {
          await _pump(
            tester,
            const DataSourcesPage(),
            brightness,
            device.value,
          );
          for (final section in {
            'maps': 'Maps and terrain',
            'aviation': 'Aeronautical information',
            'weather': 'Weather',
            'traffic': 'Air traffic',
            'location': 'Search and location',
          }.entries) {
            await tester.scrollUntilVisible(
              find.text(section.value),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            // Let the deterministic network image codec finish outside fake time.
            await tester.runAsync(() async {
              for (final image in tester.widgetList<Image>(
                find.byType(Image),
              )) {
                await precacheImage(
                  image.image,
                  tester.element(find.byType(DataSourcesPage)),
                );
              }
            });
            await tester.pumpAndSettle();
            expect(find.byType(RawImage), findsWidgets);
            expect(
              tester
                  .widgetList<RawImage>(find.byType(RawImage))
                  .any((image) => image.image != null),
              isTrue,
            );
            await _shot(tester, 'data_sources_${section.key}_$suffix');
          }
          final scrollable = tester.state<ScrollableState>(
            find.byType(Scrollable).first,
          );
          scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.sensors), findsOneWidget);
          await _shot(tester, 'data_sources_bottom_$suffix');
        });
      });
      if (device.key == 'phone_portrait') {
        for (final state in [SourceLogoState.loading, SourceLogoState.failed]) {
          testWidgets('data_sources_${state.name}_$suffix', (tester) async {
            await withSourceLogos(state, () async {
              await _pump(
                tester,
                const DataSourcesPage(),
                brightness,
                device.value,
              );
              expect(find.byIcon(Icons.public), findsWidgets);
              expect(find.text('OpenStreetMap'), findsOneWidget);
              await _shot(tester, 'data_sources_${state.name}_$suffix');
            });
          });
        }
      }
      for (final entry in <String, Widget>{
        'settings': const SettingsPage(),
        'map': const MapSettingsPage(),
        'widget_settings': const WidgetSettingsPage(),
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
            mapControlScale: 2,
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
