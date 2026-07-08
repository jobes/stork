import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/mdns_service.dart';
import '../../../../core/services/cannelloni_service_io.dart'
    if (dart.library.html) '../../../../core/services/cannelloni_service_stub.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class GatewaySettingsPage extends ConsumerWidget {
  const GatewaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final isConnected = ref.watch(cannelloniServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cannelloniGateway)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            CheckboxSetting(
              label: l10n.autoSelectDevice,
              value: settings.autoSelectDevice,
              onChanged: (val) {
                ref
                    .read(appSettingsProvider.notifier)
                    .updateAutoSelectDevice(val);
              },
            ),
            DeviceDropdownSetting(
              label: l10n.selectedDevice,
              selectedDevice: settings.selectedDevice,
              devices: devicesAsync.asData?.value ?? [],
              enabled: !settings.autoSelectDevice,
              isConnected: isConnected,
              onChanged: (device) {
                ref
                    .read(appSettingsProvider.notifier)
                    .updateSelectedDevice(device);
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}
