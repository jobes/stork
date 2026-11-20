import '../../support/map_style_backend.dart';

import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre/maplibre.dart' as ml;
// The test replaces the native renderer at the plugin's platform boundary.
// ignore: depend_on_referenced_packages
import 'package:maplibre_platform_interface/maplibre_platform_interface.dart'
    as platform;
import 'package:stork/core/router/app_router.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/core/services/map_assets_server.dart';
import 'package:stork/core/services/style_provider.dart';
import 'package:stork/core/startup/application_bootstrap.dart';
import 'package:stork/core/startup/application_runtime.dart';
import 'package:stork/core/startup/deferred_startup_tasks.dart';
import 'package:stork/core/startup/first_frame_startup.dart';
import 'package:stork/core/startup/local_map_preparation.dart';
import 'package:stork/core/startup/startup_page.dart';
import 'package:stork/core/startup/map_startup_provider.dart';
import 'package:stork/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:stork/features/map/data/repositories/radar_repository.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';
import 'package:stork/features/map/presentation/pages/map_page.dart';
import 'package:stork/features/map/presentation/providers/airspace_activity_provider.dart';
import 'package:stork/features/map/presentation/providers/map_alerts_provider.dart';
import 'package:stork/features/map/presentation/providers/map_camera_provider.dart';
import 'package:stork/features/map/presentation/providers/map_radar.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/display_preferences_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/black_box_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_provider.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import 'package:stork/features/weather/presentation/providers/route_waypoint_weather_provider.dart';
import 'package:stork/main.dart';

import '../../helpers/fake_geolocator_platform.dart';

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  Completer<void> rasterized = Completer<void>();
  @override
  Future<void> get waitUntilFirstFrameRasterized => rasterized.future;
}

class _Gps extends FakeGeolocatorPlatform {
  _Gps(super.controller);
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
}

class _Traffic extends Traffic {
  @override
  List<TrafficAircraft> build() => [];
  @override
  void updateViewport(ml.GeoBox bounds) {}
}

class _Settings extends AppSettingsNotifier {
  _Settings(this.ready);
  final Future<AppSettings> ready;
  int builds = 0;
  @override
  Future<AppSettings> build() {
    builds++;
    return ready;
  }
}

class _Preferences extends DisplayPreferencesNotifier {
  @override
  Future<DisplayPreferences> build() async =>
      (themeMode: ThemeMode.light, language: AppLanguage.slovak, saving: false);
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState(
    isActive: true,
    points: [
      NavigationPoint(latitude: 49, longitude: 18, name: 'First'),
      NavigationPoint(latitude: 50, longitude: 19, name: 'Second'),
    ],
  );
}

class _Favorites extends FavoritesNotifier {
  @override
  Future<List<FavoritePoint>> build() async => [];
}

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() => const TelemetryState(latitude: 48, longitude: 17);
}

class _Notams extends Notams {
  @override
  Future<NotamFetchResult> build() async => const NotamFetchResult([]);
}

class _Offline extends OfflineMapsNotifier {
  @override
  OfflineMapsState build() => OfflineMapsState();
}

class _RadarRepository extends Fake implements RadarRepository {}

class _Radar extends MapRadar {
  _Radar() : super(repository: _RadarRepository());
  @override
  void attachStyle(ml.StyleController style) {}
  @override
  Future<void> refresh({bool force = false}) async {}
}

class _Style extends TestStyle {
  int addedLayers = 0;
  @override
  Future<void> addLayer(
    Map<String, Object?> json, {
    String? belowLayerId,
  }) async {
    addedLayers++;
  }
}

