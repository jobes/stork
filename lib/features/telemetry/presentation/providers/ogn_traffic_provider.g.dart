// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ogn_traffic_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ognAprsService)
final ognAprsServiceProvider = OgnAprsServiceProvider._();

final class OgnAprsServiceProvider
    extends $FunctionalProvider<OgnAprsService, OgnAprsService, OgnAprsService>
    with $Provider<OgnAprsService> {
  OgnAprsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ognAprsServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ognAprsServiceHash();

  @$internal
  @override
  $ProviderElement<OgnAprsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OgnAprsService create(Ref ref) {
    return ognAprsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OgnAprsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OgnAprsService>(value),
    );
  }
}

String _$ognAprsServiceHash() => r'68fadd04beb97d7de3673b2cf1a2ba2f2dd5f9a7';

@ProviderFor(OgnTraffic)
final ognTrafficProvider = OgnTrafficProvider._();

final class OgnTrafficProvider
    extends $NotifierProvider<OgnTraffic, List<OgnTrafficAircraft>> {
  OgnTrafficProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ognTrafficProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ognTrafficHash();

  @$internal
  @override
  OgnTraffic create() => OgnTraffic();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OgnTrafficAircraft> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OgnTrafficAircraft>>(value),
    );
  }
}

String _$ognTrafficHash() => r'ca44631771a87f76f2be8af8688ee09a43efda56';

abstract class _$OgnTraffic extends $Notifier<List<OgnTrafficAircraft>> {
  List<OgnTrafficAircraft> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<OgnTrafficAircraft>, List<OgnTrafficAircraft>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<OgnTrafficAircraft>, List<OgnTrafficAircraft>>,
              List<OgnTrafficAircraft>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FilteredOgnTraffic)
final filteredOgnTrafficProvider = FilteredOgnTrafficProvider._();

final class FilteredOgnTrafficProvider
    extends $NotifierProvider<FilteredOgnTraffic, List<OgnTrafficAircraft>> {
  FilteredOgnTrafficProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredOgnTrafficProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredOgnTrafficHash();

  @$internal
  @override
  FilteredOgnTraffic create() => FilteredOgnTraffic();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OgnTrafficAircraft> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OgnTrafficAircraft>>(value),
    );
  }
}

String _$filteredOgnTrafficHash() =>
    r'3981f49c05ede9fcb4d050873938ea0b6c98c7c3';

abstract class _$FilteredOgnTraffic
    extends $Notifier<List<OgnTrafficAircraft>> {
  List<OgnTrafficAircraft> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<OgnTrafficAircraft>, List<OgnTrafficAircraft>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<OgnTrafficAircraft>, List<OgnTrafficAircraft>>,
              List<OgnTrafficAircraft>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(activeCollisionAlert)
final activeCollisionAlertProvider = ActiveCollisionAlertProvider._();

final class ActiveCollisionAlertProvider
    extends
        $FunctionalProvider<
          OgnTrafficAircraft?,
          OgnTrafficAircraft?,
          OgnTrafficAircraft?
        >
    with $Provider<OgnTrafficAircraft?> {
  ActiveCollisionAlertProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCollisionAlertProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCollisionAlertHash();

  @$internal
  @override
  $ProviderElement<OgnTrafficAircraft?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OgnTrafficAircraft? create(Ref ref) {
    return activeCollisionAlert(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OgnTrafficAircraft? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OgnTrafficAircraft?>(value),
    );
  }
}

String _$activeCollisionAlertHash() =>
    r'3bd9f6073dcec3808466704b50af27733f6c5104';
