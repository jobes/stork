// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FavoritePoint _$FavoritePointFromJson(Map<String, dynamic> json) =>
    _FavoritePoint(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      icon: $enumDecode(_$PoiTypeEnumMap, json['icon']),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );

Map<String, dynamic> _$FavoritePointToJson(_FavoritePoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'icon': _$PoiTypeEnumMap[instance.icon]!,
      'name': instance.name,
      'description': instance.description,
    };

const _$PoiTypeEnumMap = {
  PoiType.home: 'home',
  PoiType.thermal: 'thermal',
  PoiType.airfield: 'airfield',
  PoiType.outlanding: 'outlanding',
  PoiType.fuel: 'fuel',
  PoiType.restaurant: 'restaurant',
  PoiType.viewpoint: 'viewpoint',
  PoiType.camping: 'camping',
  PoiType.hospital: 'hospital',
  PoiType.parking: 'parking',
};
