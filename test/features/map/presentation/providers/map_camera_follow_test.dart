import 'package:stork/features/map/presentation/providers/airspace_highlight_layers.dart';

import 'dart:async';

import '../../../../support/map_style_backend.dart';

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:stork/features/settings/presentation/providers/display_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/features/map/utils/geojson_builder.dart';
import 'package:stork/core/startup/initial_map_camera.dart';
import 'package:stork/core/theme/stork_colors.dart';
import 'package:stork/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_activity_provider.dart';
import 'package:stork/features/map/presentation/providers/map_camera_provider.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/features/map/presentation/providers/traffic_colors.dart';
import 'package:stork/features/map/domain/models/notam.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/domain/models/resolved_altitude.dart';
import 'package:stork/features/telemetry/presentation/providers/agl_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_provider.dart';

import '../../../../helpers/fake_geolocator_platform.dart';

class _GpsPermissions extends FakeGeolocatorPlatform {
  _GpsPermissions(super.controller);

  var permission = LocationPermission.denied;
  var grantOnRequest = false;
  var permissionRequests = 0;
  var permissionChecks = 0;
  Future<Position?>? lastKnownPosition;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async {
    permissionChecks++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    if (grantOnRequest) permission = LocationPermission.whileInUse;
    return permission;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    final pending = lastKnownPosition;
    lastKnownPosition = null;
    return pending;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => makePosition();
}

class _Telemetry extends TelemetryNotifier {
  _Telemetry([
    this.initialState = const TelemetryState(
      latitude: 48,
      longitude: 17,
      groundSpeed: 30,
      isFlying: true,
      mapViewState: MapViewState.follow,
    ),
  ]);
  final TelemetryState initialState;
  @override
  TelemetryState build() => initialState;

  void changePosition(double? latitude, double? longitude) {
    state = state.copyWith(
      latitude: TelemetryValue(latitude),
      longitude: TelemetryValue(longitude),
    );
  }

  double? get latitude => state.latitude;

  MapViewState get view => state.mapViewState;

  void changeLatitude(double latitude) {
    state = state.copyWith(latitude: TelemetryValue(latitude));
  }

  void changeSpeed(double speed) {
    state = state.copyWith(groundSpeed: TelemetryValue(speed));
  }
}

class _Traffic extends Traffic {
  @override
  List<TrafficAircraft> build() => [];

  final viewports = <ml.GeoBox>[];

  @override
  void updateViewport(ml.GeoBox bounds) => viewports.add(bounds);
}

class _FilteredTraffic extends FilteredTraffic {
  @override
  List<TrafficAircraft> build() => [];

  void publish(TrafficAircraft aircraft) => state = [aircraft];
}

class _SystemPreferences extends DisplayPreferencesNotifier {
  @override
  Future<DisplayPreferences> build() async => (
    themeMode: ThemeMode.system,
    language: AppLanguage.system,
    saving: false,
  );
}

class _Settings extends AppSettingsNotifier {
  _Settings([this.initial = const AppSettings()]);
  final AppSettings initial;
  @override
  AppSettings build() => initial;

  void setFollowPitch(double pitch) {
    state = AsyncData(state.requireValue.copyWith(mapFollowPitch: pitch));
  }
}

class _Navigation extends NavigationNotifier {
  _Navigation([this.initialState = const NavigationState()]);
  final NavigationState initialState;
  @override
  NavigationState build() => initialState;
  void publish(NavigationState route) => state = AsyncData(route);
}

class _Notams extends Notams {
  @override
  Future<NotamFetchResult> build() async => const NotamFetchResult([]);

  void fail() {
    final error = AsyncError<NotamFetchResult>(
      StateError('NOTAM unavailable'),
      StackTrace.current,
    );
    // Simulate an async refresh failure that retained its previous value.
    // ignore: invalid_use_of_internal_member
    state = error.copyWithPrevious(state);
  }

  void publish(List<Notam> notams) {
    state = AsyncData(NotamFetchResult(notams));
  }
}

class _Favorites extends FavoritesNotifier {
  @override
  Future<List<FavoritePoint>> build() async => [];
}

class _Style extends TestStyle {
  _Style() {
    loadStyle({
      'sources': {
        for (final id in [
          'course-line-source',
          'navigation-route-source',
          'notams-source',
          'aircraft-source',
          'traffic-source',
          'favorites-source',
          'flight-weather-source',
        ])
          id: {
            'type': 'geojson',
            'data': {'type': 'FeatureCollection', 'features': []},
          },
      },
      'layers': [
        for (final id in airspaceHighlightLayerIds)
          {'id': id, 'type': 'background'},
      ],
    });
  }
  final updates = <String, List<String>>{};
  final removedLayers = <String>[];
  bool failNextNotamWrite = false;
  Future<void>? nextFavoritesLayerDelay;
  Future<void>? nextRouteWriteDelay;
  Future<void>? nextAircraftWriteDelay;
  int routeWriteFailures = 0;
  bool failNextAircraftWrite = false;

  @override
  Future<void> addLayer(
    Map<String, Object?> json, {
    String? belowLayerId,
  }) async {
    final layer = ml.StyleLayer.fromJson(json);
    if (layer.id == 'favorites-layer') {
      final delay = nextFavoritesLayerDelay;
      nextFavoritesLayerDelay = null;
      if (delay != null) await delay;
    }
  }

  @override
  Future<void> removeLayer(String id) async {
    removedLayers.add(id);
  }

  @override
  Future<void> setGeoJsonData(String id, ml.GeoJsonData geojson) async {
    final data = geojson.toText();
    (updates[id] ??= []).add(data);
    if (id == 'aircraft-source') {
      if (failNextAircraftWrite) {
        failNextAircraftWrite = false;
        throw StateError('Aircraft write failed');
      }
      final delay = nextAircraftWriteDelay;
      nextAircraftWriteDelay = null;
      if (delay != null) await delay;
    }
    if (id == 'navigation-route-source') {
      if (routeWriteFailures > 0) {
        routeWriteFailures--;
        throw StateError('Route write failed');
      }
      final delay = nextRouteWriteDelay;
      nextRouteWriteDelay = null;
      if (delay != null) await delay;
    }
    if (id == 'notams-source' && failNextNotamWrite) {
      failNextNotamWrite = false;
      throw StateError('NOTAM source unavailable');
    }
  }
}

class _UninitializedMap extends Fake implements ml.MapController {
  int moves = 0;
  @override
  ml.CameraPosition? get camera => null;
  @override
  Future<void> moveCamera(ml.CameraUpdate update) async {
    moves++;
  }
}

class _Map extends Fake implements ml.MapController {
  @override
  _Style style = _Style();

