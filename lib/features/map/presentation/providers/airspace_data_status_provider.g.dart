// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airspace_data_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks which FIRs currently have no fresh AUP/UUP data.
///
/// The real-time airspace controller reports every fetch result here. Keeping
/// this in a separate provider lets the map status indicator react to a failed
/// download without changing the activity state consumed by the map layers.

@ProviderFor(AirspaceDataStatus)
final airspaceDataStatusProvider = AirspaceDataStatusProvider._();

/// Tracks which FIRs currently have no fresh AUP/UUP data.
///
/// The real-time airspace controller reports every fetch result here. Keeping
/// this in a separate provider lets the map status indicator react to a failed
/// download without changing the activity state consumed by the map layers.
final class AirspaceDataStatusProvider
    extends $NotifierProvider<AirspaceDataStatus, AirspaceDataStatusState> {
  /// Tracks which FIRs currently have no fresh AUP/UUP data.
  ///
  /// The real-time airspace controller reports every fetch result here. Keeping
  /// this in a separate provider lets the map status indicator react to a failed
  /// download without changing the activity state consumed by the map layers.
  AirspaceDataStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'airspaceDataStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$airspaceDataStatusHash();

  @$internal
  @override
  AirspaceDataStatus create() => AirspaceDataStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AirspaceDataStatusState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AirspaceDataStatusState>(value),
    );
  }
}

String _$airspaceDataStatusHash() =>
    r'2640364f3a753122ea23fe2831ca9e9518dae0e6';

/// Tracks which FIRs currently have no fresh AUP/UUP data.
///
/// The real-time airspace controller reports every fetch result here. Keeping
/// this in a separate provider lets the map status indicator react to a failed
/// download without changing the activity state consumed by the map layers.

abstract class _$AirspaceDataStatus extends $Notifier<AirspaceDataStatusState> {
  AirspaceDataStatusState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AirspaceDataStatusState, AirspaceDataStatusState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AirspaceDataStatusState, AirspaceDataStatusState>,
              AirspaceDataStatusState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
