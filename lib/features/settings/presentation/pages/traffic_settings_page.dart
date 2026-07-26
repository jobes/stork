import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/altitude_unit.dart';
import '../providers/settings_provider.dart';

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
          final horizontalDistKm = settings.trafficMaxHorizontalDistance / 1000.0;
          final horizontalDistNm = settings.trafficMaxHorizontalDistance / 1852.0;

          final altUnit = settings.altitudeUnit;
          final verticalDistUnitVal = altUnit.convertFromMeters(settings.trafficMaxVerticalDistance);

          final verticalMinVal = altUnit == AltitudeUnit.feet ? 500.0 : 150.0;
          final verticalMaxVal = altUnit == AltitudeUnit.feet ? 20000.0 : 6000.0;
          final verticalDivisions = 39;

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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                            '${horizontalDistKm.toStringAsFixed(0)} km (${horizontalDistNm.toStringAsFixed(0)} NM)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: horizontalDistKm.clamp(5.0, 200.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                            '${verticalDistUnitVal.toStringAsFixed(0)} ${altUnit.getMslLabel(l10n)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: verticalDistUnitVal.clamp(verticalMinVal, verticalMaxVal),
                        min: verticalMinVal,
                        max: verticalMaxVal,
                        divisions: verticalDivisions,
                        onChanged: (val) {
                          final meters = altUnit.convertToMeters(val);
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateTrafficMaxVerticalDistance(meters);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}
