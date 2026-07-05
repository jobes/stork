import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/pilot.dart';
import '../../domain/models/aircraft.dart';
import '../../domain/models/app_settings.dart';
import '../providers/pilot_provider.dart';
import '../providers/aircraft_provider.dart';

class StatsDashboard extends ConsumerWidget {
  final Pilot? activePilot;
  final Aircraft? activeAircraft;
  final AppSettings settings;

  const StatsDashboard({
    super.key,
    required this.activePilot,
    required this.activeAircraft,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activePilot == null) {
      return _buildNoActivePilotDashboard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPilotStatsSection(context, ref, activePilot!),
        if (activeAircraft != null) ...[
          const SizedBox(height: 24),
          _buildAircraftStatsSection(context, ref, activeAircraft!.id),
        ],
      ],
    );
  }

  Widget _buildNoActivePilotDashboard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.4,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 56,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noActivePilot,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noActivePilotInstructions,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPilotStatsSection(
    BuildContext context,
    WidgetRef ref,
    Pilot pilot,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(pilotStatsProvider(pilot.id));
    final theme = Theme.of(context);

    return statsAsync.when(
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
              child: Text(
                l10n.pilotFlightStats,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 90,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  context: context,
                  title: l10n.today,
                  value: _formatHours(l10n, stats.todayHours),
                  flights: stats.todayFlights,
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.thisWeek,
                  value: _formatHours(l10n, stats.thisWeekHours),
                  flights: stats.thisWeekFlights,
                  icon: Icons.calendar_view_week,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.thisMonth,
                  value: _formatHours(l10n, stats.thisMonthHours),
                  flights: stats.thisMonthFlights,
                  icon: Icons.calendar_month,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.thisYear,
                  value: _formatHours(l10n, stats.thisYearHours),
                  flights: stats.thisYearFlights,
                  icon: Icons.calendar_today,
                  color: Colors.teal,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.overall,
                  value: _formatHours(l10n, stats.totalHours),
                  flights: stats.totalFlights,
                  icon: Icons.flight_takeoff,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n.statsCalcError,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildAircraftStatsSection(
    BuildContext context,
    WidgetRef ref,
    String airplaneId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(aircraftStatsProvider(airplaneId));
    final theme = Theme.of(context);

    return statsAsync.when(
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
              child: Text(
                l10n.aircraftFlightStats,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 90,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  context: context,
                  title: l10n.today,
                  value: _formatHours(l10n, stats.todayHours),
                  flights: stats.todayFlights,
                  icon: Icons.today,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.thisWeek,
                  value: _formatHours(l10n, stats.thisWeekHours),
                  flights: stats.thisWeekFlights,
                  icon: Icons.calendar_view_week,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.thisMonth,
                  value: _formatHours(l10n, stats.thisMonthHours),
                  flights: stats.thisMonthFlights,
                  icon: Icons.calendar_month,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.thisYear,
                  value: _formatHours(l10n, stats.thisYearHours),
                  flights: stats.thisYearFlights,
                  icon: Icons.calendar_today,
                  color: Colors.teal,
                ),
                _buildStatCard(
                  context: context,
                  title: l10n.overall,
                  value: _formatHours(l10n, stats.totalHours),
                  flights: stats.totalFlights,
                  icon: Icons.flight_takeoff,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n.aircraftStatsCalcError,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required int flights,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.takeoffsCount(flights),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
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
