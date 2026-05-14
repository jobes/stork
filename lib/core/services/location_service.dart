import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:maplibre/maplibre.dart';

class LocationService {
  static const String _geoIpUrl = 'https://ipapi.co/json/';

  /// Checks if the application already has GPS permissions.
  static Future<bool> hasPermission() async {
    final permission = await geo.Geolocator.checkPermission();
    return permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse;
  }

  /// Gets the best available location.
  /// If [requestPermission] is true, it will show the system dialog if needed.
  /// Otherwise, it only tries GPS if permission is already granted, falling back to GeoIP.
  static Future<Geographic?> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    // 1. Try GPS
    final gpsLocation = await getGpsLocationOnly(
      requestPermission: requestPermission,
    );
    if (gpsLocation != null) return gpsLocation;

    // 2. Fallback to GeoIP
    try {
      final geoIpLocation = await _getGeoIpLocation();
      if (geoIpLocation != null) {
        debugPrint(
          'Location found via GeoIP: ${geoIpLocation.lat}, ${geoIpLocation.lon}',
        );
        return geoIpLocation;
      }
    } catch (e) {
      debugPrint('GeoIP location failed: $e');
    }

    return null;
  }

  /// Gets location ONLY via GPS/System services, no GeoIP fallback.
  static Future<Geographic?> getGpsLocationOnly({
    bool requestPermission = false,
  }) async {
    try {
      final gpsLocation = await _getGpsLocation(
        requestPermission: requestPermission,
      );
      if (gpsLocation != null) {
        debugPrint(
          'Location found via GPS: ${gpsLocation.lat}, ${gpsLocation.lon}',
        );
        return gpsLocation;
      }
    } catch (e) {
      debugPrint('GPS location failed: $e');
    }
    return null;
  }

  static Future<Geographic?> _getGpsLocation({
    required bool requestPermission,
  }) async {
    // 1. Check if service is enabled (skipping on web as it's not always relevant/supported)
    if (!kIsWeb) {
      if (!await geo.Geolocator.isLocationServiceEnabled()) return null;
    }

    // 2. Handle permissions
    var permission = await geo.Geolocator.checkPermission();

    if (requestPermission) {
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      
      if (permission == geo.LocationPermission.deniedForever) {
        // On Web, we can't easily open settings, so we just fail
        return null;
      }
      
      // If we have permission (or just got it), perform an active fetch
      if (permission == geo.LocationPermission.always ||
          permission == geo.LocationPermission.whileInUse) {
        try {
          final position = await geo.Geolocator.getCurrentPosition(
            locationSettings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          return Geographic(lon: position.longitude, lat: position.latitude);
        } catch (e) {
          debugPrint('Error getting current position: $e');
          return null;
        }
      }
    }

    // 3. Quiet mode (no permission request)
    if (permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse) {
      final position = await geo.Geolocator.getLastKnownPosition();
      if (position != null) {
        return Geographic(lon: position.longitude, lat: position.latitude);
      }
    }

    return null;
  }

  static Future<Geographic?> _getGeoIpLocation() async {
    final response = await http.get(Uri.parse(_geoIpUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final lat = data['latitude'] as double?;
      final lon = data['longitude'] as double?;
      if (lat != null && lon != null) {
        return Geographic(lon: lon, lat: lat);
      }
    }
    return null;
  }
}
