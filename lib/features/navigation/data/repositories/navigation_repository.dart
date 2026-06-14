import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/models/navigation_state.dart';

part 'navigation_repository.g.dart';

class NavigationRepository {
  final SharedPreferences _prefs;
  static const _prefsKey = 'navigation_state_json';

  NavigationRepository(this._prefs);

  NavigationState loadNavigationState() {
    final jsonStr = _prefs.getString(_prefsKey);
    if (jsonStr == null) return const NavigationState();
    try {
      return NavigationState.fromJson(json.decode(jsonStr));
    } catch (_) {
      return const NavigationState();
    }
  }

  Future<void> saveNavigationState(NavigationState state) async {
    await _prefs.setString(_prefsKey, json.encode(state.toJson()));
  }
}

@riverpod
Future<NavigationRepository> navigationRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return NavigationRepository(prefs);
}
