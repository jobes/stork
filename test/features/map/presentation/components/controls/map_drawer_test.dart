import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre/maplibre.dart' show Geographic;
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/services/mdns_service.dart';
import 'package:stork/core/services/style_provider.dart';
import 'package:stork/core/widgets/stork_navigation_tile.dart';
import 'package:stork/features/map/presentation/components/controls/compass_bar.dart';
import 'package:stork/features/map/presentation/components/controls/draggable_widget.dart';
import 'package:stork/features/map/presentation/components/controls/map_controls.dart';
import 'package:stork/features/map/presentation/components/controls/map_drawer.dart';
import 'package:stork/features/map/presentation/components/controls/map_widget_wrapper.dart';
import 'package:stork/features/map/presentation/pages/map_page.dart';
import 'package:stork/features/map/presentation/providers/map_alerts_provider.dart';
import 'package:stork/features/map/presentation/providers/map_camera_provider.dart';
import 'package:stork/features/map/presentation/providers/map_clock_provider.dart';
import 'package:stork/features/map/presentation/providers/map_radar.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/cannelloni_device.dart';
import 'package:stork/features/settings/domain/models/pilot.dart';
import 'package:stork/features/settings/domain/models/widget_position.dart';
import 'package:stork/features/settings/presentation/pages/settings_page.dart';
import 'package:stork/features/settings/presentation/providers/aircraft_provider.dart';
import 'package:stork/features/settings/presentation/providers/pilot_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/domain/models/resolved_altitude.dart';
import 'package:stork/features/telemetry/presentation/providers/agl_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/traffic_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

const _gateway = CannelloniDevice(
  name: 'Stork gateway',
  hostname: 'gateway.local',
  ip: '192.0.2.1',
  port: 47998,
);

class _MapAlerts extends MapAlerts {
  @override
  List<MapAlert> build() => const [];
}

class _Settings extends AppSettingsNotifier {
  _Settings(this.widgetPositions);

  final Map<String, WidgetPosition> widgetPositions;
  @override
  AppSettings build() => AppSettings(
    pilotId: 'pilot',
    airplaneId: 'aircraft',
    selectedDevice: _gateway,
    widgetPositions: widgetPositions,
  );

  @override
  Future<SettingsUpdateResult> updateAreWidgetsDraggable(bool enabled) async {
    state = AsyncData(
      state.requireValue.copyWith(areWidgetsDraggable: enabled),
    );
    return const SettingsUpdateSuccess();
  }

  @override
  Future<SettingsUpdateResult> updateShowUtcClock(bool visible) async {
    state = AsyncData(state.requireValue.copyWith(showUtcClock: visible));
    return const SettingsUpdateSuccess();
  }

  @override
  Future<SettingsUpdateResult> updateWidgetPosition(
    String widgetId,
    double top,
    double left,
  ) async {
    state = AsyncData(
      state.requireValue.copyWith(
        widgetPositions: {
          ...state.requireValue.widgetPositions,
          widgetId: WidgetPosition(top: top, left: left),
        },
      ),
    );
    return const SettingsUpdateSuccess();
  }
}

class _Pilots extends PilotState {
  @override
  List<Pilot> build() => [const Pilot(id: 'pilot', name: 'Alex')];
}

class _Aircraft extends AircraftState {
  @override
  List<Aircraft> build() => [const Aircraft(id: 'aircraft', name: 'OM-1234')];
}

class _Navigation extends NavigationNotifier {
  _Navigation(this.navigation);

  final NavigationState navigation;

  @override
  NavigationState build() => navigation;
}

class _OfflineMaps extends OfflineMapsNotifier {
  _OfflineMaps(this.maps);

  final OfflineMapsState maps;

  @override
  OfflineMapsState build() => maps;
}

class _DisconnectedGateway extends CannelloniService {
  @override
  bool build() => false;
}

class _MapCamera extends MapCamera {
  @override
  void build() {}

  @override
  Future<void> autoStartGps() async {}
}

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() =>
      const TelemetryState(mapViewState: MapViewState.overview);
}

