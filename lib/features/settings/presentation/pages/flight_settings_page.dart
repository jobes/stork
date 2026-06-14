import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/range_thresholds.dart';
import '../../domain/models/speed_unit.dart';
import '../../domain/models/altitude_unit.dart';
import '../providers/settings_provider.dart';
import '../utils/threshold_state_extension.dart';
import '../widgets/number_input.dart';
import '../widgets/thresholds_slider.dart';

class FlightSettingsPage extends ConsumerWidget {
  const FlightSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.flightSettings)),
      body: settingsAsync.when(
        data: (settings) {
          final speedUnit = settings.speedUnit;
          final currentThresholds = RangeThresholds(
            inactiveMax: speedUnit.convertFromMs(
              settings.flightSpeedThresholds.inactiveMax ?? 2.77,
            ),
            minError: speedUnit.convertFromMs(
              settings.flightSpeedThresholds.minError ?? 16.67,
            ),
            minWarning: speedUnit.convertFromMs(
              settings.flightSpeedThresholds.minWarning ?? 20.83,
            ),
            maxWarning: speedUnit.convertFromMs(
              settings.flightSpeedThresholds.maxWarning ?? 30.56,
            ),
            maxError: speedUnit.convertFromMs(
              settings.flightSpeedThresholds.maxError ?? 34.72,
            ),
          );

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.flightSettings,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: ThresholdState.values
                                    .map(
                                      (state) => _LegendItem(
                                        color: state.color,
                                        label: state.getLabel(l10n),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        );
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.speedUnitSettings,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownButton<SpeedUnit>(
                      value: settings.speedUnit,
                      onChanged: (SpeedUnit? newValue) {
                        if (newValue != null) {
                          unawaited(
                            ref
                                .read(appSettingsProvider.notifier)
                                .updateSpeedUnit(newValue),
                          );
                        }
                      },
                      items: SpeedUnit.values.map<DropdownMenuItem<SpeedUnit>>((
                        SpeedUnit value,
                      ) {
                        return DropdownMenuItem<SpeedUnit>(
                          value: value,
                          child: Text(value.getLabel(l10n)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.altitudeUnitSettings,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownButton<AltitudeUnit>(
                      value: settings.altitudeUnit,
                      onChanged: (AltitudeUnit? newValue) {
                        if (newValue != null) {
                          unawaited(
                            ref
                                .read(appSettingsProvider.notifier)
                                .updateAltitudeUnit(newValue),
                          );
                        }
                      },
                      items: AltitudeUnit.values
                          .map<DropdownMenuItem<AltitudeUnit>>((
                            AltitudeUnit value,
                          ) {
                            return DropdownMenuItem<AltitudeUnit>(
                              value: value,
                              child: Text(value.getLabel(l10n)),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.heightUnitSettings,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownButton<AltitudeUnit>(
                      value: settings.heightUnit,
                      onChanged: (AltitudeUnit? newValue) {
                        if (newValue != null) {
                          unawaited(
                            ref
                                .read(appSettingsProvider.notifier)
                                .updateHeightUnit(newValue),
                          );
                        }
                      },
                      items: AltitudeUnit.values
                          .where((value) => value != AltitudeUnit.flightLevel)
                          .map<DropdownMenuItem<AltitudeUnit>>((
                            AltitudeUnit value,
                          ) {
                            return DropdownMenuItem<AltitudeUnit>(
                              value: value,
                              child: Text(value.getLabel(l10n)),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Text(
                  l10n.flightSpeed,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ThresholdsSlider(
                  min: 0.0,
                  max: speedUnit.convertFromMs(settings.flightSpeedMaxRange),
                  evaluate: currentThresholds.evaluate,
                  unitLabel: settings.speedUnit.getAbbreviation(l10n),
                  values: [
                    currentThresholds.inactiveMax!,
                    currentThresholds.minError!,
                    currentThresholds.minWarning!,
                    currentThresholds.maxWarning!,
                    currentThresholds.maxError!,
                  ],
                  onChanged: (newValues) {
                    unawaited(
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateFlightSpeedThresholds(
                            currentThresholds.copyWith(
                              inactiveMax: newValues[0],
                              minError: newValues[1],
                              minWarning: newValues[2],
                              maxWarning: newValues[3],
                              maxError: newValues[4],
                            ),
                          ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.flightSpeedMaxRange,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ),
                    NumberInput(
                      initialValue: speedUnit
                          .convertFromMs(settings.flightSpeedMaxRange)
                          .roundToDouble(),
                      min: 10,
                      max: 1000,
                      step: 10,
                      suffix: settings.speedUnit.getAbbreviation(l10n),
                      onChanged: (newValue) {
                        unawaited(
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateFlightSpeedMaxRange(newValue),
                        );
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.averageSpeed,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ),
                    NumberInput(
                      initialValue: speedUnit
                          .convertFromMs(settings.averageSpeed)
                          .roundToDouble(),
                      min: 10,
                      max: 500,
                      step: 5,
                      suffix: settings.speedUnit.getAbbreviation(l10n),
                      onChanged: (newValue) {
                        unawaited(
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateAverageSpeed(newValue),
                        );
                      },
                    ),
                  ],
                ),
              ),
              CourseLineSettingsSection(settings: settings, l10n: l10n),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class CourseLineSettingsSection extends ConsumerWidget {
  final AppSettings settings;
  final AppLocalizations l10n;

  const CourseLineSettingsSection({
    super.key,
    required this.settings,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Text(
            l10n.courseLineSettings,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(l10n.courseLineSegmentsCount)),
                  NumberInput(
                    initialValue: settings.courseLineSegmentsCount.toDouble(),
                    min: 1,
                    max: 30,
                    step: 1,
                    onChanged: (value) {
                      unawaited(
                        ref
                            .read(appSettingsProvider.notifier)
                            .updateCourseLineSegmentsCount(value.toInt()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(l10n.courseLineSegmentDuration)),
                  NumberInput(
                    initialValue: settings.courseLineSegmentDuration.toDouble(),
                    min: 1,
                    max: 3600,
                    step: 10,
                    suffix: l10n.durationSuffix,
                    onChanged: (value) {
                      unawaited(
                        ref
                            .read(appSettingsProvider.notifier)
                            .updateCourseLineSegmentDuration(value.toInt()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
