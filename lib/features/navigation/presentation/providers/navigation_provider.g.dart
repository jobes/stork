// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(navigationAutoAdvance)
final navigationAutoAdvanceProvider = NavigationAutoAdvanceProvider._();

final class NavigationAutoAdvanceProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  NavigationAutoAdvanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationAutoAdvanceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationAutoAdvanceHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return navigationAutoAdvance(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$navigationAutoAdvanceHash() =>
    r'edb75374963f82e46f402e7417b241b6fb5a53de';

@ProviderFor(NavigationNotifier)
final navigationProvider = NavigationNotifierProvider._();

final class NavigationNotifierProvider
    extends $AsyncNotifierProvider<NavigationNotifier, NavigationState> {
  NavigationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationNotifierHash();

  @$internal
  @override
  NavigationNotifier create() => NavigationNotifier();
}

String _$navigationNotifierHash() =>
    r'4ed8bcb337f71e651e3bc182204dc3c7b1a2c238';

abstract class _$NavigationNotifier extends $AsyncNotifier<NavigationState> {
  FutureOr<NavigationState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NavigationState>, NavigationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NavigationState>, NavigationState>,
              AsyncValue<NavigationState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
