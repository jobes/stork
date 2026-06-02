// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agl_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(telemetryCoordinates)
final telemetryCoordinatesProvider = TelemetryCoordinatesProvider._();

final class TelemetryCoordinatesProvider
    extends
        $FunctionalProvider<
          (double, double)?,
          (double, double)?,
          (double, double)?
        >
    with $Provider<(double, double)?> {
  TelemetryCoordinatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'telemetryCoordinatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$telemetryCoordinatesHash();

  @$internal
  @override
  $ProviderElement<(double, double)?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  (double, double)? create(Ref ref) {
    return telemetryCoordinates(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue((double, double)? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<(double, double)?>(value),
    );
  }
}

String _$telemetryCoordinatesHash() =>
    r'a30379933a3b0ca053bd1d564efd20df1e708913';

@ProviderFor(TerrainElevation)
final terrainElevationProvider = TerrainElevationProvider._();

final class TerrainElevationProvider
    extends $NotifierProvider<TerrainElevation, AsyncValue<double?>> {
  TerrainElevationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terrainElevationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terrainElevationHash();

  @$internal
  @override
  TerrainElevation create() => TerrainElevation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<double?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<double?>>(value),
    );
  }
}

String _$terrainElevationHash() => r'd3167aeec255fb410d6abaa8ba069183e90e9770';

abstract class _$TerrainElevation extends $Notifier<AsyncValue<double?>> {
  AsyncValue<double?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<double?>, AsyncValue<double?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<double?>, AsyncValue<double?>>,
              AsyncValue<double?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(resolvedAltitude)
final resolvedAltitudeProvider = ResolvedAltitudeProvider._();

final class ResolvedAltitudeProvider
    extends
        $FunctionalProvider<
          ResolvedAltitude,
          ResolvedAltitude,
          ResolvedAltitude
        >
    with $Provider<ResolvedAltitude> {
  ResolvedAltitudeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resolvedAltitudeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resolvedAltitudeHash();

  @$internal
  @override
  $ProviderElement<ResolvedAltitude> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ResolvedAltitude create(Ref ref) {
    return resolvedAltitude(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResolvedAltitude value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResolvedAltitude>(value),
    );
  }
}

String _$resolvedAltitudeHash() => r'55992463429424dcf3898e56db5529a247604ad9';

@ProviderFor(agl)
final aglProvider = AglProvider._();

final class AglProvider
    extends $FunctionalProvider<AglState, AglState, AglState>
    with $Provider<AglState> {
  AglProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aglProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aglHash();

  @$internal
  @override
  $ProviderElement<AglState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AglState create(Ref ref) {
    return agl(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AglState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AglState>(value),
    );
  }
}

String _$aglHash() => r'bd0e964f251915d715eba64e7531b8501df49836';
