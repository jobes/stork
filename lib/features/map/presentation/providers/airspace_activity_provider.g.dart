// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airspace_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the loaded AUP/UUP airspace activity map
/// (`Map<String, AupAirspaceActivity>` keyed by openAIP airspace id).
///
/// Subscribes to the telemetry aircraft position and automatically pre-fetches
/// active AUP/UUP data for every FIR whose boundary is within
/// [kAirspacePrefetchBufferMeters] of the aircraft. The position is evaluated
/// at most once per [kAirspaceEvaluationInterval]; when the interval elapses,
/// the data is fetched immediately for every nearby FIR.
///
/// The generated provider keeps the stable name `airspaceActivityProvider`
/// (see `name:` below); the notifier class itself uses the `*Controller`
/// suffix so it does not collide with the `AirspaceActivity` enum in the
/// domain layer.

@ProviderFor(AirspaceActivityController)
final airspaceActivityProvider = AirspaceActivityControllerProvider._();

/// Holds the loaded AUP/UUP airspace activity map
/// (`Map<String, AupAirspaceActivity>` keyed by openAIP airspace id).
///
/// Subscribes to the telemetry aircraft position and automatically pre-fetches
/// active AUP/UUP data for every FIR whose boundary is within
/// [kAirspacePrefetchBufferMeters] of the aircraft. The position is evaluated
/// at most once per [kAirspaceEvaluationInterval]; when the interval elapses,
/// the data is fetched immediately for every nearby FIR.
///
/// The generated provider keeps the stable name `airspaceActivityProvider`
/// (see `name:` below); the notifier class itself uses the `*Controller`
/// suffix so it does not collide with the `AirspaceActivity` enum in the
/// domain layer.
final class AirspaceActivityControllerProvider
    extends
        $NotifierProvider<
          AirspaceActivityController,
          Map<String, AupAirspaceActivity>
        > {
  /// Holds the loaded AUP/UUP airspace activity map
  /// (`Map<String, AupAirspaceActivity>` keyed by openAIP airspace id).
  ///
  /// Subscribes to the telemetry aircraft position and automatically pre-fetches
  /// active AUP/UUP data for every FIR whose boundary is within
  /// [kAirspacePrefetchBufferMeters] of the aircraft. The position is evaluated
  /// at most once per [kAirspaceEvaluationInterval]; when the interval elapses,
  /// the data is fetched immediately for every nearby FIR.
  ///
  /// The generated provider keeps the stable name `airspaceActivityProvider`
  /// (see `name:` below); the notifier class itself uses the `*Controller`
  /// suffix so it does not collide with the `AirspaceActivity` enum in the
  /// domain layer.
  AirspaceActivityControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'airspaceActivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$airspaceActivityControllerHash();

  @$internal
  @override
  AirspaceActivityController create() => AirspaceActivityController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, AupAirspaceActivity> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, AupAirspaceActivity>>(
        value,
      ),
    );
  }
}

String _$airspaceActivityControllerHash() =>
    r'5c7513de07ba68907c644e7c9c998eef4598622e';

/// Holds the loaded AUP/UUP airspace activity map
/// (`Map<String, AupAirspaceActivity>` keyed by openAIP airspace id).
///
/// Subscribes to the telemetry aircraft position and automatically pre-fetches
/// active AUP/UUP data for every FIR whose boundary is within
/// [kAirspacePrefetchBufferMeters] of the aircraft. The position is evaluated
/// at most once per [kAirspaceEvaluationInterval]; when the interval elapses,
/// the data is fetched immediately for every nearby FIR.
///
/// The generated provider keeps the stable name `airspaceActivityProvider`
/// (see `name:` below); the notifier class itself uses the `*Controller`
/// suffix so it does not collide with the `AirspaceActivity` enum in the
/// domain layer.

abstract class _$AirspaceActivityController
    extends $Notifier<Map<String, AupAirspaceActivity>> {
  Map<String, AupAirspaceActivity> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, AupAirspaceActivity>,
              Map<String, AupAirspaceActivity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, AupAirspaceActivity>,
                Map<String, AupAirspaceActivity>
              >,
              Map<String, AupAirspaceActivity>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
