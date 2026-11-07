// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cannelloni_service_io.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CannelloniService)
final cannelloniServiceProvider = CannelloniServiceProvider._();

final class CannelloniServiceProvider
    extends $NotifierProvider<CannelloniService, bool> {
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
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cannelloniServiceHash() => r'c769a94c0c7b4993486350bd00f45b36ac2ffae0';

abstract class _$CannelloniService extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
