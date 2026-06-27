// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aircraft_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aircraftRepository)
final aircraftRepositoryProvider = AircraftRepositoryProvider._();

final class AircraftRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<AircraftRepository>,
          AircraftRepository,
          FutureOr<AircraftRepository>
        >
    with
        $FutureModifier<AircraftRepository>,
        $FutureProvider<AircraftRepository> {
  AircraftRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aircraftRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aircraftRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<AircraftRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AircraftRepository> create(Ref ref) {
    return aircraftRepository(ref);
  }
}

String _$aircraftRepositoryHash() =>
    r'86229eb085fed9fb08cc17677d5315b860ad4def';
