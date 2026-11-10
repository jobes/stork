import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/stork_detail_surface.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/flight_duration_provider.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

class FlightTimeDetailsDialog extends ConsumerWidget {
  const FlightTimeDetailsDialog({super.key});

  String _formatStartTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return AppLocalizations.of(context)!.placeholderDash;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightSummary = ref.watch(flightDurationProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final distanceKm = flightSummary.distanceMeters / 1000.0;

    return BaseDetailsDialog(
      titleText: l10n.flightDetailsTitle,
      icon: Icons.flight_takeoff,
      maxWidth: 450,
      child: StorkDetailSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Time Row
            _buildDetailRow(
              icon: Icons.today,
              iconColor: Colors.orangeAccent,
              label: l10n.flightStartTime,
              value: _formatStartTime(context, flightSummary.startTime),
              context: context,
            ),
            const Divider(height: 24),
            // Duration Row
            _buildDetailRow(
              icon: Icons.access_time,
              iconColor: scheme.primary,
              label: l10n.flightDuration,
              value: flightSummary.duration.toHMSString(),
              context: context,
            ),
            const Divider(height: 24),
            // Distance Row
            _buildDetailRow(
              icon: Icons.map_outlined,
              iconColor: Colors.green,
              label: l10n.flightDistance,
              value: '${context.formatNumber(distanceKm, 2)} km',
              context: context,
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
    required BuildContext context,
  }) {
    final scheme = Theme.of(context).colorScheme;
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
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
