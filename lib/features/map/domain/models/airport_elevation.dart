import 'openaip_unit.dart';
import 'reference_datum.dart';

class AirportElevation {
  final double value;
  final OpenAipUnit unit;
  final int referenceDatum;

  AirportElevation({
    required this.value,
    required this.unit,
    required this.referenceDatum,
  });

  factory AirportElevation.fromJson(Map<String, Object?> json) {
    return AirportElevation(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: OpenAipUnit.fromInt((json['unit'] as num? ?? 0).toInt()),
      referenceDatum: (json['referenceDatum'] as num? ?? 0).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'value': value,
      'unit': unit.toInt(),
      'referenceDatum': referenceDatum,
    };
  }
}

extension AirportElevationConversion on AirportElevation {
  /// Elevation in meters, available only when it is referenced to mean sea
  /// level. Heights referenced to the ground or to standard pressure are not
  /// usable as an airport reference.
  double? get metersMsl {
    if (ReferenceDatum.fromInt(referenceDatum) != ReferenceDatum.msl) {
      return null;
    }
    return switch (unit) {
      OpenAipUnit.meters => value,
      OpenAipUnit.feet => value * 0.3048,
      _ => null,
    };
  }
}
