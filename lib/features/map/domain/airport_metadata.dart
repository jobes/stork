class AirportElevation {
  final double value;
  final int unit;
  final int referenceDatum;

  AirportElevation({
    required this.value,
    required this.unit,
    required this.referenceDatum,
  });

  factory AirportElevation.fromJson(Map<String, Object?> json) {
    return AirportElevation(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: (json['unit'] as num? ?? 0).toInt(),
      referenceDatum: (json['referenceDatum'] as num? ?? 0).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'value': value,
      'unit': unit,
      'referenceDatum': referenceDatum,
    };
  }
}

class AirportFrequency {
  final String id;
  final String value;
  final int unit;
  final int type;
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
      unit: (json['unit'] as num? ?? 0).toInt(),
      type: (json['type'] as num? ?? 0).toInt(),
      name: (json['name'] ?? '').toString(),
      primary: json['primary'] as bool? ?? false,
      publicUse: json['publicUse'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      '_id': id,
      'value': value,
      'unit': unit,
      'type': type,
      'name': name,
      'primary': primary,
      'publicUse': publicUse,
    };
  }
}

class RunwayDimensionValue {
  final double value;
  final int unit;

  RunwayDimensionValue({
    required this.value,
    required this.unit,
  });

  factory RunwayDimensionValue.fromJson(Map<String, Object?> json) {
    return RunwayDimensionValue(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: (json['unit'] as num? ?? 0).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'value': value,
      'unit': unit,
    };
  }
}

class RunwayDimension {
  final RunwayDimensionValue length;
  final RunwayDimensionValue width;

  RunwayDimension({
    required this.length,
    required this.width,
  });

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
    return {
      'length': length.toJson(),
      'width': width.toJson(),
    };
  }
}

class RunwaySurface {
  final List<int> composition;
  final int mainComposite;
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
          ? compList.map((e) => (e as num).toInt()).toList()
          : const [],
      mainComposite: (json['mainComposite'] as num? ?? 0).toInt(),
      condition: (json['condition'] as num? ?? 0).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'composition': composition,
      'mainComposite': mainComposite,
      'condition': condition,
    };
  }
}

class RunwayDeclaredDistanceValue {
  final double value;
  final int unit;

  RunwayDeclaredDistanceValue({
    required this.value,
    required this.unit,
  });

  factory RunwayDeclaredDistanceValue.fromJson(Map<String, Object?> json) {
    return RunwayDeclaredDistanceValue(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: (json['unit'] as num? ?? 0).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'value': value,
      'unit': unit,
    };
  }
}

class RunwayDeclaredDistance {
  final RunwayDeclaredDistanceValue? tora;
  final RunwayDeclaredDistanceValue? lda;

  RunwayDeclaredDistance({
    this.tora,
    this.lda,
  });

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
      if (declaredDistance != null) 'declaredDistance': declaredDistance!.toJson(),
      'pilotCtrlLighting': pilotCtrlLighting,
    };
  }
}

class AirportMetadata {
  final String id;
  final String name;
  final String? icaoCode;
  final int type;
  final List<int> trafficType;
  final double? magneticDeclination;
  final String country;
  final AirportElevation? elevation;
  final bool? ppr;
  final bool? private;
  final bool? skydiveActivity;
  final bool? winchOnly;
  final List<AirportFrequency> frequencies;
  final List<AirportRunway> runways;

  AirportMetadata({
    required this.id,
    required this.name,
    this.icaoCode,
    required this.type,
    required this.trafficType,
    this.magneticDeclination,
    required this.country,
    this.elevation,
    this.ppr,
    this.private,
    this.skydiveActivity,
    this.winchOnly,
    required this.frequencies,
    required this.runways,
  });

  factory AirportMetadata.fromJson(Map<String, Object?> json) {
    final trafficList = json['trafficType'];
    final elevJson = json['elevation'];
    final freqList = json['frequencies'];
    final rwyList = json['runways'];

    return AirportMetadata(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icaoCode: json['icaoCode'] as String?,
      type: (json['type'] as num? ?? 0).toInt(),
      trafficType: trafficList is List
          ? trafficList.map((e) => (e as num).toInt()).toList()
          : const [],
      magneticDeclination: (json['magneticDeclination'] as num?)?.toDouble(),
      country: (json['country'] ?? '').toString(),
      elevation: elevJson is Map<String, Object?>
          ? AirportElevation.fromJson(elevJson)
          : null,
      ppr: json['ppr'] as bool?,
      private: json['private'] as bool?,
      skydiveActivity: json['skydiveActivity'] as bool?,
      winchOnly: json['winchOnly'] as bool?,
      frequencies: freqList is List
          ? freqList
              .map((e) => AirportFrequency.fromJson(e as Map<String, Object?>))
              .toList()
          : const [],
      runways: rwyList is List
          ? rwyList
              .map((e) => AirportRunway.fromJson(e as Map<String, Object?>))
              .toList()
          : const [],
    );
  }

  Map<String, Object?> toJson() {
    return {
      '_id': id,
      'name': name,
      if (icaoCode != null) 'icaoCode': icaoCode,
      'type': type,
      'trafficType': trafficType,
      if (magneticDeclination != null)
        'magneticDeclination': magneticDeclination,
      'country': country,
      if (elevation != null) 'elevation': elevation!.toJson(),
      if (ppr != null) 'ppr': ppr,
      if (private != null) 'private': private,
      if (skydiveActivity != null) 'skydiveActivity': skydiveActivity,
      if (winchOnly != null) 'winchOnly': winchOnly,
      'frequencies': frequencies.map((e) => e.toJson()).toList(),
      'runways': runways.map((e) => e.toJson()).toList(),
    };
  }
}

class GeoJsonFeature {
  final String type;
  final AirportMetadata properties;

  GeoJsonFeature({
    required this.type,
    required this.properties,
  });

  factory GeoJsonFeature.fromJson(Map<String, Object?> json) {
    final props = json['properties'];
    return GeoJsonFeature(
      type: (json['type'] ?? 'Feature').toString(),
      properties: AirportMetadata.fromJson(
        props is Map<String, Object?> ? props : const <String, Object?>{},
      ),
    );
  }
}
