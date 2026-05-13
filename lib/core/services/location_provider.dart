import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:maplibre/maplibre.dart';
import 'location_service.dart';

part 'location_provider.g.dart';

@riverpod
Future<Geographic?> currentLocation(Ref ref) async {
  return await LocationService.getCurrentLocation();
}
