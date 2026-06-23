import 'navigation_point.dart';

class NavigationState {
  final List<NavigationPoint> points;
  final bool isActive;
  final bool wasAutoAdvanced;

  const NavigationState({
    this.points = const [],
    this.isActive = false,
    this.wasAutoAdvanced = false,
  });

  NavigationState copyWith({
    List<NavigationPoint>? points,
    bool? isActive,
    bool? wasAutoAdvanced,
  }) {
    return NavigationState(
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      wasAutoAdvanced: wasAutoAdvanced ?? this.wasAutoAdvanced,
    );
  }

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'isActive': isActive,
        'wasAutoAdvanced': wasAutoAdvanced,
      };

  factory NavigationState.fromJson(Map<String, dynamic> json) {
    final points = <NavigationPoint>[];
    if (json['points'] case List<dynamic> list) {
      for (final item in list) {
        if (item case Map<String, dynamic> map) {
          points.add(NavigationPoint.fromJson(map));
        } else {
          throw FormatException('Invalid waypoint in points list: $item');
        }
      }
    } else if (json['points'] != null) {
      throw FormatException('Invalid points format');
    }

    final isActive = json['isActive'];
    final wasAutoAdvanced = json['wasAutoAdvanced'];
    return NavigationState(
      points: points,
      isActive: isActive is bool ? isActive : false,
      wasAutoAdvanced: wasAutoAdvanced is bool ? wasAutoAdvanced : false,
    );
  }
}
