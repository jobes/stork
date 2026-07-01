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

String _$telemetryNotifierHash() => r'922bc5486c451b0edae602e3b0fcfa97e3ec573a';

abstract class _$TelemetryNotifier extends $Notifier<TelemetryState> {
  TelemetryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TelemetryState, TelemetryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TelemetryState, TelemetryState>,
              TelemetryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
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
        isAutoDispose: true,
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

String _$gpsListenerHash() => r'522a15cee9ed0dd818415419aa718e95ce16e55c';
