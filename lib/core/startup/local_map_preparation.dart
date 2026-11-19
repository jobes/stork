import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';

import '../providers/shared_preferences_provider.dart';
import '../services/database/database_service.dart';
import '../services/location_service.dart';
import '../services/map_assets_server.dart';
import '../services/protomaps_resolver.dart';
import '../../features/map/domain/utils/fir_utils.dart';
import 'startup_timing.dart';

// Independent local preparations. The coordinator starts them together and
// awaits all of them before creating the initial map style.
final startupFirIndexProvider = FutureProvider<void>(
  (_) => measureStartup('FIR index', FirUtils.initialize),
  retry: (_, _) => null,
);

final startupMapAssetsProvider = FutureProvider<void>((ref) async {
  await measureStartup('Map asset server', () async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (!ref.mounted) return;
    ProtomapsResolver.useCachedUrl(prefs);
    if (!kIsWeb) await MapAssetsServer.start();
  });
}, retry: (_, _) => null);

final startupOfflineDatabaseProvider = FutureProvider<void>(
  (_) => measureStartup('Offline database', () async {
    if (!kIsWeb) await DatabaseService.database;
  }),
  retry: (_, _) => null,
);

final startupLastKnownPositionProvider = FutureProvider<Geographic?>(
  (_) => measureStartup(
    'Last known position',
    () => LocationService.getGpsLocationOnly().timeout(
      const Duration(milliseconds: 600),
      onTimeout: () => null,
    ),
  ),
  retry: (_, _) => null,
);
