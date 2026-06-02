// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terrain_elevation_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(terrainElevationService)
final terrainElevationServiceProvider = TerrainElevationServiceProvider._();

final class TerrainElevationServiceProvider
    extends
        $FunctionalProvider<
          TerrainElevationService,
          TerrainElevationService,
          TerrainElevationService
        >
    with $Provider<TerrainElevationService> {
  TerrainElevationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terrainElevationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terrainElevationServiceHash();

  @$internal
  @override
  $ProviderElement<TerrainElevationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TerrainElevationService create(Ref ref) {
    return terrainElevationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerrainElevationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerrainElevationService>(value),
    );
  }
}

String _$terrainElevationServiceHash() =>
    r'48c64aa7802c1134aeb7e1fe1efa878c2be03d5b';