class _MapStub extends StatelessWidget {
  const _MapStub();

  @override
  Widget build(BuildContext context) => const Scaffold(drawer: MapDrawer());
}

Future<ProviderContainer> _pumpDrawer(
  WidgetTester tester, {
  NavigationState navigation = const NavigationState(),
  OfflineMapsState? maps,
  double textScale = 1,
  Locale locale = const Locale('en'),
  bool useMapPage = false,
  Map<String, WidgetPosition> widgetPositions = const {},
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => useMapPage ? const MapPage() : const _MapStub(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
    ],
  );
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appSettingsProvider.overrideWith(() => _Settings(widgetPositions)),
      pilotStateProvider.overrideWith(_Pilots.new),
      aircraftStateProvider.overrideWith(_Aircraft.new),
      navigationProvider.overrideWith(() => _Navigation(navigation)),
      offlineMapsProvider.overrideWith(
        () => _OfflineMaps(maps ?? OfflineMapsState()),
      ),
      cannelloniServiceProvider.overrideWith(_DisconnectedGateway.new),
      discoveredDevicesProvider.overrideWith((ref) => Stream.value([])),
      if (useMapPage) ...[
        mapStyleProvider.overrideWith((ref) => throw StateError('Test map')),
        mapCameraProvider.overrideWith(_MapCamera.new),
        mapClockProvider.overrideWithValue(DateTime.utc(2026, 11, 12, 14, 32)),
        mapAlertsProvider.overrideWith(_MapAlerts.new),
        telemetryProvider.overrideWith(_Telemetry.new),
        activeCollisionAlertProvider.overrideWith((ref) => null),
        aglProvider.overrideWith(
          (ref) => const AglState(
            resolvedAltitude: ResolvedAltitude(source: AltitudeSource.none),
          ),
        ),
      ],
    ],
  );
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );

  tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  await tester.pumpAndSettle();
  return container;
}

