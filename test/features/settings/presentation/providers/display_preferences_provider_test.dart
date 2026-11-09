import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/features/settings/presentation/providers/display_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to system and restores saved display preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer.test();
    final defaults = await first.read(displayPreferencesProvider.future);
    expect(defaults.themeMode, ThemeMode.system);
    expect(defaults.language.locale, isNull);

    final notifier = first.read(displayPreferencesProvider.notifier);
    await notifier.setThemeMode(ThemeMode.dark);
    await notifier.setLanguage(AppLanguage.slovak);

    final restarted = ProviderContainer.test();
    final saved = await restarted.read(displayPreferencesProvider.future);
    expect(saved.themeMode, ThemeMode.dark);
    expect(saved.language.locale, const Locale('sk'));

    final restartedNotifier = restarted.read(
      displayPreferencesProvider.notifier,
    );
    await restartedNotifier.setThemeMode(ThemeMode.system);
    await restartedNotifier.setLanguage(AppLanguage.system);
    final automatic = await ProviderContainer.test().read(
      displayPreferencesProvider.future,
    );
    expect(automatic.themeMode, ThemeMode.system);
    expect(automatic.language.locale, isNull);
  });
}
