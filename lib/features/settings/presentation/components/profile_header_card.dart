import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/pilot.dart';
import '../../domain/models/aircraft.dart';
import '../../domain/models/app_settings.dart';
import '../dialogs/pilot_settings_dialog.dart';
import '../dialogs/aircraft_settings_dialog.dart';
import '../dialogs/pin_prompt_dialog.dart';
import '../dialogs/switch_pilot_bottom_sheet.dart';
import '../dialogs/switch_aircraft_bottom_sheet.dart';

class ProfileHeaderCard extends ConsumerWidget {
  final AppSettings settings;
  final Pilot? activePilot;
  final Aircraft? activeAircraft;
  final AsyncValue<double>? aircraftHoursAsync;
  final AsyncValue<List<Pilot>> pilotsAsync;
  final AsyncValue<List<Aircraft>> aircraftsAsync;
  final String? unlockedPilotId;
  final void Function(String) onPilotUnlocked;

  const ProfileHeaderCard({
    super.key,
    required this.settings,
    required this.activePilot,
    required this.activeAircraft,
    required this.aircraftHoursAsync,
    required this.pilotsAsync,
    required this.aircraftsAsync,
    required this.unlockedPilotId,
    required this.onPilotUnlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLocked = activePilot != null &&
        activePilot!.pin != null &&
        activePilot!.pin!.isNotEmpty &&
        unlockedPilotId != activePilot!.id;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pilot Column
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showSwitchPilotBottomSheet(
                        context,
                        ref,
                        settings,
                        pilotsAsync,
                        onPilotUnlocked: onPilotUnlocked,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.pilotUppercase,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (activePilot != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.settings,
                                      size: 20,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      if (isLocked) {
                                        final success = await promptForPin(context, activePilot!, l10n.accessSettingsTitle);
                                        if (success) {
                                          onPilotUnlocked(activePilot!.id);
                                          if (context.mounted) {
                                            showPilotSettingsDialog(
                                              context,
                                              ref,
                                              activePilot!,
                                              onDelete: () => requestDeletePilot(context, ref, activePilot!),
                                            );
                                          }
                                        }
                                      } else {
                                        showPilotSettingsDialog(
                                          context,
                                          ref,
                                          activePilot!,
                                          onDelete: () => requestDeletePilot(context, ref, activePilot!),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    activePilot?.name ?? l10n.noPilotSelected,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activePilot == null
                                    ? l10n.notLoggedIn
                                    : l10n.localProfile,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Separator
                Container(
                  width: 1,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                ),
                // Aircraft Column
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showSwitchAircraftBottomSheet(context, ref, settings, aircraftsAsync),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.aircraftUppercase,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (activeAircraft != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.settings,
                                      size: 20,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      showAircraftSettingsDialog(context, ref, activeAircraft!);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    activeAircraft?.name ?? l10n.unknown,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              aircraftHoursAsync != null
                                  ? aircraftHoursAsync!.when(
                                      data: (hrs) => l10n.hoursFlown(_formatHours(l10n, hrs)),
                                      loading: () => l10n.hoursFlown('...'),
                                      error: (err, stack) => l10n.hoursFlown('--'),
                                    )
                                  : l10n.hoursFlown(_formatHours(l10n, 0.0)),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(AppLocalizations l10n, double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '$h${l10n.durationHoursSuffix} $m${l10n.durationMinutesSuffix}';
  }
}
