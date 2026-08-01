import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/puretrack_auth_service.dart';
import '../../data/puretrack_stream_service.dart';
import 'traffic_provider.dart';

part 'puretrack_auth_provider.g.dart';

@Riverpod(keepAlive: true)
PureTrackAuthService pureTrackAuthService(Ref ref) {
  final service = PureTrackAuthService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
}

@Riverpod(keepAlive: true)
PureTrackStreamService pureTrackStreamService(Ref ref) {
  final authService = ref.watch(pureTrackAuthServiceProvider);
  final streamService = PureTrackStreamService(
    onUnauthorized: () {
      authService.invalidateToken();
    },
  );
  ref.onDispose(() {
    streamService.dispose();
  });
  return streamService;
}

@Riverpod(keepAlive: true)
class PureTrackNotifier extends _$PureTrackNotifier {
  late PureTrackAuthService _authService;
  late PureTrackStreamService _streamService;
  StreamSubscription<PureTrackPacket>? _streamSubscription;
  StreamSubscription<PureTrackAuthState>? _authSubscription;

  @override
  PureTrackAuthState build() {
    _authService = ref.read(pureTrackAuthServiceProvider);
    _streamService = ref.read(pureTrackStreamServiceProvider);

    _authSubscription = _authService.authStateStream.listen((state) {
      this.state = state;
      if (state == PureTrackAuthState.authenticated &&
          _authService.currentToken != null) {
        _connectStream(_authService.currentToken!);
      } else {
        _streamService.disconnect();
        _streamSubscription?.cancel();
        _streamSubscription = null;
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
      _streamSubscription?.cancel();
    });

    // Auto-connect on startup if stored token exists
    _initAutoConnect();

    return _authService.currentState;
  }

  Future<void> _initAutoConnect() async {
    await _authService.init();
  }

  void _connectStream(String token) {
    _streamSubscription?.cancel();
    _streamSubscription = _streamService.stream.listen((packet) {
      ref.read(trafficProvider.notifier).processPureTrackPacket(packet);
    });
    _streamService.connect(token);
  }

  Future<PureTrackAuthResult> login(String username, String password) async {
    return await _authService.login(username: username, password: password);
  }

  Future<void> logout() async {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamService.disconnect();
    await _authService.logout();
    ref.read(trafficProvider.notifier).publishState();
  }

  Future<void> invalidateToken() async {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamService.disconnect();
    await _authService.invalidateToken();
  }
}
