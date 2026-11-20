import '../../support/prepared_map_style.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/core/services/style_provider.dart';
import 'package:stork/core/startup/initial_map_camera.dart';
import 'package:stork/core/startup/local_map_preparation.dart';
import 'package:stork/features/map/presentation/providers/airspace_activity_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/black_box_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
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

class _Telemetry extends TelemetryNotifier {
  _Telemetry(this.initialState);
  final TelemetryState initialState;

  @override
  TelemetryState build() => initialState;

  void receivePosition(double latitude, double longitude) {
    state = state.copyWith(
      latitude: TelemetryValue(latitude),
      longitude: TelemetryValue(longitude),
    );
  }
}

ProviderContainer _container({
  _SlowSettings? settings,
  Future<List<FavoritePoint>>? favorites,
  Future<void>? configuration,
  Future<SharedPreferences> Function()? preferences,
  Future<bool>? monitoring,
  Future<void> Function()? fir,
  Future<void>? assets,
  Future<void>? database,
  Future<Geographic?>? position,
  TelemetryState telemetry = const TelemetryState(),
  _Telemetry? liveTelemetry,
  void Function(String)? started,
}) => ProviderContainer(
  retry: (_, _) => null,
  overrides: [
    if (preferences != null)
      sharedPreferencesProvider.overrideWith((_) => preferences()),
    applicationConfigurationProvider.overrideWith((_) async {
      started?.call('configuration');
      await configuration;
    }),
    applicationRuntimeProvider.overrideWith((_) async {
      started?.call('monitoring');
      return await monitoring ?? false;
    }),
    startupFirIndexProvider.overrideWith((_) async {
      started?.call('fir');
      await fir?.call();
    }),
    startupMapAssetsProvider.overrideWith((ref) async {
      started?.call('assets');
      if (preferences != null) await ref.read(sharedPreferencesProvider.future);
      await assets;
    }),
    startupOfflineDatabaseProvider.overrideWith((_) async {
      started?.call('database');
      await database;
    }),
    startupLastKnownPositionProvider.overrideWith((_) async {
      started?.call('position');
      return await position;
    }),
    displayPreferencesProvider.overrideWith(_Preferences.new),
    appSettingsProvider.overrideWith(
      () => settings ?? _SlowSettings(Future.value(const AppSettings())),
    ),
    navigationProvider.overrideWith(_Navigation.new),
    favoritesProvider.overrideWith(
      () => _Favorites(favorites ?? Future.value([])),
    ),
    cannelloniServiceProvider.overrideWithValue(false),
    blackBoxServiceProvider.overrideWithValue(null),
    gpsListenerProvider.overrideWith((_) {}),
    telemetryProvider.overrideWith(
      () => liveTelemetry ?? _Telemetry(telemetry),
    ),
    airspaceActivityProvider.overrideWithValue({}),
    mapStyleProvider.overrideWith(
      (_) async => testPreparedStyle('{"version":8}'),
    ),
  ],
);