  @override
  ml.CameraPosition camera = const ml.CameraPosition(
    center: ml.Geographic(lat: 48, lon: 17),
    zoom: 12,
    pitch: 0,
    bearing: 0,
  );

  void Function(ml.MapEvent)? onEvent;
  void Function(ml.CameraPosition)? onPresented;
  ml.GeoBox viewportBounds = const ml.GeoBox(
    south: 47,
    north: 49,
    west: 16,
    east: 18,
  );
  int viewportReads = 0;
  final animatedCenters = <ml.Geographic?>[];

  @override
  Future<void> moveCamera(ml.CameraUpdate update) async {
    final position = update as ml.CameraUpdatePosition;
    final center = position.center;
    final zoom = position.zoom;
    final bearing = position.bearing;
    final pitch = position.pitch;
    camera = ml.CameraPosition(
      center: center ?? camera.center,
      zoom: zoom ?? camera.zoom,
      bearing: bearing ?? camera.bearing,
      pitch: pitch ?? camera.pitch,
    );
    onEvent?.call(
      ml.MapEventCameraMove(
        camera: camera,
        reason: ml.CameraChangeReason.programmatic,
      ),
    );
    onPresented?.call(camera);
    onEvent?.call(
      ml.MapEventCameraMoveEnd(
        camera: camera,
        reason: ml.CameraChangeReason.programmatic,
      ),
    );
  }

  @override
  Future<ml.CameraAnimationResult> animateCamera(
    ml.CameraUpdate update, {
    ml.CameraAnimation animation = const ml.CameraAnimation.ease(),
  }) async {
    animatedCenters.add((update as ml.CameraUpdatePosition).center);
    await moveCamera(update);
    return ml.CameraAnimationResult.completed;
  }

  Future<void>? featureQueryGate;
  int featureQueryGateAt = 1;
  final queriedLayers = <List<String>>[];

  @override
  Future<List<ml.RenderedFeature>> queryRenderedFeatures(
    ml.QueryGeometry geometry, {
    List<String>? layerIds,
    ml.Expression<bool>? filter,
  }) async {
    queriedLayers.add(layerIds!);
    if (queriedLayers.length == featureQueryGateAt) await featureQueryGate;
    return [
      ml.RenderedFeature(
        id: layerIds.first,
        properties: {
          'name': layerIds.first,
          'metadata': {'nested': true},
        },
      ),
    ];
  }

  @override
  ml.GeoBox getVisibleBounds() {
    viewportReads++;
    return viewportBounds;
  }
}

Future<
  ({MapCamera camera, _Map map, _Telemetry telemetry, _FilteredTraffic traffic})
>
_setupFollow(
  WidgetTester tester, {
  _Notams? notams,
  _Navigation? navigation,
  _Telemetry? initialTelemetry,
  InitialMapCamera? initialCamera,
  DisplayPreferencesNotifier? preferences,
  _Settings? settings,
}) async {
  final telemetry = initialTelemetry ?? _Telemetry();
  final traffic = _FilteredTraffic();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        telemetryProvider.overrideWith(() => telemetry),
        filteredTrafficProvider.overrideWith(() => traffic),
        trafficProvider.overrideWith(_Traffic.new),
        appSettingsProvider.overrideWith(() => settings ?? _Settings()),
        if (preferences != null)
          displayPreferencesProvider.overrideWith(() => preferences),
        currentLocationProvider.overrideWithValue(const AsyncData(null)),
        navigationProvider.overrideWith(() => navigation ?? _Navigation()),
        if (notams != null) notamsProvider.overrideWith(() => notams),
        favoritesProvider.overrideWith(_Favorites.new),
        airspaceActivityProvider.overrideWithValue(const {}),
        resolvedAltitudeProvider.overrideWithValue(
          const ResolvedAltitude(source: AltitudeSource.none),
        ),
      ],
      child: Consumer(
        builder: (_, ref, _) {
          ref.watch(mapCameraProvider);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Consumer)),
  );
  final camera = container.read(mapCameraProvider.notifier);
  final map = _Map();
  if (initialCamera != null) {
    container.read(initialMapCameraProvider.notifier).prepare(initialCamera);
  }
  camera.attachController(map, cameraPrepared: initialCamera != null);
  await camera.handleStyleLoaded(map.style);
  await tester.pump(const Duration(milliseconds: 200));
  map.viewportReads = 0;
  map.style.updates.clear();
  map.onEvent = camera.handleMapEvent;
  map.onPresented = camera.handleCameraPresented;
  return (camera: camera, map: map, telemetry: telemetry, traffic: traffic);
}

const _route = NavigationState(
  isActive: true,
  points: [
    NavigationPoint(latitude: 49, longitude: 18, name: 'First'),
    NavigationPoint(latitude: 50, longitude: 19, name: 'Second'),
  ],
);

List<dynamic> _routeCoordinates(String data) =>
    jsonDecode(data)['features'][0]['geometry']['coordinates'] as List;

