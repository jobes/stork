import 'package:clock/clock.dart';

import 'airspace_limit.dart';

/// Real-time activity status of an airspace, derived from an AUP/UUP
/// (Airspace Use Plan / Updated Use Plan) source.
enum AirspaceActivityStatus {
  /// The airspace is currently active (published in the AUP as activated).
  active,

  /// The airspace is currently inactive (published as not active, or
  /// deactivated by a subsequent UUP).
  inactive,

  /// No AUP/UUP information is available for the airspace.
  unknown;

  /// Parses a raw status token coming from an AUP/UUP payload (e.g. `"ACTIVE"`,
  /// `"ACTIVATED"`, `"INACTIVE"`, `"DEACTIVATED"`). Returns [unknown] when the
  /// token cannot be recognised.
  static AirspaceActivityStatus fromPayload(Object? raw) {
    final token = raw?.toString().trim().toUpperCase() ?? '';
    if (token.isEmpty) {
      return AirspaceActivityStatus.unknown;
    }
    if (token == 'ACTIVE' ||
        token == 'ACTIVATED' ||
        token == 'ACTIVATION' ||
        token == 'ON') {
      return AirspaceActivityStatus.active;
    }
    if (token == 'INACTIVE' ||
        token == 'DEACTIVATED' ||
        token == 'DEACTIVATION' ||
        token == 'NOT ACTIVE' ||
        token == 'OFF') {
      return AirspaceActivityStatus.inactive;
    }
    return AirspaceActivityStatus.unknown;
  }
}

/// A single airspace activity entry parsed from an AUP/UUP source.
///
/// [airspaceId] holds the bound openAIP airspace identifier (`_id` / `id`) when
/// a match could be established during repository binding; otherwise it falls
/// back to the AUP designator so the activity can still be looked up.
class AupAirspaceActivity {
  final String airspaceId;
  final String designator;
  final String name;
  final AirspaceActivityStatus status;
  final DateTime? validFrom;
  final DateTime? validTo;
  final AirspaceLimit? lowerLimit;
  final AirspaceLimit? upperLimit;
  final String source;
  final DateTime updatedAt;

  const AupAirspaceActivity({
    required this.airspaceId,
    required this.designator,
    required this.name,
    required this.status,
    this.validFrom,
    this.validTo,
    this.lowerLimit,
    this.upperLimit,
    required this.source,
    required this.updatedAt,
  });

  bool get isCurrentlyActive =>
      statusAt(clock.now()) == AirspaceActivityStatus.active;

  /// Returns the effective status at [now].
  ///
  /// Some AUP sources (e.g. the Slovak LzPS) only provide the current state
  /// without a validity window — in that case the parsed [status] is returned
  /// unchanged. When a validity window is present, an `active` airspace that
  /// is not yet or no longer within its window is reported as
  /// [AirspaceActivityStatus.inactive].
  AirspaceActivityStatus statusAt(DateTime now) {
    if (status != AirspaceActivityStatus.active) return status;
    final from = validFrom;
    final to = validTo;
    if (from == null && to == null) return status;
    if (from != null && now.isBefore(from)) {
      return AirspaceActivityStatus.inactive;
    }
    if (to != null && !now.isBefore(to)) {
      return AirspaceActivityStatus.inactive;
    }
    return AirspaceActivityStatus.active;
  }

  AupAirspaceActivity copyWith({
    String? airspaceId,
    String? designator,
    String? name,
    AirspaceActivityStatus? status,
    DateTime? validFrom,
    DateTime? validTo,
    AirspaceLimit? lowerLimit,
    AirspaceLimit? upperLimit,
    String? source,
    DateTime? updatedAt,
  }) {
    return AupAirspaceActivity(
      airspaceId: airspaceId ?? this.airspaceId,
      designator: designator ?? this.designator,
      name: name ?? this.name,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      lowerLimit: lowerLimit ?? this.lowerLimit,
      upperLimit: upperLimit ?? this.upperLimit,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AupAirspaceActivity.fromJson(Map<String, Object?> json) {
    return AupAirspaceActivity(
      airspaceId: (json['airspaceId'] ?? json['designator'] ?? '').toString(),
      designator: (json['designator'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      status:
          AirspaceActivityStatus.values.asNameMap()[json['status']] ??
          AirspaceActivityStatus.unknown,
      validFrom: _parseDateTime(json['validFrom']),
      validTo: _parseDateTime(json['validTo']),
      lowerLimit: _parseLimit(json['lowerLimit']),
      upperLimit: _parseLimit(json['upperLimit']),
      source: (json['source'] ?? '').toString(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? clock.now(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'airspaceId': airspaceId,
      'designator': designator,
      'name': name,
      'status': status.name,
      if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
      if (validTo != null) 'validTo': validTo!.toIso8601String(),
      if (lowerLimit != null) 'lowerLimit': lowerLimit!.toJson(),
      if (upperLimit != null) 'upperLimit': upperLimit!.toJson(),
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

AirspaceLimit? _parseLimit(Object? value) {
  if (value is! Map) return null;
  return AirspaceLimit.fromJson(Map<String, Object?>.from(value));
}
