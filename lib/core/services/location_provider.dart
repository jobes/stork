import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:maplibre/maplibre.dart';
import 'location_service.dart';
import '../../l10n/app_localizations.dart';

part 'location_provider.g.dart';

@riverpod
Future<Geographic?> currentLocation(Ref ref) async {
  return await LocationService.getCurrentLocation();
}

/// Builds the OS location settings for the phone's own GPS stream.
///
/// While a DroneCAN GPS is the active source ([droneCan] == true) the phone
/// stream is downgraded to `lowest` accuracy / 100 km distance filter / 10 s
/// interval to save battery (its emissions are ignored anyway). Otherwise it
/// runs at `bestForNavigation` with a 1 s interval for smooth tracking.
geo.LocationSettings _locationSettings({required bool droneCan}) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final locale = ui.PlatformDispatcher.instance.locale;
    final isSupported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    final supportedLocale = isSupported ? locale : const Locale('en');
    final l10n = lookupAppLocalizations(supportedLocale);

    return geo.AndroidSettings(
      accuracy: droneCan
          ? geo.LocationAccuracy.lowest
          : geo.LocationAccuracy.bestForNavigation,
      distanceFilter: droneCan ? 100000 : 0,
      intervalDuration: droneCan
          ? const Duration(seconds: 10)
          : const Duration(seconds: 1),
      useMSLAltitude: !droneCan,
      foregroundNotificationConfig: geo.ForegroundNotificationConfig(
        notificationTitle: l10n.gpsNotificationTitle,
        notificationText: l10n.gpsNotificationText,
        enableWakeLock: true,
      ),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return geo.AppleSettings(
      accuracy: droneCan
          ? geo.LocationAccuracy.lowest
          : geo.LocationAccuracy.bestForNavigation,
      distanceFilter: droneCan ? 100000 : 0,
      activityType: geo.ActivityType.otherNavigation,
      allowBackgroundLocationUpdates: true,
      pauseLocationUpdatesAutomatically: false,
    );
  } else {
    return geo.LocationSettings(
      accuracy: droneCan
          ? geo.LocationAccuracy.lowest
          : geo.LocationAccuracy.bestForNavigation,
      distanceFilter: droneCan ? 100000 : 0,
    );
  }
}

/// Lifecycle status of the OS location stream, exposed through the provider
/// state so consumers ([gpsListener], UI) can detect failures instead of only
/// seeing positions silently stop.
sealed class GeolocatorStreamStatus {
  const GeolocatorStreamStatus();
}

/// The OS stream is running (or not started yet) without any error.
class GeolocatorStreamOk extends GeolocatorStreamStatus {
  const GeolocatorStreamOk();
}

/// The OS stream reported an error; a retry is scheduled automatically.
class GeolocatorStreamFailed extends GeolocatorStreamStatus {
  const GeolocatorStreamFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// A single, persistent stream of raw OS positions.
///
/// The native OS subscription is started explicitly (see [start]) the first
/// time the map needs a fix, and then kept alive for the whole app session.
/// It is intentionally never torn down when other state changes: re-creating
/// the geolocator stream on every rebuild cancels the OS location subscription
/// and re-subscribes, which on Android can silently leave the app subscribed
/// to a dead stream — the phone GPS then stops delivering positions (frozen
/// aircraft, no ground speed, no GPS accuracy) even though the map works.
///
/// The state is a two-field record (instead of a bare `Stream`) purely so the
/// code generator emits a plain [NotifierProvider] rather than a
/// `StreamNotifier` (whose watched value would be an `AsyncValue`, hiding the
/// raw stream that [gpsListener] subscribes to directly). The second field
/// carries the [GeolocatorStreamStatus] so OS stream failures stay observable
/// instead of being silently swallowed.
///
/// A stall watchdog additionally re-creates the native subscription when the
/// stream goes completely silent *without* an error event (the common Android
/// failure mode where positions simply stop arriving). On its own that would
/// freeze the aircraft until an external GPS client (e.g. Google Maps) wakes
/// the location stack; the watchdog recovers automatically instead — and
/// keeps re-creating the subscription with a growing backoff until the OS
/// delivers again, so a single failed recovery cannot leave the aircraft
/// frozen.
@Riverpod(keepAlive: true)
class GeolocatorStream extends _$GeolocatorStream {
  /// Delay before re-subscribing after an OS stream error, so the phone GPS
  /// recovers on its own (e.g. after location permission/services return).
  static const Duration _retryDelay = Duration(seconds: 5);

  /// How long the phone stream may stay silent (while a ~1 Hz fix is expected
  /// in high-accuracy mode) before it is considered stalled and re-created.
  ///
  /// Android can silently stop delivering positions without ever emitting an
  /// error (the "dead stream" case). Without this watchdog nothing recovers
  /// the fix until an external GPS client (e.g. Google Maps) wakes the
  /// location stack — which is exactly what the pilot observed in flight.
  ///
  /// A plain static (not `const`) so tests can shrink it and exercise the
  /// recovery without waiting ten real seconds.
  @visibleForTesting
  static Duration stallTimeout = const Duration(seconds: 10);

