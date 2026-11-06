import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/dronecan_node.dart';
import '../../domain/models/firmware_update_failure.dart';
import '../../domain/models/firmware_update_progress.dart';
import '../components/dronecan_node_header.dart';
import '../providers/dronecan_firmware_update_provider.dart';
import '../utils/dronecan_formatters.dart';

/// Shows the firmware update dialog of [node]: the user picks an image, the
/// node pulls it over DroneCAN and the dialog reports the progress.
void showDroneCanFirmwareUpdateDialog(BuildContext context, DroneCanNode node) {
  showDialog<void>(
    context: context,
    builder: (_) => _FirmwareUpdateDialog(node: node),
  );
}

class _FirmwareUpdateDialog extends ConsumerWidget {
  const _FirmwareUpdateDialog({required this.node});

  final DroneCanNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(droneCanFirmwareUpdateProvider(node.nodeId));
    final notifier = ref.read(
      droneCanFirmwareUpdateProvider(node.nodeId).notifier,
    );
    final file = state.file;

    // The upload is finished only after the session stopped answering the node
    // (it stays registered for the end-of-file probe and retries). Closing the
    // dialog earlier would unregister the file reader and could make the node
    // abort the update, so the dialog waits for `uploadFinished`.
    ref.listen(droneCanFirmwareUpdateProvider(node.nodeId), (previous, next) {
      if (!next.uploadFinished || (previous?.uploadFinished ?? false)) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.dronecanFirmwareUpdateCompleted)),
      );
    });

    return PopScope(
      canPop: !state.isBusy,
      child: BaseDetailsDialog(
        titleText: l10n.dronecanFirmwareUpdateTitle,
        icon: Icons.system_update,
        maxWidth: 460,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: state.isBusy ? null : () => Navigator.of(context).pop(),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DroneCanNodeHeader(node: node),
            const SizedBox(height: 12),
            Text(
              l10n.dronecanFirmwareUpdateHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _FileTile(
              fileName: file?.name,
              fileSize: file?.size,
              enabled: !state.isRunning && !state.isPicking,
              onSelect: () => unawaited(notifier.selectFirmware()),
              onClear: state.isRunning ? null : notifier.clearFirmware,
            ),
            if (state.pickError != null)
              _ErrorLine(text: l10n.dronecanFirmwareUpdateReadFailed),
            const SizedBox(height: 14),
            if (state.isRunning || state.isFailed || state.isCompleted)
              _ProgressSection(progress: state.progress),
            if (!state.isRunning) ...[
              const Divider(height: 26),
              _FirmwareUpdateRisks(
                risks: [
                  l10n.dronecanFirmwareUpdateRiskInFlight,
                  l10n.dronecanFirmwareUpdateRiskPower,
                  l10n.dronecanFirmwareUpdateRiskRestart,
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (state.isRunning)
                  TextButton(
                    onPressed: notifier.cancel,
                    child: Text(l10n.cancel),
                  )
                else
                  TextButton(
                    // The node is still being served after the last chunk.
                    onPressed: state.isBusy
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.close),
                  ),
                FilledButton.icon(
                  onPressed: state.canStart
                      ? () => unawaited(notifier.upload())
                      : null,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(l10n.dronecanFirmwareUpdateUpload),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.fileName,
    required this.fileSize,
    required this.enabled,
    required this.onSelect,
    required this.onClear,
  });

  final String? fileName;
  final int? fileSize;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = fileName;
    final hasFile = name != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(
          theme.brightness == Brightness.dark ? 60 : 120,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.description_outlined : Icons.folder_open_outlined,
            size: 20,
            color: hasFile ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name ?? l10n.dronecanFirmwareUpdateNoFile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: hasFile ? 'monospace' : null,
                    fontWeight: hasFile ? FontWeight.w600 : null,
                    color: hasFile ? null : scheme.onSurfaceVariant,
                  ),
                ),
                if (fileSize != null)
                  Text(
                    formatDroneCanByteSize(fileSize!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (hasFile)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: l10n.cancel,
              onPressed: onClear,
              visualDensity: VisualDensity.compact,
            ),
          TextButton(
            onPressed: enabled ? onSelect : null,
            child: Text(
              hasFile
                  ? l10n.dronecanFirmwareUpdateChangeFile
                  : l10n.dronecanFirmwareUpdateChooseFile,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress});

  final FirmwareUpdateProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (progress.isFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.dronecanFirmwareUpdateFailed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_failureMessage(progress.error, l10n) case final message?)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      );
    }

    if (progress.isCompleted) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.dronecanFirmwareUpdateCompleted,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final percent = (progress.fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                progress.phase == FirmwareUpdatePhase.preparing
                    ? l10n.dronecanFirmwareUpdatePreparing
                    : l10n.dronecanFirmwareUpdateUploading,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (progress.phase == FirmwareUpdatePhase.uploading)
              Text(
                l10n.dronecanFirmwareUpdateProgress(
                  percent,
                  formatDroneCanByteSize(progress.bytesServed),
                  formatDroneCanByteSize(progress.totalBytes),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            // An unknown ratio is shown as an indeterminate bar.
            value: progress.phase == FirmwareUpdatePhase.uploading
                ? progress.fraction
                : null,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.dronecanFirmwareUpdateKeepOpen,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String? _failureMessage(Object? error, AppLocalizations l10n) {
  return switch (error) {
    FirmwareUpdateRejected(nodeMessage: final message)
        when message.isNotEmpty =>
      l10n.dronecanFirmwareUpdateRejectedWithMessage(message),
    FirmwareUpdateRejected(:final code) => l10n.dronecanFirmwareUpdateRejected(
      code,
    ),
    FirmwareUpdateTimeout() => l10n.dronecanFirmwareUpdateTimeout,
    FirmwareUpdateInvalidImage() => l10n.dronecanFirmwareUpdateEmptyFile,
    UnsupportedError() => l10n.dronecanFirmwareUpdateNotSupported,
    _ => null,
  };
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _FirmwareUpdateRisks extends StatelessWidget {
  const _FirmwareUpdateRisks({required this.risks});

  final List<String> risks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final risk in risks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    risk,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
