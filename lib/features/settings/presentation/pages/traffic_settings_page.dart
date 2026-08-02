import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/altitude_unit.dart';
import '../../domain/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/puretrack_settings_card.dart';
import '../widgets/gdl90_settings_card.dart';

class TrafficSettingsPage extends ConsumerWidget {
  const TrafficSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trafficSettings)),
      body: settingsAsync.when(
        data: (settings) {
          final horizontalDistKm =
              settings.trafficMaxHorizontalDistance / 1000.0;

          final heightUnit = settings.heightUnit;
          final verticalDistUnitVal = heightUnit.convertFromMeters(
            settings.trafficMaxVerticalDistance,
          );

          final double verticalMinVal;
          final double verticalMaxVal;
          final int verticalDivisions;
          switch (heightUnit) {
            case AltitudeUnit.feet:
            case AltitudeUnit.flightLevel:
              verticalMinVal = 500.0;
              verticalMaxVal = 20000.0;
              verticalDivisions = 39;
              break;
            case AltitudeUnit.meters:
              verticalMinVal = 150.0;
              verticalMaxVal = 6000.0;
              verticalDivisions = 39;
              break;
          }

          return ListView(
            children: [
              SwitchListTile(
                title: Text(
                  l10n.enableHorizontalDistanceFilter,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                value: settings.trafficFilterMaxHorizontalDistanceEnabled,
                onChanged: (val) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateTrafficFilterMaxHorizontalDistanceEnabled(val);
                },
              ),
              if (settings.trafficFilterMaxHorizontalDistanceEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.trafficMaxHorizontalDistance,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            l10n.trafficMaxHorizontalDistanceSummary(
                              horizontalDistKm.toStringAsFixed(0),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: horizontalDistKm.clamp(5.0, 200.0).toDouble(),
                        min: 5.0,
                        max: 200.0,
                        divisions: 39, // steps of 5 km
                        onChanged: (val) {
                          final meters = val * 1000.0;
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateTrafficMaxHorizontalDistance(meters);
                        },
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  l10n.enableVerticalDistanceFilter,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                value: settings.trafficFilterMaxVerticalDistanceEnabled,
                onChanged: (val) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateTrafficFilterMaxVerticalDistanceEnabled(val);
                },
              ),
              if (settings.trafficFilterMaxVerticalDistanceEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.trafficMaxVerticalDistance,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${verticalDistUnitVal.toStringAsFixed(0)} ${heightUnit.getLabel(l10n)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: verticalDistUnitVal
                            .clamp(verticalMinVal, verticalMaxVal)
                            .toDouble(),
                        min: verticalMinVal,
                        max: verticalMaxVal,
                        divisions: verticalDivisions,
                        onChanged: (val) {
                          final meters = heightUnit.convertToMeters(val);
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateTrafficMaxVerticalDistance(meters);
                        },
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  l10n.enableCas,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(l10n.casEnabledDesc),
                value: settings.casEnabled,
                onChanged: (val) {
                  ref.read(appSettingsProvider.notifier).updateCasEnabled(val);
                },
              ),
              if (settings.casEnabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.casLookaheadTime,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${settings.casLookaheadTime.round()} s',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.casLookaheadTime
                            .clamp(10.0, 120.0)
                            .toDouble(),
                        min: 10.0,
                        max: 120.0,
                        divisions: 22, // 5 sec steps
                        onChanged: (val) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateCasLookaheadTime(val);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.casHorizontalThreshold,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${settings.casHorizontalThreshold.round()} m',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.casHorizontalThreshold
                            .clamp(50.0, 1000.0)
                            .toDouble(),
                        min: 50.0,
                        max: 1000.0,
                        divisions: 19, // 50m steps
                        onChanged: (val) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateCasHorizontalThreshold(val);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.casVerticalThreshold,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${heightUnit.convertFromMeters(settings.casVerticalThreshold).round()} ${heightUnit.getLabel(l10n)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: heightUnit
                            .convertFromMeters(settings.casVerticalThreshold)
                            .clamp(
                              heightUnit == AltitudeUnit.meters ? 20.0 : 50.0,
                              heightUnit == AltitudeUnit.meters
                                  ? 300.0
                                  : 1000.0,
                            )
                            .toDouble(),
                        min: heightUnit == AltitudeUnit.meters ? 20.0 : 50.0,
                        max: heightUnit == AltitudeUnit.meters ? 300.0 : 1000.0,
                        divisions: 19,
                        onChanged: (val) {
                          final meters = heightUnit.convertToMeters(val);
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateCasVerticalThreshold(meters);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  l10n.ognEnableTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(l10n.ognEnableDesc),
                value: settings.ognEnabled,
                onChanged: (val) {
                  ref.read(appSettingsProvider.notifier).updateOgnEnabled(val);
                },
              ),
              const Divider(height: 1),
              const Gdl90SettingsCard(),
              const Divider(height: 1),
              const PureTrackSettingsCard(),
              const Divider(height: 1),
              _buildHiddenAircraftSection(context, ref, settings),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildHiddenAircraftSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final Set<String> hiddenIds = settings.hiddenAircraftIds;

    return ExpansionTile(
      leading: const Icon(Icons.visibility_off_outlined),
      title: Text(
        l10n.hiddenAircraftSection,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        hiddenIds.isEmpty
            ? l10n.noHiddenAircraft
            : l10n.hiddenAircraftCount(hiddenIds.length),
      ),
      children: [
        if (hiddenIds.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.noHiddenAircraft,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: Text(l10n.clearAllHiddenAircraft),
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).clearHiddenAircraft();
                },
              ),
            ),
          ),
          const Divider(height: 1),
          ...hiddenIds.map((id) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.airplanemode_inactive_outlined),
              title: Text(
                id.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.unhideAircraft,
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).unhideAircraft(id);
                },
              ),
            );
          }),
        ],
      ],
    );
  }
}
