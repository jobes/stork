import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../domain/models/pilot.dart';
import '../providers/pilot_provider.dart';
import '../providers/settings_provider.dart';
import 'pin_prompt_dialog.dart';

void showPilotSettingsDialog(BuildContext context, WidgetRef ref, Pilot pilot, {required VoidCallback onDelete}) {
  final l10n = AppLocalizations.of(context)!;
  final initialHoursController = TextEditingController(text: pilot.initialFlightHours.toString());
  final pinConfirmController = TextEditingController();
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return BaseDetailsDialog(
        titleText: l10n.pilotSettingsTitle,
        icon: Icons.settings,
        maxWidth: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Initial flight hours
            Text(
              l10n.initialFlightHoursLabel,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: initialHoursController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: l10n.hoursExampleHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final hours = double.tryParse(initialHoursController.text);
                    if (hours == null || hours < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.invalidFlightHours)),
                      );
                      return;
                    }
                    await ref.read(pilotStateProvider.notifier).updatePilot(
                          pilot.copyWith(initialFlightHours: hours),
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.initialHoursSaved)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PIN
            Text(
              l10n.pinSecurityLabel,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: pinConfirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: l10n.newPinHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final pinText = pinConfirmController.text.trim();
                    await ref.read(pilotStateProvider.notifier).updatePilot(
                          pilot.copyWith(pin: pinText.isEmpty ? null : pinText),
                        );
                    pinConfirmController.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.pilotPinUpdatedSnackbar)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(l10n.deletePilotTitle, style: const TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    onDelete();
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> requestDeletePilot(BuildContext context, WidgetRef ref, Pilot pilot) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => BaseDetailsDialog(
      titleText: l10n.deletePilotTitle,
      icon: Icons.warning_amber_rounded,
      maxWidth: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deletePilotConfirm(pilot.name),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return;

  if (context.mounted) {
    final success = await promptForPin(context, pilot, l10n.deletePilotPinPrompt);
    if (success) {
      final settings = ref.read(appSettingsProvider).value;
      if (settings?.pilotId == pilot.id) {
        await ref.read(appSettingsProvider.notifier).updatePilotId(null);
      }
      await ref.read(pilotStateProvider.notifier).deletePilot(pilot.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pilotDeletedSnackbar(pilot.name))),
        );
      }
    }
  }
}
