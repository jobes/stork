import '../../../../core/utils/geo_utils.dart';

class NavigationPoint {
  final double latitude;
  final double longitude;
  final String name;
  final bool isAirport;

  const NavigationPoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.isAirport = false,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': name,
    'isAirport': isAirport,
  };

  factory NavigationPoint.fromJson(Map<String, dynamic> json) {
    if (json case {
      'latitude': num latitude,
      'longitude': num longitude,
      'name': String name,
    }) {
      final isAirport = json['isAirport'];
      return NavigationPoint(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        name: name,
        isAirport: isAirport is bool ? isAirport : false,
      );
    }
    throw FormatException('Invalid JSON for NavigationPoint: $json');
  }

  double distanceTo(double otherLat, double otherLon) {
    return GeoUtils.distanceBetween(latitude, longitude, otherLat, otherLon);
  }
}
