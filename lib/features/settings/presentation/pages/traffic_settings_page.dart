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

          final altUnit = settings.altitudeUnit;
          final verticalDistUnitVal = altUnit.convertFromMeters(settings.trafficMaxVerticalDistance);

          final double verticalMinVal;
          final double verticalMaxVal;
          final int verticalDivisions;
          switch (altUnit) {
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
                        value: verticalDistUnitVal.clamp(verticalMinVal, verticalMaxVal).toDouble(),
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
