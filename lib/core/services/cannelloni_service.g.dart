// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cannelloni_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CannelloniService)
final cannelloniServiceProvider = CannelloniServiceProvider._();

final class CannelloniServiceProvider
    extends $NotifierProvider<CannelloniService, void> {
  CannelloniServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cannelloniServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cannelloniServiceHash();

  @$internal
  @override
  CannelloniService create() => CannelloniService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$cannelloniServiceHash() => r'0948c64e09e8fe9b322d89bf1ed6e2ea1c9bf143';

abstract class _$CannelloniService extends $Notifier<void> {
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
