import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../telemetry/presentation/providers/flight_duration_provider.dart';
import 'base_details_dialog.dart';

class FlightTimeDetailsDialog extends ConsumerWidget {
  const FlightTimeDetailsDialog({super.key});

  String _formatStartTime(DateTime? dateTime) {
    if (dateTime == null) return '---';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightSummary = ref.watch(flightDurationProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final distanceKm = flightSummary.distanceMeters / 1000.0;

    return BaseDetailsDialog(
      titleText: l10n.flightDetailsTitle,
      icon: Icons.flight_takeoff,
      maxWidth: 450,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Time Row
            _buildDetailRow(
              icon: Icons.today,
              iconColor: Colors.orangeAccent,
              label: l10n.flightStartTime,
              value: _formatStartTime(flightSummary.startTime),
              isDark: isDark,
            ),
            const Divider(height: 24),
            // Duration Row
            _buildDetailRow(
              icon: Icons.access_time,
              iconColor: Colors.blueAccent,
              label: l10n.flightDuration,
              value: flightSummary.duration.toHMSString(),
              isDark: isDark,
            ),
            const Divider(height: 24),
            // Distance Row
            _buildDetailRow(
              icon: Icons.map_outlined,
              iconColor: Colors.green,
              label: l10n.flightDistance,
              value: '${distanceKm.toStringAsFixed(2)} km',
              isDark: isDark,
            ),
          ],
        ),
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
