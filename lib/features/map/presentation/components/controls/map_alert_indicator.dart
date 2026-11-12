import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../../../core/utils/number_formatter.dart';
import '../../../../../core/utils/time_utils.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../settings/domain/models/app_settings.dart';
import '../../../../settings/domain/models/range_thresholds.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../../telemetry/domain/models/flight_alert_record.dart';
import '../../../../telemetry/domain/models/telemetry_instrument.dart';
import '../../../../telemetry/presentation/providers/instrument_status_provider.dart';
import '../../../../telemetry/presentation/providers/temperature_trend_provider.dart';
import '../../providers/map_alert_history_provider.dart';
import '../../providers/map_alerts_provider.dart';
import '../dialogs/base_details_dialog.dart';

const _alertBadgeDiameter = 44.0;

/// Shows the highest priority condition beside the GPS button.
class MapAlertIndicator extends ConsumerStatefulWidget {
  const MapAlertIndicator({super.key});

  @override
  ConsumerState<MapAlertIndicator> createState() => _MapAlertIndicatorState();
}

class _MapAlertIndicatorState extends ConsumerState<MapAlertIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _pulsing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _shouldPulse {
    final severity = ref.read(mapAlertsProvider).firstOrNull?.severity;
    // Honour the OS accessibility setting: a static, still prominent badge is
    // shown instead of the pulse.
    final animate = !MediaQuery.disableAnimationsOf(context);
    final isError =
        severity == MapAlertSeverity.critical ||
        severity == MapAlertSeverity.warning;
    return isError && animate;
  }

  /// Starts or stops the pulse outside of `build`; touching an
  /// [AnimationController] while building would be a side effect in a pure
  /// phase.
  void _syncPulse() {
    final shouldPulse = _shouldPulse;
    if (shouldPulse == _pulsing) return;
    _pulsing = shouldPulse;
    if (shouldPulse) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = ref.watch(
      mapAlertsProvider.select((alerts) => alerts.firstOrNull),
    );
    final l10n = AppLocalizations.of(context)!;
    ref.listen(mapAlertsProvider, (_, _) => _syncPulse());

    final severity = alert?.severity;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final shouldPulse =
        !reduceMotion &&
        (severity == MapAlertSeverity.critical ||
            severity == MapAlertSeverity.warning);
    final label = alert == null
        ? l10n.mapAlertStatusTooltip
        : '${_alertTitle(l10n, alert)}. ${l10n.mapAlertStatusTooltip}';

    return PointerInterceptor(
      child: Semantics(
        button: true,
        liveRegion: alert != null,
        label: label,
        child: SizedBox.square(
          dimension: 48,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: alert == null
                    ? const Center(child: _QuietBadge())
                    : Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          builder: (context, entrance, child) =>
                              Transform.scale(scale: entrance, child: child),
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final t = _controller.value;
                              final wave = (math.sin(t * math.pi * 2) + 1) / 2;
                              return Transform.scale(
                                scale: shouldPulse ? 1 + 0.09 * wave : 1,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (shouldPulse)
                                      _PulseRing(
                                        progress: t,
                                        color: _alertColor(
                                          alert.severity,
                                          Theme.of(context).brightness,
                                        ),
                                      ),
                                    child!,
                                  ],
                                ),
                              );
                            },
                            child: _AlertBadge(
                              severity: alert.severity,
                              icon: mapAlertIcon(alert.kind),
                            ),
                          ),
                        ),
                      ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showMapAlertDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietBadge extends StatelessWidget {
  const _QuietBadge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(
          Icons.shield_outlined,
          size: 19,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.severity, required this.icon});

  final MapAlertSeverity severity;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = _alertColor(severity, brightness);

    return Container(
      width: _alertBadgeDiameter,
      height: _alertBadgeDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: _alertGradient(severity, brightness)),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.75),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: _onAlertColor(severity, brightness), size: 25),
    );
  }
}

