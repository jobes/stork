import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:maplibre/maplibre.dart';
import 'location_service.dart';
import '../../../features/telemetry/domain/models/map_view_state.dart';
import '../../../features/telemetry/presentation/providers/telemetry_provider.dart';

part 'location_provider.g.dart';

@riverpod
Future<Geographic?> currentLocation(Ref ref) async {
  return await LocationService.getCurrentLocation();
}

@riverpod
Stream<({double lat, double lon, double heading, double speed})> positionStream(
  Ref ref,
) {
  final mapViewState = ref.watch(
    telemetryProvider.select((s) => s.mapViewState),
  );

  // Don't start the stream (and trigger permission prompt) while in init mode
  if (mapViewState == MapViewState.init) {
    return const Stream.empty();
  }

  return geo.Geolocator.getPositionStream(
    locationSettings: const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 1,
    ),
  ).map(
    (pos) => (
      lat: pos.latitude,
      lon: pos.longitude,
      heading: pos.heading,
      speed: pos.speed,
    ),
  );
}

@riverpod
Stream<double?> compassStream(Ref ref) {
  DateTime? lastUpdate;

  return FlutterCompass.events
          ?.where((event) {
            final now = DateTime.now();
            if (lastUpdate == null ||
                now.difference(lastUpdate!) >= const Duration(seconds: 1)) {
              lastUpdate = now;
              return true;
            }
            return false;
          })
          .map((event) => event.heading) ??
      const Stream.empty();
}
