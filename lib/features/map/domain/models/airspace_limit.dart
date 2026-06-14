import 'openaip_unit.dart';
import 'reference_datum.dart';

class AirspaceLimit {
  final double value;
  final OpenAipUnit unit;
  final ReferenceDatum referenceDatum;

  AirspaceLimit({
    required this.value,
    required this.unit,
    required this.referenceDatum,
  });

  factory AirspaceLimit.fromJson(Map<String, Object?> json) {
    return AirspaceLimit(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: OpenAipUnit.fromInt((json['unit'] as num? ?? 0).toInt()),
      referenceDatum: ReferenceDatum.fromInt(
        (json['referenceDatum'] as num? ?? 0).toInt(),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'value': value,
      'unit': unit.toInt(),
      'referenceDatum': referenceDatum.index,
    };
  }
}
