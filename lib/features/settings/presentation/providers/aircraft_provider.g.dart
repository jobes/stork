// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aircraft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AircraftState)
final aircraftStateProvider = AircraftStateProvider._();

final class AircraftStateProvider
    extends $AsyncNotifierProvider<AircraftState, List<Aircraft>> {
  AircraftStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aircraftStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aircraftStateHash();

  @$internal
  @override
  AircraftState create() => AircraftState();
}

String _$aircraftStateHash() => r'00fce3d587f4280673717ba55b2ba32aa4ad274f';

abstract class _$AircraftState extends $AsyncNotifier<List<Aircraft>> {
  FutureOr<List<Aircraft>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Aircraft>>, List<Aircraft>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Aircraft>>, List<Aircraft>>,
              AsyncValue<List<Aircraft>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(aircraftHours)
final aircraftHoursProvider = AircraftHoursFamily._();

final class AircraftHoursProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  AircraftHoursProvider._({
    required AircraftHoursFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'aircraftHoursProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$aircraftHoursHash();

  @override
  String toString() {
    return r'aircraftHoursProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    final argument = this.argument as String;
    return aircraftHours(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AircraftHoursProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$aircraftHoursHash() => r'2f5b83bc632794dbf8de9f384a40ac273bd4d82e';

final class AircraftHoursFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double>, String> {
  AircraftHoursFamily._()
    : super(
        retry: null,
        name: r'aircraftHoursProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AircraftHoursProvider call(String airplaneId) =>
      AircraftHoursProvider._(argument: airplaneId, from: this);

  @override
  String toString() => r'aircraftHoursProvider';
}

@ProviderFor(aircraftStats)
final aircraftStatsProvider = AircraftStatsFamily._();

final class AircraftStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TimeBasedStats>,
          TimeBasedStats,
          FutureOr<TimeBasedStats>
        >
    with $FutureModifier<TimeBasedStats>, $FutureProvider<TimeBasedStats> {
  AircraftStatsProvider._({
    required AircraftStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'aircraftStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$aircraftStatsHash();

  @override
  String toString() {
    return r'aircraftStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TimeBasedStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TimeBasedStats> create(Ref ref) {
    final argument = this.argument as String;
    return aircraftStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AircraftStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$aircraftStatsHash() => r'0b87de5c8951702dcd1e52f8c29241d74a26d316';

final class AircraftStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TimeBasedStats>, String> {
  AircraftStatsFamily._()
    : super(
        retry: null,
        name: r'aircraftStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AircraftStatsProvider call(String airplaneId) =>
      AircraftStatsProvider._(argument: airplaneId, from: this);

  @override
  String toString() => r'aircraftStatsProvider';
}
