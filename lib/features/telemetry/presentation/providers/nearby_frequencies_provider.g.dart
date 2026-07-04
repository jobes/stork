// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_frequencies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NearbyFrequencies)
final nearbyFrequenciesProvider = NearbyFrequenciesProvider._();

final class NearbyFrequenciesProvider
    extends $AsyncNotifierProvider<NearbyFrequencies, NearbyFrequenciesState> {
  NearbyFrequenciesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyFrequenciesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyFrequenciesHash();

  @$internal
  @override
  NearbyFrequencies create() => NearbyFrequencies();
}

String _$nearbyFrequenciesHash() => r'40898211365983f293545d30bc2fb2b0b6dfb254';

abstract class _$NearbyFrequencies
    extends $AsyncNotifier<NearbyFrequenciesState> {
  FutureOr<NearbyFrequenciesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<NearbyFrequenciesState>, NearbyFrequenciesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NearbyFrequenciesState>,
                NearbyFrequenciesState
              >,
              AsyncValue<NearbyFrequenciesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
