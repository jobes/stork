// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_metadata_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapMetadataRepository)
final mapMetadataRepositoryProvider = MapMetadataRepositoryProvider._();

final class MapMetadataRepositoryProvider
    extends
        $FunctionalProvider<
          MapMetadataRepository,
          MapMetadataRepository,
          MapMetadataRepository
        >
    with $Provider<MapMetadataRepository> {
  MapMetadataRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapMetadataRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapMetadataRepositoryHash();

  @$internal
  @override
  $ProviderElement<MapMetadataRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MapMetadataRepository create(Ref ref) {
    return mapMetadataRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapMetadataRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapMetadataRepository>(value),
    );
  }
}

String _$mapMetadataRepositoryHash() =>
    r'446054cc72959d63d0f5ae922c2b201fffc1f565';
