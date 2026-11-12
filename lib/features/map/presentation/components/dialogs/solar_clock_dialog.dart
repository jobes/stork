import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/stork_detail_surface.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../telemetry/presentation/providers/gps_health_provider.dart';
import '../../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../domain/models/solar_times.dart';
import '../../providers/map_clock_provider.dart';
import 'base_details_dialog.dart';

Future<void> showSolarClockDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _SolarClockDialog(),
);

class _SolarClockDialog extends ConsumerWidget {
  const _SolarClockDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final now = ref.watch(mapClockProvider);
    final local = now.toLocal();
    final (lastFix, hasPosition) = ref.watch(
      telemetryProvider.select(
        (state) => (
          state.gpsLastFixAt,
          state.latitude != null && state.longitude != null,
        ),
      ),
    );
    final hasFix =
        hasPosition &&
        lastFix != null &&
        now.difference(lastFix) < GpsHealth.fixStaleAfter;
    final solar = hasFix ? ref.watch(mapSolarTimesProvider) : null;
    final today = solar?.today;
    final sunrise = today?.firstTimeOf(SolarEvent.sunrise);
    final sunset = today?.firstTimeOf(SolarEvent.sunset);
    final daylight =
        sunrise != null && sunset != null && sunset.isAfter(sunrise)
        ? (sunset.difference(sunrise).inMilliseconds /
                  Duration.millisecondsPerMinute)
              .round()
        : null;
    final timeFormat = DateFormat.Hm(l10n.localeName);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final nextTwilight = solar == null
        ? null
        : nextCivilTwilight(
            now: now,
            today: solar.today,
            tomorrow: solar.tomorrow,
          );

    String eventTime(DateTime? event, {required bool utc}) {
      if (event == null) return l10n.placeholderDash;
      final rounded = event.add(const Duration(seconds: 30));
      return timeFormat.format(utc ? rounded : rounded.toLocal());
    }

    return BaseDetailsDialog(
      titleText: l10n.solarClockTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final utcReading = _ClockReading(
                label: l10n.clockUtc,
                time: timeFormat.format(now),
                date: dateFormat.format(now),
                highlighted: true,
              );
              final localReading = _ClockReading(
                label: l10n.clockLocalTimeWithOffset(_utcOffset(local)),
                time: timeFormat.format(local),
                date: dateFormat.format(local),
              );
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              if (constraints.maxWidth < 230 * scale) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    utcReading,
                    const SizedBox(height: 8),
                    localReading,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: utcReading),
                  const SizedBox(width: 8),
                  Expanded(child: localReading),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (!hasFix)
            Text(l10n.gpsWaiting, style: theme.textTheme.bodyMedium)
          else ...[
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              children: [
                TableRow(
                  children: [
                    _TableCell(l10n.today, header: true),
                    _TableCell(
                      l10n.clockLocalTime,
                      header: true,
                      numeric: true,
                    ),
                    _TableCell(l10n.clockUtc, header: true, numeric: true),
                  ],
                ),
                for (final event in SolarEvent.values)
                  TableRow(
                    children: [
                      _TableCell(
                        switch (event) {
                          SolarEvent.civilDawn => l10n.clockCivilDawn,
                          SolarEvent.sunrise => l10n.clockSunrise,
                          SolarEvent.sunset => l10n.clockSunset,
                          SolarEvent.civilDusk => l10n.clockCivilDusk,
                        },
                        abbreviation: switch (event) {
                          SolarEvent.civilDawn => l10n.clockCivilDawnAbbrev,
                          SolarEvent.civilDusk => l10n.clockCivilDuskAbbrev,
                          _ => null,
                        },
                        leading: switch (event) {
                          SolarEvent.civilDawn => Icon(
                            Icons.brightness_6_outlined,
                            color: colors.primary,
                          ),
                          SolarEvent.sunrise => Icon(
                            Icons.wb_sunny_outlined,
                            color: isDark
                                ? Colors.amber.shade300
                                : Colors.orange.shade900,
                          ),
                          SolarEvent.sunset => Icon(
                            Icons.wb_twilight,
                            color: isDark
                                ? Colors.deepOrange.shade300
                                : Colors.deepOrange.shade800,
                          ),
                          SolarEvent.civilDusk => Icon(
                            Icons.nights_stay_outlined,
                            color: colors.tertiary,
                          ),
                        },
                      ),
                      _TableCell(
                        eventTime(today?.firstTimeOf(event), utc: false),
                        numeric: true,
                      ),
                      _TableCell(
                        eventTime(today?.firstTimeOf(event), utc: true),
                        numeric: true,
                      ),
                    ],
                  ),
              ],
            ),
            if (nextTwilight case (:final crossing, :final tomorrow)) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_bottom,
                          size: 18,
                          color: colors.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(switch ((crossing.event, tomorrow)) {
                                (SolarEvent.civilDawn, false) =>
                                  l10n.clockUntilDawn,
                                (SolarEvent.civilDawn, true) =>
                                  l10n.clockUntilTomorrowDawn,
                                (_, false) => l10n.clockUntilDusk,
                                (_, true) => l10n.clockUntilTomorrowDusk,
                              }),
                              Text(
                                _countdown(crossing.time.difference(now), l10n),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Text(
            l10n.clockDayLength(
              daylight == null
                  ? l10n.clockDayLengthUnavailable
                  : l10n.clockCountdownHoursMinutes(
                      daylight ~/ 60,
                      daylight % 60,
                    ),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _countdown(Duration remaining, AppLocalizations l10n) {
    final minutes = (remaining.inMilliseconds / Duration.millisecondsPerMinute)
        .ceil();
    final hours = minutes ~/ 60;
    return hours == 0
        ? '$minutes ${l10n.minutesAbbrev}'
        : l10n.clockCountdownHoursMinutes(hours, minutes % 60);
  }

  String _utcOffset(DateTime local) {
    final minutes = local.timeZoneOffset.inMinutes;
    final sign = minutes < 0 ? '−' : '+';
    final hours = minutes.abs() ~/ 60;
    final remainder = minutes.abs() % 60;
    return remainder == 0
        ? '$sign$hours'
        : '$sign$hours:${remainder.toString().padLeft(2, '0')}';
  }
}

class _ClockReading extends StatelessWidget {
  const _ClockReading({
    required this.label,
    required this.time,
    required this.date,
    this.highlighted = false,
  });

  final String label;
  final String time;
  final String date;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StorkDetailSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(
            time,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: highlighted ? theme.colorScheme.primary : null,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(date, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(
    this.value, {
    this.numeric = false,
    this.header = false,
    this.abbreviation,
    this.leading,
  });

  final String value;
  final bool numeric;
  final bool header;
  final String? abbreviation;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final text = Text(
      value,
      textAlign: numeric ? TextAlign.end : TextAlign.start,
      style: header
          ? labelStyle
          : theme.textTheme.bodyMedium?.copyWith(
              fontFamily: numeric ? 'monospace' : null,
            ),
    );
    final label = abbreviation == null
        ? text
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              Text(abbreviation!, style: labelStyle),
            ],
          );
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(numeric ? 4 : 0, 7, 0, 7),
      child: leading == null
          ? label
          : Row(
              children: [
                IconTheme.merge(
                  data: const IconThemeData(size: 16),
                  child: leading!,
                ),
                const SizedBox(width: 8),
                Expanded(child: label),
              ],
            ),
    );
  }
}
