import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:stork/features/telemetry/data/puretrack_auth_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('PureTrackAuthService Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late MockHttpClient mockClient;
    late PureTrackAuthService authService;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockClient = MockHttpClient();
      authService = PureTrackAuthService(
        storage: mockStorage,
        client: mockClient,
      );
    });

    test('init loads token from storage if present', () async {
      when(
        () => mockStorage.read(key: 'puretrack_access_token'),
      ).thenAnswer((_) async => 'mock_token_123');
      when(
        () => mockStorage.read(key: 'puretrack_username'),
      ).thenAnswer((_) async => 'pilot@example.com');

      final token = await authService.init();

      expect(token, equals('mock_token_123'));
      expect(
        authService.currentState,
        equals(PureTrackAuthState.authenticated),
      );
      expect(authService.currentToken, equals('mock_token_123'));
      expect(authService.currentUsername, equals('pilot@example.com'));
    });

    test('init sets unauthenticated if token not present', () async {
      when(
        () => mockStorage.read(key: 'puretrack_access_token'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.read(key: 'puretrack_username'),
      ).thenAnswer((_) async => null);

      final token = await authService.init();

      expect(token, isNull);
      expect(
        authService.currentState,
        equals(PureTrackAuthState.unauthenticated),
      );
    });

    test('login persists token on 200 response', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'access_token': 'valid_jwt_token', 'pro': true}),
          200,
        ),
      );

      final result = await authService.login(
        username: 'pilot@example.com',
        password: 'secretpassword',
      );

      expect(result.isSuccess, isTrue);
      expect(result.token, equals('valid_jwt_token'));
      expect(result.isPro, isTrue);
      expect(
        authService.currentState,
        equals(PureTrackAuthState.authenticated),
      );
      verify(
        () => mockStorage.write(
          key: 'puretrack_access_token',
          value: 'valid_jwt_token',
        ),
      ).called(1);
    });

    test('login handles 401 failure gracefully', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'error': 'Unauthorized'}), 401),
      );

      final result = await authService.login(
        username: 'pilot@example.com',
        password: 'wrongpassword',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Invalid username or password'));
      expect(authService.currentState, equals(PureTrackAuthState.error));
    });

    test(
      'invalidateToken clears storage and sets state to tokenInvalid',
      () async {
        when(
          () => mockStorage.delete(key: 'puretrack_access_token'),
        ).thenAnswer((_) async => {});

        await authService.invalidateToken();

        expect(authService.currentToken, isNull);
        expect(
          authService.currentState,
          equals(PureTrackAuthState.tokenInvalid),
        );
        verify(
          () => mockStorage.delete(key: 'puretrack_access_token'),
        ).called(1);
      },
    );

    test(
      'logout clears secure storage and sets state to unauthenticated',
      () async {
        when(
          () => mockStorage.delete(key: any(named: 'key')),
        ).thenAnswer((_) async => {});

        await authService.logout();

        expect(authService.currentToken, isNull);
        expect(authService.currentUsername, isNull);
        expect(
          authService.currentState,
          equals(PureTrackAuthState.unauthenticated),
        );
        verify(
          () => mockStorage.delete(key: 'puretrack_access_token'),
        ).called(1);
        verify(() => mockStorage.delete(key: 'puretrack_username')).called(1);
      },
    );
  });
}
