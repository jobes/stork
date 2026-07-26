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

String _$ognTrafficHash() => r'b22f5c6034039fc0d18b67869337803082aee7a9';

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