void main() {
  testWidgets(
    'style load reconciles a changed fallback origin despite unchanged provider inputs',
    (tester) async {
      final setup = await _setupFollow(
        tester,
        notams: _Notams(),
        navigation: _Navigation(_route),
        initialTelemetry: _Telemetry(const TelemetryState()),
        initialCamera: const InitialMapCamera(
          center: ml.Geographic(lat: 47, lon: 16),
          zoom: 6,
          hasLocation: true,
        ),
      );
      final prepared = setup.camera.prepareStyle(
        '{"version":8,"sources":{},"layers":[]}',
      );
      setup.camera.refAccess
          .read(initialMapCameraProvider.notifier)
          .prepare(
            const InitialMapCamera(
              center: ml.Geographic(lat: 48, lon: 17),
              zoom: 6,
              hasLocation: true,
            ),
          );
      setup.map.style.updates.clear();
      await setup.camera.handleStyleLoaded(
        setup.map.style,
        overlaysPrepared: true,
        preparedStyle: prepared,
      );
      await tester.pump();
      final writes = setup.map.style.updates['navigation-route-source']!;
      expect(writes, hasLength(1));
      final origin = _routeCoordinates(writes.single).first as List;
      expect(origin[0], closeTo(17, 1e-9));
      expect(origin[1], closeTo(48, 1e-9));
      final current = setup.camera.prepareStyle(
        '{"version":8,"sources":{},"layers":[]}',
      );
      setup.map.style.updates.clear();
      await setup.camera.handleStyleLoaded(
        setup.map.style,
        overlaysPrepared: true,
        preparedStyle: current,
      );
      await tester.pump();
      expect(setup.map.style.updates['navigation-route-source'], isNull);
    },
  );
  testWidgets(
    'map clicks await 0.4 feature queries and preserve every category',
    (tester) async {
      final setup = await _setupFollow(tester, notams: _Notams());
      setup.camera.handleMapEvent(
        ml.MapEventCameraMoveEnd(
          camera: setup.map.camera,
          reason: ml.CameraChangeReason.programmatic,
        ),
      );
      final gate = Completer<void>();
      setup.map.featureQueryGate = gate.future;
      final result = Completer<List<dynamic>>();
      ml.Geographic? tappedPoint;
      const coordinate = ml.Geographic(lat: 48, lon: 17);
      setup.camera.handleMapEvent(
        const ml.MapEventClick(point: coordinate, screenPoint: Offset(10, 20)),
        onFeaturesTapped: (features, point) {
          tappedPoint = point;
          result.complete(features);
        },
      );
      await tester.pump();
      expect(result.isCompleted, isFalse);
      setup.camera.handleMapEvent(
        ml.MapEventCameraMoveEnd(
          camera: setup.map.camera,
          reason: ml.CameraChangeReason.programmatic,
        ),
      );
      gate.complete();
      await tester.pump();
      expect(result.isCompleted, isTrue);
      final features = await result.future;
      expect(tappedPoint, coordinate);
      expect(features.map((feature) => feature['layerType']), [
        'airport',
        'airspace',
        'place',
        'notam',
        'favorite',
        'traffic',
        'flight-weather',
      ]);
      expect(setup.map.queriedLayers, hasLength(7));
      expect(features.first['properties']['metadata'], {'nested': true});
    },
  );

  for (final query in [1, 7]) {
    testWidgets(
      'map clicks discard results when camera changes at query $query',
      (tester) async {
        final setup = await _setupFollow(tester, notams: _Notams());
        final gate = Completer<void>();
        setup.map.featureQueryGate = gate.future;
        setup.map.featureQueryGateAt = query;
        setup.camera.handleMapEvent(
          ml.MapEventCameraMove(
            camera: setup.map.camera,
            reason: ml.CameraChangeReason.programmatic,
          ),
        );
        var taps = 0;
        setup.camera.handleMapEvent(
          const ml.MapEventClick(
            point: ml.Geographic(lat: 48, lon: 17),
            screenPoint: Offset(10, 20),
          ),
          onFeaturesTapped: (_, _) => taps++,
        );
        await tester.pump();
        expect(setup.map.queriedLayers, hasLength(query));
        setup.camera.handleMapEvent(
          ml.MapEventCameraMove(
            camera: ml.CameraPosition(
              center: const ml.Geographic(lat: 48.1, lon: 17.1),
              zoom: setup.map.camera.zoom,
              pitch: setup.map.camera.pitch,
              bearing: setup.map.camera.bearing,
            ),
            reason: ml.CameraChangeReason.gesture,
          ),
        );
        gate.complete();
        await tester.pump();
        expect(taps, 0);
      },
    );
  }

  testWidgets('final traffic viewport waits for the ending presented camera', (
    tester,
  ) async {
    final setup = await _setupFollow(tester);
    final traffic =
        setup.camera.refAccess.read(trafficProvider.notifier) as _Traffic;
    traffic.viewports.clear();
    final oldCamera = setup.map.camera;
    setup.camera.handleCameraPresented(oldCamera);
    setup.camera.handleUserInteraction();
    final ending = ml.CameraPosition(
      center: const ml.Geographic(lat: 49, lon: 18),
      zoom: oldCamera.zoom,
      pitch: oldCamera.pitch,
      bearing: oldCamera.bearing,
    );
    setup.camera.handleMapEvent(
      ml.MapEventCameraMove(
        camera: ending,
        reason: ml.CameraChangeReason.gesture,
      ),
    );
    setup.camera.handleMapEvent(
      ml.MapEventCameraMoveEnd(
        camera: ending,
        reason: ml.CameraChangeReason.gesture,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(setup.map.viewportReads, 0);
    setup.camera.handleCameraPresented(oldCamera);
    expect(setup.map.viewportReads, 0);
    setup.map.camera = ending;
    setup.camera.handleCameraPresented(ending);
    expect(setup.map.viewportReads, 1);
    expect(
      traffic.viewports.single,
      const ml.GeoBox(south: 47, north: 49, west: 16, east: 18),
    );
    setup.camera.handleCameraPresented(ending);
    expect(setup.map.viewportReads, 1);
  });

  testWidgets(
    'an exact prepared snapshot does not move an uninitialized native camera',
    (tester) async {
      final setup = await _setupFollow(tester, notams: _Notams());
      final native = _UninitializedMap();
      setup.camera.attachController(
        native,
        cameraPrepared: true,
        preparedCamera: const InitialMapCamera(
          center: ml.Geographic(lat: 48, lon: 17),
          zoom: 6,
          hasLocation: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(native.moves, 0);
    },
  );

  testWidgets(
    'invalid prepared route origins preserve saved legs without a connector',
    (tester) async {
      final setup = await _setupFollow(
        tester,
        notams: _Notams(),
        navigation: _Navigation(_route),
        initialTelemetry: _Telemetry(const TelemetryState()),
        initialCamera: InitialMapCamera(
          center: ml.Geographic(lat: double.nan, lon: 17),
          zoom: 6,
          hasLocation: true,
        ),
      );
      final prepared = _decodePrepared(
        setup.camera.prepareStyle('{"version":8,"sources":{},"layers":[]}'),
      );
      final line =
          prepared['sources']['navigation-route-source']['data']['features'][0]['geometry']['coordinates']
              as List;
      expect(line.first[0], closeTo(18, 1e-9));
      expect(line.first[1], closeTo(49, 1e-9));
      expect(line.last[0], closeTo(19, 1e-9));
      final raw = GeoJsonBuilder.buildNavigationRouteGeoJson(
        _route,
        origin: ml.Geographic(lat: double.nan, lon: 17),
      );
      expect(_routeCoordinates(raw).first[0], closeTo(18, 1e-9));
    },
  );

  testWidgets(
    'failed route writes retry latest state and stop after a bounded budget',
    (tester) async {
      final setup = await _setupFollow(
        tester,
        notams: _Notams(),
        navigation: _Navigation(_route),
      );
      setup.map.style.routeWriteFailures = 4;
      setup.telemetry.changePosition(48.1, 17.1);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      for (final delay in [250, 500, 750]) {
        await tester.pump(Duration(milliseconds: delay));
        await tester.pump();
      }
      final writes = setup.map.style.updates['navigation-route-source']!;
      expect(writes, hasLength(4));
      await tester.pump(const Duration(seconds: 5));
      expect(writes, hasLength(4));
      setup.telemetry.changePosition(48.2, 17.2);
      await tester.pump(const Duration(seconds: 2));
      expect(_routeCoordinates(writes.last).first[0], closeTo(17.2, 1e-9));
    },
  );

  testWidgets('new route edits supersede a pending failed-write retry', (
    tester,
  ) async {
    final navigation = _Navigation(_route);
    final setup = await _setupFollow(
      tester,
      notams: _Notams(),
      navigation: navigation,
    );
    setup.map.style.routeWriteFailures = 1;
    navigation.publish(const NavigationState());
    await tester.pump();
    navigation.publish(_route);
    await tester.pump();
    final writes = setup.map.style.updates['navigation-route-source']!;
    expect(writes, hasLength(2));
    expect(_routeCoordinates(writes.last).last[0], closeTo(19, 1e-9));
    await tester.pump(const Duration(seconds: 3));
    expect(writes, hasLength(2));
  });

  testWidgets(
    'a loaded style uses its own snapshot even after another preparation',
    (tester) async {
      final setup = await _setupFollow(
        tester,
        notams: _Notams(),
        navigation: _Navigation(_route),
      );
      final first = setup.camera.prepareStyle(
        '{"version":8,"sources":{},"layers":[]}',
      );
      setup.telemetry.changePosition(49, 18);
      setup.camera.prepareStyle('{"version":8,"sources":{},"layers":[]}');
      setup.map.style.updates.clear();
      await setup.camera.handleStyleLoaded(
        setup.map.style,
        overlaysPrepared: true,
        preparedStyle: first,
      );
      final aircraft = jsonDecode(
        setup.map.style.updates['aircraft-source']!.last,
      );
      expect(aircraft['features'][0]['geometry']['coordinates'], [18, 49]);
    },
  );

  testWidgets(
    'brightness changes during native loading refresh the prepared palette',
    (tester) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.light;
      final setup = await _setupFollow(
        tester,
        notams: _Notams(),
        preferences: _SystemPreferences(),
        settings: _Settings(const AppSettings(showFlightWeather: false)),
      );
      final prepared = setup.camera.prepareStyle(
        '{"version":8,"sources":{},"layers":[]}',
      );
      setup.map.style = _Style();
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
      await setup.camera.handleStyleLoaded(
        setup.map.style,
        overlaysPrepared: true,
        preparedStyle: prepared,
      );
      await tester.pump();
      expect(
        (setup.map.style.layers['flight-weather-wind']!.toJson()['paint']
            as Map)['text-color'],
        '#E4F2FC',
      );
    },
  );

  testWidgets('NOTAM errors clear both prepared data and catch-up data', (
    tester,
  ) async {
    final notams = _Notams();
    final setup = await _setupFollow(tester, notams: notams);
    notams.publish([
      Notam(
        id: 'n',
        fir: 'LZBB',
        from: DateTime.utc(2026),
        msg: 'notice',
        latitude: 48,
        longitude: 17,
        radius: 1000,
      ),
    ]);
    final prepared = setup.camera.prepareStyle(
      '{"version":8,"sources":{},"layers":[]}',
    );
    notams.fail();
    final failed = _decodePrepared(
      setup.camera.prepareStyle('{"version":8,"sources":{},"layers":[]}'),
    );
    expect(failed['sources']['notams-source']['data']['features'], isEmpty);
    setup.map.style.updates.clear();
    await setup.camera.handleStyleLoaded(
      setup.map.style,
      overlaysPrepared: true,
      preparedStyle: prepared,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      jsonDecode(setup.map.style.updates['notams-source']!.last)['features'],
      isEmpty,
    );
  });

  testWidgets('course catch-up rereads telemetry after the aircraft write', (
    tester,
  ) async {
    final setup = await _setupFollow(
      tester,
      notams: _Notams(),
      initialTelemetry: _Telemetry(
        const TelemetryState(
          latitude: 48,
          longitude: 17,
          groundSpeed: 30,
          isFlying: true,
          mapViewState: MapViewState.overview,
        ),
      ),
    );
    final prepared = setup.camera.prepareStyle(
      '{"version":8,"sources":{},"layers":[]}',
    );
    setup.telemetry.changePosition(48.1, 17.1);
    final aircraftDone = Completer<void>();
    setup.map.style.nextAircraftWriteDelay = aircraftDone.future;
    final loading = setup.camera.handleStyleLoaded(
      setup.map.style,
      overlaysPrepared: true,
      preparedStyle: prepared,
    );
    setup.telemetry.changePosition(48.2, 17.2);
    aircraftDone.complete();
    await loading;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    );
    final expected = GeoJsonBuilder.buildCourseLineGeoJson(
      container.read(telemetryProvider),
      container.read(appSettingsProvider).value,
    );
    expect(setup.map.style.updates['course-line-source']!.last, expected);
  });

  testWidgets(
    'an aircraft failure does not skip airspace and traffic initialization',
    (tester) async {
      final setup = await _setupFollow(tester, notams: _Notams());
      setup.map.style.failNextAircraftWrite = true;
      await setup.camera.handleStyleLoaded(
        setup.map.style,
        overlaysPrepared: true,
      );
      expect(setup.map.viewportReads, greaterThan(0));
      expect(setup.map.style.removedLayers, contains('active-airspaces-fill'));
    },
  );

  testWidgets('attaching a stale prepared camera catches up latest telemetry', (
    tester,
  ) async {
    final setup = await _setupFollow(
      tester,
      notams: _Notams(),
      initialTelemetry: _Telemetry(
        const TelemetryState(
          latitude: 49,
          longitude: 18,
          mapViewState: MapViewState.overview,
        ),
      ),
    );
    final native = _Map();
    setup.camera.attachController(native, cameraPrepared: true);
    await tester.pump(const Duration(milliseconds: 250));
    expect(native.camera.center, const ml.Geographic(lat: 49, lon: 18));
  });

  testWidgets('startup route contains saved legs before any telemetry position', (
    tester,
  ) async {
    final telemetry = _Telemetry(const TelemetryState());
    final setup = await _setupFollow(
      tester,
      initialTelemetry: telemetry,
      navigation: _Navigation(_route),
      notams: _Notams(),
    );
    final prepared = _decodePrepared(
      setup.camera.prepareStyle('{"version":8,"sources":{},"layers":[]}'),
    );
    final line =
        prepared['sources']['navigation-route-source']['data']['features'][0]['geometry']['coordinates']
            as List;
    expect(line.first[0], closeTo(18, 1e-9));
    expect(line.first[1], closeTo(49, 1e-9));
    expect(line.last[0], closeTo(19, 1e-9));
    expect(line.last[1], closeTo(50, 1e-9));
    expect(telemetry.latitude, isNull);
  });

  testWidgets(
    'known startup origin is embedded and first GPS bypasses route throttling',
    (tester) async {
      final telemetry = _Telemetry(const TelemetryState());
      final setup = await _setupFollow(
        tester,
        initialTelemetry: telemetry,
        navigation: _Navigation(_route),
        notams: _Notams(),
        initialCamera: const InitialMapCamera(
          center: ml.Geographic(lat: 48, lon: 17),
          zoom: 6,
          hasLocation: true,
        ),
      );
      final prepared = _decodePrepared(
        setup.camera.prepareStyle('{"version":8,"sources":{},"layers":[]}'),
      );
      final initial =
          prepared['sources']['navigation-route-source']['data']['features'][0]['geometry']['coordinates']
              as List;
      expect(initial.first[0], closeTo(17, 1e-9));
      expect(initial.first[1], closeTo(48, 1e-9));
      expect(telemetry.latitude, isNull);
      telemetry.changePosition(48.1, 17.2);
      final writes = setup.map.style.updates['navigation-route-source']!;
      expect(writes, hasLength(1));
      final line = _routeCoordinates(writes.single);
      expect(line.first[0], closeTo(17.2, 1e-9));
      expect(line.first[1], closeTo(48.1, 1e-9));
      await tester.pump();
    },
  );

  testWidgets('last GPS update is delivered even when no next sample arrives', (
    tester,
  ) async {
    final telemetry = _Telemetry(
      const TelemetryState(
        latitude: 48,
        longitude: 17,
        mapViewState: MapViewState.overview,
      ),
    );
    final setup = await _setupFollow(
      tester,
      initialTelemetry: telemetry,
      navigation: _Navigation(_route),
      notams: _Notams(),
    );
    telemetry.changePosition(48.01, 17.01);
    await tester.pump(const Duration(milliseconds: 500));
    telemetry.changePosition(48.02, 17.02);
    await tester.pump(const Duration(milliseconds: 1299));
    expect(setup.map.style.updates['navigation-route-source'], isNull);
    await tester.pump(const Duration(milliseconds: 1));
    final writes = setup.map.style.updates['navigation-route-source']!;
    expect(writes, hasLength(1));
    final line = _routeCoordinates(writes.single);
    expect(line.first[0], closeTo(17.02, 1e-9));
    expect(line.first[1], closeTo(48.02, 1e-9));
    await tester.pump(const Duration(seconds: 5));
    expect(writes, hasLength(1));
  });

  testWidgets('route edits supersede pending position updates immediately', (
    tester,
  ) async {
    final navigation = _Navigation(_route);
    final telemetry = _Telemetry(
      const TelemetryState(
        latitude: 48,
        longitude: 17,
        mapViewState: MapViewState.overview,
      ),
    );
    final setup = await _setupFollow(
      tester,
      initialTelemetry: telemetry,
      navigation: navigation,
      notams: _Notams(),
    );
    telemetry.changePosition(48.01, 17.01);
    navigation.publish(const NavigationState());
    expect(
      jsonDecode(
        setup.map.style.updates['navigation-route-source']!.single,
      )['features'],
      isEmpty,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(setup.map.style.updates['navigation-route-source'], hasLength(1));
  });

  testWidgets(
    'a slow native write is followed by the latest route and position',
    (tester) async {
      final navigation = _Navigation(_route);
      final telemetry = _Telemetry(
        const TelemetryState(
          latitude: 48,
          longitude: 17,
          mapViewState: MapViewState.overview,
        ),
      );
      final setup = await _setupFollow(
        tester,
        initialTelemetry: telemetry,
        navigation: navigation,
        notams: _Notams(),
      );
      final oldWrite = Completer<void>();
      setup.map.style.nextRouteWriteDelay = oldWrite.future;
      navigation.publish(_route.copyWith(points: [_route.points.first]));
      telemetry.changePosition(48.1, 17.1);
      navigation.publish(_route);
      expect(setup.map.style.updates['navigation-route-source'], hasLength(1));
      oldWrite.complete();
      await tester.pump();
      final writes = setup.map.style.updates['navigation-route-source']!;
      expect(writes, hasLength(2));
      final line = _routeCoordinates(writes.last);
      expect(line.first[0], closeTo(17.1, 1e-9));
      expect(line.last[0], closeTo(19, 1e-9));
      await tester.pump(const Duration(seconds: 3));
      expect(writes, hasLength(2));
    },
  );

  testWidgets('leaving the map cancels its pending route update', (
    tester,
  ) async {
    final telemetry = _Telemetry(
      const TelemetryState(
        latitude: 48,
        longitude: 17,
        mapViewState: MapViewState.overview,
      ),
    );
    final setup = await _setupFollow(
      tester,
      initialTelemetry: telemetry,
      navigation: _Navigation(_route),
      notams: _Notams(),
    );
    telemetry.changePosition(48.1, 17.1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(setup.map.style.updates['navigation-route-source'], isNull);
  });

  testWidgets('prepared style embeds GeoJSON without native layer writes', (
    tester,
  ) async {
    final setup = await _setupFollow(tester, notams: _Notams());
    setup.map.style.layers.dispose();
    setup.map.style.updates.clear();
    final prepared = setup.camera.prepareStyle(
      '{"version":8,"sources":{},"layers":[]}',
    );
    final document = jsonDecode(prepared.json);
    final sources = document['sources'] as Map;
    expect(
      sources.keys,
      containsAll([
        'aircraft-source',
        'navigation-route-source',
        'favorites-source',
        'traffic-source',
        'notams-source',
        'course-line-source',
        'flight-weather-source',
      ]),
    );
    expect(
      sources['aircraft-source']['data']['features'][0]['geometry']['coordinates'],
      [17, 48],
    );
    expect(setup.map.style.layers, isEmpty);
    expect(setup.map.style.updates, isEmpty);
    await setup.camera.handleStyleLoaded(
      setup.map.style,
      overlaysPrepared: true,
      preparedStyle: prepared,
    );
    expect(setup.map.style.layers, isEmpty);
    expect(setup.map.style.updates, isEmpty);
  });

  testWidgets(
    'focusing a point stops following and keeps the selected center',
    (tester) async {
      final setup = await _setupFollow(tester);
      const point = ml.Geographic(lat: 47.8566, lon: 18.1257);
      final focus = setup.camera.focusOnPoint(
        latitude: point.lat,
        longitude: point.lon,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await focus;

      setup.telemetry.changeLatitude(0);
      setup.telemetry.changeLatitude(49);
      await tester.pump(const Duration(seconds: 6));

      expect(setup.map.animatedCenters, [point]);
      expect(setup.map.camera.center, point);
    },
  );

  testWidgets(
    'stationary DroneCAN fix toggles Follow without local GPS permission',
    (tester) async {
      final controller = StreamController<Position>.broadcast();
      final previousPlatform = GeolocatorPlatform.instance;
      final gps = _GpsPermissions(controller);
      GeolocatorPlatform.instance = gps;
      addTearDown(() async {
        GeolocatorPlatform.instance = previousPlatform;
        await controller.close();
      });
      final setup = await _setupFollow(
        tester,
        initialTelemetry: _Telemetry(
          const TelemetryState(
            latitude: 48.76925,
            longitude: 18.59128,
            groundSpeed: 0,
            heading: 220,
            isGpsDroneCan: true,
            mapViewState: MapViewState.overview,
          ),
        ),
      );
      await setup.camera.handleGpsToggle();
      await tester.pump(const Duration(milliseconds: 250));
      expect(setup.telemetry.view, MapViewState.follow);
      expect(setup.map.camera.bearing, 220);
      expect(setup.map.camera.pitch, 30);
      expect(
        setup.map.camera.center,
        const ml.Geographic(lat: 48.76925, lon: 18.59128),
      );
      expect(gps.permissionChecks, 0);
      expect(gps.permissionRequests, 0);
      expect(gps.getPositionStreamCallCount, 0);

      await setup.camera.handleGpsToggle();
      await tester.pump(const Duration(milliseconds: 250));
      expect(setup.telemetry.view, MapViewState.overview);
      expect(gps.permissionChecks, 0);
    },
  );

  testWidgets(
    'invalid DroneCAN coordinates do not bypass local GPS permission',
    (tester) async {
      final controller = StreamController<Position>.broadcast();
      final previousPlatform = GeolocatorPlatform.instance;
      final gps = _GpsPermissions(controller);
      GeolocatorPlatform.instance = gps;
      addTearDown(() async {
        GeolocatorPlatform.instance = previousPlatform;
        await controller.close();
      });
      final setup = await _setupFollow(
        tester,
        initialTelemetry: _Telemetry(
          const TelemetryState(
            latitude: 0,
            longitude: 0,
            isGpsDroneCan: true,
            mapViewState: MapViewState.overview,
          ),
        ),
      );
      await setup.camera.handleGpsToggle();
      expect(gps.permissionChecks, greaterThan(0));
      expect(gps.permissionRequests, 1);
      expect(setup.telemetry.view, isNot(MapViewState.follow));
    },
  );

  testWidgets('GPS can request permission after focusing a search result', (
    tester,
  ) async {
    final controller = StreamController<Position>.broadcast();
    final previousPlatform = GeolocatorPlatform.instance;
    final gps = _GpsPermissions(controller);
    GeolocatorPlatform.instance = gps;
    addTearDown(() async {
      GeolocatorPlatform.instance = previousPlatform;
      await controller.close();
    });
    final setup = await _setupFollow(tester);
    setup.telemetry.setMapViewState(MapViewState.init);
    const point = ml.Geographic(lat: 47.8566, lon: 18.1257);
    final focus = setup.camera.focusOnPoint(
      latitude: point.lat,
      longitude: point.lon,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await focus;

    await setup.camera.handleGpsToggle();
    expect(gps.permissionRequests, 1);
    expect(gps.getPositionStreamCallCount, 0);
    expect(setup.telemetry.view, MapViewState.overview);
    expect(setup.map.camera.center, point);

    gps.grantOnRequest = true;
    await setup.camera.handleGpsToggle();
    expect(gps.permissionRequests, 2);
    expect(gps.getPositionStreamCallCount, 1);
    expect(setup.telemetry.view, MapViewState.overview);
    expect(setup.map.camera.center, point);

    await setup.camera.handleGpsToggle();
    await tester.pump(const Duration(milliseconds: 250));
    expect(gps.permissionRequests, 2);
    expect(setup.telemetry.view, MapViewState.follow);
  });

  testWidgets('late startup location leaves the camera in its current mode', (
    tester,
  ) async {
    final controller = StreamController<Position>.broadcast();
    final previousPlatform = GeolocatorPlatform.instance;
    final initialPosition = Completer<Position?>();
    final gps = _GpsPermissions(controller)
      ..permission = LocationPermission.whileInUse
      ..lastKnownPosition = initialPosition.future;
    GeolocatorPlatform.instance = gps;
    addTearDown(() async {
      GeolocatorPlatform.instance = previousPlatform;
      await controller.close();
    });

    final setup = await _setupFollow(tester);
    setup.telemetry.setMapViewState(MapViewState.init);
    final startup = setup.camera.autoStartGps();
    await tester.pump();
    expect(gps.lastKnownPosition, isNull);

    setup.telemetry.setMapViewState(MapViewState.waitingForGps);
    final currentCenter = setup.map.camera.center;
    final currentZoom = setup.map.camera.zoom;
    initialPosition.complete(makePosition(lat: 47.8566, lon: 18.1257));
    await startup;
    await tester.pump(const Duration(milliseconds: 250));

    expect(setup.map.camera.center, currentCenter);
    expect(setup.map.camera.zoom, currentZoom);
    expect(setup.telemetry.view, MapViewState.waitingForGps);
    expect(gps.getPositionStreamCallCount, 1);
  });

  testWidgets('a late style load leaves NOTAM updates on the current style', (
    tester,
  ) async {
    final notams = _Notams();
    final (:map, :camera, telemetry: _, traffic: _) = await _setupFollow(
      tester,
      notams: notams,
    );
    final previousStyle = map.style;
    final finishPreviousLoad = Completer<void>();
    previousStyle.nextFavoritesLayerDelay = finishPreviousLoad.future;
    final previousLoad = camera.handleStyleLoaded(previousStyle);
    await tester.pump();

    map.style = _Style();
    await camera.handleStyleLoaded(map.style);
    finishPreviousLoad.complete();
    await previousLoad;

    notams.publish([
      Notam(id: 'A1234/26', from: DateTime.utc(2026), radius: 1852),
    ]);
    expect(map.style.updates['notams-source'], hasLength(1));
    expect(previousStyle.updates['notams-source'], isNull);
  });

  testWidgets('NOTAM fill and outline use the shared colour', (tester) async {
    final setup = await _setupFollow(tester);
    final layers = setup.map.style.layers;
    final fill = layers['notams-fill-layer']!.toJson()['paint'] as Map;
    final outline = layers['notams-line-layer']!.toJson()['paint'] as Map;
    expect(fill['fill-color'], mapColorHex(StorkColors.notam));
    expect(outline['line-color'], fill['fill-color']);
    expect(fill['fill-opacity'], 0.25);
    expect(outline['line-width'], 2.0);
    expect(outline['line-dasharray'], [2.0, 2.0]);
  });

  testWidgets('retries a failed NOTAM source write after one second', (
    tester,
  ) async {
    final notams = _Notams();
    final setup = await _setupFollow(tester, notams: notams);
    final style = setup.map.style;
    style.failNextNotamWrite = true;

    notams.publish([
      Notam(id: 'A1234/26', from: DateTime.utc(2026), radius: 1852),
    ]);

    final writes = style.updates['notams-source']!;
    await tester.pump(const Duration(milliseconds: 999));
    expect(writes, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(writes, hasLength(2));
    expect(writes.last, writes.first);

    await tester.pump(const Duration(seconds: 1));
    expect(writes, hasLength(2));
  });

  testWidgets('batches NOTAM layer writes and uses the latest snapshot', (
    tester,
  ) async {
    final notams = _Notams();
    final (:map, :camera, telemetry: _, traffic: _) = await _setupFollow(
      tester,
      notams: notams,
    );
    final writes = map.style.updates;
    Notam notice(String id) => Notam(
      id: id,
      from: DateTime.utc(2026),
      radius: 1852,
      latitude: 48,
      longitude: 17,
    );

    notams.publish([notice('first')]);
    expect(writes['notams-source'], hasLength(1));
    notams.publish([notice('second')]);
    await tester.pump(const Duration(milliseconds: 500));
    notams.publish([notice('latest')]);
    await tester.pump(const Duration(milliseconds: 499));
    expect(writes['notams-source'], hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(writes['notams-source'], hasLength(2));
    expect(writes['notams-source']!.last, contains('latest'));
    expect(writes['notams-source']!.last, isNot(contains('second')));

    notams.publish([notice('latest')]);
    await tester.pump(const Duration(seconds: 1));
    expect(writes['notams-source'], hasLength(2));
    await camera.handleStyleLoaded(map.style);
    expect(writes['notams-source'], hasLength(3));
  });

  testWidgets('follow applies a saved pitch change without a new GPS fix', (
    tester,
  ) async {
    final (:map, :telemetry, camera: _, traffic: _) = await _setupFollow(
      tester,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    );
    final settings = container.read(appSettingsProvider.notifier) as _Settings;

    expect(map.camera.pitch, 30.0);
    settings.setFollowPitch(60.0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(map.camera.pitch, 60.0);

    telemetry.changeLatitude(48.01);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(map.camera.center.lat, closeTo(48.01, 1e-8));
    expect(map.camera.pitch, 60.0);
  });

  testWidgets('follow keeps the original camera and course interpolation', (
    tester,
  ) async {
    final (:map, :telemetry, camera: _, traffic: _) = await _setupFollow(
      tester,
    );
    telemetry.changeLatitude(48.01);
    await tester.pump();

    List<String> courseUpdates() => map.style.updates['course-line-source']!;
    num courseLatitude() =>
        (jsonDecode(
                      courseUpdates().last,
                    )['features'][0]['geometry']['coordinates'][0]
                    as List)
                .last
            as num;

    await tester.pump(const Duration(milliseconds: 250));
    expect(map.camera.center.lat, closeTo(48.0025, 1e-8));
    expect(courseLatitude(), closeTo(48.005, 1e-8));

    await tester.pump(const Duration(milliseconds: 250));
    expect(map.camera.center.lat, closeTo(48.005, 1e-8));
    expect(courseLatitude(), closeTo(48.01, 1e-8));
    final updatesAtCourseEnd = courseUpdates().length;

    await tester.pump(const Duration(milliseconds: 250));
    expect(map.camera.center.lat, closeTo(48.0075, 1e-8));
    expect(courseUpdates(), hasLength(updatesAtCourseEnd));

    telemetry.changeSpeed(35);
    await tester.pump(const Duration(milliseconds: 100));
    expect(courseUpdates(), hasLength(updatesAtCourseEnd + 1));
    expect(courseLatitude(), closeTo(48.01, 1e-8));

    await tester.pump(const Duration(milliseconds: 150));
    expect(map.camera.center.lat, closeTo(48.01, 1e-8));
    expect(courseUpdates(), hasLength(updatesAtCourseEnd + 1));
  });

  testWidgets('Android follow moves the camera between overlay updates', (
    tester,
  ) async {
    final (:map, :telemetry, camera: _, traffic: _) = await _setupFollow(
      tester,
    );
    telemetry.changeLatitude(48.01);
    await tester.pump();

    final aircraftUpdates = map.style.updates['aircraft-source']!;
    final initialUpdates = aircraftUpdates.length;
    final initialLatitude = map.camera.center.lat;

    await tester.pump(const Duration(milliseconds: 16));
    expect(map.camera.center.lat, greaterThan(initialLatitude));
    expect(aircraftUpdates, hasLength(initialUpdates));

    await tester.pump(const Duration(milliseconds: 16));
    expect(aircraftUpdates, hasLength(initialUpdates + 1));

    await tester.pump(const Duration(milliseconds: 955));
    final beforeFinalTick = aircraftUpdates.length;
    await tester.pump(const Duration(milliseconds: 13));
    expect(aircraftUpdates, hasLength(beforeFinalTick + 1));
    expect(map.camera.center.lat, closeTo(48.01, 1e-8));
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));

  testWidgets(
    'identical traffic updates are skipped while threats still refresh',
    (tester) async {
      final (:map, :traffic, camera: _, telemetry: _) = await _setupFollow(
        tester,
      );
      final aircraft = TrafficAircraft(
        id: 'test',
        callsign: 'TEST',
        latitude: 48.02,
        longitude: 17,
        altitude: 800,
        track: 0,
        groundSpeed: 0,
        verticalSpeed: 0,
        aircraftType: 1,
        lastSeen: DateTime(2026),
      );
      traffic.publish(aircraft);
      final updates = map.style.updates['traffic-source']!;
      expect(updates, hasLength(1));

      traffic.publish(aircraft.copyWith());
      expect(updates, hasLength(1));

      final moved = aircraft.copyWith(latitude: 48.03);
      traffic.publish(moved);
      expect(updates, hasLength(2));

      final threat = moved.copyWith(isCollisionThreat: true);
      traffic.publish(threat);
      traffic.publish(threat.copyWith());
      expect(updates, hasLength(4));

      traffic.publish(moved);
      expect(updates, hasLength(5));
    },
  );

  testWidgets('follow refreshes traffic every 500 ms while presentation lags', (
    tester,
  ) async {
    final setup = await _setupFollow(tester);
    final camera = setup.camera;
    final map = setup.map;
    final telemetry = setup.telemetry;
    final traffic = camera.refAccess.read(trafficProvider.notifier) as _Traffic;
    traffic.viewports.clear();
    camera.handleCameraPresented(map.camera);
    // Native target-camera events continue while presentation is behind.
    map.onPresented = null;
    telemetry.changeLatitude(48.01);
    await tester.pump();
    for (var tick = 1; tick <= 3; tick++) {
      map.viewportBounds = ml.GeoBox(
        south: 47 + tick.toDouble(),
        north: 49 + tick.toDouble(),
        west: 16,
        east: 18,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(map.viewportReads, tick - 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(map.viewportReads, tick);
      expect(traffic.viewports.last, map.viewportBounds);
      expect(map.style.updates['traffic-source'], hasLength(tick));
      telemetry.changeLatitude(48.01 + tick * 0.01);
      await tester.pump();
    }
  });

  testWidgets(
    'follow coalesces idle events and manual idle flushes immediately',
    (tester) async {
      final (:camera, :map, :telemetry, :traffic) = await _setupFollow(tester);
      telemetry.changeLatitude(48.01);
      await tester.pump();

      int trafficUpdates() => map.style.updates['traffic-source']?.length ?? 0;
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(trafficUpdates(), 0);
      expect(map.viewportReads, 0);

      traffic.publish(
        TrafficAircraft(
          id: 'test',
          callsign: 'TEST',
          latitude: 48.02,
          longitude: 17,
          altitude: 800,
          track: 0,
          groundSpeed: 0,
          verticalSpeed: 0,
          aircraftType: 1,
          lastSeen: DateTime(2026),
        ),
      );
      expect(trafficUpdates(), 1);

      await tester.pump(const Duration(milliseconds: 100));
      expect(trafficUpdates(), 2);
      expect(map.viewportReads, 1);

      await tester.pump(const Duration(milliseconds: 100));
      camera.handleUserInteraction();
      camera.handleMapEvent(
        ml.MapEventCameraMoveEnd(
          camera: map.camera,
          reason: ml.CameraChangeReason.programmatic,
        ),
      );
      expect(trafficUpdates(), 3);
      expect(map.viewportReads, 2);

      await tester.pump(const Duration(milliseconds: 500));
      expect(trafficUpdates(), 3);
      expect(map.viewportReads, 2);
    },
  );
}

dynamic _decodePrepared(dynamic prepared) =>
    jsonDecode(prepared.json as String);
