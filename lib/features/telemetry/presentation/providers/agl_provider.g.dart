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
    r'33126e431b1a5c3af1461994e7fc113d56adf007';

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

String _$terrainElevationHash() => r'4a4657966e7fab52dc4b8889ce3296a7061f5f7d';

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
        isAutoDispose: false,
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

String _$resolvedAltitudeHash() => r'371fd56c302c4c497c81ed90a24baf46284351aa';

@ProviderFor(recommendedQnh)
final recommendedQnhProvider = RecommendedQnhProvider._();

final class RecommendedQnhProvider
    extends $FunctionalProvider<double?, double?, double?>
    with $Provider<double?> {
  RecommendedQnhProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendedQnhProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendedQnhHash();

  @$internal
  @override
  $ProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double? create(Ref ref) {
    return recommendedQnh(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }
}

String _$recommendedQnhHash() => r'4bbe88b9ba9df57abbb7c892b36fdeac53e4f51c';

@ProviderFor(AutoQnhCalibrator)
final autoQnhCalibratorProvider = AutoQnhCalibratorProvider._();

final class AutoQnhCalibratorProvider
    extends $NotifierProvider<AutoQnhCalibrator, AutoQnhCalibratorState> {
  AutoQnhCalibratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoQnhCalibratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoQnhCalibratorHash();

  @$internal
  @override
  AutoQnhCalibrator create() => AutoQnhCalibrator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoQnhCalibratorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoQnhCalibratorState>(value),
    );
  }
}

String _$autoQnhCalibratorHash() => r'aa412174090a4b9bba0b8a458edde99e21a936ca';

abstract class _$AutoQnhCalibrator extends $Notifier<AutoQnhCalibratorState> {
  AutoQnhCalibratorState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AutoQnhCalibratorState, AutoQnhCalibratorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AutoQnhCalibratorState, AutoQnhCalibratorState>,
              AutoQnhCalibratorState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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

String _$aglHash() => r'57b2956ab47ada9512aaf54c277340b4b0974b00';
