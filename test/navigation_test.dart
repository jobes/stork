import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationNotifier Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          // Override sharedPreferencesProvider to return mocked instance
          sharedPreferencesProvider.overrideWith((ref) => SharedPreferences.getInstance()),
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
      
      const point1 = NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1');
      await notifier.addPoint(point1);

      final stateAfterAdd = await container.read(navigationProvider.future);
      expect(stateAfterAdd.points, hasLength(1));
      expect(stateAfterAdd.points.first.name, 'Point 1');
      expect(stateAfterAdd.isActive, isTrue); // Auto-activated on first point

      const point2 = NavigationPoint(latitude: 49.0, longitude: 18.0, name: 'Point 2');
      await notifier.addPoint(point2);

      final stateAfterSecondAdd = await container.read(navigationProvider.future);
      expect(stateAfterSecondAdd.points, hasLength(2));
      expect(stateAfterSecondAdd.isActive, isTrue); // Remains active
    });

    test('removePoint removes a point and deactivates if empty', () async {
      final notifier = container.read(navigationProvider.notifier);
      
      const point1 = NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1');
      const point2 = NavigationPoint(latitude: 49.0, longitude: 18.0, name: 'Point 2');
      
      await notifier.addPoint(point1);
      await notifier.addPoint(point2);

      await notifier.removePoint(0);

      final state = await container.read(navigationProvider.future);
      expect(state.points, hasLength(1));
      expect(state.points.first.name, 'Point 2');
      expect(state.isActive, isTrue);

      await notifier.removePoint(0);

      final stateEmpty = await container.read(navigationProvider.future);
      expect(stateEmpty.points, isEmpty);
      expect(stateEmpty.isActive, isFalse); // Deactivates when empty
    });

    test('removePoints removes multiple points and deactivates if empty', () async {
      final notifier = container.read(navigationProvider.notifier);

      const point1 = NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1');
      const point2 = NavigationPoint(latitude: 49.0, longitude: 18.0, name: 'Point 2');
      const point3 = NavigationPoint(latitude: 50.0, longitude: 19.0, name: 'Point 3');

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
    });

    test('NavigationCalculations computes legs and totals correctly', () {
      const points = [
        NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1'),
        NavigationPoint(latitude: 48.0, longitude: 18.0, name: 'Point 2'),
      ];

      // Test with null coordinates
      final emptyCalc = NavigationCalculations.calculate(
        points: points,
        currentLatitude: null,
        currentLongitude: null,
        activeSpeedMs: 10.0,
      );
      expect(emptyCalc.legs, isEmpty);
      expect(emptyCalc.totalDistanceMeters, 0.0);
      expect(emptyCalc.totalDuration, Duration.zero);

      // Test with valid coordinates
      final now = DateTime(2026, 6, 13, 12, 0, 0);
      final calc = NavigationCalculations.calculate(
        points: points,
        currentLatitude: 48.0,
        currentLongitude: 17.0,
        activeSpeedMs: 10.0,
        now: now,
      );

      expect(calc.legs, hasLength(2));
      expect(calc.legs[0].legDistanceMeters, closeTo(0.0, 1.0));
      expect(calc.legs[0].legDuration, Duration.zero);

      final expectedDist = points[0].distanceTo(points[1].latitude, points[1].longitude);
      expect(calc.legs[1].legDistanceMeters, closeTo(expectedDist, 1.0));
      expect(calc.legs[1].legDuration.inSeconds, equals((expectedDist / 10.0).round()));
      expect(calc.totalDistanceMeters, closeTo(expectedDist, 1.0));
      expect(calc.totalDuration.inSeconds, equals((expectedDist / 10.0).round()));
      expect(calc.legs[1].eta, now.add(calc.totalDuration));
    });

    test('reorderPoints moves points correctly', () async {
      final notifier = container.read(navigationProvider.notifier);
      
      const point1 = NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1');
      const point2 = NavigationPoint(latitude: 49.0, longitude: 18.0, name: 'Point 2');
      const point3 = NavigationPoint(latitude: 50.0, longitude: 19.0, name: 'Point 3');
      
      await notifier.addPoint(point1);
      await notifier.addPoint(point2);
      await notifier.addPoint(point3);

      // Reorder: Move Point 1 (index 0) to after Point 2 (newIndex 1)
      await notifier.reorderPoints(0, 1);

      final state = await container.read(navigationProvider.future);
      expect(state.points[0].name, 'Point 2');
      expect(state.points[1].name, 'Point 1');
      expect(state.points[2].name, 'Point 3');
    });

    test('clearNavigation removes all points and deactivates', () async {
      final notifier = container.read(navigationProvider.notifier);
      
      const point1 = NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1');
      await notifier.addPoint(point1);

      await notifier.clearNavigation();

      final state = await container.read(navigationProvider.future);
      expect(state.points, isEmpty);
      expect(state.isActive, isFalse);
    });

    test('toggleActive toggles isActive flag', () async {
      final notifier = container.read(navigationProvider.notifier);
      
      const point1 = NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1');
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
  });
}
