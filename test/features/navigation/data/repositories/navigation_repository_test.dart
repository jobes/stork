import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/navigation/data/repositories/navigation_repository.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';

void main() {
  group('NavigationRepository Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('loadNavigationState returns default state when no data exists', () {
      final repository = NavigationRepository(prefs);
      final state = repository.loadNavigationState();
      expect(state.points, isEmpty);
      expect(state.isActive, isFalse);
    });

    test('loadNavigationState parses valid JSON correctly', () {
      final repository = NavigationRepository(prefs);
      const originalState = NavigationState(
        points: [
          NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1'),
        ],
        isActive: true,
      );

      prefs.setString(
        'navigation_state_json',
        json.encode(originalState.toJson()),
      );

      final state = repository.loadNavigationState();
      expect(state.points, hasLength(1));
      expect(state.points.first.name, equals('Point 1'));
      expect(state.isActive, isTrue);
    });

    test('loadNavigationState returns default state on parsing exception', () {
      final repository = NavigationRepository(prefs);
      prefs.setString('navigation_state_json', 'invalid_json');

      final state = repository.loadNavigationState();
      expect(state.points, isEmpty);
      expect(state.isActive, isFalse);
    });

    test(
      'saveNavigationState successfully persists NavigationState to SharedPreferences',
      () async {
        final repository = NavigationRepository(prefs);
        const stateToSave = NavigationState(
          points: [
            NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1'),
          ],
          isActive: true,
        );

        await repository.saveNavigationState(stateToSave);

        final savedJson = prefs.getString('navigation_state_json');
        expect(savedJson, isNotNull);
        final savedState = NavigationState.fromJson(json.decode(savedJson!));
        expect(savedState.points, hasLength(1));
        expect(savedState.points.first.name, equals('Point 1'));
        expect(savedState.isActive, isTrue);
      },
    );

    test(
      'saveNavigationState throws StateError when SharedPreferences.setString returns false',
      () async {
        final failurePrefs = FailureSharedPreferences();
        final repository = NavigationRepository(failurePrefs);
        const stateToSave = NavigationState(
          points: [
            NavigationPoint(latitude: 48.0, longitude: 17.0, name: 'Point 1'),
          ],
          isActive: true,
        );

        await expectLater(
          repository.saveNavigationState(stateToSave),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}

class FailureSharedPreferences implements SharedPreferences {
  @override
  Future<bool> setString(String key, String value) async {
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
