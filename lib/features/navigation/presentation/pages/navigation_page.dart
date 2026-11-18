import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/stork_detail_surface.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../../route/presentation/providers/navigation_provider.dart';
import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../../../weather/domain/flight_forecast.dart';
import '../../../weather/domain/forecast_profile.dart';
import '../../../weather/domain/forecast_query.dart';
import '../../../weather/presentation/dialogs/flight_weather_details_dialog.dart';
import '../../../weather/presentation/dialogs/waypoint_altitude_dialog.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/navigation_eta_provider.dart';
import '../../../weather/presentation/providers/route_waypoint_weather_provider.dart';
import '../dialogs/departure_dialog.dart';
import '../utils/navigation_formatters.dart';
import '../widgets/route_waypoint_tile.dart';
import '../widgets/route_weather_strip.dart';
import '../windy_route.dart';

class NavigationPage extends ConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(throttledTelemetryProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentPositionKnown =
        telemetry.latitude != null &&
        telemetry.longitude != null &&
        telemetry.latitude != 0.0 &&
        telemetry.longitude != 0.0;

    if (!currentPositionKnown) {
      return const _WaitingForLocation();
    }

    final navigationAsync = ref.watch(navigationProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return navigationAsync.when(
      data: (navState) {
        final points = navState.points;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.navigation),
            actions: [
              if (points.isNotEmpty)
                PopupMenuButton<_RouteMenuAction>(
                  tooltip: l10n.navigationRouteActions,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => switch (action) {
                    _RouteMenuAction.clear => unawaited(
                      _confirmClearRoute(context, ref),
                    ),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _RouteMenuAction.clear,
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.clearNavigation,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: points.isEmpty
              ? const _EmptyRoute()
              : settingsAsync.when(
                  data: (settings) =>
                      _RouteBody(navState: navState, settings: settings),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
          bottomNavigationBar: points.isEmpty
              ? null
              : _RouteActionBar(
                  navState: navState,
                  latitude: telemetry.latitude,
                  longitude: telemetry.longitude,
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.navigation)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(l10n.navigation)),
        body: Center(child: Text(error.toString())),
      ),
    );
  }
}

Future<void> _confirmClearRoute(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => BaseDetailsDialog(
      titleText: l10n.clearNavigation,
      icon: Icons.delete_sweep_outlined,
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.clearNavigationConfirm),
          const SizedBox(height: 20),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.clearNavigation),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(navigationProvider.notifier).clearNavigation();
  }
}

enum _RouteMenuAction { clear }

class _RouteBody extends ConsumerWidget {
  const _RouteBody({required this.navState, required this.settings});

  final NavigationState navState;
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final calculations = ref.watch(navigationEtaProvider);
    final telemetry = ref.watch(throttledTelemetryProvider);
    final weather = ref.watch(routeWaypointWeatherProvider);
    final plan = ref.watch(flightWeatherPlanProvider);
    final profiles = ref.watch(flightForecastProfilesProvider).value;
    final references = settings.showFlightWeather
        ? ref.watch(routeForecastReferencesProvider).value ??
              const <String, ForecastReference>{}
        : const <String, ForecastReference>{};
    final locations = settings.showFlightWeather
        ? ref.watch(flightWeatherProfileLocationsProvider)
        : const <String, ForecastLocation>{};
    final selectedDeparture = ref.watch(flightDepartureProvider);
    final defaultAltitude = ref
        .watch(selectedAircraftProvider)
        ?.weatherAltitudeFeet;
    final now = clock.now();
    final departure = selectedDeparture?.isAfter(now) == true
        ? selectedDeparture
        : null;
    final useRealSpeed =
        telemetry.isFlying &&
        telemetry.groundSpeed != null &&
        telemetry.groundSpeed! > 0;
    final activeSpeedMs = useRealSpeed
        ? telemetry.groundSpeed!
        : ref.watch(cruiseSpeedProvider);
    final speedLabel =
        '${useRealSpeed ? l10n.groundSpeed : l10n.aircraftCruiseSpeed}: '
        '${settings.speedUnit.convertFromMs(activeSpeedMs).toStringAsFixed(0)} '
        '${settings.speedUnit.getAbbreviation(l10n)}';

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RouteOverviewCard(
            distanceKm: calculations.totalDistanceMeters / 1000.0,
            duration: calculations.totalDuration,
            destinationEta: calculations.legs.lastOrNull?.eta,
            isActive: navState.isActive,
            isFlying: telemetry.isFlying,
            speedLabel: speedLabel,
            departure: departure,
            onEditDeparture: () =>
                unawaited(showFlightDepartureDialog(context)),
          ),
          const SizedBox(height: 10),
          const RouteWeatherStrip(),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                l10n.waypointsList,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${navState.points.length})',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      header: header,
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: navState.points.length,
      onReorderItem: (oldIndex, newIndex) => ref
          .read(navigationProvider.notifier)
          .reorderPoints(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final leg = index < calculations.legs.length
            ? calculations.legs[index]
            : null;
        final point = leg?.point ?? navState.points[index];
        final planPoint = plan
            .where((forecastPoint) => forecastPoint.waypointIndex == index)
            .firstOrNull;
        final series = planPoint == null
            ? null
            : profiles?.series[forecastLocationKey(
                locations[planPoint.id] ?? planPoint.location,
              )];
        return RouteWaypointTile(
          key: ValueKey(
            '${point.latitude}_${point.longitude}_${point.name}_$index',
          ),
          index: index,
          count: navState.points.length,
          point: point,
          leg: leg,
          weather: weather[index],
          speedUnit: settings.speedUnit,
          defaultAltitudeFeet: defaultAltitude,
          onTap: planPoint == null
              ? null
              : () => showFlightWeatherDetails(context, planPoint.id),
          onRemove: () =>
              unawaited(_removeWaypoint(ref, context, index, point)),
          onAltitude: () => unawaited(
            showWaypointAltitudeDialog(
              context,
              ref,
              waypoint: point,
              waypointIndex: index,
              defaultFeet: defaultAltitude,
              forecastPoint: planPoint,
              eta: weather[index]?.eta,
              series: series,
              reference: planPoint == null ? null : references[planPoint.id],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _removeWaypoint(
  WidgetRef ref,
  BuildContext context,
  int index,
  NavigationPoint point,
) async {
  final l10n = AppLocalizations.of(context)!;
  final navigation = ref.read(navigationProvider.notifier);
  final departure = ref.read(flightDepartureProvider.notifier);
  final plannedDeparture = ref.read(flightDepartureProvider);
  await navigation.removePoint(index);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.navigationWaypointRemoved(point.name)),
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () async {
          await navigation.insertPoint(index, point);
          if (plannedDeparture != null) departure.select(plannedDeparture);
        },
      ),
    ),
  );
}

