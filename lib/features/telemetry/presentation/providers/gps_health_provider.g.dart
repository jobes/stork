// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the GPS pipeline: OS permission/services, the stream status, fix
/// age and DroneCAN fallback.
///
/// Time-based conditions are aged by [refresh], which the map alert notifier
/// calls from its single ticker, so the app keeps only one periodic timer.

@ProviderFor(GpsHealth)
final gpsHealthProvider = GpsHealthProvider._();

/// Watches the GPS pipeline: OS permission/services, the stream status, fix
/// age and DroneCAN fallback.
///
/// Time-based conditions are aged by [refresh], which the map alert notifier
/// calls from its single ticker, so the app keeps only one periodic timer.
final class GpsHealthProvider
    extends $NotifierProvider<GpsHealth, GpsHealthState> {
  /// Watches the GPS pipeline: OS permission/services, the stream status, fix
  /// age and DroneCAN fallback.
  ///
  /// Time-based conditions are aged by [refresh], which the map alert notifier
  /// calls from its single ticker, so the app keeps only one periodic timer.
  GpsHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gpsHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gpsHealthHash();

  @$internal
  @override
  GpsHealth create() => GpsHealth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GpsHealthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GpsHealthState>(value),
    );
  }
}

String _$gpsHealthHash() => r'2861c4065a95669492dbeda4a43136ef2ef08dd9';

/// Watches the GPS pipeline: OS permission/services, the stream status, fix
/// age and DroneCAN fallback.
///
/// Time-based conditions are aged by [refresh], which the map alert notifier
/// calls from its single ticker, so the app keeps only one periodic timer.

abstract class _$GpsHealth extends $Notifier<GpsHealthState> {
  GpsHealthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GpsHealthState, GpsHealthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GpsHealthState, GpsHealthState>,
              GpsHealthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
