import 'telemetry_state.dart';

class TelemetryEntry {
  final int? id;
  final String flightUuid;
  final DateTime timestamp;
  final bool isSnapshot;
  final Map<String, dynamic> data;

  const TelemetryEntry({
    this.id,
    required this.flightUuid,
    required this.timestamp,
    required this.isSnapshot,
    required this.data,
  });

  TelemetryEntry copyWith({
    int? id,
    String? flightUuid,
    DateTime? timestamp,
    bool? isSnapshot,
    Map<String, dynamic>? data,
  }) {
    return TelemetryEntry(
      id: id ?? this.id,
      flightUuid: flightUuid ?? this.flightUuid,
      timestamp: timestamp ?? this.timestamp,
      isSnapshot: isSnapshot ?? this.isSnapshot,
      data: data ?? this.data,
    );
  }

  dynamic getFieldValue(TelemetryField field) => data[field.dbColumnName];

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'flight_uuid': flightUuid,
      'timestamp': timestamp.toIso8601String(),
      'is_snapshot': isSnapshot ? 1 : 0,
    };
    for (final key in data.keys) {
      map[key] = data[key];
    }
    return map;
  }

  factory TelemetryEntry.fromMap(Map<String, dynamic> map) {
    final {
      'id': int? id,
      'flight_uuid': String flightUuid,
      'timestamp': String timestamp,
      'is_snapshot': int? isSnapshotInt,
    } = map;

    final telemetryData = <String, dynamic>{};
    for (final field in TelemetryField.values) {
      final colName = field.dbColumnName;
      if (map[colName] != null) {
        telemetryData[colName] = map[colName];
      }
    }

    return TelemetryEntry(
      id: id,
      flightUuid: flightUuid,
      timestamp: DateTime.parse(timestamp).toUtc(),
      isSnapshot: (isSnapshotInt ?? 0) == 1,
      data: telemetryData,
    );
  }

  @override
  String toString() {
    return 'TelemetryEntry(id: $id, flightUuid: $flightUuid, timestamp: $timestamp, isSnapshot: $isSnapshot, data: $data)';
  }
}
