import 'openaip_unit.dart';
import 'frequency_type.dart';

class AirportFrequency {
  final String id;
  final String value;
  final OpenAipUnit unit;
  final FrequencyType type;
  final String name;
  final bool primary;
  final bool publicUse;

  AirportFrequency({
    required this.id,
    required this.value,
    required this.unit,
    required this.type,
    required this.name,
    required this.primary,
    required this.publicUse,
  });

  factory AirportFrequency.fromJson(Map<String, Object?> json) {
    return AirportFrequency(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      unit: OpenAipUnit.fromInt((json['unit'] as num? ?? 0).toInt()),
      type: FrequencyType.fromInt((json['type'] as num? ?? 0).toInt()),
      name: (json['name'] ?? '').toString(),
      primary: json['primary'] as bool? ?? false,
      publicUse: json['publicUse'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      '_id': id,
      'value': value,
      'unit': unit.toInt(),
      'type': type.toInt(),
      'name': name,
      'primary': primary,
      'publicUse': publicUse,
    };
  }
}
