// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'altitude_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the resolved altitude, terrain elevation and altitude-source
/// transitions.

@ProviderFor(AltitudeHealth)
final altitudeHealthProvider = AltitudeHealthProvider._();

/// Watches the resolved altitude, terrain elevation and altitude-source
/// transitions.
final class AltitudeHealthProvider
    extends $NotifierProvider<AltitudeHealth, AltitudeHealthState> {
  /// Watches the resolved altitude, terrain elevation and altitude-source
  /// transitions.
  AltitudeHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'altitudeHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$altitudeHealthHash();

  @$internal
  @override
  AltitudeHealth create() => AltitudeHealth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AltitudeHealthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AltitudeHealthState>(value),
    );
  }
}

String _$altitudeHealthHash() => r'da8b7847ec95037e10562239160548c1e04f2679';

/// Watches the resolved altitude, terrain elevation and altitude-source
/// transitions.

abstract class _$AltitudeHealth extends $Notifier<AltitudeHealthState> {
  AltitudeHealthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AltitudeHealthState, AltitudeHealthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AltitudeHealthState, AltitudeHealthState>,
              AltitudeHealthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
