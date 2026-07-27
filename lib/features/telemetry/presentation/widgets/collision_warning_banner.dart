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
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();
    final gpsAlt = ref.watch(telemetryProvider.select((t) => t.gpsAltitude));
    final mslVal = ref.watch(resolvedAltitudeProvider.select((a) => a.mslValue));
    final myAlt = mslVal ?? gpsAlt ?? 0.0;
    final heightUnit = settings?.heightUnit ?? AltitudeUnit.meters;
    final l10n = AppLocalizations.of(context)!;
    final unitLabel = heightUnit.getLabel(l10n);

    // Distance calculation
    final distMeters = threatTarget.minDistance ?? 0.0;
    final distKm = distMeters / 1000.0;
    final distStr = distKm < 1.0
        ? '${distMeters.round()}${l10n.altitudeUnitMeters}'
        : '${distKm.toStringAsFixed(1)}${l10n.speedUnitKmH}';

    final tCpaVal = threatTarget.tCpa;
    final tCpaStr = tCpaVal != null ? '${tCpaVal.round()}${l10n.durationSuffix.trim()}' : '--';

    // Altitude difference calculation
    final vertDiffMeters = threatTarget.altitude - myAlt;
    final String altText;
    if (vertDiffMeters.abs() < 15.0) {
      altText = '0 $unitLabel';
    } else {
      final val = heightUnit.convertFromMeters(vertDiffMeters).round();
      final prefix = val > 0 ? '+' : '';
      altText = '$prefix$val $unitLabel';
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
              padding: EdgeInsets.symmetric(
                horizontal: 16.0 * fontScale,
                vertical: 10.0 * fontScale,
              ),
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
                    padding: EdgeInsets.all(6 * fontScale),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 30 * fontScale,
                    ),
                  ),
                  SizedBox(width: 12 * fontScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6 * fontScale,
                                vertical: 2 * fontScale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.collisionWarningLabel,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13 * fontScale,
                                ),
                              ),
                            ),
                            SizedBox(width: 8 * fontScale),
                            Expanded(
                              child: Text(
                                threatTarget.callsign,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17 * fontScale,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6 * fontScale),
                        Row(
                          children: [
                            // Horizontal Distance Icon & Value
                            Icon(
                              Icons.compare_arrows,
                              color: Colors.white70,
                              size: 18 * fontScale,
                            ),
                            SizedBox(width: 3 * fontScale),
                            Text(
                              distStr,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * fontScale,
                              ),
                            ),
                            SizedBox(width: 12 * fontScale),
                            // Time Icon & Value
                            Icon(
                              Icons.timer_outlined,
                              color: Colors.white70,
                              size: 18 * fontScale,
                            ),
                            SizedBox(width: 3 * fontScale),
                            Text(
                              tCpaStr,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * fontScale,
                              ),
                            ),
                            SizedBox(width: 12 * fontScale),
                            // Relative Altitude Icon & Value
                            Icon(
                              Icons.height,
                              color: Colors.white70,
                              size: 18 * fontScale,
                            ),
                            SizedBox(width: 3 * fontScale),
                            Text(
                              altText,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * fontScale,
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
