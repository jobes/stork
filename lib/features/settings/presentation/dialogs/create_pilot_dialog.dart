import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../providers/pilot_provider.dart';
import '../providers/settings_provider.dart';

void showCreatePilotDialog(BuildContext context, WidgetRef ref, {void Function(String newPilotId)? onCreated}) {
  final l10n = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final pinController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return BaseDetailsDialog(
        titleText: l10n.addPilotTitle,
        icon: Icons.person_add_alt_1,
        maxWidth: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.pilotNameLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pilotNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.optionalPinLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final name = nameController.text.trim();
                        final pin = pinController.text.trim();
                        final dialogNavigator = Navigator.of(dialogCtx);
                        
                        final newId = await ref.read(pilotStateProvider.notifier).createPilot(
                              name: name,
                              pin: pin.isEmpty ? null : pin,
                            );
                        
                        // Switch to the newly created pilot automatically
                        await ref.read(appSettingsProvider.notifier).updatePilotId(newId);
                        
                        if (onCreated != null) {
                          onCreated(newId);
                        }
                        
                        dialogNavigator.pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(l10n.create),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
