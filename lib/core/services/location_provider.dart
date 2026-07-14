import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:maplibre/maplibre.dart';
import 'location_service.dart';
import '../../l10n/app_localizations.dart';
import '../../../features/telemetry/domain/models/map_view_state.dart';
import '../../../features/telemetry/presentation/providers/telemetry_provider.dart';

part 'location_provider.g.dart';

@riverpod
Future<Geographic?> currentLocation(Ref ref) async {
  return await LocationService.getCurrentLocation();
}

/// Stream of user positions. The returned [altitude] is in Mean Sea Level (MSL) datum
/// (configured via AndroidSettings.useMSLAltitude on Android).
@riverpod
Stream<
  ({
    double lat,
    double lon,
    double heading,
    double groundSpeed,
    double horizontalAccuracy,
    double verticalAccuracy,
    double altitude,
  })
>
positionStream(Ref ref) {
  final mapViewState = ref.watch(
    telemetryProvider.select((s) => s.mapViewState),
  );

  // Don't start the stream (and trigger permission prompt) while in init mode
  if (mapViewState == MapViewState.init) {
    return const Stream.empty();
  }

  // Keep the native GPS stream active with lowest accuracy and filtered emissions to save battery when DroneCAN GPS is active
  final isGpsDroneCan = ref.watch(
    telemetryProvider.select((s) => s.isGpsDroneCan),
  );

  final geo.LocationSettings locationSettings;
  if (defaultTargetPlatform == TargetPlatform.android) {
    final locale = ui.PlatformDispatcher.instance.locale;
    final isSupported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    final supportedLocale = isSupported ? locale : const Locale('en');
    final l10n = lookupAppLocalizations(supportedLocale);

    locationSettings = geo.AndroidSettings(
      accuracy: isGpsDroneCan
          ? geo.LocationAccuracy.lowest
          : geo.LocationAccuracy.bestForNavigation,
      distanceFilter: isGpsDroneCan ? 100000 : 0,
      intervalDuration: isGpsDroneCan
          ? const Duration(seconds: 10)
          : const Duration(seconds: 1),
      useMSLAltitude: !isGpsDroneCan,
      foregroundNotificationConfig: geo.ForegroundNotificationConfig(
        notificationTitle: l10n.gpsNotificationTitle,
        notificationText: l10n.gpsNotificationText,
        enableWakeLock: true,
      ),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    locationSettings = geo.AppleSettings(
      accuracy: isGpsDroneCan
          ? geo.LocationAccuracy.lowest
          : geo.LocationAccuracy.bestForNavigation,
      distanceFilter: isGpsDroneCan ? 100000 : 0,
      activityType: geo.ActivityType.otherNavigation,
      allowBackgroundLocationUpdates: true,
      pauseLocationUpdatesAutomatically: false,
    );
  } else {
    locationSettings = geo.LocationSettings(
      accuracy: isGpsDroneCan
          ? geo.LocationAccuracy.lowest
          : geo.LocationAccuracy.bestForNavigation,
      distanceFilter: isGpsDroneCan ? 100000 : 0,
    );
  }

  var stream = geo.Geolocator.getPositionStream(
    locationSettings: locationSettings,
  );

  if (isGpsDroneCan) {
    // Keep the stream alive to prevent the OS from suspending the app,
    // but ignore all actual position updates.
    stream = stream.where((_) => false);
  }

  return stream.map(
    (pos) => (
      lat: pos.latitude,
      lon: pos.longitude,
      heading: pos.heading,
      groundSpeed: pos.speed,
      horizontalAccuracy: pos.accuracy,
      verticalAccuracy: pos.altitudeAccuracy,
      altitude: pos.altitude,
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
