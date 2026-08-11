import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/favorites/data/repositories/favorites_repository.dart';
import 'package:stork/features/favorites/domain/models/favorite_point.dart';
import 'package:stork/features/map/domain/models/poi_type.dart';

void main() {
  group('FavoritesRepository Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('loadFavorites returns empty list when no data exists', () {
      final repository = FavoritesRepository(prefs);
      expect(repository.loadFavorites(), isEmpty);
    });

    test('loadFavorites parses valid JSON correctly', () {
      final repository = FavoritesRepository(prefs);
      const favorite = FavoritePoint(
        id: 'f1',
        latitude: 48.0,
        longitude: 17.0,
        icon: PoiType.viewpoint,
        name: 'Viewpoint',
        description: 'Nice **view**',
      );

      prefs.setString('favorite_points', json.encode([favorite.toJson()]));

      final favorites = repository.loadFavorites();
      expect(favorites, hasLength(1));
      expect(favorites.first.name, equals('Viewpoint'));
      expect(favorites.first.icon, equals(PoiType.viewpoint));
      expect(favorites.first.description, equals('Nice **view**'));
      expect(favorites.first.latitude, equals(48.0));
    });

    test('loadFavorites keeps valid entries and skips malformed ones', () {
      final repository = FavoritesRepository(prefs);
      const valid = FavoritePoint(
        id: 'f1',
        latitude: 48.0,
        longitude: 17.0,
        icon: PoiType.viewpoint,
        name: 'Viewpoint',
      );
      // Missing required fields (latitude, icon, name) so fromJson throws.
      final malformed = <String, dynamic>{'id': 'bad'};

      prefs.setString(
        'favorite_points',
        json.encode([valid.toJson(), malformed]),
      );

      final favorites = repository.loadFavorites();
      expect(favorites, hasLength(1));
      expect(favorites.first.id, equals('f1'));
      expect(favorites.first.name, equals('Viewpoint'));
    });

    test('loadFavorites returns empty list on parsing exception', () {
      final repository = FavoritesRepository(prefs);
      prefs.setString('favorite_points', 'invalid_json');
      expect(repository.loadFavorites(), isEmpty);
    });

    test(
      'loadFavorites returns empty list when stored value is not a list',
      () {
        final repository = FavoritesRepository(prefs);
        prefs.setString('favorite_points', '{"foo": 1}');
        expect(repository.loadFavorites(), isEmpty);
      },
    );

    test('saveFavorites persists favourites to SharedPreferences', () async {
      final repository = FavoritesRepository(prefs);
      const favorite = FavoritePoint(
        id: 'f1',
        latitude: 48.0,
        longitude: 17.0,
        icon: PoiType.airfield,
        name: 'Home field',
        description: 'My *local* airfield',
      );

      await repository.saveFavorites([favorite]);

      final savedJson = prefs.getString('favorite_points');
      expect(savedJson, isNotNull);
      final decoded = json.decode(savedJson!) as List;
      final saved = FavoritePoint.fromJson(
        decoded.first as Map<String, dynamic>,
      );
      expect(saved.id, equals('f1'));
      expect(saved.name, equals('Home field'));
      expect(saved.icon, equals(PoiType.airfield));
      expect(saved.description, equals('My *local* airfield'));
    });

    test(
      'saveFavorites throws StateError when SharedPreferences.setString returns false',
      () async {
        final failurePrefs = FailureSharedPreferences();
        final repository = FavoritesRepository(failurePrefs);
        const favorite = FavoritePoint(
          id: 'f1',
          latitude: 48.0,
          longitude: 17.0,
          icon: PoiType.home,
          name: 'Home',
        );

        await expectLater(
          repository.saveFavorites([favorite]),
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
