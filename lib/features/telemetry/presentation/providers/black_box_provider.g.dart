// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'black_box_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BlackBoxService)
final blackBoxServiceProvider = BlackBoxServiceProvider._();

final class BlackBoxServiceProvider
    extends $NotifierProvider<BlackBoxService, void> {
  BlackBoxServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blackBoxServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blackBoxServiceHash();

  @$internal
  @override
  BlackBoxService create() => BlackBoxService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$blackBoxServiceHash() => r'a0aeee2dbce4c23351517dcbf878bdaf983e8d47';

abstract class _$BlackBoxService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
