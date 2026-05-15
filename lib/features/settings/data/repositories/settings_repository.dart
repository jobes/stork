import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/app_settings.dart';

import '../../../../core/providers/shared_preferences_provider.dart';


part 'settings_repository.g.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _keyAppSettings = 'app_settings';

  AppSettings getSettings() {
    final jsonString = _prefs.getString(_keyAppSettings);
    if (jsonString != null) {
      try {
        return AppSettings.fromJson(json.decode(jsonString));
      } catch (_) {
        // Fallback to defaults
      }
    }

    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_keyAppSettings, json.encode(settings.toJson()));
  }
}


@riverpod
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs);
}
