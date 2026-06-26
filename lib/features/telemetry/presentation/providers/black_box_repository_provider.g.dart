// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'black_box_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(blackBoxDatabase)
final blackBoxDatabaseProvider = BlackBoxDatabaseProvider._();

final class BlackBoxDatabaseProvider
    extends
        $FunctionalProvider<
          BlackBoxDatabase,
          BlackBoxDatabase,
          BlackBoxDatabase
        >
    with $Provider<BlackBoxDatabase> {
  BlackBoxDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blackBoxDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blackBoxDatabaseHash();

  @$internal
  @override
  $ProviderElement<BlackBoxDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BlackBoxDatabase create(Ref ref) {
    return blackBoxDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlackBoxDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlackBoxDatabase>(value),
    );
  }
}

String _$blackBoxDatabaseHash() => r'5eabc51667198b721aad4e5efd67006d34f6f2f5';

@ProviderFor(blackBoxRepository)
final blackBoxRepositoryProvider = BlackBoxRepositoryProvider._();

final class BlackBoxRepositoryProvider
    extends
        $FunctionalProvider<
          BlackBoxRepository,
          BlackBoxRepository,
          BlackBoxRepository
        >
    with $Provider<BlackBoxRepository> {
  BlackBoxRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blackBoxRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blackBoxRepositoryHash();

  @$internal
  @override
  $ProviderElement<BlackBoxRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BlackBoxRepository create(Ref ref) {
    return blackBoxRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlackBoxRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlackBoxRepository>(value),
    );
  }
}

String _$blackBoxRepositoryHash() =>
    r'88490bdc1656ad82a53011d213e27489fd7c2718';
