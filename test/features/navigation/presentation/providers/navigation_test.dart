import 'dart:async';
import 'package:stork/features/navigation/data/repositories/navigation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';
import '../../../../helpers/sensors_mock.dart';

class _ControlledRepository extends NavigationRepository {
  _ControlledRepository(super.prefs, this.initial);
  final NavigationState initial;
  final started = Completer<void>();
  final removal = Completer<void>();
  var saves = 0;

  @override
  NavigationState loadNavigationState() => initial;

  @override
  Future<void> saveNavigationState(NavigationState state) {
    if (++saves == 1) {
      started.complete();
      return removal.future;
    }
    return Future.value();
  }
}

void main() {
  group('NavigationNotifier Tests', () {
    late ProviderContainer container;

    setUp(() async {
      mockSensorsPlus();
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          // Override sharedPreferencesProvider to return mocked instance
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
        ],
      );
      await container.read(navigationProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty and inactive', () async {
      final state = await container.read(navigationProvider.future);
      expect(state.points, isEmpty);
      expect(state.isActive, isFalse);
    });

    test('addPoint adds points and auto-activates on first point', () async {
      final notifier = container.read(navigationProvider.notifier);

      const point1 = NavigationPoint(
        latitude: 48.0,
        longitude: 17.0,
        name: 'Point 1',
      );
      await notifier.addPoint(point1);

      final stateAfterAdd = await container.read(navigationProvider.future);
      expect(stateAfterAdd.points, hasLength(1));
      expect(stateAfterAdd.points.first.name, 'Point 1');
      expect(stateAfterAdd.isActive, isTrue); // Auto-activated on first point

      const point2 = NavigationPoint(
        latitude: 49.0,
        longitude: 18.0,
        name: 'Point 2',
      );
      await notifier.addPoint(point2);

      final stateAfterSecondAdd = await container.read(
        navigationProvider.future,
      );
      expect(stateAfterSecondAdd.points, hasLength(2));
      expect(stateAfterSecondAdd.isActive, isTrue); // Remains active
    });

    test('removePoint removes a point and deactivates if empty', () async {
      final notifier = container.read(navigationProvider.notifier);

      const point1 = NavigationPoint(
        latitude: 48.0,
        longitude: 17.0,
        name: 'Point 1',
      );
      const point2 = NavigationPoint(
        latitude: 49.0,
        longitude: 18.0,
        name: 'Point 2',
      );

      await notifier.addPoint(point1);
      await notifier.addPoint(point2);

      final departure = DateTime.utc(2026, 11, 19, 12);
      container.read(flightDepartureProvider.notifier).select(departure);
      await notifier.removePoint(0);

      final state = await container.read(navigationProvider.future);
      expect(state.points, hasLength(1));
      expect(state.points.first.name, 'Point 2');
      expect(state.isActive, isTrue);
      expect(container.read(flightDepartureProvider), departure);

      await notifier.removePoint(0);

      final stateEmpty = await container.read(navigationProvider.future);
      expect(container.read(flightDepartureProvider), isNull);
      expect(stateEmpty.points, isEmpty);
      expect(stateEmpty.isActive, isFalse); // Deactivates when empty
    });

    test(
      'removePoints removes multiple points and deactivates if empty',
      () async {
        final notifier = container.read(navigationProvider.notifier);

        const point1 = NavigationPoint(
          latitude: 48.0,
          longitude: 17.0,
          name: 'Point 1',
        );
        const point2 = NavigationPoint(
          latitude: 49.0,
          longitude: 18.0,
          name: 'Point 2',
        );
        const point3 = NavigationPoint(
          latitude: 50.0,
          longitude: 19.0,
          name: 'Point 3',
        );

        await notifier.addPoint(point1);
        await notifier.addPoint(point2);
        await notifier.addPoint(point3);

        await notifier.removePoints(2);

        final state = await container.read(navigationProvider.future);
        expect(state.points, hasLength(1));
        expect(state.points.first.name, 'Point 3');
        expect(state.isActive, isTrue);

        await notifier.removePoints(1);

        final stateEmpty = await container.read(navigationProvider.future);
        expect(stateEmpty.points, isEmpty);
        expect(stateEmpty.isActive, isFalse);
      },
    );

    for (final concurrentEdit in ['none', 'route', 'departure']) {
      test(
        'failed removal rolls back without overwriting a newer edit ($concurrentEdit)',
        () async {
          const initial = NavigationState(
            points: [
              NavigationPoint(latitude: 48, longitude: 17, name: 'First'),
            ],
            isActive: true,
            wasAutoAdvanced: true,
          );
          final repository = _ControlledRepository(
            await SharedPreferences.getInstance(),
            initial,
          );
          final isolated = ProviderContainer(
            overrides: [
              navigationAutoAdvanceProvider.overrideWith((ref) {}),
              navigationRepositoryProvider.overrideWith(
                (ref) async => repository,
              ),
            ],
          );
          addTearDown(isolated.dispose);
          await isolated.read(navigationProvider.future);
          final notifier = isolated.read(navigationProvider.notifier);
          final departure = DateTime.utc(2026, 11, 19, 12);
          final laterDeparture = departure.add(const Duration(hours: 1));
          isolated.read(flightDepartureProvider.notifier).select(departure);
          final removal = notifier.removePoint(0);
          final failure = expectLater(removal, throwsStateError);
          await repository.started.future;
          expect(isolated.read(navigationProvider).value!.points, isEmpty);
          expect(isolated.read(navigationProvider).value!.isActive, isFalse);
          expect(isolated.read(flightDepartureProvider), isNull);
          if (concurrentEdit == 'route') {
            await notifier.addPoint(
              const NavigationPoint(latitude: 49, longitude: 18, name: 'New'),
            );
          }
          if (concurrentEdit != 'none') {
            isolated
                .read(flightDepartureProvider.notifier)
                .select(laterDeparture);
          }
          repository.removal.completeError(StateError('Save failed'));
          await failure;
          await isolated.pump();
          final state = isolated.read(navigationProvider).value!;
          if (concurrentEdit == 'route') {
            expect(state.points.single.name, 'New');
          } else {
            expect(state, same(initial));
            expect(state.isActive, isTrue);
            expect(state.wasAutoAdvanced, isTrue);
          }
          expect(
            isolated.read(flightDepartureProvider),
            concurrentEdit == 'none' ? departure : laterDeparture,
          );
        },
      );
    }

    test('reorderPoints moves points correctly', () async {
      final notifier = container.read(navigationProvider.notifier);

      const point1 = NavigationPoint(
        latitude: 48.0,
        longitude: 17.0,
        name: 'Point 1',
      );
      const point2 = NavigationPoint(
        latitude: 49.0,
        longitude: 18.0,
        name: 'Point 2',
      );
      const point3 = NavigationPoint(
        latitude: 50.0,
        longitude: 19.0,
        name: 'Point 3',
      );

      await notifier.addPoint(point1);
      await notifier.addPoint(point2);
      await notifier.addPoint(point3);

      // Reorder: Move Point 1 (index 0) to after Point 2 (newIndex 1 under onReorderItem semantics)
      await notifier.reorderPoints(0, 1);

      var state = await container.read(navigationProvider.future);
      expect(state.points[0].name, 'Point 2');
      expect(state.points[1].name, 'Point 1');
      expect(state.points[2].name, 'Point 3');

      // Reorder: Move Point 2 (index 0) to the very end (newIndex 2 under onReorderItem semantics)
      await notifier.reorderPoints(0, 2);
      state = await container.read(navigationProvider.future);
      expect(state.points[0].name, 'Point 1');
      expect(state.points[1].name, 'Point 3');
      expect(state.points[2].name, 'Point 2');
    });

    test('clearNavigation removes all points and deactivates', () async {
      final notifier = container.read(navigationProvider.notifier);

      const point1 = NavigationPoint(
        latitude: 48.0,
        longitude: 17.0,
        name: 'Point 1',
      );
      await notifier.addPoint(point1);

      await notifier.clearNavigation();

      final state = await container.read(navigationProvider.future);
      expect(state.points, isEmpty);
      expect(state.isActive, isFalse);
    });

    test('toggleActive toggles isActive flag', () async {
      final notifier = container.read(navigationProvider.notifier);

      const point1 = NavigationPoint(
        latitude: 48.0,
        longitude: 17.0,
        name: 'Point 1',
      );
      await notifier.addPoint(point1);

      final state1 = await container.read(navigationProvider.future);
      expect(state1.isActive, isTrue); // first point triggers active

      await notifier.toggleActive();
      final state2 = await container.read(navigationProvider.future);
      expect(state2.isActive, isFalse);

      await notifier.toggleActive();
      final state3 = await container.read(navigationProvider.future);
      expect(state3.isActive, isTrue);
    });

    test('NavigationPoint supports isAirport and serializes correctly', () {
      const genericPt = NavigationPoint(
        latitude: 48.0,
        longitude: 17.0,
        name: 'Generic Point',
      );
      expect(genericPt.isAirport, isFalse);

      const airportPt = NavigationPoint(
        latitude: 48.0,
        longitude: 17.0,
        name: 'Airport Point',
        isAirport: true,
      );
      expect(airportPt.isAirport, isTrue);

      final jsonGeneric = genericPt.toJson();
      expect(jsonGeneric['isAirport'], isFalse);

      final jsonAirport = airportPt.toJson();
      expect(jsonAirport['isAirport'], isTrue);

      final fromJsonGeneric = NavigationPoint.fromJson(jsonGeneric);
      expect(fromJsonGeneric.isAirport, isFalse);

      final fromJsonAirport = NavigationPoint.fromJson(jsonAirport);
      expect(fromJsonAirport.isAirport, isTrue);

      // Verify that old JSON without 'isAirport' key defaults to false
      final legacyJson = {
        'latitude': 48.0,
        'longitude': 17.0,
        'name': 'Legacy Point',
      };
      final fromLegacyJson = NavigationPoint.fromJson(legacyJson);
      expect(fromLegacyJson.isAirport, isFalse);
    });

    test(
      'NavigationPoint.fromJson throws FormatException on invalid/missing fields',
      () {
        expect(
          () => NavigationPoint.fromJson({}),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => NavigationPoint.fromJson({'latitude': 48.0, 'longitude': 17.0}),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => NavigationPoint.fromJson({
            'latitude': 'invalid',
            'longitude': 17.0,
            'name': 'Point',
          }),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'NavigationState.fromJson parses correctly and throws FormatException on invalid types',
      () {
        final validJson = {
          'points': [
            {'latitude': 48.0, 'longitude': 17.0, 'name': 'Point 1'},
          ],
          'isActive': true,
        };
        final state = NavigationState.fromJson(validJson);
        expect(state.points, hasLength(1));
        expect(state.isActive, isTrue);

        final invalidPointsJson = {'points': 'not_a_list'};
        expect(
          () => NavigationState.fromJson(invalidPointsJson),
          throwsA(isA<FormatException>()),
        );

        final invalidItemJson = {
          'points': ['not_a_map'],
        };
        expect(
          () => NavigationState.fromJson(invalidItemJson),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
