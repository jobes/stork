import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/pilot.dart';
import '../../domain/models/app_settings.dart';
import '../providers/settings_provider.dart';
import 'create_pilot_dialog.dart';
import 'pin_prompt_dialog.dart';

void showSwitchPilotBottomSheet(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  AsyncValue<List<Pilot>> pilotsAsync, {
  required void Function(String unlockedPilotId) onPilotUnlocked,
}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final activePilotId = settings.pilotId;
  final parentContext = context;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return pilotsAsync.when(
            data: (pilots) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.switchPilotTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(l10n.addNewPilot),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showCreatePilotDialog(
                            parentContext,
                            ref,
                            onCreated: (newId) {
                              onPilotUnlocked(newId);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.savedProfilesSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (pilots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noPilotsCreated,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pilots.length + 1,
                          separatorBuilder: (context, idx) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            if (idx == pilots.length) {
                              return TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref
                                      .read(appSettingsProvider.notifier)
                                      .updatePilotId(null);
                                },
                                child: Text(l10n.deselectPilot),
                              );
                            }
                            final pilot = pilots[idx];
                            final isActive = pilot.id == activePilotId;

                            return Card(
                              elevation: isActive ? 2 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isActive
                                    ? BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              color: isActive
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  Navigator.pop(context);
                                  if (settings.pilotId == pilot.id) return;

                                  final success = await promptForPin(
                                    parentContext,
                                    pilot,
                                    l10n.selectPilotTitle,
                                  );
                                  if (success) {
                                    await ref
                                        .read(appSettingsProvider.notifier)
                                        .updatePilotId(pilot.id);
                                    onPilotUnlocked(pilot.id);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isActive
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                        child: Icon(
                                          Icons.person,
                                          color: isActive
                                              ? Colors.white
                                              : Colors.grey[700],
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pilot.name,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: isActive
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                            ),
                                            Text(
                                              pilot.pin != null &&
                                                      pilot.pin!.isNotEmpty
                                                  ? l10n.protectedByPin
                                                  : l10n.noPin,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Center(child: Text(l10n.errorPrefix)),
          );
        },
      );
    },
  );
}
