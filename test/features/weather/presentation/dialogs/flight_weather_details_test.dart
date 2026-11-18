import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:maplibre/maplibre.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/features/map/presentation/components/controls/map_features_bottom_sheet.dart';
import 'package:stork/features/route/presentation/providers/navigation_provider.dart';
import 'package:stork/features/weather/presentation/providers/navigation_eta_provider.dart';
import 'package:stork/features/navigation/presentation/widgets/navigation_telemetry_widget.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/aircraft_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_state.dart';
import 'package:stork/features/telemetry/presentation/providers/throttled_telemetry_provider.dart';
import 'package:stork/features/weather/data/models/forecast_series.dart';
import 'package:stork/features/weather/domain/forecast_query.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/presentation/dialogs/flight_weather_details_dialog.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

final _eta = DateTime.utc(2026, 11, 16, 14, 20);
const _location = (latitude: 48.17, longitude: 17.21);
const _origin = (latitude: 48.35, longitude: 17.21);
const _destination = (latitude: 48.25, longitude: 17.21);

class _Plan extends FlightWeatherPlanNotifier {
  @override
  List<ForecastRoutePoint> build() {
    final point = ref.watch(navigationProvider).value?.points.firstOrNull;
    if (point == null) return [];
    return [
      ForecastRoutePoint(
        id: 'origin',
        location: _origin,
        eta: _eta.subtract(const Duration(minutes: 12)),
        duration: Duration.zero,
        distanceMeters: 0,
        altitudeFeet: 2000,
      ),
      ForecastRoutePoint(
        id: 'waypoint-0',
        location: _location,
        eta: _eta,
        duration: const Duration(minutes: 20),
        distanceMeters: 20000,
        altitudeFeet: (point.weatherAltitudeFeet ?? 2000).toDouble(),
        waypointIndex: 0,
      ),
      ForecastRoutePoint(
        id: 'waypoint-1',
        location: _destination,
        eta: _eta.add(const Duration(minutes: 12)),
        duration: const Duration(minutes: 24),
        distanceMeters: 40000,
        altitudeFeet: 2000,
        waypointIndex: 1,
      ),
    ];
  }
}

class _WeatherSettings extends AppSettingsNotifier {
  @override
  Future<AppSettings> build() async =>
      const AppSettings(showFlightWeather: true);
}

class _WeatherTelemetry extends ThrottledTelemetry {
  @override
  TelemetryState build() => const TelemetryState();
}

class _HazardPlan extends FlightWeatherPlanNotifier {
  @override
  List<ForecastRoutePoint> build() => [
    ForecastRoutePoint(
      id: 'waypoint-0',
      location: _location,
      eta: _eta,
      duration: const Duration(minutes: 10),
      distanceMeters: 10000,
      altitudeFeet: 2000,
    ),
  ];
}

class _PointsNavigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState(isActive: true);
}

