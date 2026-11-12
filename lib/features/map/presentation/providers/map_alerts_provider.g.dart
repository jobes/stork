// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_alerts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Aggregates active health signals in priority order.
///
/// Each signal is owned by its own provider ([GpsHealth],
/// [TelemetryLinkHealth], [TrafficSourceHealth], [AltitudeHealth] and the
/// map-specific ones). This notifier only composes them, tracks how long each
/// condition has been active and drives the shared 1 Hz ticker, so there is
/// exactly one periodic timer for the whole indicator.

@ProviderFor(MapAlerts)
final mapAlertsProvider = MapAlertsProvider._();

/// Aggregates active health signals in priority order.
///
/// Each signal is owned by its own provider ([GpsHealth],
/// [TelemetryLinkHealth], [TrafficSourceHealth], [AltitudeHealth] and the
/// map-specific ones). This notifier only composes them, tracks how long each
/// condition has been active and drives the shared 1 Hz ticker, so there is
/// exactly one periodic timer for the whole indicator.
final class MapAlertsProvider
    extends $NotifierProvider<MapAlerts, List<MapAlert>> {
  /// Aggregates active health signals in priority order.
  ///
  /// Each signal is owned by its own provider ([GpsHealth],
  /// [TelemetryLinkHealth], [TrafficSourceHealth], [AltitudeHealth] and the
  /// map-specific ones). This notifier only composes them, tracks how long each
  /// condition has been active and drives the shared 1 Hz ticker, so there is
  /// exactly one periodic timer for the whole indicator.
  MapAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapAlertsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapAlertsHash();

  @$internal
  @override
  MapAlerts create() => MapAlerts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MapAlert> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MapAlert>>(value),
    );
  }
}

String _$mapAlertsHash() => r'bad1718fa6a229df5aa552ecf2306f2fc7411259';

/// Aggregates active health signals in priority order.
///
/// Each signal is owned by its own provider ([GpsHealth],
/// [TelemetryLinkHealth], [TrafficSourceHealth], [AltitudeHealth] and the
/// map-specific ones). This notifier only composes them, tracks how long each
/// condition has been active and drives the shared 1 Hz ticker, so there is
/// exactly one periodic timer for the whole indicator.

abstract class _$MapAlerts extends $Notifier<List<MapAlert>> {
  List<MapAlert> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<MapAlert>, List<MapAlert>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<MapAlert>, List<MapAlert>>,
              List<MapAlert>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
