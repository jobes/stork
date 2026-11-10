import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../l10n/app_localizations.dart';

enum AppLanguage {
  system(null),
  english(Locale('en')),
  slovak(Locale('sk'));

  const AppLanguage(this.locale);

  final Locale? locale;

  Locale get resolvedLocale =>
      locale ??
      basicLocaleListResolution(
        PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      );
}

typedef DisplayPreferences = ({
  ThemeMode themeMode,
  AppLanguage language,
  bool saving,
});

final displayPreferencesProvider =
    AsyncNotifierProvider<DisplayPreferencesNotifier, DisplayPreferences>(
      DisplayPreferencesNotifier.new,
    );

class DisplayPreferencesNotifier extends AsyncNotifier<DisplayPreferences> {
  static const _themeKey = 'appThemeMode';
  static const _languageKey = 'appLanguage';

  @override
  Future<DisplayPreferences> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return (
      themeMode:
          ThemeMode.values.asNameMap()[prefs.get(_themeKey)] ??
          ThemeMode.system,
      language:
          AppLanguage.values.asNameMap()[prefs.get(_languageKey)] ??
          AppLanguage.system,
      saving: false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) => _save(
    _themeKey,
    mode.name,
    (current) => (themeMode: mode, language: current.language, saving: false),
  );

  Future<void> setLanguage(AppLanguage language) => _save(
    _languageKey,
    language.name,
    (current) =>
        (themeMode: current.themeMode, language: language, saving: false),
  );

  Future<void> _save(
    String key,
    String value,
    DisplayPreferences Function(DisplayPreferences) update,
  ) async {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData((
      themeMode: current.themeMode,
      language: current.language,
      saving: true,
    ));
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      if (!await prefs.setString(key, value)) {
        throw StateError('Failed to save display preferences.');
      }
      if (ref.mounted) state = AsyncData(update(current));
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }
}
