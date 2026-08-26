// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TelemetryNotifier)
final telemetryProvider = TelemetryNotifierProvider._();

final class TelemetryNotifierProvider
    extends $NotifierProvider<TelemetryNotifier, TelemetryState> {
  TelemetryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'telemetryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$telemetryNotifierHash();

  @$internal
  @override
  TelemetryNotifier create() => TelemetryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryState>(value),
    );
  }
}

String _$telemetryNotifierHash() => r'1971415fc8b97d2ab224e3dcfabb7c1af5759c87';

abstract class _$TelemetryNotifier extends $Notifier<TelemetryState> {
  TelemetryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TelemetryState, TelemetryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TelemetryState, TelemetryState>,
              TelemetryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(gpsListener)
final gpsListenerProvider = GpsListenerProvider._();

final class GpsListenerProvider extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  GpsListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gpsListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gpsListenerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return gpsListener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$gpsListenerHash() => r'a3c226ee264bd192c730c789c1a13c219e687f74';

@ProviderFor(DisableTelemetryAnimations)
final disableTelemetryAnimationsProvider =
    DisableTelemetryAnimationsProvider._();

final class DisableTelemetryAnimationsProvider
    extends
        $NotifierProvider<
          DisableTelemetryAnimations,
          Map<TelemetryField, bool>
        > {
  DisableTelemetryAnimationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'disableTelemetryAnimationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$disableTelemetryAnimationsHash();

  @$internal
  @override
  DisableTelemetryAnimations create() => DisableTelemetryAnimations();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<TelemetryField, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<TelemetryField, bool>>(value),
    );
  }
}

String _$disableTelemetryAnimationsHash() =>
    r'dda5af347b2c8fe39aaec86894ba28235541022d';

abstract class _$DisableTelemetryAnimations
    extends $Notifier<Map<TelemetryField, bool>> {
  Map<TelemetryField, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<TelemetryField, bool>, Map<TelemetryField, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<TelemetryField, bool>, Map<TelemetryField, bool>>,
              Map<TelemetryField, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
