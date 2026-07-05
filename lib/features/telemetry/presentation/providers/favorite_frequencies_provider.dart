import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/models/favorite_frequency.dart';

part 'favorite_frequencies_provider.g.dart';

@Riverpod(keepAlive: true)
class FavoriteFrequencies extends _$FavoriteFrequencies {
  static const _key = 'favorite_frequencies';

  @override
  FutureOr<List<FavoriteFrequency>> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final listJson = prefs.getStringList(_key);
    if (listJson == null) {
      final defaults = [
        FavoriteFrequency(mhz: 121.500, name: 'Emergency (Guard)'),
      ];
      await prefs.setStringList(
        _key,
        defaults.map((f) => json.encode(f.toJson())).toList(),
      );
      return defaults;
    }

    return listJson
        .map((s) {
          try {
            return FavoriteFrequency.fromJson(json.decode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<FavoriteFrequency>()
        .toList();
  }

  Future<void> addFavorite(double mhz, String name) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.value ?? [];
    final updated = [...current, FavoriteFrequency(mhz: mhz, name: name)];
    await prefs.setStringList(
      _key,
      updated.map((f) => json.encode(f.toJson())).toList(),
    );
    state = AsyncData(updated);
  }

  Future<void> removeFavorite(int index) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.value ?? [];
    if (index < 0 || index >= current.length) return;
    final updated = [...current]..removeAt(index);
    await prefs.setStringList(
      _key,
      updated.map((f) => json.encode(f.toJson())).toList(),
    );
    state = AsyncData(updated);
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.value ?? [];
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex > current.length) return;

    final updated = [...current];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    await prefs.setStringList(
      _key,
      updated.map((f) => json.encode(f.toJson())).toList(),
    );
    state = AsyncData(updated);
  }
}
