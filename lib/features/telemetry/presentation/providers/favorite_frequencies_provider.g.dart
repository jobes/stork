// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_frequencies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoriteFrequencies)
final favoriteFrequenciesProvider = FavoriteFrequenciesProvider._();

final class FavoriteFrequenciesProvider
    extends
        $AsyncNotifierProvider<FavoriteFrequencies, List<FavoriteFrequency>> {
  FavoriteFrequenciesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteFrequenciesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteFrequenciesHash();

  @$internal
  @override
  FavoriteFrequencies create() => FavoriteFrequencies();
}

String _$favoriteFrequenciesHash() =>
    r'8fc59d652552ced89c744907113eb5a04f18e31a';

abstract class _$FavoriteFrequencies
    extends $AsyncNotifier<List<FavoriteFrequency>> {
  FutureOr<List<FavoriteFrequency>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<FavoriteFrequency>>,
              List<FavoriteFrequency>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FavoriteFrequency>>,
                List<FavoriteFrequency>
              >,
              AsyncValue<List<FavoriteFrequency>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
