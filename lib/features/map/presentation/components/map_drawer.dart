import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../l10n/app_localizations.dart';
import 'stat_item.dart';

class MapDrawer extends StatelessWidget {
  const MapDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: PointerInterceptor(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatItem(
                        icon: Icons.timer_outlined,
                        value: '---h --m',
                        label: l10n.pilotTotalHours,
                      ),
                      const SizedBox(width: 16),
                      StatItem(
                        icon: Icons.airplanemode_active,
                        value: '---h --m',
                        label: l10n.aircraftTotalHours,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.anonymousPilot,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              l10n.unknownAircraft,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withAlpha(204),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: Theme.of(context).colorScheme.onPrimary,
                        onPressed: () {
                          context.pop();
                          context.push('/settings');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.map),
                title: Text(l10n.offlineMaps),
                onTap: () {
                  context.pop(); // Close drawer
                  context.push('/offline-maps');
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.editSettings),
              onTap: () {
                context.pop();
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
