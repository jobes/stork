import '../../../core/constants/api_constants.dart';

enum AirportType {
  airport, // 0
  gliderSite, // 1
  airfieldCivil, // 2
  internationalAirport, // 3
  heliportMilitary, // 4
  militaryAerodrome, // 5
  ultralightFlyingSite, // 6
  heliportCivil, // 7
  aerodromeClosed, // 8
  ifr, // 9
  airfieldWater, // 10
  landingStrip, // 11
  agriculturalLandingStrip, // 12
  altiport, // 13
  unknown;

  static AirportType fromInt(int val) {
    if (val >= 0 && val < AirportType.values.length - 1) {
      return AirportType.values[val];
    }
    return AirportType.unknown;
  }

  int toInt() {
    return index;
  }
}

enum FrequencyType {
  approach, // 0
  apron, // 1
  arrival, // 2
  center, // 3
  ctaf, // 4
  delivery, // 5
  departure, // 6
  fis, // 7
  gliding, // 8
  ground, // 9
  info, // 10
  multicom, // 11
  unicom, // 12
  radar, // 13
  tower, // 14
  atis, // 15
  radio, // 16
  other, // 17
  airmet, // 18
  awos, // 19
  lights, // 20
  volmet, // 21
  unknown;

  static FrequencyType fromInt(int val) {
    if (val >= 0 && val < FrequencyType.values.length - 1) {
      return FrequencyType.values[val];
    }
    return FrequencyType.unknown;
  }

  int toInt() {
    return index;
  }
}

enum RunwayComposition {
  asphalt, // 0
  concrete, // 1
  grass, // 2
  sand, // 3
  water, // 4
  bituminousTar, // 5
  brick, // 6
  macadam, // 7
  stone, // 8
  coral, // 9
  clay, // 10
  laterite, // 11
  gravel, // 12
  earth, // 13
  ice, // 14
  snow, // 15
  protectiveLaminate, // 16
  metal, // 17
  landingMat, // 18
  unknown, // 19
  wood; // 20

  static RunwayComposition fromInt(int val) {
    if (val >= 0 && val < RunwayComposition.values.length) {
      return RunwayComposition.values[val];
    }
    return RunwayComposition.unknown;
  }

  int toInt() {
    return index;
  }
}

enum OpenAipUnit {
  meters, // 0
  feet, // 1
  mhz, // 2
  flightLevel, // 6
  khz, // 7
  unknown;

  static OpenAipUnit fromInt(int val) => switch (val) {
        0 => OpenAipUnit.meters,
        1 => OpenAipUnit.feet,
        2 => OpenAipUnit.mhz,
        6 => OpenAipUnit.flightLevel,
        7 => OpenAipUnit.khz,
        _ => OpenAipUnit.unknown,
      };

  int toInt() => switch (this) {
        OpenAipUnit.meters => 0,
        OpenAipUnit.feet => 1,
        OpenAipUnit.mhz => 2,
        OpenAipUnit.flightLevel => 6,
        OpenAipUnit.khz => 7,
        _ => -1,
      };

  String get symbol => switch (this) {
        OpenAipUnit.meters => 'm',
        OpenAipUnit.feet => 'ft',
        OpenAipUnit.mhz => 'MHz',
        OpenAipUnit.flightLevel => 'FL',
        OpenAipUnit.khz => 'kHz',
        _ => '',
      };
}

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

class AirportImage {
  final String id;
  final String filename;

  AirportImage({required this.id, required this.filename});

  factory AirportImage.fromJson(Map<String, Object?> json) {
    return AirportImage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      filename: (json['filename'] ?? '').toString(),
    );
  }

  Map<String, Object?> toJson() {
    return {'_id': id, 'filename': filename};
  }

  String getThumbnailUrl(String apiKey) {
    return '${ApiConstants.openAipImageBaseUrl}/$filename?width=200&height=200&apiKey=$apiKey';
  }

  String getFullSizeUrl(String apiKey) {
    return '${ApiConstants.openAipImageBaseUrl}/$filename?apiKey=$apiKey';
  }
}

class AirportMetadata {
  final String id;
  final String name;
  final String? icaoCode;
  final AirportType type;
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
  final List<AirportImage> images;

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
    required this.images,
  });

  factory AirportMetadata.fromJson(Map<String, Object?> json) {
    final trafficList = json['trafficType'];
    final elevJson = json['elevation'];
    final freqList = json['frequencies'];
    final rwyList = json['runways'];
    final imgList = json['images'];

    return AirportMetadata(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icaoCode: json['icaoCode'] as String?,
      type: AirportType.fromInt((json['type'] as num? ?? 0).toInt()),
      trafficType: trafficList is List
          ? trafficList.whereType<num>().map((e) => e.toInt()).toList()
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
                .whereType<Map>()
                .map(
                  (e) =>
                      AirportFrequency.fromJson(Map<String, Object?>.from(e)),
                )
                .toList()
          : const [],
      runways: rwyList is List
          ? rwyList
                .whereType<Map>()
                .map(
                  (e) => AirportRunway.fromJson(Map<String, Object?>.from(e)),
                )
                .toList()
          : const [],
      images: imgList is List
          ? imgList
                .whereType<Map>()
                .map((e) => AirportImage.fromJson(Map<String, Object?>.from(e)))
                .toList()
          : const [],
    );
  }

  Map<String, Object?> toJson() {
    return {
      '_id': id,
      'name': name,
      if (icaoCode != null) 'icaoCode': icaoCode,
      'type': type.toInt(),
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
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}

class GeoJsonFeature {
  final String type;
  final AirportMetadata properties;

  GeoJsonFeature({required this.type, required this.properties});

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
