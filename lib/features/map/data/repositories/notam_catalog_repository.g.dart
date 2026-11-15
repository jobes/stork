// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notam_catalog_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notamCatalogRepository)
final notamCatalogRepositoryProvider = NotamCatalogRepositoryProvider._();

final class NotamCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          NotamCatalogRepository,
          NotamCatalogRepository,
          NotamCatalogRepository
        >
    with $Provider<NotamCatalogRepository> {
  NotamCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notamCatalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notamCatalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotamCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotamCatalogRepository create(Ref ref) {
    return notamCatalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotamCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotamCatalogRepository>(value),
    );
  }
}

String _$notamCatalogRepositoryHash() =>
    r'079a8665a61c50acbbbc21076791d9659c6db266';
