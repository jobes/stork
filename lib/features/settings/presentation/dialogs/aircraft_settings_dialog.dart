import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../domain/models/aircraft.dart';
import '../../domain/models/speed_unit.dart';
import '../providers/aircraft_provider.dart';
import '../providers/settings_provider.dart';

void showAircraftSettingsDialog(
  BuildContext context,
  WidgetRef ref,
  Aircraft aircraft,
) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return _AircraftSettingsDialog(
        aircraft: aircraft,
        parentContext: context,
      );
    },
  );
}

class _AircraftSettingsDialog extends ConsumerStatefulWidget {
  final Aircraft aircraft;
  final BuildContext parentContext;

  const _AircraftSettingsDialog({
    required this.aircraft,
    required this.parentContext,
  });

  @override
  ConsumerState<_AircraftSettingsDialog> createState() =>
      _AircraftSettingsDialogState();
}

class _AircraftSettingsDialogState
    extends ConsumerState<_AircraftSettingsDialog> {
  late final TextEditingController _initialHoursController;
  late final TextEditingController _initialFlightsController;
  late final TextEditingController _ognDeviceIdController;
  late bool _sendLivePosition;
  late final SpeedUnit _speedUnit;
  late final SpeedUnit _windSpeedUnit;
  late final TextEditingController _cruiseSpeedController;
  late final TextEditingController _weatherAltitudeController;
  late final TextEditingController _windLimitController;
  late final TextEditingController _gustLimitController;
  bool _savingFlightProfile = false;

  @override
  void initState() {
    super.initState();
    _initialHoursController = TextEditingController(
      text: widget.aircraft.initialFlightHours.toString(),
    );
    _initialFlightsController = TextEditingController(
      text: widget.aircraft.initialFlights.toString(),
    );
    _ognDeviceIdController = TextEditingController(
      text: widget.aircraft.ognDeviceId,
    );
    _sendLivePosition = widget.aircraft.sendLivePosition;
    _speedUnit =
        ref.read(appSettingsProvider).value?.speedUnit ?? SpeedUnit.kmh;
    _windSpeedUnit =
        ref.read(appSettingsProvider).value?.windSpeedUnit ?? SpeedUnit.kmh;
    _cruiseSpeedController = TextEditingController(
      text: _speedUnit
          .convertFromMs(widget.aircraft.cruiseSpeedMs)
          .toStringAsFixed(1),
    );
    String? limitText(double? ms) =>
        ms == null ? null : _windSpeedUnit.convertFromMs(ms).toStringAsFixed(1);
    _windLimitController = TextEditingController(
      text: limitText(widget.aircraft.dangerousWindMs),
    );
    _gustLimitController = TextEditingController(
      text: limitText(widget.aircraft.dangerousGustMs),
    );
    _weatherAltitudeController = TextEditingController(
      text: widget.aircraft.weatherAltitudeFeet?.toString(),
    );
  }

  @override
  void dispose() {
    _initialHoursController.dispose();
    _initialFlightsController.dispose();
    _ognDeviceIdController.dispose();
    _cruiseSpeedController.dispose();
    _weatherAltitudeController.dispose();
    _windLimitController.dispose();
    _gustLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveFlightProfile(AppLocalizations l10n) async {
    final speed = double.tryParse(
      _cruiseSpeedController.text.trim().replaceAll(',', '.'),
    );
    final speedMs = speed == null ? null : _speedUnit.convertToMs(speed);
    final altitudeText = _weatherAltitudeController.text.trim();
    final altitude = int.tryParse(altitudeText);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    if (speedMs == null ||
        !speedMs.isFinite ||
        speedMs < minCruiseSpeedMs ||
        speedMs > maxCruiseSpeedMs) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.aircraftInvalidCruiseSpeed)),
      );
      return;
    }
    if (altitudeText.isNotEmpty && altitude == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.weatherInvalidAltitude)),
      );
      return;
    }

    double? readLimit(TextEditingController controller) {
      final value = double.tryParse(
        controller.text.trim().replaceAll(',', '.'),
      );
      return value == null ? null : _windSpeedUnit.convertToMs(value);
    }

    final wind = readLimit(_windLimitController);
    final gust = readLimit(_gustLimitController);
    if ((_windLimitController.text.trim().isNotEmpty &&
            (wind == null || !wind.isFinite || wind <= 0)) ||
        (_gustLimitController.text.trim().isNotEmpty &&
            (gust == null || !gust.isFinite || gust <= 0))) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.weatherInvalidLimit)));
      return;
    }

    final current = ref
        .read(aircraftStateProvider)
        .value
        ?.where((a) => a.id == widget.aircraft.id)
        .firstOrNull;
    if (current == null) return;
    setState(() => _savingFlightProfile = true);
    try {
      await ref
          .read(aircraftStateProvider.notifier)
          .updateAircraft(
            current.copyWith(
              cruiseSpeedMs: speedMs,
              weatherAltitudeFeet: altitude,
              dangerousWindMs: wind,
              dangerousGustMs: gust,
            ),
          );
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.weatherSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _savingFlightProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _initialHoursController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.hoursExampleHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final hours = double.tryParse(_initialHoursController.text);
                  if (hours == null || hours < 0) {
                    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                      SnackBar(content: Text(l10n.invalidFlightHours)),
                    );
                    return;
                  }
                  final currentAircrafts =
                      ref.read(aircraftStateProvider).value ??
                      [widget.aircraft];
                  final currentAircraft = currentAircrafts.firstWhere(
                    (a) => a.id == widget.aircraft.id,
                    orElse: () => widget.aircraft,
                  );
                  await ref
                      .read(aircraftStateProvider.notifier)
                      .updateAircraft(
                        currentAircraft.copyWith(initialFlightHours: hours),
                      );
                  if (widget.parentContext.mounted) {
                    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                      SnackBar(content: Text(l10n.initialHoursSaved)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.initialFlightsLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _initialFlightsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: l10n.flightsExampleHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final flights = int.tryParse(_initialFlightsController.text);
                  if (flights == null || flights < 0) {
                    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                      SnackBar(content: Text(l10n.invalidFlights)),
                    );
                    return;
                  }
                  final currentAircrafts =
                      ref.read(aircraftStateProvider).value ??
                      [widget.aircraft];
                  final currentAircraft = currentAircrafts.firstWhere(
                    (a) => a.id == widget.aircraft.id,
                    orElse: () => widget.aircraft,
                  );
                  await ref
                      .read(aircraftStateProvider.notifier)
                      .updateAircraft(
                        currentAircraft.copyWith(initialFlights: flights),
                      );
                  if (widget.parentContext.mounted) {
                    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                      SnackBar(content: Text(l10n.initialFlightsSaved)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
          const Divider(height: 32),
          TextField(
            controller: _cruiseSpeedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.aircraftCruiseSpeed,
              suffixText: _speedUnit.getAbbreviation(l10n),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weatherAltitudeController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(
              labelText: l10n.weatherDefaultAltitude,
              helperText: l10n.weatherAltitudeHelp,
              helperMaxLines: 3,
              suffixText: l10n.weatherAltitudeFt,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _windLimitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.weatherDangerousWind,
              helperText: l10n.weatherWindLimitHelp,
              helperMaxLines: 3,
              suffixText: _windSpeedUnit.getAbbreviation(l10n),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gustLimitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.weatherDangerousGust,
              helperText: l10n.weatherGustLimitHelp,
              helperMaxLines: 3,
              suffixText: _windSpeedUnit.getAbbreviation(l10n),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _savingFlightProfile
                  ? null
                  : () => unawaited(_saveFlightProfile(l10n)),
              child: Text(l10n.save),
            ),
          ),
          const Divider(height: 32),
          Text(
            l10n.ognSettingsSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.sendLivePosition),
            subtitle: Text(l10n.sendLivePositionDesc),
            value: _sendLivePosition,
            onChanged: (val) async {
              final currentAircrafts =
                  ref.read(aircraftStateProvider).value ?? [widget.aircraft];
              final currentAircraft = currentAircrafts.firstWhere(
                (a) => a.id == widget.aircraft.id,
                orElse: () => widget.aircraft,
              );
              final validOgnId = RegExp(
                r'^[0-9A-Fa-f]{6}$',
              ).hasMatch(currentAircraft.ognDeviceId.trim());
              if (val && !validOgnId) {
                ScaffoldMessenger.of(
                  widget.parentContext,
                ).showSnackBar(SnackBar(content: Text(l10n.invalidOgnId)));
                setState(() {
                  _sendLivePosition = false;
                });
                return;
              }
              setState(() {
                _sendLivePosition = val;
              });
              await ref
                  .read(aircraftStateProvider.notifier)
                  .updateAircraft(
                    currentAircraft.copyWith(sendLivePosition: val),
                  );
            },
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ognDeviceIdLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ognDeviceIdController,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l10n.ognDeviceIdHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final id = _ognDeviceIdController.text.trim().toUpperCase();
                  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(id)) {
                    ScaffoldMessenger.of(
                      widget.parentContext,
                    ).showSnackBar(SnackBar(content: Text(l10n.invalidOgnId)));
                    return;
                  }
                  final currentAircrafts =
                      ref.read(aircraftStateProvider).value ??
                      [widget.aircraft];
                  final currentAircraft = currentAircrafts.firstWhere(
                    (a) => a.id == widget.aircraft.id,
                    orElse: () => widget.aircraft,
                  );
                  await ref
                      .read(aircraftStateProvider.notifier)
                      .updateAircraft(
                        currentAircraft.copyWith(ognDeviceId: id),
                      );
                  if (widget.parentContext.mounted) {
                    ScaffoldMessenger.of(
                      widget.parentContext,
                    ).showSnackBar(SnackBar(content: Text(l10n.save)));
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ognGuideTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.ognGuideStep1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.ognGuideStep2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.ognGuideStep3,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  l10n.deleteAircraftButton,
                  style: const TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  final dialogCtx = context;
                  Navigator.pop(dialogCtx);
                  final confirmed = await showDialog<bool>(
                    context: widget.parentContext,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deleteAircraftButton),
                      content: Text(
                        l10n.deleteAircraftConfirm(widget.aircraft.name),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final settings = ref.read(appSettingsProvider).value;
                    if (settings?.airplaneId == widget.aircraft.id) {
                      await ref
                          .read(appSettingsProvider.notifier)
                          .updateAirplaneId(null);
                    }
                    await ref
                        .read(aircraftStateProvider.notifier)
                        .deleteAircraft(widget.aircraft.id);
                    if (widget.parentContext.mounted) {
                      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.aircraftDeletedSnackbar(widget.aircraft.name),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
