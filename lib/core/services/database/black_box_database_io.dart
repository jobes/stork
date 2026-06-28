import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../../features/telemetry/domain/models/flight.dart';
import '../../../features/telemetry/domain/models/telemetry_entry.dart';
import '../../../features/telemetry/domain/models/telemetry_state.dart';
import '../../../features/telemetry/domain/utils/flight_statistics_calculator.dart';
import '../../../features/telemetry/domain/models/flight_statistics.dart';
import '../../../features/telemetry/domain/models/time_based_stats.dart';

import 'black_box_database.dart';

BlackBoxDatabase getDatabase() => IoBlackBoxDatabase();

class IoBlackBoxDatabase implements BlackBoxDatabase {
  Database? _db;
  Future<Database>? _initFuture;
  
  @visibleForTesting
  String? dbPathOverride;

  @visibleForTesting
  set database(Database? db) {
    _db = db;
    _initFuture = null;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_initFuture != null) return _initFuture!;

    _initFuture = _initDatabase().then((db) {
      _db = db;
      return db;
    }).catchError((Object e, StackTrace s) {
      _initFuture = null;
      throw e;
    });

    return _initFuture!;
  }

  Future<String> get _dbPath async {
    if (dbPathOverride != null) return dbPathOverride!;
    if (Platform.isAndroid) {
      try {
        final dirs = await getExternalStorageDirectories();
        if (dirs != null && dirs.isNotEmpty) {
          final sdCardDir = dirs.firstWhere(
            (dir) => !dir.path.contains('emulated'),
            orElse: () => dirs.first,
          );
          return p.join(sdCardDir.path, 'stork_blackbox.db');
        }
      } catch (e) {
        debugPrint('Failed to resolve external storage directories: $e');
      }
    }

    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'stork_blackbox.db');
  }

  Future<Database> _initDatabase() async {
    final path = await _dbPath;
    final db = sqlite3.open(path);
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA busy_timeout = 5000;');
    db.execute('PRAGMA synchronous = FULL;');
    setupTables(db);
    return db;
  }

  @override
  Future<void> resetDatabase() async {
    if (_db != null) {
      _db!.close();
      _db = null;
    }
    _initFuture = null;
    final path = await _dbPath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final walFile = File('$path-wal');
    if (await walFile.exists()) {
      await walFile.delete();
    }
    final shmFile = File('$path-shm');
    if (await shmFile.exists()) {
      await shmFile.delete();
    }
    await database;
  }
  void setupTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS flights (
          uuid TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          pilot_id TEXT,
          airplane_id TEXT,
          notes TEXT
      );
    ''');



    final telemetryColumns = [
      'id INTEGER PRIMARY KEY AUTOINCREMENT',
      'flight_uuid TEXT NOT NULL',
      'timestamp TEXT NOT NULL',
      'is_snapshot INTEGER NOT NULL DEFAULT 0',
    ];

    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      telemetryColumns.add('${field.dbColumnName} ${field.dbType}');
    }

    db.execute('''
      CREATE TABLE IF NOT EXISTS flight_telemetry (
          ${telemetryColumns.join(', ')},
          FOREIGN KEY (flight_uuid) REFERENCES flights(uuid) ON DELETE CASCADE
      );
    ''');

    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_telemetry_flight_id ON flight_telemetry (flight_uuid, id);',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp ON flight_telemetry (timestamp);',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_flights_start_time ON flights (start_time DESC);',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_flights_pilot_id ON flights (pilot_id);',
    );
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_flights_airplane_id ON flights (airplane_id);',
    );

    db.execute('''
      CREATE TABLE IF NOT EXISTS flight_statistics (
          flight_uuid TEXT PRIMARY KEY,
          max_altitude REAL,
          total_ascent REAL,
          total_descent REAL,
          avg_altitude REAL,
          max_ground_speed REAL,
          max_indicated_air_speed REAL,
          avg_ground_speed REAL,
          avg_indicated_air_speed REAL,
          total_distance REAL,
          max_distance_from_takeoff REAL,
          avg_engine_rpm REAL,
          FOREIGN KEY (flight_uuid) REFERENCES flights(uuid) ON DELETE CASCADE
      );
    ''');

    _migrateSchema(db);
  }

  void _migrateSchema(Database db) {

    // Telemetry columns migration
    final pragmaResults = db.select('PRAGMA table_info(flight_telemetry)');
    final existingColumns = pragmaResults
        .map((row) => row['name'] as String)
        .toSet();

    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      final colName = field.dbColumnName;
      if (!existingColumns.contains(colName)) {
        db.execute(
          'ALTER TABLE flight_telemetry ADD COLUMN $colName ${field.dbType}',
        );
      }
    }
  }

  @override
  Future<void> saveFlight(Flight flight) async {
    final db = await database;
    final stmt = db.prepare('''
      INSERT INTO flights (uuid, name, start_time, end_time, pilot_id, airplane_id, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(uuid) DO UPDATE SET
        name = excluded.name,
        start_time = excluded.start_time,
        end_time = excluded.end_time,
        pilot_id = excluded.pilot_id,
        airplane_id = excluded.airplane_id,
        notes = excluded.notes
    ''');
    stmt.execute([
      flight.uuid,
      flight.name,
      flight.startTime.toIso8601String(),
      flight.endTime?.toIso8601String(),
      flight.pilotId,
      flight.airplaneId,
      flight.notes,
    ]);
    stmt.close();
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  }

  @override
  Future<void> updateFlightEndTime(String uuid, DateTime endTime) async {
    final db = await database;
    final stmt = db.prepare('''
      UPDATE flights SET end_time = ? WHERE uuid = ?
    ''');
    stmt.execute([endTime.toIso8601String(), uuid]);
    stmt.close();
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  }

  @override
  Future<void> insertTelemetryEntries(List<TelemetryEntry> entries) async {
    if (entries.isEmpty) return;
    
    // In unit tests, run synchronously to prevent conflicts with fakeAsync 
    // and to support pre-injected mocked/in-memory database connections.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      final db = await database;
      _insertTelemetryEntriesSync(db, entries);
      return;
    }
    
    // In production, offload writes to a background Isolate.
    // Since we use PRAGMA synchronous = FULL to ensure flight data is physically
    // committed to disk (preventing data loss during crashes), the commit operation
    // performs a blocking fsync. Offloading keeps the main UI thread completely fluid.
    final path = await _dbPath;
    await Isolate.run(() => _insertTelemetryEntriesIsolate(path, entries));
  }

  Flight _mapFlightFromRow(Row row) {
    FlightStatistics? stats;
    if (row['max_altitude'] != null ||
        row['total_distance'] != null ||
        row['max_ground_speed'] != null ||
        row['avg_altitude'] != null ||
        row['avg_engine_rpm'] != null ||
        row['avg_ground_speed'] != null) {
      stats = FlightStatistics(
        maxAltitude: row['max_altitude'] as double?,
        totalAscent: row['total_ascent'] as double?,
        totalDescent: row['total_descent'] as double?,
        avgAltitude: row['avg_altitude'] as double?,
        maxGroundSpeed: row['max_ground_speed'] as double?,
        maxIndicatedAirSpeed: row['max_indicated_air_speed'] as double?,
        avgGroundSpeed: row['avg_ground_speed'] as double?,
        avgIndicatedAirSpeed: row['avg_indicated_air_speed'] as double?,
        totalDistance: row['total_distance'] as double?,
        maxDistanceFromTakeoff: row['max_distance_from_takeoff'] as double?,
        avgEngineRPM: row['avg_engine_rpm'] as double?,
      );
    }
    return Flight(
      uuid: row['uuid'] as String,
      name: row['name'] as String,
      startTime: DateTime.parse(row['start_time'] as String).toUtc(),
      endTime: row['end_time'] != null
          ? DateTime.parse(row['end_time'] as String).toUtc()
          : null,
      pilotId: row['pilot_id'] as String?,
      airplaneId: row['airplane_id'] as String?,
      notes: row['notes'] as String?,
      statistics: stats,
    );
  }

  @override
  Future<List<Flight>> getFlights() async {
    final db = await database;
    final results = db.select('''
      SELECT f.uuid, f.name, f.start_time, f.end_time, f.pilot_id, f.airplane_id, f.notes,
             s.max_altitude, s.total_ascent, s.total_descent, s.avg_altitude,
             s.max_ground_speed, s.max_indicated_air_speed, s.avg_ground_speed, s.avg_indicated_air_speed,
             s.total_distance, s.max_distance_from_takeoff, s.avg_engine_rpm
      FROM flights f
      LEFT JOIN flight_statistics s ON f.uuid = s.flight_uuid
      ORDER BY f.start_time DESC
    ''');
    return results.map(_mapFlightFromRow).toList();
  }

  @override
  Future<List<Flight>> getUnfinishedFlights() async {
    final db = await database;
    final results = db.select('''
      SELECT f.uuid, f.name, f.start_time, f.end_time, f.pilot_id, f.airplane_id, f.notes,
             s.max_altitude, s.total_ascent, s.total_descent, s.avg_altitude,
             s.max_ground_speed, s.max_indicated_air_speed, s.avg_ground_speed, s.avg_indicated_air_speed,
             s.total_distance, s.max_distance_from_takeoff, s.avg_engine_rpm
      FROM flights f
      LEFT JOIN flight_statistics s ON f.uuid = s.flight_uuid
      WHERE f.end_time IS NULL
      ORDER BY f.start_time ASC
    ''');
    return results.map(_mapFlightFromRow).toList();
  }

  @override
  Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid) async {
    final db = await database;

    final columns = ['id', 'flight_uuid', 'timestamp', 'is_snapshot'];
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      columns.add(field.dbColumnName);
    }

    final query =
        '''
      SELECT ${columns.join(', ')} 
      FROM flight_telemetry 
      WHERE flight_uuid = ? 
      ORDER BY id ASC
    ''';

    final results = db.select(query, [flightUuid]);
    return results.map((row) {
      final telemetryData = <String, dynamic>{};
      for (final field in TelemetryField.values.where(
        (f) => f.isBlackBoxField,
      )) {
        final colName = field.dbColumnName;
        final val = row[colName];
        if (val != null) {
          telemetryData[colName] = field.deserialize(val);
        }
      }

      return TelemetryEntry(
        id: row['id'] as int?,
        flightUuid: row['flight_uuid'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String).toUtc(),
        isSnapshot: (row['is_snapshot'] as int? ?? 0) == 1,
        data: telemetryData,
      );
    }).toList();
  }

  @override
  Future<TelemetryEntry?> getLastTelemetryForFlight(String flightUuid) async {
    final db = await database;

    final columns = ['id', 'flight_uuid', 'timestamp', 'is_snapshot'];
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      columns.add(field.dbColumnName);
    }

    final query = '''
      SELECT ${columns.join(', ')} 
      FROM flight_telemetry 
      WHERE flight_uuid = ? 
      ORDER BY id DESC
      LIMIT 1
    ''';

    final results = db.select(query, [flightUuid]);
    if (results.isEmpty) return null;

    final row = results.first;
    final telemetryData = <String, dynamic>{};
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      final colName = field.dbColumnName;
      final val = row[colName];
      if (val != null) {
        telemetryData[colName] = field.deserialize(val);
      }
    }

    return TelemetryEntry(
      id: row['id'] as int?,
      flightUuid: row['flight_uuid'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String).toUtc(),
      isSnapshot: (row['is_snapshot'] as int? ?? 0) == 1,
      data: telemetryData,
    );
  }

  @override
  Future<void> deleteFlight(String uuid) async {
    final db = await database;
    final stmt = db.prepare('DELETE FROM flights WHERE uuid = ?');
    stmt.execute([uuid]);
    stmt.close();
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  }

  @override
  Future<void> clearAll() async {
    final db = await database;
    db.execute('DELETE FROM flights');
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  }

  @override
  Future<List<Flight>> getFlightsPaginated(
    int limit, {
    DateTime? lastStartTime,
    String? lastUuid,
    String? pilotId,
    String? airplaneId,
    bool? pilotAnonymous,
    bool? airplaneAnonymous,
  }) async {
    final db = await database;
    final lastStartTimeStr = lastStartTime?.toIso8601String();

    final whereClauses = <String>[];
    final params = <dynamic>[];

    if (lastStartTimeStr != null && lastUuid != null) {
      whereClauses.add('(f.start_time < ? OR (f.start_time = ? AND f.uuid < ?))');
      params.addAll([lastStartTimeStr, lastStartTimeStr, lastUuid]);
    }

    if (pilotAnonymous == true) {
      whereClauses.add('f.pilot_id IS NULL');
    } else if (pilotId != null) {
      whereClauses.add('f.pilot_id = ?');
      params.add(pilotId);
    }

    if (airplaneAnonymous == true) {
      whereClauses.add('f.airplane_id IS NULL');
    } else if (airplaneId != null) {
      whereClauses.add('f.airplane_id = ?');
      params.add(airplaneId);
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    params.add(limit);
    final limitParamIdx = params.length;

    final sql = '''
      SELECT f.uuid, f.name, f.start_time, f.end_time, f.pilot_id, f.airplane_id, f.notes,
             s.max_altitude, s.total_ascent, s.total_descent, s.avg_altitude,
             s.max_ground_speed, s.max_indicated_air_speed, s.avg_ground_speed, s.avg_indicated_air_speed,
             s.total_distance, s.max_distance_from_takeoff, s.avg_engine_rpm
      FROM flights f
      LEFT JOIN flight_statistics s ON f.uuid = s.flight_uuid
      $whereString
      ORDER BY f.start_time DESC, f.uuid DESC LIMIT ?$limitParamIdx
    ''';

    final results = db.select(sql, params);
    return results.map(_mapFlightFromRow).toList();
  }

  @override
  Future<int> getFlightsCount({
    String? pilotId,
    String? airplaneId,
    bool? pilotAnonymous,
    bool? airplaneAnonymous,
  }) async {
    final db = await database;

    final whereClauses = <String>[];
    final params = <dynamic>[];

    if (pilotAnonymous == true) {
      whereClauses.add('pilot_id IS NULL');
    } else if (pilotId != null) {
      whereClauses.add('pilot_id = ?');
      params.add(pilotId);
    }

    if (airplaneAnonymous == true) {
      whereClauses.add('airplane_id IS NULL');
    } else if (airplaneId != null) {
      whereClauses.add('airplane_id = ?');
      params.add(airplaneId);
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final sql = 'SELECT COUNT(*) as count FROM flights $whereString';

    final results = db.select(sql, params);
    if (results.isEmpty) return 0;
    return results.first['count'] as int;
  }

  @override
  Future<void> updateFlightDetails({
    required String uuid,
    required String name,
    String? pilotId,
    String? airplaneId,
    String? notes,
  }) async {
    final db = await database;
    final stmt = db.prepare('''
      UPDATE flights 
      SET name = ?, pilot_id = ?, airplane_id = ?, notes = ? 
      WHERE uuid = ?
    ''');
    stmt.execute([name, pilotId, airplaneId, notes, uuid]);
    stmt.close();
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  }

  @override
  Future<List<TelemetryEntry>> getGpxTelemetryForFlight(
    String flightUuid,
  ) async {
    final db = await database;

    final latCol = TelemetryField.latitude.dbColumnName;
    final lonCol = TelemetryField.longitude.dbColumnName;
    final altCol = TelemetryField.gpsAltitude.dbColumnName;

    final query = '''
      SELECT id, flight_uuid, timestamp, is_snapshot, $latCol, $lonCol, $altCol
      FROM flight_telemetry 
      WHERE flight_uuid = ? 
      ORDER BY id ASC
    ''';

    final results = db.select(query, [flightUuid]);
    return results.map((row) {
      final telemetryData = <String, dynamic>{};

      final lat = row[latCol];
      if (lat != null) telemetryData[latCol] = lat;

      final lon = row[lonCol];
      if (lon != null) telemetryData[lonCol] = lon;

      final alt = row[altCol];
      if (alt != null) telemetryData[altCol] = alt;

      return TelemetryEntry(
        id: row['id'] as int?,
        flightUuid: row['flight_uuid'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String).toUtc(),
        isSnapshot: (row['is_snapshot'] as int? ?? 0) == 1,
        data: telemetryData,
      );
    }).toList();
  }

  @override
  Future<void> saveFlightStatistics(
    String flightUuid,
    FlightStatistics stats,
  ) async {
    final db = await database;
    final stmt = db.prepare('''
      INSERT OR REPLACE INTO flight_statistics (
        flight_uuid, max_altitude, total_ascent, total_descent, avg_altitude,
        max_ground_speed, max_indicated_air_speed, avg_ground_speed, avg_indicated_air_speed,
        total_distance, max_distance_from_takeoff, avg_engine_rpm
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    stmt.execute([
      flightUuid,
      stats.maxAltitude,
      stats.totalAscent,
      stats.totalDescent,
      stats.avgAltitude,
      stats.maxGroundSpeed,
      stats.maxIndicatedAirSpeed,
      stats.avgGroundSpeed,
      stats.avgIndicatedAirSpeed,
      stats.totalDistance,
      stats.maxDistanceFromTakeoff,
      stats.avgEngineRPM,
    ]);
    stmt.close();
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  }

  @override
  Future<List<TelemetryEntry>> getTelemetryForFlightPaginated(
    String flightUuid,
    int limit,
    int? lastId,
  ) async {
    final db = await database;

    final columns = ['id', 'flight_uuid', 'timestamp', 'is_snapshot'];
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      columns.add(field.dbColumnName);
    }

    String query;
    List<Object?> params;
    if (lastId != null) {
      query = '''
        SELECT ${columns.join(', ')} 
        FROM flight_telemetry 
        WHERE flight_uuid = ? AND id > ?
        ORDER BY id ASC
        LIMIT ?
      ''';
      params = [flightUuid, lastId, limit];
    } else {
      query = '''
        SELECT ${columns.join(', ')} 
        FROM flight_telemetry 
        WHERE flight_uuid = ? 
        ORDER BY id ASC
        LIMIT ?
      ''';
      params = [flightUuid, limit];
    }

    final results = db.select(query, params);
    return results.map((row) {
      final telemetryData = <String, dynamic>{};
      for (final field in TelemetryField.values.where(
        (f) => f.isBlackBoxField,
      )) {
        final colName = field.dbColumnName;
        final val = row[colName];
        if (val != null) {
          telemetryData[colName] = field.deserialize(val);
        }
      }

      return TelemetryEntry(
        id: row['id'] as int?,
        flightUuid: row['flight_uuid'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String).toUtc(),
        isSnapshot: (row['is_snapshot'] as int? ?? 0) == 1,
        data: telemetryData,
      );
    }).toList();
  }
  @override
  Future<void> calculateAndSaveFlightStatistics(String flightUuid) async {
    final path = await _dbPath;
    await Isolate.run(() => _calculateAndSaveStatsIsolate(path, flightUuid));
  }

  TimeBasedStats _calculateStatsFromResults(ResultSet results, double initialHours) {
    if (results.isEmpty) return TimeBasedStats.empty();
    final row = results.first;
    
    return TimeBasedStats(
      totalHours: initialHours + (row['total_hours'] as num? ?? 0.0).toDouble(),
      thisYearHours: (row['year_hours'] as num? ?? 0.0).toDouble(),
      thisMonthHours: (row['month_hours'] as num? ?? 0.0).toDouble(),
      thisWeekHours: (row['week_hours'] as num? ?? 0.0).toDouble(),
      todayHours: (row['today_hours'] as num? ?? 0.0).toDouble(),
      totalFlights: (row['total_flights'] as num? ?? 0).toInt(),
      thisYearFlights: (row['year_flights'] as num? ?? 0).toInt(),
      thisMonthFlights: (row['month_flights'] as num? ?? 0).toInt(),
      thisWeekFlights: (row['week_flights'] as num? ?? 0).toInt(),
      todayFlights: (row['today_flights'] as num? ?? 0).toInt(),
    );
  }

  String _buildStatsQuery(String filterColumn) {
    return '''
      WITH flight_durations AS (
        SELECT 
          start_time,
          (julianday(COALESCE(end_time, ?)) - julianday(start_time)) * 24.0 as hours
        FROM flights
        WHERE $filterColumn = ?
      )
      SELECT 
        SUM(hours) as total_hours,
        COUNT(*) as total_flights,
        
        SUM(CASE WHEN start_time >= ? THEN hours ELSE 0 END) as year_hours,
        SUM(CASE WHEN start_time >= ? THEN 1 ELSE 0 END) as year_flights,
        
        SUM(CASE WHEN start_time >= ? THEN hours ELSE 0 END) as month_hours,
        SUM(CASE WHEN start_time >= ? THEN 1 ELSE 0 END) as month_flights,
        
        SUM(CASE WHEN start_time >= ? THEN hours ELSE 0 END) as week_hours,
        SUM(CASE WHEN start_time >= ? THEN 1 ELSE 0 END) as week_flights,
        
        SUM(CASE WHEN start_time >= ? THEN hours ELSE 0 END) as today_hours,
        SUM(CASE WHEN start_time >= ? THEN 1 ELSE 0 END) as today_flights
      FROM flight_durations;
    ''';
  }

  List<Object?> _buildStatsParams(String filterValue) {
    final now = DateTime.now().toUtc();
    final nowStr = now.toIso8601String();
    
    final localNow = DateTime.now();
    final todayLimit = DateTime(localNow.year, localNow.month, localNow.day).toUtc().toIso8601String();
    
    final dayOfWeek = localNow.weekday; // 1 = Monday, 7 = Sunday
    final startDay = localNow.subtract(Duration(days: dayOfWeek - 1));
    final weekLimit = DateTime(startDay.year, startDay.month, startDay.day).toUtc().toIso8601String();
    
    final monthLimit = DateTime(localNow.year, localNow.month, 1).toUtc().toIso8601String();
    final yearLimit = DateTime(localNow.year, 1, 1).toUtc().toIso8601String();

    return [
      nowStr,
      filterValue,
      yearLimit, yearLimit,
      monthLimit, monthLimit,
      weekLimit, weekLimit,
      todayLimit, todayLimit,
    ];
  }

  @override
  Future<TimeBasedStats> getPilotTimeStats(String pilotId, {double initialHours = 0.0}) async {
    final db = await database;
    final results = db.select(_buildStatsQuery('pilot_id'), _buildStatsParams(pilotId));
    return _calculateStatsFromResults(results, initialHours);
  }

  @override
  Future<TimeBasedStats> getAircraftTimeStats(String airplaneId, {double initialHours = 0.0}) async {
    final db = await database;
    final results = db.select(_buildStatsQuery('airplane_id'), _buildStatsParams(airplaneId));
    return _calculateStatsFromResults(results, initialHours);
  }

  @override
  Future<List<String>> getUniquePilotIds() async {
    final db = await database;
    final results = db.select('SELECT DISTINCT pilot_id FROM flights WHERE pilot_id IS NOT NULL');
    return results.map((r) => r['pilot_id'] as String).toList();
  }

  @override
  Future<List<String>> getUniqueAirplaneIds() async {
    final db = await database;
    final results = db.select('SELECT DISTINCT airplane_id FROM flights WHERE airplane_id IS NOT NULL');
    return results.map((r) => r['airplane_id'] as String).toList();
  }

}

