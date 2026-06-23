class Flight {
  final String uuid;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final String? pilotId;
  final String? airplaneId;

  const Flight({
    required this.uuid,
    required this.name,
    required this.startTime,
    this.endTime,
    this.pilotId,
    this.airplaneId,
  });

  Flight copyWith({
    String? uuid,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    String? pilotId,
    String? airplaneId,
  }) {
    return Flight(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pilotId: pilotId ?? this.pilotId,
      airplaneId: airplaneId ?? this.airplaneId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'pilot_id': pilotId,
      'airplane_id': airplaneId,
    };
  }

  factory Flight.fromMap(Map<String, dynamic> map) {
    return Flight(
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      startTime: DateTime.parse(map['start_time'] as String).toUtc(),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String).toUtc() : null,
      pilotId: map['pilot_id'] as String?,
      airplaneId: map['airplane_id'] as String?,
    );
  }

  @override
  String toString() {
    return 'Flight(uuid: $uuid, name: $name, startTime: $startTime, endTime: $endTime, pilotId: $pilotId, airplaneId: $airplaneId)';
  }
}
