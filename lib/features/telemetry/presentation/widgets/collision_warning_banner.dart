import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../map/presentation/components/dialogs/traffic_details_dialog.dart';
import '../providers/ogn_traffic_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/agl_provider.dart';

class CollisionWarningBanner extends ConsumerWidget {
  const CollisionWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threatTarget = ref.watch(activeCollisionAlertProvider);
    if (threatTarget == null) return const SizedBox.shrink();

    final settings = ref.watch(appSettingsProvider).value;
    final telemetry = ref.watch(telemetryProvider);
    final resolvedAlt = ref.watch(resolvedAltitudeProvider).mslValue;
    final myAlt = resolvedAlt ?? telemetry.gpsAltitude ?? 0.0;
    final altUnit = settings?.altitudeUnit ?? AltitudeUnit.feet;
    final l10n = AppLocalizations.of(context)!;

    final clockPos = threatTarget.clockPosition ?? 12;
    final clockText = l10n.clockPositionFormat(clockPos.toString());

    // Distance calculation
    final distMeters = threatTarget.minDistance ?? 0.0;
    final distKm = distMeters / 1000.0;
    final distStr = distKm < 1.0
        ? '${(distMeters).round()}m'
        : '${distKm.toStringAsFixed(1)}km';

    final tCpaSeconds = (threatTarget.tCpa ?? 0.0).round();
    final cpaText = '$distStr | ${tCpaSeconds}s';

    // Altitude difference calculation
    final vertDiffMeters = threatTarget.altitude - myAlt;
    final String altText;
    if (vertDiffMeters.abs() < 15.0) {
      altText = l10n.sameAltLabel;
    } else if (vertDiffMeters >= 15.0) {
      final val = altUnit.convertFromMeters(vertDiffMeters).round();
      final unitLabel = altUnit.getMslLabel(l10n);
      altText = l10n.aboveAltLabel('$val $unitLabel');
    } else {
      final val = altUnit.convertFromMeters(vertDiffMeters.abs()).round();
      final unitLabel = altUnit.getMslLabel(l10n);
      altText = l10n.belowAltLabel('$val $unitLabel');
    }

    return SafeArea(
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
                    }
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade900,
                    Colors.red.shade700,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                clockText,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              threatTarget.callsign,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cpaText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              altText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
}
