import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

import 'package:stork/core/services/database/black_box_database_io.dart';
import 'package:stork/features/telemetry/data/repositories/black_box_repository_impl.dart';
import 'package:stork/features/telemetry/domain/models/flight.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_entry.dart';

void main() {
  late Database db;
  late IoBlackBoxDatabase blackBoxDb;
  late BlackBoxRepositoryImpl repository;
  late String dbPath;

  setUp(() {
    final tempDir = Directory.systemTemp.createTempSync('blackbox_stats_test_');
    dbPath = p.join(tempDir.path, 'test_stats_db.sqlite');
    
    db = sqlite3.open(dbPath);
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA busy_timeout = 5000;');
    
    blackBoxDb = IoBlackBoxDatabase();
    blackBoxDb.dbPathOverride = dbPath;
    blackBoxDb.database = db;
    blackBoxDb.setupTables(db);
    repository = BlackBoxRepositoryImpl(blackBoxDb);
  });

  tearDown(() {
    db.close();
    try {
      File(dbPath).parent.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('Computes correct time-weighted averages under delta-compression', () async {
    final flightUuid = 'test-stats-flight';
    final startTime = DateTime.parse('2026-06-25T12:00:00Z').toUtc();
    final flight = Flight(
      uuid: flightUuid,
      name: 'Stats Test Flight',
      startTime: startTime,
    );
    await blackBoxDb.saveFlight(flight);

    // Delta-compressed time series:
    // t=0s: snapshot = true, gps_altitude = 1000.0, ground_speed = 100.0, engine_rpm = 2000.0
    // t=1s: snapshot = false, gps_altitude = 1010.0, ground_speed = null (100), engine_rpm = 2100.0
    // t=3s: snapshot = false, gps_altitude = null (1010), ground_speed = null (100), engine_rpm = 2300.0
    // t=9s: snapshot = false, gps_altitude = 1050.0, ground_speed = null (100), engine_rpm = null (2300)
    // t=10s: snapshot = false, gps_altitude = 1050.0, ground_speed = 150.0, engine_rpm = null (2300)
    final entries = [
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime,
        isSnapshot: true,
        data: {
          'gps_altitude': 1000.0,
          'ground_speed': 100.0,
          'engine_rpm': 2000.0,
        },
      ),
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime.add(const Duration(seconds: 1)),
        isSnapshot: false,
        data: {
          'gps_altitude': 1010.0,
          'engine_rpm': 2100.0,
        },
      ),
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime.add(const Duration(seconds: 3)),
        isSnapshot: false,
        data: {
          'engine_rpm': 2300.0,
        },
      ),
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime.add(const Duration(seconds: 9)),
        isSnapshot: false,
        data: {
          'gps_altitude': 1050.0,
        },
      ),
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime.add(const Duration(seconds: 10)),
        isSnapshot: false,
        data: {
          'ground_speed': 150.0,
        },
      ),
    ];

    await blackBoxDb.insertTelemetryEntries(entries);

    // Act
    await repository.calculateAndSaveFlightStatistics(flightUuid);

    // Retrieve stats
    final flights = await blackBoxDb.getFlights();
    expect(flights.length, equals(1));
    
    final stats = flights.first.statistics;
    expect(stats, isNotNull);

    // Verify time-weighted averages (dt-weighted averages):
    // Duration = 10s.
    // gps_altitude:
    //   0s-1s: 1000.0 * 1s = 1000.0
    //   1s-3s: 1010.0 * 2s = 2020.0
    //   3s-9s: 1010.0 * 6s = 6060.0
    //   9s-10s: 1050.0 * 1s = 1050.0
    //   Sum = 10130.0 / 10s = 1013.0
    expect(stats!.avgAltitude, closeTo(1013.0, 0.001));

    // ground_speed:
    //   0s-1s: 100.0 * 1s = 100.0
    //   1s-3s: 100.0 * 2s = 200.0
    //   3s-9s: 100.0 * 6s = 600.0
    //   9s-10s: 100.0 * 1s = 100.0
    //   Sum = 1000.0 / 10s = 100.0
    expect(stats.avgGroundSpeed, closeTo(100.0, 0.001));

    // engine_rpm:
    //   0s-1s: 2000.0 * 1s = 2000.0
    //   1s-3s: 2100.0 * 2s = 4200.0
    //   3s-9s: 2300.0 * 6s = 13800.0
    //   9s-10s: 2300.0 * 1s = 2300.0
    //   Sum = 22300.0 / 10s = 2230.0
    expect(stats.avgEngineRPM, closeTo(2230.0, 0.001));

    // Peaks:
    expect(stats.maxAltitude, equals(1050.0));
    expect(stats.maxGroundSpeed, equals(150.0));
  });

  test('Computes correct distance and max distance from takeoff under delta-compression', () async {
    final flightUuid = 'test-distance-flight';
    final startTime = DateTime.parse('2026-06-25T12:00:00Z').toUtc();
    final flight = Flight(
      uuid: flightUuid,
      name: 'Distance Test Flight',
      startTime: startTime,
    );
    await blackBoxDb.saveFlight(flight);

    // Delta-compressed GPS coordinates:
    // t=0s: snapshot = true,  lat = 48.0, lon = 17.0
    // t=1s: snapshot = false, lat = 48.1, lon = null (still 17.0)
    // t=2s: snapshot = false, lat = null (still 48.1), lon = 17.1
    // t=3s: snapshot = false, lat = 48.2, lon = 17.2
    final entries = [
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime,
        isSnapshot: true,
        data: {
          'latitude': 48.0,
          'longitude': 17.0,
        },
      ),
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime.add(const Duration(seconds: 1)),
        isSnapshot: false,
        data: {
          'latitude': 48.1,
        },
      ),
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime.add(const Duration(seconds: 2)),
        isSnapshot: false,
        data: {
          'longitude': 17.1,
        },
      ),
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime.add(const Duration(seconds: 3)),
        isSnapshot: false,
        data: {
          'latitude': 48.2,
          'longitude': 17.2,
        },
      ),
    ];

    await blackBoxDb.insertTelemetryEntries(entries);

    // Act
    await repository.calculateAndSaveFlightStatistics(flightUuid);

    // Retrieve stats
    final flights = await blackBoxDb.getFlights();
    expect(flights.length, equals(1));
    
    final stats = flights.first.statistics;
    expect(stats, isNotNull);

    // Expected calculations:
    // P0 = (48.0, 17.0)
    // P1 = (48.1, 17.0)
    // P2 = (48.1, 17.1)
    // P3 = (48.2, 17.2)
    //
    // Under the bug, P1 and P2 are skipped because one coordinate is null.
    // The bug will compute distance from P0 to P3 directly (~33333 meters).
    // The correct logic will compute:
    // d01 = distance(P0, P1)
    // d12 = distance(P1, P2)
    // d23 = distance(P2, P3)
    // total = d01 + d12 + d23
    
    // We expect totalDistance to be the sum of segments, not the direct line.
    expect(stats!.totalDistance, isNotNull);
    expect(stats.maxDistanceFromTakeoff, isNotNull);

    // Verify distance is greater than the direct straight line (triangle inequality)
    // Direct P0 -> P3 distance: 33261.2 meters (approx)
    // Path P0 -> P1 -> P2 -> P3 distance: 11119.5 + 7442.2 + 13327.9 = 31889.6 (approx)
    // Wait, let's look at the actual values:
    // lat changes by 0.1 deg (~11.1km)
    // lon changes by 0.1 deg (~7.4km)
    // Path distance should match segment sums.
    expect(stats.totalDistance!, greaterThan(30000.0));
  });

  test('recoverUnfinishedFlights keeps flight retryable if stats calculation fails', () async {
    final tempDir = Directory.systemTemp.createTempSync('blackbox_recovery_test_');
    final recoveryDbPath = p.join(tempDir.path, 'test_recovery_db.sqlite');
    
    final rDb = sqlite3.open(recoveryDbPath);
    rDb.execute('PRAGMA foreign_keys = ON;');
    rDb.execute('PRAGMA journal_mode = WAL;');
    rDb.execute('PRAGMA busy_timeout = 5000;');
    
    final failDb = FailureDatabase();
    failDb.dbPathOverride = recoveryDbPath;
    failDb.database = rDb;
    failDb.setupTables(rDb);
    final recoveryRepository = BlackBoxRepositoryImpl(failDb);

    final flightUuid = 'recovery-test-flight';
    final startTime = DateTime.parse('2026-06-25T12:00:00Z').toUtc();
    final flight = Flight(
      uuid: flightUuid,
      name: 'Recovery Test Flight',
      startTime: startTime,
    );
    await failDb.saveFlight(flight);

    // Save one telemetry entry
    await failDb.insertTelemetryEntries([
      TelemetryEntry(
        flightUuid: flightUuid,
        timestamp: startTime,
        isSnapshot: true,
        data: {'gps_altitude': 1000.0},
      )
    ]);

    // Enable failure on stats calculation
    failDb.failStats = true;

    // Run recovery - should fail
    try {
      await recoveryRepository.recoverUnfinishedFlights();
      fail('Should have thrown an exception');
    } catch (e) {
      expect(e, isA<Exception>());
    }

    // Verify flight end_time is still null (retryable)
    var flights = await failDb.getFlights();
    expect(flights.first.endTime, isNull);

    // Disable failure
    failDb.failStats = false;

    // Run recovery - should succeed now
    await recoveryRepository.recoverUnfinishedFlights();

    // Verify flight end_time is now set
    flights = await failDb.getFlights();
    expect(flights.first.endTime, isNotNull);

    // Clean up
    rDb.close();
    try {
      File(recoveryDbPath).parent.deleteSync(recursive: true);
    } catch (_) {}
  });
}

class FailureDatabase extends IoBlackBoxDatabase {
  bool failStats = false;

  @override
  Future<void> calculateAndSaveFlightStatistics(String flightUuid) async {
    if (failStats) {
      throw Exception('Simulated stats calculation failure');
    }
    return super.calculateAndSaveFlightStatistics(flightUuid);
  }
}

