import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../../settings/presentation/providers/pilot_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../domain/models/flight.dart';

class EditFlightDialog extends ConsumerStatefulWidget {
  final Flight flight;
  final Future<void> Function(
    String name,
    String? pilotId,
    String? airplaneId,
    String? notes,
  )
  onSave;

  const EditFlightDialog({
    super.key,
    required this.flight,
    required this.onSave,
  });

  @override
  ConsumerState<EditFlightDialog> createState() => _EditFlightDialogState();
}

class _EditFlightDialogState extends ConsumerState<EditFlightDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedPilotId;
  String? _selectedAirplaneId;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.flight.name);
    _selectedPilotId = widget.flight.pilotId;
    _selectedAirplaneId = widget.flight.airplaneId;
    _notesController = TextEditingController(text: widget.flight.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();

    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pilotsAsync = ref.watch(pilotStateProvider);
    final aircraftsAsync = ref.watch(aircraftStateProvider);

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
                  return l10n.pleaseEnterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Pilot selection
            pilotsAsync.when(
              data: (pilots) {
                final hasSelected =
                    _selectedPilotId == null ||
                    pilots.any((p) => p.id == _selectedPilotId);
                final dropdownValue = hasSelected ? _selectedPilotId : null;
                return DropdownButtonFormField<String?>(
                  initialValue: dropdownValue,
                  decoration: InputDecoration(
                    labelText: l10n.pilot,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.anonymousPilot),
                    ),
                    ...pilots.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPilotId = value;
                    });
                  },
                );
              },
              loading: () => DropdownButtonFormField<String?>(
                initialValue: null,
                decoration: InputDecoration(
                  labelText: l10n.pilot,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.anonymousPilot),
                  ),
                ],
                onChanged: null,
              ),
              error: (err, stack) => DropdownButtonFormField<String?>(
                initialValue: null,
                decoration: InputDecoration(
                  labelText: l10n.pilot,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.errorPrefix),
                  ),
                ],
                onChanged: null,
              ),
            ),
            const SizedBox(height: 16),
            // Aircraft selection
            aircraftsAsync.when(
              data: (aircrafts) {
                final hasSelected =
                    _selectedAirplaneId == null ||
                    aircrafts.any((a) => a.id == _selectedAirplaneId);
                final dropdownValue = hasSelected ? _selectedAirplaneId : null;
                return DropdownButtonFormField<String?>(
                  initialValue: dropdownValue,
                  decoration: InputDecoration(
                    labelText: l10n.aircraft,
                    prefixIcon: const Icon(Icons.airplanemode_active),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.unknownAircraft),
                    ),
                    ...aircrafts.map(
                      (a) => DropdownMenuItem<String?>(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAirplaneId = value;
                    });
                  },
                );
              },
              loading: () => DropdownButtonFormField<String?>(
                initialValue: null,
                decoration: InputDecoration(
                  labelText: l10n.aircraft,
                  prefixIcon: const Icon(Icons.airplanemode_active),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.unknownAircraft),
                  ),
                ],
                onChanged: null,
              ),
              error: (err, stack) => DropdownButtonFormField<String?>(
                initialValue: null,
                decoration: InputDecoration(
                  labelText: l10n.aircraft,
                  prefixIcon: const Icon(Icons.airplanemode_active),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.errorPrefix),
                  ),
                ],
                onChanged: null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.flightNotes,
                prefixIcon: const Icon(Icons.notes),
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
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final name = _nameController.text.trim();
                      final notes = _notesController.text.trim();
                      // Sanitize pilot and aircraft IDs against current state
                      final pilots =
                          pilotsAsync.whenOrNull(data: (p) => p) ?? [];
                      final aircrafts =
                          aircraftsAsync.whenOrNull(data: (a) => a) ?? [];
                      final sanitizedPilotId =
                          (_selectedPilotId != null &&
                              pilots.any((p) => p.id == _selectedPilotId))
                          ? _selectedPilotId
                          : null;
                      final sanitizedAircraftId =
                          (_selectedAirplaneId != null &&
                              aircrafts.any((a) => a.id == _selectedAirplaneId))
                          ? _selectedAirplaneId
                          : null;
                      await widget.onSave(
                        name,
                        sanitizedPilotId,
                        sanitizedAircraftId,
                        notes.isEmpty ? null : notes,
                      );
                      if (context.mounted) Navigator.of(context).pop();
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
