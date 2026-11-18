enum MapSearchResultType { airport, favorite, municipality }

class MapSearchResult {
  const MapSearchResult({
    required this.type,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.airportId,
    this.airportCountry,
    this.icaoCode = '',
    this.area = '',
  });

  final MapSearchResultType type;
  final String name;
  final double latitude;
  final double longitude;
  final String? airportId;
  final String? airportCountry;
  final String icaoCode;
  final String area;
}
