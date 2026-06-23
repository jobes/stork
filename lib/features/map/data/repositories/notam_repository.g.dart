// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notam_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notamRepository)
final notamRepositoryProvider = NotamRepositoryProvider._();

final class NotamRepositoryProvider
    extends
        $FunctionalProvider<NotamRepository, NotamRepository, NotamRepository>
    with $Provider<NotamRepository> {
  NotamRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notamRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notamRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotamRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotamRepository create(Ref ref) {
    return notamRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotamRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotamRepository>(value),
    );
  }
}

String _$notamRepositoryHash() => r'deaa22e6a0dad0581b31771ed5b7e43866528ac5';
