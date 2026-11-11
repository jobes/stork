// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_link_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the DroneCAN telemetry link and reports a lost connection or frozen
/// data.
///
/// Time-based conditions are aged by [refresh], driven by the map alert
/// ticker.

@ProviderFor(TelemetryLinkHealth)
final telemetryLinkHealthProvider = TelemetryLinkHealthProvider._();

/// Watches the DroneCAN telemetry link and reports a lost connection or frozen
/// data.
///
/// Time-based conditions are aged by [refresh], driven by the map alert
/// ticker.
final class TelemetryLinkHealthProvider
    extends $NotifierProvider<TelemetryLinkHealth, TelemetryLinkHealthState> {
  /// Watches the DroneCAN telemetry link and reports a lost connection or frozen
  /// data.
  ///
  /// Time-based conditions are aged by [refresh], driven by the map alert
  /// ticker.
  TelemetryLinkHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'telemetryLinkHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$telemetryLinkHealthHash();

  @$internal
  @override
  TelemetryLinkHealth create() => TelemetryLinkHealth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryLinkHealthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryLinkHealthState>(value),
    );
  }
}

String _$telemetryLinkHealthHash() =>
    r'edf9980ae6be6dc2e665347c1c23346585371a3a';

/// Watches the DroneCAN telemetry link and reports a lost connection or frozen
/// data.
///
/// Time-based conditions are aged by [refresh], driven by the map alert
/// ticker.

abstract class _$TelemetryLinkHealth
    extends $Notifier<TelemetryLinkHealthState> {
  TelemetryLinkHealthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<TelemetryLinkHealthState, TelemetryLinkHealthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TelemetryLinkHealthState, TelemetryLinkHealthState>,
              TelemetryLinkHealthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
