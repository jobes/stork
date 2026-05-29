import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cannelloni_service_io.dart'
    if (dart.library.html) '../../../../core/services/cannelloni_service_stub.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/range_thresholds.dart';
import '../../../settings/domain/speed_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';

class SpeedDetailsDialog extends ConsumerWidget {
  const SpeedDetailsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final isConnected = ref.watch(cannelloniServiceProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final thresholds = settings?.flightSpeedThresholds ?? const RangeThresholds.raw();
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final speedUnit = settings?.speedUnit ?? SpeedUnit.kmh;
    final unitLabel = speedUnit.getAbbreviation(l10n);

    // Speed values conversion
    final double? ias = telemetry.indicatedAirSpeed != null
        ? speedUnit.convertFromMs(telemetry.indicatedAirSpeed!)
        : null;
    final double? gs = telemetry.groundSpeed != null
        ? speedUnit.convertFromMs(telemetry.groundSpeed!)
        : null;

    final bool isIasAvailable = telemetry.indicatedAirSpeed != null;
    final bool isGsAvailable = telemetry.groundSpeed != null;

    // Evaluated threshold for active speeds
    ThresholdState iasState = ThresholdState.inactive;
    if (isIasAvailable) {
      iasState = thresholds.evaluate(telemetry.indicatedAirSpeed!);
    }

    ThresholdState gsState = ThresholdState.inactive;
    if (isGsAvailable) {
      gsState = thresholds.evaluate(telemetry.groundSpeed!);
    }

    Color getThresholdColor(ThresholdState state) {
      switch (state) {
        case ThresholdState.inactive:
          return Colors.grey;
        case ThresholdState.operational:
          return Colors.green;
        case ThresholdState.minWarning:
        case ThresholdState.maxWarning:
          return Colors.orange;
        case ThresholdState.minError:
        case ThresholdState.maxError:
          return Colors.red;
      }
    }

    String getThresholdLabel(ThresholdState state) {
      switch (state) {
        case ThresholdState.inactive:
          return l10n.inactiveThreshold;
        case ThresholdState.operational:
          return l10n.operationalThreshold;
        case ThresholdState.minWarning:
          return l10n.minWarningThreshold;
        case ThresholdState.maxWarning:
          return l10n.maxWarningThreshold;
        case ThresholdState.minError:
          return l10n.minErrorThreshold;
        case ThresholdState.maxError:
          return l10n.maxErrorThreshold;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withAlpha(190)
                  : Colors.white.withAlpha(225),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.speed,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.speedDetailsTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Speed Cards (IAS and GS)
                Row(
                  children: [
                    // IAS Card
                    Expanded(
                      child: _buildSpeedCard(
                        context: context,
                        title: "IAS",
                        subTitle: l10n.indicatedAirSpeedShort,
                        value: ias != null ? ias.toStringAsFixed(0) : '---',
                        unit: unitLabel,
                        isAvailable: isIasAvailable,
                        state: iasState,
                        thresholdColor: getThresholdColor(iasState),
                        thresholdLabel: getThresholdLabel(iasState),
                        isDark: isDark,
                        l10n: l10n,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // GS Card
                    Expanded(
                      child: _buildSpeedCard(
                        context: context,
                        title: "GS",
                        subTitle: l10n.groundSpeedShort,
                        value: gs != null ? gs.toStringAsFixed(0) : '---',
                        unit: unitLabel,
                        isAvailable: isGsAvailable,
                        state: gsState,
                        thresholdColor: getThresholdColor(gsState),
                        thresholdLabel: getThresholdLabel(gsState),
                        isDark: isDark,
                        l10n: l10n,
                        sourceLabel: isGsAvailable
                            ? (telemetry.isGpsDroneCan
                                ? l10n.gpsSourceDroneCan
                                : l10n.gpsSourceInternal)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GPS & Satellites Section Header
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    l10n.gpsAccuracy,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),

                // GPS Details Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(15)
                        : Colors.black.withAlpha(10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Satellite Count Row
                      _buildDetailRow(
                        icon: Icons.satellite_alt,
                        iconColor: telemetry.gpsSatelliteCount != null && telemetry.gpsSatelliteCount! >= 6
                            ? Colors.green
                            : (telemetry.gpsSatelliteCount != null && telemetry.gpsSatelliteCount! > 0
                                ? Colors.orange
                                : Colors.red),
                        label: l10n.satelliteCount,
                        value: telemetry.gpsSatelliteCount != null
                            ? '${telemetry.gpsSatelliteCount}'
                            : l10n.valueNotAvailable,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      // Horizontal Accuracy Row
                      _buildDetailRow(
                        icon: Icons.gps_fixed,
                        iconColor: Colors.blueAccent,
                        label: l10n.horizontalAccuracy,
                        value: telemetry.gpsHorizontalAccuracy != null
                            ? '± ${telemetry.gpsHorizontalAccuracy!.toStringAsFixed(1)} m'
                            : l10n.valueNotAvailable,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      // Vertical Accuracy Row
                      _buildDetailRow(
                        icon: Icons.height,
                        iconColor: Colors.blueAccent,
                        label: l10n.verticalAccuracy,
                        value: telemetry.gpsVerticalAccuracy != null
                            ? '± ${telemetry.gpsVerticalAccuracy!.toStringAsFixed(1)} m'
                            : l10n.valueNotAvailable,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Connected status summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withAlpha(30)
                        : Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected ? Colors.green.withAlpha(60) : Colors.orange.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: isConnected ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isConnected ? "Connected to Cannelloni Telemetry Gateway" : "Offline Device GPS Mode",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green : Colors.orange,
                          ),
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
    );
  }

  Widget _buildSpeedCard({
    required BuildContext context,
    required String title,
    required String subTitle,
    required String value,
    required String unit,
    required bool isAvailable,
    required ThresholdState state,
    required Color thresholdColor,
    required String thresholdLabel,
    required bool isDark,
    required AppLocalizations l10n,
    String? sourceLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(20)
            : Colors.black.withAlpha(12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable ? thresholdColor.withAlpha(100) : Colors.grey.withAlpha(50),
          width: 1.5,
        ),
        boxShadow: isAvailable && state != ThresholdState.inactive
            ? [
                BoxShadow(
                  color: thresholdColor.withAlpha(30),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isAvailable ? thresholdColor : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Availability badge
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 12,
                color: isAvailable ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isAvailable ? l10n.valueYes : l10n.valueNo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (isAvailable && state != ThresholdState.inactive) ...[
            const SizedBox(height: 4),
            Text(
              thresholdLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: thresholdColor,
              ),
            ),
          ],
          if (isAvailable && sourceLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sourceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