class _RouteOverviewCard extends StatelessWidget {
  const _RouteOverviewCard({
    required this.distanceKm,
    required this.duration,
    required this.destinationEta,
    required this.isActive,
    required this.isFlying,
    required this.speedLabel,
    required this.departure,
    required this.onEditDeparture,
  });

  final double distanceKm;
  final Duration duration;
  final DateTime? destinationEta;
  final bool isActive;
  final bool isFlying;
  final String speedLabel;
  final DateTime? departure;
  final VoidCallback onEditDeparture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = l10n.localeName;
    final departureLabel = departure == null
        ? l10n.weatherDepartureNow
        : DateFormat.yMMMd(locale).add_Hm().format(departure!.toLocal());
    final departureUtc = departure == null
        ? null
        : '${DateFormat.Hm(locale).format(departure!.toUtc())} ${l10n.clockUtc}';

    return StorkDetailSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      radius: 16,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.route_outlined,
                  value: '${context.formatNumber(distanceKm, 2)} km',
                  label: l10n.flightDistance,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.schedule,
                  value: formatNavigationDuration(context, duration),
                  label: l10n.flightDuration,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.flag_outlined,
                  value: formatNavigationTimeUtc(
                    context,
                    destinationEta,
                  ).split(' ').first,
                  label: '${l10n.etaLabel} · ${l10n.clockUtc}',
                  highlighted: true,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _StatusChip(active: isActive),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  speedLabel,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (!isFlying) ...[
            const Divider(height: 16),
            Semantics(
              button: true,
              label: l10n.weatherPlannedDeparture,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEditDeparture,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.weatherPlannedDeparture,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              departureLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (departureUtc != null)
                              Text(
                                departureUtc,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        Icon(icon, size: 22, color: colors.onSurfaceVariant),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: highlighted ? colors.primary : colors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? l10n.navigationActive : l10n.navigationStopped,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active
                  ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteActionBar extends ConsumerWidget {
  const _RouteActionBar({
    required this.navState,
    required this.latitude,
    required this.longitude,
  });

  final NavigationState navState;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isActive = navState.isActive;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: isActive ? colors.errorContainer : null,
                  foregroundColor: isActive ? colors.onErrorContainer : null,
                ),
                icon: Icon(isActive ? Icons.stop : Icons.play_arrow),
                label: Text(
                  isActive ? l10n.stopNavigation : l10n.startNavigation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => unawaited(
                  ref.read(navigationProvider.notifier).toggleActive(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.cloud_outlined, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.weatherInWindy),
                ),
                onPressed: () => openWindyRoute(
                  navState.points,
                  currentLatitude: latitude,
                  currentLongitude: longitude,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingForLocation extends StatelessWidget {
  const _WaitingForLocation();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navigation)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_searching,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                l10n.navigationWaitingForLocation,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.navigationWaitingForLocationHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.navigationEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _EmptyStep(number: 1, text: l10n.navigationEmptyStepMap),
            _EmptyStep(number: 2, text: l10n.navigationEmptyStepTap),
            _EmptyStep(number: 3, text: l10n.navigationEmptyStepAdd),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.star_outline),
              label: Text(l10n.navigationAddFromFavourites),
              onPressed: () => GoRouter.of(context).push('/favorites'),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.navigationEmptyTip,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStep extends StatelessWidget {
  const _EmptyStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
