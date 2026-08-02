// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentLocation)
final currentLocationProvider = CurrentLocationProvider._();

final class CurrentLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<Geographic?>,
          Geographic?,
          FutureOr<Geographic?>
        >
    with $FutureModifier<Geographic?>, $FutureProvider<Geographic?> {
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

/// Stream of user positions. The returned [altitude] is in Mean Sea Level (MSL) datum
/// (configured via AndroidSettings.useMSLAltitude on Android).

@ProviderFor(positionStream)
final positionStreamProvider = PositionStreamProvider._();

/// Stream of user positions. The returned [altitude] is in Mean Sea Level (MSL) datum
/// (configured via AndroidSettings.useMSLAltitude on Android).

final class PositionStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<
            ({
              double altitude,
              double groundSpeed,
              double heading,
              double horizontalAccuracy,
              double lat,
              double lon,
              DateTime? timestamp,
              double verticalAccuracy,
            })
          >,
          ({
            double altitude,
            double groundSpeed,
            double heading,
            double horizontalAccuracy,
            double lat,
            double lon,
            DateTime? timestamp,
            double verticalAccuracy,
          }),
          Stream<
            ({
              double altitude,
              double groundSpeed,
              double heading,
              double horizontalAccuracy,
              double lat,
              double lon,
              DateTime? timestamp,
              double verticalAccuracy,
            })
          >
        >
    with
        $FutureModifier<
          ({
            double altitude,
            double groundSpeed,
            double heading,
            double horizontalAccuracy,
            double lat,
            double lon,
            DateTime? timestamp,
            double verticalAccuracy,
          })
        >,
        $StreamProvider<
          ({
            double altitude,
            double groundSpeed,
            double heading,
            double horizontalAccuracy,
            double lat,
            double lon,
            DateTime? timestamp,
            double verticalAccuracy,
          })
        > {
  /// Stream of user positions. The returned [altitude] is in Mean Sea Level (MSL) datum
  /// (configured via AndroidSettings.useMSLAltitude on Android).
  PositionStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'positionStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$positionStreamHash();

  @$internal
  @override
  $StreamProviderElement<
    ({
      double altitude,
      double groundSpeed,
      double heading,
      double horizontalAccuracy,
      double lat,
      double lon,
      DateTime? timestamp,
      double verticalAccuracy,
    })
  >
  $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<
    ({
      double altitude,
      double groundSpeed,
      double heading,
      double horizontalAccuracy,
      double lat,
      double lon,
      DateTime? timestamp,
      double verticalAccuracy,
    })
  >
  create(Ref ref) {
    return positionStream(ref);
  }
}

String _$positionStreamHash() => r'2611525349d8ee2601c7a5f4bebca30d0fa1aeb2';

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
  void runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
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
