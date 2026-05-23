import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/app_settings.dart';
import '../../domain/range_thresholds.dart';
import '../providers/settings_provider.dart';
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
          final currentThresholds = RangeThresholds(
            inactiveMax: settings.flightSpeedThresholds.inactiveMax ?? 10.0,
            minError: settings.flightSpeedThresholds.minError ?? 60.0,
            minWarning: settings.flightSpeedThresholds.minWarning ?? 75.0,
            maxWarning: settings.flightSpeedThresholds.maxWarning ?? 110.0,
            maxError: settings.flightSpeedThresholds.maxError ?? 125.0,
          );
          
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                  .map((state) => _LegendItem(
                                        color: state.color,
                                        label: state.getLabel(l10n),
                                      ))
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
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Text(
                l10n.flightSpeed,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ThresholdsSlider(
                min: 0.0,
                max: settings.flightSpeedMaxRange,
                evaluate: currentThresholds.evaluate,
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    initialValue: settings.flightSpeedMaxRange,
                    min: 10,
                    max: 1000,
                    step: 10,
                    suffix: ' ${l10n.speedSuffix}',
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
                  Expanded(
                    child: Text(l10n.courseLineSegmentsCount),
                  ),
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
                  Expanded(
                    child: Text(l10n.courseLineSegmentDuration),
                  ),
                  NumberInput(
                    initialValue: settings.courseLineSegmentDuration.toDouble(),
                    min: 1,
                    max: 3600,
                    step: 10,
                    suffix: ' s',
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


