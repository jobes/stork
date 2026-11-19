// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_timing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NavigationGroundTrackNotifier)
final navigationGroundTrackProvider = NavigationGroundTrackNotifierProvider._();

final class NavigationGroundTrackNotifierProvider
    extends $NotifierProvider<NavigationGroundTrackNotifier, GroundTrack?> {
  NavigationGroundTrackNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationGroundTrackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationGroundTrackNotifierHash();

  @$internal
  @override
  NavigationGroundTrackNotifier create() => NavigationGroundTrackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroundTrack? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroundTrack?>(value),
    );
  }
}

String _$navigationGroundTrackNotifierHash() =>
    r'eb7d3bd7f25bafe5811edb0f9f8d72710ee1d3f8';

abstract class _$NavigationGroundTrackNotifier extends $Notifier<GroundTrack?> {
  GroundTrack? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GroundTrack?, GroundTrack?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GroundTrack?, GroundTrack?>,
              GroundTrack?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(_windTimingKey)
final _windTimingKeyProvider = _WindTimingKeyProvider._();

final class _WindTimingKeyProvider
    extends $FunctionalProvider<WindTimingKey, WindTimingKey, WindTimingKey>
    with $Provider<WindTimingKey> {
  _WindTimingKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_windTimingKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_windTimingKeyHash();

  @$internal
  @override
  $ProviderElement<WindTimingKey> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WindTimingKey create(Ref ref) {
    return _windTimingKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindTimingKey value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindTimingKey>(value),
    );
  }
}

String _$_windTimingKeyHash() => r'ad19b8bbaf4a0a5510ba6a308fd29b4f9ed33191';

@ProviderFor(RouteWindTimingNotifier)
final routeWindTimingProvider = RouteWindTimingNotifierProvider._();

final class RouteWindTimingNotifierProvider
    extends $AsyncNotifierProvider<RouteWindTimingNotifier, WindTimingResult?> {
  RouteWindTimingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeWindTimingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeWindTimingNotifierHash();

  @$internal
  @override
  RouteWindTimingNotifier create() => RouteWindTimingNotifier();
}

String _$routeWindTimingNotifierHash() =>
    r'deb8546ac007733c585b0b1ce309253713bc3dc2';

abstract class _$RouteWindTimingNotifier
    extends $AsyncNotifier<WindTimingResult?> {
  FutureOr<WindTimingResult?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WindTimingResult?>, WindTimingResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WindTimingResult?>, WindTimingResult?>,
              AsyncValue<WindTimingResult?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(routePointTiming)
final routePointTimingProvider = RoutePointTimingProvider._();

final class RoutePointTimingProvider
    extends
        $FunctionalProvider<
          Map<String, TimedRoutePoint>,
          Map<String, TimedRoutePoint>,
          Map<String, TimedRoutePoint>
        >
    with $Provider<Map<String, TimedRoutePoint>> {
  RoutePointTimingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routePointTimingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routePointTimingHash();

  @$internal
  @override
  $ProviderElement<Map<String, TimedRoutePoint>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, TimedRoutePoint> create(Ref ref) {
    return routePointTiming(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, TimedRoutePoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, TimedRoutePoint>>(value),
    );
  }
}

String _$routePointTimingHash() => r'77825b5b45ab62196abaab03f83c018e7b21cf2f';
