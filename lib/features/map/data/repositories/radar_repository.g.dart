// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(radarRepository)
final radarRepositoryProvider = RadarRepositoryProvider._();

final class RadarRepositoryProvider
    extends
        $FunctionalProvider<RadarRepository, RadarRepository, RadarRepository>
    with $Provider<RadarRepository> {
  RadarRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarRepositoryHash();

  @$internal
  @override
  $ProviderElement<RadarRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RadarRepository create(Ref ref) {
    return radarRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RadarRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RadarRepository>(value),
    );
  }
}

String _$radarRepositoryHash() => r'b3bbf651e9036e540fba1d54329979be83850866';