void main() {
  for (final terrain in <double?>[null, 130]) {
    testWidgets(
      'map point details edit altitude and handle QFE terrain $terrain',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'navigation_state_json': jsonEncode(
            const NavigationState(
              points: [
                NavigationPoint(
                  latitude: 48.17,
                  longitude: 17.21,
                  name: 'Test waypoint',
                ),
                NavigationPoint(
                  latitude: 48.25,
                  longitude: 17.21,
                  name: 'Next waypoint',
                ),
              ],
              isActive: true,
            ).toJson(),
          ),
        });
        final prefs = await SharedPreferences.getInstance();
        final firstHour = DateTime.utc(2026, 11, 16, 14);
        final series = ForecastSeries.fromJson({
          'elevation': 130,
          'hourly': {
            'time': [
              firstHour.millisecondsSinceEpoch ~/ 1000,
              firstHour.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                  1000,
            ],
            'surface_pressure': [995, 991],
            'temperature_2m': [10, 11],
            'wind_gusts_10m': [18, 36],
            'wind_speed_950hPa': [20, 20],
            'wind_direction_950hPa': [0, 0],
            'geopotential_height_950hPa': [500, 500],
            'wind_speed_925hPa': [20, 20],
            'wind_direction_925hPa': [0, 0],
            'geopotential_height_925hPa': [725, 725],
          },
        }, firstHour);

        var profileRequests = 0;
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
            navigationAutoAdvanceProvider.overrideWith((ref) {}),
            appSettingsProvider.overrideWith(_WeatherSettings.new),
            throttledTelemetryProvider.overrideWith(_WeatherTelemetry.new),
            flightWeatherPlanProvider.overrideWith(_Plan.new),
            for (final location in [_origin, _location, _destination])
              forecastPointTerrainProvider(
                location,
              ).overrideWith((ref) async => terrain),
            flightForecastProfilesProvider.overrideWith((ref) async {
              profileRequests++;
              return (
                series: {
                  forecastLocationKey(_location): series,
                  forecastLocationKey(_origin): series,
                  forecastLocationKey(quantizeForecastLocation(_origin)):
                      series,
                  forecastLocationKey(_destination): series,
                },
                refreshFailed: false,
              );
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(navigationProvider.future);
        final corrected = await tester.runAsync(() async {
          final mapSubscription = container.listen(
            nearbyFlightForecastProvider,
            (_, _) {},
          );
          addTearDown(mapSubscription.close);
          await container.read(appSettingsProvider.future);
          await container.read(flightForecastProfilesProvider.future);
          final timingSubscription = container.listen(
            routeWindTimingProvider,
            (_, _) {},
          );
          addTearDown(timingSubscription.close);
          return container.read(routeWindTimingProvider.future);
        });
        expect(corrected, isNotNull);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: Builder(
                  builder: (context) => Column(
                    children: [
                      const NavigationTelemetryWidget(),
                      TextButton(
                        onPressed: () =>
                            showMapFeaturesBottomSheet(context, const [
                              {
                                'layerType': 'flight-weather',
                                'properties': {'forecastId': 'waypoint-0'},
                              },
                            ], const Geographic(lat: 48.17, lon: 17.21)),
                        child: const Text('Open map point'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(profileRequests, 1);
        final shared = container.read(navigationEtaProvider);
        expect(
          shared.legs.first.eta,
          _eta.subtract(const Duration(minutes: 2)),
        );
        expect(shared.totalDuration, const Duration(minutes: 25));
        final widgetElement = tester.element(
          find.byType(NavigationTelemetryWidget),
        );
        final minute = AppLocalizations.of(widgetElement)!.minutesAbbrev;
        expect(find.text('10 $minute'), findsOneWidget);
        expect(find.text('25 $minute'), findsOneWidget);

        await tester.tap(find.text('25 $minute'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Forecast wind'), findsWidgets);
        expect(
          find.textContaining('Surface gusts (10 m above ground)'),
          findsOneWidget,
        );
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open map point'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Route point details'));
        await tester.pumpAndSettle();
        expect(find.text('ETA'), findsOneWidget);
        final expectedEta = container
            .read(routePointTimingProvider)['waypoint-0']
            ?.eta;
        expect(expectedEta, isNotNull);
        final dialogL10n = AppLocalizations.of(
          tester.element(find.text('ETA')),
        )!;
        final hourFormat = DateFormat.Hm(dialogL10n.localeName);
        final utcEta = hourFormat.format(expectedEta!.toUtc());
        expect(find.text(utcEta), findsOneWidget);
        expect(find.textContaining('· ${dialogL10n.clockUtc}'), findsWidgets);
        final localEta = hourFormat.format(expectedEta.toLocal());
        if (localEta != utcEta) {
          expect(find.text(localEta), findsNothing);
        }
        expect(find.text('Surface gusts (10 m above ground)'), findsOneWidget);
        expect(find.text('Estimated QNH'), findsOneWidget);
        expect(
          find.text('Estimated QFE'),
          terrain == null ? findsNothing : findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '3200');
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();

        final updated = container.read(navigationEtaProvider);
        expect(updated.legs.first.eta, _eta);

        final route = container.read(navigationProvider).value!.points;
        expect(route.first.weatherAltitudeFeet, 3200);
        expect(route.last.weatherAltitudeFeet, isNull);
        expect(
          prefs.getString('navigation_state_json'),
          contains('"weatherAltitudeFeet":3200'),
        );
      },
    );
  }

  testWidgets('point details use colored icons and highlight hazards', (
    tester,
  ) async {
    final firstHour = DateTime.utc(2026, 11, 16, 14);
    final series = ForecastSeries.fromJson({
      'elevation': 100,
      'hourly': {
        'time': [
          firstHour.millisecondsSinceEpoch ~/ 1000,
          firstHour.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000,
        ],
        'surface_pressure': [1000, 1000],
        'weather_code': [45, 45],
        'cloud_cover_low': [100, 100],
        'precipitation': [0, 2],
        'wind_gusts_10m': [18, 72],
        'wind_speed_950hPa': [72, 72],
        'wind_direction_950hPa': [0, 0],
        'geopotential_height_950hPa': [500, 500],
        'wind_speed_925hPa': [72, 72],
        'wind_direction_925hPa': [0, 0],
        'geopotential_height_925hPa': [800, 800],
      },
    }, firstHour);
    final container = ProviderContainer(
      overrides: [
        appSettingsProvider.overrideWith(_WeatherSettings.new),
        navigationProvider.overrideWith(_PointsNavigation.new),
        flightWeatherPlanProvider.overrideWith(_HazardPlan.new),
        routePointTimingProvider.overrideWith((ref) => {}),
        selectedAircraftProvider.overrideWith(
          (ref) => const Aircraft(
            id: 'demo',
            name: 'Demo',
            dangerousWindMs: 10,
            dangerousGustMs: 10,
          ),
        ),
        for (final location in [_origin, _location, _destination])
          forecastPointTerrainProvider(
            location,
          ).overrideWith((ref) async => null),
        flightForecastProfilesProvider.overrideWith(
          (ref) async => (
            series: {
              forecastLocationKey(_location): series,
              forecastLocationKey(quantizeForecastLocation(_location)): series,
            },
            refreshFailed: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showFlightWeatherDetails(context, 'waypoint-0'),
                child: const Text('Open forecast'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open forecast'));
    await tester.pumpAndSettle();

    final colors = Theme.of(
      tester.element(find.byType(FlightWeatherDetailsDialog)),
    ).colorScheme;
    expect(tester.widget<Icon>(find.byIcon(Icons.air)).color, colors.error);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.compress)).color,
      colors.primary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_outlined)).color,
      isNot(colors.onSurfaceVariant),
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(4));
    expect(tester.widget<Text>(find.text('72 kph')).style?.color, colors.error);
    expect(tester.widget<Icon>(find.byIcon(Icons.speed)).color, colors.error);
  });
}
