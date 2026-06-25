import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/export/gpx_export_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/flight.dart';
import '../../domain/models/flight_statistics.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../providers/black_box_repository_provider.dart';
import '../dialogs/edit_flight_dialog.dart';
import '../providers/flight_records_provider.dart';

class FlightRecordsPage extends ConsumerStatefulWidget {
  const FlightRecordsPage({super.key});

  @override
  ConsumerState<FlightRecordsPage> createState() => _FlightRecordsPageState();
}

class _FlightRecordsPageState extends ConsumerState<FlightRecordsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(flightRecordsProvider.notifier).loadNextPage();
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || hours > 0) parts.add('${minutes}m');
    parts.add('${seconds}s');
    return parts.join(' ');
  }

  Future<void> _editFlightDetails(BuildContext context, Flight flight) async {
    showDialog(
      context: context,
      builder: (context) => EditFlightDialog(
        flight: flight,
        onSave: (name, pilotId, airplaneId) {
          ref
              .read(flightRecordsProvider.notifier)
              .updateFlightDetails(
                uuid: flight.uuid,
                name: name,
                pilotId: pilotId,
                airplaneId: airplaneId,
              );
        },
      ),
    );
  }

  Future<void> _deleteFlight(BuildContext context, Flight flight) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('Are you sure you want to delete "${flight.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(flightRecordsProvider.notifier).deleteFlight(flight.uuid);
    }
  }

  Future<void> _shareFlightGpx(BuildContext context, Flight flight) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(blackBoxRepositoryProvider);
      final file = await GpxExportService.generateFlightGpx(flight, repo);
      if (!context.mounted) return;
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No telemetry records found for this flight.'),
          ),
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: flight.name,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.shareError}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recordsAsync = ref.watch(flightRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.flightRecordsTitle), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => ref.read(flightRecordsProvider.notifier).refresh(),
        child: recordsAsync.when(
          data: (state) {
            if (state.flights.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flight_takeoff_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.flightRecordsEmpty,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: state.flights.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.flights.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final flight = state.flights[index];
                final startTimeStr = DateFormat(
                  'dd.MM.yyyy HH:mm',
                ).format(flight.startTime.toLocal());
                final endTimeStr = flight.endTime != null
                    ? DateFormat('HH:mm').format(flight.endTime!.toLocal())
                    : l10n.placeholderDash;

                final duration = flight.endTime != null
                    ? flight.endTime!.difference(flight.startTime)
                    : DateTime.now().toUtc().difference(flight.startTime);

                final isRecording = flight.endTime == null;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isRecording
                          ? Theme.of(context).colorScheme.primary.withAlpha(100)
                          : Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withAlpha(100),
                      width: isRecording ? 2 : 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: isRecording
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          isRecording ? Icons.sensors : Icons.flight,
                          color: isRecording
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        flight.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$startTimeStr - $endTimeStr (${_formatDuration(duration)})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoChip(
                                      icon: Icons.person_outline,
                                      label: l10n.pilot,
                                      value:
                                          flight.pilotId ?? l10n.anonymousPilot,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _InfoChip(
                                      icon: Icons.airplanemode_active,
                                      label: l10n.aircraft,
                                      value:
                                          flight.airplaneId ??
                                          l10n.unknownAircraft,
                                    ),
                                  ),
                                ],
                              ),
                              if (flight.statistics != null)
                                _FlightStatisticsWidget(
                                  stats: flight.statistics!,
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.redAccent,
                                    onPressed: () =>
                                        _deleteFlight(context, flight),
                                    tooltip: l10n.delete,
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(l10n.editSettings),
                                    onPressed: () =>
                                        _editFlightDetails(context, flight),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.share_outlined),
                                    label: Text(l10n.shareGpx),
                                    onPressed: () =>
                                        _shareFlightGpx(context, flight),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(130),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightStatisticsWidget extends ConsumerWidget {
  final FlightStatistics stats;

  const _FlightStatisticsWidget({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final speedUnit = settings.speedUnit;
        final altitudeUnit = settings.altitudeUnit;
        final heightUnit = settings.heightUnit;

        final items = <Widget>[];

        // 1. Max Altitude
        if (stats.maxAltitude != null) {
          final val = altitudeUnit.convertFromMeters(stats.maxAltitude!);
          final unit = altitudeUnit.getMslLabel(l10n);
          items.add(
            _InfoChip(
              icon: Icons.height,
              label: l10n.maxAltitudeLabel,
              value: '${val.toStringAsFixed(0)} $unit',
            ),
          );
        }

        // 2. Ascent / Descent
        if (stats.totalAscent != null || stats.totalDescent != null) {
          final List<String> parts = [];
          if (stats.totalAscent != null) {
            final val = heightUnit.convertFromMeters(stats.totalAscent!);
            parts.add('+${val.toStringAsFixed(0)}');
          } else {
            parts.add('0');
          }
          if (stats.totalDescent != null) {
            final val = heightUnit.convertFromMeters(stats.totalDescent!);
            parts.add('-${val.toStringAsFixed(0)}');
          } else {
            parts.add('0');
          }
          final unit = heightUnit.getLabel(l10n);
          items.add(
            _InfoChip(
              icon: Icons.unfold_more,
              label: '${l10n.totalAscentLabel} / ${l10n.totalDescentLabel}',
              value: '${parts.join(" / ")} $unit',
            ),
          );
        }

        // 3. Avg Altitude
        if (stats.avgAltitude != null) {
          final val = altitudeUnit.convertFromMeters(stats.avgAltitude!);
          final unit = altitudeUnit.getMslLabel(l10n);
          items.add(
            _InfoChip(
              icon: Icons.filter_hdr,
              label: l10n.avgAltitudeLabel,
              value: '${val.toStringAsFixed(0)} $unit',
            ),
          );
        }

        // 4. Max Ground Speed / IAS
        if (stats.maxGroundSpeed != null ||
            stats.maxIndicatedAirSpeed != null) {
          final List<String> parts = [];
          if (stats.maxIndicatedAirSpeed != null) {
            final val = speedUnit.convertFromMs(stats.maxIndicatedAirSpeed!);
            parts.add('${val.toStringAsFixed(0)} ${l10n.iasShortTitle}');
          }
          if (stats.maxGroundSpeed != null) {
            final val = speedUnit.convertFromMs(stats.maxGroundSpeed!);
            parts.add('${val.toStringAsFixed(0)} ${l10n.gsShortTitle}');
          }
          final unit = speedUnit.getAbbreviation(l10n);
          items.add(
            _InfoChip(
              icon: Icons.speed,
              label: l10n.maxSpeedLabel,
              value: '${parts.join(" / ")} $unit',
            ),
          );
        }

        // 5. Avg Ground Speed / IAS
        if (stats.avgGroundSpeed != null ||
            stats.avgIndicatedAirSpeed != null) {
          final List<String> parts = [];
          if (stats.avgIndicatedAirSpeed != null) {
            final val = speedUnit.convertFromMs(stats.avgIndicatedAirSpeed!);
            parts.add('${val.toStringAsFixed(0)} ${l10n.iasShortTitle}');
          }
          if (stats.avgGroundSpeed != null) {
            final val = speedUnit.convertFromMs(stats.avgGroundSpeed!);
            parts.add('${val.toStringAsFixed(0)} ${l10n.gsShortTitle}');
          }
          final unit = speedUnit.getAbbreviation(l10n);
          items.add(
            _InfoChip(
              icon: Icons.slow_motion_video,
              label: l10n.avgSpeedLabel,
              value: '${parts.join(" / ")} $unit',
            ),
          );
        }

        // 6. Flown distance
        if (stats.totalDistance != null) {
          final val = stats.totalDistance!;
          final displayVal = val >= 1000 ? val / 1000 : val;
          final unit = val >= 1000 ? 'km' : 'm';
          items.add(
            _InfoChip(
              icon: Icons.map,
              label: l10n.flownDistanceLabel,
              value: '${displayVal.toStringAsFixed(val >= 1000 ? 2 : 0)} $unit',
            ),
          );
        }

        // 7. Max distance from takeoff
        if (stats.maxDistanceFromTakeoff != null) {
          final val = stats.maxDistanceFromTakeoff!;
          final displayVal = val >= 1000 ? val / 1000 : val;
          final unit = val >= 1000 ? 'km' : 'm';
          items.add(
            _InfoChip(
              icon: Icons.explore,
              label: l10n.maxDistanceTakeoffLabel,
              value: '${displayVal.toStringAsFixed(val >= 1000 ? 2 : 0)} $unit',
            ),
          );
        }

        // 8. Avg Engine RPM
        if (stats.avgEngineRPM != null) {
          items.add(
            _InfoChip(
              icon: Icons.settings_input_component,
              label: l10n.avgRpmLabel,
              value: '${stats.avgEngineRPM!.toStringAsFixed(0)} RPM',
            ),
          );
        }

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(child: items[i]),
                    const SizedBox(width: 8),
                    Expanded(child: items[i + 1]),
                  ],
                ),
              ),
            );
          } else {
            rows.add(
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(child: items[i]),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
