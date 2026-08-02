// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traffic_provider.dart';

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

@ProviderFor(Traffic)
final trafficProvider = TrafficProvider._();

final class TrafficProvider
    extends $NotifierProvider<Traffic, List<TrafficAircraft>> {
  TrafficProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficHash();

  @$internal
  @override
  Traffic create() => Traffic();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TrafficAircraft> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TrafficAircraft>>(value),
    );
  }
}

String _$trafficHash() => r'1a695f4747b8f0362c0fa28c40f8cd3430caa13c';

abstract class _$Traffic extends $Notifier<List<TrafficAircraft>> {
  List<TrafficAircraft> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<TrafficAircraft>, List<TrafficAircraft>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<TrafficAircraft>, List<TrafficAircraft>>,
              List<TrafficAircraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FilteredTraffic)
final filteredTrafficProvider = FilteredTrafficProvider._();

final class FilteredTrafficProvider
    extends $NotifierProvider<FilteredTraffic, List<TrafficAircraft>> {
  FilteredTrafficProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredTrafficProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredTrafficHash();

  @$internal
  @override
  FilteredTraffic create() => FilteredTraffic();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TrafficAircraft> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TrafficAircraft>>(value),
    );
  }
}

String _$filteredTrafficHash() => r'a267bca2687944073da063ca6810111ee7ed43b0';

abstract class _$FilteredTraffic extends $Notifier<List<TrafficAircraft>> {
  List<TrafficAircraft> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<TrafficAircraft>, List<TrafficAircraft>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<TrafficAircraft>, List<TrafficAircraft>>,
              List<TrafficAircraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(activeCollisionAlert)
final activeCollisionAlertProvider = ActiveCollisionAlertProvider._();

final class ActiveCollisionAlertProvider
    extends
        $FunctionalProvider<
          TrafficAircraft?,
          TrafficAircraft?,
          TrafficAircraft?
        >
    with $Provider<TrafficAircraft?> {
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
  $ProviderElement<TrafficAircraft?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrafficAircraft? create(Ref ref) {
    return activeCollisionAlert(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrafficAircraft? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrafficAircraft?>(value),
    );
  }
}

String _$activeCollisionAlertHash() =>
    r'4f7045ab8089fb7aa1af5dedf9ff12c8224b43fa';
