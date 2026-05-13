import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre/maplibre.dart';

class LocationService {
  static const String _geoIpUrl = 'https://ipapi.co/json/';

  /// Gets the best available location.
  /// 1. Tries last known GPS position on mobile platforms.
  /// 2. Falls back to GeoIP.
  /// 3. Returns null if both fail.
  static Future<Geographic?> getCurrentLocation() async {
    // on web it would show permission dialog and we don't want that
    if (!kIsWeb) {
      try {
        final gpsLocation = await _getLastKnownGpsLocation();
        if (gpsLocation != null) {
          debugPrint(
            'Location found via GPS: ${gpsLocation.lat}, ${gpsLocation.lon}',
          );
          return gpsLocation;
        }
      } catch (e) {
        debugPrint('GPS location failed: $e');
      }
    }

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

  static Future<Geographic?> _getLastKnownGpsLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      return Geographic(lon: position.longitude, lat: position.latitude);
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
