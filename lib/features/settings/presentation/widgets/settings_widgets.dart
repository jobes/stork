import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/cannelloni_device.dart';

class SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const SliderSetting({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class CheckboxSetting extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CheckboxSetting({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class DeviceDropdownSetting extends StatelessWidget {
  final String label;
  final CannelloniDevice? selectedDevice;
  final List<CannelloniDevice> devices;
  final bool enabled;
  final ValueChanged<CannelloniDevice?> onChanged;

  const DeviceDropdownSetting({
    super.key,
    required this.label,
    required this.selectedDevice,
    required this.devices,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uniqueDevices = devices.toSet().toList();

    // Check if the currently selected device is in the list
    CannelloniDevice? value;
    try {
      value = uniqueDevices.firstWhere((d) => d == selectedDevice);
    } catch (_) {
      value = null;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<CannelloniDevice?>(
            key: ValueKey(value),
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              DropdownMenuItem<CannelloniDevice?>(
                value: null,
                child: Text(l10n.noneSelected),
              ),
              ...uniqueDevices.map(
                (device) => DropdownMenuItem(
                  value: device,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        device.hostname,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${device.ip}:${device.port}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            selectedItemBuilder: (context) {
              return [
                Text(l10n.noneSelected),
                ...uniqueDevices.map((device) => Text(device.hostname)),
              ];
            },
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
