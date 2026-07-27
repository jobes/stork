import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../settings/domain/models/aircraft_type.dart';
import '../../../../settings/domain/models/altitude_unit.dart';
import '../../../../settings/domain/models/speed_unit.dart';
import '../../../../settings/presentation/extensions/aircraft_type_extension.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../../telemetry/presentation/providers/traffic_provider.dart';
import '../../../../../core/utils/geo_utils.dart';
import 'base_details_dialog.dart';

class TrafficDetailsDialog extends ConsumerStatefulWidget {
  final List<Map<dynamic, dynamic>> features;

  const TrafficDetailsDialog({super.key, required this.features});

  @override
  ConsumerState<TrafficDetailsDialog> createState() =>
      _TrafficDetailsDialogState();
}

class _TrafficDetailsDialogState extends ConsumerState<TrafficDetailsDialog> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ids = widget.features
          .map((f) => f['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      unawaited(
        ref
            .read(trafficProvider.notifier)
            .loadDdbDetailsMultiple(ids)
            .catchError((e) {
              debugPrint('Failed to load DDB details in dialog: $e');
            }),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ids = widget.features
        .map((f) => f['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final trafficList = ref.watch(trafficProvider);
    final matchedAircraft = trafficList
        .where((ac) => ids.contains(ac.id))
        .toList();

    final telemetry = ref.watch(telemetryProvider);
    final myLat = telemetry.latitude;
    final myLon = telemetry.longitude;

    final settings = ref.watch(appSettingsProvider).value;
    final speedUnit = settings?.speedUnit ?? SpeedUnit.kmh;
    final altUnit = settings?.altitudeUnit ?? AltitudeUnit.feet;

    return BaseDetailsDialog(
      titleText: l10n.trafficTitle,
      icon: Icons.airplanemode_active,
      maxWidth: 420,
      child: matchedAircraft.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  l10n.trafficNoDataAvailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                ...matchedAircraft.map((ac) {
                  // Calculate distance
                  double? distMeters;
                  if (myLat != null && myLon != null) {
                    distMeters = GeoUtils.distanceBetween(
                      myLat,
                      myLon,
                      ac.latitude,
                      ac.longitude,
                    );
                  }

                  String distanceLabel = '-';
                  if (distMeters != null) {
                    if (distMeters >= 1000) {
                      distanceLabel =
                          '${(distMeters / 1000).toStringAsFixed(1)} km';
                    } else {
                      distanceLabel = '${distMeters.round()} m';
                    }
                  }

                  // Absolute altitude
                  final absAltVal = altUnit.convertFromMeters(ac.altitude);
                  final absAltLabel =
                      '${absAltVal.round()} ${altUnit.getLabel(l10n)}';

                  // Last seen / inactivity timer
                  final diff = DateTime.now().toUtc().difference(ac.lastSeen);
                  final diffSeconds = diff.inSeconds < 0 ? 0 : diff.inSeconds;
                  String lastSeenLabelVal;
                  if (diffSeconds < 60) {
                    lastSeenLabelVal = '${diffSeconds}s';
                  } else {
                    lastSeenLabelVal =
                        '${diffSeconds ~/ 60}m ${diffSeconds % 60}s';
                  }

                  // Ground speed
                  final gsVal = speedUnit.convertFromMs(ac.groundSpeed);
                  final gsLabel =
                      '${gsVal.round()} ${speedUnit.getLabel(l10n)}';

                  // Vario
                  final vsVal = ac.verticalSpeed;
                  final vsLabel =
                      '${vsVal >= 0.0 ? "+" : ""}${vsVal.toStringAsFixed(1)} ${l10n.varioUnitMs}';

                  // Aircraft Category & Icon details
                  final acType = AircraftType.fromOgnCode(ac.aircraftType);
                  final typeLabel = acType.getLabel(l10n);

                  String nameLabel;
                  String modelLabel;

                  if (ac.isAnonymous) {
                    nameLabel = l10n.anonymousAircraft;
                    modelLabel = typeLabel;
                  } else {
                    nameLabel = ac.registration ?? '';
                    if (nameLabel.isEmpty) {
                      nameLabel = ac.callsign;
                    }
                    if (ac.cn != null && ac.cn!.isNotEmpty) {
                      nameLabel += ' [${ac.cn}]';
                    }
                    if (ac.aircraftModel != null &&
                        ac.aircraftModel!.isNotEmpty) {
                      modelLabel = '${ac.aircraftModel!} • $typeLabel';
                    } else {
                      modelLabel = typeLabel;
                    }
                  }

                  final isFlying = ac.groundSpeed > 1.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isFlying
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.15,
                                      )
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.08,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                acType.assetPath,
                                width: 24,
                                height: 24,
                                color: isFlying
                                    ? null
                                    : (isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600]),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nameLabel,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    modelLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                distanceLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTelemetryColumn(
                              context,
                              l10n.absoluteAltitudeLabel,
                              absAltLabel,
                            ),
                            _buildTelemetryColumn(
                              context,
                              l10n.lastSeenLabel,
                              lastSeenLabelVal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTelemetryColumn(
                              context,
                              l10n.groundSpeedLabel,
                              gsLabel,
                            ),
                            _buildTelemetryColumn(
                              context,
                              l10n.verticalSpeedLabel,
                              vsLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTelemetryColumn(
                              context,
                              l10n.aircraftTypeLabel,
                              typeLabel,
                            ),
                            _buildSourceColumn(
                              context,
                              ac,
                              l10n.trafficSourceLabel,
                            ),
                          ],
                        ),
                        if (ac.isAnonymous) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Text(
                            l10n.anonymousTrafficDesc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildTelemetryColumn(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceColumn(BuildContext context, dynamic ac, String label) {
    final theme = Theme.of(context);
    final Set<String> sources = ac.sources;
    final String activeSource = ac.activeSource;
    final hasOgn = sources.contains('ogn');
    final hasPureTrack = sources.contains('puretrack');

    final List<Widget> badges = [];

    if (hasOgn) {
      final isActive = activeSource == 'ogn';
      badges.add(
        _buildSourceChip(
          context,
          name: 'OGN',
          color: Colors.blue,
          isActive: isActive,
        ),
      );
    }

    if (hasPureTrack) {
      final isActive = activeSource == 'puretrack';
      badges.add(
        _buildSourceChip(
          context,
          name: 'PureTrack',
          color: Colors.purple,
          isActive: isActive,
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: badges),
        ],
      ),
    );
  }

  Widget _buildSourceChip(
    BuildContext context, {
    required String name,
    required MaterialColor color,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isActive
        ? (isDark
              ? color.withValues(alpha: 0.35)
              : color.withValues(alpha: 0.15))
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);

    final textColor = isActive
        ? (isDark ? color.shade200 : color.shade900)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    final borderColor = isActive
        ? (isDark ? color.shade400 : color.shade600)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            name,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