/// Expanding ring behind the badge that repeats while the alert is active.
class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.scale(
        scale: 1 + progress * 1.1,
        child: Opacity(
          opacity: (1 - progress) * 0.55,
          child: Container(
            width: _alertBadgeDiameter,
            height: _alertBadgeDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alert palette per severity. Both variants are defined explicitly because
/// the badge must stay readable over light and dark map styles.
Color _alertColor(MapAlertSeverity severity, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return switch (severity) {
    MapAlertSeverity.critical =>
      isDark ? const Color(0xFFFF5252) : const Color(0xFFD50000),
    MapAlertSeverity.warning =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00),
    MapAlertSeverity.info =>
      isDark ? const Color(0xFF82B1FF) : const Color(0xFF1565C0),
  };
}

List<Color> _alertGradient(MapAlertSeverity severity, Brightness brightness) {
  final base = _alertColor(severity, brightness);
  final end = switch (brightness) {
    Brightness.dark => Color.lerp(base, Colors.black, 0.45)!,
    Brightness.light => switch (severity) {
      MapAlertSeverity.critical => const Color(0xFF8E0000),
      MapAlertSeverity.warning => const Color(0xFFBF360C),
      MapAlertSeverity.info => const Color(0xFF0D47A1),
    },
  };
  return [base, end];
}

Color _onAlertColor(MapAlertSeverity severity, Brightness brightness) {
  // Amber needs dark content to keep contrast in dark mode.
  if (brightness == Brightness.dark && severity == MapAlertSeverity.warning) {
    return Colors.black87;
  }
  return Colors.white;
}

void _showMapAlertDialog(BuildContext context) {
  _showStatusDialog(context, const _MapAlertDialog());
}

void showRecordedFlightAlerts(
  BuildContext context,
  Future<List<FlightAlertRecord>> records,
) {
  _showStatusDialog(
    context,
    FutureBuilder<List<FlightAlertRecord>>(
      future: records,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        final data = snapshot.data;
        if (data != null) {
          return _MapAlertHistoryDialog(
            recordedEntries: [
              for (final record in data)
                if (_recordedEntry(record)
                    case final MapAlertHistoryEntry entry)
                  entry,
            ],
          );
        }
        return BaseDetailsDialog(
          titleText: l10n.mapAlertHistoryTitle,
          icon: Icons.history,
          child: snapshot.hasError
              ? Text(l10n.flightRecordsLoadError)
              : const Center(
                  heightFactor: 1,
                  child: CircularProgressIndicator(),
                ),
        );
      },
    ),
  );
}

MapAlertHistoryEntry? _recordedEntry(FlightAlertRecord record) {
  final kind = MapAlertKind.values.asNameMap()[record.kind];
  if (kind == null) return null;
  final threshold = ThresholdState.values.asNameMap()[record.threshold];
  return MapAlertHistoryEntry(
    id: record.episodeId,
    alert: MapAlert(
      kind: kind,
      since: record.startedAt,
      instrumentIssue: threshold == null
          ? null
          : (
              state: threshold,
              unavailable: record.unavailable,
              channel: record.channel,
            ),
    ),
    endedAt: record.endedAt,
  );
}

void _showStatusDialog(BuildContext context, Widget dialog) {
  final container = ProviderScope.containerOf(context, listen: false);
  showDialog<void>(
    context: context,
    builder: (_) =>
        UncontrolledProviderScope(container: container, child: dialog),
  );
}

class _MapAlertDialog extends ConsumerWidget {
  const _MapAlertDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(mapAlertsProvider);
    final hasHistory = ref.watch(
      mapAlertHistoryProvider.select((entries) => entries.isNotEmpty),
    );
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primary = alerts.firstOrNull;
    final multiple = alerts.length > 1;
    final color = primary == null
        ? theme.colorScheme.primary
        : _alertColor(primary.severity, theme.brightness);

    return BaseDetailsDialog(
      titleText: switch (primary) {
        null => l10n.mapAlertAllGoodTitle,
        _ when multiple => l10n.mapAlertActiveCount(alerts.length),
        _ => _alertTitle(l10n, primary),
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          primary == null ? Icons.shield_outlined : mapAlertIcon(primary.kind),
          color: color,
          size: 24,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHistory) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  _showStatusDialog(context, const _MapAlertHistoryDialog()),
              icon: const Icon(Icons.history),
              label: Text(l10n.mapAlertHistoryTitle),
            ),
            const SizedBox(height: 12),
          ],
          if (primary == null)
            Text(l10n.mapAlertAllGoodBody, style: theme.textTheme.bodyMedium),
          for (final (index, alert) in alerts.indexed) ...[
            if (index > 0) const Divider(height: 32),
            if (multiple) ...[
              Row(
                children: [
                  Icon(
                    mapAlertIcon(alert.kind),
                    color: _alertColor(alert.severity, theme.brightness),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _alertTitle(l10n, alert),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _AlertDetails(key: ValueKey(alert.kind), alert: alert),
          ],
        ],
      ),
    );
  }
}

class _MapAlertHistoryDialog extends ConsumerWidget {
  const _MapAlertHistoryDialog({this.recordedEntries});

