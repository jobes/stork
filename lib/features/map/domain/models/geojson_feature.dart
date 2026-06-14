import 'airport_metadata.dart';

class GeoJsonFeature {
  final String type;
  final AirportMetadata properties;

  GeoJsonFeature({required this.type, required this.properties});

  factory GeoJsonFeature.fromJson(Map<String, Object?> json) {
    final props = json['properties'];
    return GeoJsonFeature(
      type: (json['type'] ?? 'Feature').toString(),
      properties: AirportMetadata.fromJson(
        props is Map<String, Object?> ? props : const <String, Object?>{},
      ),
    );
  }
}
