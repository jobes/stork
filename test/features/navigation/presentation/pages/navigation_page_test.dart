import 'package:stork/features/navigation/data/repositories/navigation_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/l10n/localizations.dart';
import 'package:stork/features/navigation/presentation/pages/navigation_page.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/navigation/presentation/widgets/route_waypoint_tile.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';

class _FailingRepository extends NavigationRepository {
  _FailingRepository(super.prefs);
  bool failSaves = false;

  @override
  Future<void> saveNavigationState(state) async {
    if (failSaves) throw StateError('Save failed');
    await super.saveNavigationState(state);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationPage Widget Tests', () {
    late ProviderContainer providerContainer;

    Widget buildTestWidget({NavigationRepository? repository, Locale? locale}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
          flightForecastProfilesProvider.overrideWith((ref) async => null),
          if (repository != null)
            navigationRepositoryProvider.overrideWith(
              (ref) async => repository,
            ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            providerContainer = ProviderScope.containerOf(context);
            return MaterialApp(
              locale: locale,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const NavigationPage(),
            );
          },
        ),
      );
    }

    testWidgets('shows warning when current location is unknown', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Waiting for GPS fix…'), findsOneWidget);
    });

    testWidgets('shows actionable steps when the route is empty', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();

      expect(find.text('No route yet'), findsOneWidget);
      expect(find.text('Tap an airport, town or favourite.'), findsOneWidget);
      expect(find.text('Add from favourites'), findsOneWidget);
    });

    testWidgets('shows the planned altitude and ETA on a waypoint row', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();

      await providerContainer
          .read(navigationProvider.notifier)
          .addPoint(
            const NavigationPoint(
              latitude: 49.0,
              longitude: 18.0,
              name: 'Waypoint 1',
              weatherAltitudeFeet: 2500,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.textContaining('2,500 ft'), findsOneWidget);
      expect(find.textContaining('ETA'), findsWidgets);
      expect(find.text('DEST'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RouteWaypointTile),
          matching: find.byType(ReorderableDelayedDragStartListener),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps waypoint menus aligned for different name lengths', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();

      final navNotifier = providerContainer.read(navigationProvider.notifier);
      await navNotifier.addPoint(
        const NavigationPoint(latitude: 49.0, longitude: 18.0, name: 'A'),
      );
      await navNotifier.addPoint(
        const NavigationPoint(
          latitude: 50.0,
          longitude: 19.0,
          name: 'Very long airport name',
        ),
      );
      await tester.pumpAndSettle();

      final tiles = find.byType(RouteWaypointTile);
      expect(tiles, findsNWidgets(2));
      final firstMenu = find.descendant(
        of: tiles.at(0),
        matching: find.byIcon(Icons.more_vert),
      );
      final secondMenu = find.descendant(
        of: tiles.at(1),
        matching: find.byIcon(Icons.more_vert),
      );
      expect(
        tester.getCenter(firstMenu).dx,
        moreOrLessEquals(tester.getCenter(secondMenu).dx),
      );
    });

    testWidgets('uses the aircraft cruise speed when not flying', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 1. Setup telemetry coordinates so location is known but not flying
      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();

      // 2. Add navigation points
      final navNotifier = providerContainer.read(navigationProvider.notifier);
      await navNotifier.addPoint(
        const NavigationPoint(
          latitude: 49.0,
          longitude: 18.0,
          name: 'Waypoint 1',
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify page does not show location warning, but shows the cruise speed label
      expect(find.textContaining('Cruising speed: 100 kph'), findsOneWidget);
    });

    testWidgets(
      'uses GPS ground speed and shows Ground Speed label when flying',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // 1. Setup telemetry coordinates and ground speed that triggers flying (e.g. 50 m/s = 180 km/h)
        providerContainer
            .read(telemetryProvider.notifier)
            .updateGPS(
              latitude: 48.0,
              longitude: 17.0,
              groundSpeed:
                  50.0, // 50.0 m/s is > threshold (2.77 m/s) -> isFlying = true
            );
        await tester.pumpAndSettle();

        // 2. Add navigation points
        final navNotifier = providerContainer.read(navigationProvider.notifier);
        await navNotifier.addPoint(
          const NavigationPoint(
            latitude: 49.0,
            longitude: 18.0,
            name: 'Waypoint 1',
          ),
        );
        await tester.pumpAndSettle();

        // 3. Verify ground speed is used: 50 m/s = 180 km/h
        expect(find.textContaining('Ground speed: 180 kph'), findsOneWidget);
      },
    );

    testWidgets('departure dialog applies a quick preset', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();
      await providerContainer
          .read(navigationProvider.notifier)
          .addPoint(
            const NavigationPoint(
              latitude: 49.0,
              longitude: 18.0,
              name: 'Waypoint 1',
            ),
          );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Planned departure'));
      await tester.pumpAndSettle();
      expect(find.text('Departure time'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TextField)).width,
        greaterThanOrEqualTo(140),
      );

      await tester.tap(find.text('+30 min'));
      await tester.pump();
      await tester.ensureVisible(find.text('Set departure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set departure'));
      await tester.pumpAndSettle();

      expect(providerContainer.read(flightDepartureProvider), isNotNull);
    });

    testWidgets('opens the altitude editor from the waypoint chip', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();
      await providerContainer
          .read(navigationProvider.notifier)
          .addPoint(
            const NavigationPoint(
              latitude: 49.0,
              longitude: 18.0,
              name: 'Waypoint 1',
              weatherAltitudeFeet: 2500,
            ),
          );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('2,500 ft'));
      await tester.pumpAndSettle();

      expect(find.text('Forecast altitude'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('long press on a waypoint starts reordering', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();

      final navNotifier = providerContainer.read(navigationProvider.notifier);
      await navNotifier.addPoint(
        const NavigationPoint(
          latitude: 49.0,
          longitude: 18.0,
          name: 'Waypoint 1',
        ),
      );
      await navNotifier.addPoint(
        const NavigationPoint(
          latitude: 50.0,
          longitude: 19.0,
          name: 'Waypoint 2',
        ),
      );
      await tester.pumpAndSettle();

      final firstTile = find.byType(RouteWaypointTile).first;
      final gesture = await tester.startGesture(tester.getCenter(firstTile));
      await tester.pump(const Duration(milliseconds: 700));
      for (var step = 0; step < 10; step++) {
        await gesture.moveBy(const Offset(0, 22));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      final state = providerContainer.read(navigationProvider).value;
      expect(state?.points.first.name, 'Waypoint 2');
    });

    for (final language in ['en', 'sk']) {
      testWidgets(
        'failed removal shows a localized error without Undo ($language)',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final repository = _FailingRepository(
            await SharedPreferences.getInstance(),
          );
          await tester.pumpWidget(
            buildTestWidget(repository: repository, locale: Locale(language)),
          );
          await tester.pump();
          providerContainer
              .read(telemetryProvider.notifier)
              .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
          await tester.pumpAndSettle();
          await providerContainer
              .read(navigationProvider.notifier)
              .addPoint(
                const NavigationPoint(
                  latitude: 49,
                  longitude: 18,
                  name: 'Waypoint 1',
                ),
              );
          await tester.pumpAndSettle();
          final previous = providerContainer.read(navigationProvider).value;
          final l10n = AppLocalizations.of(
            tester.element(find.byType(RouteWaypointTile)),
          )!;
          repository.failSaves = true;
          await tester.tap(
            find.descendant(
              of: find.byType(RouteWaypointTile),
              matching: find.byIcon(Icons.more_vert),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.navigationRemoveWaypoint));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text(l10n.navigationWaypointRemovalFailed),
            findsOneWidget,
          );
          expect(find.text(l10n.undo), findsNothing);
          expect(
            providerContainer.read(navigationProvider).value,
            same(previous),
          );
        },
      );
    }

    testWidgets('clears the planned departure when the route becomes empty', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();
      await providerContainer
          .read(navigationProvider.notifier)
          .addPoint(
            const NavigationPoint(
              latitude: 49.0,
              longitude: 18.0,
              name: 'Waypoint 1',
            ),
          );
      await tester.pumpAndSettle();

      final departure = DateTime.now().add(const Duration(hours: 1));
      providerContainer
          .read(flightDepartureProvider.notifier)
          .select(departure);
      await tester.pump();
      final stored = providerContainer.read(flightDepartureProvider);
      expect(stored, departure.toUtc());
      expect(stored!.isUtc, isTrue);

      await providerContainer.read(navigationProvider.notifier).removePoint(0);
      await tester.pumpAndSettle();

      expect(providerContainer.read(flightDepartureProvider), isNull);
    });

    testWidgets('undo restores the planned departure', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();
      await providerContainer
          .read(navigationProvider.notifier)
          .addPoint(
            const NavigationPoint(
              latitude: 49.0,
              longitude: 18.0,
              name: 'Waypoint 1',
            ),
          );
      await tester.pumpAndSettle();

      final departure = DateTime.now().add(const Duration(hours: 1)).toUtc();
      providerContainer
          .read(flightDepartureProvider.notifier)
          .select(departure);
      await tester.pump();

      final menu = find.descendant(
        of: find.byType(RouteWaypointTile),
        matching: find.byIcon(Icons.more_vert),
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove point'));
      await tester.pumpAndSettle();
      expect(providerContainer.read(flightDepartureProvider), isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      expect(providerContainer.read(flightDepartureProvider), departure);
    });

    testWidgets('reordering items downwards adjusts indices correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 1. Setup telemetry coordinates so location is known
      providerContainer
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);
      await tester.pumpAndSettle();

      // 2. Add navigation points
      final navNotifier = providerContainer.read(navigationProvider.notifier);
      await navNotifier.addPoint(
        const NavigationPoint(
          latitude: 49.0,
          longitude: 18.0,
          name: 'Waypoint 1',
        ),
      );
      await navNotifier.addPoint(
        const NavigationPoint(
          latitude: 50.0,
          longitude: 19.0,
          name: 'Waypoint 2',
        ),
      );
      await tester.pumpAndSettle();

      // 3. Find ReorderableListView and trigger onReorderItem
      final listViewFinder = find.byType(ReorderableListView);
      expect(listViewFinder, findsOneWidget);
      final reorderableListView = tester.widget<ReorderableListView>(
        listViewFinder,
      );

      // Drag index 0 to 1 (downwards). onReorderItem already adjusts indexes.
      reorderableListView.onReorderItem!(0, 1);
      await tester.pumpAndSettle();

      // 4. Verify points are reordered: Waypoint 1 (index 0 originally) should now be at index 1
      final state = providerContainer.read(navigationProvider).value;
      expect(state?.points[0].name, 'Waypoint 2');
      expect(state?.points[1].name, 'Waypoint 1');
    });
  });
}
