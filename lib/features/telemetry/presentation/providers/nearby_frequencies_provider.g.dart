// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_frequencies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot lookup of airports and airspaces near the current GPS position.
///
/// Design intent: the provider is computed once on first use (dialog open)
/// and is not reactively bound to telemetry changes. This is an intentional
/// performance optimisation — the computation is DB-heavy (loading all airports
/// from SQLite + geodesic distance calculations to airspace polygons).
/// Reactive re-evaluation on every GPS update (~1 Hz) would unnecessarily stress
/// the main thread and the database.
///
/// The repository pattern (via [mapMetadataRepositoryProvider]) is used instead
/// of calling [DatabaseService] directly, keeping the feature-layer dependency
/// rules intact.

@ProviderFor(NearbyFrequencies)
final nearbyFrequenciesProvider = NearbyFrequenciesProvider._();

/// One-shot lookup of airports and airspaces near the current GPS position.
///
/// Design intent: the provider is computed once on first use (dialog open)
/// and is not reactively bound to telemetry changes. This is an intentional
/// performance optimisation — the computation is DB-heavy (loading all airports
/// from SQLite + geodesic distance calculations to airspace polygons).
/// Reactive re-evaluation on every GPS update (~1 Hz) would unnecessarily stress
/// the main thread and the database.
///
/// The repository pattern (via [mapMetadataRepositoryProvider]) is used instead
/// of calling [DatabaseService] directly, keeping the feature-layer dependency
/// rules intact.
final class NearbyFrequenciesProvider
    extends $AsyncNotifierProvider<NearbyFrequencies, NearbyFrequenciesState> {
  /// One-shot lookup of airports and airspaces near the current GPS position.
  ///
  /// Design intent: the provider is computed once on first use (dialog open)
  /// and is not reactively bound to telemetry changes. This is an intentional
  /// performance optimisation — the computation is DB-heavy (loading all airports
  /// from SQLite + geodesic distance calculations to airspace polygons).
  /// Reactive re-evaluation on every GPS update (~1 Hz) would unnecessarily stress
  /// the main thread and the database.
  ///
  /// The repository pattern (via [mapMetadataRepositoryProvider]) is used instead
  /// of calling [DatabaseService] directly, keeping the feature-layer dependency
  /// rules intact.
  NearbyFrequenciesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyFrequenciesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyFrequenciesHash();

  @$internal
  @override
  NearbyFrequencies create() => NearbyFrequencies();
}

String _$nearbyFrequenciesHash() => r'4a48fa9c06c840da72ef33e6780ea15cafc7da84';

/// One-shot lookup of airports and airspaces near the current GPS position.
///
/// Design intent: the provider is computed once on first use (dialog open)
/// and is not reactively bound to telemetry changes. This is an intentional
/// performance optimisation — the computation is DB-heavy (loading all airports
/// from SQLite + geodesic distance calculations to airspace polygons).
/// Reactive re-evaluation on every GPS update (~1 Hz) would unnecessarily stress
/// the main thread and the database.
///
/// The repository pattern (via [mapMetadataRepositoryProvider]) is used instead
/// of calling [DatabaseService] directly, keeping the feature-layer dependency
/// rules intact.

abstract class _$NearbyFrequencies
    extends $AsyncNotifier<NearbyFrequenciesState> {
  FutureOr<NearbyFrequenciesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<NearbyFrequenciesState>, NearbyFrequenciesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NearbyFrequenciesState>,
                NearbyFrequenciesState
              >,
              AsyncValue<NearbyFrequenciesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
