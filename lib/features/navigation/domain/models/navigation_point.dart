import '../../../../core/utils/geo_utils.dart';

class NavigationPoint {
  final double latitude;
  final double longitude;
  final String name;
  final bool isAirport;
  final String? airportId;
  final String? airportCountry;
  final String? favoriteId;
  final int? weatherAltitudeFeet;

  const NavigationPoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.isAirport = false,
    this.airportId,
    this.airportCountry,
    this.favoriteId,
    this.weatherAltitudeFeet,
  });

  NavigationPoint withWeatherAltitude(int? feet) => NavigationPoint(
    latitude: latitude,
    longitude: longitude,
    name: name,
    isAirport: isAirport,
    airportId: airportId,
    airportCountry: airportCountry,
    favoriteId: favoriteId,
    weatherAltitudeFeet: feet,
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': name,
    'isAirport': isAirport,
    if (airportId != null) 'airportId': airportId,
    if (airportCountry != null) 'airportCountry': airportCountry,
    if (favoriteId != null) 'favoriteId': favoriteId,
    if (weatherAltitudeFeet != null) 'weatherAltitudeFeet': weatherAltitudeFeet,
  };

  factory NavigationPoint.fromJson(Map<String, dynamic> json) {
    if (json case {
      'latitude': num latitude,
      'longitude': num longitude,
      'name': String name,
    }) {
      return NavigationPoint(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        name: name,
        isAirport: json['isAirport'] == true,
        airportId: json['airportId'] as String?,
        airportCountry: json['airportCountry'] as String?,
        favoriteId: json['favoriteId'] as String?,
        weatherAltitudeFeet: (json['weatherAltitudeFeet'] as num?)?.toInt(),
      );
    }
    throw FormatException('Invalid JSON for NavigationPoint: $json');
  }

  double distanceTo(double otherLat, double otherLon) {
    return GeoUtils.distanceBetween(latitude, longitude, otherLat, otherLon);
  }
}
