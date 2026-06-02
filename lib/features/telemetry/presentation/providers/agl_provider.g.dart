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

String _$resolvedAltitudeHash() => r'e5a4a66771240ed07d4678f0521ebc550bc7b656';

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

String _$recommendedQnhHash() => r'5e924c56b0a58622053c630c011e33963283bb35';

@ProviderFor(autoQnhCalibrator)
final autoQnhCalibratorProvider = AutoQnhCalibratorProvider._();

final class AutoQnhCalibratorProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
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
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return autoQnhCalibrator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$autoQnhCalibratorHash() => r'030f45d495bdb050242b2c28908fa0c7ed644f27';

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

String _$aglHash() => r'6fbbbb85fcc6136bf4ff2eeff39f204d4de3d169';