  final List<MapAlertHistoryEntry>? recordedEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MapAlertHistoryEntry> entries =
        recordedEntries ?? ref.watch(mapAlertHistoryProvider);
    final settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BaseDetailsDialog(
      titleText: l10n.mapAlertHistoryTitle,
      icon: Icons.history,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty) Text(l10n.flightNoRecordedAlerts),
          for (final (index, entry) in entries.indexed) ...[
            if (index > 0) const Divider(height: 28),
            Row(
              children: [
                Icon(
                  mapAlertIcon(entry.alert.kind),
                  color: _alertColor(entry.alert.severity, theme.brightness),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _alertTitle(l10n, entry.alert),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _alertBody(l10n, entry.alert),
              style: theme.textTheme.bodyMedium,
            ),
            if ((entry.peak, entry.alert.kind.instrument) case (
              final double peak,
              final TelemetryInstrument instrument,
            ))
              Text(
                l10n.mapAlertHistoryPeak(
                  _formatReading(context, settings, instrument, peak),
                ),
              ),
            Text(
              _historyTiming(context, l10n, entry),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _historyTiming(
    BuildContext context,
    AppLocalizations l10n,
    MapAlertHistoryEntry entry,
  ) {
    final started = entry.alert.since;
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(started.toLocal());
    final start = '$date · ${_formatTime(context, started)}';
    final end = entry.endedAt;
    if (end == null) {
      return recordedEntries == null
          ? l10n.mapAlertSince(start)
          : l10n.flightAlertNoRecordedEnd(start);
    }
    return l10n.mapAlertHistoryTiming(
      start,
      _formatTime(context, end),
      end.difference(started).toHMSString(),
    );
  }
}

class _AlertDetails extends ConsumerWidget {
  const _AlertDetails({super.key, required this.alert});

  final MapAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final instrument = alert.kind.instrument;
    final readings =
        instrument == null || instrument == TelemetryInstrument.radio
        ? const <InstrumentAlertReading>[]
        : ref.watch(instrumentStatusProvider(instrument)).alertReadings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (readings.isEmpty)
          Text(_alertBody(l10n, alert), style: theme.textTheme.bodyMedium)
        else
          for (final (index, reading) in readings.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            _InstrumentReadingDetails(
              instrument: instrument!,
              reading: reading,
            ),
          ],
        const SizedBox(height: 14),
        Text(
          l10n.mapAlertSince(_formatTime(context, alert.since)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InstrumentReadingDetails extends ConsumerWidget {
  const _InstrumentReadingDetails({
    required this.instrument,
    required this.reading,
  });

  final TelemetryInstrument instrument;
  final InstrumentAlertReading reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();
    final channel = reading.issue.channel;
    final change = ref.watch(
      temperatureTrendProvider.select(
        (changes) => changes[(instrument: instrument, channel: channel)],
      ),
    );
    final value = reading.value;
    final limit = reading.limit;
    final critical =
        reading.issue.state == ThresholdState.minError ||
        reading.issue.state == ThresholdState.maxError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (channel != null)
          Text(
            l10n.mapAlertInstrumentCylinder(channel),
            style: text.titleSmall,
          ),
        Text(
          _instrumentDescription(l10n, reading.issue),
          style: text.bodyMedium,
        ),
        if (value != null &&
            value.isFinite &&
            limit != null &&
            limit.isFinite) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                l10n.mapAlertMeasured(
                  _formatReading(context, settings, instrument, value),
                ),
                style: text.titleSmall,
              ),
              Text(
                critical
                    ? l10n.mapAlertCriticalLimit(
                        _formatReading(context, settings, instrument, limit),
                      )
                    : l10n.mapAlertWarningLimit(
                        _formatReading(context, settings, instrument, limit),
                      ),
                style: text.bodyMedium,
              ),
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: 4),
            _buildTrend(context, l10n, settings, change),
          ],
        ],
      ],
    );
  }

  Widget _buildTrend(
    BuildContext context,
    AppLocalizations l10n,
    AppSettings settings,
    double change,
  ) {
    final unit = settings.temperatureUnit;
    final delta = unit.convertFromKelvin(change) - unit.convertFromKelvin(0);
    final amount =
        '${context.formatNumber(delta.abs(), 1)} ${unit.getAbbreviation()}';
    final (icon, label) = switch (delta) {
      > 0.05 => (Icons.trending_up, l10n.mapAlertTemperatureRising(amount)),
      < -0.05 => (Icons.trending_down, l10n.mapAlertTemperatureFalling(amount)),
      _ => (Icons.trending_flat, l10n.mapAlertTemperatureSteady),
    };
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(label)),
      ],
    );
  }
}

