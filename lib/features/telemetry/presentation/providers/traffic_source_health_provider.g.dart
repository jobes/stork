// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traffic_source_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches OGN, PureTrack and GDL90 so the map can report that traffic data is
/// missing without depending on the traffic list itself.

@ProviderFor(TrafficSourceHealth)
final trafficSourceHealthProvider = TrafficSourceHealthProvider._();

/// Watches OGN, PureTrack and GDL90 so the map can report that traffic data is
/// missing without depending on the traffic list itself.
final class TrafficSourceHealthProvider
    extends $NotifierProvider<TrafficSourceHealth, TrafficSourceHealthState> {
  /// Watches OGN, PureTrack and GDL90 so the map can report that traffic data is
  /// missing without depending on the traffic list itself.
  TrafficSourceHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trafficSourceHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trafficSourceHealthHash();

  @$internal
  @override
  TrafficSourceHealth create() => TrafficSourceHealth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrafficSourceHealthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrafficSourceHealthState>(value),
    );
  }
}

String _$trafficSourceHealthHash() =>
    r'725226a4e3e539eeb78bc6e2938674ea4c95fdf7';

/// Watches OGN, PureTrack and GDL90 so the map can report that traffic data is
/// missing without depending on the traffic list itself.

abstract class _$TrafficSourceHealth
    extends $Notifier<TrafficSourceHealthState> {
  TrafficSourceHealthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<TrafficSourceHealthState, TrafficSourceHealthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrafficSourceHealthState, TrafficSourceHealthState>,
              TrafficSourceHealthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
