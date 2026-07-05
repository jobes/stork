import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../telemetry/presentation/widgets/stat_item.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../../settings/presentation/providers/pilot_provider.dart';
import '../../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../../settings/domain/models/pilot.dart';
import '../../../../settings/domain/models/aircraft.dart';

class MapDrawer extends ConsumerWidget {
  const MapDrawer({super.key});

  String _formatHoursMinutes(double totalHours, AppLocalizations l10n) {
    final totalMinutes = (totalHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return l10n.hoursMinutesFormat(hours, minutes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(appSettingsProvider);

    return Drawer(
      child: PointerInterceptor(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: settingsAsync.when(
                data: (settings) {
                  final activePilotId = settings.pilotId;
                  final airplaneId = settings.airplaneId ?? '';

                  final pilotsAsync = ref.watch(pilotStateProvider);
                  final pilots = pilotsAsync.value ?? [];
                  Pilot? activePilot;
                  for (final p in pilots) {
                    if (p.id == activePilotId) {
                      activePilot = p;
                      break;
                    }
                  }

                  final aircraftsAsync = ref.watch(aircraftStateProvider);
                  final aircrafts = aircraftsAsync.value ?? [];
                  Aircraft? activeAircraft;
                  for (final a in aircrafts) {
                    if (a.id == airplaneId) {
                      activeAircraft = a;
                      break;
                    }
                  }

                  final statsAsync = activePilotId != null
                      ? ref.watch(pilotStatsProvider(activePilotId))
                      : null;

                  final aircraftHoursAsync = airplaneId.isNotEmpty
                      ? ref.watch(aircraftHoursProvider(airplaneId))
                      : null;

                  final pilotNameText =
                      activePilot?.name ?? l10n.anonymousPilot;
                  final airplaneNameText =
                      activeAircraft?.name ?? l10n.unknownAircraft;

                  final pilotHoursText = statsAsync?.value != null
                      ? _formatHoursMinutes(statsAsync!.value!.totalHours, l10n)
                      : l10n.hoursMinutesFallback;

                  final aircraftHoursText = aircraftHoursAsync?.value != null
                      ? _formatHoursMinutes(aircraftHoursAsync!.value!, l10n)
                      : l10n.hoursMinutesFallback;

                  return Column(
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
                            value: pilotHoursText,
                            label: l10n.pilotTotalHours,
                          ),
                          const SizedBox(width: 16),
                          StatItem(
                            icon: Icons.airplanemode_active,
                            value: aircraftHoursText,
                            label: l10n.aircraftTotalHours,
                          ),
                        ],
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          context.pop();
                          context.push('/profile');
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pilotNameText,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    airplaneNameText,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary.withAlpha(204),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.account_circle_outlined),
                              color: Theme.of(context).colorScheme.onPrimary,
                              onPressed: () {
                                context.pop();
                                context.push('/profile');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (err, stack) => Text(l10n.errorLoadingSettings),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.navigation_outlined),
              title: Text(l10n.navigation),
              onTap: () {
                context.pop();
                context.push('/navigation');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.flightRecords),
              onTap: () {
                context.pop();
                context.push('/flight-records');
              },
            ),
            const Spacer(),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