String _formatReading(
  BuildContext context,
  AppSettings settings,
  TelemetryInstrument instrument,
  double value,
) {
  final (converted, unit, decimals) = switch (instrument) {
    TelemetryInstrument.oilTemperature ||
    TelemetryInstrument.cylinderTemperature ||
    TelemetryInstrument.exhaustTemperature => (
      settings.temperatureUnit.convertFromKelvin(value),
      settings.temperatureUnit.getAbbreviation(),
      1,
    ),
    TelemetryInstrument.oilPressure => (
      settings.pressureUnit.convertFromKpa(value),
      settings.pressureUnit.getAbbreviation(),
      2,
    ),
    TelemetryInstrument.speed => (
      settings.speedUnit.convertFromMs(value),
      settings.speedUnit.getAbbreviation(AppLocalizations.of(context)!),
      1,
    ),
    TelemetryInstrument.fuel => (value, '%', 1),
    TelemetryInstrument.rpm => (value, 'RPM', 0),
    TelemetryInstrument.radio => (value, '', 0),
  };
  return '${context.formatNumber(converted, decimals)} $unit'.trimRight();
}

IconData mapAlertIcon(MapAlertKind kind) {
  return switch (kind) {
    MapAlertKind.collisionThreat => Icons.warning_amber_rounded,
    MapAlertKind.oilTemperature ||
    MapAlertKind.cylinderTemperature ||
    MapAlertKind.exhaustTemperature => Icons.thermostat,
    MapAlertKind.oilPressure => Icons.water_drop_outlined,
    MapAlertKind.fuelLevel => Icons.local_gas_station_outlined,
    MapAlertKind.engineRpm || MapAlertKind.flightSpeed => Icons.speed,
    MapAlertKind.radio => Icons.radio,
    MapAlertKind.gpsPermissionDenied ||
    MapAlertKind.locationServicesDisabled ||
    MapAlertKind.gpsStreamError ||
    MapAlertKind.gpsFixLost ||
    MapAlertKind.gpsNoFix => Icons.gps_off,
    MapAlertKind.droneCanGpsFallback => Icons.gps_not_fixed,
    MapAlertKind.telemetryLinkLost => Icons.sensors_off,
    MapAlertKind.telemetryStale => Icons.hourglass_disabled,
    MapAlertKind.altitudeUnavailable => Icons.height,
    MapAlertKind.altitudeSourceChanged => Icons.height,
    MapAlertKind.trafficSourceOffline => Icons.wifi_tethering_off,
    MapAlertKind.internetUnavailable => Icons.wifi_off,
    MapAlertKind.airspaceDataUnavailable => Icons.layers_clear,
    MapAlertKind.terrainUnavailable => Icons.landscape_outlined,
    MapAlertKind.radarUnavailable ||
    MapAlertKind.radarHistoryUnavailable => Icons.thunderstorm_outlined,
    MapAlertKind.offlineMapsError => Icons.map_outlined,
    MapAlertKind.mapStyleUnavailable => Icons.map_outlined,
  };
}

String _alertTitle(AppLocalizations l10n, MapAlert alert) {
  final kind = alert.kind;
  final issue = alert.instrumentIssue;
  if (issue != null) {
    final label = _instrumentLabel(l10n, kind);
    if (issue.unavailable) return l10n.mapAlertInstrumentUnavailable(label);
    if (kind == MapAlertKind.radio) return l10n.mapAlertRadioFault;
    if (alert.isEngineOverheating) {
      return l10n.mapAlertEngineOverheat(label);
    }
    return switch (issue.state) {
      ThresholdState.minError ||
      ThresholdState.minWarning => l10n.mapAlertInstrumentLow(label),
      _ => l10n.mapAlertInstrumentHigh(label),
    };
  }
  return switch (kind) {
    MapAlertKind.collisionThreat => l10n.mapAlertCollisionTitle,
    MapAlertKind.mapStyleUnavailable => l10n.mapAlertMapStyleTitle,
    MapAlertKind.gpsPermissionDenied => l10n.mapAlertGpsPermissionTitle,
    MapAlertKind.locationServicesDisabled => l10n.mapAlertLocationServicesTitle,
    MapAlertKind.gpsStreamError => l10n.mapAlertGpsStreamTitle,
    MapAlertKind.gpsFixLost => l10n.mapAlertGpsLostTitle,
    MapAlertKind.gpsNoFix => l10n.mapAlertGpsNoFixTitle,
    MapAlertKind.telemetryLinkLost => l10n.mapAlertTelemetryLinkTitle,
    MapAlertKind.telemetryStale => l10n.mapAlertTelemetryStaleTitle,
    MapAlertKind.altitudeUnavailable => l10n.mapAlertAltitudeUnavailableTitle,
    MapAlertKind.trafficSourceOffline => l10n.mapAlertTrafficOfflineTitle,
    MapAlertKind.internetUnavailable => l10n.mapAlertInternetTitle,
    MapAlertKind.airspaceDataUnavailable => l10n.mapAlertAirspaceTitle,
    MapAlertKind.terrainUnavailable => l10n.mapAlertTerrainTitle,
    MapAlertKind.offlineMapsError => l10n.mapAlertOfflineMapsTitle,
    MapAlertKind.droneCanGpsFallback => l10n.mapAlertDroneCanGpsTitle,
    MapAlertKind.altitudeSourceChanged => l10n.mapAlertAltitudeSourceTitle,
    MapAlertKind.radarUnavailable => l10n.radarUnavailable,
    MapAlertKind.radarHistoryUnavailable => l10n.radarHistoryUnavailable,
    _ => _instrumentLabel(l10n, kind),
  };
}

