import 'runway_composition.dart';

class RunwaySurface {
  final List<RunwayComposition> composition;
  final RunwayComposition mainComposite;
  final int condition;

  RunwaySurface({
    required this.composition,
    required this.mainComposite,
    required this.condition,
  });

  factory RunwaySurface.fromJson(Map<String, Object?> json) {
    final compList = json['composition'];
    return RunwaySurface(
      composition: compList is List
          ? compList
                .whereType<num>()
                .map((e) => RunwayComposition.fromInt(e.toInt()))
                .toList()
          : const [],
      mainComposite: RunwayComposition.fromInt(
        (json['mainComposite'] as num? ?? 0).toInt(),
      ),
      condition: (json['condition'] as num? ?? 0).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'composition': composition.map((e) => e.toInt()).toList(),
      'mainComposite': mainComposite.toInt(),
      'condition': condition,
    };
  }
}
