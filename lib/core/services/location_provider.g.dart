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

@ProviderFor(positionStream)
final positionStreamProvider = PositionStreamProvider._();

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
            double verticalAccuracy,
          })
        > {
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
      double verticalAccuracy,
    })
  >
  create(Ref ref) {
    return positionStream(ref);
  }
}

String _$positionStreamHash() => r'7937b606f5ebac684c1421d570659a8cc8b7e158';

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
        isAutoDispose: true,
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

String _$compassStreamHash() => r'62b8dd0ec3d4061c6fc519496cb5fb2638274668';
