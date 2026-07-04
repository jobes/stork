// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vhf_radio_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VhfRadioController)
final vhfRadioControllerProvider = VhfRadioControllerProvider._();

final class VhfRadioControllerProvider
    extends $NotifierProvider<VhfRadioController, void> {
  VhfRadioControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vhfRadioControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vhfRadioControllerHash();

  @$internal
  @override
  VhfRadioController create() => VhfRadioController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$vhfRadioControllerHash() =>
    r'104743f643600f0cadaef0ec18714ba7a7fd3987';

abstract class _$VhfRadioController extends $Notifier<void> {
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
