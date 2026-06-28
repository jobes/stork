// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_records_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FlightRecords)
final flightRecordsProvider = FlightRecordsProvider._();

final class FlightRecordsProvider
    extends $AsyncNotifierProvider<FlightRecords, FlightRecordsState> {
  FlightRecordsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flightRecordsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flightRecordsHash();

  @$internal
  @override
  FlightRecords create() => FlightRecords();
}

String _$flightRecordsHash() => r'430e0ea707ba68487549d33c87329e2c6bec48d1';

abstract class _$FlightRecords extends $AsyncNotifier<FlightRecordsState> {
  FutureOr<FlightRecordsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<FlightRecordsState>, FlightRecordsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FlightRecordsState>, FlightRecordsState>,
              AsyncValue<FlightRecordsState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
