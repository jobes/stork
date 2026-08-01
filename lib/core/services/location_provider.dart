import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
    DateTime? timestamp,
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
      timestamp: pos.timestamp,
    ),
  );
}

/// Provider for the display orientation offset applied to the compass heading.
/// Sensors report in the device's natural coordinate system, but when the
/// display rotates (e.g. landscape), the screen "up" direction differs from
/// the device's physical top. This offset compensates for that.
///
/// Typical values:
/// - Portrait (natural): 0°
/// - Landscape: 90° (device physical top to the left of screen)
@Riverpod(keepAlive: true)
class CompassOrientationOffset extends _$CompassOrientationOffset {
  @override
  double build() {
    return _readOrientationOffset();
  }

  /// Derives the orientation offset from the current viewport size
  /// ([FlutterView.physicalSize]), which reflects the app's actual rotation on
  /// every platform. [ui.Display.size] must not be used here — it reports the
  /// physical display/monitor size, which does not rotate with the view (on
  /// desktop it is the monitor's fixed size), so the offset would never update.
  ///
  /// Note: Flutter 3.x does not expose a signed display rotation (there is no
  /// view rotation getter), so the two landscape directions cannot be told
  /// apart from size alone. +90° assumes the device physical top is to the left
  /// of the screen (the usual EFB mounting orientation).
  double _readOrientationOffset() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final size = view.physicalSize;
    return size.width > size.height ? 90.0 : 0.0;
  }

  /// Must be called from a widget when display metrics change (rotation).
  void onMetricsChanged() {
    state = _readOrientationOffset();
  }
}

@Riverpod(keepAlive: true)
Stream<double?> compassStream(Ref ref) {
  DateTime? lastUpdate;
  MagnetometerEvent? lastMag;
  AccelerometerEvent? lastAcc;

  // Cache orientation offset locally — updated via ref.listen when display rotates.
  // fireImmediately applies the current offset before any sensor event is
  // processed, so the first heading is already compensated.
  var orientationOffset = 0.0;
  ref.listen(compassOrientationOffsetProvider, (_, next) {
    orientationOffset = next;
  }, fireImmediately: true);

  final controller = StreamController<double?>();

  void tryEmit() {
    if (lastMag == null || lastAcc == null) return;
    final now = DateTime.now();
    if (lastUpdate != null &&
        now.difference(lastUpdate!) < const Duration(seconds: 1)) {
      return;
    }
    lastUpdate = now;
    final rawHeading = _computeHeading(lastMag!, lastAcc!);
    if (rawHeading == null) return;
    controller.add((rawHeading + orientationOffset) % 360);
  }

  final magSub = magnetometerEventStream().listen((mag) {
    lastMag = mag;
    tryEmit();
  });
  final accSub = accelerometerEventStream().listen((acc) {
    lastAcc = acc;
    tryEmit();
  });

  ref.onDispose(() {
    magSub.cancel();
    accSub.cancel();
    controller.close();
  });

  return controller.stream;
}

/// Computes compass heading in degrees (0-360) from raw sensor data.
/// Returns null if the device orientation prevents a valid calculation.
///
/// Implements Android's SensorManager.getRotationMatrix + getOrientation:
///   H = magnetometer × accelerometer   (East-ish direction)
///   M = accelerometer × H              (North-ish direction)
///   azimuth = atan2(Hy, My)
double? _computeHeading(MagnetometerEvent mag, AccelerometerEvent acc) {
  final ax = acc.x;
  final ay = acc.y;
  final az = acc.z;

  final mx = mag.x;
  final my = mag.y;
  final mz = mag.z;

  if (ax * ax + ay * ay + az * az < 0.01) return null;

  // Normalize accelerometer
  final accNorm = sqrt(ax * ax + ay * ay + az * az);
  final nax = ax / accNorm;
  final nay = ay / accNorm;
  final naz = az / accNorm;

  // H = magnetometer × accelerometer (points East)
  // Normalise H (cross-product magnitude = sine of angle between vectors)
  double hx = my * naz - mz * nay;
  double hy = mz * nax - mx * naz;
  double hz = mx * nay - my * nax;
  final hNorm = sqrt(hx * hx + hy * hy + hz * hz);
  if (hNorm < 0.01) return null;
  hx /= hNorm;
  hy /= hNorm;
  hz /= hNorm;

  // M = accelerometer × H (points North)
  final myResult = naz * hx - nax * hz;

  // Azimuth from the device Y axis projected onto the horizontal plane:
  //   azimuth = atan2(Hy, My)
  double heading = atan2(hy, myResult) * 180 / pi;
  if (heading < 0) heading += 360;

  return heading;
}
