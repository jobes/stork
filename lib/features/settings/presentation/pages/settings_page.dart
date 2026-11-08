import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/stork_navigation_tile.dart';

import 'gateway_settings_page.dart';
import 'map_settings_page.dart';
import 'flight_settings_page.dart';
import 'traffic_settings_page.dart';

/// Keep the four existing destinations. The redesign changes presentation,
/// not the menu architecture or any of the underlying settings screens.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    void open(Widget page) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      StorkNavigationTile(
                        icon: Icons.router_outlined,
                        title: l10n.cannelloniGateway,
                        onTap: () => open(const GatewaySettingsPage()),
                      ),
                      Divider(
                        indent: 76,
                        endIndent: 16,
                        color: colors.outlineVariant,
                      ),
                      StorkNavigationTile(
                        icon: Icons.map_outlined,
                        title: l10n.mapSettings,
                        onTap: () => open(const MapSettingsPage()),
                      ),
                      Divider(
                        indent: 76,
                        endIndent: 16,
                        color: colors.outlineVariant,
                      ),
                      StorkNavigationTile(
                        icon: Icons.flight_outlined,
                        title: l10n.flightSettings,
                        onTap: () => open(const FlightSettingsPage()),
                      ),
                      Divider(
                        indent: 76,
                        endIndent: 16,
                        color: colors.outlineVariant,
                      ),
                      StorkNavigationTile(
                        icon: Icons.shield_outlined,
                        title: l10n.trafficSettings,
                        onTap: () => open(const TrafficSettingsPage()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
