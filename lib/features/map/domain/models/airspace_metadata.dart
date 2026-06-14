import 'airspace_class.dart';
import 'airspace_type.dart';
import 'airspace_limit.dart';
import 'airspace_activity.dart';

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
  });

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
    };
  }
}
