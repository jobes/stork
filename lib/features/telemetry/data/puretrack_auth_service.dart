import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

enum PureTrackAuthState {
  unauthenticated,
  authenticating,
  authenticated,
  tokenInvalid,
  error,
}

class PureTrackAuthResult {
  final bool isSuccess;
  final String? token;
  final bool isPro;
  final String? errorMessage;

  const PureTrackAuthResult({
    required this.isSuccess,
    this.token,
    this.isPro = true,
    this.errorMessage,
  });
}

class PureTrackAuthService {
  static const String _kPureTrackTokenKey = 'puretrack_access_token';
  static const String _kPureTrackUsernameKey = 'puretrack_username';
  
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _baseUrl;
  final String _apiKey;

  final StreamController<PureTrackAuthState> _authStateController =
      StreamController<PureTrackAuthState>.broadcast();

  PureTrackAuthState _currentState = PureTrackAuthState.unauthenticated;
  String? _cachedToken;
  String? _cachedUsername;

  PureTrackAuthState get currentState => _currentState;
  Stream<PureTrackAuthState> get authStateStream => _authStateController.stream;
  String? get currentToken => _cachedToken;
  String? get currentUsername => _cachedUsername;
  String get apiKey => _apiKey;

  PureTrackAuthService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String baseUrl = 'https://puretrack.io',
    String? apiKey,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _baseUrl = baseUrl,
        _apiKey = apiKey ?? (dotenv.isInitialized ? (dotenv.env['PURETRACK_KEY'] ?? '') : '');


  /// Initializes auth service by loading stored token from secure storage
  Future<String?> init() async {
    try {
      _cachedToken = await _storage.read(key: _kPureTrackTokenKey);
      _cachedUsername = await _storage.read(key: _kPureTrackUsernameKey);
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        _setState(PureTrackAuthState.authenticated);
        return _cachedToken;
      } else {
        _setState(PureTrackAuthState.unauthenticated);
        return null;
      }
    } catch (e) {
      debugPrint('PureTrackAuthService init error: $e');
      _setState(PureTrackAuthState.unauthenticated);
      return null;
    }
  }

  /// Authenticates with PureTrack official API (POST /api/login)
  /// Requires email, password, and PureTrack application API key.
  Future<PureTrackAuthResult> login({
    required String username,
    required String password,
  }) async {
    _setState(PureTrackAuthState.authenticating);
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'key': _apiKey,
          'email': username.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] ?? data['token'];
        final isPro = data['pro'] == true;

        if (token != null && token.toString().isNotEmpty) {
          final tokenStr = token.toString();
          await _storage.write(key: _kPureTrackTokenKey, value: tokenStr);
          await _storage.write(key: _kPureTrackUsernameKey, value: username.trim());
          _cachedToken = tokenStr;
          _cachedUsername = username.trim();
          _setState(PureTrackAuthState.authenticated);
          return PureTrackAuthResult(
            isSuccess: true,
            token: tokenStr,
            isPro: isPro,
          );
        }
      }

      final errorMsg = response.statusCode == 401
          ? 'Invalid username or password'
          : 'Authentication failed (HTTP ${response.statusCode})';

      _setState(PureTrackAuthState.error);
      return PureTrackAuthResult(isSuccess: false, errorMessage: errorMsg);
    } catch (e) {
      debugPrint('PureTrack login error: $e');
      _setState(PureTrackAuthState.error);
      return PureTrackAuthResult(
        isSuccess: false,
        errorMessage: 'Connection failed. Please check network.',
      );
    }
  }

  /// Called when server returns 401 Unauthorized or socket/API connection is rejected
  Future<void> invalidateToken() async {
    _cachedToken = null;
    try {
      await _storage.delete(key: _kPureTrackTokenKey);
    } catch (e) {
      debugPrint('Error clearing secure token: $e');
    }
    _setState(PureTrackAuthState.tokenInvalid);
  }

  /// Logs out user, clears secure token and saved username
  Future<void> logout() async {
    _cachedToken = null;
    _cachedUsername = null;
    try {
      await _storage.delete(key: _kPureTrackTokenKey);
      await _storage.delete(key: _kPureTrackUsernameKey);
    } catch (e) {
      debugPrint('Error during logout secure storage delete: $e');
    }
    _setState(PureTrackAuthState.unauthenticated);
  }

  void _setState(PureTrackAuthState newState) {
    _currentState = newState;
    _authStateController.add(newState);
  }

  void dispose() {
    _authStateController.close();
  }
}
