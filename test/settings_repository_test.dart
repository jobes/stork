import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/features/settings/domain/app_settings.dart';

void main() {
  group('SettingsRepository getSettings exception handling', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Loads and parses a valid AppSettings JSON correctly', () async {
      final repository = SettingsRepository(prefs);
      const originalSettings = AppSettings(
        mapFontSize: 1.2,
        mapDefaultZoom: 8.0,
        autoSelectDevice: false,
      );
      
      prefs.setString('app_settings', json.encode(originalSettings.toJson()));
      
      final settings = await repository.getSettings();
      expect(settings.mapFontSize, equals(1.2));
      expect(settings.mapDefaultZoom, equals(8.0));
      expect(settings.autoSelectDevice, isFalse);
    });

    test('Falls back to default AppSettings and updates storage on FormatException (invalid JSON syntax)', () async {
      final repository = SettingsRepository(prefs);
      
      // Invalid JSON string (missing closing brace)
      prefs.setString('app_settings', '{"mapFontSize": 1.2');
      
      final settings = await repository.getSettings();
      
      // Should fall back to default
      expect(settings.mapFontSize, equals(1.0));
      expect(settings.mapDefaultZoom, equals(6.0));

      // SharedPreferences should have been healed to hold the default AppSettings JSON
      final savedSettingsJson = prefs.getString('app_settings');
      expect(savedSettingsJson, isNotNull);
      final savedSettings = AppSettings.fromJson(json.decode(savedSettingsJson!));
      expect(savedSettings.mapFontSize, equals(1.0));
      expect(savedSettings.mapDefaultZoom, equals(6.0));
    });

    test('Falls back to default AppSettings and updates storage on TypeError (invalid type schema)', () async {
      final repository = SettingsRepository(prefs);
      
      // JSON contains double for boolean field (autoSelectDevice expected bool, gets 1.2)
      prefs.setString('app_settings', '{"autoSelectDevice": 1.2}');
      
      final settings = await repository.getSettings();
      
      // Should fall back to default
      expect(settings.autoSelectDevice, isTrue);
      expect(settings.mapFontSize, equals(1.0));

      // SharedPreferences should have been healed to hold the default AppSettings JSON
      final savedSettingsJson = prefs.getString('app_settings');
      expect(savedSettingsJson, isNotNull);
      final savedSettings = AppSettings.fromJson(json.decode(savedSettingsJson!));
      expect(savedSettings.autoSelectDevice, isTrue);
      expect(savedSettings.mapFontSize, equals(1.0));
    });

    test('getSettings recovery fails and falls back to default AppSettings', () async {
      final failurePrefs = FailureSharedPreferences();
      final repository = SettingsRepository(failurePrefs);
      
      // Seed with malformed data to force healing/recovery path
      failurePrefs.seedAppSettings('{"mapFontSize": 1.2');
      
      final settings = await repository.getSettings();
      expect(settings, equals(const AppSettings()));
    });

    test('saveSettings successfully persists AppSettings to SharedPreferences', () async {
      final repository = SettingsRepository(prefs);
      const settingsToSave = AppSettings(
        mapFontSize: 1.5,
        mapDefaultZoom: 10.0,
        autoSelectDevice: true,
      );

      await repository.saveSettings(settingsToSave);

      final savedSettingsJson = prefs.getString('app_settings');
      expect(savedSettingsJson, isNotNull);
      final savedSettings = AppSettings.fromJson(json.decode(savedSettingsJson!));
      expect(savedSettings.mapFontSize, equals(1.5));
      expect(savedSettings.mapDefaultZoom, equals(10.0));
      expect(savedSettings.autoSelectDevice, isTrue);
    });

    test('saveSettings throws StateError when SharedPreferences.setString returns false', () async {
      final failurePrefs = FailureSharedPreferences();
      final repository = SettingsRepository(failurePrefs);
      const settingsToSave = AppSettings(
        mapFontSize: 1.5,
        mapDefaultZoom: 10.0,
        autoSelectDevice: true,
      );

      expect(
        () => repository.saveSettings(settingsToSave),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class FailureSharedPreferences implements SharedPreferences {
  String? _value;

  void seedAppSettings(String value) {
    _value = value;
  }

  @override
  String? getString(String key) {
    if (key == 'app_settings') {
      return _value;
    }
    return null;
  }

  @override
  Future<bool> setString(String key, String value) async {
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
