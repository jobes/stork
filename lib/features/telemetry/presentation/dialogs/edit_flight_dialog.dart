import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../domain/models/flight.dart';

class EditFlightDialog extends StatefulWidget {
  final Flight flight;
  final Function(String name, String? pilotId, String? airplaneId) onSave;

  const EditFlightDialog({
    super.key,
    required this.flight,
    required this.onSave,
  });

  @override
  State<EditFlightDialog> createState() => _EditFlightDialogState();
}

class _EditFlightDialogState extends State<EditFlightDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _pilotIdController;
  late final TextEditingController _airplaneIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.flight.name);
    _pilotIdController = TextEditingController(
      text: widget.flight.pilotId ?? '',
    );
    _airplaneIdController = TextEditingController(
      text: widget.flight.airplaneId ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pilotIdController.dispose();
    _airplaneIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseDetailsDialog(
      titleText: l10n.editFlight,
      icon: Icons.edit_note,
      maxWidth: 400,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.flightName,
                prefixIcon: const Icon(Icons.flight_takeoff),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pilotIdController,
              decoration: InputDecoration(
                labelText: l10n.pilotId,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _airplaneIdController,
              decoration: InputDecoration(
                labelText: l10n.airplaneId,
                prefixIcon: const Icon(Icons.airplanemode_active),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final name = _nameController.text.trim();
                      final pilotId = _pilotIdController.text.trim();
                      final airplaneId = _airplaneIdController.text.trim();
                      widget.onSave(
                        name,
                        pilotId.isEmpty ? null : pilotId,
                        airplaneId.isEmpty ? null : airplaneId,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
