import 'airport_type.dart';
import 'airport_elevation.dart';
import 'airport_frequency.dart';
import 'airport_runway.dart';
import 'airport_image.dart';

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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
