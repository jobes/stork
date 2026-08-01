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
/// The offset is the *signed* rotation of the screen-up direction relative to
/// the device's natural Y axis, derived from the gravity vector (accelerometer)
/// in the device frame. Unlike a size-only heuristic it distinguishes the two
/// landscape directions and yields 0° for a natural-landscape device in its
/// natural orientation.
///
/// Typical values:
/// - Portrait (natural): 0°
/// - Landscape, device physical top to the left of screen: +90°
/// - Landscape, device physical top to the right of screen: -90°
/// - Natural-landscape device, natural orientation: 0°
@Riverpod(keepAlive: true)
class CompassOrientationOffset extends _$CompassOrientationOffset {
  static const double _kGravity = 9.80665;

  // Low-pass filtered gravity (m/s²) in the device's natural coordinate frame,
  // used to derive the signed screen-up rotation.
  double _gx = 0;
  double _gy = 0;
  double _gz = 0;
  bool _hasGravity = false;
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  double build() {
    // Initial value from the viewport size ([FlutterView.physicalSize]). Only a
    // fallback — once sensor data arrives the state is replaced by the signed
    // rotation derived from gravity.
    final initial = _sizeBasedOffset();
    _sub?.cancel();
    _sub = accelerometerEventStream().listen(
      _onAccelerometerEvent,
      onError: (Object _) {
        // No accelerometer available (e.g. some desktop/web targets): keep the
        // size-based fallback.
      },
    );
    ref.onDispose(() => _sub?.cancel());
    return initial;
  }

  void _onAccelerometerEvent(AccelerometerEvent acc) {
    // Low-pass filter to separate gravity from short-lived linear acceleration
    // (turns, climbs, turbulence).
    const alpha = 0.15;
    if (!_hasGravity) {
      _gx = acc.x;
      _gy = acc.y;
      _gz = acc.z;
      _hasGravity = true;
    } else {
      _gx += alpha * (acc.x - _gx);
      _gy += alpha * (acc.y - _gy);
      _gz += alpha * (acc.z - _gz);
    }
    state = _readOrientationOffset();
  }

  /// Signed rotation (degrees) of the screen-up direction from the device's
  /// natural Y axis, derived from the accelerometer gravity vector.
  ///
  /// sensors_plus normalises the accelerometer on every platform to point
  /// "up" (away from gravity) in the device frame (Android convention), so
  /// `atan2(gx, gy)` is the angle of the screen-up direction relative to the
  /// device's natural top. The angle is quantised to the nearest 90°, matching
  /// the display-rotation steps used by the OS.
  double _readOrientationOffset() {
    if (!_hasGravity) return _sizeBasedOffset();
    final horiz = sqrt(_gx * _gx + _gy * _gy);
    if (horiz < 0.3 * _kGravity) {
      // Device nearly flat: gravity has no reliable in-screen-plane component.
      // Keep the last known offset (or the size-based estimate).
      return state;
    }
    final angle = atan2(_gx, _gy) * 180 / pi;
    return (angle / 90).roundToDouble() * 90;
  }

  /// Fallback offset derived from the viewport size
  /// ([FlutterView.physicalSize]), which reflects the app's actual rotation on
  /// every platform. [ui.Display.size] must not be used here — it reports the
  /// physical display/monitor size, which does not rotate with the view (on
  /// desktop it is the monitor's fixed size), so the offset would never update.
  ///
  /// Size alone cannot distinguish the two landscape directions (Flutter does
  /// not expose a signed display rotation), so this is used only as the initial
  /// value and on devices without an accelerometer. +90° then assumes the
  /// device physical top is to the left of the screen (the usual EFB mounting
  /// orientation).
  double _sizeBasedOffset() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final size = view.physicalSize;
    return size.width > size.height ? 90.0 : 0.0;
  }

  /// Must be called from a widget when display metrics change (rotation).
  /// Re-reads the current offset; with sensor data available this returns the
  /// signed gravity-based value, otherwise the size-based fallback.
  void onMetricsChanged() {
    state = _readOrientationOffset();
  }
}

@Riverpod(keepAlive: true)
Stream<double?> compassStream(Ref ref) {
  DateTime? lastUpdate;
  MagnetometerEvent? lastMag;
  AccelerometerEvent? lastAcc;

  // Cache the orientation offset locally — updated via ref.listen as the
  // display rotates or gravity changes. fireImmediately applies the current
  // offset before any sensor event is processed, so the first heading is
  // already compensated.
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
