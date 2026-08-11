import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/models/favorite_point.dart';

part 'favorites_repository.g.dart';

/// Persists the list of user favourite points to SharedPreferences.
class FavoritesRepository {
  final SharedPreferences _prefs;
  static const _prefsKey = 'favorite_points';

  FavoritesRepository(this._prefs);

  List<FavoritePoint> loadFavorites() {
    final jsonStr = _prefs.getString(_prefsKey);
    if (jsonStr == null) return [];
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FavoritePoint.fromJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to load favorites from SharedPreferences: $e');
      return [];
    }
  }

  Future<void> saveFavorites(List<FavoritePoint> favorites) async {
    final success = await _prefs.setString(
      _prefsKey,
      json.encode(favorites.map((f) => f.toJson()).toList()),
    );
    if (!success) {
      throw StateError('Failed to save favorites to SharedPreferences.');
    }
  }
}

@riverpod
Future<FavoritesRepository> favoritesRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FavoritesRepository(prefs);
}
