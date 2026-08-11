import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../map/domain/models/poi_type.dart';

part 'favorite_point.freezed.dart';
part 'favorite_point.g.dart';

/// A user-defined favourite point of interest stored locally and rendered as a
/// POI marker on the map.
///
/// The [description] supports basic formatting: `**bold**` and `*italic*`
/// markers are rendered by `Textf`.
@freezed
abstract class FavoritePoint with _$FavoritePoint {
  const factory FavoritePoint({
    required String id,
    required double latitude,
    required double longitude,
    required PoiType icon,
    required String name,
    @Default('') String description,
  }) = _FavoritePoint;

  factory FavoritePoint.fromJson(Map<String, dynamic> json) =>
      _$FavoritePointFromJson(json);
}
