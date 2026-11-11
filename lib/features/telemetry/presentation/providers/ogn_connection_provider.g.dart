// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ogn_connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the OGN APRS inbound connection is currently established.
///
/// The traffic notifier owns the connection and writes the status here so that
/// map-level status indicators can surface a lost traffic source without
/// having to depend on the traffic list itself.

@ProviderFor(OgnConnected)
final ognConnectedProvider = OgnConnectedProvider._();

/// Whether the OGN APRS inbound connection is currently established.
///
/// The traffic notifier owns the connection and writes the status here so that
/// map-level status indicators can surface a lost traffic source without
/// having to depend on the traffic list itself.
final class OgnConnectedProvider extends $NotifierProvider<OgnConnected, bool> {
  /// Whether the OGN APRS inbound connection is currently established.
  ///
  /// The traffic notifier owns the connection and writes the status here so that
  /// map-level status indicators can surface a lost traffic source without
  /// having to depend on the traffic list itself.
  OgnConnectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ognConnectedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ognConnectedHash();

  @$internal
  @override
  OgnConnected create() => OgnConnected();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$ognConnectedHash() => r'7f18ba923d2fae77ed2d01b8eee0b2b23164eccf';

/// Whether the OGN APRS inbound connection is currently established.
///
/// The traffic notifier owns the connection and writes the status here so that
/// map-level status indicators can surface a lost traffic source without
/// having to depend on the traffic list itself.

abstract class _$OgnConnected extends $Notifier<bool> {
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
