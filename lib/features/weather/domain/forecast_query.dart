import 'flight_forecast.dart';

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

class ForecastQuery {
  final Map<String, ForecastLocation> locations;
  final DateTime start;
  final DateTime end;

  ForecastQuery(Iterable<ForecastLocation> locations, this.start, this.end)
    : locations = {
        for (final location in locations)
          forecastLocationKey(location): location,
      };

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
