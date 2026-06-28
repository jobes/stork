import '../models/flight.dart';
import '../models/telemetry_entry.dart';
import '../models/time_based_stats.dart';
abstract class BlackBoxRepository {
  Future<void> saveFlight(Flight flight);
  Future<void> updateFlightEndTime(String uuid, DateTime endTime);
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries);
  Future<List<Flight>> getFlights();
  Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid);
  Future<void> deleteFlight(String uuid);
  Future<void> clearAll();
  Future<List<Flight>> getFlightsPaginated(
    int limit, {
    DateTime? lastStartTime,
    String? lastUuid,
    String? pilotId,
    String? airplaneId,
    bool? pilotAnonymous,
    bool? airplaneAnonymous,
  });
  Future<int> getFlightsCount({
    String? pilotId,
    String? airplaneId,
    bool? pilotAnonymous,
    bool? airplaneAnonymous,
  });
  Future<List<String>> getUniquePilotIds();
  Future<List<String>> getUniqueAirplaneIds();
  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
    String? notes,
  });
  Future<List<TelemetryEntry>> getGpxTelemetryForFlight(String flightUuid);
  Future<void> calculateAndSaveFlightStatistics(String flightUuid);
  Future<void> recoverUnfinishedFlights();
  Future<TimeBasedStats> getPilotTimeStats(String pilotId, {double initialHours = 0.0});
  Future<TimeBasedStats> getAircraftTimeStats(String airplaneId, {double initialHours = 0.0});
}
