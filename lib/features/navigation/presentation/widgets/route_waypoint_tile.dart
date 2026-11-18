import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route/domain/models/navigation_leg.dart';
import '../../../route/domain/models/navigation_point.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../../../telemetry/presentation/widgets/telemetry_card.dart';
import '../../../weather/domain/weather_hazard.dart';
import '../../../weather/presentation/components/weather_hazard_labels.dart';
import '../../../weather/presentation/providers/route_waypoint_weather_provider.dart';
import '../utils/navigation_formatters.dart';

/// One row of the route list: ETA, leg totals, planned altitude and wind.
class RouteWaypointTile extends StatelessWidget {
  const RouteWaypointTile({
    super.key,
    required this.index,
    required this.count,
    required this.point,
    required this.leg,
    required this.weather,
    required this.speedUnit,
    required this.defaultAltitudeFeet,
    required this.onTap,
    required this.onRemove,
    required this.onAltitude,
  });

  final int index;
  final int count;
  final NavigationPoint point;
  final NavigationLeg? leg;
  final RouteWaypointWeather? weather;
  final SpeedUnit speedUnit;
  final int? defaultAltitudeFeet;
  final VoidCallback? onTap;
  final VoidCallback onRemove;
  final VoidCallback onAltitude;

  bool get _isDestination => index == count - 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final warningColor = TelemetryCard.warningColor(
      isDark: theme.brightness == Brightness.dark,
    );
    final hazards = weather?.hazards ?? const <WeatherHazard>{};
    final hasHazard = hazards.isNotEmpty;
    final eta = weather?.eta ?? leg?.eta;
    final legDistanceKm = leg == null ? null : leg!.legDistanceMeters / 1000.0;
    final cumulativeDistanceKm = leg == null
        ? null
        : leg!.cumulativeDistanceMeters / 1000.0;

    return ReorderableDelayedDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: colors.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: hasHazard ? warningColor : colors.outlineVariant,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, right: 8),
                      child: Icon(
                        Icons.drag_handle,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _NumberBadge(
                    index: index,
                    isDestination: _isDestination,
                    hasHazard: hasHazard,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      point.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (point.isAirport) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.local_airport,
                                      size: 15,
                                      color: colors.primary,
                                    ),
                                  ],
                                  if (hasHazard) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: hazardLabels(
                                        l10n,
                                        hazards,
                                        separator: '\n',
                                      ),
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                        color: warningColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<_WaypointAction>(
                              tooltip: l10n.navigationWaypointActions,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert,
                                size: 20,
                                color: colors.onSurfaceVariant,
                              ),
                              onSelected: (action) => switch (action) {
                                _WaypointAction.details => onTap?.call(),
                                _WaypointAction.remove => onRemove(),
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: _WaypointAction.details,
                                  enabled: onTap != null,
                                  child: _MenuRow(
                                    icon: Icons.info_outline,
                                    label: l10n.navigationWaypointDetails,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _WaypointAction.remove,
                                  child: _MenuRow(
                                    icon: Icons.delete_outline,
                                    label: l10n.navigationRemoveWaypoint,
                                    color: colors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${l10n.etaLabel} ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              TextSpan(
                                text: formatNavigationTimeUtc(context, eta),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' · ${l10n.leg} '
                                    '${legDistanceKm == null ? l10n.placeholderDash : '${context.formatNumber(legDistanceKm, 1)} km'}'
                                    ' · ${leg?.eta == null ? l10n.placeholderDash : formatNavigationDuration(context, leg?.legDuration)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${l10n.total} '
                          '${cumulativeDistanceKm == null ? l10n.placeholderDash : '${context.formatNumber(cumulativeDistanceKm, 1)} km'}'
                          ' · ${leg?.eta == null ? l10n.placeholderDash : formatNavigationDuration(context, leg?.cumulativeDuration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _AltitudeChip(
                              altitudeFeet: point.weatherAltitudeFeet
                                  ?.toDouble(),
                              defaultFeet: defaultAltitudeFeet,
                              onTap: onAltitude,
                            ),
                            if (weather?.wind case final wind?)
                              _InfoChip(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.rotate(
                                      angle:
                                          (wind.directionFrom + 180) *
                                          math.pi /
                                          180,
                                      child: const Icon(
                                        Icons.navigation,
                                        size: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(wind.directionFrom.round() % 360).toString().padLeft(3, '0')}° · '
                                      '${context.formatNumber(speedUnit.convertFromMs(wind.speedMs), 0)} '
                                      '${speedUnit.getAbbreviation(l10n)}',
                                    ),
                                  ],
                                ),
                              )
                            else if (weather != null &&
                                !weather!.forecastAvailable)
                              Tooltip(
                                message: l10n.weatherForecastUnavailable,
                                child: Icon(
                                  Icons.cloud_off_outlined,
                                  size: 16,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            if (_windEffectMinutes(weather) case final minutes?)
                              _InfoChip(
                                tooltip: l10n.navigationWindTimeChange(
                                  '${minutes > 0 ? '+' : '−'}${context.formatNumber(minutes.abs().toDouble(), 0)}',
                                ),
                                child: Text(
                                  '${minutes > 0 ? '+' : '−'}${context.formatNumber(minutes.abs().toDouble(), 0)} ${l10n.minutesAbbrev}',
                                ),
                              ),
                            if (index == 0 && count > 1)
                              _Badge(
                                label: l10n.navigationNextWaypoint,
                                background: colors.primaryContainer,
                                foreground: colors.onPrimaryContainer,
                              ),
                            if (_isDestination)
                              _Badge(
                                label: l10n.navigationDestination,
                                background: colors.secondaryContainer,
                                foreground: colors.onSecondaryContainer,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _windEffectMinutes(RouteWaypointWeather? weather) {
    final seconds = weather?.windEffect?.inSeconds ?? 0;
    final minutes = (seconds / 60).round();
    return minutes == 0 ? null : minutes;
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({
    required this.index,
    required this.isDestination,
    required this.hasHazard,
  });

  final int index;
  final bool isDestination;
  final bool hasHazard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = hasHazard
        ? TelemetryCard.warningColor(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ).withValues(alpha: 0.16)
        : colors.primaryContainer;
    final foreground = hasHazard
        ? TelemetryCard.warningColor(
            isDark: Theme.of(context).brightness == Brightness.dark,
          )
        : colors.onPrimaryContainer;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: isDestination
          ? Icon(Icons.flag_outlined, size: 15, color: foreground)
          : Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: foreground,
              ),
            ),
    );
  }
}

class _AltitudeChip extends StatelessWidget {
  const _AltitudeChip({
    required this.altitudeFeet,
    required this.defaultFeet,
    required this.onTap,
  });

  final double? altitudeFeet;
  final int? defaultFeet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final custom = altitudeFeet != null;
    final value = (altitudeFeet ?? defaultFeet?.toDouble())?.round();
    final label = value == null
        ? l10n.altitudeSetAction
        : custom
        ? l10n.altitudeChipValue(context.formatNumber(value.toDouble(), 0))
        : l10n.altitudeDefaultChip(context.formatNumber(value.toDouble(), 0));
    final colors = Theme.of(context).colorScheme;
    return _InfoChip(
      onTap: onTap,
      foreground: value == null ? colors.primary : null,
      child: Text(label),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.child,
    this.onTap,
    this.tooltip,
    this.foreground,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: foreground ?? colors.onSurfaceVariant,
        ),
        child: child,
      ),
    );
    final chip = Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: foreground,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

enum _WaypointAction { details, remove }
