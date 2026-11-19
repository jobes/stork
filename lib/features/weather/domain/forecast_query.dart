import 'package:freezed_annotation/freezed_annotation.dart';

import 'flight_forecast.dart';

part 'forecast_query.freezed.dart';

String forecastLocationKey(ForecastLocation location) =>
    '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';

/// Rounds a profile coordinate to the local model grid. Reuse for the moving
/// aircraft is controlled by [forecastOriginRefreshDistanceMeters].
const forecastLocationGrid = 0.03;

ForecastLocation quantizeForecastLocation(ForecastLocation location) => (
  latitude:
      (location.latitude / forecastLocationGrid).round() * forecastLocationGrid,
  longitude:
      (location.longitude / forecastLocationGrid).round() *
      forecastLocationGrid,
);

@Freezed(
  equal: false,
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ForecastQuery with _$ForecastQuery {
  const ForecastQuery._();

  const factory ForecastQuery._value({
    required Map<String, ForecastLocation> locations,
    required DateTime start,
    required DateTime end,
  }) = _ForecastQuery;

  factory ForecastQuery(
    Iterable<ForecastLocation> locations,
    DateTime start,
    DateTime end,
  ) => ForecastQuery._value(
    locations: Map.unmodifiable({
      for (final location in locations) forecastLocationKey(location): location,
    }),
    start: start,
    end: end,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastQuery &&
          start == other.start &&
          end == other.end &&
          locations.length == other.locations.length &&
          locations.keys.every(other.locations.containsKey);

  @override
  int get hashCode =>
      Object.hash(start, end, Object.hashAllUnordered(locations.keys));
}
