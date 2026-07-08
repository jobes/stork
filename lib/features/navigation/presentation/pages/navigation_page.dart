import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clock/clock.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../providers/navigation_provider.dart';

class NavigationPage extends ConsumerWidget {
  const NavigationPage({super.key});

  String _formatDurationNoSeconds(BuildContext context, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final minStr = minutes.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minStr';
    } else {
      return '$minutes ${AppLocalizations.of(context)!.minutesAbbrev}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(throttledTelemetryProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if the current position is known (analogous to map camera initialization/rendering criteria)
    final currentPositionKnown =
        telemetry.latitude != null &&
        telemetry.longitude != null &&
        telemetry.latitude != 0.0 &&
        telemetry.longitude != 0.0;

    if (!currentPositionKnown) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navigation), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_disabled_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.navigationRequiresLocation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final navigationAsync = ref.watch(navigationProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return navigationAsync.when(
      data: (navState) {
        final points = navState.points;
        final isActive = navState.isActive;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.navigation),
            centerTitle: true,
            actions: [
              if (points.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: l10n.clearNavigation,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.clearNavigation),
                        content: Text(l10n.clearNavigationConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              MaterialLocalizations.of(
                                context,
                              ).cancelButtonLabel,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              l10n.clearNavigation,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(navigationProvider.notifier)
                          .clearNavigation();
                    }
                  },
                ),
                TextButton.icon(
                  icon: Icon(
                    isActive ? Icons.stop : Icons.play_arrow,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                  label: Text(
                    isActive ? l10n.stopNavigation : l10n.startNavigation,
                    style: TextStyle(
                      color: isActive ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    ref.read(navigationProvider.notifier).toggleActive();
                  },
                ),
              ],
            ],
          ),
          body: points.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.noNavigationPoints,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : settingsAsync.when(
                  data: (settings) {
                    final speedUnit = settings.speedUnit;
                    final useRealSpeed =
                        telemetry.isFlying &&
                        telemetry.groundSpeed != null &&
                        telemetry.groundSpeed! > 0;
                    final activeSpeedMs = useRealSpeed
                        ? telemetry.groundSpeed!
                        : settings.averageSpeed;

                    final calculations = NavigationCalculations.calculate(
                      points: points,
                      currentLatitude: telemetry.latitude,
                      currentLongitude: telemetry.longitude,
                      activeSpeedMs: activeSpeedMs,
                      now: clock.now(),
                    );

                    final totalDistanceKm =
                        calculations.totalDistanceMeters / 1000.0;
                    final totalDuration = calculations.totalDuration;
                    final formattedSpeed = speedUnit
                        .convertFromMs(activeSpeedMs)
                        .toStringAsFixed(0);

                    return Column(
                      children: [
                        // Premium Summary Card
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withAlpha(200),
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withAlpha(150),
                                      ]
                                    : [
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withAlpha(180),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    isDark ? 50 : 20,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${context.formatNumber(totalDistanceKm, 2)} km',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        Text(
                                          l10n.flightDistance,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withAlpha(200),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 1,
                                      height: 50,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withAlpha(50),
                                    ),
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatDurationNoSeconds(
                                            context,
                                            totalDuration,
                                          ),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        Text(
                                          l10n.flightDuration,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withAlpha(200),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, thickness: 0.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.speed_outlined,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withAlpha(180),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${useRealSpeed ? l10n.groundSpeed : l10n.averageSpeed}: $formattedSpeed ${speedUnit.getAbbreviation(l10n)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withAlpha(200),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withAlpha(
                                            isDark ? 40 : 30,
                                          )
                                        : Colors.grey.withAlpha(
                                            isDark ? 40 : 30,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.green
                                          : Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isActive
                                            ? l10n.navigationActive
                                            : l10n.navigationStopped,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isActive
                                              ? (isDark
                                                    ? Colors.greenAccent
                                                    : Colors.green.shade800)
                                              : (isDark
                                                    ? Colors.white70
                                                    : Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Reorderable Waypoints List
                        Expanded(
                          child: ReorderableListView.builder(
                            itemCount: points.length,
                            onReorderItem: (oldIndex, newIndex) {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              ref
                                  .read(navigationProvider.notifier)
                                  .reorderPoints(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final leg = calculations.legs[index];
                              final point = leg.point;
                              final legDistanceKm =
                                  leg.legDistanceMeters / 1000.0;
                              final cumulativeDistanceKm =
                                  leg.cumulativeDistanceMeters / 1000.0;

                              return Card(
                                key: Key(
                                  '${point.latitude}_${point.longitude}_$index',
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 6.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.adjust,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          point.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (point.isAirport) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.local_airport,
                                          size: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${l10n.leg}: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              '${context.formatNumber(legDistanceKm, 1)} km • ${_formatDurationNoSeconds(context, leg.legDuration)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '${l10n.total}: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              '${context.formatNumber(cumulativeDistanceKm, 1)} km • ${_formatDurationNoSeconds(context, leg.cumulativeDuration)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(navigationProvider.notifier)
                                          .removePoint(index);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(e.toString())),
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.navigation), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: Text(l10n.navigation), centerTitle: true),
        body: Center(child: Text(e.toString())),
      ),
    );
  }
}
