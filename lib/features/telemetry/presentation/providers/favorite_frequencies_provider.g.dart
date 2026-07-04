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
    r'cdca1afa802213993b6314e12078e8f2de45c030';

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
