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

String _$telemetryNotifierHash() => r'2a2916a1c4c3eea3bb69a230d7033625715148cd';

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
