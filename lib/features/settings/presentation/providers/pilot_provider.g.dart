// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pilot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PilotState)
final pilotStateProvider = PilotStateProvider._();

final class PilotStateProvider
    extends $AsyncNotifierProvider<PilotState, List<Pilot>> {
  PilotStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pilotStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pilotStateHash();

  @$internal
  @override
  PilotState create() => PilotState();
}

String _$pilotStateHash() => r'aa80c6dca2853f0fbaabc72fa25754b51f15c84e';

abstract class _$PilotState extends $AsyncNotifier<List<Pilot>> {
  FutureOr<List<Pilot>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Pilot>>, List<Pilot>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Pilot>>, List<Pilot>>,
              AsyncValue<List<Pilot>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(pilotStats)
final pilotStatsProvider = PilotStatsFamily._();

final class PilotStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TimeBasedStats>,
          TimeBasedStats,
          FutureOr<TimeBasedStats>
        >
    with $FutureModifier<TimeBasedStats>, $FutureProvider<TimeBasedStats> {
  PilotStatsProvider._({
    required PilotStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pilotStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pilotStatsHash();

  @override
  String toString() {
    return r'pilotStatsProvider'
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
    return pilotStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PilotStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pilotStatsHash() => r'2cdfe7a8c358f0df238c5a0b4bf921ae1465fdf1';

final class PilotStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TimeBasedStats>, String> {
  PilotStatsFamily._()
    : super(
        retry: null,
        name: r'pilotStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PilotStatsProvider call(String pilotId) =>
      PilotStatsProvider._(argument: pilotId, from: this);

  @override
  String toString() => r'pilotStatsProvider';
}
