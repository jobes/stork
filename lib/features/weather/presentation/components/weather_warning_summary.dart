import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/widgets/telemetry_card.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/weather_hazard.dart';
import '../dialogs/flight_weather_details_dialog.dart';
import '../providers/flight_weather_provider.dart';
import '../providers/weather_hazard_provider.dart';
import 'weather_attribution_link.dart';

class WeatherWarningSummary extends ConsumerWidget {
  const WeatherWarningSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(activeWeatherHazardDetailsProvider);
    if (details.isEmpty) return const SizedBox.shrink();
    final plan = ref.watch(flightWeatherPlanProvider);
    final route = ref.watch(navigationProvider).value?.points ?? [];
    final unit =
        ref.watch(appSettingsProvider).value?.windSpeedUnit ?? SpeedUnit.kmh;
    final l10n = AppLocalizations.of(context)!;
    final color = TelemetryCard.warningColor(
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final format = DateFormat.yMMMd(l10n.localeName).add_Hm();
    final hour = DateFormat.Hm(l10n.localeName);
    String speed(double value) =>
        '${context.formatNumber(unit.convertFromMs(value), 0)} ${unit.getAbbreviation(l10n)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.weatherRouteWarnings,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: color),
              ),
              for (final detail in details) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final point = weatherPoint(plan, detail.pointId);
                    final index = point?.waypointIndex;
                    final name = index != null && index < route.length
                        ? route[index].name
                        : detail.pointId == forecastOriginPointId
                        ? l10n.weatherRouteStart
                        : l10n.weatherRouteSampleLocation;
                    final coordinates =
                        '${detail.location.latitude.toStringAsFixed(4)}, ${detail.location.longitude.toStringAsFixed(4)}';
                    final reasons = [
                      for (final hazard in detail.hazards)
                        switch (hazard) {
                          WeatherHazard.wind => switch ((
                            detail.windMs,
                            detail.windLimitMs,
                          )) {
                            (final wind?, final limit?) =>
                              l10n.weatherExceededWind(
                                speed(wind),
                                speed(limit),
                              ),
                            _ => l10n.weatherAlertWindTitle,
                          },
                          WeatherHazard.gust => switch ((
                            detail.gustMs,
                            detail.gustLimitMs,
                          )) {
                            (final gust?, final limit?) =>
                              l10n.weatherExceededGust(
                                speed(gust),
                                speed(limit),
                              ),
                            _ => l10n.weatherAlertGustTitle,
                          },
                          WeatherHazard.precipitation => switch (detail
                              .precipitationMm) {
                            final precipitation? =>
                              '${l10n.weatherPrecipitation} · '
                                  '${context.formatNumber(precipitation, 1)} mm',
                            _ => l10n.weatherAlertPrecipitationTitle,
                          },
                          WeatherHazard.fog => l10n.weatherAlertFogTitle,
                          WeatherHazard.freezingPrecipitation =>
                            l10n.weatherAlertFreezingTitle,
                          WeatherHazard.snow => l10n.weatherAlertSnowTitle,
                          WeatherHazard.thunderstorm =>
                            l10n.weatherAlertThunderstormTitle,
                        },
                    ];
                    final end = detail.intervalEnd?.toUtc();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '$coordinates · ${format.format(detail.time.toUtc())} '
                          '${l10n.clockUtc}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (detail.altitudeFeet case final feet?)
                          Text(
                            '${context.formatNumber(feet, 0)} ${l10n.weatherAltitudeFt}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(reasons.join('\n')),
                        if (end != null &&
                            (detail.hazards.contains(WeatherHazard.gust) ||
                                detail.hazards.contains(
                                  WeatherHazard.precipitation,
                                )))
                          Text(
                            '${hour.format(end.subtract(const Duration(hours: 1)))}–${hour.format(end)} '
                            '${l10n.clockUtc}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (point != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => showFlightWeatherDetails(
                                context,
                                detail.pointId,
                              ),
                              child: Text(l10n.weatherPointDetails),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              const WeatherAttributionLink(),
            ],
          ),
        ),
      ),
    );
  }
}
