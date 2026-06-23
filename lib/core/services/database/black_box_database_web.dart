import '../../../features/telemetry/domain/models/flight.dart';
import '../../../features/telemetry/domain/models/telemetry_entry.dart';

class BlackBoxDatabase {
  static Future<dynamic> get database async =>
      throw UnsupportedError('SQLite is not supported on web.');

  static set database(dynamic db) {
    // No-op on web
  }

  static void setupTables(dynamic db) {
    // No-op on web
  }


  static Future<void> resetDatabase() async {
    // No-op on web
  }

  static Future<void> saveFlight(Flight flight) async {
    // No-op on web
  }

  static Future<void> updateFlightEndTime(String uuid, DateTime endTime) async {
    // No-op on web
  }

  static Future<void> insertTelemetryEntries(List<TelemetryEntry> entries) async {
    // No-op on web
  }

  static Future<List<Flight>> getFlights() async {
    return [];
  }

  static Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid) async {
    return [];
  }

  static Future<void> deleteFlight(String uuid) async {
    // No-op on web
  }

  static Future<void> clearAll() async {
    // No-op on web
  }
}
