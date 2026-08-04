import '../models/airspace_activity_status.dart';

/// Result of splitting the loaded AUP/UUP activities into openAIP airspace ids
/// by their effective status at a given moment.
class AirspaceActivityIdSplit {
  final List<String> activeIds;
  final List<String> inactiveIds;

  const AirspaceActivityIdSplit({
    required this.activeIds,
    required this.inactiveIds,
  });
}

/// Splits [activities] (keyed by openAIP airspace id) into active and inactive
/// id lists, using each activity's effective status at [now] (see
/// [AupAirspaceActivity.statusAt]). Unknown activities are ignored.
///
/// This is a pure function so the map layer filtering can be unit-tested
/// independently of the MapLibre controller.
AirspaceActivityIdSplit splitAirspaceActivityIds(
  Map<String, AupAirspaceActivity> activities,
  DateTime now,
) {
  final active = <String>[];
  final inactive = <String>[];
  for (final activity in activities.values) {
    if (activity.airspaceId.isEmpty) continue;
    switch (activity.statusAt(now)) {
      case AirspaceActivityStatus.active:
        active.add(activity.airspaceId);
      case AirspaceActivityStatus.inactive:
        inactive.add(activity.airspaceId);
      case AirspaceActivityStatus.unknown:
        break;
    }
  }
  return AirspaceActivityIdSplit(activeIds: active, inactiveIds: inactive);
}
