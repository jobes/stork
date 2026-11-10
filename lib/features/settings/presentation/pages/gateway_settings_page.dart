import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cannelloni_service.dart';
import '../../../../core/services/mdns_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dronecan_devices/presentation/pages/dronecan_instruments_page.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/stork_settings_section.dart';

class GatewaySettingsPage extends ConsumerWidget {
  const GatewaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final isConnected = ref.watch(cannelloniServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuInstrumentsAndConnection)),
      body: settingsAsync.when(
        data: (settings) => StorkSettingsPageContent(
          children: [
            StorkSettingsSection(
              title: l10n.settingsConnection,
              children: [
                ListTile(
                  leading: Icon(
                    isConnected ? Icons.wifi_outlined : Icons.wifi_off_outlined,
                  ),
                  title: Text(
                    isConnected
                        ? l10n.menuGatewayConnected
                        : l10n.menuGatewayDisconnected,
                  ),
                  subtitle: Text(l10n.cannelloniGateway),
                ),
                const Divider(indent: 16, endIndent: 16),
                CheckboxSetting(
                  label: l10n.autoSelectDevice,
                  value: settings.autoSelectDevice,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateAutoSelectDevice(val);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                DeviceDropdownSetting(
                  label: l10n.selectedDevice,
                  selectedDevice: settings.selectedDevice,
                  devices: devicesAsync.value ?? [],
                  enabled: !settings.autoSelectDevice,
                  onChanged: (device) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSelectedDevice(device);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: devicesAsync.isLoading
                          ? null
                          : () => ref.invalidate(discoveredDevicesProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        devicesAsync.isLoading
                            ? l10n.menuSearchingGateways
                            : l10n.menuFindGateways,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            StorkSettingsSection(
              title: l10n.dronecanInstruments,
              children: [
                if (isConnected)
                  const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: DroneCanRefreshButton(),
                  ),
                const DroneCanInstrumentsContent(),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorLoadingSettings)),
      ),
    );
  }
}
