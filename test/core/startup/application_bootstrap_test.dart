import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/startup/application_bootstrap.dart';
import 'package:stork/core/startup/application_runtime.dart';
import 'package:stork/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/display_preferences_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';

final _dependency = Provider<int>((_) => 0);

class _SlowSettings extends AppSettingsNotifier {
  _SlowSettings(this.pending);
  final Future<AppSettings> pending;
  int builds = 0;
  bool listenedAfterLoading = false;

  @override
  Future<AppSettings> build() async {
    builds++;
    final settings = await pending;
    // The real settings provider installs discovery listeners after loading.
    // This used to throw UnmountedRefException during the first startup.
    ref.listen(_dependency, (_, _) {});
    listenedAfterLoading = true;
    return settings;
  }
}

class _Preferences extends DisplayPreferencesNotifier {
  @override
  Future<DisplayPreferences> build() async => (
    themeMode: ThemeMode.system,
    language: AppLanguage.system,
    saving: false,
  );
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState();
}

class _Favorites extends FavoritesNotifier {
  _Favorites(this.pending);
  final Future<List<FavoritePoint>> pending;
  @override
  Future<List<FavoritePoint>> build() => pending;
}

void main() {
  test(
    'real bootstrap keeps asynchronous settings mounted before the map exists',
    () async {
      final settingsReady = Completer<AppSettings>();
      final favoritesReady = Completer<List<FavoritePoint>>();
      final settings = _SlowSettings(settingsReady.future);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          applicationRuntimeProvider.overrideWith((_) async => false),
          displayPreferencesProvider.overrideWith(_Preferences.new),
          appSettingsProvider.overrideWith(() => settings),
          navigationProvider.overrideWith(_Navigation.new),
          favoritesProvider.overrideWith(
            () => _Favorites(favoritesReady.future),
          ),
        ],
      );
      // Exercise the actual coordinator, not a replacement bootstrap future.
      final startup = container.listen(applicationBootstrapProvider, (_, _) {});
      await container.pump();
      settingsReady.complete(const AppSettings());
      await container.pump();
      expect(settings.builds, 1);
      expect(settings.listenedAfterLoading, isTrue);
      expect(
        container.read(appSettingsProvider).requireValue,
        const AppSettings(),
      );
      // Favourites deliberately remain pending, so no platform/map services run.
      expect(startup.read().isLoading, isTrue);
      container.dispose();
      favoritesReady.complete([]);
    },
  );
}
