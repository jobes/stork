import 'airspace_class.dart';
import 'airspace_type.dart';
import 'airspace_limit.dart';
import 'airspace_activity.dart';
import 'airspace_frequency.dart';

class AirspaceMetadata {
  final String id;
  final String name;
  final AirspaceClass icaoClass;
  final AirspaceType type;
  final String country;
  final AirspaceLimit limitLower;
  final AirspaceLimit limitUpper;
  final AirspaceActivity? activity;
  final bool? byNotam;
  final bool? onDemand;
  final bool? onRequest;
  final List<AirspaceFrequency>? frequencies;
  final Map<String, dynamic>? geometry;

  AirspaceMetadata({
    required this.id,
    required this.name,
    required this.icaoClass,
    required this.type,
    required this.country,
    required this.limitLower,
    required this.limitUpper,
    this.activity,
    this.byNotam,
    this.onDemand,
    this.onRequest,
    this.frequencies,
    this.geometry,
  });

  List<List<List<List<double>>>> get polygons {
    final geom = geometry;
    if (geom == null) return const [];
    try {
      final String type = geom['type'] as String;
      final List<dynamic> coords = geom['coordinates'] as List<dynamic>;
      final List<List<List<List<double>>>> polygons = [];

      List<List<List<double>>> parsePolygon(List<dynamic> polyCoords) {
        final List<List<List<double>>> poly = [];
        for (final dynamic ringObj in polyCoords) {
          final List<List<double>> ring = [];
          for (final dynamic pt in ringObj) {
            ring.add([(pt[0] as num).toDouble(), (pt[1] as num).toDouble()]);
          }
          poly.add(ring);
        }
        return poly;
      }

      if (type == 'Polygon') {
        polygons.add(parsePolygon(coords));
      } else if (type == 'MultiPolygon') {
        for (final dynamic polyObj in coords) {
          polygons.add(parsePolygon(polyObj as List<dynamic>));
        }
      }
      return polygons;
    } catch (_) {
      return const [];
    }
  }

  factory AirspaceMetadata.fromJson(Map<String, Object?> json) {
    final lowerLimitJson = json['lowerLimit'];
    final upperLimitJson = json['upperLimit'];

    return AirspaceMetadata(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icaoClass: AirspaceClass.fromInt(
        (json['icaoClass'] as num? ?? -1).toInt(),
      ),
      type: AirspaceType.fromInt((json['type'] as num? ?? -1).toInt()),
      country: (json['country'] ?? '').toString(),
      limitLower: AirspaceLimit.fromJson(
        lowerLimitJson is Map<String, Object?> ? lowerLimitJson : const {},
      ),
      limitUpper: AirspaceLimit.fromJson(
        upperLimitJson is Map<String, Object?> ? upperLimitJson : const {},
      ),
      activity: json['activity'] != null
          ? AirspaceActivity.fromInt((json['activity'] as num).toInt())
          : null,
      byNotam: json['byNotam'] as bool?,
      onDemand: json['onDemand'] as bool?,
      onRequest: json['onRequest'] as bool?,
      frequencies: (json['frequencies'] as List<dynamic>?)
          ?.map((f) => AirspaceFrequency.fromJson(Map<String, Object?>.from(f as Map)))
          .toList(),
      geometry: json['geometry'] != null ? Map<String, dynamic>.from(json['geometry'] as Map) : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      '_id': id,
      'name': name,
      'icaoClass': icaoClass == AirspaceClass.unclassified
          ? 8
          : icaoClass == AirspaceClass.unknown
          ? 9
          : icaoClass.index,
      'type': type.index,
      'country': country,
      'lowerLimit': limitLower.toJson(),
      'upperLimit': limitUpper.toJson(),
      if (activity != null) 'activity': activity!.index,
      if (byNotam != null) 'byNotam': byNotam,
      if (onDemand != null) 'onDemand': onDemand,
      if (onRequest != null) 'onRequest': onRequest,
      if (frequencies != null) 'frequencies': frequencies!.map((f) => f.toJson()).toList(),
      if (geometry != null) 'geometry': geometry,
    };
  }
}
