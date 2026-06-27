import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/notam.dart';
import '../../providers/notams_provider.dart';
import 'base_details_dialog.dart';

class NotamDetailsDialog extends ConsumerWidget {
  final List<Notam> notams;

  const NotamDetailsDialog({super.key, required this.notams});

  String _formatDateTime(DateTime dt, String locale) {
    try {
      final localDt = dt.toLocal();
      return DateFormat.yMd(locale).add_Hm().format(localDt);
    } catch (_) {
      return dt.toIso8601String();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // [notams] represents the NOTAMs associated with the tapped map features.
    // [visibleNotams] filters these to only include those currently active and not hidden
    // by the user (tracked in [notamsProvider]), allowing the dialog to reactively update
    // when a NOTAM is hidden.
    final allNotams = ref.watch(notamsProvider).value ?? [];
    final visibleNotams = notams
        .where((n) => allNotams.any((an) => an.id == n.id))
        .toList();

    final String titleText = visibleNotams.length == 1
        ? '${l10n.notamDetails} ${visibleNotams.first.id}'
        : '${l10n.notamsTitle} (${visibleNotams.length})';

    return BaseDetailsDialog(
      titleText: titleText,
      icon: Icons.warning_amber_rounded,
      maxHeight: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < visibleNotams.length; i++) ...[
            if (i > 0) ...[const Divider(height: 32)],
            _buildNotamItem(
              context,
              ref,
              visibleNotams[i],
              visibleNotams,
              isDark,
              l10n,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotamItem(
    BuildContext context,
    WidgetRef ref,
    Notam notam,
    List<Notam> visibleNotams,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIR badge & ID info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (visibleNotams.length > 1)
              Text(
                notam.id,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              )
            else
              const SizedBox.shrink(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withAlpha(100)),
              ),
              child: Text(
                '${l10n.notamFir}: ${notam.fir}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Title / Feature Name
        if (notam.featureName.isNotEmpty) ...[
          Text(
            notam.featureName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withAlpha(230) : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Vertical Limits
        _buildInfoRow(
          icon: Icons.height,
          label: l10n.notamLimits,
          value: (notam.lowerLimit2 != null || notam.upperLimit2 != null)
              ? '${notam.lowerLimit2 ?? 'GND'} - ${notam.upperLimit2 ?? 'UNL'}'
              : l10n.valueNotAvailable,
          isDark: isDark,
        ),

        // Validity range
        _buildInfoRow(
          icon: Icons.calendar_today_outlined,
          label: l10n.notamStart,
          value: _formatDateTime(notam.from, l10n.localeName),
          isDark: isDark,
        ),
        _buildInfoRow(
          icon: Icons.event_busy_outlined,
          label: l10n.notamEnd,
          value: _formatDateTime(notam.to, l10n.localeName),
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        // Message E) decoded
        Text(
          l10n.airspaceActivity, // Reusing localized label or general term
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          notam.msg,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.white.withAlpha(220) : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Hide action button under the NOTAM content
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(notamsProvider.notifier).hideNotam(notam);
                final remaining = visibleNotams
                    .where((n) => n.id != notam.id)
                    .toList();
                if (remaining.isEmpty && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.visibility_off_outlined, size: 16),
              label: Text(
                l10n.hideNotam,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: Colors.black.withAlpha(120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
