import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/l10n/app_localizations.dart';
import 'package:stork/features/navigation/presentation/pages/navigation_page.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationPage Widget Tests', () {
    late ProviderContainer providerContainer;

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            providerContainer = ProviderScope.containerOf(context);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
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
      await tester.pumpAndSettle();

      expect(
        find.text('Navigation requires current location.'),
        findsOneWidget,
      );
    });

    testWidgets('uses settings expected flight speed when not flying', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

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

      // 3. Verify page does not show location warning, but shows expected flight speed label
      expect(
        find.textContaining('Expected flight speed: 100 kph'),
        findsOneWidget,
      );
    });

    testWidgets(
      'uses GPS ground speed and shows Ground Speed label when flying',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

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

    testWidgets('reordering items downwards adjusts indices correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

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

      // Drag index 0 to 2 (downwards). It should adjust to (0, 1).
      reorderableListView.onReorderItem!(0, 2);
      await tester.pumpAndSettle();

      // 4. Verify points are reordered: Waypoint 1 (index 0 originally) should now be at index 1
      final state = providerContainer.read(navigationProvider).value;
      expect(state?.points[0].name, 'Waypoint 2');
      expect(state?.points[1].name, 'Waypoint 1');
    });
  });
}
