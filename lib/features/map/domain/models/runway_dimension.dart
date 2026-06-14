import 'openaip_unit.dart';

class RunwayDimensionValue {
  final double value;
  final OpenAipUnit unit;

  RunwayDimensionValue({required this.value, required this.unit});

  factory RunwayDimensionValue.fromJson(Map<String, Object?> json) {
    return RunwayDimensionValue(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: OpenAipUnit.fromInt((json['unit'] as num? ?? 0).toInt()),
    );
  }

  Map<String, Object?> toJson() {
    return {'value': value, 'unit': unit.toInt()};
  }
}

class RunwayDimension {
  final RunwayDimensionValue length;
  final RunwayDimensionValue width;

  RunwayDimension({required this.length, required this.width});

  factory RunwayDimension.fromJson(Map<String, Object?> json) {
    final lenJson = json['length'];
    final widthJson = json['width'];
    return RunwayDimension(
      length: RunwayDimensionValue.fromJson(
        lenJson is Map<String, Object?> ? lenJson : const {},
      ),
      width: RunwayDimensionValue.fromJson(
        widthJson is Map<String, Object?> ? widthJson : const {},
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {'length': length.toJson(), 'width': width.toJson()};
  }
}
