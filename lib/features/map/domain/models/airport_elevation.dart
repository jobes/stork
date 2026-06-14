import 'openaip_unit.dart';

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
