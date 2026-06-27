import '../../../features/telemetry/domain/models/flight.dart';
import '../../../features/telemetry/domain/models/flight_statistics.dart';
import '../../../features/telemetry/domain/models/telemetry_entry.dart';
import '../../../features/telemetry/domain/models/time_based_stats.dart';

import 'black_box_database_stub.dart'
    if (dart.library.io) 'black_box_database_io.dart'
    if (dart.library.html) 'black_box_database_web.dart';



abstract interface class BlackBoxDatabase {
  factory BlackBoxDatabase() => getDatabase();

  Future<void> resetDatabase();
  Future<void> saveFlight(Flight flight);
  Future<void> updateFlightEndTime(String uuid, DateTime endTime);
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries);
  Future<List<Flight>> getFlights();
  Future<List<Flight>> getUnfinishedFlights();
  Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid);
  Future<TelemetryEntry?> getLastTelemetryForFlight(String flightUuid);
  Future<void> deleteFlight(String uuid);
  Future<void> clearAll();
  Future<List<Flight>> getFlightsPaginated(
    int limit, {
    DateTime? lastStartTime,
    String? lastUuid,
  });
  Future<int> getFlightsCount();
  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
    String? notes,
  });
  Future<List<TelemetryEntry>> getGpxTelemetryForFlight(String flightUuid);
  Future<void> saveFlightStatistics(String flightUuid, FlightStatistics stats);
  Future<List<TelemetryEntry>> getTelemetryForFlightPaginated(String flightUuid, int limit, int? lastId);
  Future<void> calculateAndSaveFlightStatistics(String flightUuid);
  Future<TimeBasedStats> getPilotTimeStats(String pilotId, {double initialHours = 0.0});
  Future<TimeBasedStats> getAircraftTimeStats(String airplaneId, {double initialHours = 0.0});
}

