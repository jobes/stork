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

String _$ognTrafficHash() => r'aadd1e668d9a9b82813382fd0b783b5e9c971629';

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

@ProviderFor(filteredOgnTraffic)
final filteredOgnTrafficProvider = FilteredOgnTrafficProvider._();

final class FilteredOgnTrafficProvider
    extends
        $FunctionalProvider<
          List<OgnTrafficAircraft>,
          List<OgnTrafficAircraft>,
          List<OgnTrafficAircraft>
        >
    with $Provider<List<OgnTrafficAircraft>> {
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
  $ProviderElement<List<OgnTrafficAircraft>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<OgnTrafficAircraft> create(Ref ref) {
    return filteredOgnTraffic(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OgnTrafficAircraft> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OgnTrafficAircraft>>(value),
    );
  }
}

String _$filteredOgnTrafficHash() =>
    r'fd3cd50dddafd6df175a93da40e36522b5d486ce';