String _alertBody(AppLocalizations l10n, MapAlert alert) {
  final kind = alert.kind;
  final issue = alert.instrumentIssue;
  if (issue != null) {
    final description = kind == MapAlertKind.radio && !issue.unavailable
        ? l10n.mapAlertRadioFaultBody
        : _instrumentDescription(l10n, issue);
    final channel = issue.channel;
    return channel == null
        ? description
        : '${l10n.mapAlertInstrumentCylinder(channel)}. $description';
  }
  return switch (kind) {
    MapAlertKind.collisionThreat => l10n.mapAlertCollisionBody,
    MapAlertKind.mapStyleUnavailable => l10n.mapAlertMapStyleBody,
    MapAlertKind.gpsPermissionDenied => l10n.mapAlertGpsPermissionBody,
    MapAlertKind.locationServicesDisabled => l10n.mapAlertLocationServicesBody,
    MapAlertKind.gpsStreamError => l10n.mapAlertGpsStreamBody,
    MapAlertKind.gpsFixLost => l10n.mapAlertGpsLostBody,
    MapAlertKind.gpsNoFix => l10n.mapAlertGpsNoFixBody,
    MapAlertKind.telemetryLinkLost => l10n.mapAlertTelemetryLinkBody,
    MapAlertKind.telemetryStale => l10n.mapAlertTelemetryStaleBody,
    MapAlertKind.altitudeUnavailable => l10n.mapAlertAltitudeUnavailableBody,
    MapAlertKind.trafficSourceOffline => l10n.mapAlertTrafficOfflineBody,
    MapAlertKind.internetUnavailable => l10n.mapAlertInternetBody,
    MapAlertKind.airspaceDataUnavailable => l10n.mapAlertAirspaceBody,
    MapAlertKind.terrainUnavailable => l10n.mapAlertTerrainBody,
    MapAlertKind.offlineMapsError => l10n.mapAlertOfflineMapsBody,
    MapAlertKind.droneCanGpsFallback => l10n.mapAlertDroneCanGpsBody,
    MapAlertKind.altitudeSourceChanged => l10n.mapAlertAltitudeSourceBody,
    MapAlertKind.radarUnavailable => l10n.mapAlertRadarBody,
    MapAlertKind.radarHistoryUnavailable => l10n.mapAlertRadarHistoryBody,
    _ => l10n.mapAlertInstrumentUnavailableBody,
  };
}

String _instrumentDescription(AppLocalizations l10n, InstrumentIssue issue) {
  if (issue.unavailable) return l10n.mapAlertInstrumentUnavailableBody;
  return switch (issue.state) {
    ThresholdState.minWarning => l10n.mapAlertInstrumentLowWarningBody,
    ThresholdState.maxWarning => l10n.mapAlertInstrumentHighWarningBody,
    ThresholdState.minError => l10n.mapAlertInstrumentLowErrorBody,
    _ => l10n.mapAlertInstrumentHighErrorBody,
  };
}

String _instrumentLabel(AppLocalizations l10n, MapAlertKind kind) =>
    switch (kind) {
      MapAlertKind.oilTemperature => l10n.oilTemperature,
      MapAlertKind.cylinderTemperature => l10n.cylinderHeadTemperatureShort,
      MapAlertKind.exhaustTemperature => l10n.egtTemperature,
      MapAlertKind.oilPressure => l10n.oilPressure,
      MapAlertKind.engineRpm => l10n.engineRpm,
      MapAlertKind.fuelLevel => l10n.fuelTankStatus,
      MapAlertKind.flightSpeed => l10n.flightSpeed,
      MapAlertKind.radio => l10n.mapAlertRadioLabel,
      _ => throw ArgumentError.value(kind, 'kind'),
    };

String _formatTime(BuildContext context, DateTime time) {
  final local = time.toLocal();
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
