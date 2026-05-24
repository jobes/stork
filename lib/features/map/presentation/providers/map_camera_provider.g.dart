// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_camera_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MapCamera)
final mapCameraProvider = MapCameraProvider._();

final class MapCameraProvider extends $NotifierProvider<MapCamera, void> {
  MapCameraProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapCameraProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapCameraHash();

  @$internal
  @override
  MapCamera create() => MapCamera();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$mapCameraHash() => r'ea2c12a3014d0cdf7f3189865d54e0c3077900ed';

abstract class _$MapCamera extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
