import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/core/theme/stork_colors.dart';
import 'package:stork/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_activity_provider.dart';
import 'package:stork/features/map/presentation/providers/map_camera_provider.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/features/map/presentation/providers/traffic_colors.dart';
import 'package:stork/features/map/domain/models/notam.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/domain/models/resolved_altitude.dart';
import 'package:stork/features/telemetry/presentation/providers/agl_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_provider.dart';

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() => const TelemetryState(
    latitude: 48,
    longitude: 17,
    groundSpeed: 30,
    isFlying: true,
    mapViewState: MapViewState.follow,
  );

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

  @override
  void updateViewport(ml.LngLatBounds bounds) {}
}

class _FilteredTraffic extends FilteredTraffic {
  @override
  List<TrafficAircraft> build() => [];

  void publish(TrafficAircraft aircraft) => state = [aircraft];
}

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();

  void setFollowPitch(double pitch) {
    state = AsyncData(state.requireValue.copyWith(mapFollowPitch: pitch));
  }
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState();
}

class _Notams extends Notams {
  @override
  Future<NotamFetchResult> build() async => const NotamFetchResult([]);

  void publish(List<Notam> notams) {
    state = AsyncData(NotamFetchResult(notams));
  }
}

class _Favorites extends FavoritesNotifier {
  @override
  Future<List<FavoritePoint>> build() async => [];
}

class _Style extends Fake implements ml.StyleController {
  final updates = <String, List<String>>{};
  final layers = <String, ml.StyleLayer>{};
  bool failNextNotamWrite = false;

  @override
  Future<void> addSource(ml.Source source) async {}

  @override
  Future<void> addLayer(
    ml.StyleLayer layer, {
    String? belowLayerId,
    String? aboveLayerId,
    int? atIndex,
  }) async {
    layers[layer.id] = layer;
  }

  @override
  Future<void> removeLayer(String id) async {}

  @override
  Future<void> updateGeoJsonSource({
    required String id,
    required String data,
  }) async {
    (updates[id] ??= []).add(data);
    if (id == 'notams-source' && failNextNotamWrite) {
      failNextNotamWrite = false;
      throw StateError('NOTAM source unavailable');
    }
  }
}

class _Map extends Fake implements ml.MapController {
  @override
  final _Style style = _Style();

  @override
  ml.MapCamera camera = const ml.MapCamera(
    center: ml.Geographic(lat: 48, lon: 17),
    zoom: 12,
    pitch: 0,
    bearing: 0,
  );

  void Function(ml.MapEvent)? onEvent;
  int viewportReads = 0;

  @override
  Future<void> moveCamera({
    ml.Geographic? center,
    double? zoom,
    double? bearing,
    double? pitch,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    camera = ml.MapCamera(
      center: center ?? camera.center,
      zoom: zoom ?? camera.zoom,
      bearing: bearing ?? camera.bearing,
      pitch: pitch ?? camera.pitch,
    );
    onEvent?.call(ml.MapEventMoveCamera(camera: camera));
    onEvent?.call(const ml.MapEventCameraIdle());
  }

  @override
  ml.LngLatBounds getVisibleRegion() {
    viewportReads++;
    return const ml.LngLatBounds(
      latitudeSouth: 47,
      latitudeNorth: 49,
      longitudeWest: 16,
      longitudeEast: 18,
    );
  }
}

Future<
  ({MapCamera camera, _Map map, _Telemetry telemetry, _FilteredTraffic traffic})
>
_setupFollow(WidgetTester tester, {_Notams? notams}) async {
  final telemetry = _Telemetry();
  final traffic = _FilteredTraffic();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        telemetryProvider.overrideWith(() => telemetry),
        filteredTrafficProvider.overrideWith(() => traffic),
        trafficProvider.overrideWith(_Traffic.new),
        appSettingsProvider.overrideWith(_Settings.new),
        currentLocationProvider.overrideWithValue(const AsyncData(null)),
        navigationProvider.overrideWith(_Navigation.new),
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
  camera.attachController(map);
  await camera.handleStyleLoaded(map.style);
  await tester.pump(const Duration(milliseconds: 200));
  map.viewportReads = 0;
  map.style.updates.clear();
  map.onEvent = camera.handleMapEvent;
  return (camera: camera, map: map, telemetry: telemetry, traffic: traffic);
}

void main() {
  testWidgets('NOTAM fill and outline use the shared colour', (tester) async {
    final setup = await _setupFollow(tester);
    final layers = setup.map.style.layers;
    final fill = layers['notams-fill-layer']!.paint;
    final outline = layers['notams-line-layer']!.paint;
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
      camera.handleMapEvent(const ml.MapEventCameraIdle());
      expect(trafficUpdates(), 3);
      expect(map.viewportReads, 2);

      await tester.pump(const Duration(milliseconds: 500));
      expect(trafficUpdates(), 3);
      expect(map.viewportReads, 2);
    },
  );
}