Future<void> _enableEditingInMapSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Map'));
  await tester.pumpAndSettle();

  final moveWidgets = find.widgetWithText(SwitchListTile, 'Move widgets');
  await tester.scrollUntilVisible(
    moveWidgets,
    100,
    scrollable: find.byType(Scrollable),
  );
  await tester.pumpAndSettle();
  await tester.tap(moveWidgets.hitTestable());
  await tester.pumpAndSettle();

  await tester.pageBack();
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  final area = OfflineMapArea(
    id: 'area',
    northwest: const Geographic(lat: 49, lon: 17),
    southeast: const Geographic(lat: 48, lon: 18),
  );

  testWidgets('radar playback is the first action and closes the drawer', (
    tester,
  ) async {
    final container = await _pumpDrawer(tester, useMapPage: true);

    final playback = find.text('Play precipitation history');
    expect(playback.hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(playback).dy,
      lessThan(tester.getTopLeft(find.text('Flight and map')).dy),
    );

    await tester.tap(playback);
    await tester.pumpAndSettle();
    expect(find.byType(MapDrawer), findsNothing);
    expect(container.read(mapRadarProvider).value.unavailable, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'shows the active crew, destination and offline map download date',
    (tester) async {
      await _pumpDrawer(
        tester,
        navigation: const NavigationState(
          isActive: true,
          points: [
            NavigationPoint(latitude: 48.7, longitude: 17.7, name: 'Waypoint'),
            NavigationPoint(latitude: 48.6, longitude: 17.8, name: 'Piešťany'),
          ],
        ),
        maps: OfflineMapsState(
          isDownloaded: true,
          regions: [area],
          downloadDate: DateTime(2026, 11, 6),
        ),
      );

      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Move widgets'), findsNothing);
      expect(find.text('OM-1234'), findsOneWidget);
      expect(find.text('Active · Piešťany'), findsOneWidget);
      expect(find.text('Downloaded Nov 6, 2026'), findsOneWidget);
      final tiles = tester.widgetList<StorkNavigationTile>(
        find.byType(StorkNavigationTile),
      );
      expect(tiles.map((tile) => tile.title), [
        'Route',
        'Flight Records',
        'Favorite places',
        'Offline maps',
        'Settings',
      ]);
      expect(tiles.where((tile) => tile.highlighted).single.title, 'Route');
    },
  );

  testWidgets('formats the download date in Slovak', (tester) async {
    await _pumpDrawer(
      tester,
      locale: const Locale('sk'),
      maps: OfflineMapsState(
        regions: [area],
        isDownloaded: true,
        downloadDate: DateTime(2026, 11, 6),
      ),
    );

    expect(find.text('Stiahnuté 6. 11. 2026'), findsOneWidget);
  });

  testWidgets('shows download required instead of a stale download date', (
    tester,
  ) async {
    await _pumpDrawer(
      tester,
      maps: OfflineMapsState(
        regions: [area],
        downloadDate: DateTime(2026, 11, 6),
      ),
    );

    expect(
      find.text('Download required for the selected areas'),
      findsOneWidget,
    );
    expect(find.text('Downloaded Nov 6, 2026'), findsNothing);
  });

  testWidgets('dragging stops at instruments, compass and map buttons', (
    tester,
  ) async {
    final container = await _pumpDrawer(
      tester,
      useMapPage: true,
      widgetPositions: const {
        'speed_widget': WidgetPosition(top: 200, left: 180),
        'altitude_widget': WidgetPosition(top: 200, left: 400),
        'vario_widget': WidgetPosition(top: 400, left: 180),
        'flight_time_widget': WidgetPosition(top: 400, left: 400),
        'utc_clock_widget': WidgetPosition(top: 500, left: 100),
      },
    );
    await _enableEditingInMapSettings(tester);

    Finder instrument(String id) => find.byWidgetPredicate(
      (widget) => widget is MapWidgetWrapper && widget.widgetId == id,
    );
    final speed = instrument('speed_widget');

    Future<void> drag(Offset delta) async {
      final gesture = await tester.startGesture(tester.getCenter(speed));
      await gesture.moveBy(Offset(20 * delta.dx.sign, 20 * delta.dy.sign));
      await gesture.moveBy(delta);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    final altitude = tester.getRect(instrument('altitude_widget'));
    await drag(const Offset(500, 0));
    expect(tester.getRect(speed).right, closeTo(altitude.left, 0.01));

    await drag(const Offset(-100, 0));
    await drag(const Offset(0, -300));
    final compass = tester.getRect(find.byType(CompassBar));
    expect(tester.getRect(speed).top, closeTo(compass.bottom, 0.01));

    final controls = find.byType(MapControls);
    final buttons = find.descendant(
      of: controls,
      matching: find.byType(IconButton),
    );
    final menu = tester.getRect(buttons.first);
    final gps = tester.getRect(buttons.last);
    await drag(const Offset(0, 140));
    await drag(const Offset(-500, 0));
    await drag(const Offset(0, -300));
    expect(tester.getRect(speed).top, closeTo(menu.bottom, 0.01));

    await drag(const Offset(0, 220));
    await drag(const Offset(800, 0));
    await drag(const Offset(0, -300));
    expect(tester.getRect(speed).top, closeTo(gps.bottom, 0.01));

    final saved = container
        .read(appSettingsProvider)
        .requireValue
        .widgetPositions['speed_widget']!;
    expect(saved.top, closeTo(gps.bottom, 0.01));
  });

  testWidgets('UTC clock uses the default and saved map layout', (
    tester,
  ) async {
    final container = await _pumpDrawer(tester, useMapPage: true);
    tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
    await tester.pumpAndSettle();
    Finder instrument(String id) => find.byWidgetPredicate(
      (widget) => widget is MapWidgetWrapper && widget.widgetId == id,
    );
    final clock = instrument('utc_clock_widget');
    expect(find.text('14:32 UTC', findRichText: true), findsOneWidget);
    final wrapper = tester.widget<MapWidgetWrapper>(clock);
    expect(wrapper.defaultLeft, 652);
    expect(wrapper.defaultTop, 50);

    await tester.tap(clock);
    await tester.pumpAndSettle();
    expect(find.text('Time and sun'), findsOneWidget);
    expect(find.text('Waiting for GPS...'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).hitTestable().first);
    await tester.pumpAndSettle();

    final settings = container.read(appSettingsProvider.notifier);
    await settings.updateWidgetPosition('utc_clock_widget', 300, 500);
    await settings.updateAreWidgetsDraggable(true);
    await tester.pumpAndSettle();
    final oldPosition = tester.getTopLeft(clock);
    expect(oldPosition, const Offset(500, 300));
    final gesture = await tester.startGesture(tester.getCenter(clock));
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 160));
    await gesture.up();
    await tester.pumpAndSettle();
    final newPosition = tester.getTopLeft(clock);
    expect(newPosition.dy, greaterThan(oldPosition.dy));
    final saved = container
        .read(appSettingsProvider)
        .requireValue
        .widgetPositions['utc_clock_widget']!;
    expect(newPosition, Offset(saved.left, saved.top));

    Future<void> toggleClockFromMenu() async {
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      final widgetSettings = find.widgetWithText(ListTile, 'Widget settings');
      await tester.scrollUntilVisible(
        widgetSettings,
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(widgetSettings.hitTestable());
      await tester.pumpAndSettle();

      final toggle = find.widgetWithText(SwitchListTile, 'Show UTC clock');
      final wasVisible = tester.widget<SwitchListTile>(toggle).value;
      await tester.tap(toggle.hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.text('Sunset warning (min)'),
        wasVisible ? findsNothing : findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await toggleClockFromMenu();
    expect(clock, findsNothing);
    await toggleClockFromMenu();
    expect(tester.getTopLeft(clock), newPosition);
  });

  testWidgets('finishes widget editing from the map controls', (tester) async {
    final container = await _pumpDrawer(tester, useMapPage: true);

    await _enableEditingInMapSettings(tester);
    expect(
      tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
      isFalse,
    );
    expect(
      container.read(appSettingsProvider).requireValue.areWidgetsDraggable,
      isTrue,
    );

    final done = find.descendant(
      of: find.byType(MapControls),
      matching: find.widgetWithText(FilledButton, 'Done'),
    );
    expect(done.hitTestable(), findsOneWidget);
    await tester.tap(done);
    await tester.pumpAndSettle();

    expect(done, findsNothing);
    expect(
      container.read(appSettingsProvider).requireValue.areWidgetsDraggable,
      isFalse,
    );
    final widgets = tester.widgetList<DraggableWidget>(
      find.byType(DraggableWidget),
    );
    expect(widgets, hasLength(5));
    expect(widgets.every((widget) => !widget.isDraggable), isTrue);
  });

  testWidgets('system back finishes editing without leaving the map', (
    tester,
  ) async {
    final container = await _pumpDrawer(tester, useMapPage: true);
    final map = tester.state(find.byType(MapPage));
    await _enableEditingInMapSettings(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.state(find.byType(MapPage)), same(map));
    expect(
      container.read(appSettingsProvider).requireValue.areWidgetsDraggable,
      isFalse,
    );
  });

  testWidgets('reaches disconnected gateway settings and returns to the map', (
    tester,
  ) async {
    await _pumpDrawer(tester);
    final map = tester.state<ScaffoldState>(find.byType(Scaffold));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(map.isDrawerOpen, isFalse);

    await tester.tap(find.text('Instruments and connection'));
    await tester.pumpAndSettle();
    expect(find.text('Gateway disconnected'), findsOneWidget);
    expect(find.text('gateway.local'), findsOneWidget);
    expect(find.text('DroneCAN instruments'), findsOneWidget);
    expect(find.text('Search again'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(tester.state<ScaffoldState>(find.byType(Scaffold)), same(map));
  });

  testWidgets('can scroll to settings in landscape with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(892, 412);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDrawer(tester, textScale: 2);

    final settings = find.byIcon(Icons.settings_outlined);
    await tester.scrollUntilVisible(
      settings,
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(settings.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
