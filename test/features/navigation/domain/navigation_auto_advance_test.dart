import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Auto-Advance Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
          appSettingsProvider.overrideWith(
            () => FakeAppSettingsNotifier(
              const AppSettings(averageSpeed: 10.0), // 10.0 m/s
            ),
          ),
        ],
      );
      // Wait for initialization
      await container.read(navigationProvider.future);
      await container.read(appSettingsProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'does not auto-advance when time to next point is > 60 seconds',
      () async {
        final notifier = container.read(navigationProvider.notifier);

        // Point 1 is at 48.01, 17.0 (~1110 meters away)
        const point1 = NavigationPoint(
          latitude: 48.01,
          longitude: 17.0,
          name: 'Point 1',
        );
        const point2 = NavigationPoint(
          latitude: 48.05,
          longitude: 17.0,
          name: 'Point 2',
        );
        await notifier.addPoint(point1);
        await notifier.addPoint(point2);

        // Current location at 48.0, 17.0.
        // Distance is ~1110m. Speed is 10 m/s.
        // Time is 111 seconds (> 60 seconds) -> should NOT auto-advance
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);

        // Wait a tick
        await Future.delayed(Duration.zero);

        final state = await container.read(navigationProvider.future);
        expect(state.points, hasLength(2));
        expect(state.points[0].name, 'Point 1');
      },
    );

    test(
      'auto-advances when time to next point is <= 60 seconds (using settings speed)',
      () async {
        final notifier = container.read(navigationProvider.notifier);

        // Point 1 is at 48.004, 17.0 (~444 meters away)
        const point1 = NavigationPoint(
          latitude: 48.004,
          longitude: 17.0,
          name: 'Point 1',
        );
        const point2 = NavigationPoint(
          latitude: 48.05,
          longitude: 17.0,
          name: 'Point 2',
        );
        await notifier.addPoint(point1);
        await notifier.addPoint(point2);

        // Distance is ~444m. Speed is 10 m/s.
        // Time is 44 seconds (<= 60 seconds) -> should auto-advance
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);

        // Wait for notifier updates to settle
        await Future.delayed(const Duration(milliseconds: 50));

        final state = await container.read(navigationProvider.future);
        expect(state.points, hasLength(1));
        expect(state.points[0].name, 'Point 2');
      },
    );

    test('auto-advances using ground speed when flying', () async {
      final notifier = container.read(navigationProvider.notifier);

      // Point 1 is at 48.02, 17.0 (~2220 meters away)
      const point1 = NavigationPoint(
        latitude: 48.02,
        longitude: 17.0,
        name: 'Point 1',
      );
      const point2 = NavigationPoint(
        latitude: 48.05,
        longitude: 17.0,
        name: 'Point 2',
      );
      await notifier.addPoint(point1);
      await notifier.addPoint(point2);

      // If we use settings speed (10 m/s), time is 222 seconds (> 60s -> no auto-advance).
      // But we are flying with ground speed 50 m/s (time is 44 seconds <= 60s -> auto-advance).
      container
          .read(telemetryProvider.notifier)
          .updateGPS(
            latitude: 48.0,
            longitude: 17.0,
            groundSpeed: 50.0, // > 2.77 threshold -> isFlying = true
          );

      await Future.delayed(const Duration(milliseconds: 50));

      final state = await container.read(navigationProvider.future);
      expect(state.points, hasLength(1));
      expect(state.points[0].name, 'Point 2');
    });

    test(
      'auto-advances multiple points at once when all are under 60 seconds threshold',
      () async {
        final notifier = container.read(navigationProvider.notifier);

        // Point 1 is at 48.002, 17.0 (~222m away)
        // Point 2 is at 48.004, 17.0 (~222m from Point 1, cumulative ~444m away)
        // Point 3 is at 48.050, 17.0 (~5.1km away, cumulative ~5.5km away)
        const point1 = NavigationPoint(
          latitude: 48.002,
          longitude: 17.0,
          name: 'Point 1',
        );
        const point2 = NavigationPoint(
          latitude: 48.004,
          longitude: 17.0,
          name: 'Point 2',
        );
        const point3 = NavigationPoint(
          latitude: 48.050,
          longitude: 17.0,
          name: 'Point 3',
        );

        await notifier.addPoint(point1);
        await notifier.addPoint(point2);
        await notifier.addPoint(point3);

        // Distance to point 1 is 222m. At 10m/s: time is 22s (<= 60s)
        // Distance to point 2 is cumulative 444m. At 10m/s: time is 44s (<= 60s)
        // Distance to point 3 is cumulative 5.5km. At 10m/s: time is 550s (> 60s)
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);

        await Future.delayed(const Duration(milliseconds: 50));

        final state = await container.read(navigationProvider.future);
        expect(state.points, hasLength(1));
        expect(state.points[0].name, 'Point 3');
      },
    );

    test('does not auto-advance if navigation is inactive', () async {
      final notifier = container.read(navigationProvider.notifier);

      const point1 = NavigationPoint(
        latitude: 48.004,
        longitude: 17.0,
        name: 'Point 1',
      );
      await notifier.addPoint(point1);

      // Deactivate navigation
      await notifier.toggleActive();
      final stateBefore = await container.read(navigationProvider.future);
      expect(stateBefore.isActive, isFalse);

      // Update GPS inside threshold
      container
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.0, longitude: 17.0, groundSpeed: 0.0);

      await Future.delayed(const Duration(milliseconds: 50));

      final stateAfter = await container.read(navigationProvider.future);
      expect(stateAfter.points, hasLength(1));
    });
  });
}

class FakeAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings initialSettings;
  FakeAppSettingsNotifier([this.initialSettings = const AppSettings()]);

  @override
  Future<AppSettings> build() async {
    return initialSettings;
  }
}
