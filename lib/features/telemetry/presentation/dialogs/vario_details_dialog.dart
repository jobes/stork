import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/vario_state.dart';
import '../providers/vario_provider.dart';
import '../providers/telemetry_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

class VarioDetailsDialog extends ConsumerWidget {
  const VarioDetailsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vario = ref.watch(varioProvider);
    final telemetry = ref.watch(telemetryProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Source info — switch expression returning a record
    final (sourceText, sourceIcon, sourceColor) = switch (vario.source) {
      VarioSource.baro => (l10n.varioSourceBaro, Icons.compress, Colors.green),
      VarioSource.gps => (
        l10n.varioSourceGps,
        Icons.satellite_alt,
        Colors.blueAccent,
      ),
      VarioSource.none => (
        l10n.varioSourceNone,
        Icons.report_problem_outlined,
        Colors.grey,
      ),
    };

    // Trend arrow — switch expression on verticalSpeed returning a record
    final (trendIcon, trendColor) = switch (vario.verticalSpeed) {
      null => (Icons.remove, Colors.grey),
      final v when v.abs() < 0.05 => (Icons.arrow_forward, Colors.grey),
      final v when v > 0.5 => (Icons.arrow_upward, Colors.green),
      final v when v < -0.5 => (Icons.arrow_downward, Colors.red),
      _ => (Icons.arrow_forward, Colors.grey),
    };

    return BaseDetailsDialog(
      titleText: l10n.varioDetailsTitle,
      icon: Icons.trending_up,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current value card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 32),
                const SizedBox(width: 16),
                Text(
                  l10n.varioCurrentValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const Spacer(),
                if (vario.verticalSpeed != null) ...[
                  Text(
                    () {
                      final v = vario.verticalSpeed!;
                      if (v.abs() < 0.05) return '0.0';
                      return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}';
                    }(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.varioUnitMs,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ] else ...[
                  Text(
                    l10n.placeholderDash,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.varioUnitMs,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Source section
          Text(
            l10n.varioSourceLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
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
            child: Row(
              children: [
                Icon(sourceIcon, color: sourceColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sourceText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Source details
          if (vario.source == VarioSource.baro) ...[
            _buildDetailSection(
              isDark: isDark,
              children: [
                _buildDetailRow(
                  icon: Icons.air,
                  iconColor: Colors.blueAccent,
                  label: l10n.varioAirPressure,
                  value: telemetry.airPressure != null
                      ? '${(telemetry.airPressure! / 100).toStringAsFixed(1)} hPa'
                      : l10n.valueNotAvailable,
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  icon: Icons.speed,
                  iconColor: Colors.orange,
                  label: l10n.varioQnhUsed,
                  value:
                      '${ref.watch(appSettingsProvider).value?.qnh.toStringAsFixed(2) ?? '1013.25'} hPa',
                  isDark: isDark,
                ),
              ],
            ),
          ] else if (vario.source == VarioSource.gps) ...[
            _buildDetailSection(
              isDark: isDark,
              children: [
                _buildDetailRow(
                  icon: Icons.height,
                  iconColor: Colors.blueAccent,
                  label: l10n.verticalAccuracy,
                  value: telemetry.gpsVerticalAccuracy != null
                      ? '± ${telemetry.gpsVerticalAccuracy!.toStringAsFixed(1)} m'
                      : l10n.valueNotAvailable,
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  icon: Icons.satellite_alt,
                  iconColor:
                      telemetry.gpsSatelliteCount != null &&
                          telemetry.gpsSatelliteCount! >= 6
                      ? Colors.green
                      : Colors.orange,
                  label: l10n.satelliteCount,
                  value: telemetry.gpsSatelliteCount != null
                      ? '${telemetry.gpsSatelliteCount}'
                      : l10n.valueNotAvailable,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(children: children),
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
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
