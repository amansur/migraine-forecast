import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/oura_auth_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('OuraAuthManager', () {
    test('starts with no authentication', () async {
      final manager = OuraAuthManager(storage: MockSecureStorage());
      expect(manager.isAuthenticated, false);
      expect(manager.userEmail, null);
    });

    test('stores and retrieves access token via saveTokens', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final manager = OuraAuthManager(storage: storage);
      await manager.saveTokens(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(manager.isAuthenticated, true);
    });

    test('clears token on logout', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      final manager = OuraAuthManager(storage: storage);
      await manager.saveTokens(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await manager.logout();
      expect(manager.isAuthenticated, false);
    });

    test('saveTokens stores all values and returns fresh token before expiry', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final manager = OuraAuthManager(storage: storage);
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      await manager.saveTokens(
        accessToken: 'access-123',
        refreshToken: 'refresh-abc',
        expiresAt: expiresAt,
        userEmail: 'user@example.com',
      );

      expect(manager.isAuthenticated, true);
      expect(manager.userEmail, 'user@example.com');

      // Token is fresh (expires in 1h), should return it directly
      final token = await manager.getValidAccessToken();
      expect(token, 'access-123');
    });

    test('getValidAccessToken refreshes when token is near expiry', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final mockHttp = MockHttpClient();
      final refreshResponseBody = jsonEncode({
        'access_token': 'new-access-token',
        'refresh_token': 'new-refresh-token',
        'expires_in': 86400,
      });
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(refreshResponseBody, 200));

      final manager = OuraAuthManager(storage: storage, httpClient: mockHttp);

      // Store a token that is already expired
      final expiredAt = DateTime.now().subtract(const Duration(minutes: 5));
      await manager.saveTokens(
        accessToken: 'old-access-token',
        refreshToken: 'old-refresh-token',
        expiresAt: expiredAt,
      );

      final token = await manager.getValidAccessToken();

      // Should have called the refresh endpoint
      verify(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .called(1);

      // Should return the new token
      expect(token, 'new-access-token');

      // Manager should now hold the new token in memory
      expect(manager.isAuthenticated, true);
    });

    test('getValidAccessToken logs out and returns null when refresh returns 400', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      final mockHttp = MockHttpClient();
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"error": "invalid_grant"}', 400));

      final manager = OuraAuthManager(storage: storage, httpClient: mockHttp);

      final expiredAt = DateTime.now().subtract(const Duration(minutes: 5));
      await manager.saveTokens(
        accessToken: 'old-access-token',
        refreshToken: 'old-refresh-token',
        expiresAt: expiredAt,
      );

      final token = await manager.getValidAccessToken();

      expect(token, isNull);
      // Token was genuinely rejected — session should be cleared.
      expect(manager.isAuthenticated, false);
    });

    test('getValidAccessToken preserves tokens and returns null on transient 5xx', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final mockHttp = MockHttpClient();
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Service Unavailable', 503));

      final manager = OuraAuthManager(storage: storage, httpClient: mockHttp);

      final expiredAt = DateTime.now().subtract(const Duration(minutes: 5));
      await manager.saveTokens(
        accessToken: 'old-access-token',
        refreshToken: 'old-refresh-token',
        expiresAt: expiredAt,
      );

      final token = await manager.getValidAccessToken();

      expect(token, isNull);
      // Transient server error — tokens should be preserved for next attempt.
      expect(manager.isAuthenticated, true);
    });
  });
}
