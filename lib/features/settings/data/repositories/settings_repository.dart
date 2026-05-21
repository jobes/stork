import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/app_settings.dart';

import '../../../../core/providers/shared_preferences_provider.dart';

part 'settings_repository.g.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _keyAppSettings = 'app_settings';
  static final _defaultSettingsJson = json.encode(const AppSettings().toJson());

  Future<void> _resetToDefaults() async {
    final success = await _prefs.setString(_keyAppSettings, _defaultSettingsJson);
    if (!success) {
      throw StateError('Failed to reset settings to defaults.');
    }
  }

  Future<AppSettings> getSettings() async {
    final jsonString = _prefs.getString(_keyAppSettings);
    if (jsonString != null) {
      try {
        return AppSettings.fromJson(json.decode(jsonString));
      } on FormatException catch (e) {
        debugPrint('SettingsRepository: Failed to parse settings JSON: $e');
        try {
          await _resetToDefaults();
        } catch (resetError) {
          debugPrint('SettingsRepository: Failed to reset settings to defaults: $resetError');
        }
      } on TypeError catch (e) {
        debugPrint('SettingsRepository: Settings JSON shape mismatch: $e');
        try {
          await _resetToDefaults();
        } catch (resetError) {
          debugPrint('SettingsRepository: Failed to reset settings to defaults: $resetError');
        }
      }
    }

    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final success = await _prefs.setString(_keyAppSettings, json.encode(settings.toJson()));
    if (!success) {
      throw StateError('Failed to save settings to SharedPreferences.');
    }
  }
}

@riverpod
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs);
}
