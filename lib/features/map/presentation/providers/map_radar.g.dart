// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_radar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapRadar)
final mapRadarProvider = MapRadarProvider._();

final class MapRadarProvider
    extends $FunctionalProvider<MapRadar, MapRadar, MapRadar>
    with $Provider<MapRadar> {
  MapRadarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapRadarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapRadarHash();

  @$internal
  @override
  $ProviderElement<MapRadar> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapRadar create(Ref ref) {
    return mapRadar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapRadar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapRadar>(value),
    );
  }
}

String _$mapRadarHash() => r'45baf7cb21159feaca620ea07bf779c9e85971e0';
