import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/navigation_provider.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/widgets/telemetry_card.dart';
import '../../../weather/presentation/components/weather_hazard_labels.dart';
import '../../../weather/presentation/dialogs/flight_weather_details_dialog.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/route_waypoint_weather_provider.dart';
import '../utils/navigation_formatters.dart';

/// Compact weather state for the route: warnings, destination wind, or the
/// reason why forecast data is not available.
class RouteWeatherStrip extends ConsumerWidget {
  const RouteWeatherStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
    );
    if (!enabled) {
      return _Notice(
        icon: Icons.cloud_off_outlined,
        message: l10n.weatherDisabled,
        onTap: () => GoRouter.of(context).push('/settings'),
      );
    }
    final weather = ref.watch(routeWaypointWeatherProvider);
    if (weather.isEmpty) return const SizedBox.shrink();
    final points = ref.watch(navigationProvider).value?.points ?? const [];
    final profiles = ref.watch(flightForecastProfilesProvider);

    final hazardous =
        weather.entries
            .where((entry) => entry.value.hazards.isNotEmpty)
            .toList()
          ..sort(
            (a, b) => (a.value.eta ?? DateTime(2100)).compareTo(
              b.value.eta ?? DateTime(2100),
            ),
          );
    if (hazardous.isNotEmpty) {
      final first = hazardous.first;
      final name = first.key < points.length
          ? points[first.key].name
          : l10n.weatherRouteStart;
      final warnings = hazardLabels(l10n, first.value.hazards);
      final planPoint = ref
          .watch(flightWeatherPlanProvider)
          .where((point) => point.waypointIndex == first.key)
          .firstOrNull;
      return _Notice(
        icon: Icons.warning_amber_rounded,
        warning: true,
        message: l10n.routeWeatherWarnings(hazardous.length),
        detail:
            '$name · $warnings · ${formatNavigationTimeUtc(context, first.value.eta)}',
        onTap: planPoint == null
            ? null
            : () => showFlightWeatherDetails(context, planPoint.id),
      );
    }

    if (weather.values.every((entry) => entry.altitudeFeet == null)) {
      return _Notice(
        icon: Icons.height,
        message: l10n.weatherMissingAltitude,
        onTap: null,
      );
    }

    final destinationIndex = points.isEmpty ? null : points.length - 1;
    final destination = destinationIndex == null
        ? null
        : weather[destinationIndex];
    if (destination != null && destination.altitudeFeet == null) {
      return _Notice(icon: Icons.height, message: l10n.weatherMissingAltitude);
    }
    final wind = destination?.wind;
    if (destination == null || !destination.forecastAvailable || wind == null) {
      if (profiles.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: LinearProgressIndicator(minHeight: 2),
        );
      }
      return _Notice(
        icon: Icons.cloud_off_outlined,
        message: l10n.weatherForecastUnavailable,
      );
    }

    final unit =
        ref.watch(appSettingsProvider).value?.windSpeedUnit ?? SpeedUnit.kmh;
    final speed = context.formatNumber(unit.convertFromMs(wind.speedMs), 0);
    final gust = destination.gustMs == null
        ? null
        : context.formatNumber(unit.convertFromMs(destination.gustMs!), 0);
    final effect = ((destination.windEffect?.inSeconds ?? 0) / 60).round();
    final parts = [
      '${(wind.directionFrom.round() % 360).toString().padLeft(3, '0')}° · '
          '$speed ${unit.getAbbreviation(l10n)}',
      if (gust != null)
        '${l10n.weatherGustShort} $gust ${unit.getAbbreviation(l10n)}',
      if (effect != 0)
        l10n.navigationWindTimeChange(
          '${effect > 0 ? '+' : '−'}${context.formatNumber(effect.abs().toDouble(), 0)}',
        ),
    ];
    return _Notice(
      icon: Icons.air,
      message: l10n.routeWeatherDestinationWind,
      detail: parts.join(' · '),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    this.detail,
    this.onTap,
    this.warning = false,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final VoidCallback? onTap;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = warning
        ? TelemetryCard.warningColor(
            isDark: theme.brightness == Brightness.dark,
          )
        : colors.onSurfaceVariant;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: warning ? FontWeight.bold : FontWeight.w500,
                    color: warning ? accent : colors.onSurface,
                  ),
                ),
                if (detail case final detail?)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, size: 18, color: accent),
        ],
      ),
    );
    return Material(
      color: warning
          ? accent.withValues(alpha: 0.08)
          : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warning ? accent : colors.outlineVariant),
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
