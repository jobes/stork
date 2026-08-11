import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../domain/models/favorite_point.dart';

export '../../domain/models/favorite_point.dart';

part 'favorites_provider.g.dart';

/// Sealed class representing the result of a favourites save operation.
sealed class FavoriteSaveResult {
  const FavoriteSaveResult();
}

/// Represents a successful favourites save.
class FavoriteSaveSuccess extends FavoriteSaveResult {
  const FavoriteSaveSuccess();
}

/// Represents a failed favourites save.
class FavoriteSaveFailure extends FavoriteSaveResult {
  final Object error;
  final StackTrace stackTrace;

  const FavoriteSaveFailure(this.error, this.stackTrace);
}

@Riverpod(keepAlive: true)
class FavoritesNotifier extends _$FavoritesNotifier {
  @override
  Future<List<FavoritePoint>> build() async {
    final repository = await ref.watch(favoritesRepositoryProvider.future);
    return repository.loadFavorites();
  }

  /// Persists [favorites] and returns the outcome instead of throwing.
  ///
  /// On failure the previous in-memory state is left untouched so callers can
  /// react (e.g. show a snack bar) without losing the saved list.
  Future<FavoriteSaveResult> _save(List<FavoritePoint> favorites) async {
    try {
      final repository = await ref.read(favoritesRepositoryProvider.future);
      await repository.saveFavorites(favorites);
      return const FavoriteSaveSuccess();
    } catch (e, stackTrace) {
      return FavoriteSaveFailure(e, stackTrace);
    }
  }

  /// Serialises all mutations (add/update/remove) through a single queue so
  /// each operation reads the latest state only after the previous save has
  /// completed. Without this, two concurrent calls could read the same stale
  /// state and one favourite would be lost.
  Future<void> _mutationQueue = Future.value();

  Future<FavoriteSaveResult> _enqueue(
    Future<FavoriteSaveResult> Function() operation,
  ) {
    final result = _mutationQueue.then((_) => operation());
    _mutationQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<FavoriteSaveResult> addFavorite(FavoritePoint point) {
    return _enqueue(() async {
      final current = state.value ?? [];
      final updated = [...current, point];
      // Persist first so a failed write does not leave the in-memory list
      // (and the map) with a point that was never saved to disk.
      final result = await _save(updated);
      if (result is FavoriteSaveSuccess) {
        state = AsyncData(updated);
      }
      return result;
    });
  }

  Future<FavoriteSaveResult> updateFavorite(FavoritePoint point) {
    return _enqueue(() async {
      final current = state.value ?? [];
      final updated = current.map((f) => f.id == point.id ? point : f).toList();
      final result = await _save(updated);
      if (result is FavoriteSaveSuccess) {
        state = AsyncData(updated);
      }
      return result;
    });
  }

  Future<FavoriteSaveResult> removeFavorite(String id) {
    return _enqueue(() async {
      final current = state.value ?? [];
      final updated = current.where((f) => f.id != id).toList();
      final result = await _save(updated);
      if (result is FavoriteSaveSuccess) {
        state = AsyncData(updated);
      }
      return result;
    });
  }
}
