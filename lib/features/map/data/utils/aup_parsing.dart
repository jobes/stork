import '../../domain/models/airspace_activity_status.dart';
import '../../domain/models/airspace_limit.dart';
import '../../domain/models/openaip_unit.dart';
import '../../domain/models/reference_datum.dart';

/// Parses a textual AUP/UUP vertical limit into an [AirspaceLimit].
///
/// Supported formats:
/// - `GND`, `SFC`  -> ground level (0 m, GND)
/// - `FL95`, `FL 95` -> flight level 95 (STD)
/// - `9500FT AMSL`, `9500FT` -> feet above mean sea level
/// - `2500M`, `2500 M AMSL` -> meters above mean sea level
/// - `UNL` -> unlimited (returns `null`)
///
/// Returns `null` when the token cannot be parsed (e.g. `NOTAM`).
AirspaceLimit? parseAupLimit(String? raw) {
  if (raw == null) return null;
  final token = raw.trim().toUpperCase();
  if (token.isEmpty) return null;

  if (token == 'GND' || token == 'SFC' || token == '0') {
    return AirspaceLimit(
      value: 0,
      unit: OpenAipUnit.meters,
      referenceDatum: ReferenceDatum.gnd,
    );
  }
  if (token == 'UNL' || token == 'UNLIMITED' || token == 'NOTAM') {
    return null;
  }

  final flMatch = RegExp(r'^FL\s*(\d+)$').firstMatch(token);
  if (flMatch != null) {
    return AirspaceLimit(
      value: double.parse(flMatch.group(1)!),
      unit: OpenAipUnit.flightLevel,
      referenceDatum: ReferenceDatum.std,
    );
  }

  // Czech ŘLP AUP writes flight levels as `F` + three digits (e.g. `F095` =
  // FL95, `F420` = FL420).
  final fLevelMatch = RegExp(r'^F(\d{3})$').firstMatch(token);
  if (fLevelMatch != null) {
    return AirspaceLimit(
      value: double.parse(fLevelMatch.group(1)!),
      unit: OpenAipUnit.flightLevel,
      referenceDatum: ReferenceDatum.std,
    );
  }

  final ftMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*FT').firstMatch(token);
  if (ftMatch != null) {
    return AirspaceLimit(
      value: double.parse(ftMatch.group(1)!),
      unit: OpenAipUnit.feet,
      referenceDatum: token.contains('GND') || token.contains('AGL')
          ? ReferenceDatum.gnd
          : ReferenceDatum.msl,
    );
  }

  final mMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*M\b').firstMatch(token);
  if (mMatch != null) {
    return AirspaceLimit(
      value: double.parse(mMatch.group(1)!),
      unit: OpenAipUnit.meters,
      referenceDatum: token.contains('GND') || token.contains('AGL')
          ? ReferenceDatum.gnd
          : ReferenceDatum.msl,
    );
  }

  final numeric = double.tryParse(token);
  if (numeric != null) {
    return AirspaceLimit(
      value: numeric,
      unit: OpenAipUnit.meters,
      referenceDatum: ReferenceDatum.msl,
    );
  }

  return null;
}

/// Parses an ISO-8601 date/time token from an AUP/UUP payload. Accepts both
/// string and [DateTime] values; returns `null` on failure.
DateTime? parseAupDateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString());
}

/// Extracts a designator from a payload entry, checking the most common key
/// names (`designator`, `id`, `code`, `name`).
String extractAupDesignator(Map<String, Object?> entry) {
  for (final key in const ['designator', 'id', 'code', 'name']) {
    final value = entry[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

/// Extracts an AUP status from a payload entry. Prefers a textual `status`
/// token and falls back to boolean `activated` / `active` flags.
AirspaceActivityStatus extractAupStatus(Map<String, Object?> entry) {
  final statusRaw = entry['status'] ?? entry['activity'] ?? entry['state'];
  final parsed = AirspaceActivityStatus.fromPayload(statusRaw);
  if (parsed != AirspaceActivityStatus.unknown) {
    return parsed;
  }

  final activated = entry['activated'] ?? entry['active'] ?? entry['isActive'];
  if (activated is bool) {
    return activated
        ? AirspaceActivityStatus.active
        : AirspaceActivityStatus.inactive;
  }
  return AirspaceActivityStatus.unknown;
}
