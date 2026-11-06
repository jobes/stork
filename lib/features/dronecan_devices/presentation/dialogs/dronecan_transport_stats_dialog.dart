import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/transport_statistics.dart';
import '../providers/dronecan_nodes_provider.dart';
import '../providers/dronecan_transport_stats_provider.dart';

/// Shows live `uavcan.protocol.GetTransportStats` data of [node].
///
/// The statistics are re-read once per second and every value is shown together
/// with the change since the previous reading, so the dialog doubles as a
/// per-second rate meter.
void showDroneCanTransportStatsDialog(
  BuildContext context, {
  required DroneCanNode node,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _TransportStatsDialog(node: node),
  );
}

class _TransportStatsDialog extends ConsumerWidget {
  const _TransportStatsDialog({required this.node});

  final DroneCanNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(droneCanTransportStatsProvider(node.nodeId));
    final current = state.current;

    return BaseDetailsDialog(
      titleText: l10n.dronecanTransportStatsTitle(node.nodeId),
      icon: Icons.insights_outlined,
      maxWidth: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AutoRefreshHeader(hasError: state.hasError),
          const SizedBox(height: 12),
          if (current == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _TransportStatsBody(stats: current, previous: state.previous),
        ],
      ),
    );
  }
}

class _AutoRefreshHeader extends StatelessWidget {
  const _AutoRefreshHeader({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          hasError ? Icons.cloud_off_outlined : Icons.sync,
          size: 16,
          color: hasError
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasError
                ? l10n.dronecanRequestFailed
                : l10n.dronecanStatsAutoRefreshHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransportStatsBody extends StatelessWidget {
  const _TransportStatsBody({required this.stats, required this.previous});

  final TransportStatistics stats;
  final TransportStatistics? previous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prev = previous;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatRow(
          icon: Icons.upload_outlined,
          label: l10n.dronecanTransfersTx,
          value: stats.transfersTx,
          delta: _delta(stats.transfersTx, prev?.transfersTx),
        ),
        _StatRow(
          icon: Icons.download_outlined,
          label: l10n.dronecanTransfersRx,
          value: stats.transfersRx,
          delta: _delta(stats.transfersRx, prev?.transfersRx),
        ),
        _StatRow(
          icon: Icons.error_outline,
          label: l10n.dronecanTransferErrors,
          value: stats.transferErrors,
          delta: _delta(stats.transferErrors, prev?.transferErrors),
          isError: stats.transferErrors > 0,
        ),
        const Divider(height: 28),
        Text(l10n.dronecanCanInterfaces, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (stats.canInterfaces.isEmpty)
          Text(
            l10n.dronecanNoInterfaceStats,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final (index, iface) in stats.canInterfaces.indexed)
            _CanInterfaceCard(
              index: index,
              stats: iface,
              previous: prev != null && index < prev.canInterfaces.length
                  ? prev.canInterfaces[index]
                  : null,
            ),
      ],
    );
  }
}

class _CanInterfaceCard extends StatelessWidget {
  const _CanInterfaceCard({
    required this.index,
    required this.stats,
    required this.previous,
  });

  final int index;
  final CanInterfaceStatistics stats;
  final CanInterfaceStatistics? previous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dronecanCanInterfaceLabel(index),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _StatRow(
            icon: Icons.upload_outlined,
            label: l10n.dronecanFramesTx,
            value: stats.framesTx,
            delta: _delta(stats.framesTx, previous?.framesTx),
            compact: true,
          ),
          _StatRow(
            icon: Icons.download_outlined,
            label: l10n.dronecanFramesRx,
            value: stats.framesRx,
            delta: _delta(stats.framesRx, previous?.framesRx),
            compact: true,
          ),
          _StatRow(
            icon: Icons.error_outline,
            label: l10n.dronecanErrors,
            value: stats.errors,
            delta: _delta(stats.errors, previous?.errors),
            compact: true,
            isError: stats.errors > 0,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    this.isError = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final int? delta;
  final bool isError;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueColor = isError ? scheme.error : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 6),
      child: Row(
        children: [
          Icon(icon, size: compact ? 15 : 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value',
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: valueColor ?? scheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            delta == null ? '(${l10n.placeholderDash})' : '(+$delta)',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontFamily: 'monospace',
              color: delta == null
                  ? theme.colorScheme.onSurfaceVariant
                  : (isError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Difference since the previous reading, or `null` when there is none (first
/// reading) or the counter was reset (e.g. because the node restarted).
int? _delta(int current, int? previous) {
  if (previous == null || current < previous) return null;
  return current - previous;
}
