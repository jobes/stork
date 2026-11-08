import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/aircraft.dart';
import '../../domain/models/app_settings.dart';
import '../providers/settings_provider.dart';
import 'create_aircraft_dialog.dart';

void showSwitchAircraftBottomSheet(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
  AsyncValue<List<Aircraft>> aircraftsAsync,
) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final activeAircraftId = settings.airplaneId;
  final parentContext = context;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Appearance comes from the shared BottomSheetThemeData.
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return aircraftsAsync.when(
            data: (aircrafts) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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
                            l10n.switchAircraftTitle,
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
                        icon: const Icon(Icons.flight_takeoff),
                        label: Text(l10n.addNewAircraft),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showCreateAircraftDialog(parentContext, ref);
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.savedAircraftsSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (aircrafts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.airplanemode_inactive,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noAircraftsCreated,
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
                          itemCount: aircrafts.length + 1, // +1 for Deselect
                          separatorBuilder: (context, idx) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            if (idx == aircrafts.length) {
                              return TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref
                                      .read(appSettingsProvider.notifier)
                                      .updateAirplaneId(null);
                                },
                                child: Text(l10n.deselectAircraft),
                              );
                            }
                            final aircraft = aircrafts[idx];
                            final isActive = aircraft.id == activeAircraftId;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                  width: isActive ? 2 : 1,
                                ),
                              ),
                              color: isActive
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerLow,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await ref
                                      .read(appSettingsProvider.notifier)
                                      .updateAirplaneId(aircraft.id);
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
                                          Icons.flight,
                                          color: isActive
                                              ? theme.colorScheme.onPrimary
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
                                              aircraft.name,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: isActive
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
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