class _NativeMap extends platform.MapLibreMapState {
  _NativeMap(this.owner);
  final _Platform owner;
  @override
  final _Style style = _Style();
  @override
  void initState() {
    super.initState();
    final position = options.initCamera! as ml.CameraUpdatePosition;
    camera = ml.CameraPosition(
      center: position.center!,
      zoom: position.zoom!,
      pitch: position.pitch ?? 0,
      bearing: position.bearing ?? 0,
    );
    final json = (options.style as ml.MapStyleJson).json;
    style.loadStyle(jsonDecode(json) as Map<String, dynamic>);
    owner.styles.add(json);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onMapCreated?.call(this);
      widget.onStyleLoaded?.call(style);
    });
  }

  @override
  Widget buildPlatformWidget(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('native-map'));
  @override
  ml.GeoBox getVisibleBounds() =>
      const ml.GeoBox(south: 47, north: 49, west: 16, east: 18);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Platform extends platform.MapLibrePlatform {
  final styles = <String>[];
  @override
  platform.MapLibreMapState createWidgetState() => _NativeMap(this);
}

void main() {
  final binding = _Binding();
  for (final (retry, escape, refreshFails) in [
    (false, false, false),
    (true, false, false),
    (false, true, false),
    (false, false, true),
  ]) {
    testWidgets(
      'real startup hands prepared map to the page${retry ? ' after retry' : ''}${escape ? ' then leaves before rendering' : ''}${refreshFails ? ' with a failed refreshed preparation' : ''}',
      (tester) async {
        binding.rasterized = Completer<void>();
        rootBundle.clear();
        final previousPlatform = platform.MapLibrePlatform.instance;
        final native = _Platform();
        platform.MapLibrePlatform.instance = native;
        final previousGps = GeolocatorPlatform.instance;
        final positions = StreamController<Position>.broadcast();
        GeolocatorPlatform.instance = _Gps(positions);
        addTearDown(() async {
          platform.MapLibrePlatform.instance = previousPlatform;
          GeolocatorPlatform.instance = previousGps;
          await positions.close();
          await MapAssetsServer.stop();
        });
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async => const StandardMessageCodec().encodeMessage([null]),
        );
        // The actual style loader needs only a local asset-server URL. No tiles
        // or online resources are requested by the substitute native renderer.
        await tester.runAsync(MapAssetsServer.start);
        final settingsReady = Completer<AppSettings>();
        final settingsInstances = <_Settings>[];
        var firAttempts = 0;
        var cameraDisposals = 0;
        var stylePreparations = 0;
        final refreshedStyleReady = Completer<void>();
        final monitoring = Completer<bool>();
        final container = ProviderContainer(
          retry: (_, _) => null,
          overrides: [
            applicationConfigurationProvider.overrideWith((_) async {}),
            applicationRuntimeProvider.overrideWith((_) => monitoring.future),
            startupFirIndexProvider.overrideWith((_) async {
              if (++firAttempts == 1 && retry) {
                throw StateError('FIR unavailable');
              }
            }),
            mapStyleProvider.overrideWith((ref) async {
              if (++stylePreparations > 1 && !retry && !escape) {
                await refreshedStyleReady.future;
              }
              return mapStyle(ref);
            }),
            startupMapAssetsProvider.overrideWith((_) async {}),
            startupOfflineDatabaseProvider.overrideWith((_) async {}),
            startupLastKnownPositionProvider.overrideWith((_) async => null),
            appSettingsProvider.overrideWith(() {
              final settings = _Settings(settingsReady.future);
              settingsInstances.add(settings);
              return settings;
            }),
            displayPreferencesProvider.overrideWith(_Preferences.new),
            favoritesProvider.overrideWith(_Favorites.new),
            navigationProvider.overrideWith(_Navigation.new),
            cannelloniServiceProvider.overrideWithValue(false),
            blackBoxServiceProvider.overrideWithValue(null),
            gpsListenerProvider.overrideWith((_) {}),
            telemetryProvider.overrideWith(_Telemetry.new),
            notamsProvider.overrideWith(_Notams.new),
            airspaceActivityProvider.overrideWithValue({}),
            filteredTrafficProvider.overrideWithValue([]),
            trafficProvider.overrideWith(_Traffic.new),
            flightWeatherPlanProvider.overrideWithValue([]),
            routePointWindsProvider.overrideWith((_) => {}),
            mapAlertsProvider.overrideWithValue([]),
            offlineMapsProvider.overrideWith(_Offline.new),
            mapRadarProvider.overrideWith((ref) {
              final radar = _Radar();
              ref.onDispose(radar.dispose);
              return radar;
            }),
          ],
        );
        var disposed = false;
        addTearDown(() {
          if (!disposed) container.dispose();
        });
        appRouter.go('/');
        await tester.pumpWidget(
          FirstFrameStartup(
            appBuilder: (_) => UncontrolledProviderScope(
              container: container,
              child: const StorkApp(),
            ),
          ),
        );
        expect(find.byType(StartupContent), findsOneWidget);
        expect(find.byType(StorkApp), findsNothing);
        expect(native.styles, isEmpty);
        binding.rasterized.complete();
        await tester.pump();
        await tester.pump();
        expect(find.byType(StartupPage), findsOneWidget);
        expect(native.styles, isEmpty);
        var weatherReleased = false;
        unawaited(
          container
              .read(deferredStartupTasksProvider)
              .waitFor(StartupTask.weather)
              .then((_) => weatherReleased = true),
        );
        expect(weatherReleased, isFalse);
        settingsReady.complete(
          const AppSettings(mapFontSize: 1.2, autoSelectDevice: false),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump();
        }
        if (retry) {
          expect(find.text('Príprava sa nepodarila'), findsOneWidget);
          expect(native.styles, isEmpty);
          await tester.tap(find.text('Skúsiť znova'));
          for (var i = 0; i < 12; i++) {
            await tester.pump();
          }
        }
        // File-backed assets need real event-loop turns, while provider
        // continuations and widget frames use the test clock.
        for (
          var i = 0;
          i < 50 && container.read(applicationBootstrapProvider).isLoading;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 2)),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(
          container.read(applicationBootstrapProvider).hasValue,
          isTrue,
          reason: '${container.read(applicationBootstrapProvider)}',
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump();
        }
        expect(find.byType(StartupPage), findsOneWidget);
        expect(find.byType(MapPage), findsOneWidget);
        expect(
          tester
              .widget<IgnorePointer>(
                find.byKey(const ValueKey('startup-interaction-gate')),
              )
              .ignoring,
          isTrue,
        );
        final oldMap = tester.state<_NativeMap>(find.byType(ml.MapLibreMap));
        oldMap.widget.onRenderFrame?.call(
          const ml.MapEventRenderFrame(fullyRendered: false),
        );
        await tester.pump();
        expect(find.byType(StartupPage), findsOneWidget);
        if (escape) {
          appRouter.go('/favorites');
          await tester.pump();
          await tester.pump();
          expect(container.read(mapStartupProvider).ready, isTrue);
          expect(find.byType(StartupPage), findsNothing);
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 3),
          );
          expect(find.byType(MapPage), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
          container.dispose();
          disposed = true;
          appRouter.go('/');
          await tester.pump();
          return;
        }
        if (!retry) {
          // Native creation/style load alone cannot unlock the map. A renderer
          // that never delivers a complete frame must expose a retry instead.
          await tester.pump(MapStartup.renderingBudget);
          expect(find.text('Príprava sa nepodarila'), findsOneWidget);
          await tester.tap(find.text('Skúsiť znova'));
          // Riverpod retains the successful bootstrap while refreshing. It must
          // not hand that old result to the new startup attempt across frames.
          await tester.pump();
          await tester.pump();
          final refreshing = container.read(applicationBootstrapProvider);
          expect(refreshing.isLoading, isTrue);
          expect(refreshing.hasValue, isTrue);
          expect(find.byType(StartupPage), findsOneWidget);
          expect(find.byType(MapPage), findsNothing);
          expect(native.styles, hasLength(1));
          expect(weatherReleased, isFalse);
          if (refreshFails) {
            refreshedStyleReady.completeError(
              StateError('Refreshed preparation failed'),
            );
            for (var i = 0; i < 5; i++) {
              await tester.pump();
            }
            expect(
              container.read(applicationBootstrapProvider).hasError,
              isTrue,
            );
            expect(find.byType(StartupPage), findsOneWidget);
            expect(find.text('Príprava sa nepodarila'), findsOneWidget);
            expect(find.text('Skúsiť znova'), findsOneWidget);
            expect(find.byType(MapPage), findsNothing);
            expect(weatherReleased, isFalse);
            await tester.pumpWidget(const SizedBox.shrink());
            container.dispose();
            disposed = true;
            await tester.pump();
            return;
          }
          refreshedStyleReady.complete();
          for (var i = 0; i < 50 && native.styles.length < 2; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 2)),
            );
            await tester.pump(const Duration(milliseconds: 10));
          }
          expect(native.styles, hasLength(2));
          oldMap.widget.onRenderMap?.call(
            const ml.MapEventRenderMap(fullyRendered: true),
          );
          await tester.pump();
          expect(find.byType(StartupPage), findsOneWidget);
        }
        final currentMap = tester.state<_NativeMap>(
          find.byType(ml.MapLibreMap),
        );
        currentMap.widget.onRenderMap?.call(
          const ml.MapEventRenderMap(fullyRendered: true),
        );
        await tester.pump();
        await tester.pump();
        expect(find.byType(StartupPage), findsNothing);
        // Even monitoring that never settled did not gate the map. Completing
        // it later must not replace the native map subtree.
        monitoring.complete(true);
        await tester.pump();
        expect(
          tester.state<_NativeMap>(find.byType(ml.MapLibreMap)),
          same(currentMap),
        );
        expect(
          tester
              .widget<IgnorePointer>(
                find.byKey(const ValueKey('startup-interaction-gate')),
              )
              .ignoring,
          isFalse,
        );
        container
            .read(mapCameraProvider.notifier)
            .refAccess
            .onDispose(() => cameraDisposals++);
        expect(find.byKey(const ValueKey('native-map')), findsOneWidget);
        expect(native.styles, hasLength(retry ? 1 : 2));
        expect(
          tester
              .state<_NativeMap>(find.byType(ml.MapLibreMap))
              .style
              .addedLayers,
          0,
        );
        expect(
          settingsInstances.every((settings) => settings.builds == 1),
          isTrue,
        );
        expect(settingsInstances.length, retry ? 2 : 1);
        expect(firAttempts, retry ? 2 : 1);
        final style = jsonDecode(native.styles.last);
        final line =
            style['sources']['navigation-route-source']['data']['features'][0]['geometry']['coordinates']
                as List;
        expect(line.first[0], closeTo(17, 1e-9));
        expect(line.first[1], closeTo(48, 1e-9));
        expect((line.last[0] as num), closeTo(19, 1e-9));
        expect(style['sources']['favorites-source']['type'], 'geojson');
        final favoritesLayer = (style['layers'] as List).singleWhere(
          (layer) => layer['id'] == 'favorites-layer',
        );
        expect(favoritesLayer['layout']['text-size'], closeTo(21.6, 1e-9));
        expect(
          container
              .read(mapCameraProvider.notifier)
              .isAircraftSymbolInitialized,
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 200));
        expect(cameraDisposals, 0);
        expect(weatherReleased, isFalse);
        await tester.pump(const Duration(seconds: 3));
        expect(weatherReleased, isTrue);
        // Keep the application scope and bootstrap alive while leaving the map;
        // its temporary style lease must not pin map providers afterwards.
        appRouter.go('/favorites');
        // The extracted Material UI uses an animated route transition.
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 3),
        );
        expect(find.byType(MapPage), findsNothing);
        expect(container.read(mapStyleProvider.exists), isFalse);
        expect(cameraDisposals, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        disposed = true;
        await tester.pump();
      },
    );
  }
}
