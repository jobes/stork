import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/mdns_service.dart';
import '../../domain/cannelloni_device.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), centerTitle: true),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            _SettingsSection(
              title: l10n.cannelloniGateway,
              children: [
                _CheckboxSetting(
                  label: l10n.autoSelectDevice,
                  value: settings.autoSelectDevice,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateAutoSelectDevice(val);
                  },
                ),
                _DeviceDropdownSetting(
                  label: l10n.selectedDevice,
                  selectedDevice: settings.selectedDevice,
                  devices: devicesAsync.asData?.value ?? [],
                  enabled: !settings.autoSelectDevice,
                  onChanged: (device) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSelectedDevice(device);
                  },
                ),
              ],
            ),
            _SettingsSection(
              title: l10n.offlineMaps,
              children: [
                _SliderSetting(
                  label: l10n.mapFontSize,
                  value: settings.mapFontSize,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (val) {
                    ref.read(appSettingsProvider.notifier).updateFontSize(val);
                  },
                ),
                _SliderSetting(
                  label: l10n.mapDefaultZoom,
                  value: settings.mapDefaultZoom,
                  min: 0.0,
                  max: 14.0,
                  divisions: 14,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateDefaultZoom(val);
                  },
                ),
                _SliderSetting(
                  label: l10n.mapOverviewZoom,
                  value: settings.mapOverviewZoom,
                  min: 0.0,
                  max: 14.0,
                  divisions: 14,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateOverviewZoom(val);
                  },
                ),
                _SliderSetting(
                  label: l10n.mapFollowZoom,
                  value: settings.mapFollowZoom,
                  min: 0.0,
                  max: 18.0,
                  divisions: 18,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateFollowZoom(val);
                  },
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
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

class _CheckboxSetting extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckboxSetting({
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

class _DeviceDropdownSetting extends StatelessWidget {
  final String label;
  final CannelloniDevice? selectedDevice;
  final List<CannelloniDevice> devices;
  final bool enabled;
  final ValueChanged<CannelloniDevice?> onChanged;

  const _DeviceDropdownSetting({
    required this.label,
    required this.selectedDevice,
    required this.devices,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Check if the currently selected device is in the list
    CannelloniDevice? value;
    try {
      value = devices.firstWhere(
        (d) => d == selectedDevice,
      );
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
              ...devices.map(
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
                ...devices.map((device) => Text(device.hostname)),
              ];
            },
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
