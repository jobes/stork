// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'throttled_telemetry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThrottledTelemetry)
final throttledTelemetryProvider = ThrottledTelemetryProvider._();

final class ThrottledTelemetryProvider
    extends $NotifierProvider<ThrottledTelemetry, TelemetryState> {
  ThrottledTelemetryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'throttledTelemetryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$throttledTelemetryHash();

  @$internal
  @override
  ThrottledTelemetry create() => ThrottledTelemetry();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TelemetryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TelemetryState>(value),
    );
  }
}

String _$throttledTelemetryHash() =>
    r'00919ab3140bb75023a3ebe9629bf053fad6849a';

abstract class _$ThrottledTelemetry extends $Notifier<TelemetryState> {
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
