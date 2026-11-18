// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(navigationRepository)
final navigationRepositoryProvider = NavigationRepositoryProvider._();

final class NavigationRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<NavigationRepository>,
          NavigationRepository,
          FutureOr<NavigationRepository>
        >
    with
        $FutureModifier<NavigationRepository>,
        $FutureProvider<NavigationRepository> {
  NavigationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<NavigationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NavigationRepository> create(Ref ref) {
    return navigationRepository(ref);
  }
}

String _$navigationRepositoryHash() =>
    r'02e71f2bb341f9c27bc698fe8af09ffe9ee01edd';
