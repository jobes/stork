import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/core/services/database/database_service.dart';
import 'package:stork/core/utils/geo_utils.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

part 'nearby_frequencies_provider.g.dart';

class NearbyFrequenciesState {
  final List<MapEntry<AirportMetadata, double>> nearbyAirports;
  final List<MapEntry<AirspaceMetadata, double>> nearbyAirspaces;

  NearbyFrequenciesState({
    required this.nearbyAirports,
    required this.nearbyAirspaces,
  });
}

@riverpod
class NearbyFrequencies extends _$NearbyFrequencies {
  @override
  FutureOr<NearbyFrequenciesState> build() async {
    final telemetry = ref.read(telemetryProvider);
    final lat = telemetry.latitude;
    final lon = telemetry.longitude;

    if (lat == null || lon == null) {
      return NearbyFrequenciesState(nearbyAirports: [], nearbyAirspaces: []);
    }

    // Načítanie letísk
    final memoryAirports = ref.read(airportMetadataCacheProvider.notifier).memoryCache.values.toList();
    final dbAptFeatures = await DatabaseService.getAllOpenAipFeatures('apt');
    final dbAirports = dbAptFeatures.map((json) {
      try {
        return AirportMetadata.fromJson(json);
      } catch (_) {
        return null;
      }
    }).whereType<AirportMetadata>().toList();

    final allAirportsMap = <String, AirportMetadata>{};
    for (final apt in dbAirports) {
      if (apt.latitude != null && apt.longitude != null) {
        allAirportsMap[apt.id] = apt;
      }
    }
    for (final apt in memoryAirports) {
      if (apt.latitude != null && apt.longitude != null) {
        allAirportsMap[apt.id] = apt;
      }
    }

    final airportsWithDistance = allAirportsMap.values.map((apt) {
      final dist = GeoUtils.distanceBetween(lat, lon, apt.latitude!, apt.longitude!);
      return MapEntry(apt, dist);
    }).toList();

    airportsWithDistance.sort((a, b) => a.value.compareTo(b.value));

    // Načítanie priestorov
    final memoryAirspaces = ref.read(airspaceMetadataCacheProvider.notifier).memoryCache.values.toList();
    final dbAspFeatures = await DatabaseService.getAllOpenAipFeatures('asp');
    final dbAirspaces = dbAspFeatures.map((json) {
      try {
        return AirspaceMetadata.fromJson(json);
      } catch (_) {
        return null;
      }
    }).whereType<AirspaceMetadata>().toList();

    final allAirspacesMap = <String, AirspaceMetadata>{};
    for (final asp in dbAirspaces) {
      if (asp.geometry != null) {
        allAirspacesMap[asp.id] = asp;
      }
    }
    for (final asp in memoryAirspaces) {
      if (asp.geometry != null) {
        allAirspacesMap[asp.id] = asp;
      }
    }

    final airspacesWithDistance = allAirspacesMap.values.map((asp) {
      final dist = GeoUtils.distanceToPolygons(lat, lon, asp.polygons);
      return MapEntry(asp, dist);
    }).where((entry) => entry.key.frequencies != null && entry.key.frequencies!.isNotEmpty).toList();

    airspacesWithDistance.sort((a, b) {
      final distA = a.value;
      final distB = b.value;
      if (distA == 0.0 && distB == 0.0) {
        return a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase());
      }
      return distA.compareTo(distB);
    });

    return NearbyFrequenciesState(
      nearbyAirports: airportsWithDistance.take(5).toList(),
      nearbyAirspaces: airspacesWithDistance.take(5).toList(),
    );
  }
}
