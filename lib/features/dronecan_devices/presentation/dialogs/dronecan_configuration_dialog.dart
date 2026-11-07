import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/dronecan_node.dart';
import '../../domain/models/dronecan_parameter.dart';
import '../components/dronecan_node_header.dart';
import '../providers/dronecan_configuration_provider.dart';
import '../utils/dronecan_formatters.dart';
import 'dronecan_parameter_edit_dialog.dart';

/// Shows the parameter table of [node] and lets the user read, change, store
/// and erase the node configuration.
void showDroneCanConfigurationDialog(BuildContext context, DroneCanNode node) {
  showDialog<void>(
    context: context,
    builder: (_) => _ConfigurationDialog(node: node),
  );
}

class _ConfigurationDialog extends ConsumerStatefulWidget {
  const _ConfigurationDialog({required this.node});

  final DroneCanNode node;

  @override
  ConsumerState<_ConfigurationDialog> createState() =>
      _ConfigurationDialogState();
}

class _ConfigurationDialogState extends ConsumerState<_ConfigurationDialog> {
  DroneCanNode get node => widget.node;

  DroneCanConfigurationNotifier get _notifier =>
      ref.read(droneCanConfigurationProvider(node.nodeId).notifier);

  @override
  void initState() {
    super.initState();
    // Reading the whole parameter list is the primary purpose of the dialog.
    Future.microtask(() {
      if (!mounted) return;
      unawaited(_notifier.refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(droneCanConfigurationProvider(node.nodeId));
    final canTap = !state.busy && !state.isLoading;

    return BaseDetailsDialog(
      titleText: l10n.dronecanConfigurationTitle,
      icon: Icons.tune,
      maxWidth: 720,
      maxHeight: 620,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DroneCanNodeHeader(node: node),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ConfigurationButton(
                icon: Icons.refresh,
                label: l10n.dronecanConfigurationRefresh,
                onPressed: canTap ? () => unawaited(_refresh()) : null,
              ),
              _ConfigurationButton(
                icon: Icons.save_outlined,
                label: l10n.dronecanConfigurationStoreAll,
                onPressed: canTap ? () => unawaited(_storeAll()) : null,
              ),
              _ConfigurationButton(
                icon: Icons.delete_outline,
                label: l10n.dronecanConfigurationEraseAll,
                onPressed: canTap ? () => unawaited(_eraseAll()) : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.dronecanConfigurationModifiedHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 22),
          if (state.isLoading && state.parameters.isEmpty)
            _LoadingBody(message: l10n.dronecanConfigurationLoading)
          else if (state.hasFailed)
            _MessageBody(
              message: l10n.dronecanConfigurationLoadFailed,
              isError: true,
            )
          else if (state.parameters.isEmpty)
            _MessageBody(message: l10n.dronecanConfigurationEmpty)
          else
            _ParameterTable(
              parameters: state.parameters,
              busy: !canTap,
              onEdit: _edit,
            ),
          if (state.error != null && state.parameters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.dronecanConfigurationLoadFailed,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (state.isLoading && state.parameters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.dronecanConfigurationLoading,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    await _notifier.refresh();
  }

  Future<void> _storeAll() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _notifier.storeAll();
    _showMessage(
      result.isSuccess
          ? l10n.dronecanConfigurationStoreSuccess
          : l10n.dronecanConfigurationStoreFailed,
    );
  }

  Future<void> _eraseAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _EraseConfirmDialog(node: node),
    );
    if (confirmed != true || !mounted) return;

    final result = await _notifier.eraseAll();
    _showMessage(
      result.isSuccess
          ? l10n.dronecanConfigurationEraseSuccess
          : l10n.dronecanConfigurationEraseFailed,
    );
  }

  Future<void> _edit(DroneCanParameter parameter) async {
    final l10n = AppLocalizations.of(context)!;
    final value = await showDroneCanParameterEditDialog(
      context,
      parameter: parameter,
    );
    if (value == null || !mounted) return;

    final result = await _notifier.setParameterValue(parameter, value);
    _showMessage(
      result.isSuccess
          ? l10n.dronecanParameterSetSuccess(parameter.name)
          : l10n.dronecanParameterSetFailed(parameter.name),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ConfigurationButton extends StatelessWidget {
  const _ConfigurationButton({
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

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isError
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ParameterTable extends StatelessWidget {
  const _ParameterTable({
    required this.parameters,
    required this.busy,
    required this.onEdit,
  });

  final List<DroneCanParameter> parameters;
  final bool busy;
  final ValueChanged<DroneCanParameter> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The type of a parameter is also shown in the editor, so it is the
        // first column to go when the dialog gets narrow.
        final showType = constraints.maxWidth >= 420;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _HeaderCell(
                    label: l10n.dronecanParameterColumnId,
                    width: _ColumnWidths.id,
                  ),
                  Expanded(
                    flex: 5,
                    child: _HeaderCell(label: l10n.dronecanParameterColumnName),
                  ),
                  if (showType)
                    _HeaderCell(
                      label: l10n.dronecanParameterColumnType,
                      width: _ColumnWidths.type,
                    ),
                  Expanded(
                    flex: 4,
                    child: _HeaderCell(
                      label: l10n.dronecanParameterColumnValue,
                    ),
                  ),
                  const SizedBox(width: _ColumnWidths.edit),
                ],
              ),
            ),
            const Divider(height: 10),
            for (final parameter in parameters)
              _ParameterRow(
                parameter: parameter,
                showType: showType,
                enabled: !busy,
                onEdit: () => onEdit(parameter),
              ),
          ],
        );
      },
    );
  }
}

class _ColumnWidths {
  static const double id = 34;
  static const double type = 88;
  static const double edit = 40;
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, this.width});

  final String label;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (width == null) return text;
    return SizedBox(width: width, child: text);
  }
}

class _ParameterRow extends StatelessWidget {
  const _ParameterRow({
    required this.parameter,
    required this.showType,
    required this.enabled,
    required this.onEdit,
  });

  final DroneCanParameter parameter;
  final bool showType;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final modified = parameter.isModified;

    final defaultHint = parameter.defaultValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: modified
            ? scheme.tertiaryContainer.withValues(alpha: isDark ? 0.28 : 0.45)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _ColumnWidths.id,
            child: Text(
              '${parameter.index}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              parameter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: modified ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (showType)
            SizedBox(
              width: _ColumnWidths.type,
              child: Text(
                droneCanParameterTypeLabel(parameter.type, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDroneCanParameterValue(parameter.value, l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: modified ? scheme.onTertiaryContainer : null,
                  ),
                ),
                if (modified && defaultHint != null)
                  Text(
                    l10n.dronecanParameterDefaultValue(
                      formatDroneCanParameterValue(defaultHint, l10n),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: _ColumnWidths.edit,
            child: IconButton(
              onPressed: enabled ? onEdit : null,
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: l10n.dronecanParameterEditTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _EraseConfirmDialog extends StatelessWidget {
  const _EraseConfirmDialog({required this.node});

  final DroneCanNode node;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BaseDetailsDialog(
      titleText: l10n.dronecanConfigurationEraseConfirmTitle,
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
            l10n.dronecanConfigurationEraseConfirmMessage(
              node.name ?? l10n.dronecanNodeDetailsTitle,
              node.nodeId,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
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
                child: Text(l10n.dronecanConfigurationEraseConfirmAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
