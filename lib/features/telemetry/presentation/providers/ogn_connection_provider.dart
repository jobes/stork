import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ogn_connection_provider.g.dart';

/// Whether the OGN APRS inbound connection is currently established.
///
/// The traffic notifier owns the connection and writes the status here so that
/// map-level status indicators can surface a lost traffic source without
/// having to depend on the traffic list itself.
@Riverpod(keepAlive: true)
class OgnConnected extends _$OgnConnected {
  @override
  bool build() => false;

  void setConnected(bool value) {
    if (state != value) state = value;
  }
}
