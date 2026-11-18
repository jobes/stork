// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_waypoint_weather_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Forecast at each route waypoint, keyed by the waypoint index in the
/// navigation route. Uses the same timing and profile data as the point
/// details so the route list and the dialogs never disagree.

@ProviderFor(routeWaypointWeather)
final routeWaypointWeatherProvider = RouteWaypointWeatherProvider._();

/// Forecast at each route waypoint, keyed by the waypoint index in the
/// navigation route. Uses the same timing and profile data as the point
/// details so the route list and the dialogs never disagree.

final class RouteWaypointWeatherProvider
    extends
        $FunctionalProvider<
          Map<int, RouteWaypointWeather>,
          Map<int, RouteWaypointWeather>,
          Map<int, RouteWaypointWeather>
        >
    with $Provider<Map<int, RouteWaypointWeather>> {
  /// Forecast at each route waypoint, keyed by the waypoint index in the
  /// navigation route. Uses the same timing and profile data as the point
  /// details so the route list and the dialogs never disagree.
  RouteWaypointWeatherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeWaypointWeatherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeWaypointWeatherHash();

  @$internal
  @override
  $ProviderElement<Map<int, RouteWaypointWeather>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<int, RouteWaypointWeather> create(Ref ref) {
    return routeWaypointWeather(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, RouteWaypointWeather> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<int, RouteWaypointWeather>>(
        value,
      ),
    );
  }
}

String _$routeWaypointWeatherHash() =>
    r'b0cc4ccfeb7f94c9538aeaa62f0bd2f531916ced';

/// Wind and surface gusts at every forecast point for its estimated arrival
/// time. Uses the same wind-adjusted timing as the route list.

@ProviderFor(routePointWinds)
final routePointWindsProvider = RoutePointWindsProvider._();

/// Wind and surface gusts at every forecast point for its estimated arrival
/// time. Uses the same wind-adjusted timing as the route list.

final class RoutePointWindsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, RoutePointWind>>,
          Map<String, RoutePointWind>,
          FutureOr<Map<String, RoutePointWind>>
        >
    with
        $FutureModifier<Map<String, RoutePointWind>>,
        $FutureProvider<Map<String, RoutePointWind>> {
  /// Wind and surface gusts at every forecast point for its estimated arrival
  /// time. Uses the same wind-adjusted timing as the route list.
  RoutePointWindsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routePointWindsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routePointWindsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, RoutePointWind>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, RoutePointWind>> create(Ref ref) {
    return routePointWinds(ref);
  }
}

String _$routePointWindsHash() => r'1941b34bd59bc2a35d4dbc446405f51ba3ee51c1';
