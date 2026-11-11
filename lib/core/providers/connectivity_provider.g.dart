// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Platform connectivity source.
///
/// Exposed as a provider (instead of constructing [Connectivity] inside the
/// notifier) so tests can override it and no platform plugin is touched.

@ProviderFor(connectivity)
final connectivityProvider = ConnectivityProvider._();

/// Platform connectivity source.
///
/// Exposed as a provider (instead of constructing [Connectivity] inside the
/// notifier) so tests can override it and no platform plugin is touched.

final class ConnectivityProvider
    extends $FunctionalProvider<Connectivity, Connectivity, Connectivity>
    with $Provider<Connectivity> {
  /// Platform connectivity source.
  ///
  /// Exposed as a provider (instead of constructing [Connectivity] inside the
  /// notifier) so tests can override it and no platform plugin is touched.
  ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  $ProviderElement<Connectivity> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Connectivity create(Ref ref) {
    return connectivity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Connectivity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Connectivity>(value),
    );
  }
}

String _$connectivityHash() => r'e66720f09edf1a8b09e450e1eaedd51da9443f0e';

/// Whether the device has an active network link (Wi-Fi, mobile data, ...).
///
/// This reports the state of the network interfaces rather than probing a
/// remote host: a captive portal or a hotspot without upstream connectivity
/// still reports `true`. Features that need fresh remote data must verify it
/// themselves (see `AirspaceDataStatus`); this flag is only a fast hint.
///
/// The initial value is `true` until the first platform check completes, so a
/// warning is never flashed during startup on a healthy device.

@ProviderFor(NetworkLinkAvailability)
final networkLinkAvailabilityProvider = NetworkLinkAvailabilityProvider._();

/// Whether the device has an active network link (Wi-Fi, mobile data, ...).
///
/// This reports the state of the network interfaces rather than probing a
/// remote host: a captive portal or a hotspot without upstream connectivity
/// still reports `true`. Features that need fresh remote data must verify it
/// themselves (see `AirspaceDataStatus`); this flag is only a fast hint.
///
/// The initial value is `true` until the first platform check completes, so a
/// warning is never flashed during startup on a healthy device.
final class NetworkLinkAvailabilityProvider
    extends $NotifierProvider<NetworkLinkAvailability, bool> {
  /// Whether the device has an active network link (Wi-Fi, mobile data, ...).
  ///
  /// This reports the state of the network interfaces rather than probing a
  /// remote host: a captive portal or a hotspot without upstream connectivity
  /// still reports `true`. Features that need fresh remote data must verify it
  /// themselves (see `AirspaceDataStatus`); this flag is only a fast hint.
  ///
  /// The initial value is `true` until the first platform check completes, so a
  /// warning is never flashed during startup on a healthy device.
  NetworkLinkAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkLinkAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkLinkAvailabilityHash();

  @$internal
  @override
  NetworkLinkAvailability create() => NetworkLinkAvailability();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$networkLinkAvailabilityHash() =>
    r'031a367ca70a88e6f9cafe5a4c181bf67980ee75';

/// Whether the device has an active network link (Wi-Fi, mobile data, ...).
///
/// This reports the state of the network interfaces rather than probing a
/// remote host: a captive portal or a hotspot without upstream connectivity
/// still reports `true`. Features that need fresh remote data must verify it
/// themselves (see `AirspaceDataStatus`); this flag is only a fast hint.
///
/// The initial value is `true` until the first platform check completes, so a
/// warning is never flashed during startup on a healthy device.

abstract class _$NetworkLinkAvailability extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
