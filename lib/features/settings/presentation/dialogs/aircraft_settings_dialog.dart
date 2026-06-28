import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../domain/models/aircraft.dart';
import '../providers/aircraft_provider.dart';
import '../providers/settings_provider.dart';

void showAircraftSettingsDialog(BuildContext context, WidgetRef ref, Aircraft aircraft) {
  final l10n = AppLocalizations.of(context)!;
  final initialHoursController = TextEditingController(text: aircraft.initialFlightHours.toString());
  final initialFlightsController = TextEditingController(text: aircraft.initialFlights.toString());
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return BaseDetailsDialog(
        titleText: l10n.aircraftSettingsTitle,
        icon: Icons.airplanemode_active,
        maxWidth: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    await ref.read(aircraftStateProvider.notifier).updateAircraft(
                          aircraft.copyWith(initialFlightHours: hours),
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
            Text(
              l10n.initialFlightsLabel,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: initialFlightsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: l10n.flightsExampleHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final flights = int.tryParse(initialFlightsController.text);
                    if (flights == null || flights < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.invalidFlights)),
                      );
                      return;
                    }
                    await ref.read(aircraftStateProvider.notifier).updateAircraft(
                          aircraft.copyWith(initialFlights: flights),
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.initialFlightsSaved)),
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
                  label: Text(l10n.deleteAircraftButton, style: const TextStyle(color: Colors.red)),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deleteAircraftButton),
                        content: Text(l10n.deleteAircraftConfirm(aircraft.name)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final settings = ref.read(appSettingsProvider).value;
                      if (settings?.airplaneId == aircraft.id) {
                         await ref.read(appSettingsProvider.notifier).updateAirplaneId(null);
                      }
                      await ref.read(aircraftStateProvider.notifier).deleteAircraft(aircraft.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.aircraftDeletedSnackbar(aircraft.name))),
                        );
                      }
                    }
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
