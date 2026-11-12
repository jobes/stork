import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:stork/core/services/database/black_box_database_io.dart';
import 'package:stork/features/telemetry/domain/models/flight.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_entry.dart';

void main() {
  late IoBlackBoxDatabase blackBoxDb;
  late String dbPath;

  setUp(() {
    final tempDir = Directory.systemTemp.createTempSync('blackbox_io_test_');
    dbPath = p.join(tempDir.path, 'test_db.sqlite');
    blackBoxDb = IoBlackBoxDatabase();
    blackBoxDb.dbPathOverride = dbPath;
  });

  tearDown(() async {
    try {
      await blackBoxDb.resetDatabase();
    } catch (_) {}
    try {
      final dir = Directory(p.dirname(dbPath));
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('IoBlackBoxDatabase Concurrency Tests', () {
    test(
      'concurrently awaiting database returns the same instance and only initializes once',
      () async {
        final futures = Future.wait([
          blackBoxDb.database,
          blackBoxDb.database,
          blackBoxDb.database,
        ]);

        final databases = await futures;
        expect(databases[0], isNotNull);
        expect(databases[0], same(databases[1]));
        expect(databases[0], same(databases[2]));
      },
    );

    test(
      'resetting the database allows creating a new database connection instance',
      () async {
        final db1 = await blackBoxDb.database;
        await blackBoxDb.resetDatabase();
        final db2 = await blackBoxDb.database;

        expect(db1, isNot(same(db2)));
      },
    );
  });

  test('migrates telemetry without losing existing flight data', () async {
    final legacyDb = sqlite3.open(dbPath);
    try {
      legacyDb.execute('''
        CREATE TABLE flights (
          uuid TEXT PRIMARY KEY, name TEXT NOT NULL, start_time TEXT NOT NULL,
          end_time TEXT, pilot_id TEXT, airplane_id TEXT, notes TEXT
        );
        CREATE TABLE flight_telemetry (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          flight_uuid TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          is_snapshot INTEGER NOT NULL DEFAULT 0,
          engine_rpm INTEGER,
          FOREIGN KEY (flight_uuid) REFERENCES flights(uuid) ON DELETE CASCADE
        );
        CREATE INDEX idx_telemetry_timestamp ON flight_telemetry (timestamp);
        INSERT INTO flights (uuid, name, start_time)
        VALUES ('legacy', 'Legacy flight', '2026-01-01T00:00:00Z');
        INSERT INTO flight_telemetry (id, flight_uuid, timestamp, is_snapshot, engine_rpm)
        VALUES (42, 'legacy', '2026-01-01T00:00:00Z', 1, 2300);
      ''');
    } finally {
      legacyDb.close();
    }

    final db = await blackBoxDb.database;
    blackBoxDb.setupTables(db); // Opening an already migrated schema is safe.
    await blackBoxDb.insertTelemetryEntries([
      TelemetryEntry(
        flightUuid: null,
        timestamp: DateTime.utc(2026, 1, 2),
        isSnapshot: true,
        data: {'engine_rpm': 1900},
      ),
    ]);

    final flightEntry = (await blackBoxDb.getTelemetryForFlight(
      'legacy',
    )).single;
    expect(flightEntry.id, 42);
    expect(flightEntry.isSnapshot, isTrue);
    expect(flightEntry.data['engine_rpm'], 2300);

    await blackBoxDb.deleteFlight('legacy');
    final remaining = db.select('SELECT * FROM flight_telemetry').single;
    expect(remaining['flight_uuid'], isNull);
    expect(remaining['engine_rpm'], 1900);
    expect(remaining['id'], greaterThan(42));
    expect(db.select('PRAGMA foreign_key_check'), isEmpty);
  });

  group('IoBlackBoxDatabase saveFlight Tests', () {
    test(
      'saveFlight with existing UUID preserves related telemetry entries (ON CONFLICT DO UPDATE)',
      () async {
        final flightUuid = 'conflict-test-uuid';
        final flight = Flight(
          uuid: flightUuid,
          name: 'Initial Flight Name',
          startTime: DateTime.now(),
          pilotId: 'pilot-1',
          airplaneId: 'airplane-1',
        );

        await blackBoxDb.saveFlight(flight);

        // Insert some telemetry associated with the flight
        final entries = [
          TelemetryEntry(
            flightUuid: flightUuid,
            timestamp: DateTime.now(),
            isSnapshot: true,
            data: {'engine_rpm': 2300.0},
          ),
        ];
        await blackBoxDb.insertTelemetryEntries(entries);

        // Check telemetry exists
        var telemetry = await blackBoxDb.getTelemetryForFlight(flightUuid);
        expect(telemetry, hasLength(1));

        // Re-save/upsert the same flight (e.g. updating the name or endTime)
        final updatedFlight = Flight(
          uuid: flightUuid,
          name: 'Updated Flight Name',
          startTime: flight.startTime,
          endTime: DateTime.now(),
          pilotId: 'pilot-1',
          airplaneId: 'airplane-1',
        );
        await blackBoxDb.saveFlight(updatedFlight);

        // Verify flight details were updated
        final flights = await blackBoxDb.getFlights();
        final savedFlight = flights.firstWhere((f) => f.uuid == flightUuid);
        expect(savedFlight.name, equals('Updated Flight Name'));
        expect(savedFlight.endTime, isNotNull);

        // Verify that related telemetry WAS NOT deleted by CASCADE (as it would be under INSERT OR REPLACE)
        telemetry = await blackBoxDb.getTelemetryForFlight(flightUuid);
        expect(telemetry, hasLength(1));
      },
    );
  });
}
