// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puretrack_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pureTrackAuthService)
final pureTrackAuthServiceProvider = PureTrackAuthServiceProvider._();

final class PureTrackAuthServiceProvider
    extends
        $FunctionalProvider<
          PureTrackAuthService,
          PureTrackAuthService,
          PureTrackAuthService
        >
    with $Provider<PureTrackAuthService> {
  PureTrackAuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pureTrackAuthServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pureTrackAuthServiceHash();

  @$internal
  @override
  $ProviderElement<PureTrackAuthService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PureTrackAuthService create(Ref ref) {
    return pureTrackAuthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PureTrackAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PureTrackAuthService>(value),
    );
  }
}

String _$pureTrackAuthServiceHash() =>
    r'080deed1295d11a8c49d859f13dc4be43e3f3f48';

@ProviderFor(pureTrackStreamService)
final pureTrackStreamServiceProvider = PureTrackStreamServiceProvider._();

final class PureTrackStreamServiceProvider
    extends
        $FunctionalProvider<
          PureTrackStreamService,
          PureTrackStreamService,
          PureTrackStreamService
        >
    with $Provider<PureTrackStreamService> {
  PureTrackStreamServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pureTrackStreamServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pureTrackStreamServiceHash();

  @$internal
  @override
  $ProviderElement<PureTrackStreamService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PureTrackStreamService create(Ref ref) {
    return pureTrackStreamService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PureTrackStreamService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PureTrackStreamService>(value),
    );
  }
}

String _$pureTrackStreamServiceHash() =>
    r'bfd18b5518b94e0fb6afc2b4a226d7f4c4cfa314';

@ProviderFor(PureTrackNotifier)
final pureTrackProvider = PureTrackNotifierProvider._();

final class PureTrackNotifierProvider
    extends $NotifierProvider<PureTrackNotifier, PureTrackAuthState> {
  PureTrackNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pureTrackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pureTrackNotifierHash();

  @$internal
  @override
  PureTrackNotifier create() => PureTrackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PureTrackAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PureTrackAuthState>(value),
    );
  }
}

String _$pureTrackNotifierHash() => r'de51e44267d22370da91376622ebd8979bbcc145';

abstract class _$PureTrackNotifier extends $Notifier<PureTrackAuthState> {
  PureTrackAuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PureTrackAuthState, PureTrackAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PureTrackAuthState, PureTrackAuthState>,
              PureTrackAuthState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
