import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/core/utils/hex_utils.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/dronecan_result.dart';
import '../components/dronecan_node_header.dart';
import '../providers/dronecan_node_actions_provider.dart';
import '../providers/dronecan_nodes_provider.dart';
import 'dronecan_configuration_dialog.dart';
import 'dronecan_firmware_update_dialog.dart';
import 'dronecan_transport_stats_dialog.dart';

/// Shows the details and management actions of [node].
void showDroneCanNodeDetailsDialog(BuildContext context, DroneCanNode node) {
  showDialog<void>(
    context: context,
    builder: (_) => BaseDetailsDialog(
      title: _NodeDialogTitle(node: node),
      icon: Icons.developer_board_outlined,
      maxWidth: 440,
      child: _NodeDetailsBody(node: node),
    ),
  );
}

class _NodeDialogTitle extends ConsumerWidget {
  const _NodeDialogTitle({required this.node});

  final DroneCanNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = _liveNode(ref, this.node);
    final theme = Theme.of(context);

    return DroneCanNodeHeader(
      node: node,
      titleStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _NodeDetailsBody extends ConsumerStatefulWidget {
  const _NodeDetailsBody({required this.node});

  final DroneCanNode node;

  @override
  ConsumerState<_NodeDetailsBody> createState() => _NodeDetailsBodyState();
}

class _NodeDetailsBodyState extends ConsumerState<_NodeDetailsBody> {
  DroneCanNode get node => widget.node;

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dash = l10n.placeholderDash;
    final isConnected = ref.watch(cannelloniServiceProvider);
    // Follow the registry so the dialog shows the data the node reports now,
    // e.g. the new firmware version after an update and restart.
    final node = _liveNode(ref, widget.node);

    // The table already shows the live node data; only the vendor status code
    // and the GetNodeInfo-specific fields are repeated here.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow(
          icon: Icons.report_outlined,
          label: l10n.dronecanVendorStatusCode,
          value: node.vendorSpecificStatusCode == 0
              ? dash
              : '0x${formatHexInt(node.vendorSpecificStatusCode, digits: 4)}',
        ),
        if (node.uniqueId == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.dronecanDetailsUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._nodeInfoRows(node, l10n, dash),
        const Divider(height: 28),
        _NodeActions(
          enabled: isConnected && !_busy,
          busy: _busy,
          onRestart: _restart,
          onTransportStats: _showTransportStats,
          onUpdateFirmware: () =>
              showDroneCanFirmwareUpdateDialog(context, node),
          onConfiguration: () => showDroneCanConfigurationDialog(context, node),
        ),
      ],
    );
  }

  Future<void> _restart() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmRestart();
    if (!confirmed || !mounted) return;

    await _run(
      () =>
          ref.read(droneCanNodeActionsProvider(node.nodeId).notifier).restart(),
      onSuccess: (accepted) =>
          accepted ? l10n.dronecanRestartSuccess : l10n.dronecanRestartRejected,
    );
  }

  Future<bool> _confirmRestart() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _RestartConfirmDialog(node: node),
    );
    return result ?? false;
  }

  void _showTransportStats() {
    // The dialog polls the node itself so the values stay live.
    showDroneCanTransportStatsDialog(context, node: node);
  }

  /// Runs [action] with a busy indicator and reports the outcome.
  Future<void> _run<T>(
    Future<DroneCanResult<T>> Function() action, {
    required String Function(T value) onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final result = await action();
    final message = switch (result) {
      DroneCanSuccess<T>(:final value) => onSuccess(value),
      DroneCanFailure<T>() => l10n.dronecanRequestFailed,
    };
    if (mounted) setState(() => _busy = false);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<Widget> _nodeInfoRows(
    DroneCanNode node,
    AppLocalizations l10n,
    String dash,
  ) {
    return [
      _DetailRow(
        icon: Icons.system_update_alt,
        label: l10n.dronecanSoftwareVersion,
        value: _formatVersion(node.swMajor, node.swMinor, dash),
      ),
      _DetailRow(
        icon: Icons.commit,
        label: l10n.dronecanVcsCommit,
        value: _formatVcsCommit(node.swVcsCommit, dash),
      ),
      _DetailRow(
        icon: Icons.verified_outlined,
        label: l10n.dronecanImageCrc,
        value: _formatImageCrc(node.swImageCrc, dash),
      ),
      _DetailRow(
        icon: Icons.memory,
        label: l10n.dronecanHardwareVersion,
        value: _formatVersion(node.hwMajor, node.hwMinor, dash),
      ),
      _DetailRow(
        icon: Icons.verified_user_outlined,
        label: l10n.dronecanCertificateOfAuthenticity,
        value: node.certificateOfAuthenticity ?? dash,
      ),
    ];
  }
}

/// Asks for confirmation before restarting a node, spelling out the risks of an
/// accidental restart.
class _RestartConfirmDialog extends StatelessWidget {
  const _RestartConfirmDialog({required this.node});

  final DroneCanNode node;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BaseDetailsDialog(
      titleText: l10n.dronecanRestartConfirmTitle,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 24),
      ),
      maxWidth: 400,
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dronecanRestartConfirmMessage(
              node.name ?? l10n.dronecanNodeDetailsTitle,
              node.nodeId,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _RestartRisk(text: l10n.dronecanRestartRiskUnavailable),
          _RestartRisk(text: l10n.dronecanRestartRiskUnsavedConfig),
          _RestartRisk(text: l10n.dronecanRestartRiskInFlight),
          _RestartRisk(text: l10n.dronecanRestartRiskOffline),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.dronecanRestartConfirmAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestartRisk extends StatelessWidget {
  const _RestartRisk({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeActions extends StatelessWidget {
  const _NodeActions({
    required this.enabled,
    required this.busy,
    required this.onRestart,
    required this.onTransportStats,
    required this.onUpdateFirmware,
    required this.onConfiguration,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onRestart;
  final VoidCallback onTransportStats;
  final VoidCallback onUpdateFirmware;
  final VoidCallback onConfiguration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canTap = enabled && !busy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _NodeActionButton(
              icon: Icons.restart_alt,
              label: l10n.dronecanActionRestart,
              onPressed: canTap ? onRestart : null,
            ),
            _NodeActionButton(
              icon: Icons.insights_outlined,
              label: l10n.dronecanActionTransportStats,
              onPressed: canTap ? onTransportStats : null,
            ),
            _NodeActionButton(
              icon: Icons.system_update,
              label: l10n.dronecanActionUpdateFirmware,
              onPressed: canTap ? onUpdateFirmware : null,
            ),
            _NodeActionButton(
              icon: Icons.settings_suggest_outlined,
              label: l10n.dronecanActionConfiguration,
              onPressed: canTap ? onConfiguration : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _NodeActionButton extends StatelessWidget {
  const _NodeActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatVersion(int? major, int? minor, String dash) {
  if (major == null || minor == null) return dash;
  return '$major.$minor';
}

String _formatVcsCommit(int? commit, String dash) {
  if (commit == null || commit == 0) return dash;
  return '0x${formatHexInt(commit, digits: 8)}';
}

String _formatImageCrc(String? crc, String dash) {
  if (crc == null || crc == '0000000000000000') return dash;
  return '0x$crc';
}

/// Returns the current registry entry of [fallback].
///
/// Dialogs get the node as a snapshot when they are opened; watching the
/// registry keeps them in sync with what the node reports now (uptime, mode,
/// and the `GetNodeInfo` data such as the firmware version).
DroneCanNode _liveNode(WidgetRef ref, DroneCanNode fallback) {
  final nodes = ref.watch(droneCanNodesProvider).value;
  if (nodes == null) return fallback;
  for (final node in nodes) {
    if (node.nodeId == fallback.nodeId) return node;
  }
  // The node is gone (the link was reset): keep showing the last known data.
  return fallback;
}
