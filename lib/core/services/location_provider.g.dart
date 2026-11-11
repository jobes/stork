// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Gets a single position fix from the device.

@ProviderFor(currentLocation)
final currentLocationProvider = CurrentLocationProvider._();

/// Gets a single position fix from the device.

final class CurrentLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<Geographic?>,
          Geographic?,
          FutureOr<Geographic?>
        >
    with $FutureModifier<Geographic?>, $FutureProvider<Geographic?> {
  /// Gets a single position fix from the device.
  CurrentLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLocationHash();

  @$internal
  @override
  $FutureProviderElement<Geographic?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Geographic?> create(Ref ref) {
    return currentLocation(ref);
  }
}

String _$currentLocationHash() => r'cb79119672f4cb95e04b9d102ca104793b740642';

/// A single, persistent stream of raw OS positions.
///
/// The native OS subscription is started explicitly (see [start]) the first
/// time the map needs a fix, and then kept alive for the whole app session.
/// Ordinary provider updates leave the native subscription intact: re-creating
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

@ProviderFor(GeolocatorStream)
final geolocatorStreamProvider = GeolocatorStreamProvider._();

/// A single, persistent stream of raw OS positions.
///
/// The native OS subscription is started explicitly (see [start]) the first
/// time the map needs a fix, and then kept alive for the whole app session.
/// Ordinary provider updates leave the native subscription intact: re-creating
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
final class GeolocatorStreamProvider
    extends
        $NotifierProvider<
          GeolocatorStream,
          ({GeolocatorStreamStatus status, Stream<geo.Position> stream})
        > {
  /// A single, persistent stream of raw OS positions.
  ///
  /// The native OS subscription is started explicitly (see [start]) the first
  /// time the map needs a fix, and then kept alive for the whole app session.
  /// Ordinary provider updates leave the native subscription intact: re-creating
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
  GeolocatorStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geolocatorStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geolocatorStreamHash();

  @$internal
  @override
  GeolocatorStream create() => GeolocatorStream();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({GeolocatorStreamStatus status, Stream<geo.Position> stream}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({GeolocatorStreamStatus status, Stream<geo.Position> stream})
          >(value),
    );
  }
}

String _$geolocatorStreamHash() => r'f9749e16d95eafe750b443545413e6e0f550fec2';

/// A single, persistent stream of raw OS positions.
///
/// The native OS subscription is started explicitly (see [start]) the first
/// time the map needs a fix, and then kept alive for the whole app session.
/// Ordinary provider updates leave the native subscription intact: re-creating
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

abstract class _$GeolocatorStream
    extends
        $Notifier<
          ({GeolocatorStreamStatus status, Stream<geo.Position> stream})
        > {
  ({GeolocatorStreamStatus status, Stream<geo.Position> stream}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({GeolocatorStreamStatus status, Stream<geo.Position> stream}),
              ({GeolocatorStreamStatus status, Stream<geo.Position> stream})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({GeolocatorStreamStatus status, Stream<geo.Position> stream}),
                ({GeolocatorStreamStatus status, Stream<geo.Position> stream})
              >,
              ({GeolocatorStreamStatus status, Stream<geo.Position> stream}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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

@ProviderFor(CompassOrientationOffset)
final compassOrientationOffsetProvider = CompassOrientationOffsetProvider._();

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
final class CompassOrientationOffsetProvider
    extends $NotifierProvider<CompassOrientationOffset, double> {
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
  CompassOrientationOffsetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compassOrientationOffsetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compassOrientationOffsetHash();

  @$internal
  @override
  CompassOrientationOffset create() => CompassOrientationOffset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$compassOrientationOffsetHash() =>
    r'c8cd2a98755e687667937b2dd7f921ce441570e9';

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

abstract class _$CompassOrientationOffset extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(compassStream)
final compassStreamProvider = CompassStreamProvider._();

final class CompassStreamProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, Stream<double?>>
    with $FutureModifier<double?>, $StreamProvider<double?> {
  CompassStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compassStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compassStreamHash();

  @$internal
  @override
  $StreamProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double?> create(Ref ref) {
    return compassStream(ref);
  }
}

String _$compassStreamHash() => r'4f92ed651949d5901437ab22e0ff2b54d6e1b0cd';
