import 'runway_surface.dart';
import 'runway_dimension.dart';
import 'runway_declared_distance.dart';

class AirportRunway {
  final String id;
  final String designator;
  final double trueHeading;
  final bool alignedTrueNorth;
  final int operations;
  final bool mainRunway;
  final int turnDirection;
  final bool takeOffOnly;
  final bool landingOnly;
  final RunwaySurface? surface;
  final RunwayDimension? dimension;
  final RunwayDeclaredDistance? declaredDistance;
  final bool pilotCtrlLighting;

  AirportRunway({
    required this.id,
    required this.designator,
    required this.trueHeading,
    required this.alignedTrueNorth,
    required this.operations,
    required this.mainRunway,
    required this.turnDirection,
    required this.takeOffOnly,
    required this.landingOnly,
    this.surface,
    this.dimension,
    this.declaredDistance,
    required this.pilotCtrlLighting,
  });

  factory AirportRunway.fromJson(Map<String, Object?> json) {
    final surfaceJson = json['surface'];
    final dimJson = json['dimension'];
    final distJson = json['declaredDistance'];
    return AirportRunway(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      designator: (json['designator'] ?? '').toString(),
      trueHeading: (json['trueHeading'] as num? ?? 0.0).toDouble(),
      alignedTrueNorth: json['alignedTrueNorth'] as bool? ?? false,
      operations: (json['operations'] as num? ?? 0).toInt(),
      mainRunway: json['mainRunway'] as bool? ?? false,
      turnDirection: (json['turnDirection'] as num? ?? 0).toInt(),
      takeOffOnly: json['takeOffOnly'] as bool? ?? false,
      landingOnly: json['landingOnly'] as bool? ?? false,
      surface: surfaceJson is Map<String, Object?>
          ? RunwaySurface.fromJson(surfaceJson)
          : null,
      dimension: dimJson is Map<String, Object?>
          ? RunwayDimension.fromJson(dimJson)
          : null,
      declaredDistance: distJson is Map<String, Object?>
          ? RunwayDeclaredDistance.fromJson(distJson)
          : null,
      pilotCtrlLighting: json['pilotCtrlLighting'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      '_id': id,
      'designator': designator,
      'trueHeading': trueHeading,
      'alignedTrueNorth': alignedTrueNorth,
      'operations': operations,
      'mainRunway': mainRunway,
      'turnDirection': turnDirection,
      'takeOffOnly': takeOffOnly,
      'landingOnly': landingOnly,
      if (surface != null) 'surface': surface!.toJson(),
      if (dimension != null) 'dimension': dimension!.toJson(),
      if (declaredDistance != null)
        'declaredDistance': declaredDistance!.toJson(),
      'pilotCtrlLighting': pilotCtrlLighting,
    };
  }
}
