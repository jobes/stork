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
