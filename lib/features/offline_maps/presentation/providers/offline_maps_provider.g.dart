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
    r'f20cc14a7bf0a28655afeaff136e150723ec03f4';

abstract class _$OfflineMapsNotifier extends $Notifier<OfflineMapsState> {
  OfflineMapsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OfflineMapsState, OfflineMapsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OfflineMapsState, OfflineMapsState>,
              OfflineMapsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
