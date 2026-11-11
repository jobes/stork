import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_access_provider.g.dart';

/// OS-level location access state.
@immutable
class LocationAccessState {
  const LocationAccessState({
    this.permissionDenied = false,
    this.servicesDisabled = false,
  });

  /// The app is not allowed to use the device location.
  final bool permissionDenied;

  /// Location services are switched off system-wide.
  final bool servicesDisabled;

  bool get hasIssue => permissionDenied || servicesDisabled;

  @override
  bool operator ==(Object other) =>
      other is LocationAccessState &&
      other.permissionDenied == permissionDenied &&
      other.servicesDisabled == servicesDisabled;

  @override
  int get hashCode => Object.hash(permissionDenied, servicesDisabled);

  @override
  String toString() =>
      'LocationAccessState(permissionDenied: $permissionDenied, '
      'servicesDisabled: $servicesDisabled)';
}

/// Reads the OS location permission and location-service state.
///
/// Platform access lives in `core` rather than in a presentation notifier so
/// the checks can be stubbed in tests. Nothing is polled in the background:
/// consumers call [LocationAccess.refresh] when they need a current answer.
@Riverpod(keepAlive: true)
class LocationAccess extends _$LocationAccess {
  @override
  LocationAccessState build() => const LocationAccessState();

  Future<void> refresh() async {
    var servicesEnabled = true;
    if (!kIsWeb) {
      try {
        servicesEnabled = await geo.Geolocator.isLocationServiceEnabled();
      } catch (error) {
        debugPrint('[LocationAccess] service check failed: $error');
      }
    }

    var permission = geo.LocationPermission.unableToDetermine;
    try {
      permission = await geo.Geolocator.checkPermission();
    } catch (error) {
      debugPrint('[LocationAccess] permission check failed: $error');
    }

    final next = LocationAccessState(
      permissionDenied:
          permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever,
      servicesDisabled: !servicesEnabled,
    );
    if (next != state) state = next;
  }
}
