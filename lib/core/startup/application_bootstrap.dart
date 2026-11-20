import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cannelloni_service.dart';
import '../providers/shared_preferences_provider.dart';
import '../services/style_provider.dart';
import '../../features/favorites/presentation/providers/favorites_provider.dart';
import '../../features/map/presentation/providers/airspace_activity_provider.dart';
import '../../features/navigation/presentation/providers/navigation_provider.dart';
import '../../features/settings/presentation/providers/display_preferences_provider.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/telemetry/presentation/providers/black_box_provider.dart';
import '../../features/telemetry/presentation/providers/telemetry_provider.dart';
import 'initial_map_camera.dart';
import 'application_runtime.dart';
import 'local_map_preparation.dart';
import 'startup_timing.dart';

/// Holds the prepared style only until the first destination has mounted.
/// After handoff, ordinary page subscriptions own the map providers again.
class PreparedApplication {
  const PreparedApplication({this.releaseMapPreparation});
  final void Function()? releaseMapPreparation;
}

/// Read once by the app shell after its first frame. No native map is mounted
/// until this future completes, including preparation of its initial GeoJSON.
final applicationBootstrapProvider = FutureProvider<PreparedApplication>(
  (ref) => measureStartup('Bootstrap', () async {
    await ref.watch(applicationConfigurationProvider.future);
    if (!ref.mounted) return const PreparedApplication();

    // A read of an auto-disposed provider's future does not keep its async
    // build mounted. Hold settings through preparation and the first UI frame.
    final settingsLease = ref.listen(appSettingsProvider, (_, _) {});
    ref.onDispose(settingsLease.close);
    // Start the bounded location lookup before the other local work. It is only
    // awaited below if telemetry still has no valid position.
    final lastPosition = ref.read(startupLastKnownPositionProvider.future);
    await measureStartup(
      'Local preparation',
      () => Future.wait([
        ref.read(startupFirIndexProvider.future),
        ref.read(startupMapAssetsProvider.future),
        ref.read(startupOfflineDatabaseProvider.future),
        measureStartup('Settings and session services', () async {
          await Future.wait([
            ref.read(displayPreferencesProvider.future),
            ref.read(appSettingsProvider.future),
            ref.read(navigationProvider.future),
            ref.read(favoritesProvider.future),
          ]);
          if (!ref.mounted) return;
          // Session services must not wait for map preparation or monitoring.
          ref.read(cannelloniServiceProvider);
          ref.read(blackBoxServiceProvider);
          ref.read(gpsListenerProvider);
        }),
      ]),
    );
    if (!ref.mounted) return const PreparedApplication();

    final settings = ref.read(appSettingsProvider).requireValue;
    final telemetryCamera = InitialMapCamera.fromTelemetry(
      ref.read(telemetryProvider),
      settings,
    );
    final knownPosition = telemetryCamera.hasLocation
        ? null
        : await lastPosition;
    if (!ref.mounted) return const PreparedApplication();
    // Re-read telemetry after an asynchronous lookup: a live fix may have arrived.
    ref
        .read(initialMapCameraProvider.notifier)
        .prepare(
          InitialMapCamera.fromTelemetry(
            ref.read(telemetryProvider),
            settings,
            lastKnownPosition: knownPosition,
          ),
        );
    ref.read(airspaceActivityProvider);
    final styleLease = ref.listen(mapStyleProvider, (_, _) {});
    ref.onDispose(styleLease.close);
    await measureStartup(
      'Initial map style',
      () => ref.read(mapStyleProvider.future),
    );
    return PreparedApplication(
      releaseMapPreparation: () {
        styleLease.close();
        settingsLease.close();
      },
    );
  }),
  retry: (_, _) => null,
);

/// Retry failed local dependencies as well as the coordinator. Reading only
/// existing providers avoids starting unrelated work on a failed early boot.
void retryApplicationBootstrap(
  ProviderContainer container, {
  bool retryPending = false,
}) {
  bool needsRetry(AsyncValue value) =>
      value.hasError || (retryPending && value.isLoading && !value.hasValue);
  container.invalidate(applicationBootstrapProvider);
  if (container.read(sharedPreferencesProvider.exists) &&
      needsRetry(container.read(sharedPreferencesProvider))) {
    container.invalidate(sharedPreferencesProvider);
  }
  for (final dependency in [
    applicationConfigurationProvider,
    startupFirIndexProvider,
    startupMapAssetsProvider,
    startupOfflineDatabaseProvider,
  ]) {
    if (container.read(dependency.exists) &&
        needsRetry(container.read(dependency))) {
      container.invalidate(dependency);
    }
  }
  if (container.read(applicationRuntimeProvider.exists) &&
      needsRetry(container.read(applicationRuntimeProvider))) {
    container.invalidate(applicationRuntimeProvider);
  }
  if (container.read(displayPreferencesProvider.exists) &&
      needsRetry(container.read(displayPreferencesProvider))) {
    container.invalidate(displayPreferencesProvider);
  }
  if (container.read(appSettingsProvider.exists) &&
      needsRetry(container.read(appSettingsProvider))) {
    container.invalidate(appSettingsProvider);
  }
  if (container.read(navigationProvider.exists) &&
      needsRetry(container.read(navigationProvider))) {
    container.invalidate(navigationProvider);
  }
  if (container.read(favoritesProvider.exists) &&
      needsRetry(container.read(favoritesProvider))) {
    container.invalidate(favoritesProvider);
  }
  container.invalidate(mapStyleProvider);
}