void _calculateAndSaveStatsIsolate(String dbPath, String flightUuid) {
  final db = sqlite3.open(dbPath);
  db.execute('PRAGMA foreign_keys = ON;');
  db.execute('PRAGMA journal_mode = WAL;');
  db.execute('PRAGMA busy_timeout = 5000;');
  try {
    const int limit = 5000;
    int? lastId;
    bool hasMore = true;

    final calculator = FlightStatisticsCalculator();

    while (hasMore) {
      final columns = ['id', 'flight_uuid', 'timestamp', 'is_snapshot'];
      for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
        columns.add(field.dbColumnName);
      }

      String query;
      List<Object?> params;
      if (lastId != null) {
        query = '''
          SELECT ${columns.join(', ')} 
          FROM flight_telemetry 
          WHERE flight_uuid = ? AND id > ?
          ORDER BY id ASC
          LIMIT ?
        ''';
        params = [flightUuid, lastId, limit];
      } else {
        query = '''
          SELECT ${columns.join(', ')} 
          FROM flight_telemetry 
          WHERE flight_uuid = ? 
          ORDER BY id ASC
          LIMIT ?
        ''';
        params = [flightUuid, limit];
      }

      final seqResult = db.select(query, params);

      if (seqResult.isEmpty) {
        break;
      }

      final entries = seqResult.map((row) {
        final telemetryData = <String, dynamic>{};
        for (final field in TelemetryField.values.where(
          (f) => f.isBlackBoxField,
        )) {
          final colName = field.dbColumnName;
          final val = row[colName];
          if (val != null) {
            telemetryData[colName] = field.deserialize(val);
          }
        }

        return TelemetryEntry(
          id: row['id'] as int?,
          flightUuid: row['flight_uuid'] as String,
          timestamp: DateTime.parse(row['timestamp'] as String).toUtc(),
          isSnapshot: (row['is_snapshot'] as int? ?? 0) == 1,
          data: telemetryData,
        );
      }).toList();

      calculator.addEntries(entries);

      lastId = entries.last.id;
      if (entries.length < limit) {
        hasMore = false;
      }
    }

    final stats = calculator.getStatistics();

    // Insert or Replace into flight_statistics
    final stmt = db.prepare('''
      INSERT OR REPLACE INTO flight_statistics (
        flight_uuid, max_altitude, total_ascent, total_descent, avg_altitude,
        max_ground_speed, max_indicated_air_speed, avg_ground_speed, avg_indicated_air_speed,
        total_distance, max_distance_from_takeoff, avg_engine_rpm
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    stmt.execute([
      flightUuid,
      stats.maxAltitude,
      stats.totalAscent,
      stats.totalDescent,
      stats.avgAltitude,
      stats.maxGroundSpeed,
      stats.maxIndicatedAirSpeed,
      stats.avgGroundSpeed,
      stats.avgIndicatedAirSpeed,
      stats.totalDistance,
      stats.maxDistanceFromTakeoff,
      stats.avgEngineRPM,
    ]);
    stmt.close();
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  } finally {
    db.close();
  }
}

// Runs on a background isolate. It must open a separate connection to the SQLite database
// since raw sqlite3 pointers cannot be safely shared across Isolates.
void _insertTelemetryEntriesIsolate(String dbPath, List<TelemetryEntry> entries) {
  final db = sqlite3.open(dbPath);
  db.execute('PRAGMA foreign_keys = ON;');
  db.execute('PRAGMA journal_mode = WAL;');
  db.execute('PRAGMA busy_timeout = 5000;');
  // Set synchronous = FULL on this background connection to force fsync calls
  // on commits, ensuring flight logs are physically safe on the storage medium.
  db.execute('PRAGMA synchronous = FULL;');
  try {
    _insertTelemetryEntriesSync(db, entries);
  } finally {
    db.close();
  }
}

void _insertTelemetryEntriesSync(Database db, List<TelemetryEntry> entries) {
  db.execute('BEGIN TRANSACTION');
  try {
    final columns = ['flight_uuid', 'timestamp', 'is_snapshot'];
    final placeholders = ['?', '?', '?'];

    for (final field in TelemetryField.values.where(
      (f) => f.isBlackBoxField,
    )) {
      columns.add(field.dbColumnName);
      placeholders.add('?');
    }

    final query =
        'INSERT INTO flight_telemetry (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    final stmt = db.prepare(query);

    for (final entry in entries) {
      final queryParams = <Object?>[
        entry.flightUuid,
        entry.timestamp.toIso8601String(),
        entry.isSnapshot ? 1 : 0,
      ];

      for (final field in TelemetryField.values.where(
        (f) => f.isBlackBoxField,
      )) {
        final colName = field.dbColumnName;
        if (entry.data.containsKey(colName)) {
          final val = entry.data[colName];
          if (val is bool) {
            queryParams.add(val ? 1 : 0);
          } else if (val is Enum) {
            queryParams.add(val.name);
          } else {
            queryParams.add(val);
          }
        } else {
          queryParams.add(null);
        }
      }

      stmt.execute(queryParams);
    }
    stmt.close();
    db.execute('COMMIT');
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
