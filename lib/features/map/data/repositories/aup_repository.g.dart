// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aup_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aupRepository)
final aupRepositoryProvider = AupRepositoryProvider._();

final class AupRepositoryProvider
    extends $FunctionalProvider<AupRepository, AupRepository, AupRepository>
    with $Provider<AupRepository> {
  AupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aupRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aupRepositoryHash();

  @$internal
  @override
  $ProviderElement<AupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AupRepository create(Ref ref) {
    return aupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AupRepository>(value),
    );
  }
}

String _$aupRepositoryHash() => r'ad84db108469c85cd91ac3d19b5860c2dd1667d7';
