// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_access_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads the OS location permission and location-service state.
///
/// Platform access lives in `core` rather than in a presentation notifier so
/// the checks can be stubbed in tests. Nothing is polled in the background:
/// consumers call [LocationAccess.refresh] when they need a current answer.

@ProviderFor(LocationAccess)
final locationAccessProvider = LocationAccessProvider._();

/// Reads the OS location permission and location-service state.
///
/// Platform access lives in `core` rather than in a presentation notifier so
/// the checks can be stubbed in tests. Nothing is polled in the background:
/// consumers call [LocationAccess.refresh] when they need a current answer.
final class LocationAccessProvider
    extends $NotifierProvider<LocationAccess, LocationAccessState> {
  /// Reads the OS location permission and location-service state.
  ///
  /// Platform access lives in `core` rather than in a presentation notifier so
  /// the checks can be stubbed in tests. Nothing is polled in the background:
  /// consumers call [LocationAccess.refresh] when they need a current answer.
  LocationAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationAccessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationAccessHash();

  @$internal
  @override
  LocationAccess create() => LocationAccess();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationAccessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationAccessState>(value),
    );
  }
}

String _$locationAccessHash() => r'8241742a57d7c79249e07fd5240b100ef75d8b81';

/// Reads the OS location permission and location-service state.
///
/// Platform access lives in `core` rather than in a presentation notifier so
/// the checks can be stubbed in tests. Nothing is polled in the background:
/// consumers call [LocationAccess.refresh] when they need a current answer.

abstract class _$LocationAccess extends $Notifier<LocationAccessState> {
  LocationAccessState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocationAccessState, LocationAccessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocationAccessState, LocationAccessState>,
              LocationAccessState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
