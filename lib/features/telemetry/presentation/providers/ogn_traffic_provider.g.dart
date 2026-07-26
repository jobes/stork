// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ogn_traffic_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$ognTrafficHash() => r'44eec9dc073a2c1a9ef614d331165810d063fdec';

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
