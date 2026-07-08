// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vario_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VarioNotifier)
final varioProvider = VarioNotifierProvider._();

final class VarioNotifierProvider
    extends $NotifierProvider<VarioNotifier, VarioState> {
  VarioNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'varioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$varioNotifierHash();

  @$internal
  @override
  VarioNotifier create() => VarioNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VarioState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VarioState>(value),
    );
  }
}

String _$varioNotifierHash() => r'e9e77ef94207f0e8ab02e77672415bcf1361fb14';

abstract class _$VarioNotifier extends $Notifier<VarioState> {
  VarioState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VarioState, VarioState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VarioState, VarioState>,
              VarioState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
