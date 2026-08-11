// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_maps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OfflineMapsNotifier)
final offlineMapsProvider = OfflineMapsNotifierProvider._();

final class OfflineMapsNotifierProvider
    extends $NotifierProvider<OfflineMapsNotifier, OfflineMapsState> {
  OfflineMapsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineMapsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineMapsNotifierHash();

  @$internal
  @override
  OfflineMapsNotifier create() => OfflineMapsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineMapsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineMapsState>(value),
    );
  }
}

String _$offlineMapsNotifierHash() =>
    r'0a94e7c7b9d57539119b67c9723c3372d5d3cc8e';

abstract class _$OfflineMapsNotifier extends $Notifier<OfflineMapsState> {
  OfflineMapsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OfflineMapsState, OfflineMapsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OfflineMapsState, OfflineMapsState>,
              OfflineMapsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
