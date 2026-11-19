import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shared_preferences_provider.dart';
import '../services/cannelloni_service.dart';
import '../services/database/database_service.dart';
import '../services/location_service.dart';
import '../services/map_assets_server.dart';
import '../services/protomaps_resolver.dart';
import '../services/style_provider.dart';
import '../../features/favorites/presentation/providers/favorites_provider.dart';
import '../../features/map/domain/utils/fir_utils.dart';
import '../../features/map/presentation/providers/airspace_activity_provider.dart';
import '../../features/navigation/presentation/providers/navigation_provider.dart';
import '../../features/settings/presentation/providers/display_preferences_provider.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/telemetry/presentation/providers/black_box_provider.dart';
import '../../features/telemetry/presentation/providers/telemetry_provider.dart';
import 'initial_map_camera.dart';
import 'application_runtime.dart';

/// Holds the prepared style only until the first destination has mounted.
/// After handoff, ordinary page subscriptions own the map providers again.
class PreparedApplication {
  const PreparedApplication({this.releaseMapPreparation});
  final void Function()? releaseMapPreparation;
}

/// Read once by the app shell after its first frame. No native map is mounted
/// until this future completes, including preparation of its initial GeoJSON.
final applicationBootstrapProvider = FutureProvider<PreparedApplication>((
  ref,
) async {
  await ref.watch(applicationRuntimeProvider.future);
  if (!ref.mounted) return const PreparedApplication();

  // A read of an auto-disposed provider's future does not keep its async
  // build mounted. Hold settings through preparation and the first UI frame.
  final settingsLease = ref.listen(appSettingsProvider, (_, _) {});
  ref.onDispose(settingsLease.close);
  await Future.wait([
    ref.read(displayPreferencesProvider.future),
    ref.read(appSettingsProvider.future),
    ref.read(navigationProvider.future),
    ref.read(favoritesProvider.future),
  ]);
  if (!ref.mounted) return const PreparedApplication();

  // These are session services, not map services. Do not postpone recording
  // until the renderer or online data is available. Their providers keep alive.
  ref.read(cannelloniServiceProvider);
  ref.read(blackBoxServiceProvider);
  ref.read(gpsListenerProvider);

  await FirUtils.initialize();
  if (!ref.mounted) return const PreparedApplication();
  final prefs = await ref.read(sharedPreferencesProvider.future);
  ProtomapsResolver.useCachedUrl(prefs);
  if (!kIsWeb) {
    await MapAssetsServer.start();
    await DatabaseService.database;
  }
  if (!ref.mounted) return const PreparedApplication();

  // Quiet, bounded local lookup only. Neither GeoIP nor a new GPS fix belongs
  // on the startup critical path.
  final lastPosition = await LocationService.getGpsLocationOnly().timeout(
    const Duration(milliseconds: 600),
    onTimeout: () => null,
  );
  if (!ref.mounted) return const PreparedApplication();
  final telemetry = ref.read(telemetryProvider);
  final settings = ref.read(appSettingsProvider).requireValue;
  ref
      .read(initialMapCameraProvider.notifier)
      .prepare(
        InitialMapCamera.fromTelemetry(
          telemetry,
          settings,
          lastKnownPosition: lastPosition,
        ),
      );
  ref.read(airspaceActivityProvider);
  final styleLease = ref.listen(mapStyleProvider, (_, _) {});
  ref.onDispose(styleLease.close);
  await ref.read(mapStyleProvider.future);
  return PreparedApplication(
    releaseMapPreparation: () {
      styleLease.close();
      settingsLease.close();
    },
  );
}, retry: (_, _) => null);

/// Retry failed local dependencies as well as the coordinator. Reading only
/// existing providers avoids starting unrelated work on a failed early boot.
void retryApplicationBootstrap(ProviderContainer container) {
  container.invalidate(applicationBootstrapProvider);
  if (container.read(applicationRuntimeProvider.exists) &&
      container.read(applicationRuntimeProvider).hasError) {
    container.invalidate(applicationRuntimeProvider);
  }
  if (container.read(displayPreferencesProvider.exists) &&
      container.read(displayPreferencesProvider).hasError) {
    container.invalidate(displayPreferencesProvider);
  }
  if (container.read(appSettingsProvider.exists) &&
      container.read(appSettingsProvider).hasError) {
    container.invalidate(appSettingsProvider);
  }
  if (container.read(navigationProvider.exists) &&
      container.read(navigationProvider).hasError) {
    container.invalidate(navigationProvider);
  }
  if (container.read(favoritesProvider.exists) &&
      container.read(favoritesProvider).hasError) {
    container.invalidate(favoritesProvider);
  }
  container.invalidate(mapStyleProvider);
}
