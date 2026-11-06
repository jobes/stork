import 'package:flutter/material.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/dronecan_node.dart';

/// Name of a DroneCAN node with its node ID shown in a separate badge.
///
/// The badge keeps the numeric node ID from being mistaken for part of the
/// name; the name falls back to the dialog title while `GetNodeInfo` has not
/// answered yet.
class DroneCanNodeHeader extends StatelessWidget {
  const DroneCanNodeHeader({super.key, required this.node, this.titleStyle});

  final DroneCanNode node;

  /// Overrides the name style, e.g. for a dialog title.
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            node.name ?? l10n.dronecanNodeDetailsTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                titleStyle ??
                theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.primary.withAlpha(90)),
          ),
          child: Text(
            l10n.dronecanNodeIdBadge(node.nodeId),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}