  /// Ceiling of the stall-recovery backoff (see [_stallProbeDelay]): even a
  /// persistently dead OS stream is only re-subscribed to at most this often,
  /// so the watchdog never hammers the native location service.
  static const Duration _stallRecoveryCap = Duration(minutes: 5);

  StreamController<geo.Position>? _controller;
  StreamSubscription<geo.Position>? _subscription;
  Timer? _retryTimer;
  Timer? _stallTimer;
  bool _started = false;
  bool _droneCanMode = false;

  /// Whether the OS stream has ever delivered a position, kept across
  /// re-subscribes.
  ///
  /// The stall watchdog only acts once a position has been delivered: before
  /// the first fix there is no way to tell a dead stream from a device that
  /// simply has no satellite lock yet (re-subscribing would only waste battery
  /// without helping). Keeping it across re-subscribes lets a re-created
  /// stream that stays silently dead be detected and probed again.
  bool _hasProvenFix = false;

  /// Consecutive stall recoveries since the last delivered position. Grows the
  /// watchdog timeout (backoff, see [_stallProbeDelay]) so a genuinely dead
  /// stream is not hammered, while still being probed again and again until
  /// the OS delivers — instead of freezing the aircraft after a single failed
  /// recovery attempt. Reset to zero on the next delivered position.
  int _stallRecoveries = 0;
  Future<void>? _restartInFlight;

  @override
  ({Stream<geo.Position> stream, GeolocatorStreamStatus status}) build() {
    _controller ??= StreamController<geo.Position>.broadcast();
    ref.onDispose(() {
      _retryTimer?.cancel();
      _retryTimer = null;
      _stallTimer?.cancel();
      _stallTimer = null;
      _subscription?.cancel();
      _subscription = null;
      _controller?.close();
      _controller = null;
      _restartInFlight = null;
      _started = false;
      _droneCanMode = false;
      _hasProvenFix = false;
      _stallRecoveries = 0;
    });
    return (stream: _controller!.stream, status: const GeolocatorStreamOk());
  }

