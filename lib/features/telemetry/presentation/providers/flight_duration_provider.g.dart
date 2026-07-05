// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_duration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FlightDuration)
final flightDurationProvider = FlightDurationProvider._();

final class FlightDurationProvider
    extends $NotifierProvider<FlightDuration, FlightSummary> {
  FlightDurationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightDurationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightDurationHash();

  @$internal
  @override
  FlightDuration create() => FlightDuration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlightSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlightSummary>(value),
    );
  }
}

String _$flightDurationHash() => r'b41d5cf9e0fd6451e110a499dda3ddf221ef4546';

abstract class _$FlightDuration extends $Notifier<FlightSummary> {
  FlightSummary build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FlightSummary, FlightSummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FlightSummary, FlightSummary>,
              FlightSummary,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
