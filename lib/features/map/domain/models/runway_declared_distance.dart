import 'openaip_unit.dart';

class RunwayDeclaredDistanceValue {
  final double value;
  final OpenAipUnit unit;

  RunwayDeclaredDistanceValue({required this.value, required this.unit});

  factory RunwayDeclaredDistanceValue.fromJson(Map<String, Object?> json) {
    return RunwayDeclaredDistanceValue(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: OpenAipUnit.fromInt((json['unit'] as num? ?? 0).toInt()),
    );
  }

  Map<String, Object?> toJson() {
    return {'value': value, 'unit': unit.toInt()};
  }
}

class RunwayDeclaredDistance {
  final RunwayDeclaredDistanceValue? tora;
  final RunwayDeclaredDistanceValue? lda;

  RunwayDeclaredDistance({this.tora, this.lda});

  factory RunwayDeclaredDistance.fromJson(Map<String, Object?> json) {
    final toraJson = json['tora'];
    final ldaJson = json['lda'];
    return RunwayDeclaredDistance(
      tora: toraJson is Map<String, Object?>
          ? RunwayDeclaredDistanceValue.fromJson(toraJson)
          : null,
      lda: ldaJson is Map<String, Object?>
          ? RunwayDeclaredDistanceValue.fromJson(ldaJson)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (tora != null) 'tora': tora!.toJson(),
      if (lda != null) 'lda': lda!.toJson(),
    };
  }
}
