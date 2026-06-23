// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notams_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notamService)
final notamServiceProvider = NotamServiceProvider._();

final class NotamServiceProvider
    extends $FunctionalProvider<NotamService, NotamService, NotamService>
    with $Provider<NotamService> {
  NotamServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notamServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notamServiceHash();

  @$internal
  @override
  $ProviderElement<NotamService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotamService create(Ref ref) {
    return notamService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotamService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotamService>(value),
    );
  }
}

String _$notamServiceHash() => r'212faa531e8f72a95075cdb6bd9b5675e2c34e44';

@ProviderFor(currentFir)
final currentFirProvider = CurrentFirProvider._();

final class CurrentFirProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  CurrentFirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentFirProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentFirHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentFir(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentFirHash() => r'f069ae5e8d50d7d92f2b789755b2d846d9fc8394';

@ProviderFor(routePoints)
final routePointsProvider = RoutePointsProvider._();

final class RoutePointsProvider
    extends
        $FunctionalProvider<
          List<Geographic>,
          List<Geographic>,
          List<Geographic>
        >
    with $Provider<List<Geographic>> {
  RoutePointsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routePointsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routePointsHash();

  @$internal
  @override
  $ProviderElement<List<Geographic>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Geographic> create(Ref ref) {
    return routePoints(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Geographic> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Geographic>>(value),
    );
  }
}

String _$routePointsHash() => r'0760f6d513e4735580171eebc126239f823e19c4';

@ProviderFor(Notams)
final notamsProvider = NotamsProvider._();

final class NotamsProvider extends $AsyncNotifierProvider<Notams, List<Notam>> {
  NotamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notamsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notamsHash();

  @$internal
  @override
  Notams create() => Notams();
}

String _$notamsHash() => r'b0f01711c9404bf540c56398b3cafb5383dbdc73';

abstract class _$Notams extends $AsyncNotifier<List<Notam>> {
  FutureOr<List<Notam>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Notam>>, List<Notam>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Notam>>, List<Notam>>,
              AsyncValue<List<Notam>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
