import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../domain/models/favorite_point.dart';

export '../../domain/models/favorite_point.dart';

part 'favorites_provider.g.dart';

@Riverpod(keepAlive: true)
class FavoritesNotifier extends _$FavoritesNotifier {
  @override
  Future<List<FavoritePoint>> build() async {
    final repository = await ref.watch(favoritesRepositoryProvider.future);
    return repository.loadFavorites();
  }

  Future<void> _save(List<FavoritePoint> favorites) async {
    final repository = await ref.read(favoritesRepositoryProvider.future);
    await repository.saveFavorites(favorites);
  }

  Future<void> addFavorite(FavoritePoint point) async {
    final current = state.value ?? [];
    final updated = [...current, point];
    // Persist first so a failed write does not leave the in-memory list
    // (and the map) with a point that was never saved to disk.
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> updateFavorite(FavoritePoint point) async {
    final current = state.value ?? [];
    final updated = current.map((f) => f.id == point.id ? point : f).toList();
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> removeFavorite(String id) async {
    final current = state.value ?? [];
    final updated = current.where((f) => f.id != id).toList();
    await _save(updated);
    state = AsyncData(updated);
  }
}
