import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../features/telemetry/domain/models/flight.dart';
import '../../../features/telemetry/domain/models/telemetry_entry.dart';
import '../../../features/telemetry/domain/models/telemetry_state.dart';

class BlackBoxDatabase {
  static Database? _db;

  @visibleForTesting
  static set database(Database? db) => _db = db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<String> get _dbPath async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'black_box.db');
  }

  static Future<Database> _initDatabase() async {
    final path = await _dbPath;
    final db = sqlite3.open(path);
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA synchronous = NORMAL;');
    setupTables(db);
    return db;
  }

  static Future<void> resetDatabase() async {
    if (_db != null) {
      _db!.close();
      _db = null;
    }
    final path = await _dbPath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await database;
  }

  static void setupTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS flights (
          uuid TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          pilot_id TEXT,
          airplane_id TEXT
      );
    ''');

    final telemetryColumns = [
      'id INTEGER PRIMARY KEY AUTOINCREMENT',
      'flight_uuid TEXT NOT NULL',
      'timestamp TEXT NOT NULL',
      'is_snapshot INTEGER NOT NULL DEFAULT 0'
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

    db.execute('CREATE INDEX IF NOT EXISTS idx_telemetry_flight ON flight_telemetry (flight_uuid);');
    db.execute('CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp ON flight_telemetry (timestamp);');

    _migrateSchema(db);
  }

  static void _migrateSchema(Database db) {
    final pragmaResults = db.select('PRAGMA table_info(flight_telemetry)');
    final existingColumns = pragmaResults.map((row) => row['name'] as String).toSet();

    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      final colName = field.dbColumnName;
      if (!existingColumns.contains(colName)) {
        db.execute('ALTER TABLE flight_telemetry ADD COLUMN $colName ${field.dbType}');
      }
    }
  }

  static Future<void> saveFlight(Flight flight) async {
    final db = await database;
    final stmt = db.prepare('''
      INSERT OR REPLACE INTO flights (uuid, name, start_time, end_time, pilot_id, airplane_id)
      VALUES (?, ?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      flight.uuid,
      flight.name,
      flight.startTime.toIso8601String(),
      flight.endTime?.toIso8601String(),
      flight.pilotId,
      flight.airplaneId,
    ]);
    stmt.close();
  }

  static Future<void> updateFlightEndTime(String uuid, DateTime endTime) async {
    final db = await database;
    final stmt = db.prepare('''
      UPDATE flights SET end_time = ? WHERE uuid = ?
    ''');
    stmt.execute([endTime.toIso8601String(), uuid]);
    stmt.close();
  }

  static Future<void> insertTelemetryEntries(List<TelemetryEntry> entries) async {
    if (entries.isEmpty) return;
    final db = await database;
    db.execute('BEGIN TRANSACTION');
    try {
      final columns = ['flight_uuid', 'timestamp', 'is_snapshot'];
      final placeholders = ['?', '?', '?'];

      for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
        columns.add(field.dbColumnName);
        placeholders.add('?');
      }

      final query = 'INSERT INTO flight_telemetry (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
      final stmt = db.prepare(query);

      for (final entry in entries) {
        final params = <Object?>[
          entry.flightUuid,
          entry.timestamp.toIso8601String(),
          entry.isSnapshot ? 1 : 0,
        ];

        for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
          final colName = field.dbColumnName;
          if (entry.data.containsKey(colName)) {
            final val = entry.data[colName];
            if (val is bool) {
              params.add(val ? 1 : 0);
            } else if (val is Enum) {
              params.add(val.name);
            } else {
              params.add(val);
            }
          } else {
            params.add(null);
          }
        }

        stmt.execute(params);
      }
      stmt.close();
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Future<List<Flight>> getFlights() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = db.select('SELECT uuid, name, start_time, end_time, pilot_id, airplane_id FROM flights ORDER BY start_time DESC');
    return results.map((row) {
      return Flight(
        uuid: row['uuid'] as String,
        name: row['name'] as String,
        startTime: DateTime.parse(row['start_time'] as String).toUtc(),
        endTime: row['end_time'] != null ? DateTime.parse(row['end_time'] as String).toUtc() : null,
        pilotId: row['pilot_id'] as String?,
        airplaneId: row['airplane_id'] as String?,
      );
    }).toList();
  }

  static Future<List<TelemetryEntry>> getTelemetryForFlight(String flightUuid) async {
    if (kIsWeb) return [];
    final db = await database;

    final columns = ['id', 'flight_uuid', 'timestamp', 'is_snapshot'];
    for (final field in TelemetryField.values.where((f) => f.isBlackBoxField)) {
      columns.add(field.dbColumnName);
    }

    final query = '''
      SELECT ${columns.join(', ')} 
      FROM flight_telemetry 
      WHERE flight_uuid = ? 
      ORDER BY timestamp ASC
    ''';

    final results = db.select(query, [flightUuid]);
    return results.map((row) {
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
    }).toList();
  }

  static Future<void> deleteFlight(String uuid) async {
    final db = await database;
    final stmt = db.prepare('DELETE FROM flights WHERE uuid = ?');
    stmt.execute([uuid]);
    stmt.close();
  }

  static Future<void> clearAll() async {
    final db = await database;
    db.execute('DELETE FROM flights');
  }
}
