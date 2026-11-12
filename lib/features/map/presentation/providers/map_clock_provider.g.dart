// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapSunsetWarning)
final mapSunsetWarningProvider = MapSunsetWarningProvider._();

final class MapSunsetWarningProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  MapSunsetWarningProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapSunsetWarningProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapSunsetWarningHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return mapSunsetWarning(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$mapSunsetWarningHash() => r'0db6567d76afbea50edcf999e43a3e91c8b45519';

@ProviderFor(MapClock)
final mapClockProvider = MapClockProvider._();

final class MapClockProvider extends $NotifierProvider<MapClock, DateTime> {
  MapClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapClockHash();

  @$internal
  @override
  MapClock create() => MapClock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$mapClockHash() => r'b1a9cdbde869b093a4fc7aa905bba4474e326b3c';

abstract class _$MapClock extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(mapSolarTimes)
final mapSolarTimesProvider = MapSolarTimesProvider._();

final class MapSolarTimesProvider
    extends
        $FunctionalProvider<
          ({SolarTimes today, SolarTimes tomorrow}),
          ({SolarTimes today, SolarTimes tomorrow}),
          ({SolarTimes today, SolarTimes tomorrow})
        >
    with $Provider<({SolarTimes today, SolarTimes tomorrow})> {
  MapSolarTimesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapSolarTimesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapSolarTimesHash();

  @$internal
  @override
  $ProviderElement<({SolarTimes today, SolarTimes tomorrow})> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ({SolarTimes today, SolarTimes tomorrow}) create(Ref ref) {
    return mapSolarTimes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({SolarTimes today, SolarTimes tomorrow}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({SolarTimes today, SolarTimes tomorrow})>(value),
    );
  }
}

String _$mapSolarTimesHash() => r'b381d35233d001fcb948d0b6636c8f6603ffc911';