void main() {
  test(
    'retry recovers shared preferences before dependent local preparation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var attempts = 0;
      final container = _container(
        preferences: () async {
          if (++attempts == 1) throw StateError('Preferences unavailable');
          return preferences;
        },
      );
      addTearDown(container.dispose);
      container.listen(applicationBootstrapProvider, (_, _) {});
      await expectLater(
        container.read(applicationBootstrapProvider.future),
        throwsA(anything),
      );
      retryApplicationBootstrap(container);
      await container.read(applicationBootstrapProvider.future);
      expect(attempts, 2);
    },
  );

  test('real bootstrap keeps asynchronous settings mounted before the map exists', () async {
    final settingsReady = Completer<AppSettings>();
    final favoritesReady = Completer<List<FavoritePoint>>();
    final settings = _SlowSettings(settingsReady.future);
    final container = _container(
      settings: settings,
      favorites: favoritesReady.future,
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
  });
  test('configuration gates local preparation but slow monitoring never gates the map', () async {
    final configuration = Completer<void>();
    final monitoring = Completer<bool>();
    final fir = Completer<void>();
    final assets = Completer<void>();
    final database = Completer<void>();
    final settingsReady = Completer<AppSettings>();
    final started = <String>[];
    final container = _container(
      configuration: configuration.future,
      monitoring: monitoring.future,
      fir: () => fir.future,
      assets: assets.future,
      database: database.future,
      settings: _SlowSettings(settingsReady.future),
      started: started.add,
    );
    addTearDown(container.dispose);
    final startup = container.listen(applicationBootstrapProvider, (_, _) {});
    await container.pump();
    expect(started, ['configuration']);
    configuration.complete();
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    expect(started, containsAll(['fir', 'assets', 'database', 'position']));
    expect(startup.read().isLoading, isTrue);
    settingsReady.complete(const AppSettings());
    fir.complete();
    assets.complete();
    database.complete();
    await container.pump();
    await container.read(applicationBootstrapProvider.future);
    expect(startup.read().hasValue, isTrue);
    expect(started, isNot(contains('monitoring')));
    monitoring.complete(false);
  });

  test('valid telemetry does not wait for last-known position', () async {
    final position = Completer<Geographic?>();
    final container = _container(
      position: position.future,
      telemetry: const TelemetryState(latitude: 48.1, longitude: 17.2),
    );
    final startup = container.listen(applicationBootstrapProvider, (_, _) {});
    await container
        .read(applicationBootstrapProvider.future)
        .timeout(const Duration(seconds: 1));
    expect(startup.read().hasValue, isTrue);
    final camera = container.read(initialMapCameraProvider)!;
    expect(camera.center.lat, 48.1);
    expect(camera.center.lon, 17.2);
    container.dispose();
    position.complete(const Geographic(lat: 49, lon: 19));
  });

  test(
    'without telemetry the prepared camera waits only for last-known position',
    () async {
      final position = Completer<Geographic?>();
      final container = _container(position: position.future);
      addTearDown(container.dispose);
      final startup = container.listen(applicationBootstrapProvider, (_, _) {});
      await container.pump();
      expect(startup.read().isLoading, isTrue);
      position.complete(const Geographic(lat: 49, lon: 19));
      await container.read(applicationBootstrapProvider.future);
      final camera = container.read(initialMapCameraProvider)!;
      expect(camera.hasLocation, isTrue);
      expect(camera.center.lat, 49);
      expect(camera.center.lon, 19);
    },
  );

  test(
    'a live fix received during lookup wins over the older position',
    () async {
      final position = Completer<Geographic?>();
      final telemetry = _Telemetry(const TelemetryState());
      final container = _container(
        position: position.future,
        liveTelemetry: telemetry,
      );
      addTearDown(container.dispose);
      container.listen(applicationBootstrapProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      telemetry.receivePosition(48.1, 17.2);
      position.complete(const Geographic(lat: 49, lon: 19));
      await container.read(applicationBootstrapProvider.future);
      final camera = container.read(initialMapCameraProvider)!;
      expect(camera.center.lat, 48.1);
      expect(camera.center.lon, 17.2);
    },
  );

  test(
    'retry repeats a failed local dependency and keeps successful preparation',
    () async {
      var attempts = 0;
      var assetStarts = 0;
      final container = _container(
        fir: () async {
          if (++attempts == 1) throw StateError('FIR unavailable');
        },
        started: (name) {
          if (name == 'assets') assetStarts++;
        },
      );
      addTearDown(container.dispose);
      container.listen(applicationBootstrapProvider, (_, _) {});
      await expectLater(
        container.read(applicationBootstrapProvider.future),
        throwsA(anything),
      );
      retryApplicationBootstrap(container);
      await container.read(applicationBootstrapProvider.future);
      expect(attempts, 2);
      expect(assetStarts, 1);
    },
  );
}
