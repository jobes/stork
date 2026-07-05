import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../providers/aircraft_provider.dart';
import '../providers/settings_provider.dart';

void showCreateAircraftDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return BaseDetailsDialog(
        titleText: l10n.addAircraftTitle,
        icon: Icons.flight_takeoff,
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
                  labelText: l10n.aircraftNameLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.flight),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.aircraftNameRequired;
                  }
                  return null;
                },
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

                        final newId = await ref
                            .read(aircraftStateProvider.notifier)
                            .createAircraft(name: name);

                        final result = await ref
                            .read(appSettingsProvider.notifier)
                            .updateAirplaneId(newId);

                        if (result is SettingsUpdateSuccess) {
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                        } else if (result is SettingsUpdateFailure) {
                          if (dialogCtx.mounted) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.settingsUpdateFailed(
                                    result.error.toString(),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
