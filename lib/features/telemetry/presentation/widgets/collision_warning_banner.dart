import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../map/presentation/components/dialogs/traffic_details_dialog.dart';
import '../providers/traffic_provider.dart';
import '../providers/agl_provider.dart';

class CollisionWarningBanner extends ConsumerWidget {
  const CollisionWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threatTarget = ref.watch(activeCollisionAlertProvider);
    if (threatTarget == null) return const SizedBox.shrink();

    final settings = ref.watch(appSettingsProvider).value;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();
    final myAlt = ref.watch(resolvedAltitudeProvider.select((a) => a.mslValue));
    final heightUnit = settings?.heightUnit ?? AltitudeUnit.meters;
    final l10n = AppLocalizations.of(context)!;
    final unitLabel = heightUnit.getLabel(l10n);

    const unavailable = '—';
    final distance = threatTarget.minDistance;
    final distanceText = switch (distance) {
      null => unavailable,
      < 1000 =>
        '${context.formatNumber(distance, 0)} ${l10n.altitudeUnitMeters}',
      _ => '${context.formatNumber(distance / 1000, 1)} km',
    };

    final time = threatTarget.tCpa;
    final timeText = time == null
        ? unavailable
        : '${context.formatNumber(time, 0)}${l10n.durationSuffix}';

    final altitudeText = myAlt == null || !threatTarget.altitudeValid
        ? unavailable
        : _formatAltitudeDifference(
            context,
            threatTarget.altitude - myAlt,
            heightUnit,
            unitLabel,
          );

    final headingScale = fontScale.clamp(0.5, 2.0);
    final labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 12 * fontScale.clamp(0.5, 1.5),
    );
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 16 * fontScale,
      fontWeight: FontWeight.bold,
    );
    final headingStyle = valueStyle.copyWith(fontSize: 16 * headingScale);

    Widget metric(String label, String value) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade900,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => TrafficDetailsDialog(
                  features: [
                    {
                      'id': threatTarget.id,
                      'properties': {
                        'id': threatTarget.id,
                        'heading': threatTarget.track,
                        'title': threatTarget.callsign,
                        'altitude': threatTarget.altitude,
                        'groundSpeed': threatTarget.groundSpeed,
                        'verticalSpeed': threatTarget.verticalSpeed,
                      },
                    },
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                gradient: LinearGradient(
                  colors: [Colors.red.shade900, Colors.red.shade700],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20 * headingScale,
                      ),
                      Text(l10n.collisionWarningLabel, style: headingStyle),
                      Text(
                        threatTarget.callsign,
                        style: headingStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      metric(l10n.collisionMinSeparation, distanceText),
                      metric(l10n.collisionTimeToClosest, timeText),
                      metric(l10n.collisionAltitudeDifference, altitudeText),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatAltitudeDifference(
    BuildContext context,
    double meters,
    AltitudeUnit unit,
    String unitLabel,
  ) {
    if (meters.abs() < 15) return '0 $unitLabel';
    final value = unit.convertFromMeters(meters).roundToDouble();
    final sign = value > 0 ? '+' : '';
    return '$sign${context.formatNumber(value, 0)} $unitLabel';
  }
}
