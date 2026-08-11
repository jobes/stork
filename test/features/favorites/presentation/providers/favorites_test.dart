import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:stork/features/map/domain/models/poi_type.dart';

void main() {
  group('FavoritesNotifier Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          // Override sharedPreferencesProvider to return mocked instance
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
        ],
      );
      await container.read(favoritesProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () async {
      final state = await container.read(favoritesProvider.future);
      expect(state, isEmpty);
    });

    test('addFavorite adds and persists a point', () async {
      final notifier = container.read(favoritesProvider.notifier);

      const point = FavoritePoint(
        id: 'f1',
        latitude: 48.0,
        longitude: 17.0,
        icon: PoiType.viewpoint,
        name: 'Lookout',
        description: 'Nice **view**',
      );
      await notifier.addFavorite(point);

      final state = await container.read(favoritesProvider.future);
      expect(state, hasLength(1));
      expect(state.first.name, 'Lookout');
      expect(state.first.icon, PoiType.viewpoint);

      // Data is persisted: a fresh container reloads the same point
      final container2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(container2.dispose);
      final reloaded = await container2.read(favoritesProvider.future);
      expect(reloaded, hasLength(1));
      expect(reloaded.first.id, 'f1');
      expect(reloaded.first.description, 'Nice **view**');
    });

    test('addFavorite preserves previously added points', () async {
      final notifier = container.read(favoritesProvider.notifier);
      const p1 = FavoritePoint(
        id: 'f1',
        latitude: 48.0,
        longitude: 17.0,
        icon: PoiType.home,
        name: 'A',
      );
      const p2 = FavoritePoint(
        id: 'f2',
        latitude: 49.0,
        longitude: 18.0,
        icon: PoiType.camping,
        name: 'B',
      );

      await notifier.addFavorite(p1);
      await notifier.addFavorite(p2);

      final state = await container.read(favoritesProvider.future);
      expect(state, hasLength(2));
      expect(state.map((f) => f.id), containsAll(['f1', 'f2']));
    });

    test('removeFavorite removes a point by id', () async {
      final notifier = container.read(favoritesProvider.notifier);
      const p1 = FavoritePoint(
        id: 'f1',
        latitude: 48.0,
        longitude: 17.0,
        icon: PoiType.home,
        name: 'A',
      );
      const p2 = FavoritePoint(
        id: 'f2',
        latitude: 49.0,
        longitude: 18.0,
        icon: PoiType.camping,
        name: 'B',
      );

      await notifier.addFavorite(p1);
      await notifier.addFavorite(p2);
      await notifier.removeFavorite('f1');

      final state = await container.read(favoritesProvider.future);
      expect(state, hasLength(1));
      expect(state.first.id, 'f2');

      // Removing a non-existent id is a no-op
      await notifier.removeFavorite('does-not-exist');
      final after = await container.read(favoritesProvider.future);
      expect(after, hasLength(1));
    });

    test('updateFavorite edits an existing point in place', () async {
      final notifier = container.read(favoritesProvider.notifier);
      const p1 = FavoritePoint(
        id: 'f1',
        latitude: 48.0,
        longitude: 17.0,
        icon: PoiType.home,
        name: 'A',
        description: 'Old description',
      );

      await notifier.addFavorite(p1);

      final updated = p1.copyWith(
        icon: PoiType.thermal,
        name: 'A (renamed)',
        description: 'New **description**',
      );
      await notifier.updateFavorite(updated);

      final state = await container.read(favoritesProvider.future);
      expect(state, hasLength(1));
      expect(state.first.name, 'A (renamed)');
      expect(state.first.icon, PoiType.thermal);
      expect(state.first.description, 'New **description**');
      expect(state.first.id, 'f1');

      // Updating an unknown id is a no-op
      const ghost = FavoritePoint(
        id: 'does-not-exist',
        latitude: 50.0,
        longitude: 20.0,
        icon: PoiType.fuel,
        name: 'Ghost',
      );
      await notifier.updateFavorite(ghost);
      final after = await container.read(favoritesProvider.future);
      expect(after, hasLength(1));
      expect(after.first.id, 'f1');
    });
  });
}
