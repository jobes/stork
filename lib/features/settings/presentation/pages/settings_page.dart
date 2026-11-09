import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cannelloni_service.dart';
import '../../../../core/widgets/stork_navigation_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/altitude_unit.dart';
import '../providers/display_preferences_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/stork_settings_section.dart';
import 'flight_settings_page.dart';
import 'gateway_settings_page.dart';
import 'map_settings_page.dart';
import 'traffic_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final preferences = ref.watch(displayPreferencesProvider).value;
    final canSave = preferences != null && !preferences.saving;
    final connected = ref.watch(cannelloniServiceProvider);

    void open(Widget page) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    }

    Future<void> savePreference(Future<void> Function() save) async {
      try {
        await save();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settingsPreferenceSaveFailed)),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: StorkSettingsPageContent(
        children: [
          StorkSettingsSection(
            title: l10n.settingsDisplayPreferences,
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(l10n.settingsTheme),
                trailing: DropdownButton<ThemeMode>(
                  value: preferences?.themeMode ?? ThemeMode.system,
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.settingsFollowSystem),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.settingsLightTheme),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.settingsDarkTheme),
                    ),
                  ],
                  onChanged: !canSave
                      ? null
                      : (mode) {
                          if (mode == null) return;
                          savePreference(
                            () => ref
                                .read(displayPreferencesProvider.notifier)
                                .setThemeMode(mode),
                          );
                        },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.settingsLanguage),
                trailing: DropdownButton<AppLanguage>(
                  value: preferences?.language ?? AppLanguage.system,
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.system,
                      child: Text(l10n.settingsFollowSystem),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.english,
                      child: Text(l10n.settingsEnglish),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.slovak,
                      child: Text(l10n.settingsSlovak),
                    ),
                  ],
                  onChanged: !canSave
                      ? null
                      : (language) {
                          if (language == null) return;
                          savePreference(
                            () => ref
                                .read(displayPreferencesProvider.notifier)
                                .setLanguage(language),
                          );
                        },
                ),
              ),
            ],
          ),
          StorkSettingsSection(
            title: '',
            children: [
              StorkNavigationTile(
                icon: Icons.map_outlined,
                title: l10n.menuMap,
                subtitle: l10n.menuMapSummary,
                onTap: () => open(const MapSettingsPage()),
              ),
              StorkNavigationTile(
                icon: Icons.flight_outlined,
                title: l10n.menuUnitsAndLimits,
                subtitle: settings == null
                    ? null
                    : l10n.menuUnitsSummary(
                        settings.speedUnit.getAbbreviation(l10n),
                        settings.altitudeUnit.getLabel(l10n),
                      ),
                onTap: () => open(const FlightSettingsPage()),
              ),
              StorkNavigationTile(
                icon: Icons.shield_outlined,
                title: l10n.menuTrafficAndAlerts,
                subtitle: settings == null
                    ? null
                    : settings.casEnabled
                    ? l10n.menuCollisionAlertsOn
                    : l10n.menuCollisionAlertsOff,
                onTap: () => open(const TrafficSettingsPage()),
              ),
            ],
          ),
          StorkSettingsSection(
            title: '',
            children: [
              StorkNavigationTile(
                icon: Icons.router_outlined,
                title: l10n.menuInstrumentsAndConnection,
                subtitle: connected
                    ? l10n.menuGatewayConnected
                    : l10n.menuGatewayDisconnected,
                onTap: () => open(const GatewaySettingsPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
