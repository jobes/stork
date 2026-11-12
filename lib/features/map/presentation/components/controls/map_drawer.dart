import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../../../core/widgets/stork_navigation_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../../offline_maps/presentation/providers/offline_maps_provider.dart';
import '../../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../../settings/presentation/providers/pilot_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/map_radar.dart';

class MapDrawer extends ConsumerWidget {
  const MapDrawer({super.key, this.radar, this.onRadarPlayback});

  final ValueListenable<RadarDisplay>? radar;
  final VoidCallback? onRadarPlayback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settings = ref.watch(appSettingsProvider).value;
    final pilot = ref
        .watch(pilotStateProvider)
        .value
        ?.where((pilot) => pilot.id == settings?.pilotId)
        .firstOrNull;
    final aircraft = ref
        .watch(aircraftStateProvider)
        .value
        ?.where((aircraft) => aircraft.id == settings?.airplaneId)
        .firstOrNull;
    final navigation = ref.watch(navigationProvider).value;
    final destination = navigation?.isActive == true
        ? navigation?.points.lastOrNull
        : null;
    final offlineStatus = kIsWeb
        ? null
        : ref.watch(
            offlineMapsProvider.select((state) {
              if (state.isDownloading) return l10n.menuOfflineDownloading;
              if (state.hasError) return l10n.downloadError;
              if (state.regions.isEmpty) return null;
              if (!state.isDownloaded) return l10n.offlineMapsDownloadRequired;
              final date = state.downloadDate;
              return date == null
                  ? l10n.offlineMapsReady
                  : l10n.menuOfflineDownloaded(date);
            }),
          );

    void open(String route) {
      final router = GoRouter.of(context);
      Scaffold.of(context).closeDrawer();
      unawaited(router.push<void>(route));
    }

    return Drawer(
      width: math.min(336, MediaQuery.sizeOf(context).width * .88),
      backgroundColor: colors.surfaceContainerLow,
      child: PointerInterceptor(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            children: [
              ListTile(
                minTileHeight: 52,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    theme.brightness == Brightness.dark
                        ? 'assets/images/app_icon_dark.png'
                        : 'assets/images/app_icon.png',
                    width: 28,
                    height: 28,
                    cacheWidth: 84,
                  ),
                ),
                title: Text(
                  pilot?.name ?? l10n.noPilotSelected,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  aircraft?.name ?? l10n.unknownAircraft,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => open('/profile'),
              ),
              if (radar case final radar?)
                ValueListenableBuilder(
                  valueListenable: radar,
                  builder: (context, status, _) {
                    final latest = status.latest;
                    return StorkNavigationTile(
                      icon: Icons.thunderstorm_outlined,
                      title: l10n.radarPlay,
                      subtitle: latest == null
                          ? null
                          : l10n.radarLatestTime(
                              DateFormat('HH:mm').format(latest),
                            ),
                      onTap: () {
                        Scaffold.of(context).closeDrawer();
                        onRadarPlayback?.call();
                      },
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.menuFlightAndMap,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              StorkNavigationTile(
                icon: Icons.route_outlined,
                title: l10n.menuRoute,
                subtitle: destination == null
                    ? l10n.menuNoActiveRoute
                    : l10n.menuActiveRoute(destination.name),
                highlighted: destination != null,
                onTap: () => open('/navigation'),
              ),
              StorkNavigationTile(
                icon: Icons.history,
                title: l10n.flightRecords,
                onTap: () => open('/flight-records'),
              ),
              StorkNavigationTile(
                icon: Icons.star_outline,
                title: l10n.menuFavoritePlaces,
                onTap: () => open('/favorites'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Divider(),
              ),
              if (!kIsWeb)
                StorkNavigationTile(
                  icon: Icons.map_outlined,
                  title: l10n.offlineMaps,
                  subtitle: offlineStatus,
                  onTap: () => open('/offline-maps'),
                ),
              StorkNavigationTile(
                icon: Icons.settings_outlined,
                title: l10n.settings,
                onTap: () => open('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
