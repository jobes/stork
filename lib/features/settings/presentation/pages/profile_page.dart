import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/pilot.dart';
import '../../domain/models/aircraft.dart';
import '../providers/settings_provider.dart';
import '../providers/pilot_provider.dart';
import '../providers/aircraft_provider.dart';
import '../components/profile_header_card.dart';
import '../components/stats_dashboard.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _unlockedPilotId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(appSettingsProvider);
    final pilotsAsync = ref.watch(pilotStateProvider);
    final aircraftsAsync = ref.watch(aircraftStateProvider);

    final Widget body;
    if (settingsAsync.isLoading || pilotsAsync.isLoading || aircraftsAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (settingsAsync.hasError || pilotsAsync.hasError || aircraftsAsync.hasError) {
      body = Center(child: Text(l10n.errorPrefix));
    } else {
      final settings = settingsAsync.requireValue;
      final pilots = pilotsAsync.requireValue;
      final aircrafts = aircraftsAsync.requireValue;

      final activePilotId = settings.pilotId;
      Pilot? activePilot;
      for (final p in pilots) {
        if (p.id == activePilotId) {
          activePilot = p;
          break;
        }
      }

      final activeAirplaneId = settings.airplaneId;
      Aircraft? activeAircraft;
      for (final a in aircrafts) {
        if (a.id == activeAirplaneId) {
          activeAircraft = a;
          break;
        }
      }

      final airplaneId = settings.airplaneId ?? '';
      final aircraftHoursAsync = airplaneId.isNotEmpty
          ? ref.watch(aircraftHoursProvider(airplaneId))
          : null;

      body = ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          ProfileHeaderCard(
            settings: settings,
            activePilot: activePilot,
            activeAircraft: activeAircraft,
            aircraftHoursAsync: aircraftHoursAsync,
            pilotsAsync: pilotsAsync,
            aircraftsAsync: aircraftsAsync,
            unlockedPilotId: _unlockedPilotId,
            onPilotUnlocked: (id) {
              setState(() {
                _unlockedPilotId = id;
              });
            },
          ),
          const SizedBox(height: 20),
          StatsDashboard(
            activePilot: activePilot,
            activeAircraft: activeAircraft,
            settings: settings,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileAndAircraftPageTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: body,
    );
  }
}
