// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoritesNotifier)
final favoritesProvider = FavoritesNotifierProvider._();

final class FavoritesNotifierProvider
    extends $AsyncNotifierProvider<FavoritesNotifier, List<FavoritePoint>> {
  FavoritesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesNotifierHash();

  @$internal
  @override
  FavoritesNotifier create() => FavoritesNotifier();
}

String _$favoritesNotifierHash() => r'8e0cb3e9e0c29c0449145cceba1aa209ff92bacb';

abstract class _$FavoritesNotifier extends $AsyncNotifier<List<FavoritePoint>> {
  FutureOr<List<FavoritePoint>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<FavoritePoint>>, List<FavoritePoint>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FavoritePoint>>, List<FavoritePoint>>,
              AsyncValue<List<FavoritePoint>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
