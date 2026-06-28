// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pilot_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pilotRepository)
final pilotRepositoryProvider = PilotRepositoryProvider._();

final class PilotRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PilotRepository>,
          PilotRepository,
          FutureOr<PilotRepository>
        >
    with $FutureModifier<PilotRepository>, $FutureProvider<PilotRepository> {
  PilotRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pilotRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pilotRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<PilotRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PilotRepository> create(Ref ref) {
    return pilotRepository(ref);
  }
}

String _$pilotRepositoryHash() => r'593b01f89da938f3d0b48306e5813f3f9fc3882c';