  /// Starts the native OS location stream (idempotent). Called once the map
  /// needs a fix (permission granted / user enables tracking), so no location
  /// permission prompt or battery drain happens before that. The first start
  /// is synchronous (there is no previous subscription to tear down).
  void start() {
    if (_started) return;
    _started = true;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message:
            'geolocator: stream started '
            '(${_droneCanMode ? 'dronecan low-power' : 'high-accuracy'})',
        category: 'gps',
        level: SentryLevel.info,
      ),
    );
    _subscribe();
  }

  /// Switches the OS location stream between high-accuracy phone mode and
  /// low-power mode (used while a DroneCAN GPS is the active source, to save
  /// battery). Restarts are serialised and always apply the latest mode; the
  /// old subscription is awaited before re-creating so the geolocator plugin
  /// frees its cached stream (avoids re-subscribing to a dead stream). No-op
  /// before [start] has been called (the mode is remembered and applied then).
  Future<void> setDroneCanActive(bool active) {
    if (_droneCanMode == active) return Future.value();
    _droneCanMode = active;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message:
            'geolocator: mode switch -> '
            '${active ? 'dronecan low-power' : 'high-accuracy'}',
        category: 'gps',
        level: SentryLevel.info,
      ),
    );
    if (!_started) return Future.value();
    _startWithMode();
    return _restartInFlight ?? Future.value();
  }

  void _startWithMode() {
    // A mode switch re-subscribes anyway; drop any pending retry/stall timer.
    _retryTimer?.cancel();
    _retryTimer = null;
    _disarmStallWatchdog();
    _restartInFlight = (_restartInFlight ?? Future.value()).then((_) async {
      if (!_started) return;
      final old = _subscription;
      _subscription = null;
      await old?.cancel();
      if (!_started) return;
      _subscribe();
    });
  }

  /// Opens a new OS location subscription with the current mode. Any previous
  /// subscription must already be cancelled by the caller.
  void _subscribe() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _stallTimer?.cancel();
    _stallTimer = null;
    // A brand-new subscription has no proof of life yet: the stall watchdog
    // is armed from the first delivered position (see [_onPosition]). If this
    // is a re-subscribe after a proven fix (_hasProvenFix) the watchdog is
    // re-armed below so a stream that stays silently dead is detected again.
    try {
      _subscription = geo.Geolocator.getPositionStream(
        locationSettings: _locationSettings(droneCan: _droneCanMode),
      ).listen(_onPosition, onError: _onStreamError);
    } catch (error, stackTrace) {
      // Some platforms surface OS location errors synchronously when the
      // location service is unavailable; treat them like an async error.
      _onStreamError(error, stackTrace);
      return;
    }
    // Re-arm after every (re)subscribe that follows a proven fix, so a stream
    // that dies silently again is recovered — not just once. No-op before the
    // first fix or while a DroneCAN GPS is the active source (see
    // [_armStallWatchdog]).
    _armStallWatchdog();
  }

  void _onPosition(geo.Position pos) {
    // A delivered position proves the OS stream is healthy again.
    if (state.status is GeolocatorStreamFailed) {
      state = (stream: _controller!.stream, status: const GeolocatorStreamOk());
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'geolocator: stream recovered (position back)',
          category: 'gps',
          level: SentryLevel.info,
        ),
      );
    }
    _hasProvenFix = true;
    // A delivered position proves the stream is live again: reset the stall
    // recovery backoff and re-arm the watchdog so the next stall is measured
    // from this fix, not from subscription time.
    _stallRecoveries = 0;
    _armStallWatchdog();
    _controller?.add(pos);
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    debugPrint('[GeolocatorStream] OS position stream error: $error');
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'geolocator: OS stream error: $error',
        category: 'gps',
        level: SentryLevel.error,
      ),
    );
    _subscription?.cancel();
    _subscription = null;
    _disarmStallWatchdog();
    state = (
      stream: _controller!.stream,
      status: GeolocatorStreamFailed(error, stackTrace),
    );
    _scheduleRetry();
  }

  /// Re-subscribes after [_retryDelay] so the stream recovers on its own
  /// (e.g. once the user re-enables location permission or services).
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (_started && _subscription == null) {
        _subscribe();
      }
    });
  }

  /// (Re)starts the stall watchdog. It is only armed while the native stream
  /// is live in high-accuracy phone mode, where a ~1 Hz fix is expected, and
  /// only once the stream has proven it can deliver a position
  /// (_hasProvenFix) — before the first fix silence just means "no lock yet".
  ///
  /// It is deliberately NOT armed while a DroneCAN GPS is the active source:
  /// there the phone request is downgraded to a passive/low-power request that
  /// can legitimately stay silent for long stretches (its positions are
  /// ignored anyway), so silence must not be mistaken for a stall.
  ///
  /// The delay grows with [_stallRecoveries] (see [_stallProbeDelay]) so a
  /// stream that keeps dying is not hammered, yet keeps being probed until the
  /// OS delivers again — even if that is minutes later.
  void _armStallWatchdog() {
    _stallTimer?.cancel();
    _stallTimer = null;
    if (!_started || _droneCanMode || _subscription == null) return;
    if (!_hasProvenFix) return;
    _stallTimer = Timer(_stallProbeDelay(), _onStallDetected);
  }

  /// Delay after which the next stall is detected, given how many silent
  /// recoveries already happened ([_stallRecoveries]).
  ///
  /// With no recoveries yet this is [stallTimeout] after the last delivered
  /// fix. Every silent recovery that still yields no fix doubles the wait —
  /// capped at [_stallRecoveryCap] — so a genuinely dead OS stream is probed
  /// at most every [_stallRecoveryCap] in the worst case, while a stream that
  /// comes back (even much later) is picked up as soon as it delivers again.
  Duration _stallProbeDelay() {
    // Bounded exponent keeps the shift well inside 64-bit range even if a
    // stream stays dead for an entire (very long) session.
    final steps = _stallRecoveries > 8 ? 8 : _stallRecoveries;
    final delay = stallTimeout * (1 << steps);
    return delay > _stallRecoveryCap ? _stallRecoveryCap : delay;
  }

  void _disarmStallWatchdog() {
    _stallTimer?.cancel();
    _stallTimer = null;
  }

  /// Human-readable form of [duration] for logs/diagnostics. A duration below
  /// one second prints as ms, where `inSeconds` would misleadingly print "0 s".
  static String _durationLabel(Duration duration) {
    if (duration.inSeconds < 1) {
      return '${duration.inMilliseconds} ms';
    }
    return '${duration.inSeconds} s';
  }

  /// Fired by the stall watchdog when no position has arrived for the current
  /// probe delay even though the stream was delivering before. The OS stream
  /// has gone silently dead (no error event), so force a clean restart of the
  /// native subscription — exactly like a mode switch — to recover the fix
  /// without the pilot having to touch another GPS app.
  void _onStallDetected() {
    if (!_started || _droneCanMode) return;
    if (!_hasProvenFix) return;
    // The watchdog waited the full backed-off probe delay before firing;
    // capture it (before incrementing) so diagnostics report the true silent
    // period instead of the base stall timeout.
    final delay = _durationLabel(_stallProbeDelay());
    _stallRecoveries++;
    debugPrint(
      '[GeolocatorStream] No position for $delay while '
      'a fix is expected; re-subscribing to recover a stalled stream '
      '(recovery #$_stallRecoveries).',
    );
    Sentry.addBreadcrumb(
      Breadcrumb(
        message:
            'geolocator: STALL - no position for $delay '
            'while a fix is expected; re-subscribing to recover '
            '(recovery #$_stallRecoveries)',
        category: 'gps',
        level: SentryLevel.warning,
      ),
    );
    // Re-subscribing re-arms the watchdog (see [_subscribe]): if the OS
    // stream is still dead after this recovery, another probe follows with a
    // longer delay — the aircraft does not freeze after a single attempt.
    _startWithMode();
  }
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
