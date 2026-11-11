import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Platform connectivity source.
///
/// Exposed as a provider (instead of constructing [Connectivity] inside the
/// notifier) so tests can override it and no platform plugin is touched.
@Riverpod(keepAlive: true)
Connectivity connectivity(Ref ref) => Connectivity();

/// Whether the device has an active network link (Wi-Fi, mobile data, ...).
///
/// This reports the state of the network interfaces rather than probing a
/// remote host: a captive portal or a hotspot without upstream connectivity
/// still reports `true`. Features that need fresh remote data must verify it
/// themselves (see `AirspaceDataStatus`); this flag is only a fast hint.
///
/// The initial value is `true` until the first platform check completes, so a
/// warning is never flashed during startup on a healthy device.
@Riverpod(keepAlive: true)
class NetworkLinkAvailability extends _$NetworkLinkAvailability {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  bool build() {
    final connectivity = ref.watch(connectivityProvider);

    unawaited(_refresh(connectivity));
    _subscription = connectivity.onConnectivityChanged.listen(
      _apply,
      onError: (Object error) {
        debugPrint('[NetworkLinkAvailability] stream error: $error');
      },
    );

    ref.onDispose(() => _subscription?.cancel());
    return true;
  }

  Future<void> _refresh(Connectivity connectivity) async {
    try {
      _apply(await connectivity.checkConnectivity());
    } catch (error) {
      debugPrint('[NetworkLinkAvailability] check failed: $error');
    }
  }

  void _apply(List<ConnectivityResult> results) {
    // Some platforms report an empty list when the state is unknown; do not
    // raise a warning we cannot confirm.
    if (results.isEmpty) return;
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    if (state != isOnline) state = isOnline;
  }
}
