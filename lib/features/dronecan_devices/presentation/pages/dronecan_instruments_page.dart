import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/dronecan_result.dart';
import '../dialogs/dronecan_node_details_dialog.dart';
import '../providers/dronecan_node_actions_provider.dart';
import '../providers/dronecan_nodes_provider.dart';
import '../utils/dronecan_formatters.dart';

/// Re-reads `GetNodeInfo` of every known node and reports the outcome.
Future<void> _refreshAll(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await ref
      .read(droneCanNodesActionsProvider.notifier)
      .refreshAll();
  if (!context.mounted) return;

  final message = switch (result) {
    DroneCanSuccess(:final value) when value.isEmpty =>
      l10n.dronecanRefreshNoNodes,
    DroneCanSuccess(:final value) when value.isComplete =>
      l10n.dronecanRefreshSuccess(value.answered),
    DroneCanSuccess(:final value) => l10n.dronecanRefreshPartial(
      value.answered,
      value.requested,
    ),
    DroneCanFailure() => l10n.dronecanRefreshFailed,
  };

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Lists the flight instruments (DroneCAN nodes) currently seen on the bus.
///
/// Everything shown here comes from live DroneCAN traffic and is never
/// persisted; "last seen" is derived from the time since the last heartbeat.
class DroneCanInstrumentsPage extends ConsumerWidget {
  const DroneCanInstrumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nodesAsync = ref.watch(droneCanNodesProvider);
    final isConnected = ref.watch(cannelloniServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dronecanInstruments),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.dronecanRefresh,
            onPressed: isConnected
                ? () => unawaited(_refreshAll(context, ref))
                : null,
          ),
        ],
      ),
      body: nodesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          debugPrint('DroneCAN instruments stream failed: $error');
          return Center(child: Text(l10n.dronecanInstrumentsLoadError));
        },
        data: (nodes) {
          if (nodes.isNotEmpty) {
            return _NodeTable(nodes: nodes);
          }
          return _EmptyState(
            icon: isConnected
                ? Icons.developer_board_outlined
                : Icons.wifi_off_outlined,
            message: isConnected
                ? l10n.dronecanInstrumentsEmpty
                : l10n.dronecanInstrumentsDisconnected,
          );
        },
      ),
    );
  }
}

class _NodeTable extends StatelessWidget {
  const _NodeTable({required this.nodes});

  final List<DroneCanNode> nodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingTextStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          columns: [
            DataColumn(label: Text(l10n.dronecanNodeId)),
            DataColumn(label: Text(l10n.dronecanNodeName)),
            DataColumn(label: Text(l10n.dronecanUniqueId)),
            DataColumn(label: Text(l10n.dronecanHealth)),
            DataColumn(label: Text(l10n.dronecanMode)),
            DataColumn(label: Text(l10n.dronecanUptime)),
            DataColumn(label: Text(l10n.dronecanLastSeen)),
          ],
          rows: [
            for (final node in nodes)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      node.nodeId.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      node.name ?? l10n.placeholderDash,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: theme.colorScheme.primary,
                      ),
                    ),
                    onTap: () => showDroneCanNodeDetailsDialog(context, node),
                  ),
                  DataCell(
                    Text(
                      node.uniqueId ?? l10n.placeholderDash,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataCell(
                    _HealthIndicator(
                      health: node.health,
                      label: droneCanHealthLabel(node.health, l10n),
                    ),
                  ),
                  DataCell(Text(droneCanModeLabel(node.mode, l10n))),
                  DataCell(
                    Text(
                      formatDroneCanUptime(
                        Duration(seconds: node.uptimeSec),
                        l10n,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(formatDroneCanLastSeen(node.lastSeenAgo(), l10n)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  const _HealthIndicator({required this.health, required this.label});

  final DroneCanNodeHealth health;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = droneCanHealthColor(scheme, health, isDark: isDark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
